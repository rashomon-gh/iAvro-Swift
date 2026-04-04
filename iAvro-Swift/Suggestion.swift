import Foundation

class Suggestion {
    static let shared = Suggestion()

    private var suggestions: [String] = []

    private let karChars: Set<Character> = [
        "\u{09BE}", "\u{09BF}", "\u{09C0}", "\u{09C1}", "\u{09C2}",
        "\u{09C3}", "\u{09C7}", "\u{09C8}", "\u{09CB}", "\u{09CC}", "\u{09C4}"
    ]

    private let vowelChars: Set<Character> = [
        "\u{0985}", "\u{0986}", "\u{0987}", "\u{0988}", "\u{0989}", "\u{098A}",
        "\u{098B}", "\u{098F}", "\u{0990}", "\u{0993}", "\u{0994}", "\u{098C}",
        "\u{09E1}", "\u{09BE}", "\u{09BF}", "\u{09C0}", "\u{09C1}", "\u{09C2}",
        "\u{09C3}", "\u{09C7}", "\u{09C8}", "\u{09CB}", "\u{09CC}"
    ]

    private init() {}

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
                let autoCorrect = AutoCorrect.shared.find(term)
                if let ac = autoCorrect {
                    suggestions.append(ac)
                }

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

                            let word: String
                            if isVowel(itemRMC) && isKar(suffixLMC) {
                                word = item + "\u{09DF}" + suffixBangla
                            } else if itemRMC == "\u{09CE}" {
                                let prefix = String(item[..<cutPos])
                                word = prefix + "\u{09A4}" + suffixBangla
                            } else if itemRMC == "\u{0982}" {
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

        if !suggestions.contains(parsedString) {
            suggestions.append(parsedString)
        }

        return suggestions
    }

    private func isKar(_ letter: String) -> Bool {
        guard letter.count == 1, let c = letter.first else { return false }
        return karChars.contains(c)
    }

    private func isVowel(_ letter: String) -> Bool {
        guard letter.count == 1, let c = letter.first else { return false }
        return vowelChars.contains(c)
    }
}
