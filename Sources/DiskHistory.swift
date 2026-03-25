import Foundation

struct DiskHistoryEntry: Identifiable, Codable {
    let id: UUID
    let usedBytes: UInt64
    let totalBytes: UInt64
    let timestamp: Date
}

final class DiskHistoryManager {
    static let shared = DiskHistoryManager()

    private let historyKey = "diskHistory"
    private let maxEntries = 365

    private init() {}

    func recordSnapshot(usedBytes: UInt64, totalBytes: UInt64) {
        let entry = DiskHistoryEntry(
            id: UUID(),
            usedBytes: usedBytes,
            totalBytes: totalBytes,
            timestamp: Date()
        )

        var history = fetchHistory()
        history.append(entry)

        if history.count > maxEntries {
            history = Array(history.suffix(maxEntries))
        }

        saveHistory(history)
    }

    func fetchHistory() -> [DiskHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return [] }
        do {
            return try JSONDecoder().decode([DiskHistoryEntry].self, from: data)
        } catch {
            return []
        }
    }

    func getUsageTrend(days: Int = 30) -> (used: [Double], dates: [Date]) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let history = fetchHistory().filter { $0.timestamp >= cutoff }

        let used = history.map { Double($0.usedBytes) / 1_000_000_000 }
        let dates = history.map { $0.timestamp }

        return (used, dates)
    }

    private func saveHistory(_ history: [DiskHistoryEntry]) {
        do {
            let data = try JSONEncoder().encode(history)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            print("Failed to save disk history: \(error)")
        }
    }
}
