@testable import CozyBrewService
import XCTest

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

        let data = try XCTUnwrap(json.data(using: .utf8))
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

        let data = try XCTUnwrap(json.data(using: .utf8))
        let cask = try JSONDecoder().decode(Cask.self, from: data)

        XCTAssertEqual(cask.token, "test-cask")
        XCTAssertEqual(cask.name, "Test Cask")
        XCTAssertEqual(cask.fullName, "test-cask")
        XCTAssertEqual(cask.desc, "Test cask description")
        XCTAssertEqual(cask.version, "1.0.0")
        XCTAssertNotNil(cask.installed)
        XCTAssertEqual(cask.installed?.count, 1)
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

    func testPackageEnrichedWithInfo() {
        let listPackage = Package(
            id: "aspell",
            name: "aspell",
            fullName: "aspell",
            type: .formula,
            installedVersion: "0.60.8.3",
            isInstalled: true,
            isOutdated: true
        )
        let infoPackage = Package(
            id: "aspell",
            name: "aspell",
            fullName: "aspell",
            type: .formula,
            desc: "Spell checker with better logic than ispell",
            homepage: "http://aspell.net/",
            version: "0.60.8.3_1",
            isInstalled: true,
            isOutdated: true,
            dependencies: ["libarchive"],
            buildDependencies: ["pkg-config"]
        )

        let merged = listPackage.enriched(
            with: infoPackage,
            dependencies: ["libarchive"],
            buildDependencies: ["pkg-config"]
        )

        XCTAssertEqual(merged.desc, infoPackage.desc)
        XCTAssertEqual(merged.homepage, infoPackage.homepage)
        XCTAssertEqual(merged.installedVersion, "0.60.8.3")
        XCTAssertEqual(merged.version, "0.60.8.3_1")
        XCTAssertEqual(merged.dependencies, ["libarchive"])
    }

    func testParseTapsFromPlainList() {
        let taps = BrewTapParsing.parsePlainList("homebrew/core\nsdkman/tap\n")
        XCTAssertEqual(taps.count, 2)
        XCTAssertEqual(taps[0].name, "homebrew/core")
        XCTAssertEqual(taps[1].user, "sdkman")
    }

    func testCaskEmptyUpgradeFailureMentionsAppManagement() {
        let message = BrewUserMessage.upgradeFailure(from: "", packageType: .cask)
        XCTAssertTrue(message.contains("App Management"))
    }

    func testCaskUpgradeFailureMessage() {
        let message = BrewUserMessage.upgradeFailure(
            from: "sudo: a password is required",
            packageType: .formula
        )
        XCTAssertTrue(message.contains("administrator"))
        XCTAssertTrue(message.contains("password"))
    }

    func testPackageMatchesSearch() {
        let pkg = Package(
            id: "cursor",
            name: "cursor",
            fullName: "cursor",
            type: .cask,
            desc: "AI editor",
            isInstalled: true
        )
        XCTAssertTrue(PackageListFilter.matches(pkg, query: "cur"))
        XCTAssertTrue(PackageListFilter.matches(pkg, query: "CUR"))
        XCTAssertFalse(PackageListFilter.matches(pkg, query: "xyz"))
    }

    func testAnnotatingOutdatedStatusLogic() {
        let installed = Package(
            id: "httpd",
            name: "httpd",
            fullName: "httpd",
            type: .formula,
            version: "2.4.69_1",
            installedVersion: "2.4.69_1",
            isInstalled: true,
            isOutdated: false
        )
        let outdated = Package(
            id: "httpd",
            name: "httpd",
            fullName: "httpd",
            type: .formula,
            version: "2.4.70",
            installedVersion: "2.4.69_1",
            isInstalled: true,
            isOutdated: true
        )

        let merged = installed.withListPresentation(from: outdated, isOutdated: true)

        XCTAssertTrue(merged.isOutdated)
        XCTAssertEqual(merged.upgradeTargetVersion, "2.4.70")
    }

    func testWithListPresentationClearsOutdatedState() {
        let detail = Package(
            id: "aspell",
            name: "aspell",
            fullName: "aspell",
            type: .formula,
            desc: "Spell checker",
            version: "0.60.8.3",
            installedVersion: "0.60.8.3_1",
            isInstalled: true,
            isOutdated: true,
            license: "LGPL-2.1-only"
        )
        let installedList = Package(
            id: "aspell",
            name: "aspell",
            fullName: "aspell",
            type: .formula,
            version: "0.60.8.3_1",
            installedVersion: "0.60.8.3_1",
            isInstalled: true,
            isOutdated: false
        )

        let updated = detail.withListPresentation(from: installedList, isOutdated: false)

        XCTAssertFalse(updated.isOutdated)
        XCTAssertEqual(updated.installedVersion, "0.60.8.3_1")
        XCTAssertEqual(updated.version, "0.60.8.3_1")
    }

    func testEnrichedKeepsOutdatedTargetVersion() {
        let outdatedList = Package(
            id: "aspell",
            name: "aspell",
            fullName: "aspell",
            type: .formula,
            version: "0.60.8.3_1",
            installedVersion: "0.60.8.3",
            isInstalled: true,
            isOutdated: true
        )
        let fromInfo = Package(
            id: "aspell",
            name: "aspell",
            fullName: "aspell",
            type: .formula,
            desc: "Spell checker",
            version: "0.60.8.3",
            installedVersion: "0.60.8.3",
            isInstalled: true,
            isOutdated: true
        )

        let merged = outdatedList.enriched(with: fromInfo)

        XCTAssertEqual(merged.version, "0.60.8.3_1")
        XCTAssertEqual(merged.upgradeTargetVersion, "0.60.8.3_1")
    }

    func testBrewInfoJSONFormulaDecoding() throws {
        let json = """
        {
            "formulae": [
                {
                    "name": "aspell",
                    "full_name": "aspell",
                    "desc": "Spell checker with better logic than ispell",
                    "homepage": "http://aspell.net/",
                    "license": "LGPL-2.1-only",
                    "tap": "homebrew/core",
                    "ruby_source_path": "Formula/a/aspell.rb",
                    "versions": {
                        "stable": "0.60.8.3_1",
                        "head": null,
                        "bottle": true
                    },
                    "installed": [
                        {
                            "version": "0.60.8.3",
                            "installed_on_request": true
                        }
                    ],
                    "outdated": true
                }
            ]
        }
        """
        let response = try JSONDecoder().decode(BrewInfoResponse.self, from: Data(json.utf8))
        let formula = try XCTUnwrap(response.formulae?.first)
        let package = Package.from(formula)

        XCTAssertEqual(formula.desc, "Spell checker with better logic than ispell")
        XCTAssertEqual(formula.version, "0.60.8.3_1")
        XCTAssertEqual(package.license, "LGPL-2.1-only")
        XCTAssertEqual(
            package.formulaSourceURL,
            "https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/a/aspell.rb"
        )
        XCTAssertEqual(package.installationKindLabel, "Installed (on request)")
        XCTAssertTrue(package.isInstalled)
    }

    func testOutdatedJSONFormulaDecoding() throws {
        let json = """
        {
            "name": "aspell",
            "installed_versions": ["0.60.8.3"],
            "current_version": "0.60.8.3_1",
            "pinned": false,
            "pinned_version": null
        }
        """
        let formula = try JSONDecoder().decode(Formula.self, from: Data(json.utf8))
        let package = Package.from(formula)

        XCTAssertEqual(formula.version, "0.60.8.3_1")
        XCTAssertEqual(formula.installed?.first?.version, "0.60.8.3")
        XCTAssertEqual(formula.outdated, true)
        XCTAssertTrue(package.isInstalled)
        XCTAssertTrue(package.isOutdated)
        XCTAssertEqual(package.installedVersion, "0.60.8.3")
    }

    func testBrewManagedServiceDecoding() throws {
        let json = """
        {
            "name": "httpd",
            "status": "started",
            "user": "stein",
            "file": "/Users/stein/Library/LaunchAgents/sh.brew.httpd.plist",
            "exit_code": null
        }
        """
        let service = try JSONDecoder().decode(BrewManagedService.self, from: Data(json.utf8))
        XCTAssertEqual(service.name, "httpd")
        XCTAssertEqual(service.status, "started")
        XCTAssertTrue(service.shouldStopBeforeUpgrade)
    }

    func testBrewInstalledVersionsResponseDecodingAndConversion() throws {
        let json = """
        {
            "formulae": [
                {
                    "name": "wget",
                    "versions": ["1.25.0"],
                    "linked_version": "1.25.0",
                    "optlinked_version": "1.25.0",
                    "pinned_version": null
                }
            ],
            "casks": [
                {
                    "token": "cursor",
                    "versions": ["2.0.0"],
                    "pinned_version": null
                }
            ]
        }
        """

        let data = try XCTUnwrap(json.data(using: .utf8))
        let response = try JSONDecoder().decode(BrewInstalledVersionsResponse.self, from: data)
        let list = response.asBrewListResponse()

        XCTAssertEqual(response.formulae.count, 1)
        XCTAssertEqual(response.casks.count, 1)
        XCTAssertEqual(list.formulae?.first?.name, "wget")
        XCTAssertEqual(list.casks?.first?.token, "cursor")
        XCTAssertEqual(try Package.from(XCTUnwrap(list.formulae?.first)).isInstalled, true)
        XCTAssertEqual(try Package.from(XCTUnwrap(list.casks?.first)).name, "cursor")
    }
}
