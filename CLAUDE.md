# Claude Code Guide for iAvro-Swift

## ✅ Project Status: WORKING (April 2026)

**Current Status**: The pure Swift port is now fully functional! All IMKServer registration and UI rendering issues have been resolved.

The Swift port successfully:
- ✅ Registers with macOS Input Method system
- ✅ Appears in System Preferences → Keyboard → Input Sources
- ✅ Handles keyboard input and converts to Bangla script
- ✅ Displays candidate panel with word suggestions
- ✅ Shows correct icon in input method switching menu

## Project Overview

iAvro-Swift is a pure Swift port of the original Objective-C version located at `/Users/shawon/Projects/iAvro`. This is a macOS Input Method Kit (IMK) application providing Bangla phonetic typing.

**Critical Context**: This is an input method that runs as a background application, intercepting keyboard events and converting Romanized text to Bangla script.

## Issues Resolved (April 2026)

### 1. IMKServer Registration Issue ✅ FIXED
**Problem**: Swift app couldn't register IMKServer connection
- Error: `[_IMKServerLegacy _createConnection] could not register org.shawonashraf.iAvro-Swift_Connection`

**Solution**: Changed bundle identifier to match working version
- From: `org.shawonashraf.iAvro-Swift`
- To: `com.omicronlab.inputmethod.AvroKeyboard`

### 2. Menu Icon Rendering Issue ✅ FIXED
**Problem**: Oversized blue background in input method switching menu

**Solution**: Two-part fix
- Removed `AccentColor.colorset` (SwiftUI default asset causing conflicts)
- Changed `tsInputMethodIconFileKey` from `"AppIcon"` to `"MenuIcon"`

### 3. UserDefaults Initialization Order ✅ FIXED
**Problem**: Wrong panel type (0 instead of 1) causing rendering issues

**Solution**: Initialize `IMPreferences` before `Candidates.allocateSharedInstance()` to ensure defaults are registered

### 4. NIB File Reference ✅ FIXED
**Problem**: Info.plist referenced non-existent `NSMainNibFile`

**Solution**: Removed `NSMainNibFile` key (Swift version uses programmatic UI)

## Swift Port Architecture & Conventions

### Project Structure
- **Entry point**: `main.swift` (top-level code, NOT `@main`)
- **No sandboxing**: `ENABLE_APP_SANDBOX = NO`
- **No external dependencies**: Uses SQLite3 C API and NSRegularExpression only
- **Deployment target**: macOS 15.3
- **Activation policy**: `.accessory` (background-only application)

### Critical Files
| File | Purpose |
|---|---|
| `main.swift` | Entry point, initializes IMKServer and singletons |
| `AvroKeyboardController.swift` | Main IMKInputController for handling keystrokes |
| `MainMenuAppDelegate.swift` | App delegate with status bar menu and lifecycle |
| `Candidates.swift` | IMKCandidates singleton wrapper for candidate panel |
| `AvroParser.swift` | Converts Romanized text to Bangla using data.json patterns |
| `Suggestion.swift` | Combines phonetic parse + dictionary + autocorrect + suffix handling |
| `IMPreferences.swift` | Manages default preferences and preferences window |

### Key Configuration Files
- `Info.plist`: Input method metadata (connection name, controller class, icon)
- `preferences.plist`: Default user preferences (panel type, dictionary settings)
- `Assets.xcassets`: Icon resources (MenuIcon, AppIcon)

## Build & Install

### Building
```bash
cd /Users/shawon/Projects/iAvro-Swift
xcodebuild -project iAvro-Swift.xcodeproj -scheme "iAvro-Swift" -configuration Release build
```

### Installing
```bash
sudo cp -R "/Users/shawon/Library/Developer/Xcode/DerivedData/iAvro-Swift-awhpqmexxxvnbwcaoftitoddmbyk/Build/Products/Release/Avro Keyboard.app" "/Library/Input Methods/"
```

### Testing Input Methods
1. Install to `/Library/Input Methods/`
2. Log out/in (required for macOS to register)
3. Enable in System Preferences → Keyboard → Input Sources
4. Switch to input method in any text field
5. Test typing, candidate selection, commitment

## Key Differences from Objective-C Version

The original is at `/Users/shawon/Projects/iAvro`. Key differences:
- **ObjC**: Uses NIB files | **Swift**: Programmatic UI
- **ObjC**: Uses CocoaPods (FMDB, RegexKitLite) | **Swift**: No dependencies
- **ObjC**: Legacy ObjC patterns | **Swift**: Modern Swift patterns
- **Both**: Use same IMK framework and core logic
- **Both versions now work reliably**

## Critical Configuration Details

### Bundle Identifier
```
com.omicronlab.inputmethod.AvroKeyboard
```
Must match the working version for IMKServer registration.

### Connection Name
```
Avro_Keyboard_Connection
```
Used for IMKServer communication with client applications.

### Icon Reference
```
tsInputMethodIconFileKey = MenuIcon
```
Must reference `MenuIcon` asset, not `AppIcon`.

### Assets to Avoid
- **Do NOT use**: `AccentColor.colorset` (causes rendering conflicts)
- **Do NOT use**: `NSMainNibFile` in Info.plist (no NIB in Swift version)

## Lessons Learned

1. **Bundle Identifier Matters**: IMKServer registration requires exact match with working version
2. **SwiftUI Assets Conflict**: Default SwiftUI assets can interfere with IMK rendering
3. **Icon Reference Critical**: Must use correct icon file key for menu display
4. **Initialization Order**: UserDefaults defaults must be registered before use
5. **No NIB Files Needed**: Pure Swift can do everything programmatically

## Git Workflow
- Main branch: `main` (use for PRs)
- Current branch: `fix`
- The Swift port on this branch is now fully functional

## Comparison: Swift vs Objective-C

| Aspect | Objective-C | Swift |
|---|---|---|
| IMK Integration | Mature | Working ✅ |
| Build System | Complex (CocoaPods) | Simple (no deps) |
| UI Implementation | NIB-based | Programmatic |
| Code Style | Legacy ObjC | Modern Swift |
| Performance | Proven | Equivalent |
| Maintenance | Older | Active |

## Future Work

Potential improvements:
- Migrate preferences window to SwiftUI fully (partially done)
- Consider async/await for database operations
- Add unit tests for parser and suggestion engine
- Explore SwiftUI candidates panel (currently IMKCandidates)

## Resources

- **Original Objective-C version**: `$HOME/Projects/iAvro`
- **Working installation**: `/Library/Input Methods/Avro Keyboard.app`
- **Build output**: `$HOME/Library/Developer/Xcode/DerivedData/iAvro-Swift-*/Build/Products/Release/`
