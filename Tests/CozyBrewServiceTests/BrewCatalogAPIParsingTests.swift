@testable import CozyBrewService
import XCTest

final class BrewCatalogAPIParsingTests: XCTestCase {
    func testAnyToStringCoercesNSNumber() {
        XCTAssertEqual(BrewCatalogAPIParsing.anyToString(NSNumber(value: 42)), "42")
    }

    func testParseFormulaRowWithNumericStableVersion() throws {
        let json = """
        [{"name":"foo","full_name":"foo","desc":"d","versions":{"stable":12.5},"deprecated":false}]
        """
        let packages = try BrewCatalogAPIParsing.packagesFromFormulaCatalog(Data(json.utf8))
        XCTAssertEqual(packages.count, 1)
        XCTAssertEqual(packages[0].name, "foo")
        XCTAssertEqual(packages[0].version, "12.5")
    }

    func testParseLiveFormulaCatalogSubset() throws {
        let url = try XCTUnwrap(URL(string: "https://formulae.brew.sh/api/formula.json"))
        let data = try Data(contentsOf: url)
        let packages = try BrewCatalogAPIParsing.packagesFromFormulaCatalog(data)
        XCTAssertGreaterThan(packages.count, 5000)
        let aPage = BrewCatalog.partitionByPage(packages)[.aThroughE] ?? []
        XCTAssertGreaterThan(aPage.count, 100)
        for package in aPage.prefix(20) {
            XCTAssertFalse(package.name.isEmpty)
            XCTAssertTrue(
                package.name.allSatisfy {
                    $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" || $0 == "@" || $0 == "+"
                }
            )
        }
    }
}
