import InputMethodKit

@objc(Candidates)
class Candidates: IMKCandidates {
    private static var _sharedInstance: Candidates?
    private static var _server: IMKServer?

    @objc static func setupSharedInstance(with server: IMKServer) {
        guard _sharedInstance == nil else { return }
        _server = server
        let panelType = UserDefaults.standard.integer(forKey: "CandidatePanelType")
        let instance = Candidates(server: server, panelType: panelType)!
        instance.setAttributes([IMKCandidatesSendServerKeyEventFirst: true])
        instance.setDismissesAutomatically(false)
        _sharedInstance = instance
    }

    @objc static var shared: Candidates {
        guard let instance = _sharedInstance else {
            fatalError("Candidates shared instance not initialized")
        }
        return instance
    }

    @objc static func reallocate() {
        _sharedInstance = nil
        if let server = _server {
            setupSharedInstance(with: server)
        }
    }
}
