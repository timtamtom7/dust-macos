import AppIntents
import Foundation

// MARK: - Dust App Shortcuts Provider (R17 - Extended)

struct DustShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // Original shortcuts
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

        // R17 Focus shortcuts
        AppShortcut(
            intent: StartFocusSessionIntent(),
            phrases: [
                "Start focus session in \(.applicationName)",
                "Begin deep work with \(.applicationName)"
            ],
            shortTitle: "Start Focus",
            systemImageName: "brain.head.profile"
        )

        AppShortcut(
            intent: EndFocusSessionIntent(),
            phrases: [
                "End focus session in \(.applicationName)",
                "Stop focusing with \(.applicationName)"
            ],
            shortTitle: "End Focus",
            systemImageName: "stop.circle"
        )

        AppShortcut(
            intent: GetFocusStatsIntent(),
            phrases: [
                "Get focus stats in \(.applicationName)",
                "Show my focus stats"
            ],
            shortTitle: "Focus Stats",
            systemImageName: "chart.bar"
        )

        AppShortcut(
            intent: BlockAppIntent(),
            phrases: [
                "Block app in \(.applicationName)",
                "Block app with \(.applicationName)"
            ],
            shortTitle: "Block App",
            systemImageName: "xmark.circle"
        )

        AppShortcut(
            intent: GetFocusInsightsIntent(),
            phrases: [
                "Get focus insights in \(.applicationName)",
                "AI insights with \(.applicationName)"
            ],
            shortTitle: "Focus Insights",
            systemImageName: "lightbulb"
        )
    }
}

// MARK: - Original Dust Intents

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
        return .result(dialog: "Opening Dust to scan for duplicates")
    }
}

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

// MARK: - R17 Focus Intents

struct StartFocusSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Focus Session"
    static var description = IntentDescription("Starts a new focus session in Dust")

    @Parameter(title: "Session Name")
    var sessionName: String?

    @Parameter(title: "Duration (minutes)", default: 25)
    var durationMinutes: Int

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let name = sessionName ?? "Focus Session"
        await DustFocusService.shared.startSession(name: name, minutes: durationMinutes)
        return .result(dialog: "Started \(name) for \(durationMinutes) minutes")
    }
}

struct EndFocusSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "End Focus Session"
    static var description = IntentDescription("Ends the current focus session")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let result = await DustFocusService.shared.endSession()
        return .result(dialog: result ? "Focus session ended" : "No active session")
    }
}

struct GetFocusStatsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Focus Stats"
    static var description = IntentDescription("Returns today's focus statistics")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let stats = await DustFocusService.shared.getTodayStats()
        return .result(value: stats, dialog: "Focus: \(stats)")
    }
}

struct BlockAppIntent: AppIntent {
    static var title: LocalizedStringResource = "Block App"
    static var description = IntentDescription("Adds an app to the blocklist")

    @Parameter(title: "App Name")
    var appName: String

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await DustFocusService.shared.blockApp(named: appName)
        return .result(dialog: "Blocked \(appName)")
    }
}

struct GetFocusInsightsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Focus Insights"
    static var description = IntentDescription("Returns ML-generated focus insights")

    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<[String]> & ProvidesDialog {
        let insights = await DustFocusService.shared.getInsights()
        return .result(value: insights, dialog: IntentDialog(stringLiteral: insights.first ?? "No insights available"))
    }
}
