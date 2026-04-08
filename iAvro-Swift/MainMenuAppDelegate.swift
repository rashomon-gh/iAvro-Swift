import Cocoa
import InputMethodKit

/// The application delegate responsible for the status bar menu and lifecycle management.
///
/// Creates a menu with a Preferences item, loads dictionary data on first launch,
/// and persists the suggestion cache on application termination.
@objc(MainMenuAppDelegate)
class MainMenuAppDelegate: NSObject, NSApplicationDelegate {

    /// The preferences manager instance.
    @objc var imPref: IMPreferences?

    /// The status bar menu shown when the input method icon is clicked.
    @objc let menu = NSMenu()

    /// Sets up the application menu programmatically (no NIB file).
    @objc func setupMenu() {
        print("iAvro: Setting up menu...")

        // Create Preferences menu item
        let preferencesItem = NSMenuItem()
        preferencesItem.title = "Preferences..."
        preferencesItem.tag = 1
        preferencesItem.action = #selector(showPreferences(_:))
        preferencesItem.target = self
        menu.addItem(preferencesItem)

        print("iAvro: ✅ Menu setup complete")
    }

    /// Called when the NIB is loaded. Wires up menu actions and eagerly loads
    /// dictionary data and singletons if dictionary suggestions are enabled.
    @objc override func awakeFromNib() {
        print("iAvro: awakeFromNib called (should not happen in pure Swift version)")

        let preferencesItem = menu.item(withTag: 1)
        preferencesItem?.action = #selector(showPreferences(_:))

        if UserDefaults.standard.bool(forKey: "IncludeDictionary") {
            print("iAvro: Loading Dictionary...")
            let _ = Database.shared
            let _ = RegexParser.shared
            let _ = CacheManager.shared
        }
        let _ = AutoCorrect.shared

        print("iAvro: ✅ Awake from nib complete")
    }

    /// Called when the app finishes launching.
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("iAvro: applicationDidFinishLaunching called")

        // Load dictionary data if needed
        if UserDefaults.standard.bool(forKey: "IncludeDictionary") {
            print("iAvro: Loading Dictionary...")
            let _ = Database.shared
            let _ = RegexParser.shared
            let _ = CacheManager.shared
        }
        let _ = AutoCorrect.shared

        print("iAvro: ✅ App launch complete")
    }

    /// Opens the preferences window.
    @objc func showPreferences(_ sender: Any?) {
        guard let imPref = imPref else { return }
        let pw = imPref.windowController.window
        pw?.hidesOnDeactivate = false
        pw?.level = .modalPanel
        pw?.makeKeyAndOrderFront(self)
    }

    /// Persists the suggestion cache to disk before the application terminates.
    func applicationWillTerminate(_ notification: Notification) {
        if UserDefaults.standard.bool(forKey: "IncludeDictionary") {
            CacheManager.shared.persist()
        }
    }
}
