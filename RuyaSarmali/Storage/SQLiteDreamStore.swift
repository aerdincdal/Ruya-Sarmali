import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

final class SQLiteDreamStore {
    private let db: OpaquePointer?
    private let queue = DispatchQueue(label: "app.ruyasarmali.sqlite")

    init?(databaseName: String = "DreamLogs.sqlite") {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPathComponent(databaseName)
        var handle: OpaquePointer?
        guard let path = url?.path, sqlite3_open(path, &handle) == SQLITE_OK else {
            return nil
        }
        db = handle
        let createSQL = """
        CREATE TABLE IF NOT EXISTS dream_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            prompt TEXT NOT NULL,
            interpretation TEXT,
            remote_url TEXT,
            created_at REAL DEFAULT (strftime('%s','now'))
        );
        """
        if sqlite3_exec(db, createSQL, nil, nil, nil) != SQLITE_OK {
            sqlite3_close(db)
            return nil
        }
    }

    deinit {
        sqlite3_close(db)
    }

    func add(prompt: String, interpretation: String?, remoteURL: URL?) {
        queue.async { [db] in
            guard let db else { return }
            let insertSQL = "INSERT INTO dream_logs (prompt, interpretation, remote_url) VALUES (?,?,?);"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, insertSQL, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, prompt, -1, SQLITE_TRANSIENT)
                if let interpretation {
                    sqlite3_bind_text(statement, 2, interpretation, -1, SQLITE_TRANSIENT)
                } else {
                    sqlite3_bind_null(statement, 2)
                }
                if let remoteURL {
                    sqlite3_bind_text(statement, 3, remoteURL.absoluteString, -1, SQLITE_TRANSIENT)
                } else {
                    sqlite3_bind_null(statement, 3)
                }
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }

    func fetchLatest(limit: Int = 20) -> [DreamLog] {
        var results: [DreamLog] = []
        queue.sync { [db] in
            guard let db else { return }
            let query = "SELECT id, prompt, interpretation, remote_url, created_at FROM dream_logs ORDER BY created_at DESC LIMIT ?;"
            var statement: OpaquePointer?
            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_int(statement, 1, Int32(limit))
                while sqlite3_step(statement) == SQLITE_ROW {
                    let prompt = String(cString: sqlite3_column_text(statement, 1))
                    let interpretation = sqlite3_column_text(statement, 2).flatMap { String(cString: $0) }
                    let remote = sqlite3_column_text(statement, 3).flatMap { String(cString: $0) }
                    let timestamp = sqlite3_column_double(statement, 4)
                    results.append(DreamLog(prompt: prompt, interpretation: interpretation, remoteURL: remote.flatMap(URL.init(string:)), createdAt: Date(timeIntervalSince1970: timestamp)))
                }
            }
            sqlite3_finalize(statement)
        }
        return results
    }
}

struct DreamLog: Identifiable {
    let id = UUID()
    let prompt: String
    let interpretation: String?
    let remoteURL: URL?
    let createdAt: Date
}
