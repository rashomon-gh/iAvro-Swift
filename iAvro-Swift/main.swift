import Cocoa
import InputMethodKit

/// Connection name used to communicate between the input method server and client applications.
let kConnectionName = "Avro_Keyboard_Connection"

// Eagerly initialize the phonetic parser and suggestion engine at launch.
let _ = AvroParser.shared
let _ = Suggestion.shared
let imPref = IMPreferences()

guard let identifier = Bundle.main.bundleIdentifier else {
    fatalError("No bundle identifier found")
}

/// The IMK server that handles communication with client applications.
let server = IMKServer(name: kConnectionName, bundleIdentifier: identifier)!
Candidates.setupSharedInstance(with: server)

let appDelegate = MainMenuAppDelegate()
NSApp.delegate = appDelegate
appDelegate.imPref = imPref
appDelegate.setupMenu()

NSApp.run()
