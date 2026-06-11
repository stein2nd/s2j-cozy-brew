import Foundation

/// Homebrew のインストールを補助する
public final class BrewInstaller {
    /// Homebrew 公式インストールスクリプトの URL
    public static let installScriptURL = "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    
    /// インストールスクリプトを実行する
    /// - Parameter outputHandler: リアルタイム出力ハンドラ（オプション）
    /// - Returns: インストール結果
    public static func install(outputHandler: (@Sendable (String) -> Void)? = nil) async throws -> BrewResult {
        let collector = InstallStreamCollector(handler: outputHandler)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", "curl -fsSL \(installScriptURL) | bash"]
        
        // 環境変数の設定（非インタラクティブモード）
        var env = ProcessInfo.processInfo.environment
        env["NONINTERACTIVE"] = "1"
        process.environment = env
        
        // パイプの設定
        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe
        
        // リアルタイム出力の監視（オプション）- プロセス実行前に設定
        if outputHandler != nil {
            let outHandle = outPipe.fileHandleForReading
            let errHandle = errPipe.fileHandleForReading
            
            outHandle.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty {
                    handle.readabilityHandler = nil
                } else {
                    collector.appendStdout(data)
                }
            }
            
            errHandle.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty {
                    handle.readabilityHandler = nil
                } else {
                    collector.appendStderr(data)
                }
            }
        }
        
        // プロセス実行
        try process.run()
        process.waitUntilExit()
        
        if outputHandler != nil {
            outPipe.fileHandleForReading.readabilityHandler = nil
            errPipe.fileHandleForReading.readabilityHandler = nil
        }
        
        // 出力の読み取り
        let outData: Data
        let errData: Data
        
        if outputHandler != nil {
            let (collectedOut, collectedErr) = collector.snapshot()
            outData = collectedOut.isEmpty ? outPipe.fileHandleForReading.readDataToEndOfFile() : collectedOut
            errData = collectedErr.isEmpty ? errPipe.fileHandleForReading.readDataToEndOfFile() : collectedErr
        } else {
            outData = outPipe.fileHandleForReading.readDataToEndOfFile()
            errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        }
        
        let stdout = String(data: outData, encoding: .utf8) ?? ""
        let stderr = String(data: errData, encoding: .utf8) ?? ""
        
        return BrewResult(
            stdout: stdout,
            stderr: stderr,
            exitCode: process.terminationStatus
        )
    }
    
    /// インストールスクリプトの内容を取得する（検証用）
    /// - Returns: スクリプトの内容
    public static func fetchInstallScript() async throws -> String {
        guard let url = URL(string: installScriptURL) else {
            throw BrewInstallerError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let script = String(data: data, encoding: .utf8) else {
            throw BrewInstallerError.invalidEncoding
        }
        
        return script
    }
}

/// インストール時の標準出力・標準エラーをスレッドセーフに収集する
private final class InstallStreamCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var outputData = Data()
    private var errorData = Data()
    private let handler: (@Sendable (String) -> Void)?
    
    init(handler: (@Sendable (String) -> Void)?) {
        self.handler = handler
    }
    
    func appendStdout(_ data: Data) {
        guard !data.isEmpty else { return }
        lock.lock()
        outputData.append(data)
        lock.unlock()
        if let handler, let line = String(data: data, encoding: .utf8) {
            handler(line)
        }
    }
    
    func appendStderr(_ data: Data) {
        guard !data.isEmpty else { return }
        lock.lock()
        errorData.append(data)
        lock.unlock()
        if let handler, let line = String(data: data, encoding: .utf8) {
            handler(line)
        }
    }
    
    func snapshot() -> (Data, Data) {
        lock.lock()
        defer { lock.unlock() }
        return (outputData, errorData)
    }
}

/// BrewInstaller のエラー
public enum BrewInstallerError: Error {
    case invalidURL
    case invalidEncoding
    case installationFailed(exitCode: Int32, stderr: String)
}
