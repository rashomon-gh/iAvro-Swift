import AppKit

/// Registers default user preferences from `preferences.plist` and manages the preferences window.
///
/// Loaded at startup from `main.swift`. The defaults include:
/// - `CandidatePanelType`: The candidate panel display style (1 = vertical, 2 = horizontal).
/// - `CommitNewLineOnEnter`: Whether pressing Enter commits a newline.
/// - `IncludeDictionary`: Whether dictionary suggestions are enabled.
class IMPreferences: NSObject {

    /// The window controller for the preferences window (lazy-loaded).
    private var _windowController: NSWindowController?

    override init() {
        super.init()
        registerDefaults()
    }

    /// Registers the default preference values from the bundled `preferences.plist`.
    private func registerDefaults() {
        guard let prefFile = Bundle.main.path(forResource: "preferences", ofType: "plist"),
              let prefDict = NSDictionary(contentsOfFile: prefFile) as? [String: Any] else {
            return
        }
        UserDefaults.standard.register(defaults: prefDict)
    }

    /// The window controller for the preferences window.
    ///
    /// Creates a `PreferencesWindowController` on first access.
    var windowController: NSWindowController {
        if _windowController == nil {
            _windowController = PreferencesWindowController()
        }
        return _windowController!
    }
}
