import Foundation
import Network

// MARK: - Dust R14: REST API (port 8772) & Webhooks

final class DustAPIService: ObservableObject {
    static let shared = DustAPIService()

    struct HTTPResponse {
        let code: Int
        let body: String
    }

    private struct ParsedRequest {
        let method: String
        let path: String
        let headers: [String: String]
        let body: String

        init?(rawValue: String) {
            let parts = rawValue.components(separatedBy: "\r\n\r\n")
            let headerBlock = parts.first ?? rawValue
            body = parts.count > 1 ? parts.dropFirst().joined(separator: "\r\n\r\n") : ""

            let lines = headerBlock.components(separatedBy: "\r\n")
            guard let requestLine = lines.first else { return nil }
            let requestParts = requestLine.split(separator: " ")
            guard requestParts.count >= 2 else { return nil }

            method = String(requestParts[0])
            path = String(requestParts[1]).components(separatedBy: "?").first ?? String(requestParts[1])

            var parsedHeaders: [String: String] = [:]
            for line in lines.dropFirst() {
                let segments = line.split(separator: ":", maxSplits: 1)
                guard segments.count == 2 else { continue }
                parsedHeaders[String(segments[0]).lowercased()] = String(segments[1]).trimmingCharacters(in: .whitespaces)
            }
            headers = parsedHeaders
        }

        func header(named name: String) -> String? {
            headers[name.lowercased()]
        }
    }

    private var listener: NWListener?
    private let port: UInt16 = 8772
    @Published var isRunning = false

    private init() {}

