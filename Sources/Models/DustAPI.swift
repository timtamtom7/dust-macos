import Foundation
import Network

// MARK: - Dust R14: REST API (port 8772) & Webhooks

final class DustAPIService: ObservableObject {
    static let shared = DustAPIService()

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
        let lines = req.split(separator: "\r\n")
        guard let rl = lines.first else { return HTTPResponse(code: 404, body: #"{"error":"Not found"}"#) }
        let parts = String(rl).split(separator: " ")
        guard parts.count >= 2 else { return HTTPResponse(code: 404, body: #"{"error":"Not found"}"#) }
        let path = String(parts[1])
        guard lines.contains(where: { $0.hasPrefix("X-API-Key:") }) else {
            return HTTPResponse(code: 401, body: #"{"error":"Unauthorized"}"#)
        }
        switch path {
        case "/status": return HTTPResponse(code: 200, body: #"{"focused":false,"sessionStarted":null}"#)
        case "/stats": return HTTPResponse(code: 200, body: #"{"totalFocusToday":0,"streak":0}"#)
        case "/blocked-apps": return HTTPResponse(code: 200, body: "[]")
        case "/schedule": return HTTPResponse(code: 200, body: #"{"daily":[]}"#)
        case "/openapi.json": return HTTPResponse(code: 200, body: openAPISpec())
        default: return HTTPResponse(code: 404, body: #"{"error":"Not found}"#)
        }
    }

    struct HTTPResponse {
        let code: Int
        let body: String
    }

    private func openAPISpec() -> String {
        return #"{"openapi":"3.0.0","info":{"title":"Dust API","version":"1.0"},"paths":{"/status":{"get":{"summary":"Focus status"}},"/stats":{"get":{"summary":"Focus statistics"}},"/blocked-apps":{"get":{"summary":"Blocked apps"}}},"/schedule":{"get":{"summary":"Focus schedule"}}}}"#
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
