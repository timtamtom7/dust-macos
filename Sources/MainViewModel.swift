import SwiftUI
import AppKit

// MARK: - FolderItem
struct FolderItem: Identifiable, Hashable {
    let id: UUID
    let url: URL
    let name: String

    init(url: URL) {
        self.id = UUID()
        self.url = url
        self.name = url.lastPathComponent
    }

    var path: String { url.path }
}

// MARK: - MainViewModel
@MainActor
class MainViewModel: ObservableObject {
    @Published var selectedFolders: [FolderItem] = []
    @Published var duplicateGroups: [DuplicateGroup] = []
    @Published var isScanning = false
    @Published var progressMessage = ""
    @Published var showTrashConfirmation = false
    @Published var minFileSize: Int64 = 1024

    private let finderService = DuplicateFinderService()
    private let historyStore = ScanHistoryStore()
    private var selectedFileItems: Set<UUID> = []

    var totalSpaceRecovered: String {
        "0 bytes"
    }

    var selectedCount: Int {
        selectedFileItems.count
    }

    func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.message = "Select folders to scan for duplicates"

        if panel.runModal() == .OK {
            for url in panel.urls {
                let folder = FolderItem(url: url)
                if !selectedFolders.contains(where: { $0.path == folder.path }) {
                    selectedFolders.append(folder)
                }
            }
        }
    }

    func removeFolder(_ folder: FolderItem) {
        selectedFolders.removeAll { $0.id == folder.id }
    }

    func quickScan(_ preset: ScanPreset) {
        guard let url = preset.url else { return }
        let folder = FolderItem(url: url)
        if !selectedFolders.contains(where: { $0.path == folder.path }) {
            selectedFolders.append(folder)
        }
        startScan()
    }

    func startScan() {
        guard !selectedFolders.isEmpty else { return }

        isScanning = true
        progressMessage = "Preparing..."
        duplicateGroups = []
        selectedFileItems.removeAll()

        Task {
            let urls = selectedFolders.map { $0.url }

            await finderService.setProgressHandler { [weak self] current, total, name in
                Task { @MainActor in
                    self?.progressMessage = "\(current)/\(total): \(name)"
                }
            }

            let groups = await finderService.findDuplicates(in: urls)

            await MainActor.run {
                self.duplicateGroups = groups
                self.isScanning = false
                self.progressMessage = ""

                // Save to history
                for folder in self.selectedFolders {
                    self.historyStore.addRecord(
                        folderPath: folder.path,
                        duplicatesFound: groups.reduce(0) { $0 + $1.files.count },
                        spaceRecovered: groups.reduce(0) { $0 + $1.totalWastedSpace },
                        fileCount: groups.reduce(0) { $0 + $1.files.count }
                    )
                }
            }
        }
    }

    func selectExceptOldest(in group: DuplicateGroup) {
        guard let oldest = group.files.first else { return }
        for file in group.files where file.id != oldest.id {
            selectedFileItems.insert(file.id)
        }
    }

    func selectExceptNewest(in group: DuplicateGroup) {
        guard let newest = group.files.last else { return }
        for file in group.files where file.id != newest.id {
            selectedFileItems.insert(file.id)
        }
    }

    func trashSelected() {
        showTrashConfirmation = true
    }

    func confirmTrash() {
        var spaceRecovered: Int64 = 0

        for group in duplicateGroups {
            for file in group.files {
                if selectedFileItems.contains(file.id) {
                    let url = URL(fileURLWithPath: file.path)
                    do {
                        try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                        spaceRecovered += file.size
                    } catch {
                        print("Failed to trash \(file.path): \(error)")
                    }
                }
            }
        }

        // Remove trashed files from groups
        duplicateGroups = duplicateGroups.compactMap { group in
            let remaining = group.files.filter { !selectedFileItems.contains($0.id) }
            if remaining.count < 2 {
                return nil
            }
            let wastedSpace = remaining.dropFirst().reduce(0) { $0 + $1.size }
            return DuplicateGroup(id: group.id, files: remaining, totalWastedSpace: wastedSpace)
        }

        selectedFileItems.removeAll()
    }
}

// MARK: - ScanStore (for Popover)
@MainActor
class ScanStore: ObservableObject {
    @Published var isScanning = false
    @Published var progressMessage: String?
    @Published var lastScanDate: Date?

    private let finderService = DuplicateFinderService()
    private let historyStore = ScanHistoryStore()

    init() {
        let records = historyStore.getRecentRecords(limit: 1)
        lastScanDate = records.first?.date
    }

    func quickScan(_ preset: ScanPreset) {
        guard let url = preset.url else { return }

        isScanning = true
        progressMessage = "Scanning \(preset)..."

        Task {
            _ = await finderService.findDuplicates(in: [url])

            await MainActor.run {
                self.isScanning = false
                self.progressMessage = nil
                self.lastScanDate = Date()
            }
        }
    }
}
