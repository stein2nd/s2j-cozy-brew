import XCTest

/// macOS UI スモーク (ローカル `xcodebuild test` / Xcode)。CI 未組込み ([testing_spec.md](../docs/testing_spec.md))
@MainActor
final class CozyBrewUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchShowsMainWindow() {
        let app = XCUIApplication()
        app.launch()

        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 10))
    }
}
