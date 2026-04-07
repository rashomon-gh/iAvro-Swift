import Cocoa
import InputMethodKit

/// The main input controller that handles keystrokes, composition, and candidate selection.
///
/// Registered with IMK as `AvroKeyboardController` (via the `@objc` name and `Info.plist`).
/// Receives key events from client applications, builds a composition buffer, generates
/// Bangla suggestions, and manages the candidate panel.
@objc(AvroKeyboardController)
class AvroKeyboardController: IMKInputController {

    // MARK: - State

    /// The current client application receiving text input.
    private var currentClient: AnyObject?

    /// Index of the previously selected candidate (for restoring selection).
    private var prevSelected: Int = -1

    /// The current inline composition buffer (raw Romanized input).
    private var composedBuffer: String = ""

    /// The current list of candidate strings shown in the panel.
    private var currentCandidates: [Any] = []

    /// Index of the candidate that will be committed on space/enter.
    private var selectedCandidateIndex: Int = 0

    /// Bangla prefix parsed from punctuation at the start of the buffer.
    private var prefix: String = ""

    /// The core input term extracted from the composition buffer.
    private var term: String = ""

    /// Bangla suffix parsed from punctuation at the end of the buffer.
    private var suffix: String = ""

    /// Whether the user navigated candidates with arrow keys (triggers cache persist).
    private var usedArrowKeys: Bool = false

    // MARK: - Initialization

