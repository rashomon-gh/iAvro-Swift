# iAvro-Swift

A Swift rewrite of [iAvro](https://github.com/torifat/iAvro).

## Requirements

- macOS 15.3+
- Xcode 16+

## Installation

Download the zip file from the Release section, then:
1. Unzip and copy the `Avro Keyboard.app` to `~/Library/Input Methods/`
2. Go to **System Settings → Keyboard → Input Sources → Edit → +** and add **Avro Keyboard** from the Bengali section



## Local Development

### Build

```bash
xcodebuild -project iAvro-Swift.xcodeproj -scheme "iAvro-Swift" -configuration Debug build
```

Or open `iAvro-Swift.xcodeproj` in Xcode and press Cmd+B.

### Install as Input Method

1. Build the project
2. Copy the build binary from `~/Library/Developer/Xcode/DerivedData/`. 
Apparently Xcode stores binaries with a hash for each build.
3. Go to **System Settings → Keyboard → Input Sources → Edit → +** and add **Avro Keyboard** from the Bengali section



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
├── database.db3                  # Bengali dictionary
├── autodict.plist                # Autocorrect entries
├── preferences.plist             # Default preferences
└── Assets.xcassets/              # App & menu icons
```
