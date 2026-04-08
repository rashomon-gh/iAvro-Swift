import Foundation

/// Converts Romanized (English) text into Bangla using phonetic patterns loaded from `data.json`.
///
/// The parser uses a longest-match-first strategy with binary search over a sorted pattern table.
/// Each pattern may have conditional rules that inspect surrounding characters (prefix/suffix)
/// before deciding which replacement to apply.
class AvroParser: BaseParser {
    static let shared = AvroParser()

    // AvroParser includes 'number' set which is not in BaseParser
    private var number: Set<Character> = []

    private init() {
        super.init(jsonFileName: "data")
        // Load number set separately since it's not in BaseParser
        guard let filePath = Bundle.main.path(forResource: "data", ofType: "json"),
              let jsonData = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
              let json = try? JSONDecoder().decode(JSONDataWithNumber.self, from: jsonData) else {
            return
        }
        number = Set(json.number)
    }

    /// Normalizes the input string by lowercasing all characters except those in the case-sensitive set.
    ///
    /// - Parameter string: The raw input string.
    /// - Returns: The normalized string ready for pattern matching.
    func fix(_ string: String) -> String {
        return clean(string)
    }

    /// Returns whether the character is a digit (AvroParser-specific).
    func isNumber(_ c: Character) -> Bool {
        return inSet(number, c: c)
    }
}

// MARK: - Optimized Codable Models

/// Root JSON structure for data.json (includes number field)
private struct JSONDataWithNumber: Decodable {
    let vowel: String
    let consonant: String
    let number: String
    let casesensitive: String
    let patterns: [Pattern]

    enum CodingKeys: String, CodingKey {
        case vowel, consonant, number
        case casesensitive
        case patterns
    }
}

