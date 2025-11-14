import SwiftUI
import CozyBrewService

/// パッケージの詳細ビュー
public struct PackageDetailView: View {
    let package: Package
    let onInstall: (() -> Void)?
    let onUninstall: (() -> Void)?
    let onUpgrade: (() -> Void)?
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // ヘッダー
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: package.type == .formula ? "cube.box.fill" : "app.badge.fill")
                            .font(.largeTitle)
                            .foregroundColor(package.type == .formula ? .blue : .green)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(package.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text(package.fullName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    // バッジ
                    HStack(spacing: 8) {
                        if package.isOutdated {
                            Label("Update Available", systemImage: "arrow.down.circle.fill")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(6)
                        }
                        
                        if package.isDeprecated {
                            Label("Deprecated", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.2))
                                .foregroundColor(.red)
                                .cornerRadius(6)
                        }
                        
                        Text(package.type == .formula ? "Formula" : "Cask")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.2))
                            .foregroundColor(.secondary)
                            .cornerRadius(6)
                    }
                }
                
                Divider()
                
                // 説明
                if let desc = package.desc {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.headline)
                        Text(desc)
                            .font(.body)
                    }
                }
                
                // バージョン情報
                if let version = package.version {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Version")
                            .font(.headline)
                        Text(version)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                // ホームページ
                if let homepage = package.homepage, let url = URL(string: homepage) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Homepage")
                            .font(.headline)
                        Link(homepage, destination: url)
                    }
                }
                
                // インストール状態
                VStack(alignment: .leading, spacing: 4) {
                    Text("Status")
                        .font(.headline)
                    Text(package.isInstalled ? "Installed" : "Not Installed")
                        .font(.body)
                        .foregroundColor(package.isInstalled ? .green : .secondary)
                }
                
                Divider()
                
                // アクションボタン
                HStack(spacing: 12) {
                    if package.isInstalled {
                        if package.isOutdated, let onUpgrade = onUpgrade {
                        Button(action: {
                            isLoading = true
                            errorMessage = nil
                            onUpgrade()
                            isLoading = false
                        }) {
                            Label("Upgrade", systemImage: "arrow.down.circle")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isLoading)
                    }
                    
                    if let onUninstall = onUninstall {
                        Button(action: {
                            isLoading = true
                            errorMessage = nil
                            onUninstall()
                            isLoading = false
                        }) {
                            Label("Uninstall", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                        .disabled(isLoading)
                    }
                } else {
                    if let onInstall = onInstall {
                        Button(action: {
                            isLoading = true
                            errorMessage = nil
                            onInstall()
                            isLoading = false
                        }) {
                            Label("Install", systemImage: "arrow.down.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isLoading)
                    }
                }
                }
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
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
    }
}
