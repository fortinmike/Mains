import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openWindow) private var openWindow
    @State private var launchAtLogin = false

    var body: some View {
        Form {
            Toggle("Start Mains at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin, updateLaunchAtLogin)

            LabeledContent {
                Button(
                    "Open Instructions",
                    systemImage: "apple.terminal",
                    action: showScriptInstructions
                )
            } label: {
                Text("Setup")
            }

            if appModel.loginItemRequiresApproval {
                LabeledContent {
                    Button("Open Login Items Settings", action: appModel.openLoginItemsSettings)
                } label: {
                    Text("Approval required")
                }
            }

            if let settingsErrorMessage = appModel.settingsErrorMessage {
                Text(settingsErrorMessage)
                    .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 420)
        .onAppear(perform: refresh)
    }

    private func refresh() {
        appModel.refreshLoginItemStatus()
        launchAtLogin = appModel.launchAtLogin
    }

    private func showScriptInstructions() {
        openWindow(id: ScriptInstructionsView.windowID)
    }

    private func updateLaunchAtLogin() {
        guard launchAtLogin != appModel.launchAtLogin else { return }

        appModel.setLaunchAtLogin(launchAtLogin)
        launchAtLogin = appModel.launchAtLogin
    }
}
