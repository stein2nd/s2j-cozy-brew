import SwiftUI
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
    }
}
