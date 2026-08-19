import SwiftUI

struct ScriptInstructionsView: View {
    static let windowID = "script-instructions"

    @Environment(AppModel.self) private var appModel
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Create a Script to Begin", systemImage: "terminal")
                .font(.title2)
                .bold()

            Text(
                "Mains runs a user-owned script whenever the active power source changes. "
                    + "Paste this command into Terminal to create and open it in your default terminal text editor:"
            )
            .fixedSize(horizontal: false, vertical: true)

            Text(appModel.scriptCreationCommand)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding()
                .background(.quaternary, in: .rect(cornerRadius: 8))

            HStack {
                Button("Copy Command", systemImage: "document.on.document", action: copyCommand)
                Button("Open Terminal", systemImage: "apple.terminal", action: appModel.openTerminal)
                Button(
                    "Reveal Folder",
                    systemImage: "folder",
                    action: appModel.revealScriptInFinder
                )
            }

            Text(
                "The script receives the current state as its first argument. "
                    + "Possible values are `mains`, `ups`, `battery`, and `unknown`."
            )
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            Text("To diagnose issues, open Console and filter for `net.irradiated.Mains`.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()
                Button("Done", action: close)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 640)
    }

    private func copyCommand() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(appModel.scriptCreationCommand, forType: .string)
    }

    private func close() {
        appModel.refreshScriptStatus()
        dismissWindow(id: Self.windowID)
    }
}
