import Foundation

/// Provides autocorrect lookup from a static English→Bengali mapping loaded from `autodict.plist`.
///
/// The autocorrect dictionary contains common English words/phrases that map directly
/// to their Bengali equivalents, bypassing the phonetic parsing pipeline.
class AutoCorrect {
    static let shared = AutoCorrect()

    /// The English→Bengali autocorrect entries.
    private var entries: [String: String] = [:]

    private init() {
        guard let fileName = Bundle.main.path(forResource: "autodict", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: fileName) as? [String: String] else {
            return
        }
        entries = dict
    }

    /// Looks up an autocorrect entry for the given Romanized input.
    ///
    /// The input is first normalized (lowercased, case-sensitive chars preserved) via
    /// `AvroParser.fix()` before looking up in the dictionary.
    ///
    /// - Parameter term: The Romanized input string.
    /// - Returns: The Bengali autocorrect string, or `nil` if no entry exists.
    func find(_ term: String) -> String? {
        let fixed = AvroParser.shared.fix(term)
        return entries[fixed]
    }
}
