import AppKit
import Foundation

public enum BrewTerminalLauncherError: LocalizedError {
    case appleScriptFailed(String)

    public var errorDescription: String? {
        switch self {
        case let .appleScriptFailed(detail):
            "Could not open Terminal: \(detail)"
        }
    }
}

/// クリップボードと Terminal (Apple Events) へのコマンド委譲
public enum BrewTerminalLauncher {
    @MainActor
    public static func copyToPasteboard(_ command: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(command, forType: .string)
    }

    /// クリップボードにコピーし、Terminal でコマンドを実行する
    @MainActor
    public static func copyAndRunInTerminal(command: String) throws {
        copyToPasteboard(command)
        try runAppleScriptOpeningTerminal(with: command)
    }

    private static func runAppleScriptOpeningTerminal(with command: String) throws {
        let escaped = appleScriptEscaped(command)
        let source = """
        tell application "Terminal"
            activate
            do script "\(escaped)"
        end tell
        """
        var errorInfo: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw BrewTerminalLauncherError.appleScriptFailed("Invalid AppleScript")
        }
        script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            let message = (errorInfo[NSAppleScript.errorMessage] as? String) ?? String(describing: errorInfo)
            throw BrewTerminalLauncherError.appleScriptFailed(message)
        }
    }

    private static func appleScriptEscaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
