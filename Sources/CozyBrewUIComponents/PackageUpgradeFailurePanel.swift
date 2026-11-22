import CozyBrewService
import SwiftUI

/// 一覧・詳細で Upgrade 失敗を、対象行の直下（または操作欄の下）に表示する
struct PackageUpgradeFailurePanel: View {
    let message: String
    let package: Package
    let stderr: String?

    private var showsTerminalFallback: Bool {
        guard let stderr else { return false }
        return BrewCaskTerminalFallback.suggestsTerminalFallback(stderr: stderr, packageType: package.type)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(CozyBrewL10n.upgradeFailed, systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.red)

            if showsTerminalFallback {
                BrewUpgradeTerminalFallbackView(package: package)
            }

            DisclosureGroup {
                ScrollView {
                    Text(message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 140)
            } label: {
                Text(CozyBrewL10n.showDetails)
                    .font(.caption)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.08))
    }
}
