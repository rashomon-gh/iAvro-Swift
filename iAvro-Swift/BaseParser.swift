import Foundation

// MARK: - Shared Codable Models

/// Root JSON structure for parser data files
public struct JSONData: Decodable {
    let vowel: String
    let consonant: String
    let casesensitive: String
    let patterns: [Pattern]

    enum CodingKeys: String, CodingKey {
        case vowel, consonant, casesensitive, patterns
    }
}

/// OPTIMIZATION: Strongly-typed struct eliminates dynamic [String: Any] casting
/// Represents a single pattern with its find/replace strings and optional conditional rules
public struct Pattern: Decodable {
    let find: String
    let replace: String?
    let rules: [Rule]?

    // OPTIMIZATION: Pre-computed character array for zero-allocation comparisons
    var findChars: [Character] { Array(find) }
}

/// OPTIMIZATION: Strongly-typed struct eliminates dynamic [String: Any] casting
/// Represents a conditional rule with multiple match conditions
public struct Rule: Decodable {
    let replace: String
    let matches: [Match]?
}

/// OPTIMIZATION: Strongly-typed struct eliminates dynamic [String: Any] casting
/// Represents a single match condition within a rule
public struct Match: Decodable {
    let type: String
    let scope: String
    let value: String?
    let negative: Bool?
}

// MARK: - Base Parser

/// Abstract base class for pattern-based parsing engines.
///
/// Provides a shared, optimized parsing engine that uses longest-match-first
/// binary search over sorted pattern tables. Subclasses customize behavior via
/// the `formatReplacement(_:)` hook.
///
/// Key optimizations:
/// - O(1) character classification using Set<Character>
/// - Zero-allocation pattern matching using ArraySlice
/// - Pre-computed character arrays for patterns
/// - Strongly-typed Codable models eliminate dynamic casting
open class BaseParser {

    // MARK: - Properties

    /// OPTIMIZATION: O(1) Set<Character> lookups instead of O(N) String.contains()
    private(set) var vowel: Set<Character> = []

    private(set) var consonant: Set<Character> = []

    private(set) var caseSensitive: Set<Character> = []

    private(set) var patterns: [Pattern] = []

    private(set) var maxPatternLength: Int = 0

    /// Multiplier for output buffer capacity reservation. Subclasses can override.
    var capacityMultiplier: Int = 1

    // MARK: - Initialization

    /// Initializes the parser by loading patterns from a JSON file.
    ///
    /// - Parameter jsonFileName: The name of the JSON file (without extension) in the bundle.
    public init(jsonFileName: String) {
        guard let filePath = Bundle.main.path(forResource: jsonFileName, ofType: "json"),
              let jsonData = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
              let json = try? JSONDecoder().decode(JSONData.self, from: jsonData) else {
            return
        }

        // OPTIMIZATION: Convert strings to Set<Character> for O(1) lookups
        vowel = Set(json.vowel)
        consonant = Set(json.consonant)
        caseSensitive = Set(json.casesensitive)
        patterns = json.patterns

        if let firstPattern = patterns.first {
            maxPatternLength = firstPattern.find.count
        }
    }

    // MARK: - Core Parse Engine

    /// Parses an input string using the loaded patterns.
    ///
    /// Iterates through the input character by character, attempting to match
    /// the longest possible pattern at each position using binary search.
    /// When a pattern match is found, its conditional rules are evaluated
    /// to determine the correct replacement.
    ///
    /// - Parameter string: The input string to parse.
    /// - Returns: The parsed output string.
    func parse(_ string: String) -> String {
        guard !string.isEmpty else { return string }

        let cleaned = clean(string)
        var output = ""

        // OPTIMIZATION: Pre-allocate output memory to prevent repeated reallocations
        output.reserveCapacity(cleaned.count * capacityMultiplier)

        let len = cleaned.count
        let cleanedChars = Array(cleaned)
        var cur = 0

        while cur < len {
            let start = cur
            var matched = false

            // Try longest chunks first for greedy matching
            for chunkLen in (1...maxPatternLength).reversed() {
                let end = start + chunkLen
                if end > len { continue }

                // OPTIMIZATION: Use ArraySlice instead of creating String (zero-allocation)
                let chunkSlice = cleanedChars[start..<end]

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
                                var doReplace = true
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
                                            // OPTIMIZATION: Pass [Character] array instead of String
                                            if !isExact(value, haystack: cleanedChars, start: start, end: end, type: type, not: isNegative) {
                                                doReplace = false
                                                break
                                            }
                                        }
                                    }
                                }

                                if doReplace {
                                    output += formatReplacement(rule.replace)
                                    cur = end - 1
                                    matched = true
                                    break
                                }
                            }
                        }

                        if matched { break }

                        // No rules or no rule matched — use the default replacement
                        if let defaultReplace = pattern.replace {
                            output += formatReplacement(defaultReplace)
                        }
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
                output.append(cleanedChars[cur])
            }
            cur += 1
        }

        return output
    }

    // MARK: - Subclass Hooks

    /// Hook for subclasses to format the output string upon a successful match.
    ///
    /// Subclasses can override this method to apply custom formatting to replacement strings.
    /// For example, RegexParser appends a regex suffix to each replacement.
    ///
    /// - Parameter text: The replacement text from a matched pattern or rule.
    /// - Returns: The formatted replacement text.
    open func formatReplacement(_ text: String) -> String {
        return text
    }

    // MARK: - Helper Methods

    /// Normalizes the input string by lowercasing all characters except those in the case-sensitive set.
    ///
    /// - Parameter string: The raw input string.
    /// - Returns: The normalized string ready for pattern matching.
    func clean(_ string: String) -> String {
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
    func inSet(_ set: Set<Character>, c: Character) -> Bool {
        let lower = smallCap(c)
        return set.contains(lower)
    }

    /// Returns whether the character is a vowel.
    func isVowel(_ c: Character) -> Bool {
        return inSet(vowel, c: c)
    }

    /// Returns whether the character is a consonant.
    func isConsonant(_ c: Character) -> Bool {
        return inSet(consonant, c: c)
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
    func isExact(_ needle: String, haystack: [Character], start: Int, end: Int, type: String, not: Bool) -> Bool {
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
    func smallCap(_ letter: Character) -> Character {
        if let scalar = letter.asciiValue, scalar >= 65, scalar <= 90 {
            return Character(UnicodeScalar(scalar - 65 + 97))
        }
        return letter
    }

    /// OPTIMIZATION: Lexicographic comparison for binary search traversal
    /// Compares two character sequences to determine if the first is less than the second.
    func lexicographicLess<C1: Collection, C2: Collection>(_ lhs: C1, _ rhs: C2) -> Bool
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
