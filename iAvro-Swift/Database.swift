import Foundation
import SQLite3

class Database {
    static let shared = Database()

    private var db: [String: [String]] = [:]
    private var suffixMap: [String: String] = [:]

    private init() {
        guard let filePath = Bundle.main.path(forResource: "database", ofType: "db3") else {
            return
        }

        var dbPtr: OpaquePointer?
        guard sqlite3_open(filePath, &dbPtr) == SQLITE_OK, let db = dbPtr else {
            return
        }
        defer { sqlite3_close(db) }

        let tableNames = [
            "A", "AA", "B", "BH", "C", "CH", "D", "Dd", "Ddh", "Dh", "E", "G", "Gh",
            "H", "I", "II", "J", "JH", "K", "KH", "Khandatta", "L", "M", "N", "NGA",
            "NN", "NYA", "O", "OI", "OU", "P", "PH", "R", "RR", "RRH", "RRI", "S",
            "SH", "SS", "T", "TH", "TT", "TTH", "U", "UU", "Y", "Z"
        ]

        for name in tableNames {
            self.db[name.lowercased()] = loadTable(name: name, from: db)
        }

        loadSuffixTable(from: db)
    }

    private func loadTable(name: String, from dbPtr: OpaquePointer) -> [String] {
        var items: [String] = []
        let query = "SELECT * FROM \(name)"
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(dbPtr, query, -1, &statement, nil) == SQLITE_OK else {
            return items
        }

        while sqlite3_step(statement) == SQLITE_ROW {
            if let text = sqlite3_column_text(statement, 0) {
                items.append(String(cString: text))
            }
        }
        sqlite3_finalize(statement)
        return items
    }

    private func loadSuffixTable(from dbPtr: OpaquePointer) {
        var statement: OpaquePointer?
        let query = "SELECT * FROM Suffix"

        guard sqlite3_prepare_v2(dbPtr, query, -1, &statement, nil) == SQLITE_OK else {
            return
        }

        while sqlite3_step(statement) == SQLITE_ROW {
            if let english = sqlite3_column_text(statement, 0),
               let bangla = sqlite3_column_text(statement, 1) {
                suffixMap[String(cString: english)] = String(cString: bangla)
            }
        }
        sqlite3_finalize(statement)
    }

    func find(_ term: String) -> [String] {
        let lower = term.lowercased()
        guard let firstChar = lower.first else { return [] }
        let lmc = firstChar

        let regexStr = "^" + RegexParser.shared.parse(term) + "$"
        var tableList: [String] = []

        switch lmc {
        case "a": tableList = ["a", "aa", "e", "oi", "o", "nya", "y"]
        case "b": tableList = ["b", "bh"]
        case "c": tableList = ["c", "ch", "k"]
        case "d": tableList = ["d", "dh", "dd", "ddh"]
        case "e": tableList = ["i", "ii", "e", "y"]
        case "f": tableList = ["ph"]
        case "g": tableList = ["g", "gh", "j"]
        case "h": tableList = ["h"]
        case "i": tableList = ["i", "ii", "y"]
        case "j": tableList = ["j", "jh", "z"]
        case "k": tableList = ["k", "kh"]
        case "l": tableList = ["l"]
        case "m": tableList = ["h", "m"]
        case "n": tableList = ["n", "nya", "nga", "nn"]
        case "o": tableList = ["a", "u", "uu", "oi", "o", "ou", "y"]
        case "p": tableList = ["p", "ph"]
        case "q": tableList = ["k"]
        case "r": tableList = ["rri", "h", "r", "rr", "rrh"]
        case "s": tableList = ["s", "sh", "ss"]
        case "t": tableList = ["t", "th", "tt", "tth", "khandatta"]
        case "u": tableList = ["u", "uu", "y"]
        case "v": tableList = ["bh"]
        case "w": tableList = ["o"]
        case "x": tableList = ["e", "k"]
        case "y": tableList = ["i", "y"]
        case "z": tableList = ["h", "j", "jh", "z"]
        default: break
        }

        var suggestions = Set<String>()

        guard let compiledRegex = try? NSRegularExpression(pattern: regexStr) else {
            return []
        }

        for table in tableList {
            guard let tableData = db[table] else { continue }
            for tmpString in tableData {
                let nsRange = NSRange(tmpString.startIndex..., in: tmpString)
                if compiledRegex.firstMatch(in: tmpString, range: nsRange) != nil {
                    suggestions.insert(tmpString)
                }
            }
        }

        return Array(suggestions)
    }

    func banglaForSuffix(_ suffixStr: String) -> String? {
        return suffixMap[suffixStr.lowercased()]
    }
}
