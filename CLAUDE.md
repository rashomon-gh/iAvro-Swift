# Claude Code Guide for iAvro-Swift

## Project Overview

iAvro-Swift is a macOS Input Method Kit (IMK) application providing Bangla phonetic typing. This is a Swift port of the original Objective-C version located at `/Users/shawon/Projects/iAvro`.

**Critical Context**: This is an input method that runs as a background application, intercepting keyboard events and converting Romanized text to Bangla script.

## Recent Critical Fixes (April 2026)

Major crash and input registration issues were fixed:
- MainMenuAppDelegate initialization was failing due to missing NIB file loading
- Candidates method signatures were incorrect for Swift/IMKCandidates bridge
- IMK constants were being used as magic numbers
- **All singletons must be initialized in the correct order before NSApp.run()**

See `CRASH_FIXES.md` for detailed information.

## Architecture & Conventions

### Project Structure
- **Entry point**: `main.swift` (top-level code, NOT `@main`)
- **No sandboxing**: `ENABLE_APP_SANDBOX = NO`
- **No external dependencies**: Uses SQLite3 C API and NSRegularExpression only
- **Deployment target**: macOS 15.3

### Critical Files
| File | Purpose |
|---|---|
| `main.swift` | Entry point: creates IMKServer, loads singletons, sets up app delegate |
| `AvroKeyboardController.swift` | Main IMKInputController — handles keystrokes, composition, candidates |
| `MainMenuAppDelegate.swift` | App delegate with status bar menu and singleton initialization |
| `Candidates.swift` | IMKCandidates singleton wrapper for candidate panel |
| `AvroParser.swift` | Converts Romanized text to Bangla using data.json patterns |
| `Suggestion.swift` | Combines phonetic parse + dictionary + autocorrect + suffix handling |

### Key Patterns

#### IMK Method Signatures
- Action methods (`deleteBackward`, `insertTab`, `insertNewline`, `moveUp/Down/Left/Right`) are `@objc` methods, **NOT** `override` methods
- They are dispatched via `didCommand(by:client:)`, not direct overrides
- Example: `@objc func moveUp(_ sender: Any?)` not `override func moveUp(_ sender: Any?)`

#### IMKCandidates Properties vs Methods
- `attributes` and `dismissesAutomatically` are **methods** in Swift, not properties
- Use `setAttributes(_:)` and `setDismissesAutomatically(_:)`
- `isVisible` is a method: `isVisible()` not `isVisible`
- `panelType` returns `IMKCandidatePanelType`, not `Int`

#### IMK Constants
Use proper constants, not magic numbers:
- `kIMKLocateCandidatesBelowHint` for positioning
- `kIMKSingleColumnScrollingCandidatePanel` for vertical panel
- `kIMKSingleRowSteppingCandidatePanel` for horizontal panel

#### XOR Logic Translation
Old ObjC used `^` (XOR) for boolean logic:
- `!(condition ^ isNegative)` → Swift: `condition == isNegative`
- `(sub == needle) ^ not` → Swift: `(sub == needle) != not`

#### Initialization Order (Critical!)
Singletons **must** be initialized in this exact order:
1. `AvroParser.shared`
2. `Suggestion.shared`
3. `IMPreferences()`
4. `IMKServer`
5. `Candidates.setupSharedInstance(with: server)`
6. `MainMenuAppDelegate` setup (triggers Database, RegexParser, CacheManager, AutoCorrect)

#### No NIB Files
The Swift version doesn't use NIB files. All UI is created programmatically:
- Menu is created in `MainMenuAppDelegate.setupMenu()`
- All initialization must happen explicitly in code

## Swift Specific Considerations

### Swift/ObjC Bridge
- Classes exposed to IMK need `@objc(ClassName)` annotation
- Methods called from ObjC runtime need `@objc` annotation
- Use proper types: `IMKCandidatePanelType` not `Int`

### Memory Management
- Swift uses ARC, no manual retain/release
- But IMK objects still need proper lifecycle management
- Candidates singleton must be explicitly managed

### UserDefaults
- Use `UserDefaults.standard` (not `NSUserDefaults`)
- Register defaults from bundled `preferences.plist`

## Resources Bundled
- `data.json` — phonetic conversion patterns
- `regex.json` — regex generation patterns
- `database.db3` — SQLite Bangla dictionary (~47 tables)
- `autodict.plist` — autocorrect dictionary (~1800 entries)
- `preferences.plist` — default user preferences
- `Info.plist` — IMK configuration

## Build & Run

```bash
# Build
xcodebuild -project iAvro-Swift.xcodeproj -scheme "iAvro-Swift" -configuration Debug build

# Built app location
~/Library/Developer/Xcode/DerivedData/iAvro-Swift-*/Build/Products/Debug/Avro Keyboard.app
```

**Installation**:
```bash
# Copy to system input methods directory
cp -R "Avro Keyboard.app" /Library/Input\ Methods/

# Log out and back in for system to recognize
```

## Testing IMK Applications
Input methods are tricky to test:
1. Install to `/Library/Input Methods/`
2. Log out/in (required for macOS to register)
3. Enable in System Preferences → Keyboard → Input Sources
4. Switch to input method in any text field
5. Test typing, candidate selection, commitment

## Common Pitfalls

### Crashes on Activation
- Check singleton initialization order in `main.swift`
- Verify all singletons are initialized before `NSApp.run()`
- Ensure `MainMenuAppDelegate.initializeSingletons()` is called

### No Input Registered
- Check `Info.plist` has correct `InputMethodServerControllerClass`
- Verify class is exposed to ObjC: `@objc(AvroKeyboardController)`
- Ensure IMKServer is created with correct connection name

### Build Issues
- Swift's IMKCandidates signatures differ from ObjC
- Need `override` keyword for some methods
- Check that `@objc` annotations are present for IMK callbacks

### Candidate Panel Issues
- Use correct constants, not integers
- `panelType()` returns `IMKCandidatePanelType`, not `Int`
- Call methods with parentheses: `isVisible()` not `isVisible`

## Comparison with Objective-C Version
The original is at `/Users/shawon/Projects/iAvro`. Key differences:
- ObjC uses NIB files, Swift uses programmatic UI
- ObjC uses CocoaPods (FMDB, RegexKitLite), Swift uses no dependencies
- Swift uses modern Swift 5 syntax and ARC
- IMKCandidates method signatures differ between Swift and ObjC

## Git Workflow
- Main branch: `main` (use for PRs)
- Current branch: `fix`
- Clean status required before builds
- Use `git status` to check state before making changes