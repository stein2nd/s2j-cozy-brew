import XCTest
@testable import CozyBrewCore

final class BrewBinaryLocatorTests: XCTestCase {
    func testLocate() {
        // brew がインストールされている場合のテスト
        // 注: 実際の環境に依存するため、モック化が必要な場合がある
        let located = BrewBinaryLocator.locate()
        
        // brew がインストールされていない環境では nil が返る可能性がある
        if let located = located {
            XCTAssertFalse(located.path.isEmpty)
            XCTAssertTrue(FileManager.default.fileExists(atPath: located.path))
        }
    }
    
    func testGetHomebrewPrefix() {
        // brew がインストールされている場合のテスト
        if let located = BrewBinaryLocator.locate() {
            let prefix = BrewBinaryLocator.getHomebrewPrefix(brewPath: located.path)
            
            if let prefix = prefix {
                XCTAssertFalse(prefix.isEmpty)
                XCTAssertTrue(FileManager.default.fileExists(atPath: prefix))
            }
        }
    }
}
