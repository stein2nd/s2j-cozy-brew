@testable import CozyBrewService
import XCTest

final class FormulaeAPIDecodeTests: XCTestCase {
    func testDecodeLiveFormulaCatalogSubset() throws {
        let url = try XCTUnwrap(URL(string: "https://formulae.brew.sh/api/formula.json"))
        let data = try Data(contentsOf: url)
        let packages = try BrewCatalogAPIParsing.packagesFromFormulaCatalog(data)
        XCTAssertGreaterThan(packages.count, 5000)
        let aPage = BrewCatalog.partitionByPage(packages)[.aThroughE] ?? []
        XCTAssertGreaterThan(aPage.count, 100)
        for package in aPage.prefix(20) {
            XCTAssertFalse(package.name.isEmpty)
        }
    }
}
