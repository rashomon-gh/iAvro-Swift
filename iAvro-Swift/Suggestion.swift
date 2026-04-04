import Foundation

/// The main suggestion engine that combines phonetic parsing, dictionary lookup,
/// autocorrect, suffix handling, and caching to produce candidate suggestions
/// for the current input.
class Suggestion {
    static let shared = Suggestion()

    /// The current list of suggestion candidates.
    private var suggestions: [String] = []

    /// Bengali dependent vowel signs (কার).
    private let karChars: Set<Character> = [
        "\u{09BE}", "\u{09BF}", "\u{09C0}", "\u{09C1}", "\u{09C2}",
        "\u{09C3}", "\u{09C7}", "\u{09C8}", "\u{09CB}", "\u{09CC}", "\u{09C4}"
    ]

    /// Bengali independent vowels and dependent vowel signs.
    private let vowelChars: Set<Character> = [
        "\u{0985}", "\u{0986}", "\u{0987}", "\u{0988}", "\u{0989}", "\u{098A}",
        "\u{098B}", "\u{098F}", "\u{0990}", "\u{0993}", "\u{0994}", "\u{098C}",
        "\u{09E1}", "\u{09BE}", "\u{09BF}", "\u{09C0}", "\u{09C1}", "\u{09C2}",
        "\u{09C3}", "\u{09C7}", "\u{09C8}", "\u{09CB}", "\u{09CC}"
    ]

    private init() {}

    /// Generates a list of Bengali suggestion candidates for the given Romanized input.
    ///
    /// The suggestion pipeline:
    /// 1. Parse the input phonetically via `AvroParser`.
    /// 2. If dictionary suggestions are enabled, look up cached results or query the database.
    /// 3. Add autocorrect entries if available.
    /// 4. Sort dictionary results by Levenshtein distance from the phonetic parse.
    /// 5. Apply suffix combinations by splitting the input at various positions.
    /// 6. Always include the phonetic parse result as the last suggestion.
    ///
    /// - Parameter term: The Romanized input string.
    /// - Returns: An ordered array of Bengali suggestion strings.
    func getList(_ term: String) -> [String] {
        if term.isEmpty {
            return suggestions
        }

        suggestions.removeAll()
        let parsedString = AvroParser.shared.parse(term)

        if UserDefaults.standard.bool(forKey: "IncludeDictionary") {
            let cached = CacheManager.shared.array(forKey: term)
            if let cached = cached, !cached.isEmpty {
                suggestions = cached.compactMap { $0 as? String }
            } else {
                // Add autocorrect entry if found
                let autoCorrect = AutoCorrect.shared.find(term)
                if let ac = autoCorrect {
                    suggestions.append(ac)
                }

                // Query dictionary and sort by Levenshtein distance
                let dicList = Database.shared.find(term)
                if !dicList.isEmpty {
                    if let ac = autoCorrect, dicList.contains(ac) {
                        suggestions.removeAll { $0 == ac }
                    }
                    let sorted = dicList.sorted { a, b in
                        parsedString.levenshteinDistance(to: a) < parsedString.levenshteinDistance(to: b)
                    }
                    suggestions.append(contentsOf: sorted)
                }

                CacheManager.shared.setArray(suggestions, forKey: term)
            }

            // Suffix combination: try splitting the input at each position
            // to combine a base word with a suffix
            var alreadySelected = false
            CacheManager.shared.removeAllBase()

            for i in stride(from: term.count - 1, through: 1, by: -1) {
                let suffixStart = term.index(term.startIndex, offsetBy: i)
                let suffixStr = String(term[suffixStart...]).lowercased()

                if let suffixBangla = Database.shared.banglaForSuffix(suffixStr) {
                    let base = String(term[..<suffixStart])
                    let cached = CacheManager.shared.array(forKey: base)
                    var selected: String? = nil
                    if !alreadySelected {
                        selected = CacheManager.shared.string(forKey: base)
                    }

                    if let cached = cached {
                        for item in cached {
                            guard let item = item as? String else { continue }
                            if base == item { continue }

                            let cutPos = item.index(item.endIndex, offsetBy: -1)
                            let itemRMC = String(item[cutPos...])
                            let suffixLMC = String(suffixBangla[suffixBangla.startIndex])

                            // Apply phonetic joining rules between base word ending and suffix
                            let word: String
                            if isVowel(itemRMC) && isKar(suffixLMC) {
                                word = item + "\u{09DF}" + suffixBangla
                            } else if itemRMC == "\u{09CE}" {
                                // Handantta → ta + suffix
                                let prefix = String(item[..<cutPos])
                                word = prefix + "\u{09A4}" + suffixBangla
                            } else if itemRMC == "\u{0982}" {
                                // Anusvara → nga + suffix
                                let prefix = String(item[..<cutPos])
                                word = prefix + "\u{0999}" + suffixBangla
                            } else {
                                word = item + suffixBangla
                            }

                            CacheManager.shared.setBase([base, item], forKey: word)

                            if !suggestions.contains(word) {
                                if !alreadySelected, let selected = selected, item == selected {
                                    if CacheManager.shared.string(forKey: term) == nil {
                                        CacheManager.shared.setString(word, forKey: term)
                                    }
                                    alreadySelected = true
                                }
                                suggestions.append(word)
                            }
                        }
                    }
                }
            }
        }

        // Always include the direct phonetic parse as a candidate
        if !suggestions.contains(parsedString) {
            suggestions.append(parsedString)
        }

        return suggestions
    }

    /// Returns whether the given single-character string is a Bengali kar (dependent vowel sign).
    private func isKar(_ letter: String) -> Bool {
        guard letter.count == 1, let c = letter.first else { return false }
        return karChars.contains(c)
    }

    /// Returns whether the given single-character string is a Bengali vowel.
    private func isVowel(_ letter: String) -> Bool {
        guard letter.count == 1, let c = letter.first else { return false }
        return vowelChars.contains(c)
    }
}
