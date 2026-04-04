import Cocoa
import InputMethodKit

@objc(MainMenuAppDelegate)
class MainMenuAppDelegate: NSObject, NSApplicationDelegate {
    @objc var imPref: IMPreferences?
    @objc let menu = NSMenu()

    @objc func setupMenu() {
        let preferencesItem = NSMenuItem(title: "Preferences...", action: #selector(showPreferences(_:)), keyEquivalent: ",")
        preferencesItem.tag = 1
        menu.addItem(preferencesItem)
    }

    @objc func showPreferences(_ sender: Any?) {
        guard let imPref = imPref else { return }
        let pw = imPref.windowController.window
        pw?.hidesOnDeactivate = false
        pw?.level = .modalPanel
        pw?.makeKeyAndOrderFront(self)
    }

    @objc func applicationWillTerminate(_ notification: Notification) {
        if UserDefaults.standard.bool(forKey: "IncludeDictionary") {
            CacheManager.shared.persist()
        }
    }

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
