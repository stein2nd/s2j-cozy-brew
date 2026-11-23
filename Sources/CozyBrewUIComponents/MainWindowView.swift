import AppKit
import CozyBrewService
import SwiftUI

/// メインウィンドウビュー
public struct MainWindowView: View {
    @ObservedObject var manager: BrewManager
    @StateObject private var sourceListAdapter = S2JSourceListAdapter()
    @State private var showsUpgradeAllConfirmation = false
    @State private var isUpgradingAll = false
    @State private var upgradeAllErrorMessage: String?
    @State private var showsCakebrewMigration = false
    @State private var cakebrewLegacy: CakebrewLegacyPreferences?

    public init(manager: BrewManager) {
        self.manager = manager
    }

    public var body: some View {
        NavigationSplitView {
            CozyBrewSourceListSidebar(adapter: sourceListAdapter, manager: manager)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        } detail: {
            ContentAreaView(
                manager: manager,
                selectedSidebarItem: sourceListAdapter.selectedSidebarItem,
                selectedSidebarItemBinding: sourceListAdapter.selectedSidebarItemBinding
            )
        }
        .toolbar {
            if sourceListAdapter.selectedSidebarItem == .outdated,
               !manager.outdatedPackages.isEmpty
            {
                ToolbarItem(placement: .automatic) {
                    Button {
                        showsUpgradeAllConfirmation = true
                    } label: {
                        Label(CozyBrewL10n.upgradeAll, systemImage: "arrow.down.circle.fill")
                    }
                    .disabled(isUpgradingAll || !manager.isBrewAvailable)
                    .help(CozyBrewL10n.upgradeAllHelp)
                    .accessibilityLabel(CozyBrewL10n.a11yUpgradeAll)
                }
            }

            ToolbarItem(placement: .primaryAction) {
                if sourceListAdapter.selectedSidebarItem == .warnings {
                    Button {
                        Task { await manager.refreshDoctorWarnings() }
                    } label: {
                        Label(CozyBrewL10n.refresh, systemImage: "arrow.clockwise")
                    }
                    .disabled(manager.doctorIsLoading || !manager.isBrewAvailable)
                    .accessibilityLabel(CozyBrewL10n.a11yRefresh)
                } else {
                    Button {
                        Task { await manager.refreshApplicationState() }
                    } label: {
                        Label(CozyBrewL10n.refresh, systemImage: "arrow.clockwise")
                    }
                    .disabled(manager.isLoading || !manager.isBrewAvailable)
                    .help(CozyBrewL10n.refreshHelp)
                    .accessibilityLabel(CozyBrewL10n.a11yRefresh)
                }
            }
        }
        .confirmationDialog(
            CozyBrewL10n.upgradeAllDialogTitle,
            isPresented: $showsUpgradeAllConfirmation,
            titleVisibility: .visible
        ) {
            Button(CozyBrewL10n.upgradeAllDialogConfirm) {
                Task { await performUpgradeAll() }
            }
            Button(CozyBrewL10n.actionCancel, role: .cancel) {}
        } message: {
            Text(CozyBrewL10n.upgradeAllDialogMessage(manager.outdatedPackages.count))
        }
        .onReceive(NotificationCenter.default.publisher(for: .cozyBrewNavigateToWarnings)) { _ in
            sourceListAdapter.selectSidebarItem(.warnings)
            Task { await manager.refreshDoctorWarnings() }
            NSApplication.shared.activate(ignoringOtherApps: true)
            let envTitle = CozyBrewL10n.environmentWindowTitle
            if let main = NSApplication.shared.windows.first(where: { $0.isVisible && $0.title != envTitle }) {
                main.makeKeyAndOrderFront(nil)
            }
        }
        .overlay {
            if isUpgradingAll {
                BrewOperationOverlay(
                    title: CozyBrewL10n.upgradingAllOverlay,
                    footnote: nil,
                    style: .blocking
                )
            }
        }
        .disabled(isUpgradingAll)
        .task {
            if manager.isBrewAvailable {
                await manager.refreshManagedServices()
                await manager.refreshInstalledPackages()
                await manager.refreshOutdatedPackages()
                await manager.refreshTaps()
                await manager.refreshDoctorWarnings()
            }
        }
        .onAppear {
            if cakebrewLegacy == nil,
               let legacy = CakebrewMigration.detectLegacyPreferences(),
               !CakebrewMigration.hasCompletedMigration()
            {
                cakebrewLegacy = legacy
                showsCakebrewMigration = true
            }
        }
        .sheet(isPresented: $showsCakebrewMigration) {
            if let legacy = cakebrewLegacy {
                CakebrewMigrationSheet(legacy: legacy, manager: manager) {
                    showsCakebrewMigration = false
                }
            }
        }
        .alert(
            CozyBrewL10n.upgradeAllFailedTitle,
            isPresented: Binding(
                get: { upgradeAllErrorMessage != nil },
                set: { presented in
                    if !presented {
                        upgradeAllErrorMessage = nil
                    }
                }
            ),
            actions: {
                Button(CozyBrewL10n.actionOK, role: .cancel) {}
            },
            message: {
                Text(upgradeAllErrorMessage ?? "")
            }
        )
    }

