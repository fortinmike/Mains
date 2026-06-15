import AppKit
import Observation
import ServiceManagement

@MainActor
@Observable
final class AppModel {
    private(set) var powerState = PowerState.unknown
    private(set) var isScriptReady = false
    private(set) var launchAtLogin = false
    private(set) var loginItemRequiresApproval = false
    private(set) var scriptErrorMessage: String?
    private(set) var settingsErrorMessage: String?

    private let powerMonitor = PowerMonitor()
    private let scriptManager = ScriptManager()
    private var scriptExecutionTask: Task<Void, Never>?

    init() {
        refreshScriptStatus()
        refreshLoginItemStatus()

        powerMonitor.onUpdate = { [weak self] newState in
            self?.handlePowerUpdate(newState)
        }
        powerState = powerMonitor.start()
    }

    var menuBarSystemImage: String {
        isScriptReady ? powerState.systemImage : "bolt.horizontal.circle"
    }

    var menuBarAccessibilityLabel: String {
        isScriptReady ? powerState.title : "Mains needs a script"
    }

    var scriptPath: String {
        scriptManager.scriptPath
    }

    var scriptCreationCommand: String {
        scriptManager.creationCommand
    }

    func refreshScriptStatus() {
        isScriptReady = scriptManager.isScriptReady
    }

    func revealScriptInFinder() {
        do {
            try scriptManager.revealInFinder()
        } catch {
            scriptErrorMessage = "Unable to reveal the script: \(error.localizedDescription)"
        }
    }

    func openTerminal() {
        guard let terminalURL = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: "com.apple.Terminal"
        ) else {
            scriptErrorMessage = "Unable to find Terminal."
            return
        }

        scriptErrorMessage = nil
        if !NSWorkspace.shared.open(terminalURL) {
            scriptErrorMessage = "Unable to open Terminal."
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        settingsErrorMessage = nil

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            settingsErrorMessage = error.localizedDescription
        }

        refreshLoginItemStatus()
    }

    func refreshLoginItemStatus() {
        let status = SMAppService.mainApp.status
        launchAtLogin = status == .enabled || status == .requiresApproval
        loginItemRequiresApproval = status == .requiresApproval
    }

    func openLoginItemsSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }

    private func handlePowerUpdate(_ newState: PowerState) {
        powerState = newState
        refreshScriptStatus()

        guard isScriptReady else { return }

        scriptErrorMessage = nil
        let previousTask = scriptExecutionTask
        scriptExecutionTask = Task { [weak self, scriptManager] in
            _ = await previousTask?.value

            do {
                try await scriptManager.execute(with: newState)
                self?.scriptErrorMessage = nil
            } catch {
                self?.scriptErrorMessage = "Script failed: \(error.localizedDescription)"
            }
        }
    }
}
