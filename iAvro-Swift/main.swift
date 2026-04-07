import Cocoa
import InputMethodKit

/// Connection name used to communicate between the input method server and client applications.
let kConnectionName = "Avro_Keyboard_Connection"

// Eagerly initialize the phonetic parser and suggestion engine at launch (matches ObjC order)
let _ = AvroParser.shared
let _ = Suggestion.shared

print("iAvro: Starting initialization...")

// Ensure NSApp is properly initialized before any other setup
let app = NSApplication.shared
print("iAvro: NSApplication initialized")

// Get bundle identifier FIRST, before anything else
guard let identifier = Bundle.main.bundleIdentifier else {
    fatalError("No bundle identifier found")
}
print("iAvro: Bundle identifier: \(identifier)")

/// The IMK server that handles communication with client applications.
print("iAvro: Creating IMKServer with connection name: \(kConnectionName)")
let server: IMKServer
if let tempServer = IMKServer(name: kConnectionName, bundleIdentifier: identifier) {
    server = tempServer
    print("iAvro: ✅ IMKServer created with bundle identifier")
} else {
    print("iAvro: ⚠️  IMKServer creation returned nil, trying fallback...")
    print("iAvro: This may be OK - some macOS versions handle this differently")

    // Try creating without bundle identifier
    guard let fallbackServer = IMKServer(name: kConnectionName, bundleIdentifier: nil) else {
        fatalError("Failed to create any IMKServer")
    }
    server = fallbackServer
    print("iAvro: ✅ Fallback IMKServer created")
}

print("iAvro: ✅ IMKServer creation complete")

// Setup the shared candidates panel
print("iAvro: Setting up Candidates...")
Candidates.allocateSharedInstance(with: server)
print("iAvro: Candidates setup complete")

// Create and configure the app delegate
print("iAvro: Creating app delegate...")
let appDelegate = MainMenuAppDelegate()
print("iAvro: App delegate created")

print("iAvro: Setting app delegate...")
NSApplication.shared.delegate = appDelegate
print("iAvro: App delegate set")

print("iAvro: Configuring app delegate...")
appDelegate.setupMenu()
print("iAvro: App delegate configured")

// Run the application
print("iAvro: ✅ Starting NSApplication.run()...")
NSApplication.shared.run()