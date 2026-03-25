import Foundation
import CryptoKit

// MARK: - Smart Group

struct SmartGroup: Identifiable, Hashable {
    let id: UUID
    let name: String
    let icon: String
    let filter: (DuplicateGroup) -> Bool
    let sortOrder: Int

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: SmartGroup, rhs: SmartGroup) -> Bool {
        lhs.id == rhs.id
    }

    static let allGroups: [SmartGroup] = [
        SmartGroup(id: UUID(), name: "All Duplicates", icon: "doc.on.doc", filter: { _ in true }, sortOrder: 0),
        SmartGroup(id: UUID(), name: "Large Files (>10MB)", icon: "doc.fill", filter: { $0.files.first?.size ?? 0 > 10_000_000 }, sortOrder: 1),
        SmartGroup(id: UUID(), name: "Images", icon: "photo", filter: { $0.files.first.map { Self.isImage($0.name) } ?? false }, sortOrder: 2),
        SmartGroup(id: UUID(), name: "Videos", icon: "video", filter: { $0.files.first.map { Self.isVideo($0.name) } ?? false }, sortOrder: 3),
        SmartGroup(id: UUID(), name: "Documents", icon: "doc.text", filter: { $0.files.first.map { Self.isDocument($0.name) } ?? false }, sortOrder: 4),
        SmartGroup(id: UUID(), name: "Audio", icon: "music.note", filter: { $0.files.first.map { Self.isAudio($0.name) } ?? false }, sortOrder: 5),
        SmartGroup(id: UUID(), name: "Archives", icon: "doc.zipper", filter: { $0.files.first.map { Self.isArchive($0.name) } ?? false }, sortOrder: 6),
        SmartGroup(id: UUID(), name: "Recent (7 days)", icon: "clock", filter: { ($0.files.first?.modificationDate ?? Date.distantPast) > Date().addingTimeInterval(-7 * 24 * 60 * 60) }, sortOrder: 7),
    ]

    private static func isImage(_ name: String) -> Bool {
        let ext = (name as NSString).pathExtension.lowercased()
        return ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "webp", "heic", "heif", "svg"].contains(ext)
    }

    private static func isVideo(_ name: String) -> Bool {
        let ext = (name as NSString).pathExtension.lowercased()
        return ["mp4", "mov", "avi", "mkv", "wmv", "flv", "webm", "m4v", "mpg", "mpeg"].contains(ext)
    }

    private static func isDocument(_ name: String) -> Bool {
        let ext = (name as NSString).pathExtension.lowercased()
        return ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "rtf", "odt"].contains(ext)
    }

    private static func isAudio(_ name: String) -> Bool {
        let ext = (name as NSString).pathExtension.lowercased()
        return ["mp3", "wav", "aac", "flac", "m4a", "ogg", "wma", "aiff"].contains(ext)
    }

    private static func isArchive(_ name: String) -> Bool {
        let ext = (name as NSString).pathExtension.lowercased()
        return ["zip", "rar", "7z", "tar", "gz", "bz2", "dmg", "pkg"].contains(ext)
    }
}

// MARK: - Cloud Storage Provider

struct CloudStorageProvider: Identifiable, Codable {
    let id: UUID
    var name: String
    var basePath: String
    var isEnabled: Bool

    static let defaultProviders: [CloudStorageProvider] = [
        CloudStorageProvider(id: UUID(), name: "iCloud Drive", basePath: "~/Library/Mobile Documents/com~apple~CloudDocs", isEnabled: false),
        CloudStorageProvider(id: UUID(), name: "Dropbox", basePath: "~/Dropbox", isEnabled: false),
        CloudStorageProvider(id: UUID(), name: "Google Drive", basePath: "~/Library/CloudStorage/GoogleDrive", isEnabled: false),
        CloudStorageProvider(id: UUID(), name: "OneDrive", basePath: "~/Library/CloudStorage/OneDrive", isEnabled: false),
    ]
}

// MARK: - Scan Settings

struct ScanSettings: Codable {
    var minFileSize: Int64 = 1024
    var enabledCloudProviders: [UUID] = []
    var usePartialHash: Bool = false
    var partialHashSize: Int64 = 65_536  // 64KB partial hash
    var skipHiddenFiles: Bool = true
    var skipSystemDirs: Bool = true

    static let `default` = ScanSettings()
}

// MARK: - Partial Hash

struct PartialFileHash {
    let path: String
    let size: Int64
    let partialHash: String  // hash of first N bytes
    var fullHash: String?     // computed later

    static func compute(for url: URL, size: Int64, chunkSize: Int64 = 65_536) async -> PartialFileHash? {
        do {
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }

            let data = try handle.read(upToCount: Int(chunkSize)) ?? Data()
            guard !data.isEmpty else { return nil }

            let hash = SHA256Hash.compute(data)
            return PartialFileHash(path: url.path, size: size, partialHash: hash, fullHash: nil)
        } catch {
            return nil
        }
    }
}

// MARK: - SHA256 Helper

enum SHA256Hash {
    static func compute(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    static func computeFile(at url: URL) async -> String? {
        let bufferSize = 64 * 1024

        do {
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }

            var hasher = SHA256()
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
