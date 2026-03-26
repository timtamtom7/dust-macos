import SwiftUI

// MARK: - Dust Vision OS App (R20)

@available(visionOS 1.0, *)
struct DustVisionOSApp: App {
    var body: some Scene {
        WindowGroup {
            SpatialFocusView()
                .preferredColorScheme(.dark)
        }
    }
}

struct SpatialFocusView: View {
    @StateObject private var focusStore = DustVisionStore()

    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Header
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 28))
                        .foregroundColor(.cyan)
                    Text("Dust")
                        .font(.system(size: 32, weight: .bold))
                    Spacer()
                    if focusStore.isActive {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                            Text("FOCUSING")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.horizontal, 40)

                // Main focus area
                HStack(spacing: 40) {
                    // Left: Timer
                    VStack(spacing: 16) {
                        Text(focusStore.isActive ? "\(focusStore.remainingMinutes)" : "00")
                            .font(.system(size: 120, weight: .bold, design: .rounded))
                            .foregroundColor(focusStore.isActive ? .white : .gray)

                        Text(focusStore.isActive ? "MINUTES LEFT" : "READY TO FOCUS")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)

                        if !focusStore.isActive {
                            Button(action: { focusStore.startSession() }) {
                                Text("START FOCUS")
                                    .font(.system(size: 18, weight: .bold))
                                    .padding(.horizontal, 40)
                                    .padding(.vertical, 16)
                                    .background(Color.cyan)
                                    .foregroundColor(.black)
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .frame(width: 400)

                    // Right: Stats
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Today's Progress")
                            .font(.system(size: 20, weight: .semibold))

                        ForEach(focusStore.stats) { stat in
                            HStack {
                                Image(systemName: stat.icon)
                                    .foregroundColor(stat.color)
                                    .frame(width: 24)
                                VStack(alignment: .leading) {
                                    Text(stat.title)
                                        .font(.system(size: 14))
                                    Text(stat.value)
                                        .font(.system(size: 20, weight: .bold))
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                        }

                        Spacer()
                    }
                    .frame(width: 300)
                }
                .padding(.horizontal, 40)

                Spacer()

                // Bottom: streak
                HStack(spacing: 40) {
                    ForEach(focusStore.weeklyData, id: \.day) { day in
                        VStack(spacing: 8) {
                            Text(day.day)
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            Circle()
                                .fill(day.minutes > 0 ? Color.cyan : Color.gray.opacity(0.3))
                                .frame(width: 12, height: 12)
                            Text("\(day.minutes)m")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 32)
            }
            .padding(.vertical, 32)
        }
    }
}

@MainActor
class DustVisionStore: ObservableObject {
    @Published var isActive: Bool = false
    @Published var remainingMinutes: Int = 25
    @Published var stats: [FocusStat] = []
    @Published var weeklyData: [DayData] = []

    struct FocusStat: Identifiable {
        let id = UUID()
        let title: String
        let value: String
        let icon: String
        let color: Color
    }

    struct DayData {
        let day: String
        let minutes: Int
    }

    init() {
        loadData()
    }

    func loadData() {
        stats = [
            FocusStat(title: "Minutes Focused", value: "67", icon: "clock.fill", color: .cyan),
            FocusStat(title: "Sessions", value: "3", icon: "checkmark.circle.fill", color: .green),
            FocusStat(title: "Day Streak", value: "5", icon: "flame.fill", color: .orange)
        ]
        weeklyData = [
            DayData(day: "Mon", minutes: 45),
            DayData(day: "Tue", minutes: 30),
            DayData(day: "Wed", minutes: 60),
            DayData(day: "Thu", minutes: 0),
            DayData(day: "Fri", minutes: 67),
            DayData(day: "Sat", minutes: 0),
            DayData(day: "Sun", minutes: 0)
        ]
    }

    func startSession() {
        isActive = true
        remainingMinutes = 25
    }
}
