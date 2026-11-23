import AppKit
import CozyBrewService
import SwiftUI

public extension Notification.Name {
    /// メインウィンドウで Warnings を選択する
    static let cozyBrewNavigateToWarnings = Notification.Name("cozyBrewNavigateToWarnings")
}

/// Homebrew 実行環境 (read-only) — ux_flows_spec §6.2
public struct BrewEnvironmentView: View {
    @ObservedObject private var manager: BrewManager
    private let appBundlePath: String?

    @State private var snapshot: BrewEnvironmentSnapshot?
    @State private var isLoading = false
    @State private var loadError: String?

    public init(manager: BrewManager, appBundlePath: String? = nil) {
        self.manager = manager
        self.appBundlePath = appBundlePath
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerActions

                if isLoading, snapshot == nil {
                    ProgressView(CozyBrewL10n.environmentLoading)
                        .frame(maxWidth: .infinity)
                        .padding()
                } else if let snapshot {
                    detectionSection(snapshot)
                    if let version = snapshot.brewVersionOutput {
                        pathOrTextSection(
                            title: CozyBrewL10n.environmentSectionVersion,
                            text: version
                        )
                    }
                    if let config = snapshot.brewConfigOutput {
                        monospaceSection(
                            title: CozyBrewL10n.environmentSectionConfig,
                            text: config,
                            copyLabel: CozyBrewL10n.environmentCopyConfig
                        )
                    }
                    pathsSection(snapshot)
                    cozyBrewSection(snapshot)
                    shortcutsSection(snapshot)
                }

                if let loadError {
                    Text(loadError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(CozyBrewL10n.environmentWindowTitle)
        .task {
            await reload()
        }
    }

    private var headerActions: some View {
        HStack {
            Button {
                Task { await reload() }
            } label: {
                Label(CozyBrewL10n.refresh, systemImage: "arrow.clockwise")
            }
            .disabled(isLoading)
            .accessibilityLabel(CozyBrewL10n.a11yEnvironmentRefresh)

            Spacer()
        }
    }

    private func detectionSection(_ snapshot: BrewEnvironmentSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(CozyBrewL10n.environmentSectionDetection)
            if let path = snapshot.brewBinaryPath {
                environmentRow(path: path)
            } else {
                Text(CozyBrewL10n.environmentBrewNotDetected)
                    .foregroundColor(.secondary)
            }
            if let arch = snapshot.architectureLabel {
                labeledValue(CozyBrewL10n.environmentArchitecture, arch)
            }
            if let detection = snapshot.fetchErrors["detection"] {
                Text(detection)
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
    }

    private func pathsSection(_ snapshot: BrewEnvironmentSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(CozyBrewL10n.environmentSectionHomebrewPaths)
            optionalPathRow(CozyBrewL10n.environmentPathPrefix, snapshot.prefixPath)
            optionalPathRow(CozyBrewL10n.environmentPathCellar, snapshot.cellarPath)
            optionalPathRow(CozyBrewL10n.environmentPathRepository, snapshot.repositoryPath)
        }
    }

    private func cozyBrewSection(_ snapshot: BrewEnvironmentSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(CozyBrewL10n.environmentSectionCozyBrewData)
            environmentRow(path: snapshot.operationHistoryPath)
            environmentRow(path: snapshot.cacheDirectoryPath)
            if let bundle = snapshot.appBundlePath {
                environmentRow(path: bundle)
            }
        }
    }

    private func shortcutsSection(_ snapshot: BrewEnvironmentSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(CozyBrewL10n.environmentSectionShortcuts)
            HStack {
                Button(CozyBrewL10n.environmentOpenTerminalConfig) {
                    let command = terminalConfigCommand(snapshot)
                    try? BrewTerminalLauncher.copyAndRunInTerminal(command: command)
                }
                .disabled(!manager.isBrewAvailable)
                .accessibilityLabel(CozyBrewL10n.a11yEnvironmentTerminalConfig)

                Button(CozyBrewL10n.environmentShowWarnings) {
                    NotificationCenter.default.post(name: .cozyBrewNavigateToWarnings, object: nil)
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
                .accessibilityLabel(CozyBrewL10n.a11yEnvironmentShowWarnings)
            }
        }
    }

    private func terminalConfigCommand(_ snapshot: BrewEnvironmentSnapshot) -> String {
        if let brew = snapshot.brewBinaryPath {
            return "\"\(brew)\" config"
        }
        return "brew config"
    }

    @ViewBuilder
    private func optionalPathRow(_ title: String, _ path: String?) -> some View {
        if let path {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                environmentRow(path: path)
            }
        }
    }

    private func pathOrTextSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title)
            HStack(alignment: .top) {
                Text(text)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                Spacer(minLength: 8)
                copyButton(text: text, label: CozyBrewL10n.environmentCopy)
            }
        }
    }

    private func monospaceSection(title: String, text: String, copyLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title)
            HStack(alignment: .top) {
                Text(text)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                copyButton(text: text, label: copyLabel)
            }
            .padding(8)
            .background(Color(nsColor: .textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func environmentRow(path: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(path)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            copyButton(text: path, label: CozyBrewL10n.environmentCopy)
            revealButton(path: path)
        }
    }

    private func labeledValue(_ title: String, _ value: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .foregroundColor(.secondary)
            Text(value)
        }
        .font(.subheadline)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .accessibilityAddTraits(.isHeader)
    }

    private func copyButton(text: String, label: String) -> some View {
        Button(label) {
            BrewTerminalLauncher.copyToPasteboard(text)
        }
        .controlSize(.small)
        .accessibilityLabel(label)
    }

    private func revealButton(path: String) -> some View {
        Button(CozyBrewL10n.environmentRevealInFinder) {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: path) {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            } else {
                let parent = url.deletingLastPathComponent()
                NSWorkspace.shared.open(parent)
            }
        }
        .controlSize(.small)
        .accessibilityLabel(CozyBrewL10n.a11yEnvironmentReveal(path))
    }

    private func reload() async {
        isLoading = true
        loadError = nil
        defer { isLoading = false }
        let bundle = appBundlePath ?? Bundle.main.bundlePath
        snapshot = await manager.fetchEnvironmentSnapshot(appBundlePath: bundle)
        if let snapshot, !snapshot.fetchErrors.isEmpty, snapshot.brewBinaryPath == nil {
            loadError = snapshot.fetchErrors.values.joined(separator: "\n")
        }
    }
}
