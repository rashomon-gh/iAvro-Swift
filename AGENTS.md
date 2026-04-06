# AGENTS.md

## Project Overview

iAvro-Swift is a macOS Input Method Kit (IMK) application providing Bangla phonetic typing via Avro Phonetic. 

## Build & Run

```bash
xcodebuild -project iAvro-Swift.xcodeproj -scheme "iAvro-Swift" -configuration Debug build
```

The built app is at `~/Library/Developer/Xcode/DerivedData/iAvro-Swift-*/Build/Products/Debug/Avro Keyboard.app`.

To install as an input method, copy the `.app` bundle to `/Library/Input Methods/` and log out/in.

## Architecture

- **Deployment target**: macOS 15.3
- **No sandboxing** (`ENABLE_APP_SANDBOX = NO`)
- **No external dependencies** — uses `SQLite3` C API (linked via `OTHER_LDFLAGS = "-lsqlite3"`) and `NSRegularExpression` instead of CocoaPods (FMDB, RegexKitLite)
- **Entry point**: `main.swift` (top-level code, NOT `@main`)

### Source Files (`iAvro-Swift/`)

| File | Purpose |
|---|---|
| `main.swift` | Entry point: creates `IMKServer`, loads singletons |
| `AvroParser.swift` | Converts Romanized text to Bangla using `data.json` patterns (binary search) |
| `RegexParser.swift` | Generates regex patterns from `regex.json` for dictionary lookups |
| `Database.swift` | Loads Bangla dictionary from `database.db3` (SQLite3 C API) |
| `Suggestion.swift` | Combines phonetic parse + dictionary + autocorrect + suffix handling |
| `AutoCorrect.swift` | Loads autocorrect entries from `autodict.plist` |
| `CacheManager.swift` | Caches suggestions to `~/Library/Application Support/OmicronLab/Avro Keyboard/weight.plist` |
| `Candidates.swift` | `IMKCandidates` subclass (shared instance) |
| `AvroKeyboardController.swift` | Main `IMKInputController` — handles keystrokes, composition, candidate selection |
| `MainMenuAppDelegate.swift` | App delegate with status bar menu |
| `IMPreferences.swift` | Registers defaults from `preferences.plist` |
| `PreferencesWindowController.swift` | SwiftUI-based preferences window (General + About tabs) |
| `Levenshtein.swift` | `String` extension for Levenshtein distance |
| `Info.plist` | Custom plist with IMK keys (InputMethodConnectionName, TISIntendedLanguage, etc.) |

### Key Resources (bundled)

- `data.json` — phonetic conversion patterns
- `regex.json` — regex generation patterns
- `database.db3` — SQLite Bangla dictionary (~47 tables + Suffix table)
- `autodict.plist` — autocorrect dictionary (English→Bangla, ~1800+ entries)
- `preferences.plist` — default user preferences

## Key Patterns

### XOR Logic
Old ObjC used `^` (XOR) for boolean logic: `!(condition ^ isNegative)`. In Swift, this is `condition == isNegative`. Similarly `(sub == needle) ^ not` becomes `(sub == needle) != not`.

### IMK Methods
Action methods like `deleteBackward`, `insertTab`, `insertNewline`, `moveUp/Down/Left/Right` are NOT overrides of `IMKInputController` — they are `@objc` methods dispatched via `didCommand(by:client:)`. Use `@objc` without `override`.

### IMKCandidates Properties
`attributes` and `dismissesAutomatically` are methods in Swift (not properties). Use `setAttributes(_:)` and `setDismissesAutomatically(_:)`.

## Conventions

- No external SPM packages
- Swift 5, no strict concurrency (removed `SWIFT_APPROACHABLE_CONCURRENCY`, `SWIFT_DEFAULT_ACTOR_ISOLATION`)
- `GENERATE_INFOPLIST_FILE = YES` with custom `Info.plist` via `INFOPLIST_FILE`
