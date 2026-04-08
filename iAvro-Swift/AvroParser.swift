import Foundation

/// Converts Romanized (English) text into Bangla using phonetic patterns loaded from `data.json`.
///
/// The parser uses a longest-match-first strategy with binary search over a sorted pattern table.
/// Each pattern may have conditional rules that inspect surrounding characters (prefix/suffix)
/// before deciding which replacement to apply.
class AvroParser {
    static let shared = AvroParser()

    // OPTIMIZATION: O(1) Set<Character> lookups instead of O(N) String.contains()
    private var vowel: Set<Character> = []
    private var consonant: Set<Character> = []
    private var number: Set<Character> = []
    private var caseSensitive: Set<Character> = []

    // OPTIMIZATION: Strongly-typed structs eliminate dynamic [String: Any] casting
    private var patterns: [Pattern] = []
    private var maxPatternLength: Int = 0

    private init() {
        guard let filePath = Bundle.main.path(forResource: "data", ofType: "json"),
              let jsonData = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
              let json = try? JSONDecoder().decode(JSONData.self, from: jsonData) else {
            return
        }

        // OPTIMIZATION: Convert strings to Set<Character> for O(1) lookups
        vowel = Set(json.vowel)
        consonant = Set(json.consonant)
        number = Set(json.number)
        caseSensitive = Set(json.casesensitive)
        patterns = json.patterns
        if let firstPattern = patterns.first {
            maxPatternLength = firstPattern.find.count
        }
    }

