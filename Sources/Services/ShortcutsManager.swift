import AppIntents
import Foundation

// MARK: - App Shortcuts Provider

struct DustShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ScanForDuplicatesIntent(),
            phrases: [
                "Scan for duplicates in \(.applicationName)",
                "Find duplicates with \(.applicationName)"
            ],
            shortTitle: "Find Duplicates",
            systemImageName: "doc.on.doc"
        )

        AppShortcut(
            intent: GetLastScanResultIntent(),
            phrases: [
                "Get \(.applicationName) last scan",
                "Last duplicate scan in \(.applicationName)"
            ],
            shortTitle: "Last Scan",
            systemImageName: "clock"
        )
    }
}

// MARK: - Scan For Duplicates Intent

struct ScanForDuplicatesIntent: AppIntent {
    static var title: LocalizedStringResource = "Scan for Duplicates"
    static var description = IntentDescription("Starts a duplicate file scan in Dust")

    @Parameter(title: "Directory Path")
    var directoryPath: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Scan \(\.$directoryPath) for duplicates")
    }

    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        // The scan would need to be triggered through the app
        // For now, just open the app
        return .result(dialog: "Opening Dust to scan for duplicates")
    }
}

// MARK: - Get Last Scan Result Intent

struct GetLastScanResultIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Last Scan Result"
    static var description = IntentDescription("Returns the result of the most recent duplicate scan")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let duplicateGroups = await DustState.shared.viewModel?.duplicateGroups ?? []

        if duplicateGroups.isEmpty {
            return .result(dialog: "No previous scan found. Run a scan first.")
        }

        let groupCount = duplicateGroups.count
        let totalDuplicates = duplicateGroups.reduce(0) { $0 + $1.files.count - 1 }
        let wastedSpace = duplicateGroups.reduce(0) { $0 + $1.totalWastedSpace }

        let spaceStr = ByteCountFormatter.string(fromByteCount: wastedSpace, countStyle: .file)
        return .result(dialog: "Last scan: \(groupCount) duplicate groups, \(totalDuplicates) duplicate files, \(spaceStr) wasted space")
    }
}
