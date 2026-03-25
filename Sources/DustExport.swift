import Foundation

struct DustExport: Codable {
    let version: String
    let exportDate: Date
    let exclusionPatterns: [ExclusionPattern]
}

final class DustExportManager {
    static let shared = DustExportManager()

    private init() {}

    func exportToJSON() -> Data? {
        let export = DustExport(
            version: "R10",
            exportDate: Date(),
            exclusionPatterns: ExclusionManager.shared.fetchPatterns()
        )

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            return try encoder.encode(export)
        } catch {
            print("Failed to encode export: \(error)")
            return nil
        }
    }

    func importFrom(_ data: Data) -> Bool {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let export = try decoder.decode(DustExport.self, from: data)

            for pattern in export.exclusionPatterns {
                ExclusionManager.shared.savePattern(pattern)
            }

            return true
        } catch {
            print("Failed to import: \(error)")
            return false
        }
    }

    func saveExportToFile() -> URL? {
        guard let data = exportToJSON() else { return nil }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let fileName = "Dust-Backup-\(dateFormatter.string(from: Date())).json"

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to write export file: \(error)")
            return nil
        }
    }
}
