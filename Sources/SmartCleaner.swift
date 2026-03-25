import Foundation

struct LargeFile: Identifiable {
    let id = UUID()
    let path: String
    let name: String
    let size: UInt64
    let modified: Date
}

final class SmartCleaner {
    static let shared = SmartCleaner()

    private init() {}

    func findLargeFiles(at url: URL, limit: Int = 50, minSize: UInt64 = 100_000_000) -> [LargeFile] {
        var files: [LargeFile] = []

        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey], options: [.skipsHiddenFiles]) else {
            return files
        }

        while let fileURL = enumerator.nextObject() as? URL {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                if let size = attributes[.size] as? UInt64, size >= minSize {
                    let modDate = attributes[.modificationDate] as? Date ?? Date()
                    files.append(LargeFile(
                        path: fileURL.path,
                        name: fileURL.lastPathComponent,
                        size: size,
                        modified: modDate
                    ))
                }
            } catch {
                continue
            }

            if files.count >= limit * 2 {
                break
            }
        }

        return Array(files.sorted { $0.size > $1.size }.prefix(limit))
    }

    func findDuplicateFiles(at url: URL) -> [[URL]] {
        var hashes: [String: [URL]] = [:]

        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles]) else {
            return []
        }

        while let fileURL = enumerator.nextObject() as? URL {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                if let size = attributes[.size] as? UInt64, size > 0 {
                    if size < 10_000_000 { // Skip files > 10MB for duplicate checking
                        let hash = hashFile(at: fileURL)
                        hashes[hash, default: []].append(fileURL)
                    }
                }
            } catch {
                continue
            }
        }

        return hashes.values.filter { $0.count > 1 }
    }

    private func hashFile(at url: URL) -> String {
        // Simple size-based hash for duplicate detection
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let size = attributes[.size] as? UInt64 {
                return "\(size)-\(url.lastPathComponent)"
            }
        } catch {}
        return ""
    }

    func getCacheFolders() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return [
            home.appendingPathComponent("Library/Caches"),
            home.appendingPathComponent("Library/Logs"),
            home.appendingPathComponent(".Trash"),
        ]
    }
}
