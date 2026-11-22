@testable import CozyBrewService
import XCTest

final class BrewTapInfoTests: XCTestCase {
    func testRemovalSummaryCountsInstalled() {
        let record = BrewTapInfoRecord(
            name: "sdkman/tap",
            formulaNames: ["sdkman/tap/sdkman-cli", "sdkman/tap/other"],
            caskTokens: []
        )
        let installed = [
            Package(
                id: "sdkman-cli",
                name: "sdkman-cli",
                fullName: "sdkman/tap/sdkman-cli",
                type: .formula,
                isInstalled: true
            ),
        ]
        let summary = BrewTapInfo.removalSummary(record: record, installedPackages: installed)
        XCTAssertEqual(summary.formulaCount, 2)
        XCTAssertEqual(summary.caskCount, 0)
        XCTAssertEqual(summary.installedNames, ["sdkman/tap/sdkman-cli"])
    }
}
