import Cocoa
import InputMethodKit

/// The application delegate responsible for the status bar menu and lifecycle management.
///
/// Creates a menu with a Preferences item, loads dictionary data on first launch,
/// and persists the suggestion cache on application termination.
@objc(MainMenuAppDelegate)
class MainMenuAppDelegate: NSObject, NSApplicationDelegate {

    /// The preferences manager instance, set at startup from `main.swift`.
    @objc var imPref: IMPreferences?

    /// The status bar menu shown when the input method icon is clicked.
    @objc let menu = NSMenu()

    /// Creates and configures the menu with a Preferences item.
    @objc func setupMenu() {
        let preferencesItem = NSMenuItem(title: "Preferences...", action: #selector(showPreferences(_:)), keyEquivalent: ",")
        preferencesItem.tag = 1
        menu.addItem(preferencesItem)
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
    @objc func applicationWillTerminate(_ notification: Notification) {
        if UserDefaults.standard.bool(forKey: "IncludeDictionary") {
            CacheManager.shared.persist()
        }
    }

    /// Called when the NIB is loaded. Wires up menu actions and eagerly loads
    /// dictionary data and singletons if dictionary suggestions are enabled.
    override func awakeFromNib() {
        let preferencesItem = menu.item(withTag: 1)
        preferencesItem?.action = #selector(showPreferences(_:))

        if UserDefaults.standard.bool(forKey: "IncludeDictionary") {
            print("Loading Dictionary...")
            let _ = Database.shared
            let _ = RegexParser.shared
            let _ = CacheManager.shared
        }
        let _ = AutoCorrect.shared
    }
}
