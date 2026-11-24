import Foundation

enum CozyBrewAbout {
    /// バンドル内 GPL 全文（`CozyBrewApp/Resources/LICENSE.txt`、ルート LICENSE と同期）
    static let licenseResourceName = "LICENSE.txt"

    /// OSS Notice（`ack:generate` → `CozyBrewApp/Resources/ACKNOWLEDGEMENTS.md` をバンドル同梱）
    static let acknowledgementsResourceName = "ACKNOWLEDGEMENTS.md"

    /// 下段プライマリ外部リンク（`AboutHeaderOptions.primaryLink*`）
    static let primaryLinkTitle = "GitHub Repository"
    static let primaryLinkURL = URL(string: "https://github.com/stein2nd/s2j-cozy-brew")!

    /// About 本文（アプリ名・バージョン・著作権は `AboutView` ヘッダー、GitHub は `primaryLink`）
    static let markdown = """
    A modern SwiftUI app for managing Homebrew packages.
    """
}
