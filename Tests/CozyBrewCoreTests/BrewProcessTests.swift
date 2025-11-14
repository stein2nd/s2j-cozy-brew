import XCTest
@testable import CozyBrewCore

final class BrewProcessTests: XCTestCase {
    func testBrewProcessInitialization() {
        let process = BrewProcess()
        // 初期化が成功することを確認
        XCTAssertNotNil(process)
    }
    
    func testBrewProcessWithCustomPath() {
        // カスタムパスでの初期化テスト
        let customPath = "/usr/local/bin/brew"
        let process = BrewProcess(brewPath: customPath)
        XCTAssertNotNil(process)
    }
    
    func testBrewCommandRun() async throws {
        // brew --version を実行してテスト
        // 注: 実際の brew がインストールされている環境でのみ動作
        let result = try await BrewCommand.run(["--version"])
        
        // brew がインストールされている場合、バージョン情報が返る
        if result.exitCode == 0 {
            XCTAssertFalse(result.stdout.isEmpty)
        }
    }
}
