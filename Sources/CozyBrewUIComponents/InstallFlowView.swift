import SwiftUI
import CozyBrewService

/// インストールフロービュー
public struct InstallFlowView: View {
    let package: Package
    let onConfirm: () async throws -> Void
    let onCancel: () -> Void
    
    @State private var isInstalling = false
    @State private var logOutput = ""
    @State private var errorMessage: String?
    @State private var showError = false
    
    public init(
        package: Package,
        onConfirm: @escaping () async throws -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.package = package
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isInstalling {
                InstallProgressView(
                    title: "Installing \(package.name)...",
                    logOutput: logOutput,
                    onCancel: {
                        // キャンセル処理（将来実装）
                        onCancel()
                    },
                    isCancellable: false
                )
            } else if let errorMessage = errorMessage {
                BrewAlertView(
                    title: "Installation Failed",
                    message: errorMessage,
                    rawLog: logOutput,
                    onDismiss: {
                        self.errorMessage = nil
                        onCancel()
                    }
                )
            } else {
                // 確認ダイアログ
                VStack(alignment: .leading, spacing: 12) {
                    Text("Install \(package.name)?")
                        .font(.headline)
                    
                    if let desc = package.desc {
                        Text(desc)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Type:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(package.type == .formula ? "Formula" : "Cask")
                            .font(.caption)
                    }
                    
                    if let version = package.version {
                        HStack {
                            Text("Version:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(version)
                                .font(.caption)
                        }
                    }
                }
                .padding()
                
                HStack {
                    Spacer()
                    Button("Cancel", action: onCancel)
                        .buttonStyle(.bordered)
                    Button("Install", action: {
                        Task {
                            await performInstall()
                        }
                    })
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .frame(minWidth: 400, minHeight: 200)
    }
    
    private func performInstall() async {
        isInstalling = true
        errorMessage = nil
        logOutput = ""
        
        do {
            try await onConfirm()
            // インストール成功
            isInstalling = false
            onCancel() // ダイアログを閉じる
        } catch {
            errorMessage = error.localizedDescription
            isInstalling = false
        }
    }
}
