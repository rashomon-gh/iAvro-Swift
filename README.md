# iAvro-Swift

A Swift rewrite of [iAvro](https://github.com/torifat/iAvro).

## Requirements

- macOS 15.3+
- Xcode 16+

## Build

```bash
xcodebuild -project iAvro-Swift.xcodeproj -scheme "iAvro-Swift" -configuration Debug build
```

Or open `iAvro-Swift.xcodeproj` in Xcode and press Cmd+B.

## Install as Input Method

1. Build the project
2. Copy the built `iAvro-Swift.app` to `/Library/Input Methods/`:
   ```bash
   sudo cp -R ~/Library/Developer/Xcode/DerivedData/iAvro-Swift-*/Build/Products/Debug/iAvro-Swift.app /Library/Input\ Methods/
   ```
3. Log out and log back in
4. Go to **System Settings → Keyboard → Input Sources → Edit → +** and add **iAvro-Swift** from the Bengali section



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

## License

Same as original iAvro project.
