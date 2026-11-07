import S2JAboutWindow
import SwiftUI

enum CozyBrewAbout {
    /// About 本文（アプリ名・バージョン・著作権は `AboutView` ヘッダーに任せる）
    static let markdown = """
    A modern SwiftUI app for managing Homebrew packages.

    [GitHub Repository](https://github.com/stein2nd/s2j-cozy-brew)

    [License](https://github.com/stein2nd/s2j-cozy-brew/blob/main/LICENSE)
    """
}

struct CozyBrewAboutSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            AboutView(content: CozyBrewAbout.markdown, appName: "CozyBrew")
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
