import Foundation

/// brew CLI 出力を UI 向けメッセージに意訳する
public enum BrewUserMessage {
    /// Cask Upgrade 中オーバーレイの補足
    public static let caskUpgradePasswordHint = """
    macOS may ask for an administrator password. If you see a Privacy & Security notice that app changes were blocked, \
    allow CozyBrew under System Settings → Privacy & Security → App Management, then try again.
    """

    /// システム設定「アプリの管理」 (App Management) へのショートカット
    public static let appManagementSettingsURL =
        URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?AppMgmt")

    public static let appManagementGuidance = """
    System Settings → Privacy & Security → App Management: turn on CozyBrew \
    (required for some Cask upgrades that modify other apps).
    """

    public static func upgradeFailure(from stderr: String, packageType: PackageType) -> String {
        let detail = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = detail.lowercased()

        if packageType == .cask, detail.isEmpty {
            return caskUpgradeBlockedOrPermissionHint(detail: nil)
        }

        let suggestsAppManagement = lower.contains("block")
            || lower.contains("prevent")
            || lower.contains("not authorized")
            || lower.contains("app management")

        let needsAdminHint = packageType == .cask
            || lower.contains("sudo")
            || lower.contains("password")
            || lower.contains("administrator")
            || suggestsAppManagement

        if needsAdminHint {
            if packageType == .cask, suggestsAppManagement || detail.isEmpty {
                return caskUpgradeBlockedOrPermissionHint(detail: detail.isEmpty ? nil : detail)
            }
            var message = "This upgrade may require administrator approval."
            if packageType == .cask {
                message += " Some Casks update apps in /Applications and trigger macOS authentication."
                message += " If macOS blocked app changes, check App Management (see overlay note)."
            }
            message += " If a password dialog appeared, approve it and try again—or run "
                + "`brew upgrade --cask <name>` in Terminal."
            if !detail.isEmpty {
                message += "\n\n\(detail)"
            }
            return message
        }

        if detail.isEmpty {
            return "Upgrade failed."
        }
        return detail
    }

    private static func caskUpgradeBlockedOrPermissionHint(detail: String?) -> String {
        var message = """
        macOS may have blocked CozyBrew from updating another app (Privacy & Security notification).

        \(appManagementGuidance)

        Alternatively run `brew upgrade --cask <name>` in Terminal.
        """
        if let detail, !detail.isEmpty {
            message += "\n\n\(detail)"
        }
        return message
    }
}
