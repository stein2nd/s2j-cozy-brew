import CozyBrewService
import SwiftUI

/// パッケージ一覧の行ビュー
public struct PackageRowView: View {
    let package: Package
    let brewServiceStatus: String?
    let onInstall: (() -> Void)?
    let onUninstall: (() -> Void)?
    let onUpgrade: (() -> Void)?

    public init(
        package: Package,
        brewServiceStatus: String? = nil,
        onInstall: (() -> Void)? = nil,
        onUninstall: (() -> Void)? = nil,
        onUpgrade: (() -> Void)? = nil
    ) {
        self.package = package
        self.brewServiceStatus = brewServiceStatus
        self.onInstall = onInstall
        self.onUninstall = onUninstall
        self.onUpgrade = onUpgrade
    }

    public var body: some View {
        let displayName = String(package.name)
        let displayDesc = package.desc.map { String($0) }
        let displayInstalledVersion = package.installedVersion.map { String($0) }
        let displayVersion = package.version.map { String($0) }
        let displayLatest = (package.upgradeTargetVersion ?? package.version).map { String($0) }
        let displayServiceStatus = brewServiceStatus.map { String($0) }

        HStack {
            // アイコン (将来実装)
            Image(systemName: package.type == .formula ? "cube.box" : "app.badge")
                .foregroundColor(package.type == .formula ? .blue : .green)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(verbatim: displayName)
                        .font(.headline)

                    if package.isOutdated {
                        Text(CozyBrewL10n.badgeUpdateAvailable)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }

                    if package.isDeprecated {
                        Text(CozyBrewL10n.badgeDeprecated)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(4)
                    }

                    if let displayServiceStatus {
                        Text(verbatim: "Service · \(displayServiceStatus)")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.15))
                            .foregroundColor(.purple)
                            .cornerRadius(4)
                    }
                }

                if let displayDesc {
                    Text(verbatim: displayDesc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                HStack(spacing: 8) {
                    if package.isOutdated,
                       let installed = displayInstalledVersion,
                       let latest = displayLatest
                    {
                        Text(verbatim: "v\(installed) → v\(latest)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else if let version = displayInstalledVersion ?? displayVersion {
                        Text(verbatim: "v\(version)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Text(package.type == .formula ? CozyBrewL10n.typeFormula : CozyBrewL10n.typeCask)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // アクションボタン
            HStack(spacing: 8) {
                if package.isInstalled {
                    if package.isOutdated, let onUpgrade {
                        Button(CozyBrewL10n.actionUpgrade, action: onUpgrade)
                            .accessibilityLabel(CozyBrewL10n.actionUpgrade)
                            .buttonStyle(.borderedProminent)
                    }

                    if let onUninstall {
                        Button(CozyBrewL10n.actionUninstall, action: onUninstall)
                            .accessibilityLabel(CozyBrewL10n.actionUninstall)
                            .buttonStyle(.bordered)
                    }
                } else {
                    if let onInstall {
                        Button(CozyBrewL10n.actionInstall, action: onInstall)
                            .accessibilityLabel(CozyBrewL10n.actionInstall)
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            Text(
                verbatim: CozyBrewL10n.a11yPackageRow(
                    displayName,
                    type: package.type == .formula ? CozyBrewL10n.typeFormula : CozyBrewL10n.typeCask,
                    installed: package.isInstalled
                )
            )
        )
    }
}
