import Foundation

// MARK: - Dust R13: Enterprise & IT Features

/// MDM, Policy Enforcement, Compliance, SSO
final class DustEnterpriseService: ObservableObject {
    static let shared = DustEnterpriseService()

    @Published var enrolledDevices: [MDMDevice] = []
    @Published var policies: [FocusPolicy] = []
    @Published var complianceLogs: [ComplianceLog] = []
    @Published var breakSchedule: BreakSchedule?

    struct MDMDevice: Identifiable, Codable {
        let id: String
        var name: String
        var enrolledAt: Date
        var compliance: MDMCompliance
    }

    enum MDMCompliance: String, Codable { case compliant, nonCompliant, notEnrolled }

    struct FocusPolicy: Identifiable, Codable {
        let id: UUID
        var name: String
        var defaultBlocklist: [String]
        var allowedApps: [String]
        var focusHours: FocusHours
        var isLocked: Bool
    }

    struct FocusHours: Codable {
        var startHour: Int
        var endHour: Int
    }

    struct ComplianceLog: Identifiable, Codable {
        let id: UUID
        let deviceId: String
        let event: String
        let timestamp: Date
    }

    struct BreakSchedule: Codable {
        var focusDuration: TimeInterval // seconds
        var breakDuration: TimeInterval // seconds
        var autoStart: Bool
    }

    private init() { loadState() }

    func enrollDevice(id: String, name: String) -> MDMDevice {
        let device = MDMDevice(id: id, name: name, enrolledAt: Date(), compliance: .compliant)
        enrolledDevices.append(device)
        saveState(); return device
    }

    func addPolicy(_ policy: FocusPolicy) {
        policies.append(policy); saveState()
    }

    func logViolation(deviceId: String, detail: String) {
        let log = ComplianceLog(id: UUID(), deviceId: deviceId, event: detail, timestamp: Date())
        complianceLogs.append(log); saveState()
    }

    private var stateURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Dust/enterprise.json")
    }

    func saveState() {
        try? FileManager.default.createDirectory(at: stateURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let state = DustEnterpriseState(enrolledDevices: enrolledDevices, policies: policies, complianceLogs: complianceLogs, breakSchedule: breakSchedule)
        try? JSONEncoder().encode(state).write(to: stateURL)
    }

    func loadState() {
        guard let data = try? Data(contentsOf: stateURL),
              let state = try? JSONDecoder().decode(DustEnterpriseState.self, from: data) else { return }
        enrolledDevices = state.enrolledDevices; policies = state.policies
        complianceLogs = state.complianceLogs; breakSchedule = state.breakSchedule
    }
}

struct DustEnterpriseState: Codable {
    var enrolledDevices: [DustEnterpriseService.MDMDevice]
    var policies: [DustEnterpriseService.FocusPolicy]
    var complianceLogs: [DustEnterpriseService.ComplianceLog]
    var breakSchedule: DustEnterpriseService.BreakSchedule?
}
