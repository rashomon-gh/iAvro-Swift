import Foundation

class AutoCorrect {
    static let shared = AutoCorrect()

    private var entries: [String: String] = [:]

    private init() {
        guard let fileName = Bundle.main.path(forResource: "autodict", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: fileName) as? [String: String] else {
            return
        }
        entries = dict
    }

    func find(_ term: String) -> String? {
        let fixed = AvroParser.shared.fix(term)
        return entries[fixed]
    }
}
