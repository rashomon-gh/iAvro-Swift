import InputMethodKit

/// A shared singleton wrapper around `IMKCandidates` that manages the candidate selection panel.
///
/// Exposed to the Objective-C runtime as `Candidates` so that IMK can find it.
/// Only one instance exists at a time, managed via `setupSharedInstance(with:)`.
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
    @objc static func setupSharedInstance(with server: IMKServer) {
        guard _sharedInstance == nil else { return }
        _server = server
        let panelType = UserDefaults.standard.integer(forKey: "CandidatePanelType")
        let instance = Candidates(server: server, panelType: panelType)!
        instance.setAttributes([IMKCandidatesSendServerKeyEventFirst: true])
        instance.setDismissesAutomatically(false)
        _sharedInstance = instance
    }

    /// The shared candidate panel instance.
    ///
    /// - Warning: Accessing this before calling `setupSharedInstance(with:)` triggers a fatal error.
    @objc static var shared: Candidates {
        guard let instance = _sharedInstance else {
            fatalError("Candidates shared instance not initialized")
        }
        return instance
    }

    /// Discards the current instance and creates a new one with updated settings.
    ///
    /// Called when the user changes the candidate panel type in preferences.
    @objc static func reallocate() {
        _sharedInstance = nil
        if let server = _server {
            setupSharedInstance(with: server)
        }
    }
}
