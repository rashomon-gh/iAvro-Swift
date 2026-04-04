import SwiftUI

class PreferencesWindowController: NSWindowController {
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

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("iAvro")
                .font(.title)
                .fontWeight(.bold)
            Text("Bengali Input Method for macOS")
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