    private func performUpgradeAll() async {
        isUpgradingAll = true
        upgradeAllErrorMessage = nil
        defer { isUpgradingAll = false }
        do {
            try await manager.upgradeAll()
        } catch {
            upgradeAllErrorMessage = error.localizedDescription
        }
    }
}

/// サイドバーアイテム
public enum SidebarItem: String, CaseIterable, Identifiable, Sendable {
    case warnings = "Warnings"
    case installed = "Installed"
    case outdated = "Outdated"
    case history = "History"
    case taps = "Taps"
    case formulae = "Formulae"
    case casks = "Casks"

    public var id: String {
        rawValue
    }

    public var icon: String {
        switch self {
        case .warnings: "exclamationmark.triangle.fill"
        case .installed: "checkmark.circle.fill"
        case .outdated: "arrow.down.circle.fill"
        case .history: "clock.arrow.circlepath"
        case .taps: "square.stack.3d.up.fill"
        case .formulae: "cube.box.fill"
        case .casks: "app.badge.fill"
        }
    }

    public var localizedTitle: String {
        switch self {
        case .warnings: CozyBrewL10n.sidebarWarnings
        case .installed: CozyBrewL10n.sidebarInstalled
        case .outdated: CozyBrewL10n.sidebarOutdated
        case .history: CozyBrewL10n.sidebarHistory
        case .taps: CozyBrewL10n.sidebarTaps
        case .formulae: CozyBrewL10n.sidebarFormulae
        case .casks: CozyBrewL10n.sidebarCasks
        }
    }
}

