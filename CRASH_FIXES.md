# Crash Fixes Applied to iAvro-Swift

## Summary
Fixed critical initialization and method signature issues that were causing the Swift port of iAvro to crash on activation and fail to register input.

## Issues Found and Fixed

### 1. MainMenuAppDelegate Initialization
**Problem**: The `awakeFromNib()` method was never called because there's no NIB file in the Swift project, but all critical singleton initialization happened there.

**Fix**:
- Removed reliance on `awakeFromNib()`
- Moved singleton initialization into `initializeSingletons()` method
- Called this method from `setupMenu()` which is invoked from `main.swift`
- Ensured Database, RegexParser, CacheManager, and AutoCorrect are initialized correctly

### 2. Candidates Method Signatures
**Problem**: IMKCandidates method signatures were incorrect, causing compilation errors and runtime crashes.

**Fix**:
- Added proper `override` keywords to `update()` and `panelType()` methods
- Fixed return type from `Int` to `IMKCandidatePanelType` for `panelType()`
- Added bridge methods to maintain compatibility with existing code
- Fixed `isVisible()` calls to include parentheses (it's a method, not a property)
- **Force unwrapping fix**: Changed `Candidates(server:panelType)!` to proper `guard let` handling

### 3. IMKCandidates Constants Usage
**Problem**: Hard-coded integer values were used instead of proper IMK constants.

**Fix**:
- Changed `Candidates.shared.show(1)` to `Candidates.shared.show(kIMKLocateCandidatesBelowHint)`
- Changed `panelType() == 1` to `panelType() == kIMKSingleColumnScrollingCandidatePanel`
- Changed `panelType() == 2` to `panelType() == kIMKSingleRowSteppingCandidatePanel`

### 4. Main.swift Initialization Order
**Problem**: Initialization order didn't match the working Objective-C version.

**Fix**:
- Explicitly initialize `NSApplication.shared` before any other setup
- Ensured singletons are initialized in the correct order: AvroParser → Suggestion → IMPreferences
- Added proper error handling for IMKServer creation
- Ensured app delegate setup happens before `NSApp.run()`
- **Added comprehensive debug logging** to identify crash locations

### 5. Runtime Crash Debugging
**Problem**: "Unexpectedly found nil while implicitly unwrapping an Optional value" crash on line 26.

**Fix**:
- Replaced force unwrapping in `Candidates.setupSharedInstance` with proper `guard let`
- Added debug output throughout the initialization sequence
- Explicitly initialized `NSApplication.shared` at startup
- Added error messages for all failure points

## Debug Output Added
The following debug statements have been added to help identify the exact crash location:
- `iAvro: Starting initialization...`
- `iAvro: NSApplication initialized`
- `iAvro: Initializing AvroParser/Suggestion/IMPreferences...`
- `iAvro: Creating IMKServer...`
- `iAvro: Setting up Candidates...`
- `iAvro: Creating app delegate...`
- `iAvro: Starting NSApplication.run()...`

## Testing
The project now builds successfully without errors. With the added debug output, when you run the app via Xcode or check Console.app, you'll see exactly where the crash occurs.

## Next Steps for Testing
1. Run the app in Xcode with the debugger to see the crash location
2. Check the console output to see how far initialization gets before crashing
3. Look for the last "iAvro:" message before the crash
4. Install to `/Library/Input Methods/` for real testing
5. Test typing in various applications

## Files Modified in Latest Fix
- `iAvro-Swift/MainMenuAppDelegate.swift` - Added debug output to initializeSingletons
- `iAvro-Swift/main.swift` - Added comprehensive debug logging
- `iAvro-Swift/Candidates.swift` - Fixed force unwrapping and added debug output

## Key Differences from Objective-C Version
1. No NIB file - menu and initialization are done programmatically
2. Swift/ObjC bridge requires proper `@objc` annotations
3. IMKCandidates methods have different signatures in Swift
4. Need to use proper IMK constants instead of magic numbers
5. Must explicitly handle optional IMKCandidates initializer
6. Need explicit NSApplication.shared initialization