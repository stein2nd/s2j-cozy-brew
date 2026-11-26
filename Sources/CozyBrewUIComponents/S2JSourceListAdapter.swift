import Combine
import CozyBrewService
import S2JSourceList
import SwiftUI

/// `SidebarItem` と S2J Source List の固定 UUID を双方向で結ぶレジストリ（`metadata` には載せない）。
/// サイドバーに件数バッジを付ける `SidebarItem`（History は対象外）
private let sidebarItemsWithCountBadge: [SidebarItem] = [
    .installed, .outdated, .taps, .formulae, .casks,
]

enum SidebarItemSourceListRegistry {
    /// アプリ更新ごとに不変。再ビルドで選択が飛ばないよう固定 UUID を使う。
    private static let idsByItem: [SidebarItem: UUID] = [
        .warnings: UUID(uuidString: "C0A70900-0001-4000-8000-53696E650001")!,
        .installed: UUID(uuidString: "C0A70900-0002-4000-8000-53696E650002")!,
        .outdated: UUID(uuidString: "C0A70900-0003-4000-8000-53696E650003")!,
        .history: UUID(uuidString: "C0A70900-0007-4000-8000-53696E650007")!,
        .taps: UUID(uuidString: "C0A70900-0004-4000-8000-53696E650004")!,
        .formulae: UUID(uuidString: "C0A70900-0005-4000-8000-53696E650005")!,
        .casks: UUID(uuidString: "C0A70900-0006-4000-8000-53696E650006")!,
    ]

    private static let installedPackagesGroupID =
        UUID(uuidString: "C0A70900-0010-4000-8000-53696E650010")!
    private static let catalogGroupID =
        UUID(uuidString: "C0A70900-0011-4000-8000-53696E650011")!

    private static let itemByID: [UUID: SidebarItem] = Dictionary(
        uniqueKeysWithValues: idsByItem.map { ($0.value, $0.key) }
    )

    static func id(for item: SidebarItem) -> UUID {
        guard let id = idsByItem[item] else {
            preconditionFailure("Unknown SidebarItem: \(item)")
        }
        return id
    }

    static func sidebarItem(for id: UUID) -> SidebarItem? {
        itemByID[id]
    }

    static func makeRootItems() -> [SourceItem] {
        func leaf(_ item: SidebarItem) -> SourceItem {
            SourceItem(
                id: id(for: item),
                title: item.localizedTitle,
                icon: item.icon,
                badge: nil,
                isSelectable: true
            )
        }

        return [
            leaf(.warnings),
            SourceItem.group(
                id: installedPackagesGroupID,
                title: CozyBrewL10n.sidebarGroupInstalledPackages,
                icon: "shippingbox.fill",
                children: [leaf(.installed), leaf(.outdated), leaf(.history)],
                isExpanded: true
            ),
            leaf(.taps),
            SourceItem.group(
                id: catalogGroupID,
                title: CozyBrewL10n.sidebarGroupCatalog,
                icon: "square.grid.2x2.fill",
                children: [leaf(.formulae), leaf(.casks)],
                isExpanded: true
            ),
        ]
    }
}

/// 仕様どおり S2J Source List を CozyBrew のサイドバー選択に橋渡しする。
@MainActor
public final class S2JSourceListAdapter: ObservableObject {
    public let service: SourceListService
    public let selectionManager: SelectionManager

    @Published public private(set) var selectedSidebarItem: SidebarItem? = .installed

    private var isSyncingSelection = false
    private var cancellables = Set<AnyCancellable>()

