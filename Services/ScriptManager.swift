import AppKit
import Foundation
import OSLog

private let logger = Logger(subsystem: "net.irradiated.Mains", category: "ScriptManager")

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
        let quotedTemplatePath = shellPath(templateURL.path(percentEncoded: false))

        return #"mkdir -p \#(quotedDirectory) && cp \#(quotedTemplatePath) \#(quotedPath) && chmod +x \#(quotedPath) && "${EDITOR:-nano}" \#(quotedPath)"#
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
        guard let scriptURL else {
            logger.error(
                "Missing script at \(self.expectedScriptPath, privacy: .public) for power state \(state.rawValue, privacy: .public)"
            )
            throw CocoaError(.fileNoSuchFile)
        }

        let scriptPath = abbreviatedPath(for: scriptURL)
        guard isScriptReady else {
            logger.error(
                "Script at \(scriptPath, privacy: .public) is not ready for power state \(state.rawValue, privacy: .public)"
            )
            throw CocoaError(.fileNoSuchFile)
        }

        let task = try NSUserUnixTask(url: scriptURL)
        logger.info(
            "Executing script at \(scriptPath, privacy: .public) for power state \(state.rawValue, privacy: .public)"
        )

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            task.execute(withArguments: [state.rawValue]) { error in
                if let error {
                    logger.error(
                        "Script at \(scriptPath, privacy: .public) failed for power state \(state.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)"
                    )
                    continuation.resume(throwing: error)
                } else {
                    logger.info(
                        "Script at \(scriptPath, privacy: .public) completed for power state \(state.rawValue, privacy: .public)"
                    )
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

    private func shellPath(_ path: String) -> String {
        let homePath = fileManager.homeDirectoryForCurrentUser.path(percentEncoded: false)
        guard path == homePath || path.hasPrefix("\(homePath)/") else {
            return shellQuote(path)
        }

        return "$HOME\(shellEscape(String(path.dropFirst(homePath.count))))"
    }

    private func shellEscape(_ value: String) -> String {
        value.reduce(into: "") { result, character in
            if character.isLetter || character.isNumber || "/._-~".contains(character) {
                result.append(character)
            } else {
                result.append("\\\(character)")
            }
        }
    }

    private func abbreviatedPath(for url: URL) -> String {
        let path = url.path(percentEncoded: false)
        let homePath = fileManager.homeDirectoryForCurrentUser.path(percentEncoded: false)
        guard path == homePath || path.hasPrefix("\(homePath)/") else { return path }

        return "~\(path.dropFirst(homePath.count))"
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
