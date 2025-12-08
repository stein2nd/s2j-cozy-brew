import SwiftUI
import AppKit
import CozyBrewService
import CozyBrewUIComponents
import CozyBrewCore
import S2JAboutWindow

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // アプリ起動時にウィンドウを前面に表示
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // 少し遅延させてウィンドウを確実に前面に表示
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = NSApplication.shared.windows.first {
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Dockアイコンをクリックしたときにウィンドウを表示
        if !flag {
            for window in sender.windows {
                window.makeKeyAndOrderFront(nil)
            }
        }
        return true
    }
}

@main
struct CozyBrewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var manager = BrewManager()
    @State private var showAboutWindow = false

    var body: some Scene {
        WindowGroup {
            ContentView(manager: manager, showAboutWindow: $showAboutWindow)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.automatic)
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
                if BrewBinaryLocator.locate() != nil {
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
