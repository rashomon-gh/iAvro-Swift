# iAvro-Swift

| Build | Release |
|-------|---------|
| [![Build](https://github.com/rashomon-gh/iAvro-Swift/actions/workflows/build.yml/badge.svg)](https://github.com/rashomon-gh/iAvro-Swift/actions/workflows/build.yml) | [![Release](https://github.com/rashomon-gh/iAvro-Swift/actions/workflows/release.yml/badge.svg)](https://github.com/rashomon-gh/iAvro-Swift/actions/workflows/release.yml) |

A Swift rewrite of [iAvro](https://github.com/torifat/iAvro).

## Requirements

- macOS 15.3+
- Xcode 16+ (for local development)


## Local Development

### Build

```bash
xcodebuild -project iAvro-Swift.xcodeproj -scheme "iAvro-Swift" -configuration Release build
```

Or open `iAvro-Swift.xcodeproj` in Xcode and press Cmd+B.

**Note**: Use `Release` configuration for production builds. The `Debug` configuration works but may have different performance characteristics.

### Install as Input Method

1. Build the project in Release configuration
2. Copy the built app to the Input Methods directory:

```bash
sudo cp -R ~/Library/Developer/Xcode/DerivedData/iAvro-Swift-*/Build/Products/Release/Avro\ Keyboard.app /Library/Input\ Methods/
```

3. **Log out of your user account completely**
4. **Log back in** (this is required for macOS to register the input method)
5. Go to **System Settings → Keyboard → Input Sources → Edit → +** and add **Avro Keyboard** from the Bangla section

**Finding the built app**: Xcode stores build outputs in a hashed directory. The path above uses a wildcard to match it. You can also find the exact path by running:

```bash
xcodebuild -project iAvro-Swift.xcodeproj -scheme "iAvro-Swift" -showBuildSettings | grep BUILT_PRODUCTS_DIR
```

**Finding the built app**: Xcode stores build outputs in a hashed directory. The path above uses a wildcard to match it. You can also find the exact path by running:

```bash
xcodebuild -project iAvro-Swift.xcodeproj -scheme "iAvro-Swift" -showBuildSettings | grep BUILT_PRODUCTS_DIR
```



## Project Structure

```
iAvro-Swift/
├── main.swift                    # Entry point
├── AvroParser.swift              # Phonetic conversion engine
├── RegexParser.swift             # Regex pattern generator
├── Database.swift                # SQLite dictionary access
├── Suggestion.swift              # Suggestion engine
├── AutoCorrect.swift             # Autocorrect lookup
├── CacheManager.swift            # Suggestion caching
├── Candidates.swift              # IMK candidate panel
├── AvroKeyboardController.swift  # Input controller
├── MainMenuAppDelegate.swift     # App delegate
├── IMPreferences.swift           # Preferences management
├── PreferencesWindowController.swift  # SwiftUI preferences UI
├── Levenshtein.swift             # Levenshtein distance
├── Info.plist                    # IMK configuration
├── data.json                     # Phonetic patterns
├── regex.json                    # Regex patterns
├── database.db3                  # Bangla dictionary
├── autodict.plist                # Autocorrect entries
├── preferences.plist             # Default preferences
└── Assets.xcassets/              # App & menu icons
```
