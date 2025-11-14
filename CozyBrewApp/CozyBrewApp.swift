import SwiftUI
import CozyBrewService
import CozyBrewUIComponents
import CozyBrewCore
import S2JAboutWindow

@main
struct CozyBrewApp: App {
    @StateObject private var manager = BrewManager()
    @State private var showAboutWindow = false
    
    var body: some Scene {
        WindowGroup {
            ContentView(manager: manager, showAboutWindow: $showAboutWindow)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About CozyBrew") {
                    showAboutWindow = true
                }
            }
        }
    }
}

/// Homebrew が利用できない場合のビュー
struct BrewNotAvailableView: View {
    @ObservedObject var manager: BrewManager
    @State private var isInstalling = false
    @State private var installLog = ""
    @State private var showInstallError = false
    @State private var installError: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64))
                .foregroundColor(.orange)
            
            Text("Homebrew Not Found")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Homebrew is required to use CozyBrew. Please install Homebrew to continue.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Installation Instructions:")
                    .font(.headline)
                
                Text("1. Open Terminal")
                Text("2. Run the installation command:")
                    .padding(.top, 4)
                
                Text("/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"")
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .textSelection(.enabled)
            }
            .padding()
            .frame(maxWidth: 500)
            
            if isInstalling {
                InstallProgressView(
                    title: "Installing Homebrew...",
                    logOutput: installLog,
                    isCancellable: false
                )
                .frame(maxWidth: 500, maxHeight: 300)
            } else {
                Button("Install Homebrew Automatically") {
                    Task {
                        await installHomebrew()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            
            if showInstallError, let error = installError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: 500)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func installHomebrew() async {
        isInstalling = true
        installError = nil
        showInstallError = false
        installLog = ""
        
        do {
            let result = try await BrewInstaller.install { logLine in
                installLog += logLine + "\n"
            }
            
            if result.isSuccess {
                // インストール成功 - 再検出して再初期化
                // 注: 実際のアプリでは再起動を推奨する場合がある
                if let located = BrewBinaryLocator.locate() {
                    // Manager を再初期化（実際の実装では再起動が必要な場合がある）
                    // ここでは簡易的に再検出のみ行う
                    await manager.refreshInstalledPackages()
                }
            } else {
                installError = result.errorMessage
                showInstallError = true
            }
        } catch {
            installError = error.localizedDescription
            showInstallError = true
        }
        
        isInstalling = false
    }
}

/// About Window View（S2JAboutWindow のプレースホルダー）
struct AboutWindowView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            Text("CozyBrew")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("A modern SwiftUI app for managing Homebrew packages")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Text("Version 1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Link("GitHub Repository", destination: URL(string: "https://github.com/stein2nd/s2j-cozy-brew")!)
                Link("License", destination: URL(string: "https://github.com/stein2nd/s2j-cozy-brew/blob/main/LICENSE")!)
            }
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 400)
    }
}
