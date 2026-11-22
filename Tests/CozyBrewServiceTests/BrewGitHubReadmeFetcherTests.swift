@testable import CozyBrewService
import XCTest

final class BrewGitHubReadmeFetcherTests: XCTestCase {
    func testParsesGitHubHomepage() {
        let reference = GitHubRepositoryReference.parse(homepage: "https://github.com/Homebrew/brew")
        XCTAssertEqual(reference?.owner, "Homebrew")
        XCTAssertEqual(reference?.name, "brew")
        XCTAssertEqual(reference?.branch, "HEAD")
    }

    func testRejectsNonGitHubHomepage() {
        XCTAssertNil(GitHubRepositoryReference.parse(homepage: "https://example.com"))
    }
}
