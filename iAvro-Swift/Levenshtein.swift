import Foundation

extension String {
    func levenshteinDistance(to other: String) -> Int {
        let n = self.count
        let m = other.count

        if n == 0 || m == 0 {
            return max(n, m)
        }

        var d = [Int](repeating: 0, count: (n + 1) * (m + 1))

        for k in 0...n { d[k] = k }
        for k in 0...m { d[k * (n + 1)] = k }

        let selfChars = Array(self)
        let otherChars = Array(other)

        for i in 1...n {
            for j in 1...m {
                let cost = selfChars[i - 1] == otherChars[j - 1] ? 0 : 1
                let a = d[(j - 1) * (n + 1) + i] + 1
                let b = d[j * (n + 1) + i - 1] + 1
                let c = d[(j - 1) * (n + 1) + i - 1] + cost
                d[j * (n + 1) + i] = Swift.min(a, b, c)
            }
        }

        return d[m * (n + 1) + n]
    }
}
