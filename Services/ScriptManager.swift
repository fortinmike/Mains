import AppKit
import Foundation

@MainActor
final class ScriptManager {
    static let fileName = "power-status-changed.sh"

    private let fileManager = FileManager.default

    var scriptPath: String {
        expectedScriptPath
    }

    var creationCommand: String {
        let quotedPath = #""$HOME/Library/Application Scripts/\#(bundleIdentifier)/\#(Self.fileName)""#
        let quotedDirectory = #""$HOME/Library/Application Scripts/\#(bundleIdentifier)""#
        let quotedTemplatePath = shellQuote(templateURL.path(percentEncoded: false))

        return #"mkdir -p \#(quotedDirectory) && cp \#(quotedTemplatePath) \#(quotedPath) && chmod +x \#(quotedPath) && "${EDITOR:-vi}" \#(quotedPath)"#
    }

    var isScriptReady: Bool {
        guard let scriptURL else { return false }

        do {
            let values = try scriptURL.resourceValues(forKeys: [
                .isRegularFileKey,
                .isSymbolicLinkKey,
            ])

            return values.isRegularFile == true
                && values.isSymbolicLink != true
                && fileManager.isExecutableFile(atPath: scriptURL.path)
        } catch {
            return false
        }
    }

    func execute(with state: PowerState) async throws {
        guard let scriptURL, isScriptReady else {
            throw CocoaError(.fileNoSuchFile)
        }

        let task = try NSUserUnixTask(url: scriptURL)

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            task.execute(withArguments: [state.rawValue]) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    func revealInFinder() throws {
        let scriptsDirectory = try applicationScriptsDirectory(create: true)
        let selectedURL = if let scriptURL, fileManager.fileExists(atPath: scriptURL.path) {
            scriptURL
        } else {
            scriptsDirectory
        }

        NSWorkspace.shared.activateFileViewerSelecting([selectedURL])
    }

    private var scriptURL: URL? {
        try? applicationScriptsDirectory(create: false).appending(path: Self.fileName)
    }

    private var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "net.irradiated.Mains"
    }

    private var expectedScriptPath: String {
        "~/Library/Application Scripts/\(bundleIdentifier)/\(Self.fileName)"
    }

    private var templateURL: URL {
        guard let url = Bundle.main.url(
            forResource: "power-status-changed",
            withExtension: "sh"
        ) else {
            preconditionFailure("Missing bundled script template")
        }

        return url
    }

    private func shellQuote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private func applicationScriptsDirectory(create: Bool) throws -> URL {
        try fileManager.url(
            for: .applicationScriptsDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: create
        )
    }
}
