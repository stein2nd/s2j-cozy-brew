@testable import CozyBrewService
import XCTest

/// 実 brew なしで Service 層の連鎖を検証する統合テスト (CI 対象)
final class BrewServiceIntegrationTests: XCTestCase {
    func testCatalogOverlayAndPagingIntegration() {
        let catalog = [
            Package(
                id: "aria2",
                name: "aria2",
                fullName: "aria2",
                type: .formula,
                desc: "Download accelerator",
                version: "1.37.0",
                isInstalled: false
            ),
            Package.catalogStub(name: "curl", type: .formula),
        ]
        let installed = Package(
            id: "aria2",
            name: "aria2",
            fullName: "aria2",
            type: .formula,
            version: "1.36.0",
            installedVersion: "1.36.0",
            isInstalled: true
        )

        let merged = BrewCatalog.overlayLocalInstalled(catalog, installed: [installed], type: .formula)
        let sorted = BrewCatalog.sortedByName(merged)
        let page = sorted.filter { CatalogPageRange.aThroughE.matches($0) }

        XCTAssertEqual(page.count, 2)
        XCTAssertEqual(page.first(where: { $0.name == "aria2" })?.isInstalled, true)
    }

    func testCaskFailureInterpretationIntegration() {
        let stderr = "Error: Download failed: Need sudo or terminal"
        XCTAssertTrue(
            BrewCaskTerminalFallback.suggestsTerminalFallback(
                stderr: stderr,
                packageType: .cask
            )
        )
        let friendly = BrewUserMessage.upgradeFailure(from: stderr, packageType: .cask)
        XCTAssertFalse(friendly.isEmpty)
    }

    func testDoctorParserProducesWarningBlocks() {
        let sample = """
        Warning: Unbrewed header files were found in /usr/local/include
        If you didn't put them there on purpose they could cause problems when
        building Homebrew formulae and Ruby gems.
        """
        let parsed = BrewDoctorParser.parse(sample)
        XCTAssertFalse(parsed.warnings.isEmpty)
        XCTAssertTrue(parsed.warnings[0].title.contains("Unbrewed"))
    }
}
