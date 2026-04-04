import Foundation

class RegexParser {
    static let shared = RegexParser()

    private var vowel: String = ""
    private var consonant: String = ""
    private var caseSensitive: String = ""
    private var patterns: [[String: Any]] = []
    private var maxPatternLength: Int = 0

    private init() {
        guard let filePath = Bundle.main.path(forResource: "regex", ofType: "json"),
              let jsonData = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return
        }

        vowel = json["vowel"] as? String ?? ""
        consonant = json["consonant"] as? String ?? ""
        caseSensitive = json["casesensitive"] as? String ?? ""
        patterns = json["patterns"] as? [[String: Any]] ?? []
        if let firstPattern = patterns.first, let find = firstPattern["find"] as? String {
            maxPatternLength = find.count
        }
    }

    func parse(_ string: String) -> String {
        guard !string.isEmpty else { return string }

        let cleaned = clean(string)
        var output = ""

        let len = cleaned.count
        let cleanedChars = Array(cleaned)
        var cur = 0

        while cur < len {
            let start = cur
            var matched = false

            for chunkLen in (1...maxPatternLength).reversed() {
                let end = start + chunkLen
                if end > len { continue }

                let chunk = String(cleanedChars[start..<end])
                var left = 0
                var right = patterns.count - 1

                while right >= left {
                    let mid = (right + left) / 2
                    let pattern = patterns[mid]
                    let find = pattern["find"] as? String ?? ""

                    if find == chunk {
                        if let rules = pattern["rules"] as? [[String: Any]] {
                            for rule in rules {
                                var doReplace = true
                                var chk = 0

                                if let matches = rule["matches"] as? [[String: Any]] {
                                    for match in matches {
                                        let value = match["value"] as? String ?? ""
                                        let type = match["type"] as? String ?? ""
                                        let scope = match["scope"] as? String ?? ""
                                        let isNegative = match["negative"] as? Bool ?? false

                                        if type == "suffix" {
                                            chk = end
                                        } else {
                                            chk = start - 1
                                        }

                                        if scope == "punctuation" {
                                            let condition = (
                                                (chk < 0 && type == "prefix") ||
                                                (chk >= len && type == "suffix") ||
                                                isPunctuation(cleanedChars[chk])
                                            )
                                            if condition == isNegative {
                                                doReplace = false
                                                break
                                            }
                                        } else if scope == "vowel" {
                                            let condition = (
                                                (chk >= 0 && type == "prefix") ||
                                                (chk < len && type == "suffix")
                                            ) && isVowel(cleanedChars[chk])
                                            if condition == isNegative {
                                                doReplace = false
                                                break
                                            }
                                        } else if scope == "consonant" {
                                            let condition = (
                                                (chk >= 0 && type == "prefix") ||
                                                (chk < len && type == "suffix")
                                            ) && isConsonant(cleanedChars[chk])
                                            if condition == isNegative {
                                                doReplace = false
                                                break
                                            }
                                        } else if scope == "exact" {
                                            var s: Int, e: Int
                                            if type == "suffix" {
                                                s = end
                                                e = end + value.count
                                            } else {
                                                s = start - value.count
                                                e = start
                                            }
                                            if !isExact(value, haystack: cleaned, start: s, end: e, not: isNegative) {
                                                doReplace = false
                                                break
                                            }
                                        }
                                    }
                                }

                                if doReplace {
                                    output += (rule["replace"] as? String ?? "")
                                    output += "(্[যবম])?(্?)([ঃঁ]?)"
                                    cur = end - 1
                                    matched = true
                                    break
                                }
                            }
                        }

                        if matched { break }

                        output += (pattern["replace"] as? String ?? "")
                        output += "(্[যবম])?(্?)([ঃঁ]?)"
                        cur = end - 1
                        matched = true
                        break
                    } else if find.count > chunk.count || (find.count == chunk.count && find < chunk) {
                        left = mid + 1
                    } else {
                        right = mid - 1
                    }
                }
                if matched { break }
            }

            if !matched {
                output.append(cleanedChars[cur])
            }
            cur += 1
        }

        return output
    }

    private func clean(_ string: String) -> String {
        var result = ""
        for c in string {
            if !isCaseSensitive(c) {
                result.append(smallCap(c))
            }
        }
        return result
    }

    private func isVowel(_ c: Character) -> Bool {
        let lower = smallCap(c)
        return vowel.contains(lower)
    }

    private func isConsonant(_ c: Character) -> Bool {
        let lower = smallCap(c)
        return consonant.contains(lower)
    }

    private func isPunctuation(_ c: Character) -> Bool {
        return !isVowel(c) && !isConsonant(c)
    }

    private func isCaseSensitive(_ c: Character) -> Bool {
        let lower = smallCap(c)
        return caseSensitive.contains(lower)
    }

    private func isExact(_ needle: String, haystack: String, start: Int, end: Int, not: Bool) -> Bool {
        guard start >= 0 && end <= haystack.count else { return not }
        let startIdx = haystack.index(haystack.startIndex, offsetBy: start)
        let endIdx = haystack.index(haystack.startIndex, offsetBy: end)
        let sub = String(haystack[startIdx..<endIdx])
        return (sub == needle) != not
    }

    private func smallCap(_ letter: Character) -> Character {
        if let scalar = letter.asciiValue, scalar >= 65, scalar <= 90 {
            return Character(UnicodeScalar(scalar - 65 + 97))
        }
        return letter
    }
}
