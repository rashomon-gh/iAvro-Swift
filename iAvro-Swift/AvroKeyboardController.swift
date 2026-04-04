import Cocoa
import InputMethodKit

@objc(AvroKeyboardController)
class AvroKeyboardController: IMKInputController {
    private var currentClient: AnyObject?
    private var prevSelected: Int = -1
    private var composedBuffer: String = ""
    private var currentCandidates: [Any] = []
    private var selectedCandidateIndex: Int = 0
    private var prefix: String = ""
    private var term: String = ""
    private var suffix: String = ""
    private var usedArrowKeys: Bool = false

    override init!(server: IMKServer!, delegate: Any!, client inputClient: Any!) {
        super.init(server: server, delegate: delegate, client: inputClient)
        currentClient = inputClient as AnyObject?
    }

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

    private func updateCandidatesPanel() {
        if !currentCandidates.isEmpty {
            let defaults = UserDefaults.standard

            if Candidates.shared.panelType() != defaults.integer(forKey: "CandidatePanelType") {
                Candidates.reallocate()
            }
            Candidates.shared.update()
            Candidates.shared.show(1)
            if prevSelected > -1 {
                for _ in 0..<prevSelected {
                    if Candidates.shared.panelType() == 1 {
                        Candidates.shared.moveDown(self)
                    } else if Candidates.shared.panelType() == 2 {
                        Candidates.shared.moveRight(self)
                    }
                }
            }
        } else {
            Candidates.shared.hide()
        }
    }

    override func candidates(_ sender: Any!) -> [Any]! {
        return currentCandidates
    }

    override func candidateSelectionChanged(_ candidateString: NSAttributedString!) {
        if UserDefaults.standard.bool(forKey: "IncludeDictionary") {
            if !term.isEmpty {
                let comp = candidateString.string == (currentCandidates[0] as? String ?? "")
                if !(comp && prevSelected == -1) {
                    let prefixLen = prefix.count
                    let candidateLen = candidateString.length
                    let suffixLen = suffix.count
                    let range = NSRange(location: prefixLen, length: candidateLen - prefixLen - suffixLen)
                    let nsCandidate = candidateString.string as NSString
                    let selected = nsCandidate.substring(with: range)
                    CacheManager.shared.setString(selected, forKey: term)

                    if let tmpArray = CacheManager.shared.base(forKey: candidateString.string) as? [Any],
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

    override func commitComposition(_ sender: Any!) {
        let attrStr = NSAttributedString(string: composedBuffer)
        (sender as AnyObject?)?.insertText(attrStr, replacementRange: NSRange(location: NSNotFound, length: 0))
        clearCompositionBuffer()
        currentCandidates = []
        updateCandidatesPanel()
    }

    override func composedString(_ sender: Any!) -> Any! {
        return NSAttributedString(string: composedBuffer)
    }

    private func clearCompositionBuffer() {
        composedBuffer = ""
    }

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

    @objc func deleteBackward(_ sender: Any!) {
        if !composedBuffer.isEmpty {
            composedBuffer.removeLast()
            findCurrentCandidates()
            updateComposition()
            updateCandidatesPanel()
        }
    }

    @objc func insertTab(_ sender: Any!) {
        commitText("\t")
    }

    @objc func insertNewline(_ sender: Any!) {
        if UserDefaults.standard.bool(forKey: "CommitNewLineOnEnter") {
            commitText("\n")
        } else {
            commitText("")
        }
    }

    @objc func moveUp(_ sender: Any?) {
        if Candidates.shared.isVisible() {
            usedArrowKeys = true
            Candidates.shared.moveUp(self)
        }
    }

    @objc func moveDown(_ sender: Any?) {
        if Candidates.shared.isVisible() {
            usedArrowKeys = true
            Candidates.shared.moveDown(self)
        }
    }

    @objc func moveLeft(_ sender: Any?) {
        if Candidates.shared.isVisible() {
            usedArrowKeys = true
            Candidates.shared.moveLeft(self)
        }
    }

    @objc func moveRight(_ sender: Any?) {
        if Candidates.shared.isVisible() {
            usedArrowKeys = true
            Candidates.shared.moveRight(self)
        }
    }

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

    override func menu() -> NSMenu! {
        return (NSApp.delegate as? MainMenuAppDelegate)?.menu
    }

    @objc override func showPreferences(_ sender: Any?) {
        guard let appDelegate = NSApp.delegate as? MainMenuAppDelegate,
              let imPref = appDelegate.imPref else { return }
        let pw = imPref.windowController.window
        pw?.hidesOnDeactivate = false
        pw?.level = .modalPanel
        pw?.makeKeyAndOrderFront(self)
    }
}
