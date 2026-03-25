import Foundation

@MainActor
final class DustSyncManager: ObservableObject {
    static let shared = DustSyncManager()

    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSynced: Date?

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case synced
        case offline
        case error(String)
    }

    private let store = NSUbiquitousKeyValueStore.default
    private var observers: [NSObjectProtocol] = []

    private init() {
        setupObservers()
    }

    private func setupObservers() {
        let notification = NSUbiquitousKeyValueStore.didChangeExternallyNotification
        let observer = NotificationCenter.default.addObserver(
            forName: notification,
            object: store,
            queue: .main
        ) { [weak self] _ in
            self?.handleExternalChange()
        }
        observers.append(observer)
    }

    // MARK: - Sync Data

    struct SyncPayload: Codable {
        var scanHistory: [ScanResult]
        var settings: DustSettings

        struct DustSettings: Codable {
            var skipHidden: Bool
            var followSymlinks: Bool
            var minFileSizeBytes: Int64
        }
    }

    func sync() {
        guard isICloudAvailable else {
            syncStatus = .offline
            return
        }

        syncStatus = .syncing

        do {
            let payload = buildPayload()
            let data = try JSONEncoder().encode(payload)
            store.set(data, forKey: "dust.sync.data")
            store.synchronize()

            syncStatus = .synced
            lastSynced = Date()
        } catch {
            syncStatus = .error(error.localizedDescription)
        }
    }

    func pullFromCloud() {
        guard isICloudAvailable else { return }

        guard let data = store.data(forKey: "dust.sync.data"),
              let payload = try? JSONDecoder().decode(SyncPayload.self, from: data) else {
            return
        }

        applyPayload(payload)
    }

    private func buildPayload() -> SyncPayload {
        let settings = SyncPayload.DustSettings(
            skipHidden: UserDefaults.standard.bool(forKey: "dust_skipHidden"),
            followSymlinks: UserDefaults.standard.bool(forKey: "dust_followSymlinks"),
            minFileSizeBytes: Int64(UserDefaults.standard.integer(forKey: "dust_minFileSize"))
        )

        return SyncPayload(
            scanHistory: DustState.shared.history ?? [],
            settings: settings
        )
    }

    private func applyPayload(_ payload: SyncPayload) {
        DustState.shared.history = payload.scanHistory

        UserDefaults.standard.set(payload.settings.skipHidden, forKey: "dust_skipHidden")
        UserDefaults.standard.set(payload.settings.followSymlinks, forKey: "dust_followSymlinks")
        UserDefaults.standard.set(Int(payload.settings.minFileSizeBytes), forKey: "dust_minFileSize")
    }

    private func handleExternalChange() {
        pullFromCloud()
        syncStatus = .synced
        lastSynced = Date()
    }

    var isICloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    func syncNow() {
        sync()
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}
