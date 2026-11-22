import CozyBrewService
import SwiftUI

/// パッケージの詳細ビュー
public struct PackageDetailView: View {
    @Binding var package: Package
    let manager: BrewManager

    @State private var displayedPackage: Package?
    @State private var isLoadingInfo = false
    @State private var isPerformingAction = false
    @State private var performingActionTitle: String?
    @State private var performingActionFootnote: String?
    @State private var infoErrorMessage: String?
    @State private var actionErrorMessage: String?
    @State private var upgradeFailureStderr: String?
    @State private var showsInstallFlow = false

    public init(package: Binding<Package>, manager: BrewManager) {
        _package = package
        self.manager = manager
    }

    private var activePackage: Package {
        displayedPackage ?? package
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoadingInfo, displayedPackage == nil {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text(CozyBrewL10n.loadingPackageInfo)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                if let infoErrorMessage {
                    Text(infoErrorMessage)
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }

                headerSection
                Divider()
                descriptionSection
                versionSections
                brewInfoExtrasSections
                homepageSection
                installationKindSection
                formulaSourceSection
                licenseSection
                dependenciesSection
                readmeSection
                statusSection
                Divider()
                actionButtons

                if let actionErrorMessage, upgradeFailureStderr != nil {
                    PackageUpgradeFailurePanel(
                        message: actionErrorMessage,
                        package: activePackage,
                        stderr: upgradeFailureStderr
                    )
                } else if let actionErrorMessage {
                    Text(actionErrorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .overlay {
            if isPerformingAction {
                BrewOperationOverlay(
                    title: performingActionTitle ?? "Working…",
                    footnote: performingActionFootnote,
                    style: performingActionFootnote == nil ? .blocking : .passwordFriendly
                )
            }
        }
        .disabled(isPerformingAction)
        .task(id: package.id) {
            await loadPackageInfo()
        }
        .sheet(isPresented: $showsInstallFlow) {
            InstallFlowView(
                package: activePackage,
                onConfirm: {
                    try await manager.install(activePackage)
                    await manager.refreshInstalledPackages()
                    if let fresh = manager.freshListPackage(matching: package) {
                        package = fresh
                    }
                    await loadPackageInfo()
                },
                onCancel: {
                    showsInstallFlow = false
                }
            )
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: activePackage.type == .formula ? "cube.box.fill" : "app.badge.fill")
                    .font(.largeTitle)
                    .foregroundColor(activePackage.type == .formula ? .blue : .green)

                VStack(alignment: .leading, spacing: 4) {
                    Text(activePackage.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text(activePackage.fullName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 8) {
                if activePackage.isOutdated {
                    Label(CozyBrewL10n.badgeUpdateAvailable, systemImage: "arrow.down.circle.fill")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(6)
                }

                if activePackage.isDeprecated {
                    Label(CozyBrewL10n.badgeDeprecated, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .cornerRadius(6)
                }

                Text(activePackage.type == .formula ? "Formula" : "Cask")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.2))
                    .foregroundColor(.secondary)
                    .cornerRadius(6)
            }
        }
    }

    @ViewBuilder
    private var descriptionSection: some View {
        if let desc = activePackage.desc, !desc.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(CozyBrewL10n.sectionDescription)
                    .font(.headline)
                Text(desc)
                    .font(.body)
            }
        }
    }

    @ViewBuilder
    private var brewInfoExtrasSections: some View {
        if let extras = activePackage.infoExtras {
            if let summary = extras.versionSummary, !summary.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(CozyBrewL10n.sectionBrewVersionLine)
                        .font(.headline)
                    Text(summary)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }

            if !extras.installedKegLines.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(CozyBrewL10n.sectionInstalledKegs)
                        .font(.headline)
                    ForEach(extras.installedKegLines, id: \.self) { line in
                        Text(line)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if !extras.runtimeDependencies.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(CozyBrewL10n.sectionRecursiveRuntime)
                        .font(.headline)
                    ForEach(extras.runtimeDependencies, id: \.name) { dep in
                        HStack(spacing: 6) {
                            Image(systemName: dep.isInstalled ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(dep.isInstalled ? .green : .secondary)
                                .font(.caption)
                            Text(dep.name)
                                .font(.body)
                                .foregroundColor(.secondary)
                            if dep.declaredDirectly {
                                Text(CozyBrewL10n.runtimeDependencyDirect)
                                    .font(.caption2)
                                    .foregroundColor(.secondary.opacity(0.8))
                            }
                        }
                    }
                }
            }

            if !extras.options.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(CozyBrewL10n.sectionOptions)
                        .font(.headline)
                    ForEach(extras.options, id: \.flag) { option in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(option.flag)
                                .font(.body.monospaced())
                            if !option.description.isEmpty {
                                Text(option.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            if !extras.analyticsLines.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(CozyBrewL10n.sectionAnalytics)
                        .font(.headline)
                    ForEach(extras.analyticsLines, id: \.self) { line in
                        Text(line)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var versionSections: some View {
        if let installedVersion = activePackage.installedVersion {
            VStack(alignment: .leading, spacing: 4) {
                Text(CozyBrewL10n.sectionInstalledVersion)
                    .font(.headline)
                Text(installedVersion)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }

        if let version = activePackage.upgradeTargetVersion ?? activePackage.version {
            VStack(alignment: .leading, spacing: 4) {
                Text(activePackage.isOutdated ? "Latest Version" : "Version")
                    .font(.headline)
                Text(version)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var homepageSection: some View {
        if let homepage = activePackage.homepage, let url = homepageURL(homepage) {
            VStack(alignment: .leading, spacing: 4) {
                Text(CozyBrewL10n.sectionHomepage)
                    .font(.headline)
                Link(homepage, destination: url)
            }
        }
    }

    @ViewBuilder
    private var installationKindSection: some View {
        if let label = activePackage.installationKindLabel {
            VStack(alignment: .leading, spacing: 4) {
                Text(CozyBrewL10n.sectionInstallation)
                    .font(.headline)
                Text(label)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var formulaSourceSection: some View {
        if let source = activePackage.formulaSourceURL, let url = homepageURL(source) {
            VStack(alignment: .leading, spacing: 4) {
                Text(CozyBrewL10n.sectionFrom)
                    .font(.headline)
                Link(source, destination: url)
            }
        }
    }

    @ViewBuilder
    private var licenseSection: some View {
        if let license = activePackage.license, !license.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(CozyBrewL10n.sectionLicense)
                    .font(.headline)
                Text(license)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var dependenciesSection: some View {
        if let dependencies = activePackage.dependencies, !dependencies.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(CozyBrewL10n.sectionDependencies)
                    .font(.headline)
                Text(dependencies.joined(separator: ", "))
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }

        if let buildDeps = activePackage.buildDependencies, !buildDeps.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(CozyBrewL10n.sectionBuildDependencies)
                    .font(.headline)
                Text(buildDeps.joined(separator: ", "))
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var readmeSection: some View {
        if let markdown = activePackage.infoMarkdown, !markdown.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(CozyBrewL10n.sectionReadme)
                    .font(.headline)
                Group {
                    if let attributed = try? AttributedString(markdown: markdown) {
                        Text(attributed)
                    } else {
                        Text(markdown)
                            .font(.body)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(CozyBrewL10n.sectionStatus)
                .font(.headline)
            if activePackage.isInstalled {
                Text(activePackage.isOutdated ? CozyBrewL10n.statusInstalledUpdate : CozyBrewL10n.statusInstalled)
                    .font(.body)
                    .foregroundColor(.green)
            } else {
                Text(CozyBrewL10n.statusNotInstalled)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            if activePackage.isInstalled {
                if activePackage.isOutdated {
                    Button {
                        Task { await performUpgrade() }
                    } label: {
                        Label(CozyBrewL10n.actionUpgrade, systemImage: "arrow.down.circle")
                            .accessibilityLabel(CozyBrewL10n.actionUpgrade)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isPerformingAction || isLoadingInfo)
                }

                Button {
                    Task { await performUninstall() }
                } label: {
                    Label(CozyBrewL10n.actionUninstall, systemImage: "trash")
                        .accessibilityLabel(CozyBrewL10n.actionUninstall)
                }
                .buttonStyle(.bordered)
                .disabled(isPerformingAction || isLoadingInfo)
            } else {
                Button {
                    showsInstallFlow = true
                } label: {
                    Label(CozyBrewL10n.actionInstall, systemImage: "arrow.down.circle.fill")
                        .accessibilityLabel(CozyBrewL10n.actionInstall)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isPerformingAction || isLoadingInfo)
            }
        }
    }

    private func performUpgrade() async {
        let isCask = activePackage.type == .cask
        await runBrewAction(
            title: isCask ? "Upgrading Cask…" : "Upgrading…",
            footnote: isCask ? BrewUserMessage.caskUpgradePasswordHint : nil
        ) {
            try await manager.upgrade(activePackage)
            await manager.refreshInstalledPackages()
            await manager.refreshOutdatedPackages()
            await manager.refreshManagedServices()
            if let fresh = manager.freshListPackage(matching: package) {
                package = fresh
            }
            await loadPackageInfo()
        }
    }

    private func performUninstall() async {
        await runBrewAction(title: "Uninstalling…") {
            try await manager.uninstall(activePackage)
            await manager.refreshInstalledPackages()
            await manager.refreshOutdatedPackages()
            if let fresh = manager.freshListPackage(matching: package) {
                package = fresh
            } else {
                package = Package(
                    id: package.id,
                    name: package.name,
                    fullName: package.fullName,
                    type: package.type,
                    desc: package.desc,
                    homepage: package.homepage,
                    isInstalled: false,
                    isOutdated: false
                )
            }
            await loadPackageInfo()
        }
    }

    private func runBrewAction(
        title: String,
        footnote: String? = nil,
        operation: () async throws -> Void
    ) async {
        isPerformingAction = true
        performingActionTitle = title
        performingActionFootnote = footnote
        actionErrorMessage = nil
        upgradeFailureStderr = nil
        defer {
            isPerformingAction = false
            performingActionTitle = nil
            performingActionFootnote = nil
        }

        do {
            try await operation()
        } catch {
            if case let BrewManagerError.upgradeFailed(stderr) = error {
                upgradeFailureStderr = stderr
            } else {
                upgradeFailureStderr = nil
            }
            actionErrorMessage = brewActionErrorMessage(error)
        }
    }

    private func brewActionErrorMessage(_ error: Error) -> String {
        if case let BrewManagerError.upgradeFailed(stderr) = error {
            return BrewUserMessage.upgradeFailure(from: stderr, packageType: activePackage.type)
        }
        return error.localizedDescription
    }

    private func loadPackageInfo() async {
        isLoadingInfo = true
        infoErrorMessage = nil
        defer { isLoadingInfo = false }

        do {
            displayedPackage = try await manager.packageInfo(for: package)
        } catch {
            infoErrorMessage = error.localizedDescription
            displayedPackage = package
        }
    }

    private func homepageURL(_ string: String) -> URL? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        return URL(string: "https://\(trimmed)")
    }
}
