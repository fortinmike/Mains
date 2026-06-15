import SwiftUI

struct MenuContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if appModel.isScriptReady {
            Label(appModel.powerState.title, systemImage: appModel.powerState.systemImage)
                .foregroundStyle(appModel.powerState.color)
        } else {
            Button("Create a Script to Begin...", action: showScriptInstructions)
        }

        if let scriptErrorMessage = appModel.scriptErrorMessage {
            Text(scriptErrorMessage)
                .foregroundStyle(.red)
        }

        Divider()

        Button("Reveal Script in Finder...", action: appModel.revealScriptInFinder)

        SettingsLink {
            Text("Settings...")
        }

        Divider()

        Button("Quit Mains", action: quit)
            .keyboardShortcut("q")
            .onAppear(perform: appModel.refreshScriptStatus)
    }

    private func showScriptInstructions() {
        openWindow(id: ScriptInstructionsView.windowID)
    }

    private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
