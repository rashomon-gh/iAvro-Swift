import Cocoa
import InputMethodKit

let kConnectionName = "Avro_Keyboard_Connection"

let _ = AvroParser.shared
let _ = Suggestion.shared
let imPref = IMPreferences()

guard let identifier = Bundle.main.bundleIdentifier else {
    fatalError("No bundle identifier found")
}

let server = IMKServer(name: kConnectionName, bundleIdentifier: identifier)!
Candidates.setupSharedInstance(with: server)

let appDelegate = MainMenuAppDelegate()
NSApp.delegate = appDelegate
appDelegate.imPref = imPref
appDelegate.setupMenu()

NSApp.run()
