import CozyBrewService
import SwiftUI

/// メインウィンドウビュー
public struct MainWindowView: View {
    @ObservedObject var manager: BrewManager
    @State private var selectedSidebarItem: SidebarItem? = .installed

    public init(manager: BrewManager) {
        self.manager = manager
    }

    public var body: some View {
        NavigationSplitView {
            // サイドバー
            SidebarView(selectedItem: $selectedSidebarItem, manager: manager)
                .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        } detail: {
            // コンテンツエリア
            ContentAreaView(
                manager: manager,
                selectedSidebarItem: selectedSidebarItem,
                selectedSidebarItemBinding: $selectedSidebarItem
            )
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if selectedSidebarItem == .warnings {
                    Button {
                        Task { await manager.refreshDoctorWarnings() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(manager.doctorIsLoading || !manager.isBrewAvailable)
                } else {
                    Button {
                        Task {
                            try? await manager.update()
                        }
                    } label: {
                        Label("Update", systemImage: "arrow.clockwise")
                    }
                    .disabled(manager.isLoading || !manager.isBrewAvailable)
                }
            }
        }
        .task {
            if manager.isBrewAvailable {
                await manager.refreshManagedServices()
                await manager.refreshInstalledPackages()
                await manager.refreshOutdatedPackages()
                await manager.refreshTaps()
                await manager.refreshDoctorWarnings()
            }
        }
    }
}

/// サイドバーアイテム
public enum SidebarItem: String, CaseIterable, Identifiable {
    case warnings = "Warnings"
    case installed = "Installed"
    case outdated = "Outdated"
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
        case .taps: "square.stack.3d.up.fill"
        case .formulae: "cube.box.fill"
        case .casks: "app.badge.fill"
        }
    }
}

/// サイドバービュー
struct SidebarView: View {
    @Binding var selectedItem: SidebarItem?
    @ObservedObject var manager: BrewManager

    var body: some View {
        List(selection: $selectedItem) {
            ForEach(SidebarItem.allCases) { item in
                HStack {
                    Label(item.rawValue, systemImage: item.icon)
                    Spacer()
                    if item == .warnings, manager.doctorWarningCount > 0 {
                        Text("\(manager.doctorWarningCount)")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.25))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                    }
                }
                .tag(item)
            }
        }
        .navigationTitle("CozyBrew")
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
                if selectedSidebarItem != .warnings {
                    // 検索バー
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search packages...", text: $searchText)
                            .textFieldStyle(.plain)

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
                            Label("Back", systemImage: "chevron.backward")
                        }
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
        return selectedSidebarItem?.rawValue ?? "Packages"
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
    @State private var catalogPageRange: CatalogPageRange = .aThroughE

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
            if let upgradeErrorMessage {
                Text(upgradeErrorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
            }

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
        PackageRowView(
            package: package,
            brewServiceStatus: manager.managedService(for: package)?.status,
            onInstall: {
                Task {
                    try? await manager.install(package)
                    await manager.refreshInstalledPackages()
                }
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
            if case let BrewManagerError.upgradeFailed(stderr) = error {
                upgradeErrorMessage = BrewUserMessage.upgradeFailure(from: stderr, packageType: package.type)
            } else {
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
                    Text("Could not run brew doctor")
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
                    Text("No warnings")
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
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
