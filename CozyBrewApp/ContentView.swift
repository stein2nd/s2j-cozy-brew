import SwiftUI
import AppKit
import CozyBrewService
import CozyBrewUIComponents

/// メインコンテンツビュー
struct ContentView: View {
    @ObservedObject var manager: BrewManager
    @Binding var showAboutWindow: Bool
    
    var body: some View {
        Group {
            if manager.isBrewAvailable {
                MainWindowView(manager: manager)
            } else {
                BrewNotAvailableView(manager: manager)
            }
        }
        .sheet(isPresented: $showAboutWindow) {
            // S2J About Window を表示
            // 注: S2JAboutWindow の実際の API に合わせて調整が必要
            AboutWindowView()
        }
        .onAppear {
            // ウィンドウサイズを設定し、前面に表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if let window = NSApplication.shared.windows.first {
                    window.setContentSize(NSSize(width: 1000, height: 700))
                    window.center()
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
            }
        }
    }
}
