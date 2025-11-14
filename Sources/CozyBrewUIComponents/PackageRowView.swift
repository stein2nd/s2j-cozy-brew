import SwiftUI
import CozyBrewService

/// パッケージ一覧の行ビュー
public struct PackageRowView: View {
    let package: Package
    let onInstall: (() -> Void)?
    let onUninstall: (() -> Void)?
    let onUpgrade: (() -> Void)?
    
    public init(
        package: Package,
        onInstall: (() -> Void)? = nil,
        onUninstall: (() -> Void)? = nil,
        onUpgrade: (() -> Void)? = nil
    ) {
        self.package = package
        self.onInstall = onInstall
        self.onUninstall = onUninstall
        self.onUpgrade = onUpgrade
    }
    
    public var body: some View {
        HStack {
            // アイコン（将来実装）
            Image(systemName: package.type == .formula ? "cube.box" : "app.badge")
                .foregroundColor(package.type == .formula ? .blue : .green)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(package.name)
                        .font(.headline)
                    
                    if package.isOutdated {
                        Text("Update Available")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                    
                    if package.isDeprecated {
                        Text("Deprecated")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(4)
                    }
                }
                
                if let desc = package.desc {
                    Text(desc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 8) {
                    if let version = package.version {
                        Text("v\(version)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(package.type == .formula ? "Formula" : "Cask")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // アクションボタン
            HStack(spacing: 8) {
                if package.isInstalled {
                    if package.isOutdated, let onUpgrade = onUpgrade {
                        Button("Upgrade", action: onUpgrade)
                            .buttonStyle(.borderedProminent)
                    }
                    
                    if let onUninstall = onUninstall {
                        Button("Uninstall", action: onUninstall)
                            .buttonStyle(.bordered)
                    }
                } else {
                    if let onInstall = onInstall {
                        Button("Install", action: onInstall)
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(package.name), \(package.type == .formula ? "Formula" : "Cask")")
    }
}
