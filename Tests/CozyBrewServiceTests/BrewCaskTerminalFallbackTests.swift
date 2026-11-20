@testable import CozyBrewService
import XCTest

final class BrewCaskTerminalFallbackTests: XCTestCase {
    func testUpgradeShellCommand_usesAbsoluteBrewPathWhenProvided() {
        let package = Package(
            id: "temurin",
            name: "temurin",
            fullName: "temurin",
            type: .cask,
            desc: nil,
            homepage: nil,
            isInstalled: true,
            isOutdated: true
        )
        let command = BrewCaskTerminalFallback.upgradeShellCommand(
            for: package,
            brewBinaryPath: "/opt/homebrew/bin/brew"
        )
        XCTAssertEqual(command, "/opt/homebrew/bin/brew upgrade --yes --cask temurin")
    }

    func testSuggestsTerminalFallback_whenSudoTTYError() {
        let stderr = "sudo: a terminal is required to read the password"
        XCTAssertTrue(BrewCaskTerminalFallback.suggestsTerminalFallback(stderr: stderr, packageType: .cask))
        XCTAssertFalse(BrewCaskTerminalFallback.suggestsTerminalFallback(stderr: stderr, packageType: .formula))
    }

    func testSuggestsTerminalFallback_negativeForUnrelatedFormula() {
        XCTAssertFalse(
            BrewCaskTerminalFallback.suggestsTerminalFallback(stderr: "network error", packageType: .formula)
        )
    }
}
