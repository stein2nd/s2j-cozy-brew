import CozyBrewCore
import CozyBrewService
import XCTest

final class BrewEnvironmentFetcherTests: XCTestCase {
    func testArchitectureLabels() {
        XCTAssertEqual(
            BrewEnvironmentFetcher.architectureLabel(for: .appleSilicon),
            "Apple Silicon"
        )
        XCTAssertEqual(BrewEnvironmentFetcher.architectureLabel(for: .intel), "Intel")
        XCTAssertEqual(
            BrewEnvironmentFetcher.architectureLabel(for: .custom("/tmp/brew")),
            "Custom (/tmp/brew)"
        )
    }

    func testFetchWhenBrewUnavailable() async {
        let process = BrewProcess(brewPath: "/nonexistent/brew")
        let snap = await BrewEnvironmentFetcher.fetch(
            brewProcess: process,
            isBrewAvailable: false,
            operationHistoryPath: "/tmp/history.json",
            cacheDirectoryPath: "/tmp/cache",
            appBundlePath: "/Applications/CozyBrew.app"
        )
        XCTAssertEqual(snap.operationHistoryPath, "/tmp/history.json")
        XCTAssertNil(snap.brewVersionOutput)
        XCTAssertNotNil(snap.fetchErrors["detection"])
    }
}
