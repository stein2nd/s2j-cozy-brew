import AppKit
import Combine
import S2JAboutWindow

/// メニュー About → タイトルバー付き `NSWindow`（S2J About Window）
@MainActor
final class CozyBrewAboutPresenter: ObservableObject {
    private let aboutWindow = AboutWindow()

    func show() {
        aboutWindow.showAboutWindow(
            content: CozyBrewAbout.markdown,
            appName: "CozyBrew",
            licenseResourceName: CozyBrewAbout.licenseResourceName,
            acknowledgementsResourceName: CozyBrewAbout.acknowledgementsResourceName,
            resourceBundle: .main
        )
    }
}
