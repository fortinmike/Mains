import SwiftUI

@main
struct MainsApp: App {
    @State private var appModel = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MenuContentView()
                .environment(appModel)
        } label: {
            Image(systemName: appModel.menuBarSystemImage)
                .accessibilityLabel(appModel.menuBarAccessibilityLabel)
        }

        Window("Setup", id: ScriptInstructionsView.windowID) {
            ScriptInstructionsView()
                .environment(appModel)
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .environment(appModel)
        }
    }
}
