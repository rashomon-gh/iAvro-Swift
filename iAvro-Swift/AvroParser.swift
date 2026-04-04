import Foundation

/// Converts Romanized (English) text into Bengali using phonetic patterns loaded from `data.json`.
///
/// The parser uses a longest-match-first strategy with binary search over a sorted pattern table.
/// Each pattern may have conditional rules that inspect surrounding characters (prefix/suffix)
/// before deciding which replacement to apply.
class AvroParser {
    static let shared = AvroParser()

    // Character class strings loaded from data.json
    private var vowel: String = ""
    private var consonant: String = ""
    private var number: String = ""
    private var caseSensitive: String = ""
    private var patterns: [[String: Any]] = []
    private var maxPatternLength: Int = 0

    private init() {
        guard let filePath = Bundle.main.path(forResource: "data", ofType: "json"),
              let jsonData = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return
        }

        vowel = json["vowel"] as? String ?? ""
        consonant = json["consonant"] as? String ?? ""
        number = json["number"] as? String ?? ""
        caseSensitive = json["casesensitive"] as? String ?? ""
        patterns = json["patterns"] as? [[String: Any]] ?? []
        if let firstPattern = patterns.first, let find = firstPattern["find"] as? String {
            maxPatternLength = find.count
        }
    }

    /// Parses a Romanized string and returns the Bengali equivalent.
    ///
    /// Iterates through the input character by character, attempting to match the longest
    /// possible pattern at each position using binary search. When a pattern match is found,
    /// its conditional rules are evaluated to determine the correct replacement.
    ///
    /// - Parameter string: The Romanized input text (e.g. "ami").
    /// - Returns: The Bengali output string (e.g. "আমি").
    func parse(_ string: String) -> String {
        guard !string.isEmpty else { return "" }

        let fixed = fix(string)
        var output = ""

        let len = fixed.count
        let fixedChars = Array(fixed)
        var cur = 0

        while cur < len {
            let start = cur
            var matched = false

            // Try longest chunks first for greedy matching
            for chunkLen in (1...maxPatternLength).reversed() {
                let end = start + chunkLen
                if end > len { continue }

                let chunk = String(fixedChars[start..<end])

                // Binary search for the pattern matching this chunk
                var left = 0
                var right = patterns.count - 1

                while right >= left {
                    let mid = (right + left) / 2
                    let pattern = patterns[mid]
                    let find = pattern["find"] as? String ?? ""

                    if find == chunk {
                        // Evaluate conditional rules if present
                        if let rules = pattern["rules"] as? [[String: Any]] {
                            for rule in rules {
                                var replace = true
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
                                                isPunctuation(fixedChars[chk])
                                            )
                                            // XOR equivalent: !(condition ^ isNegative)
                                            if condition == isNegative {
                                                replace = false
                                                break
                                            }
                                        } else if scope == "vowel" {
                                            let condition = (
                                                (chk >= 0 && type == "prefix") ||
                                                (chk < len && type == "suffix")
                                            ) && isVowel(fixedChars[chk])
                                            if condition == isNegative {
                                                replace = false
                                                break
                                            }
                                        } else if scope == "consonant" {
                                            let condition = (
                                                (chk >= 0 && type == "prefix") ||
                                                (chk < len && type == "suffix")
                                            ) && isConsonant(fixedChars[chk])
                                            if condition == isNegative {
                                                replace = false
                                                break
                                            }
                                        } else if scope == "number" {
                                            let condition = (
                                                (chk >= 0 && type == "prefix") ||
                                                (chk < len && type == "suffix")
                                            ) && isNumber(fixedChars[chk])
                                            if condition == isNegative {
                                                replace = false
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
                                            if !isExact(value, haystack: fixed, start: s, end: e, not: isNegative) {
                                                replace = false
                                                break
                                            }
                                        }
                                    }
                                }

                                if replace {
                                    output += (rule["replace"] as? String ?? "")
                                    cur = end - 1
                                    matched = true
                                    break
                                }
                            }
                        }

                        if matched { break }

                        // No rules or no rule matched — use the default replacement
                        output += (pattern["replace"] as? String ?? "")
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

            // No pattern matched — pass through the character as-is
            if !matched {
                output.append(fixedChars[cur])
            }
            cur += 1
        }

        return output
    }

    /// Normalizes the input string by lowercasing all characters except those in the case-sensitive set.
    ///
    /// - Parameter string: The raw input string.
    /// - Returns: The normalized string ready for pattern matching.
    func fix(_ string: String) -> String {
        var result = ""
        for c in string {
            if !isCaseSensitive(c) {
                result.append(smallCap(c))
            } else {
                result.append(c)
            }
        }
        return result
    }

    /// Checks if a character belongs to the given category string (case-insensitive).
    private func inString(_ str: String, c: Character) -> Bool {
        let lower = smallCap(c)
        return str.contains(lower)
    }

    /// Returns whether the character is a Bengali or English vowel.
    func isVowel(_ c: Character) -> Bool {
        return inString(vowel, c: c)
    }

    /// Returns whether the character is a consonant.
    func isConsonant(_ c: Character) -> Bool {
        return inString(consonant, c: c)
    }

    /// Returns whether the character is a digit.
    func isNumber(_ c: Character) -> Bool {
        return inString(number, c: c)
    }

    /// Returns whether the character is neither a vowel nor a consonant.
    func isPunctuation(_ c: Character) -> Bool {
        return !isVowel(c) && !isConsonant(c)
    }

    /// Returns whether the character is in the case-sensitive set (should not be lowercased).
    func isCaseSensitive(_ c: Character) -> Bool {
        return inString(caseSensitive, c: c)
    }

    /// Checks whether a substring of `haystack` in the range `[start, end)` exactly equals `needle`.
    ///
    /// - Parameters:
    ///   - needle: The string to compare against.
    ///   - haystack: The full string to extract the substring from.
    ///   - start: The start index (inclusive) of the substring.
    ///   - end: The end index (exclusive) of the substring.
    ///   - not: When `true`, inverts the result (XOR logic from ObjC).
    /// - Returns: Whether the substring matches `needle`, optionally inverted.
    private func isExact(_ needle: String, haystack: String, start: Int, end: Int, not: Bool) -> Bool {
        guard start >= 0 && end <= haystack.count else { return not }
        let startIdx = haystack.index(haystack.startIndex, offsetBy: start)
        let endIdx = haystack.index(haystack.startIndex, offsetBy: end)
        let sub = String(haystack[startIdx..<endIdx])
        return (sub == needle) != not
    }

    /// Converts an uppercase ASCII letter to its lowercase equivalent.
    private func smallCap(_ letter: Character) -> Character {
        if let scalar = letter.asciiValue, scalar >= 65, scalar <= 90 {
            return Character(UnicodeScalar(scalar - 65 + 97))
        }
        return letter
    }
}
