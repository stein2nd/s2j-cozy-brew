@testable import CozyBrewService
import XCTest

final class BrewInfoTextParserTests: XCTestCase {
    func testParsePyenvStyleInfo() {
        let sample = """
        ==> pyenv: stable 2.8.15 (bottled), HEAD
        Python version management
        https://github.com/pyenv/pyenv
        Installed (on request)
        From: https://github.com/Homebrew/homebrew-core/blob/HEAD/Formula/p/pyenv.rb
        License: MIT
        ==> Installed Versions
        pyenv 2.8.15 (1,797 files, 9.2MB) [Linked]
        ==> Dependencies
        Required (4): autoconf, openssl@4, pkgconf, readline
        Recursive Runtime (6): all installed ✔
        ==> Options
        --HEAD
        \tInstall HEAD version
        ==> Analytics
        install: 47,573 (30 days), 127,794 (90 days), 720,308 (365 days)
        install-on-request: 47,247 (30 days), 126,875 (90 days), 715,693 (365 days)
        build-error: 5 (30 days)
        """

        let parsed = BrewInfoTextParser.parse(stdout: sample)

        XCTAssertEqual(parsed.installedKegLines.count, 1)
        XCTAssertTrue(parsed.installedKegLines[0].contains("pyenv 2.8.15"))
        XCTAssertEqual(parsed.optionLines.count, 1)
        XCTAssertEqual(parsed.optionLines[0].flag, "--HEAD")
        XCTAssertEqual(parsed.optionLines[0].description, "Install HEAD version")
        XCTAssertEqual(parsed.analyticsLines.count, 3)
    }

    func testVersionSummaryBuilder() {
        let summary = PackageInfoExtrasBuilder.versionSummary(
            from: BrewFormulaVersions(stable: "2.8.15", head: "HEAD", bottle: true)
        )
        XCTAssertEqual(summary, "stable 2.8.15 (bottled), HEAD")
    }
}
