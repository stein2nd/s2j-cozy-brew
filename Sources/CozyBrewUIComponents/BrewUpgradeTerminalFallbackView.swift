import CozyBrewService
import SwiftUI

/// Cask Upgrade 失敗時のターミナル委譲 UI
public struct BrewUpgradeTerminalFallbackView: View {
    let package: Package
    @State private var terminalError: String?
    @State private var didCopy = false

    private var shellCommand: String {
        BrewCaskTerminalFallback.upgradeShellCommand(for: package)
    }

    public init(package: Package) {
        self.package = package
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(CozyBrewL10n.continueInTerminal)
                .font(.subheadline)
                .fontWeight(.semibold)

            Text(
                "Homebrew may ask for your administrator password inside Terminal. "
                    + "Do not run `sudo brew`; use the command below as-is."
            )
            .font(.caption)
            .foregroundColor(.secondary)
            .fixedSize(horizontal: false, vertical: true)

            Text(shellCommand)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .textBackgroundColor).opacity(0.6))
                .cornerRadius(6)

            HStack(spacing: 12) {
                Button {
                    BrewTerminalLauncher.copyToPasteboard(shellCommand)
                    didCopy = true
                    terminalError = nil
                } label: {
                    Label(didCopy ? "Copied" : "Copy Command", systemImage: didCopy ? "checkmark" : "doc.on.doc")
                }
                .buttonStyle(.bordered)

                Button {
                    didCopy = false
                    terminalError = nil
                    do {
                        try BrewTerminalLauncher.copyAndRunInTerminal(command: shellCommand)
                        didCopy = true
                    } catch {
                        terminalError = error.localizedDescription
                    }
                } label: {
                    Label(CozyBrewL10n.runInTerminal, systemImage: "terminal")
                        .accessibilityLabel(CozyBrewL10n.runInTerminal)
                }
                .buttonStyle(.borderedProminent)

                if package.type == .cask, let url = BrewUserMessage.appManagementSettingsURL {
                    Link("App Management…", destination: url)
                        .font(.caption)
                }
            }

            if let terminalError {
                Text(terminalError)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(10)
        .background(Color.orange.opacity(0.08))
        .cornerRadius(8)
    }
}