/// コンテンツエリアビュー
struct ContentAreaView: View {
    @ObservedObject var manager: BrewManager
    let selectedSidebarItem: SidebarItem?
    @Binding var selectedSidebarItemBinding: SidebarItem?
    @State private var searchText: String = ""
    @State private var selectedPackage: Package?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if selectedSidebarItem != .warnings, selectedPackage == nil {
                    // 検索バー (詳細表示中は非表示 — #17)
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField(CozyBrewL10n.searchPlaceholder, text: $searchText)
                            .textFieldStyle(.plain)
                            .accessibilityLabel(CozyBrewL10n.a11ySearchField)

                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))

                    Divider()
                }

                // パッケージ一覧または詳細
                if selectedPackage != nil {
                    PackageDetailView(
                        package: Binding(
                            get: { selectedPackage! },
                            set: { selectedPackage = $0 }
                        ),
                        manager: manager
                    )
                } else if selectedSidebarItem == .warnings {
                    DoctorWarningsView(manager: manager)
                } else if selectedSidebarItem == .taps {
                    TapListView(manager: manager, searchText: searchText)
                } else if selectedSidebarItem == .history {
                    OperationHistoryView(manager: manager, searchText: searchText)
                } else {
                    PackageListView(
                        manager: manager,
                        selectedSidebarItem: selectedSidebarItem,
                        searchText: searchText,
                        onPackageSelect: { package in
                            selectedPackage = package
                        }
                    )
                }
            }
            .navigationTitle(detailNavigationTitle)
            .toolbar {
                if selectedPackage != nil {
                    ToolbarItem(placement: .navigation) {
                        Button {
                            selectedPackage = nil
                        } label: {
                            Label(CozyBrewL10n.back, systemImage: "chevron.backward")
                        }
                        .accessibilityLabel(CozyBrewL10n.a11yBack)
                        .keyboardShortcut(.escape, modifiers: [])
                    }
                }
            }
        }
        .onChange(of: selectedSidebarItem) { _, newItem in
            selectedPackage = nil
            switch newItem {
            case .warnings:
                Task { await manager.refreshDoctorWarnings() }
            case .formulae:
                Task { await manager.refreshCatalogFormulae() }
            case .casks:
                Task { await manager.refreshCatalogCasks() }
            default:
                break
            }
        }
    }

    private var detailNavigationTitle: String {
        if let selectedPackage {
            return selectedPackage.name
        }
        return selectedSidebarItem?.localizedTitle ?? CozyBrewL10n.navigationTitle
    }
}

/// パッケージ一覧ビュー
struct PackageListView: View {
    @ObservedObject var manager: BrewManager
    let selectedSidebarItem: SidebarItem?
    let searchText: String
    let onPackageSelect: (Package) -> Void

    @State private var isUpgrading = false
    @State private var upgradeOverlayTitle = "Upgrading…"
    @State private var upgradeOverlayFootnote: String?
    @State private var upgradeErrorMessage: String?
    @State private var upgradeFailurePackage: Package?
    @State private var upgradeFailureStderr: String?
    @State private var catalogPageRange: CatalogPageRange = .aThroughE
    @State private var installFlowPackage: Package?

    private var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var rawDisplayedPackages: [Package] {
        let base: [Package] = {
            switch selectedSidebarItem {
            case .installed:
                return manager.installedPackages
            case .outdated:
                return manager.outdatedPackages
            case .formulae:
                if isSearchActive {
                    return manager.catalogFormulaeSnapshot()
                }
                return manager.catalogFormulaePage(catalogPageRange)
            case .casks:
                if isSearchActive {
                    return manager.catalogCasksSnapshot()
                }
                return manager.catalogCasksPage(catalogPageRange)
            default:
                return []
            }
        }()
        guard isSearchActive else { return base }
        return base.filter { PackageListFilter.matches($0, query: searchText) }
    }

    private var shouldAnnotateOutdatedStatus: Bool {
        switch selectedSidebarItem {
        case .installed, .formulae, .casks:
            true
        default:
            false
        }
    }

    private var isCatalogSidebar: Bool {
        selectedSidebarItem == .formulae || selectedSidebarItem == .casks
    }

    private var isListLoading: Bool {
        if isCatalogSidebar {
            switch selectedSidebarItem {
            case .formulae:
                return manager.catalogFormulaeIsLoading && !manager.hasCatalogFormulae
            case .casks:
                return manager.catalogCasksIsLoading && !manager.hasCatalogCasks
            default:
                return false
            }
        }
        return manager.isLoading
    }

    private var listLoadErrorMessage: String? {
        guard !isSearchActive else { return nil }
        if isCatalogSidebar {
            switch selectedSidebarItem {
            case .formulae:
                return manager.catalogFormulaeErrorMessage
            case .casks:
                return manager.catalogCasksErrorMessage
            default:
                return nil
            }
        }
        return manager.errorMessage
    }

