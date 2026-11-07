@testable import CozyBrewService
import XCTest

final class BrewDoctorParserTests: XCTestCase {
    func testParseUserSampleWarnings() throws {
        let sample = """
        Please note that these warnings are just used to help the Homebrew maintainers
        with debugging if you file an issue. If everything you use Homebrew for is
        working fine: please don't worry or file an issue; just ignore this. Thanks!

        Warning: Some installed casks are deprecated or disabled.
        You should find replacements for the following casks:

          fontforge-app

        Warning: Some installed kegs have no formulae!
        This means they were either deleted or installed manually.


        You should find replacements for the following formulae:

          six

        Warning: Some installed formulae are deprecated or disabled.
        You should find replacements for the following formulae:

          icu4c@77
          icu4c@78
          pcre
        """

        let parsed = BrewDoctorParser.parse(sample)

        XCTAssertNotNil(parsed.preamble)
        XCTAssertTrue(try XCTUnwrap(parsed.preamble?.contains("Please note that these warnings")))

        XCTAssertEqual(parsed.warnings.count, 3)

        XCTAssertEqual(parsed.warnings[0].title, "Some installed casks are deprecated or disabled.")
        XCTAssertEqual(parsed.warnings[0].items, ["fontforge-app"])

        XCTAssertEqual(parsed.warnings[1].title, "Some installed kegs have no formulae!")
        XCTAssertTrue(parsed.warnings[1].bodyLines.contains(where: { $0.contains("deleted or installed manually") }))
        XCTAssertEqual(parsed.warnings[1].items, ["six"])

        XCTAssertEqual(parsed.warnings[2].title, "Some installed formulae are deprecated or disabled.")
        XCTAssertEqual(parsed.warnings[2].items, ["icu4c@77", "icu4c@78", "pcre"])
    }

    func testParseReadyToBrewHasNoWarnings() {
        let text = "Your system is ready to brew."
        let parsed = BrewDoctorParser.parse(text)
        XCTAssertTrue(parsed.warnings.isEmpty)
        XCTAssertEqual(parsed.preamble, "Your system is ready to brew.")
    }
}
