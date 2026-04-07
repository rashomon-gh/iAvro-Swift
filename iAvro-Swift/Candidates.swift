import InputMethodKit

/// A shared singleton wrapper around `IMKCandidates` that manages the candidate selection panel.
///
/// Exposed to the Objective-C runtime as `Candidates` so that IMK can find it.
/// Only one instance exists at a time, managed via `allocateSharedInstanceWithServer:`.
@objc(Candidates)
class Candidates: IMKCandidates {
    private static var _sharedInstance: Candidates?
    private static var _server: IMKServer?

    /// Creates and stores the shared candidate panel instance.
    ///
    /// Must be called once at startup after the `IMKServer` is created.
    /// Reads the panel type from `CandidatePanelType` user default.
    ///
    /// - Parameter server: The IMK server instance to associate with.
    @objc static func allocateSharedInstance(with server: IMKServer) {
        guard _sharedInstance == nil else { return }
        _server = server
        let panelType = UserDefaults.standard.integer(forKey: "CandidatePanelType")
        guard let instance = Candidates(server: server, panelType: panelType) else {
            print("iAvro: Failed to create Candidates instance")
            return
        }
        instance.setAttributes([IMKCandidatesSendServerKeyEventFirst: true])
        instance.setDismissesAutomatically(false)
        _sharedInstance = instance
        print("iAvro: ✅ Candidates instance created")
    }

    /// Returns the shared candidate panel instance.
    @objc static func sharedInstance() -> Candidates? {
        return _sharedInstance
    }

    /// Swift-style property accessor for the shared instance.
    static var shared: Candidates {
        guard let instance = _sharedInstance else {
            fatalError("Candidates.shared accessed before allocateSharedInstance was called")
        }
        return instance
    }

    /// Cleans up the shared instance.
    @objc static func deallocateSharedInstance() {
        _sharedInstance = nil
    }

    /// Discards the current instance and creates a new one with updated settings.
    ///
    /// Called when the user changes the candidate panel type in preferences.
    @objc static func reallocate() {
        _sharedInstance = nil
        if let server = _server {
            allocateSharedInstance(with: server)
        }
    }

    // MARK: - IMKCandidates Methods

    /// Updates the candidate panel with the current candidate list.
    @objc override func update() {
        super.update()
    }

    /// Returns the current candidate panel type.
    @objc override func panelType() -> IMKCandidatePanelType {
        return super.panelType()
    }

    /// Checks if the candidate panel is currently visible.
    @objc override func isVisible() -> Bool {
        return super.isVisible()
    }

    /// Hides the candidate panel.
    @objc override func hide() {
        super.hide()
    }

    /// Shows the candidate panel at the specified position.
    @objc override func show(_ position: Int) {
        super.show(position)
    }

    /// Moves the candidate selection up.
    @objc override func moveUp(_ sender: Any?) {
        super.moveUp(sender)
    }

    /// Moves the candidate selection down.
    @objc override func moveDown(_ sender: Any?) {
        super.moveDown(sender)
    }

    /// Moves the candidate selection left.
    @objc override func moveLeft(_ sender: Any?) {
        super.moveLeft(sender)
    }

    /// Moves the candidate selection right.
    @objc override func moveRight(_ sender: Any?) {
        super.moveRight(sender)
    }
}