    public init() {
        service = SourceListService(rootItems: SidebarItemSourceListRegistry.makeRootItems())
        // `SidebarView` の `allowsMultipleSelection: false` と一致（#10: ライブラリ側でモード同期しない）
        selectionManager = SelectionManager(selectionMode: .single)

        selectionManager.$selectedItemIds
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ids in
                guard let self, !self.isSyncingSelection else { return }
                let mapped = ids.first.flatMap { SidebarItemSourceListRegistry.sidebarItem(for: $0) }
                guard selectedSidebarItem != mapped else { return }
                Task { @MainActor in
                    self.selectedSidebarItem = mapped
                }
            }
            .store(in: &cancellables)
    }

    /// 初回表示後に選択を適用（`init` 中の `@Published` 更新を避ける）。
    func applyInitialSelectionIfNeeded() {
        guard selectionManager.selectedItemIds.isEmpty else { return }
        selectSidebarItem(.installed)
    }

    public func selectSidebarItem(_ item: SidebarItem?, sendToManager: Bool = true) {
        guard let item, sendToManager else {
            Task { @MainActor in
                self.selectedSidebarItem = item
            }
            return
        }
        let targetId = SidebarItemSourceListRegistry.id(for: item)
        guard selectionManager.firstSelectedId != targetId || selectedSidebarItem != item else { return }
        Task { @MainActor in
            self.isSyncingSelection = true
            self.selectedSidebarItem = item
            if self.selectionManager.firstSelectedId != targetId {
                self.selectionManager.selectItem(targetId)
            }
            self.isSyncingSelection = false
        }
    }

    public var selectedSidebarItemBinding: Binding<SidebarItem?> {
        Binding(
            get: { self.selectedSidebarItem },
            set: { self.selectSidebarItem($0) }
        )
    }

    /// `BrewManager` の一覧件数を S2J Source List の `badge` に反映する（Warnings はカスタム行のまま）。
    func syncSidebarBadges(counts: BrewManager.SidebarBadgeCounts) {
        let countByItem: [SidebarItem: Int] = [
            .installed: counts.installed,
            .outdated: counts.outdated,
            .taps: counts.taps,
            .formulae: counts.formulae,
            .casks: counts.casks,
        ]
        for item in sidebarItemsWithCountBadge {
            guard let count = countByItem[item],
                  let found = service.findItem(id: SidebarItemSourceListRegistry.id(for: item))
            else { continue }
            var updated = found.item
            let nextBadge = "\(count)"
            guard updated.badge != nextBadge else { continue }
            updated.badge = nextBadge
            service.updateItem(updated)
        }
    }

    func warningsRowContent(item: SourceItem, warningCount: Int, isSelected: Bool) -> AnyView {
        AnyView(
            HStack {
                Text(item.title)
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                if warningCount > 0 {
                    Text("\(warningCount)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(isSelected ? 0.45 : 0.25))
                        .foregroundColor(.orange)
                        .clipShape(Capsule())
                }
            }
        )
    }

    func defaultRowContent(item: SourceItem, isSelected: Bool) -> AnyView {
        AnyView(
            Text(item.title)
                .foregroundColor(isSelected ? .white : .primary)
                .lineLimit(1)
        )
    }
}

/// S2J Source List ベースのメイン・ウィンドウ用サイドバー。
struct CozyBrewSourceListSidebar: View {
    @ObservedObject var adapter: S2JSourceListAdapter
    @ObservedObject var manager: BrewManager

    var body: some View {
        S2JSourceList.SidebarView(
            service: adapter.service,
            selectionManager: adapter.selectionManager,
            showsSearchBar: false,
            customRowContent: { item in
                let isSelected = adapter.selectionManager.isSelected(item.id)
                guard SidebarItemSourceListRegistry.sidebarItem(for: item.id) == .warnings else {
                    return adapter.defaultRowContent(item: item, isSelected: isSelected)
                }
                return adapter.warningsRowContent(
                    item: item,
                    warningCount: manager.doctorWarningCount,
                    isSelected: isSelected
                )
            }
        )
        .navigationTitle(CozyBrewL10n.navigationTitle)
        .onAppear {
            adapter.applyInitialSelectionIfNeeded()
            adapter.syncSidebarBadges(counts: manager.sidebarBadgeCounts)
        }
        .onChange(of: manager.sidebarBadgeCounts) { _, counts in
            adapter.syncSidebarBadges(counts: counts)
        }
    }
}
