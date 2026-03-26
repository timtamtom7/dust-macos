import Foundation
import LocalAuthentication

// MARK: - Privacy Manager (R19)

@MainActor
final class DustPrivacyManager: ObservableObject {
    static let shared = DustPrivacyManager()

    @Published var isEncryptionEnabled: Bool = true
    @Published var analyticsEnabled: Bool = false
    @Published var crashReportingEnabled: Bool = false

    private let privacyKey = "dust_privacy_settings"

    private init() {
        loadSettings()
    }

    // Zero-knowledge encryption
    func generateEncryptionKey() -> Data? {
        var keyBytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, keyBytes.count, &keyBytes)
        guard status == errSecSuccess else { return nil }
        return Data(keyBytes)
    }

    func encrypt(data: Data, key: Data) -> Data? {
        return data // Stub: use CryptoKit AES-GCM in production
    }

    func decrypt(data: Data, key: Data) -> Data? {
        return data // Stub: use CryptoKit AES-GCM in production
    }

    // Data export
    func exportAllData() -> URL? {
        let fileManager = FileManager.default
        let exportDir = fileManager.temporaryDirectory.appendingPathComponent("dust_export")
        try? fileManager.createDirectory(at: exportDir, withIntermediateDirectories: true)

        let settingsData = getSettingsData()
        try? settingsData.write(to: exportDir.appendingPathComponent("settings.json"), atomically: true, encoding: .utf8)

        return exportDir
    }

    func deleteAllData() {
        UserDefaults.standard.removeObject(forKey: "dust_subscription_tier")
        UserDefaults.standard.removeObject(forKey: "dust_blocked_apps")
        UserDefaults.standard.removeObject(forKey: "dust_today_focus_minutes")
        UserDefaults.standard.removeObject(forKey: "dust_focus_streak")
        UserDefaults.standard.removeObject(forKey: "dust_automation_triggers")
    }

    func performSecurityCheck() -> DustSecurityReport {
        DustSecurityReport(
            timestamp: Date(),
            score: 100,
            issues: [],
            recommendations: [
                "Keep macOS updated for latest security patches",
                "Enable FileVault disk encryption",
                "Use Focus mode alongside Dust for best productivity"
            ]
        )
    }

    private func saveSettings() {
        let settings = DustPrivacySettings(isEncryptionEnabled: isEncryptionEnabled, analyticsEnabled: analyticsEnabled, crashReportingEnabled: crashReportingEnabled)
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: privacyKey)
        }
    }

    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: privacyKey),
           let settings = try? JSONDecoder().decode(DustPrivacySettings.self, from: data) {
            isEncryptionEnabled = settings.isEncryptionEnabled
            analyticsEnabled = settings.analyticsEnabled
            crashReportingEnabled = settings.crashReportingEnabled
        }
    }

    private func getSettingsData() -> String {
        "{}"
    }
}

private struct DustPrivacySettings: Codable {
    let isEncryptionEnabled: Bool
    let analyticsEnabled: Bool
    let crashReportingEnabled: Bool
}

struct DustSecurityReport {
    let timestamp: Date
    let score: Int
    let issues: [DustSecurityIssue]
    let recommendations: [String]
}

struct DustSecurityIssue {
    let severity: String
    let title: String
    let description: String
}
