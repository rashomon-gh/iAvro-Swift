import Cocoa
import InputMethodKit

/// Connection name used to communicate between the input method server and client applications.
let kConnectionName = "Avro_Keyboard_Connection"

// Eagerly initialize the phonetic parser and suggestion engine at launch (matches ObjC order)
let _ = AvroParser.shared
let _ = Suggestion.shared
let imPref = IMPreferences()

guard let identifier = Bundle.main.bundleIdentifier else {
    fatalError("No bundle identifier found")
}

/// The IMK server that handles communication with client applications.
guard let server = IMKServer(name: kConnectionName, bundleIdentifier: identifier) else {
    fatalError("Failed to create IMKServer")
}

// Setup the shared candidates panel
Candidates.setupSharedInstance(with: server)

// Create and configure the app delegate
let appDelegate = MainMenuAppDelegate()
NSApp.delegate = appDelegate
appDelegate.imPref = imPref
appDelegate.setupMenu()

// Run the application
NSApp.run()
