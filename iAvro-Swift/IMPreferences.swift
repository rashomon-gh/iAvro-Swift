import AppKit

class IMPreferences: NSObject {
    private var _windowController: NSWindowController?

    override init() {
        super.init()
        registerDefaults()
    }

    private func registerDefaults() {
        guard let prefFile = Bundle.main.path(forResource: "preferences", ofType: "plist"),
              let prefDict = NSDictionary(contentsOfFile: prefFile) as? [String: Any] else {
            return
        }
        UserDefaults.standard.register(defaults: prefDict)
    }

    var windowController: NSWindowController {
        if _windowController == nil {
            _windowController = PreferencesWindowController()
        }
        return _windowController!
    }
}
