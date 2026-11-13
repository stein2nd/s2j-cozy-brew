import S2JAboutWindow
import SwiftUI

enum CozyBrewAbout {
    /// バンドル内 GPL 全文（`CozyBrewApp/Resources/LICENSE.txt`、ルート LICENSE と同期）
    static let licenseResourceName = "LICENSE.txt"

    /// OSS Notice（`ack:generate` → `CozyBrewApp/Resources/ACKNOWLEDGEMENTS.md` をバンドル同梱）
    static let acknowledgementsResourceName = "ACKNOWLEDGEMENTS.md"

    /// About 本文（アプリ名・バージョン・著作権は `AboutView` ヘッダーに任せる）
    static let markdown = """
    A modern SwiftUI app for managing Homebrew packages.

    [GitHub Repository](https://github.com/stein2nd/s2j-cozy-brew)
    """
}

struct CozyBrewAboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            AboutView(
                content: CozyBrewAbout.markdown,
                appName: "CozyBrew",
                licenseResourceName: CozyBrewAbout.licenseResourceName,
                acknowledgementsResourceName: CozyBrewAbout.acknowledgementsResourceName
            )
            Divider()
            HStack {
                Spacer()
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 400)
    }
}
