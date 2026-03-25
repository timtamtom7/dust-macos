import Foundation
import AppKit

final class ExportReportService {
    static let shared = ExportReportService()

    private init() {}

    // MARK: - Export Report

    struct ExportReport: Codable {
        let generatedAt: Date
        let scanDirectory: String
        let totalFilesScanned: Int
        let duplicateGroups: [ExportGroup]
        let totalWastedSpace: Int64
        let scanDuration: TimeInterval

        struct ExportGroup: Codable {
            let size: Int64
            let fileCount: Int
            let files: [ExportFile]
            let wastedSpace: Int64
        }

        struct ExportFile: Codable {
            let path: String
            let modifiedDate: Date
        }
    }

    func exportToJSON(_ scanResult: ScanResult, directory: String) throws -> Data {
        let groups = scanResult.duplicateGroups.map { group in
            ExportReport.ExportGroup(
                size: group.files.first?.size ?? 0,
                fileCount: group.files.count,
                files: group.files.map { file in
                    ExportReport.ExportFile(path: file.path, modifiedDate: file.modificationDate)
                },
                wastedSpace: group.totalWastedSpace
            )
        }

        let report = ExportReport(
            generatedAt: Date(),
            scanDirectory: directory,
            totalFilesScanned: scanResult.totalFilesScanned,
            duplicateGroups: groups,
            totalWastedSpace: scanResult.totalWastedSpace,
            scanDuration: scanResult.scanDuration
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(report)
    }

    func exportToCSV(_ scanResult: ScanResult) -> Data {
        var lines: [String] = []

        // Header
        lines.append("Group Size,File Count,Wasted Space,File Path,Modified Date")

        for group in scanResult.duplicateGroups {
            let sizeStr = ByteCountFormatter.string(fromByteCount: group.files.first?.size ?? 0, countStyle: .file)
            let wastedStr = ByteCountFormatter.string(fromByteCount: group.totalWastedSpace, countStyle: .file)
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .none

            for file in group.files {
                let modified = dateFormatter.string(from: file.modificationDate)
                let escapedPath = escapeCSV(file.path)
                lines.append("\(sizeStr),\(group.files.count),\(wastedStr),\(escapedPath),\(modified)")
            }
            lines.append("")  // Blank line between groups
        }

        return (lines.joined(separator: "\n")).data(using: .utf8) ?? Data()
    }

    private func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            let escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return string
    }

    // MARK: - Save to File

    func saveReport(_ scanResult: ScanResult, directory: String, format: ExportFormat) throws -> URL {
        let data: Data
        let fileName: String

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateStr = dateFormatter.string(from: Date())

        switch format {
        case .json:
            data = try exportToJSON(scanResult, directory: directory)
            fileName = "Dust-Report-\(dateStr).json"
        case .csv:
            data = exportToCSV(scanResult)
            fileName = "Dust-Report-\(dateStr).csv"
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        try data.write(to: fileURL)
        return fileURL
    }

    enum ExportFormat {
        case json
        case csv
    }
}
