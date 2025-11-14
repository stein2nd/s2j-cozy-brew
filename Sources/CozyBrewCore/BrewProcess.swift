import Foundation

/// brew コマンドを非同期で実行するプロセスラッパー
public final class BrewProcess {
    private let brewPath: String
    private let environment: [String: String]?
    
    /// 初期化
    /// - Parameters:
    ///   - brewPath: brew バイナリのパス。nil の場合は自動検出
    ///   - environment: 追加の環境変数
    public init(brewPath: String? = nil, environment: [String: String]? = nil) {
        if let brewPath = brewPath {
            self.brewPath = brewPath
        } else if let located = BrewBinaryLocator.locate() {
            self.brewPath = located.path
        } else {
            // フォールバック: /usr/bin/env brew を使用
            self.brewPath = "/usr/bin/env"
        }
        self.environment = environment
    }
    
    /// brew コマンドを実行する
    /// - Parameters:
    ///   - args: brew コマンドの引数（例: ["list", "--formula"]）
    ///   - environment: 追加の環境変数（nil の場合は初期化時の環境変数を使用）
    /// - Returns: 実行結果
    public func run(_ args: [String], environment: [String: String]? = nil) async throws -> BrewResult {
        let process = Process()
        
        // 実行可能ファイルの設定
        if brewPath == "/usr/bin/env" {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["brew"] + args
        } else {
            process.executableURL = URL(fileURLWithPath: brewPath)
            process.arguments = args
        }
        
        // 環境変数の設定
        var env = ProcessInfo.processInfo.environment
        if let additionalEnv = environment ?? self.environment {
            env.merge(additionalEnv) { _, new in new }
        }
        process.environment = env
        
        // パイプの設定
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        
        // プロセス実行
        try process.run()
        process.waitUntilExit()
        
        // 出力の読み取り
        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        
        let stdout = String(data: outData, encoding: .utf8) ?? ""
        let stderr = String(data: errData, encoding: .utf8) ?? ""
        
        return BrewResult(
            stdout: stdout,
            stderr: stderr,
            exitCode: process.terminationStatus
        )
    }
}

/// 非同期実行用の簡易関数
public enum BrewCommand {
    /// brew コマンドを実行する
    /// - Parameters:
    ///   - args: brew コマンドの引数
    ///   - env: 追加の環境変数
    /// - Returns: 実行結果
    public static func run(_ args: [String], env: [String: String]? = nil) async throws -> (stdout: String, stderr: String, exitCode: Int32) {
        let process = BrewProcess(environment: env)
        let result = try await process.run(args, environment: env)
        return (result.stdout, result.stderr, result.exitCode)
    }
}
