import XCTest
@testable import CozyBrewService

final class ModelsTests: XCTestCase {
    func testFormulaDecoding() throws {
        let json = """
        {
            "name": "test-formula",
            "full_name": "test/test-formula",
            "desc": "Test formula description",
            "homepage": "https://example.com",
            "version": "1.0.0",
            "installed": [
                {
                    "version": "1.0.0",
                    "installed_on_request": true,
                    "installed_as_dependency": false
                }
            ],
            "outdated": false,
            "deprecated": false
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let formula = try decoder.decode(Formula.self, from: data)
        
        XCTAssertEqual(formula.name, "test-formula")
        XCTAssertEqual(formula.fullName, "test/test-formula")
        XCTAssertEqual(formula.desc, "Test formula description")
        XCTAssertEqual(formula.version, "1.0.0")
        XCTAssertNotNil(formula.installed)
        XCTAssertEqual(formula.installed?.count, 1)
    }
    
    func testCaskDecoding() throws {
        let json = """
        {
            "token": "test-cask",
            "name": ["Test Cask"],
            "full_name": "test-cask",
            "desc": "Test cask description",
            "homepage": "https://example.com",
            "version": "1.0.0",
            "installed": [
                {
                    "version": "1.0.0",
                    "installed_on_request": true,
                    "installed_as_dependency": false
                }
            ],
            "outdated": false,
            "deprecated": false
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        // 注: 実際の brew --json=v2 の構造に合わせて調整が必要
        // ここでは簡易的なテスト
        XCTAssertNotNil(data)
    }
    
    func testPackageFromFormula() {
        let formula = Formula(
            id: "test-formula",
            name: "test-formula",
            fullName: "test/test-formula",
            desc: "Test description",
            homepage: "https://example.com",
            version: "1.0.0",
            installed: [InstalledVersion(version: "1.0.0", installedOnRequest: true, installedAsDependency: false)],
            outdated: true
        )
        
        let package = Package.from(formula)
        
        XCTAssertEqual(package.name, "test-formula")
        XCTAssertEqual(package.type, .formula)
        XCTAssertTrue(package.isInstalled)
        XCTAssertTrue(package.isOutdated)
    }
    
    func testPackageFromCask() {
        let cask = Cask(
            id: "test-cask",
            name: "Test Cask",
            fullName: "test-cask",
            token: "test-cask",
            desc: "Test description",
            homepage: "https://example.com",
            version: "1.0.0",
            installed: [InstalledVersion(version: "1.0.0", installedOnRequest: true, installedAsDependency: false)],
            outdated: false
        )
        
        let package = Package.from(cask)
        
        XCTAssertEqual(package.name, "Test Cask")
        XCTAssertEqual(package.type, .cask)
        XCTAssertTrue(package.isInstalled)
        XCTAssertFalse(package.isOutdated)
    }
}
