import Foundation

/// Generates a regex pattern string from Romanized input for dictionary lookups.
///
/// Works similarly to `AvroParser` but instead of producing Bangla text, it produces
/// a regular expression pattern that can match Bangla words in the dictionary database.
/// Each replacement is followed by a suffix-capturing group `(্[যবম])?(্?)([ঃঁ]?)`
/// to handle conjunct consonants and diacritical marks.
class RegexParser: BaseParser {
    static let shared = RegexParser()

    private init() {
        super.init(jsonFileName: "regex")
        // Set capacity multiplier to account for regex expansion
        self.capacityMultiplier = 4
    }

    /// Hook for RegexParser to append regex suffix to each replacement.
    override func formatReplacement(_ text: String) -> String {
        return text + "(্[যবম])?(্?)([ঃঁ]?)"
    }
}
