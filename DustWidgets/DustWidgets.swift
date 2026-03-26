import WidgetKit
import SwiftUI

// MARK: - Focus Timer Entry

struct DustTimerEntry: TimelineEntry {
    let date: Date
    let sessionName: String
    let remainingMinutes: Int
    let isActive: Bool
    let todayMinutes: Int
    let streak: Int
}

struct DustTimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> DustTimerEntry {
        DustTimerEntry(date: Date(), sessionName: "Deep Work", remainingMinutes: 18, isActive: true, todayMinutes: 67, streak: 5)
    }

    func getSnapshot(in context: Context, completion: @escaping (DustTimerEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DustTimerEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> DustTimerEntry {
        let userDefaults = UserDefaults(suiteName: "group.com.dust.shared")
        let isActive = userDefaults?.bool(forKey: "focusSessionActive") ?? false
        let remaining = userDefaults?.integer(forKey: "focusRemainingMinutes") ?? 0
        let sessionName = userDefaults?.string(forKey: "focusSessionName") ?? "Focus"
        let todayMinutes = userDefaults?.integer(forKey: "todayFocusMinutes") ?? 0
        let streak = userDefaults?.integer(forKey: "focusStreak") ?? 0

        return DustTimerEntry(
            date: Date(),
            sessionName: sessionName,
            remainingMinutes: remaining,
            isActive: isActive,
            todayMinutes: todayMinutes,
            streak: streak
        )
    }
}

// MARK: - Timer Widget Views

struct DustTimerWidgetView: View {
    var entry: DustTimerEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.accentColor)
                Text("Dust")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                if entry.isActive {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                }
            }

            Spacer()

            if entry.isActive {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.sessionName)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("\(entry.remainingMinutes)")
                        .font(.system(size: 36, weight: .bold))
                    Text("minutes remaining")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 8) {
                    Text("No active session")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Link(destination: URL(string: "dust://start")!) {
                        Text("Start Focus")
                            .font(.system(size: 12, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding()
        .widgetURL(URL(string: "dust://open")!)
    }
}

struct DustStatsWidgetView: View {
    var entry: DustTimerEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.accentColor)
                Text("Dust Stats")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
            }

            Divider()

            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("\(entry.todayMinutes)")
                        .font(.system(size: 22, weight: .bold))
                    Text("min today")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                VStack(spacing: 2) {
                    Text("\(entry.streak)")
                        .font(.system(size: 22, weight: .bold))
                    Text("day streak")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Link(destination: URL(string: "dust://stats")!) {
                Text("View Dashboard")
                    .font(.system(size: 11, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(6)
            }
        }
        .padding()
    }
}

struct DustBlockingWidgetView: View {
    var entry: DustTimerEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "xmark.circle")
                    .foregroundColor(.red)
                Text("Blocked")
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Text("\(entry.isActive ? 5 : 0) apps")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Divider()

            if entry.isActive {
                Text("Focus mode active — distractions blocked")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            } else {
                Text("Start a focus session to block distractions")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Link(destination: URL(string: "dust://blocking")!) {
                Text("Manage Blocklist")
                    .font(.system(size: 11, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(6)
            }
        }
        .padding()
    }
}

// MARK: - Widget Definitions

struct DustTimerWidget: Widget {
    let kind: String = "DustTimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DustTimerProvider()) { entry in
            DustTimerWidgetView(entry: entry)
        }
        .configurationDisplayName("Focus Timer")
        .description("Live focus session countdown.")
        .supportedFamilies([.systemSmall])
    }
}

struct DustStatsWidget: Widget {
    let kind: String = "DustStatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DustTimerProvider()) { entry in
            DustStatsWidgetView(entry: entry)
        }
        .configurationDisplayName("Focus Stats")
        .description("Today's focus time and streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct DustBlockingWidget: Widget {
    let kind: String = "DustBlockingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DustTimerProvider()) { entry in
            DustBlockingWidgetView(entry: entry)
        }
        .configurationDisplayName("Focus Blocker")
        .description("Blocked apps status.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Widget Bundle

@main
struct DustWidgetBundle: WidgetBundle {
    var body: some Widget {
        DustTimerWidget()
        DustStatsWidget()
        DustBlockingWidget()
    }
}