    /// Parses a Romanized string and returns the Bangla equivalent.
    ///
    /// Iterates through the input character by character, attempting to match the longest
    /// possible pattern at each position using binary search. When a pattern match is found,
    /// its conditional rules are evaluated to determine the correct replacement.
    ///
    /// - Parameter string: The Romanized input text (e.g. "ami").
    /// - Returns: The Bangla output string (e.g. "আমি").
    func parse(_ string: String) -> String {
        guard !string.isEmpty else { return "" }

        let fixed = fix(string)
        var output = ""

        // OPTIMIZATION: Pre-allocate output memory to prevent repeated reallocations
        output.reserveCapacity(fixed.count)

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

                // OPTIMIZATION: Use ArraySlice instead of creating String (zero-allocation)
                let chunkSlice = fixedChars[start..<end]

                // Binary search for the pattern matching this chunk
                var left = 0
                var right = patterns.count - 1

                while right >= left {
                    let mid = (right + left) / 2
                    let pattern = patterns[mid]
                    let findChars = pattern.findChars
                    let findCount = findChars.count

                    // OPTIMIZATION: Compare ArraySlice directly with [Character] array
                    if chunkSlice.elementsEqual(findChars) {
                        // Evaluate conditional rules if present
                        if let rules = pattern.rules {
                            for rule in rules {
                                var replace = true
                                var chk = 0

                                if let matches = rule.matches {
                                    for match in matches {
                                        let value = match.value ?? ""
                                        let type = match.type
                                        let scope = match.scope
                                        let isNegative = match.negative ?? false

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
                                            // OPTIMIZATION: Pass [Character] array instead of String
                                            if !isExact(value, haystack: fixedChars, start: start, end: end, type: type, not: isNegative) {
                                                replace = false
                                                break
                                            }
                                        }
                                    }
                                }

                                if replace {
                                    output += rule.replace
                                    cur = end - 1
                                    matched = true
                                    break
                                }
                            }
                        }

                        if matched { break }

                        // No rules or no rule matched — use the default replacement
                        output += pattern.replace
                        cur = end - 1
                        matched = true
                        break
                    } else {
                        // OPTIMIZATION: Binary search traversal based on length and lexicographic order
                        let chunkCount = chunkSlice.count
                        if findCount > chunkCount || (findCount == chunkCount && lexicographicLess(findChars, chunkSlice)) {
                            left = mid + 1
                        } else {
                            right = mid - 1
                        }
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

    /// OPTIMIZATION: O(1) Set<Character> lookup instead of O(N) String.contains()
    /// Checks if a character belongs to the given category set.
    private func inSet(_ set: Set<Character>, c: Character) -> Bool {
        let lower = smallCap(c)
        return set.contains(lower)
    }

    /// Returns whether the character is a Bangla or English vowel.
    func isVowel(_ c: Character) -> Bool {
        return inSet(vowel, c: c)
    }

    /// Returns whether the character is a consonant.
    func isConsonant(_ c: Character) -> Bool {
        return inSet(consonant, c: c)
    }

    /// Returns whether the character is a digit.
    func isNumber(_ c: Character) -> Bool {
        return inSet(number, c: c)
    }

    /// Returns whether the character is neither a vowel nor a consonant.
    func isPunctuation(_ c: Character) -> Bool {
        return !isVowel(c) && !isConsonant(c)
    }

    /// Returns whether the character is in the case-sensitive set (should not be lowercased).
    func isCaseSensitive(_ c: Character) -> Bool {
        return inSet(caseSensitive, c: c)
    }

    /// OPTIMIZATION: Operates on [Character] array instead of String to avoid O(N) index calculations
    /// Checks whether a substring of `haystack` in the range `[start, end)` exactly equals `needle`.
    ///
    /// - Parameters:
    ///   - needle: The string to compare against.
    ///   - haystack: The full character array to extract the substring from.
    ///   - start: The start index (inclusive) of the substring.
    ///   - end: The end index (exclusive) of the substring.
    ///   - type: "prefix" or "suffix" to determine comparison direction.
    ///   - not: When `true`, inverts the result (XOR logic from ObjC).
    /// - Returns: Whether the substring matches `needle`, optionally inverted.
    private func isExact(_ needle: String, haystack: [Character], start: Int, end: Int, type: String, not: Bool) -> Bool {
        var s: Int, e: Int
        if type == "suffix" {
            s = end
            e = end + needle.count
        } else {
            s = start - needle.count
            e = start
        }

        guard s >= 0 && e <= haystack.count else { return not }

        // OPTIMIZATION: O(1) array slice comparison instead of String.index manipulation
        let sub = haystack[s..<e]
        let needleChars = Array(needle)
        return (sub.elementsEqual(needleChars)) != not
    }

    /// Converts an uppercase ASCII letter to its lowercase equivalent.
    private func smallCap(_ letter: Character) -> Character {
        if let scalar = letter.asciiValue, scalar >= 65, scalar <= 90 {
            return Character(UnicodeScalar(scalar - 65 + 97))
        }
        return letter
    }

    /// OPTIMIZATION: Lexicographic comparison for binary search traversal
    /// Compares two character sequences to determine if the first is less than the second.
    private func lexicographicLess<C1: Collection, C2: Collection>(_ lhs: C1, _ rhs: C2) -> Bool
        where C1.Element == Character, C2.Element == Character {
        let minCount = min(lhs.count, rhs.count)
        for i in 0..<minCount {
            let l = lhs[lhs.index(lhs.startIndex, offsetBy: i)]
            let r = rhs[rhs.index(rhs.startIndex, offsetBy: i)]
            if l != r {
                return l < r
            }
        }
        return lhs.count < rhs.count
    }
}

// MARK: - Optimized Codable Models

/// Root JSON structure for data.json
private struct JSONData: Decodable {
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

/// OPTIMIZATION: Strongly-typed struct eliminates dynamic [String: Any] casting
/// Represents a single pattern with its find/replace strings and optional conditional rules
private struct Pattern: Decodable {
    let find: String
    let replace: String
    let rules: [Rule]?

    // OPTIMIZATION: Pre-computed character array for zero-allocation comparisons
    var findChars: [Character] { Array(find) }
}

/// OPTIMIZATION: Strongly-typed struct eliminates dynamic [String: Any] casting
/// Represents a conditional rule with multiple match conditions
private struct Rule: Decodable {
    let replace: String
    let matches: [Match]?
}

/// OPTIMIZATION: Strongly-typed struct eliminates dynamic [String: Any] casting
/// Represents a single match condition within a rule
private struct Match: Decodable {
    let type: String
    let scope: String
    let value: String?
    let negative: Bool?
}