    var displayedPackages: [Package] {
        let base = rawDisplayedPackages
        if isCatalogSidebar {
            if isSearchActive {
                return manager.sortedCatalogAlphabetically(
                    manager.annotatingOutdatedStatus(base)
                )
            }
            return base
        }
        let annotated = shouldAnnotateOutdatedStatus
            ? manager.annotatingOutdatedStatus(base)
            : base
        return manager.sortedForDisplay(annotated)
    }

    var body: some View {
        VStack(spacing: 0) {
            if isCatalogSidebar, !isSearchActive {
                CatalogPageRangeBar(selection: $catalogPageRange)
                Divider()
            }

            Group {
                if isListLoading {
                    ProgressView()
                } else if displayedPackages.isEmpty {
                    VStack(spacing: 16) {
                        let showLoadError = listLoadErrorMessage != nil
                        Image(systemName: showLoadError ? "exclamationmark.triangle" : "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text(
                            isSearchActive
                                ? "No matching packages"
                                : (showLoadError ? "Could not load packages" : emptyCatalogMessage)
                        )
                        .font(.headline)
                        .foregroundColor(.secondary)
                        if showLoadError, let errorMessage = listLoadErrorMessage {
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if isCatalogSidebar {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(displayedPackages, id: \.listRowID) { package in
                                catalogPackageRow(package)
                                Divider()
                            }
                        }
                    }
                    .id(catalogListRefreshToken)
                } else {
                    List {
                        ForEach(displayedPackages, id: \.listRowID) { package in
                            catalogPackageRow(package)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            if isUpgrading {
                BrewOperationOverlay(
                    title: upgradeOverlayTitle,
                    footnote: upgradeOverlayFootnote,
                    style: upgradeOverlayFootnote == nil ? .blocking : .passwordFriendly
                )
            }
        }
        .disabled(isUpgrading)
        .onChange(of: selectedSidebarItem) { _, newItem in
            if newItem == .formulae || newItem == .casks {
                catalogPageRange = .aThroughE
            }
        }
        .onChange(of: manager.isLoading) { wasLoading, isLoading in
            guard wasLoading, !isLoading, upgradeErrorMessage != nil else { return }
            if let failed = upgradeFailurePackage,
               !manager.outdatedPackages.contains(where: { $0.listRowID == failed.listRowID })
            {
                upgradeErrorMessage = nil
                upgradeFailurePackage = nil
                upgradeFailureStderr = nil
            }
        }
        .sheet(item: $installFlowPackage) { package in
            InstallFlowView(
                package: package,
                onConfirm: {
                    try await manager.install(package)
                    await manager.refreshInstalledPackages()
                },
                onCancel: {
                    installFlowPackage = nil
                }
            )
        }
    }

    private var catalogListRefreshToken: Int {
        switch selectedSidebarItem {
        case .formulae:
            manager.catalogFormulaeGeneration
        case .casks:
            manager.catalogCasksGeneration
        default:
            0
        }
    }

    private func catalogPackageRow(_ package: Package) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            PackageRowView(
                package: package,
                brewServiceStatus: manager.managedService(for: package)?.status,
                onInstall: {
                    installFlowPackage = package
                },
                onUninstall: {
                    Task {
                        try? await manager.uninstall(package)
                        await manager.refreshInstalledPackages()
                    }
                },
                onUpgrade: {
                    Task { await performUpgrade(package) }
                }
            )
            .contentShape(Rectangle())
            .onTapGesture {
                onPackageSelect(package)
            }

            if showsUpgradeFailure(for: package) {
                PackageUpgradeFailurePanel(
                    message: upgradeErrorMessage ?? "",
                    package: package,
                    stderr: upgradeFailureStderr
                )
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
    }

    private func showsUpgradeFailure(for package: Package) -> Bool {
        guard upgradeErrorMessage != nil,
              let failed = upgradeFailurePackage,
              failed.listRowID == package.listRowID
        else {
            return false
        }
        return true
    }

    private var emptyCatalogMessage: String {
        if isCatalogSidebar, !isSearchActive, listLoadErrorMessage == nil {
            return "No packages in \(catalogPageRange.rawValue)"
        }
        return "No packages found"
    }

    private func performUpgrade(_ package: Package) async {
        isUpgrading = true
        upgradeErrorMessage = nil
        upgradeFailurePackage = nil
        upgradeFailureStderr = nil
        upgradeOverlayTitle = package.type == .cask ? "Upgrading Cask…" : "Upgrading…"
        upgradeOverlayFootnote = package.type == .cask ? BrewUserMessage.caskUpgradePasswordHint : nil
        defer {
            isUpgrading = false
            upgradeOverlayTitle = "Upgrading…"
            upgradeOverlayFootnote = nil
        }

        do {
            try await manager.upgrade(package)
            await manager.refreshInstalledPackages()
            await manager.refreshOutdatedPackages()
            await manager.refreshManagedServices()
        } catch {
            upgradeFailurePackage = package
            if case let BrewManagerError.upgradeFailed(stderr) = error {
                upgradeFailureStderr = stderr
                upgradeErrorMessage = BrewUserMessage.upgradeFailure(from: stderr, packageType: package.type)
            } else {
                upgradeFailureStderr = ""
                upgradeErrorMessage = error.localizedDescription
            }
        }
    }
}

/// Formulae / Casks の先頭文字ページ選択
struct CatalogPageRangeBar: View {
    @Binding var selection: CatalogPageRange

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CatalogPageRange.allCases) { range in
                    Button {
                        selection = range
                    } label: {
                        Text(range.rawValue)
                            .font(.subheadline)
                            .fontWeight(selection == range ? .semibold : .regular)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selection == range
                                    ? Color.accentColor.opacity(0.2)
                                    : Color(NSColor.controlBackgroundColor)
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        .fixedSize(horizontal: false, vertical: true)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

/// `brew doctor` Warning 一覧
struct DoctorWarningsView: View {
    @ObservedObject var manager: BrewManager

    var body: some View {
        Group {
            if manager.doctorIsLoading, manager.doctorWarnings.isEmpty {
                ProgressView("Running brew doctor…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = manager.doctorErrorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(CozyBrewL10n.doctorCouldNotRun)
                        .font(.headline)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if manager.doctorWarnings.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    Text(CozyBrewL10n.doctorNoWarnings)
                        .font(.headline)
                    if let preamble = manager.doctorPreamble {
                        Text(preamble)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    if let preamble = manager.doctorPreamble {
                        Section {
                            Text(preamble)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    ForEach(manager.doctorWarnings) { warning in
                        Section {
                            ForEach(warning.bodyLines, id: \.self) { line in
                                Text(line)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            ForEach(warning.items, id: \.self) { item in
                                Label(item, systemImage: "smallcircle.filled.circle")
                                    .font(.body.monospaced())
                            }
                        } header: {
                            Text(warning.title)
                                .font(.headline)
                                .foregroundColor(.orange)
                                .textCase(nil)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Tap 一覧
struct TapListView: View {
    @ObservedObject var manager: BrewManager
    let searchText: String

    @State private var showsAddTap = false
    @State private var newTapName = ""
    @State private var tapToRemove: Tap?
    @State private var untapSummary: TapRemovalSummary?
    @State private var tapActionError: String?
    @State private var isTapActionRunning = false

    private var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var displayedTaps: [Tap] {
        let base = manager.taps
        guard isSearchActive else { return base }
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return base.filter {
            $0.name.localizedCaseInsensitiveContains(needle)
                || $0.user.localizedCaseInsensitiveContains(needle)
                || $0.repo.localizedCaseInsensitiveContains(needle)
        }
    }

    var body: some View {
        Group {
            if manager.isLoading, manager.taps.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if displayedTaps.isEmpty {
                VStack(spacing: 16) {
                    let showLoadError = !isSearchActive && manager.tapsErrorMessage != nil
                    Image(systemName: showLoadError ? "exclamationmark.triangle" : "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(
                        isSearchActive
                            ? "No matching taps"
                            : (showLoadError ? "Could not load taps" : "No taps found")
                    )
                    .font(.headline)
                    .foregroundColor(.secondary)
                    if showLoadError, let message = manager.tapsErrorMessage {
                        Text(message)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(displayedTaps) { tap in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tap.name)
                            .font(.headline)
                        if let remote = tap.remote, !remote.isEmpty {
                            Text(remote)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 4)
                    .contextMenu {
                        if tap.official != true {
                            Button(CozyBrewL10n.tapUntap, role: .destructive) {
                                tapToRemove = tap
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    newTapName = ""
                    showsAddTap = true
                } label: {
                    Label(CozyBrewL10n.tapAdd, systemImage: "plus")
                }
                .disabled(!manager.isBrewAvailable || isTapActionRunning)
                .accessibilityLabel(CozyBrewL10n.tapAdd)
            }
        }
        .sheet(isPresented: $showsAddTap) {
            VStack(alignment: .leading, spacing: 16) {
                Text(CozyBrewL10n.tapAddTitle)
                    .font(.headline)
                TextField(CozyBrewL10n.tapAddPlaceholder, text: $newTapName)
                HStack {
                    Button(CozyBrewL10n.actionCancel) {
                        showsAddTap = false
                    }
                    Spacer()
                    Button(CozyBrewL10n.tapAddConfirm) {
                        Task { await submitAddTap() }
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(newTapName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(20)
            .frame(minWidth: 360)
        }
        .confirmationDialog(
            CozyBrewL10n.tapUntapTitle,
            isPresented: Binding(
                get: { tapToRemove != nil },
                set: {
                    if !$0 {
                        tapToRemove = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            if let tap = tapToRemove {
                Button(CozyBrewL10n.tapUntapConfirm, role: .destructive) {
                    Task { await submitUntap(tap) }
                }
            }
            Button(CozyBrewL10n.actionCancel, role: .cancel) {
                tapToRemove = nil
            }
        } message: {
            if let tap = tapToRemove {
                if let untapSummary {
                    Text(
                        "\(CozyBrewL10n.tapUntapMessage(tap.name))\n\n"
                            + CozyBrewL10n.tapUntapSummary(untapSummary)
                    )
                } else {
                    Text(CozyBrewL10n.tapUntapMessage(tap.name))
                }
            }
        }
        .alert(CozyBrewL10n.tapActionFailed, isPresented: Binding(
            get: { tapActionError != nil },
            set: {
                if !$0 {
                    tapActionError = nil
                }
            }
        )) {
            Button(CozyBrewL10n.actionOK, role: .cancel) {}
        } message: {
            Text(tapActionError ?? "")
        }
        .overlay {
            if isTapActionRunning {
                BrewOperationOverlay(title: CozyBrewL10n.tapWorking, footnote: nil, style: .blocking)
            }
        }
        .disabled(isTapActionRunning)
        .onChange(of: tapToRemove?.id) { _, tapID in
            untapSummary = nil
            guard let tapID, let tap = tapToRemove, tap.id == tapID else { return }
            Task {
                untapSummary = await manager.tapRemovalSummary(for: tap)
            }
        }
    }

    private func submitAddTap() async {
        isTapActionRunning = true
        defer { isTapActionRunning = false }
        do {
            try await manager.addTap(named: newTapName)
            showsAddTap = false
        } catch {
            tapActionError = error.localizedDescription
        }
    }

    private func submitUntap(_ tap: Tap) async {
        isTapActionRunning = true
        defer { isTapActionRunning = false }
        do {
            try await manager.removeTap(tap)
        } catch {
            tapActionError = error.localizedDescription
        }
    }
}
