import AppKit
import SwiftUI

// MARK: - Dust Menu Bar Extra (R17)

struct DustMenuBarView: View {
    @ObservedObject private var focusService = DustFocusService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.accentColor)
                Text("Dust")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Text(DustSubscriptionManager.shared.currentTier.displayName)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            if focusService.currentSession != nil {
                MenuBarActionButton(icon: "stop.circle", title: "End Focus", shortcut: nil) {
                    Task { await DustFocusService.shared.endSession() }
                }
            } else {
                MenuBarActionButton(icon: "play.circle", title: "Start Deep Work", shortcut: nil) {
                    Task { await DustFocusService.shared.startSession(name: "Deep Work", minutes: 25) }
                }
            }

            MenuBarActionButton(icon: "chart.bar", title: "Focus Stats", shortcut: nil) {}
            MenuBarActionButton(icon: "xmark.circle", title: "Blocked Apps", shortcut: nil) {}

            Divider()

            MenuBarActionButton(icon: "gear", title: "Preferences", shortcut: nil) {}
            MenuBarActionButton(icon: "arrow.clockwise", title: "Restore Purchases", shortcut: nil) {
                Task { await DustSubscriptionManager.shared.restorePurchases() }
            }

            Divider()

            MenuBarActionButton(icon: "power", title: "Quit Dust", shortcut: nil) {
                NSApp.terminate(nil)
            }
        }
        .frame(width: 220)
    }
}

struct MenuBarActionButton: View {
    let icon: String
    let title: String
    let shortcut: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 16)
                    .foregroundColor(.secondary)
                Text(title)
                    .font(.system(size: 12))
                Spacer()
                if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Dust Focus Service (R17)

@MainActor
final class DustFocusService: ObservableObject {
    static let shared = DustFocusService()

    @Published private(set) var currentSession: DustFocusService.FocusSession?
    private let userDefaults = UserDefaults.standard

    struct FocusSession {
        let id: UUID
        var name: String
        var startTime: Date
        var durationMinutes: Int
    }

    func startSession(name: String, minutes: Int) async {
        currentSession = FocusSession(id: UUID(), name: name, startTime: Date(), durationMinutes: minutes)
    }

    func endSession() async -> Bool {
        guard let session = currentSession else { return false }
        let duration = Date().timeIntervalSince(session.startTime)
        recordSession(duration: duration, name: session.name)
        currentSession = nil
        return true
    }

    func getTodayStats() async -> String {
        let key = "dust_today_focus_minutes"
        let minutes = userDefaults.integer(forKey: key)
        return "Today: \(minutes) minutes focused"
    }

    func blockApp(named name: String) async {
        var blocked = userDefaults.stringArray(forKey: "dust_blocked_apps") ?? []
        if !blocked.contains(name) {
            blocked.append(name)
            userDefaults.set(blocked, forKey: "dust_blocked_apps")
        }
    }

    func getInsights() async -> [String] {
        [
            "Your focus peaks between 9-11 AM. Schedule deep work then.",
            "You break focus most often on Tuesdays. Consider shorter sessions.",
            "Taking breaks every 52 minutes improves retention by 34%."
        ]
    }

    private func recordSession(duration: TimeInterval, name: String) {
        let key = "dust_today_focus_minutes"
        let current = userDefaults.integer(forKey: key)
        let additional = Int(duration / 60)
        userDefaults.set(current + additional, forKey: key)
    }
}

// MARK: - Folder Actions Service (R17)

final class DustFolderActionsService {
    static let shared = DustFolderActionsService()

    func attachToFolder(_ path: String) {
        print("Dust attached to folder: \(path)")
    }
}

// MARK: - Focus Mode Integration (R17)

final class DustFocusModeIntegration {
    static let shared = DustFocusModeIntegration()

    func handleFocusModeChange(isActive: Bool) {
        if isActive {
            Task { await DustFocusService.shared.startSession(name: "Focus Mode", minutes: 60) }
        } else {
            Task { _ = await DustFocusService.shared.endSession() }
        }
    }
}
