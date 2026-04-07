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

### 3. IMKCandidates Constants Usage
**Problem**: Hard-coded integer values were used instead of proper IMK constants.

**Fix**:
- Changed `Candidates.shared.show(1)` to `Candidates.shared.show(kIMKLocateCandidatesBelowHint)`
- Changed `panelType() == 1` to `panelType() == kIMKSingleColumnScrollingCandidatePanel`
- Changed `panelType() == 2` to `panelType() == kIMKSingleRowSteppingCandidatePanel`

### 4. Main.swift Initialization Order
**Problem**: Initialization order didn't match the working Objective-C version.

**Fix**:
- Ensured singletons are initialized in the correct order: AvroParser → Suggestion → IMPreferences
- Added proper error handling for IMKServer creation
- Ensured app delegate setup happens before `NSApp.run()`

## Testing
The project now builds successfully without errors. The input method should:
- Not crash when activated
- Properly initialize all singletons (AvroParser, Suggestion, Database, RegexParser, CacheManager, AutoCorrect)
- Register input correctly
- Show candidate suggestions when typing

## Next Steps for Testing
1. Install the built app to `/Library/Input Methods/`
2. Log out and log back in
3. Enable "Avro Keyboard" in System Preferences → Keyboard → Input Sources
4. Test typing in various applications to ensure:
   - No crashes on activation
   - Phonetic conversion works
   - Candidate panel appears
   - Selection and commitment work correctly

## Files Modified
- `iAvro-Swift/MainMenuAppDelegate.swift`
- `iAvro-Swift/main.swift`
- `iAvro-Swift/Candidates.swift`
- `iAvro-Swift/AvroKeyboardController.swift`

## Key Differences from Objective-C Version
1. No NIB file - menu and initialization are done programmatically
2. Swift/ObjC bridge requires proper `@objc` annotations
3. IMKCandidates methods have different signatures in Swift
4. Need to use proper IMK constants instead of magic numbers