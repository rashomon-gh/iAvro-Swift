import Foundation

extension String {

    /// Computes the Levenshtein edit distance between this string and another.
    ///
    /// The Levenshtein distance is the minimum number of single-character edits
    /// (insertions, deletions, or substitutions) required to change one string
    /// into the other. Used to sort dictionary suggestions by relevance.
    ///
    /// - Parameter other: The string to compare against.
    /// - Returns: The edit distance as an integer (0 = identical).
    ///
    /// - Complexity: O(n * m) where n and m are the lengths of the two strings.
    func levenshteinDistance(to other: String) -> Int {
        let n = self.count
        let m = other.count

        if n == 0 || m == 0 {
            return max(n, m)
        }

        // Flat array representing a 2D distance matrix
        var d = [Int](repeating: 0, count: (n + 1) * (m + 1))

        // Initialize first column (deleting all chars from self)
        for k in 0...n { d[k] = k }
        // Initialize first row (inserting all chars of other)
        for k in 0...m { d[k * (n + 1)] = k }

        let selfChars = Array(self)
        let otherChars = Array(other)

        for i in 1...n {
            for j in 1...m {
                let cost = selfChars[i - 1] == otherChars[j - 1] ? 0 : 1
                let deletion = d[(j - 1) * (n + 1) + i] + 1
                let insertion = d[j * (n + 1) + i - 1] + 1
                let substitution = d[(j - 1) * (n + 1) + i - 1] + cost
                d[j * (n + 1) + i] = Swift.min(deletion, insertion, substitution)
            }
        }

        return d[m * (n + 1) + n]
    }
}