    @objc public override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        super.init(server: server, delegate: delegate, client: inputClient)
        currentClient = inputClient as AnyObject?
    }

    // MARK: - Candidate Generation

    /// Parses the composition buffer into prefix/term/suffix and generates suggestions.
    ///
    /// Uses a regex to split the buffer into three parts:
    /// - Group 1: Leading punctuation → converted to Bangla as `prefix`
    /// - Group 2: The core input term → used for suggestion lookup
    /// - Group 3: Trailing punctuation → converted to Bangla as `suffix`
    ///
    /// Each candidate is assembled as `prefix + BanglaWord + suffix`.
    private func findCurrentCandidates() {
        currentCandidates = []
        if composedBuffer.isEmpty { return }

        let pattern = #"(^(?::`|\.`|[-\]\\~!@#&*()_=+\[{}'";<>/?|.,])*?(?=(?:,{2,}))|^(?::`|\.`|[-\]\\~!@#&*()_=+\[{}'";<>/?|.,])*)(.*?(?:,,)*)((?::`|\.`|[-\]\\~!@#&*()_=+\[{}'";<>/?|.,])*$)"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let nsRange = NSRange(composedBuffer.startIndex..., in: composedBuffer)
        guard let match = regex.firstMatch(in: composedBuffer, range: nsRange) else { return }

        let nsString = composedBuffer as NSString
        guard match.numberOfRanges >= 4 else { return }

        prefix = AvroParser.shared.parse(nsString.substring(with: match.range(at: 1)))
        term = nsString.substring(with: match.range(at: 2))
        suffix = AvroParser.shared.parse(nsString.substring(with: match.range(at: 3)))

        var candidates = Suggestion.shared.getList(term)
        if !candidates.isEmpty {
            // Restore previously selected candidate if dictionary is enabled
            var prevString: String? = nil
            if UserDefaults.standard.bool(forKey: "IncludeDictionary") {
                prevSelected = -1
                prevString = CacheManager.shared.string(forKey: term)
            }

            for i in 0..<candidates.count {
                if let item = candidates[i] as? String {
                    if UserDefaults.standard.bool(forKey: "IncludeDictionary"),
                       let prev = prevString, item == prev {
                        prevSelected = i
                    }
                    candidates[i] = prefix + item + suffix
                }
            }

            // Add autocorrect for the full buffer when it differs from the term
            if composedBuffer != term && UserDefaults.standard.bool(forKey: "IncludeDictionary") {
                if let smily = AutoCorrect.shared.find(composedBuffer) {
                    candidates.insert(smily, at: 0)
                }
            }

            currentCandidates = candidates
        } else {
            currentCandidates = [prefix]
        }
    }

    // MARK: - Candidate Panel Management

    /// Shows or hides the candidate panel based on the current candidate list.
    ///
    /// Reallocates the panel if the user changed the panel type preference,
    /// and restores the previously selected candidate index.
    private func updateCandidatesPanel() {
        if !currentCandidates.isEmpty {
            let defaults = UserDefaults.standard

            if Candidates.shared.panelType() != defaults.integer(forKey: "CandidatePanelType") {
                Candidates.reallocate()
            }
            Candidates.shared.update()
            Candidates.shared.show(kIMKLocateCandidatesBelowHint)
            if prevSelected > -1 {
                for _ in 0..<prevSelected {
                    if Candidates.shared.panelType() == kIMKSingleColumnScrollingCandidatePanel {
                        Candidates.shared.moveDown(self)
                    } else if Candidates.shared.panelType() == kIMKSingleRowSteppingCandidatePanel {
                        Candidates.shared.moveRight(self)
                    }
                }
            }
        } else {
            Candidates.shared.hide()
        }
    }

    // MARK: - IMK Overrides

    /// Returns the current candidate list for the IMK candidate panel.
    override func candidates(_ sender: Any!) -> [Any]! {
        return currentCandidates
    }

    /// Called when the user highlights a different candidate in the panel.
    ///
    /// Updates the weight cache to remember the selection for this input term.
    override func candidateSelectionChanged(_ candidateString: NSAttributedString!) {
        if UserDefaults.standard.bool(forKey: "IncludeDictionary") {
            if !term.isEmpty {
                let comp = candidateString.string == (currentCandidates[0] as? String ?? "")
                if !(comp && prevSelected == -1) {
                    // Extract just the Bangla word (strip prefix/suffix)
                    let prefixLen = prefix.count
                    let candidateLen = candidateString.length
                    let suffixLen = suffix.count
                    let range = NSRange(location: prefixLen, length: candidateLen - prefixLen - suffixLen)
                    let nsCandidate = candidateString.string as NSString
                    let selected = nsCandidate.substring(with: range)
                    CacheManager.shared.setString(selected, forKey: term)

                    // Also update the base word selection for suffix combinations
                    if let tmpArray = CacheManager.shared.base(forKey: candidateString.string),
                       tmpArray.count >= 2,
                       let base = tmpArray[0] as? String,
                       let item = tmpArray[1] as? String {
                        CacheManager.shared.setString(item, forKey: base)
                    }
                }
            }
        }
        if let idx = currentCandidates.firstIndex(where: { ($0 as? String) == candidateString.string }) {
            selectedCandidateIndex = idx
        }
    }

    /// Called when the user confirms a candidate selection.
    ///
    /// Inserts the selected candidate text into the client application.
    override func candidateSelected(_ candidateString: NSAttributedString!) {
        currentClient?.insertText(candidateString, replacementRange: NSRange(location: NSNotFound, length: 0))
        clearCompositionBuffer()
        currentCandidates = []
        updateCandidatesPanel()

        if usedArrowKeys {
            usedArrowKeys = false
            if UserDefaults.standard.bool(forKey: "IncludeDictionary") {
                CacheManager.shared.persist()
            }
        }
    }

    /// Called when the composition needs to be committed without a selection (e.g. focus lost).
    override func commitComposition(_ sender: Any!) {
        let attrStr = NSAttributedString(string: composedBuffer)
        (sender as AnyObject?)?.insertText(attrStr, replacementRange: NSRange(location: NSNotFound, length: 0))
        clearCompositionBuffer()
        currentCandidates = []
        updateCandidatesPanel()
    }

    /// Returns the inline composition string displayed by the client.
    override func composedString(_ sender: Any!) -> Any! {
        return NSAttributedString(string: composedBuffer)
    }

    /// Clears the composition buffer.
    private func clearCompositionBuffer() {
        composedBuffer = ""
    }

    // MARK: - Input Handling

    /// Processes each character typed by the user.
    ///
    /// On space: commits the currently selected candidate.
    /// On other input: appends to the composition buffer and updates suggestions.
    override func inputText(_ string: String!, client sender: Any!) -> Bool {
        if string == " " {
            if !currentCandidates.isEmpty {
                if selectedCandidateIndex < currentCandidates.count {
                    let selected = currentCandidates[selectedCandidateIndex]
                    let attrStr = NSAttributedString(string: selected as? String ?? "")
                    candidateSelected(attrStr)
                }
            }
            return false
        } else {
            composedBuffer += string
            findCurrentCandidates()
            updateComposition()
            updateCandidatesPanel()
            return true
        }
    }

    // MARK: - Action Methods (dispatched via didCommand(by:client:))

    /// Handles the delete/backward key. Removes the last character from the composition buffer.
    @objc func deleteBackward(_ sender: Any!) {
        if !composedBuffer.isEmpty {
            composedBuffer.removeLast()
            findCurrentCandidates()
            updateComposition()
            updateCandidatesPanel()
        }
    }

    /// Handles the tab key. Commits the current selection and inserts a tab character.
    @objc func insertTab(_ sender: Any!) {
        commitText("\t")
    }

    /// Handles the enter/return key.
    ///
    /// Behavior depends on the `CommitNewLineOnEnter` preference:
    /// - If enabled: commits the selection and inserts a newline.
    /// - If disabled: commits the selection only.
    @objc func insertNewline(_ sender: Any!) {
        if UserDefaults.standard.bool(forKey: "CommitNewLineOnEnter") {
            commitText("\n")
        } else {
            commitText("")
        }
    }

    /// Moves the candidate selection up (vertical panel mode).
    @objc func moveUp(_ sender: Any?) {
        if Candidates.shared.isVisible() {
            usedArrowKeys = true
            Candidates.shared.moveUp(self)
        }
    }

    /// Moves the candidate selection down (vertical panel mode).
    @objc func moveDown(_ sender: Any?) {
        if Candidates.shared.isVisible() {
            usedArrowKeys = true
            Candidates.shared.moveDown(self)
        }
    }

    /// Moves the candidate selection left (horizontal panel mode).
    @objc func moveLeft(_ sender: Any?) {
        if Candidates.shared.isVisible() {
            usedArrowKeys = true
            Candidates.shared.moveLeft(self)
        }
    }

    /// Moves the candidate selection right (horizontal panel mode).
    @objc func moveRight(_ sender: Any?) {
        if Candidates.shared.isVisible() {
            usedArrowKeys = true
            Candidates.shared.moveRight(self)
        }
    }

    // MARK: - Command Dispatch

    /// Intercepts NSResponder action methods when the composition buffer is active.
    ///
    /// Only handles actions that should be processed by the input method (tab, enter,
    /// delete, arrow keys). All other commands are passed through to the client.
    override func didCommand(by aSelector: Selector!, client sender: Any!) -> Bool {
        if responds(to: aSelector) && !composedBuffer.isEmpty {
            if aSelector == #selector(insertTab(_:)) ||
                aSelector == #selector(insertNewline(_:)) ||
                aSelector == #selector(deleteBackward(_:)) ||
                aSelector == #selector(moveLeft(_:)) ||
                aSelector == #selector(moveRight(_:)) ||
                aSelector == #selector(moveUp(_:)) ||
                aSelector == #selector(moveDown(_:)) {
                perform(aSelector, with: sender)
                return true
            }
        }
        return false
    }

    // MARK: - Helpers

    /// Commits the current candidate selection and optionally inserts a trailing character.
    ///
    /// - Parameter string: A trailing character to insert after the selection (e.g. "\t", "\n").
    private func commitText(_ string: String) {
        if !currentCandidates.isEmpty {
            if selectedCandidateIndex < currentCandidates.count {
                let selected = currentCandidates[selectedCandidateIndex]
                let attrStr = NSAttributedString(string: selected as? String ?? "")
                candidateSelected(attrStr)
            }
            let attrStr = NSAttributedString(string: string)
            currentClient?.insertText(attrStr, replacementRange: NSRange(location: NSNotFound, length: 0))
        } else {
            NSSound.beep()
        }
    }

    /// Returns the menu shown when the user clicks the input method's status bar icon.
    override func menu() -> NSMenu! {
        return (NSApp.delegate as? MainMenuAppDelegate)?.menu
    }

    /// Opens the preferences window.
    @objc override func showPreferences(_ sender: Any?) {
        guard let appDelegate = NSApp.delegate as? MainMenuAppDelegate,
              let imPref = appDelegate.imPref else { return }
        let pw = imPref.windowController.window
        pw?.hidesOnDeactivate = false
        pw?.level = .modalPanel
        pw?.makeKeyAndOrderFront(self)
    }
}