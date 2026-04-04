import SwiftUI

/// A window controller that hosts the SwiftUI-based preferences interface.
class PreferencesWindowController: NSWindowController {

    /// Creates a titled, closable window containing the preferences SwiftUI view.
    convenience init() {
        let hostingView = NSHostingView(rootView: PreferencesView())
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
                              styleMask: [.titled, .closable],
                              backing: .buffered,
                              defer: false)
        window.contentView = hostingView
        window.title = "iAvro Preferences"
        window.center()
        self.init(window: window)
    }
}

// MARK: - SwiftUI Views

/// The root preferences view with General and About tabs.
struct PreferencesView: View {
    @AppStorage("IncludeDictionary") var includeDictionary = true
    @AppStorage("CommitNewLineOnEnter") var commitNewLineOnEnter = false
    @AppStorage("CandidatePanelType") var candidatePanelType = 1

    var body: some View {
        TabView {
            GeneralPreferencesView()
                .tabItem { Label("General", systemImage: "gear") }

            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .padding(20)
        .frame(minWidth: 450, minHeight: 300)
    }
}

/// The General preferences tab with toggles and a picker for candidate panel style.
struct GeneralPreferencesView: View {
    @AppStorage("IncludeDictionary") var includeDictionary = true
    @AppStorage("CommitNewLineOnEnter") var commitNewLineOnEnter = false
    @AppStorage("CandidatePanelType") var candidatePanelType = 1

    var body: some View {
        Form {
            Toggle("Include Dictionary Suggestions", isOn: $includeDictionary)
            Toggle("Commit New Line on Enter", isOn: $commitNewLineOnEnter)

            Picker("Candidate Panel Type", selection: $candidatePanelType) {
                Text("Vertical Scrolling").tag(1)
                Text("Horizontal Stepping").tag(2)
            }
        }
        .padding()
    }
}

/// The About tab showing application name and credits.
struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("iAvro")
                .font(.title)
                .fontWeight(.bold)
            Text("Bangla Input Method for macOS")
                .foregroundStyle(.secondary)
            Text("Based on Avro Phonetic by OmicronLab")
                .foregroundStyle(.secondary)
            Divider()
            Text("Rewritten in Swift from the original Objective-C version.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