    func start() {
        guard listener == nil else { return }
        do {
            let params = NWParameters.tcp
            params.allowLocalEndpointReuse = true
            listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
            listener?.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async { self?.isRunning = state == .ready }
            }
            listener?.newConnectionHandler = { [weak self] conn in
                self?.handle(conn)
            }
            listener?.start(queue: .global())
        } catch { print("DustAPI error: \(error)") }
    }

    func stop() {
        listener?.cancel(); listener = nil
        DispatchQueue.main.async { self.isRunning = false }
    }

    private func handle(_ conn: NWConnection) {
        conn.start(queue: .global())
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, _ in
            guard let data = data, let req = String(data: data, encoding: .utf8) else { conn.cancel(); return }
            let resp = self?.route(req) ?? HTTPResponse(code: 404, body: #"{"error":"Not found}"#)
            let http = "HTTP/1.1 \(resp.code)\r\nContent-Type: application/json\r\nContent-Length: \(resp.body.count)\r\n\r\n\(resp.body)"
            conn.send(content: http.data(using: .utf8), completion: .contentProcessed { _ in conn.cancel() })
        }
    }

    private func route(_ req: String) -> HTTPResponse {
        guard let parsed = ParsedRequest(rawValue: req) else {
            return HTTPResponse(code: 404, body: #"{"error":"Not found"}"#)
        }
        guard parsed.header(named: "X-API-Key") != nil else {
            return HTTPResponse(code: 401, body: #"{"error":"Unauthorized"}"#)
        }

        switch (parsed.method, parsed.path) {
        case ("GET", "/status"):
            return HTTPResponse(code: 200, body: statusJSON())
        case ("POST", "/session/start"):
            return startSession(body: parsed.body)
        case ("POST", "/session/end"):
            return endSession(body: parsed.body)
        case ("GET", "/stats"):
            return HTTPResponse(code: 200, body: statsJSON())
        case ("GET", "/blocked-apps"):
            return HTTPResponse(code: 200, body: blockedAppsJSON())
        case ("GET", "/schedule"):
            return HTTPResponse(code: 200, body: scheduleJSON())
        case ("GET", "/openapi.json"):
            return HTTPResponse(code: 200, body: openAPISpec())
        default:
            return HTTPResponse(code: 404, body: #"{"error":"Not found"}"#)
        }
    }

    private func openAPISpec() -> String {
        return #"{"openapi":"3.0.0","info":{"title":"Dust API","version":"1.0"},"paths":{"/status":{"get":{"summary":"Focus status"}},"/session/start":{"post":{"summary":"Start focus session"}},"/session/end":{"post":{"summary":"End focus session"}},"/stats":{"get":{"summary":"Focus statistics"}},"/blocked-apps":{"get":{"summary":"Blocked apps"}},"/schedule":{"get":{"summary":"Focus schedule"}}}}"#
    }

    private func statusJSON() -> String {
        let activeSession = TeamFocusService.shared.teamSessions.last(where: { $0.status == .active })
        if let session = activeSession {
            let participants = session.participants.map { "\"\(escape($0))\"" }.joined(separator: ",")
            return #"{"focused":true,"sessionId":"\#(session.id)","sessionStarted":"\#(ISO8601DateFormatter().string(from: session.startTime))","participants":[\#(participants)]}"#
        }
        return #"{"focused":false,"sessionStarted":null,"participants":[]}"#
    }

    private func startSession(body: String) -> HTTPResponse {
        let payload = jsonObject(from: body)
        let duration = (payload?["duration"] as? Double) ?? 1500
        let participants = (payload?["participants"] as? [String]) ?? ["You"]
        let session = TeamFocusService.shared.startTeamSession(duration: duration, participants: participants)
        DustiOSService.shared.currentSession = "active"
        DustiOSService.shared.todayFocusTime += duration
        DustiOSService.shared.refreshWidget()
        return HTTPResponse(code: 201, body: #"{"id":"\#(session.id)","status":"\#(session.status.rawValue)"}"#)
    }

    private func endSession(body: String) -> HTTPResponse {
        let payload = jsonObject(from: body)
        let requestedID = (payload?["sessionId"] as? String).flatMap(UUID.init(uuidString:))
        guard let session = requestedID.flatMap({ id in TeamFocusService.shared.teamSessions.last(where: { $0.id == id && $0.status == .active }) })
            ?? TeamFocusService.shared.teamSessions.last(where: { $0.status == .active }) else {
            return HTTPResponse(code: 404, body: #"{"error":"No active session"}"#)
        }
        TeamFocusService.shared.endTeamSession(session.id)
        DustiOSService.shared.currentSession = "idle"
        DustiOSService.shared.refreshWidget()
        return HTTPResponse(code: 200, body: #"{"ended":true,"id":"\#(session.id)"}"#)
    }

    private func statsJSON() -> String {
        let sessions = TeamFocusService.shared.teamSessions
        let partners = TeamFocusService.shared.accountabilityPartners
        let totalFocus = sessions.filter { Calendar.current.isDateInToday($0.startTime) }.reduce(0) { $0 + $1.duration }
        let bestStreak = partners.map(\.focusStats.streak).max() ?? 0
        return #"{"totalFocusToday":\#(Int(totalFocus)),"sessions":\#(sessions.count),"activeChallenges":\#(TeamFocusService.shared.teamChallenges.filter { $0.status == .active }.count),"streak":\#(bestStreak)}"#
    }

    private func blockedAppsJSON() -> String {
        let blocked = TeamFocusService.shared.sharedAllowlists.flatMap(\.blockedSites)
        let rows = blocked.map { "\"\(escape($0))\"" }
        return "[\(rows.joined(separator: ","))]"
    }

    private func scheduleJSON() -> String {
        let active = TeamFocusService.shared.teamSessions.filter { $0.status == .active }
        let rows = active.map {
            #"{"id":"\#($0.id)","starts":"\#(ISO8601DateFormatter().string(from: $0.startTime))","duration":\#(Int($0.duration)),"participants":\#($0.participants.count)}"#
        }
        return #"{"daily":[\#(rows.joined(separator: ","))]}"#
    }

    private func jsonObject(from body: String) -> [String: Any]? {
        guard let data = body.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return object
    }

    private func escape(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}

// MARK: - Dust R15: iOS Companion Stub

final class DustiOSService: ObservableObject {
    static let shared = DustiOSService()
    @Published var currentSession: String = "none"
    @Published var todayFocusTime: TimeInterval = 0
    @Published var widgetData: [String: Any] = [:]

    private init() {}

    func refreshWidget() {
        widgetData = [
            "session": currentSession,
            "todaySeconds": todayFocusTime,
            "streak": 0,
            "status": "idle"
        ]
    }
}
