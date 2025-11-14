import SwiftUI
import CozyBrewService
import CozyBrewUIComponents

/// メインコンテンツビュー（将来の拡張用）
struct ContentView: View {
    @StateObject private var manager = BrewManager()
    
    var body: some View {
        MainWindowView(manager: manager)
    }
}
