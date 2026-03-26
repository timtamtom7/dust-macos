import Foundation
import SQLite3

// MARK: - Scan Record
struct ScanRecord: Identifiable {
    let id: Int64
    let date: Date
    let folderPath: String
    let duplicatesFound: Int
    let spaceRecovered: Int64
    let fileCount: Int
}

// MARK: - ScanHistoryStore
final class ScanHistoryStore {
    private var db: OpaquePointer?
    private let dbPath: String

    init() {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            dbPath = NSTemporaryDirectory() + "dust.sqlite"
            openDatabase()
            createTables()
            return
        }
        let appFolder = appSupport.appendingPathComponent("Dust", isDirectory: true)
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)
        dbPath = appFolder.appendingPathComponent("dust.sqlite").path

        openDatabase()
        createTables()
    }

    deinit {
        if db != nil {
            sqlite3_close_v2(db)
        }
    }

    private func openDatabase() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            db = nil
        }
    }

    private func createTables() {
        let createSQL = """
        CREATE TABLE IF NOT EXISTS scan_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date REAL NOT NULL,
            folder_path TEXT NOT NULL,
            duplicates_found INTEGER NOT NULL,
            space_recovered INTEGER NOT NULL,
            file_count INTEGER NOT NULL
        );
        """
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, createSQL, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }

    func addRecord(folderPath: String, duplicatesFound: Int, spaceRecovered: Int64, fileCount: Int) {
        let sql = "INSERT INTO scan_history (date, folder_path, duplicates_found, space_recovered, file_count) VALUES (?, ?, ?, ?, ?);"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return }

        sqlite3_bind_double(statement, 1, Date().timeIntervalSince1970)
        sqlite3_bind_text(statement, 2, (folderPath as NSString).utf8String, -1, nil)
        sqlite3_bind_int(statement, 3, Int32(duplicatesFound))
        sqlite3_bind_int64(statement, 4, spaceRecovered)
        sqlite3_bind_int(statement, 5, Int32(fileCount))

        sqlite3_step(statement)
        sqlite3_finalize(statement)
    }

    func getRecentRecords(limit: Int = 10) -> [ScanRecord] {
        var records: [ScanRecord] = []
        let sql = "SELECT id, date, folder_path, duplicates_found, space_recovered, file_count FROM scan_history ORDER BY date DESC LIMIT ?;"
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return records }
        sqlite3_bind_int(statement, 1, Int32(limit))

        while sqlite3_step(statement) == SQLITE_ROW {
            let id = sqlite3_column_int64(statement, 0)
            let date = Date(timeIntervalSince1970: sqlite3_column_double(statement, 1))
            let folderPath = String(cString: sqlite3_column_text(statement, 2))
            let duplicatesFound = Int(sqlite3_column_int(statement, 3))
            let spaceRecovered = sqlite3_column_int64(statement, 4)
            let fileCount = Int(sqlite3_column_int(statement, 5))

            records.append(ScanRecord(
                id: id,
                date: date,
                folderPath: folderPath,
                duplicatesFound: duplicatesFound,
                spaceRecovered: spaceRecovered,
                fileCount: fileCount
            ))
        }

        sqlite3_finalize(statement)
        return records
    }

    func deleteRecord(id: Int64) {
        let sql = "DELETE FROM scan_history WHERE id = ?;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return }
        sqlite3_bind_int64(statement, 1, id)
        sqlite3_step(statement)
        sqlite3_finalize(statement)
    }

    func clearAllRecords() {
        let sql = "DELETE FROM scan_history;"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return }
        sqlite3_step(statement)
        sqlite3_finalize(statement)
    }
}
