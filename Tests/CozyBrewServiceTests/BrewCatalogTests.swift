@testable import CozyBrewService
import XCTest

final class BrewCatalogTests: XCTestCase {
    func testOverlayLocalInstalledMergesInstallState() {
        let catalog = [
            Package(
                id: "wget",
                name: "wget",
                fullName: "wget",
                type: .formula,
                desc: "Download files",
                version: "1.26.0",
                isInstalled: false
            ),
            Package.catalogStub(name: "curl", type: .formula),
        ]
        let installed = Package(
            id: "wget",
            name: "wget",
            fullName: "wget",
            type: .formula,
            version: "1.25.0",
            installedVersion: "1.25.0",
            isInstalled: true
        )

        let merged = BrewCatalog.overlayLocalInstalled(catalog, installed: [installed], type: .formula)
        let wget = merged.first { $0.name == "wget" }
        XCTAssertEqual(wget?.isInstalled, true)
        XCTAssertEqual(wget?.installedVersion, "1.25.0")
        XCTAssertEqual(wget?.desc, "Download files")
        XCTAssertEqual(wget?.version, "1.26.0")
    }

    func testCatalogPageRangeLetters() {
        let curl = Package.catalogStub(name: "curl", type: .formula)
        XCTAssertTrue(CatalogPageRange.aThroughE.matches(curl))
        XCTAssertFalse(CatalogPageRange.fThroughJ.matches(curl))
    }

    func testCatalogPageRangeDigitsAndLeadingSymbol() {
        let zeroAd = Package.catalogStub(name: "0-ad", type: .cask)
        XCTAssertTrue(CatalogPageRange.sixThroughZero.matches(zeroAd))
        let three = Package.catalogStub(name: "3dgenceslicer", type: .cask)
        XCTAssertTrue(CatalogPageRange.oneThroughFive.matches(three))
    }

    func testSortedByName() {
        let packages = [
            Package.catalogStub(name: "zz", type: .formula),
            Package.catalogStub(name: "aa", type: .formula),
        ]
        let sorted = BrewCatalog.sortedByName(packages)
        XCTAssertEqual(sorted.map(\.name), ["aa", "zz"])
    }
}
