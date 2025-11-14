import Foundation

/// brew コマンド実行結果
public struct BrewResult {
    public let stdout: String
    public let stderr: String
    public let exitCode: Int32
    
    public init(stdout: String, stderr: String, exitCode: Int32) {
        self.stdout = stdout
        self.stderr = stderr
        self.exitCode = exitCode
    }
    
    /// 実行が成功したかどうか
    public var isSuccess: Bool {
        exitCode == 0
    }
    
    /// エラーメッセージ（stderr が空の場合は stdout から取得）
    public var errorMessage: String {
        if !stderr.isEmpty {
            return stderr
        }
        return stdout
    }
}
