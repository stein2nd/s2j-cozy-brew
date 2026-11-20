import CozyBrewCore
import Foundation

/// Cask の Upgrade が GUI 内で完了できないとき、ターミナルへ委譲するためのコマンド組み立てと判定
public enum BrewCaskTerminalFallback {
    /// `brew upgrade` と同じ引数 (`BrewManager.upgrade` と揃える)。先頭に `sudo` は付けない
    public static func upgradeShellCommand(for package: Package, brewBinaryPath: String? = nil) -> String {
        let brew = brewBinaryPath ?? BrewBinaryLocator.locate()?.path ?? "brew"
        let token = shellEscape(package.fullName)
        return "\(brew) upgrade --yes --cask \(token)"
    }

    /// Upgrade 失敗ログから、ターミナル実行 UI を出すべきか
    public static func suggestsTerminalFallback(stderr: String, packageType: PackageType) -> Bool {
        guard packageType == .cask else { return false }
        let lower = stderr.lowercased()
        if lower.contains("terminal is required") {
            return true
        }
        if lower.contains("sudo") {
            return true
        }
        if lower.contains("password is required") {
            return true
        }
        if lower.contains("app management") {
            return true
        }
        if lower.contains("not authorized") {
            return true
        }
        if lower.contains("prevent") || lower.contains("block") {
            return true
        }
        return false
    }

    private static func shellEscape(_ argument: String) -> String {
        if argument.isEmpty {
            return "''"
        }
        if argument.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" || $0 == "." || $0 == "+" }) {
            return argument
        }
        return "'" + argument.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
