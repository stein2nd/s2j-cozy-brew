import SwiftUI
import CozyBrewService

/// メインウィンドウビュー
public struct MainWindowView: View {
    @ObservedObject var manager: BrewManager
    @State private var selectedSidebarItem: SidebarItem? = .installed
    @State private var searchText: String = ""
    @State private var selectedPackage: Package?
    
    public init(manager: BrewManager) {
        self.manager = manager
    }
    
    public var body: some View {
        if #available(macOS 13.0, *) {
            NavigationSplitView {
                // サイドバー
                SidebarView(selectedItem: $selectedSidebarItem)
                    .navigationSplitViewColumnWidth(min: 200, ideal: 250)
            } detail: {
                // コンテンツエリア
                ContentAreaView(
                    manager: manager,
                    selectedSidebarItem: selectedSidebarItem,
                    searchText: $searchText,
                    selectedPackage: $selectedPackage,
                    selectedSidebarItemBinding: $selectedSidebarItem
                )
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        Task {
                            try? await manager.update()
                        }
                    }) {
                        Label("Update", systemImage: "arrow.clockwise")
                    }
                    .disabled(manager.isLoading || !manager.isBrewAvailable)
                }
            }
            .task {
                if manager.isBrewAvailable {
                    await manager.refreshInstalledPackages()
                    await manager.refreshOutdatedPackages()
                    await manager.refreshTaps()
                }
            }
        } else {
            // macOS 12.0 用の代替実装
            HSplitView {
                // サイドバー
                SidebarView(selectedItem: $selectedSidebarItem)
                    .frame(minWidth: 200, idealWidth: 250)
                
                // コンテンツエリア
                ContentAreaView(
                    manager: manager,
                    selectedSidebarItem: selectedSidebarItem,
                    searchText: $searchText,
                    selectedPackage: $selectedPackage,
                    selectedSidebarItemBinding: $selectedSidebarItem
                )
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        Task {
                            try? await manager.update()
                        }
                    }) {
                        Label("Update", systemImage: "arrow.clockwise")
                    }
                    .disabled(manager.isLoading || !manager.isBrewAvailable)
                }
            }
            .task {
                if manager.isBrewAvailable {
                    await manager.refreshInstalledPackages()
                    await manager.refreshOutdatedPackages()
                    await manager.refreshTaps()
                }
            }
        }
    }
}

/// サイドバーアイテム
public enum SidebarItem: String, CaseIterable, Identifiable {
    case installed = "Installed"
    case outdated = "Outdated"
    case taps = "Taps"
    case formulae = "Formulae"
    case casks = "Casks"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .installed: return "checkmark.circle.fill"
        case .outdated: return "arrow.down.circle.fill"
        case .taps: return "square.stack.3d.up.fill"
        case .formulae: return "cube.box.fill"
        case .casks: return "app.badge.fill"
        }
    }
}

/// サイドバービュー
struct SidebarView: View {
    @Binding var selectedItem: SidebarItem?
    
    var body: some View {
        List(selection: $selectedItem) {
            ForEach(SidebarItem.allCases) { item in
                Label(item.rawValue, systemImage: item.icon)
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
    @Binding var searchText: String
    @Binding var selectedPackage: Package?
    @Binding var selectedSidebarItemBinding: SidebarItem?
    
    var body: some View {
        VStack(spacing: 0) {
            // 検索バー
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search packages...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        Task {
                            await manager.search(searchText)
                        }
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        selectedSidebarItemBinding = .installed
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // パッケージ一覧または詳細
            if let selectedPackage = selectedPackage {
                PackageDetailView(
                    package: selectedPackage,
                    onInstall: {
                        Task {
                            try? await manager.install(selectedPackage)
                            await manager.refreshInstalledPackages()
                        }
                    },
                    onUninstall: {
                        Task {
                            try? await manager.uninstall(selectedPackage)
                            await manager.refreshInstalledPackages()
                        }
                    },
                    onUpgrade: {
                        Task {
                            try? await manager.upgrade(selectedPackage)
                            await manager.refreshInstalledPackages()
                            await manager.refreshOutdatedPackages()
                        }
                    }
                )
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
    }
}

/// パッケージ一覧ビュー
struct PackageListView: View {
    @ObservedObject var manager: BrewManager
    let selectedSidebarItem: SidebarItem?
    let searchText: String
    let onPackageSelect: (Package) -> Void
    
    var displayedPackages: [Package] {
        if !searchText.isEmpty {
            return manager.searchResults
        }
        
        switch selectedSidebarItem {
        case .installed:
            return manager.installedPackages
        case .outdated:
            return manager.outdatedPackages
        case .formulae:
            return manager.installedPackages.filter { $0.type == .formula }
        case .casks:
            return manager.installedPackages.filter { $0.type == .cask }
        default:
            return []
        }
    }
    
    var body: some View {
        Group {
            if manager.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if displayedPackages.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No packages found")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(displayedPackages) { package in
                    PackageRowView(
                        package: package,
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
                            Task {
                                try? await manager.upgrade(package)
                                await manager.refreshInstalledPackages()
                                await manager.refreshOutdatedPackages()
                            }
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onPackageSelect(package)
                    }
                }
            }
        }
    }
}
