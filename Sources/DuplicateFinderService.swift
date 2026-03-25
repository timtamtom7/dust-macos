import Foundation
import CryptoKit

// MARK: - Models
struct FileItem: Identifiable, Hashable, Codable {
    let id: UUID
    let path: String
    let name: String
    let size: Int64
    let modificationDate: Date
    var hash: String?
    var isSelected: Bool = false

    var url: URL { URL(fileURLWithPath: path) }
    var formattedSize: String { ByteCountFormatter.string(fromByteCount: size, countStyle: .file) }
}

struct DuplicateGroup: Identifiable, Codable {
    let id: UUID
    let files: [FileItem]
    var totalWastedSpace: Int64

    var formattedWastedSpace: String {
        ByteCountFormatter.string(fromByteCount: totalWastedSpace, countStyle: .file)
    }
}

// MARK: - Exclusion Patterns
struct ExclusionPatterns {
    static let skipNames: Set<String> = [
        ".DS_Store", "Thumbs.db", ".git", "node_modules",
        ".Spotlight-V100", ".Trashes", ".fseventsd"
    ]

    static func shouldExclude(_ name: String) -> Bool {
        skipNames.contains(name) || name.hasPrefix(".")
    }
}

// MARK: - DuplicateFinderService
actor DuplicateFinderService {
    private let minFileSize: Int64 = 1024 // 1KB default
    private var isCancelled = false

    // Progress callback: (current, total, currentFileName)
    typealias ProgressHandler = @Sendable (Int, Int, String) -> Void
    private var progressHandler: ProgressHandler?

    func setProgressHandler(_ handler: @escaping ProgressHandler) {
        self.progressHandler = handler
    }

    func cancel() {
        isCancelled = true
    }

    func findDuplicates(in urls: [URL]) async -> [DuplicateGroup] {
        isCancelled = false

        // Step 1: Collect all files, grouped by size
        let allFiles = await collectFiles(from: urls)
        let sizeGroups = Dictionary(grouping: allFiles) { $0.size }

        // Filter to only sizes with 2+ files
        let potentialDuplicates = sizeGroups.filter { $0.value.count > 1 }
        let totalToHash = potentialDuplicates.values.reduce(0) { $0 + $1.count }

        if totalToHash == 0 {
            return []
        }

        // Step 2: Hash files with same size
        var hashedFiles: [[FileItem]] = []
        var processed = 0

        for (_, files) in potentialDuplicates {
            if isCancelled { return [] }

            let hashed = await hashFiles(files) { current, name in
                processed += 1
                self.progressHandler?(processed, totalToHash, name)
            }
            hashedFiles.append(hashed)
        }

        // Step 3: Group by hash
        var result: [DuplicateGroup] = []
        for group in hashedFiles {
            let hashGroups = Dictionary(grouping: group) { $0.hash ?? "" }
            for (_, items) in hashGroups where items.count > 1 {
                let wastedSpace = items.dropFirst().reduce(0) { $0 + $1.size }
                result.append(DuplicateGroup(
                    id: UUID(),
                    files: items.sorted { $0.modificationDate < $1.modificationDate },
                    totalWastedSpace: wastedSpace
                ))
            }
        }

        return result.sorted { $0.totalWastedSpace > $1.totalWastedSpace }
    }

    private func collectFiles(from urls: [URL]) async -> [FileItem] {
        var files: [FileItem] = []
        let fm = FileManager.default

        for url in urls {
            guard let enumerator = fm.enumerator(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }

            for case let fileURL as URL in enumerator {
                if isCancelled { return files }

                let name = fileURL.lastPathComponent
                if ExclusionPatterns.shouldExclude(name) { continue }

                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey])
                    guard resourceValues.isRegularFile == true else { continue }
                    guard let size = resourceValues.fileSize, size >= minFileSize else { continue }
                    let modDate = resourceValues.contentModificationDate ?? Date.distantPast

                    files.append(FileItem(
                        id: UUID(),
                        path: fileURL.path,
                        name: name,
                        size: Int64(size),
                        modificationDate: modDate
                    ))
                } catch {
                    continue
                }
            }
        }

        return files
    }

    private func hashFiles(_ files: [FileItem], onProgress: @escaping (Int, String) -> Void) async -> [FileItem] {
        var results: [FileItem] = []

        for (index, file) in files.enumerated() {
            if isCancelled { return results }

            onProgress(index + 1, file.name)

            guard let hash = await computeHash(for: file.url) else { continue }
            var updated = file
            updated.hash = hash
            results.append(updated)
        }

        return results
    }

    private func computeHash(for url: URL) async -> String? {
        let bufferSize = 64 * 1024 // 64KB buffer for better performance

        do {
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }

            var hasher = SHA256()
            let chunk = try handle.read(upToCount: bufferSize) ?? Data()
            hasher.update(data: chunk)

            // If file is small enough, read the rest
            if try handle.read(upToCount: 1) == nil {
                let digest = hasher.finalize()
                return digest.map { String(format: "%02x", $0) }.joined()
            }

            // For larger files, read the rest
            while let data = try handle.read(upToCount: bufferSize) {
                hasher.update(data: data)
            }

            let digest = hasher.finalize()
            return digest.map { String(format: "%02x", $0) }.joined()
        } catch {
            return nil
        }
    }
}
