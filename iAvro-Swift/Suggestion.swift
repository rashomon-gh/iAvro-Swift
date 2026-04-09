import Foundation

/// The main suggestion engine that combines phonetic parsing, dictionary lookup,
/// autocorrect, suffix handling, and caching to produce candidate suggestions
/// for the current input.
class Suggestion {
    static let shared = Suggestion()

    /// Bangla dependent vowel signs (কার).
    private let karChars: Set<Character> = [
        "\u{09BE}", "\u{09BF}", "\u{09C0}", "\u{09C1}", "\u{09C2}",
        "\u{09C3}", "\u{09C7}", "\u{09C8}", "\u{09CB}", "\u{09CC}", "\u{09C4}"
    ]

    /// Bangla independent vowels and dependent vowel signs.
    private let vowelChars: Set<Character> = [
        "\u{0985}", "\u{0986}", "\u{0987}", "\u{0988}", "\u{0989}", "\u{098A}",
        "\u{098B}", "\u{098F}", "\u{0990}", "\u{0993}", "\u{0994}", "\u{098C}",
        "\u{09E1}", "\u{09BE}", "\u{09BF}", "\u{09C0}", "\u{09C1}", "\u{09C2}",
        "\u{09C3}", "\u{09C7}", "\u{09C8}", "\u{09CB}", "\u{09CC}"
    ]

    private init() {}

    /// Generates a list of Bangla suggestion candidates for the given Romanized input.
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
    /// - Returns: An ordered array of Bangla suggestion strings.
    func getList(_ term: String) -> [String] {
        if term.isEmpty {
            return []
        }

        // Local state for thread safety
        var suggestions: [String] = []
        var seenSuggestions: Set<String> = []

        // Helper to add suggestions with O(1) deduplication
        func addSuggestion(_ word: String) {
            if !seenSuggestions.contains(word) {
                seenSuggestions.insert(word)
                suggestions.append(word)
            }
        }

        let parsedString = AvroParser.shared.parse(term)

        if UserDefaults.standard.bool(forKey: "IncludeDictionary") {
            let cached = CacheManager.shared.array(forKey: term)
            if let cached = cached, !cached.isEmpty {
                for item in cached {
                    guard let word = item as? String else { continue }
                    addSuggestion(word)
                }
            } else {
                // Add autocorrect entry if found
                let autoCorrect = AutoCorrect.shared.find(term)
                if let ac = autoCorrect {
                    addSuggestion(ac)
                }

                // Query dictionary and sort by Levenshtein distance (Schwartzian transform)
                let dicList = Database.shared.find(term)
                if !dicList.isEmpty {
                    if let ac = autoCorrect, dicList.contains(ac) {
                        seenSuggestions.remove(ac)
                        suggestions.removeAll { $0 == ac }
                    }

                    // Pre-calculate distances once per word
                    let sorted = dicList
                        .map { (word: $0, distance: parsedString.levenshteinDistance(to: $0)) }
                        .sorted { $0.distance < $1.distance }
                        .map { $0.word }

                    for word in sorted {
                        addSuggestion(word)
                    }
                }

                CacheManager.shared.setArray(suggestions, forKey: term)
            }

            // Suffix combination: try splitting the input at each position
            // to combine a base word with a suffix (O(N) string traversal)
            var alreadySelected = false
            CacheManager.shared.removeAllBase()

            var currentSuffixStart = term.index(before: term.endIndex)
            while currentSuffixStart > term.startIndex {
                let suffixStr = String(term[currentSuffixStart...]).lowercased()
                let base = String(term[..<currentSuffixStart])

                if let suffixBangla = Database.shared.banglaForSuffix(suffixStr) {
                    let cached = CacheManager.shared.array(forKey: base)
                    var selected: String? = nil
                    if !alreadySelected {
                        selected = CacheManager.shared.string(forKey: base)
                    }

                    if let cached = cached {
                        for item in cached {
                            guard let item = item as? String else { continue }
                            if base == item { continue }

                            // Apply phonetic joining rules between base word ending and suffix
                            // (using Character directly to avoid string allocations)
                            guard let itemLastChar = item.last,
                                  let suffixFirstChar = suffixBangla.first else { continue }

                            let word: String
                            if isVowel(itemLastChar) && isKar(suffixFirstChar) {
                                word = item + "\u{09DF}" + suffixBangla
                            } else if itemLastChar == "\u{09CE}" {
                                // Handantta → ta + suffix
                                let prefix = String(item.dropLast())
                                word = prefix + "\u{09A4}" + suffixBangla
                            } else if itemLastChar == "\u{0982}" {
                                // Anusvara → nga + suffix
                                let prefix = String(item.dropLast())
                                word = prefix + "\u{0999}" + suffixBangla
                            } else {
                                word = item + suffixBangla
                            }

                            CacheManager.shared.setBase([base, item], forKey: word)

                            if !seenSuggestions.contains(word) {
                                if !alreadySelected, let selected = selected, item == selected {
                                    if CacheManager.shared.string(forKey: term) == nil {
                                        CacheManager.shared.setString(word, forKey: term)
                                    }
                                    alreadySelected = true
                                }
                                addSuggestion(word)
                            }
                        }
                    }
                }

                currentSuffixStart = term.index(before: currentSuffixStart)
            }
        }

        // Always include the direct phonetic parse as a candidate
        addSuggestion(parsedString)

        return suggestions
    }

    /// Returns whether the given character is a Bangla kar (dependent vowel sign).
    private func isKar(_ c: Character) -> Bool {
        karChars.contains(c)
    }

    /// Returns whether the given character is a Bangla vowel.
    private func isVowel(_ c: Character) -> Bool {
        vowelChars.contains(c)
    }
}
