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

        // Initialize dictionary and singletons if dictionary is enabled
        initializeSingletons()
    }

    /// Initializes dictionary-related singletons based on user preferences.
    ///
    /// This replicates the awakeFromNib() behavior from the Objective-C version,
    /// loading Database, RegexParser, CacheManager, and AutoCorrect singletons.
    private func initializeSingletons() {
        if UserDefaults.standard.bool(forKey: "IncludeDictionary") {
            print("Loading Dictionary...")
            let _ = Database.shared
            let _ = RegexParser.shared
            let _ = CacheManager.shared
        }
        let _ = AutoCorrect.shared
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
