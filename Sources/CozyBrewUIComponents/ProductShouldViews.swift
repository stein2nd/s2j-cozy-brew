import CozyBrewService
import SwiftUI

/// 操作履歴一覧
struct OperationHistoryView: View {
    @ObservedObject var manager: BrewManager
    let searchText: String

    private var filteredRecords: [BrewOperationRecord] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return manager.operationHistory }
        return manager.operationHistory.filter {
            $0.title.localizedCaseInsensitiveContains(needle)
                || ($0.detail?.localizedCaseInsensitiveContains(needle) ?? false)
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        Group {
            if filteredRecords.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? CozyBrewL10n.historyEmpty : CozyBrewL10n.historyNoMatches)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredRecords) { record in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(record.title)
                                .font(.headline)
                            Spacer()
                            Text(record.kind.localizedLabel)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text(Self.dateFormatter.string(from: record.date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let detail = record.detail, !detail.isEmpty {
                            Text(detail)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Cakebrew 設定検出時のオプション移行シート
struct CakebrewMigrationSheet: View {
    let legacy: CakebrewLegacyPreferences
    @ObservedObject var manager: BrewManager
    let onDismiss: () -> Void

    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(CozyBrewL10n.cakebrewMigrationTitle)
                .font(.title2)
                .fontWeight(.semibold)

            Text(CozyBrewL10n.cakebrewMigrationMessage(legacy.shortVersion))
                .foregroundColor(.secondary)

            if !legacy.historyLines.isEmpty {
                Text(CozyBrewL10n.cakebrewMigrationHistoryCount(legacy.historyLines.count))
                    .font(.subheadline)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            HStack {
                Button(CozyBrewL10n.cakebrewMigrationSkip) {
                    manager.skipCakebrewMigration()
                    onDismiss()
                }
                Spacer()
                Button(CozyBrewL10n.cakebrewMigrationImport) {
                    do {
                        try manager.performCakebrewMigration()
                        onDismiss()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(minWidth: 420)
    }
}

private extension BrewOperationRecord.Kind {
    var localizedLabel: String {
        switch self {
        case .install: CozyBrewL10n.historyKindInstall
        case .uninstall: CozyBrewL10n.historyKindUninstall
        case .upgrade: CozyBrewL10n.historyKindUpgrade
        case .upgradeAll: CozyBrewL10n.historyKindUpgradeAll
        case .tap: CozyBrewL10n.historyKindTap
        case .untap: CozyBrewL10n.historyKindUntap
        case .migration: CozyBrewL10n.historyKindMigration
        }
    }
}
