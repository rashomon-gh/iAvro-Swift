# Claude Code Guide for iAvro-Swift

## ⚠️ Important Note About This Project

**Current Status**: The pure Swift port has fundamental IMKServer registration issues. Use the working Objective-C version instead.

**See SOLUTION.md for the working solution.**

## Project Overview

iAvro-Swift was intended as a Swift port of the original Objective-C version located at `/Users/shawon/Projects/iAvro`. This is a macOS Input Method Kit (IMK) application providing Bangla phonetic typing.

**Critical Context**: This is an input method that runs as a background application, intercepting keyboard events and converting Romanized text to Bangla script.

## Recent Critical Discovery (April 2026)

After extensive debugging, we found that:
- **Pure Swift input methods cannot properly register IMKServer connections**
- Error: `[_IMKServerLegacy _createConnection] could not register org.shawonashraf.iAvro-Swift_Connection`
- **The Swift/ObjC bridge has complex build dependencies that prevent reliable IMK setup**
- **Input methods are extremely sensitive to initialization timing**

**Recommendation**: Use the working Objective-C version at `/Users/shawon/Projects/iAvro`. The Swift port is not currently viable.

## Swift Port Architecture & Conventions (For Reference)

### Project Structure
- **Entry point**: Was `main.swift` (top-level code, NOT `@main`)
- **No sandboxing**: `ENABLE_APP_SANDBOX = NO`
- **No external dependencies**: Uses SQLite3 C API and NSRegularExpression only
- **Deployment target**: macOS 15.3

### Critical Files
| File | Purpose |
|---|---|
| `main.swift` | Entry point (removed - using Objective-C main.m instead) |
| `AvroKeyboardController.swift` | Main IMKInputController (removed - using Objective-C version) |
| `MainMenuAppDelegate.swift` | App delegate with status bar menu and singleton initialization |
| `Candidates.swift` | IMKCandidates singleton wrapper for candidate panel |
| `AvroParser.swift` | Converts Romanized text to Bangla using data.json patterns |
| `Suggestion.swift` | Combines phonetic parse + dictionary + autocorrect + suffix handling |

### Known Issues with Swift Port

1. **IMKServer Registration Failure**: Swift classes cannot properly register with IMK framework
2. **Swift-ObjC Bridge Build Dependencies**: Objective-C files compile before Swift, preventing proper bridging
3. **Class Discovery Issues**: macOS Input Method system cannot discover Swift-based input methods
4. **Initialization Timing**: IMK requires very specific initialization sequence that Swift doesn't support

### What Was Learned

- **Input methods MUST use Objective-C for IMK setup**
- **Swift can be used for logic only, not framework integration**
- **Hybrid approaches have complex build system requirements**
- **The working Objective-C version is the only reliable solution**

## Resources and Working Solution

- **Working version**: `/Users/shawon/Projects/iAvro` (Objective-C)
- **Installation script**: `/tmp/install_working_version.sh`
- **Detailed analysis**: `SOLUTION.md`
- **Crash investigation**: `CRASH_FIXES.md`

## Build & Run (For Reference)

The Swift project builds but doesn't work as an input method:
```bash
xcodebuild -project iAvro-Swift.xcodeproj -scheme "iAvro-Swift" -configuration Debug build
```

**However, it will not appear in System Preferences due to IMKServer registration issues.**

## Testing Input Methods

Input methods are tricky to test:
1. Install to `/Library/Input Methods/`
2. Log out/in (required for macOS to register)
3. Enable in System Preferences → Keyboard → Input Sources
4. Switch to input method in any text field
5. Test typing, candidate selection, commitment

## Key Differences from Objective-C Version

The original is at `/Users/shawon/Projects/iAvro`. Key differences:
- ObjC uses NIB files, Swift attempted programmatic UI
- ObjC uses CocoaPods (FMDB, RegexKitLite), Swift uses no dependencies
- **Swift version cannot register IMKServer - this is the critical issue**
- IMKCandidates method signatures differ between Swift and ObjC
- **Objective-C version works reliably**

## Recommended Approach

1. **Use the working Objective-C version for daily use**
2. **Only consider Swift migration for non-critical components**
3. **Never attempt to rewrite IMK setup in Swift**
4. **Input methods are too critical to rely on experimental approaches**

## Git Workflow
- Main branch: `main` (use for PRs)
- Current branch: `fix`
- The Swift port on this branch is not functional as an input method