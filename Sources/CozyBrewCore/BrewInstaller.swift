import Foundation

/// Homebrew のインストールを補助する
public final class BrewInstaller {
    /// Homebrew 公式インストールスクリプトの URL
    public static let installScriptURL = "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    
    /// インストールスクリプトを実行する
    /// - Parameter outputHandler: リアルタイム出力ハンドラ（オプション）
    /// - Returns: インストール結果
    public static func install(outputHandler: ((String) -> Void)? = nil) async throws -> BrewResult {
        var outputData = Data()
        var errorData = Data()
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
        if let handler = outputHandler {
            let outHandle = outPipe.fileHandleForReading
            let errHandle = errPipe.fileHandleForReading
            
            // 非同期で出力を監視
            let outTask = Task {
                outHandle.waitForDataInBackgroundAndNotify()
                NotificationCenter.default.addObserver(
                    forName: .NSFileHandleDataAvailable,
                    object: outHandle,
                    queue: nil
                ) { _ in
                    let data = outHandle.availableData
                    if !data.isEmpty {
                        outputData.append(data)
                        if let line = String(data: data, encoding: .utf8) {
                            handler(line)
                        }
                        outHandle.waitForDataInBackgroundAndNotify()
                    }
                }
            }
            
            let errTask = Task {
                errHandle.waitForDataInBackgroundAndNotify()
                NotificationCenter.default.addObserver(
                    forName: .NSFileHandleDataAvailable,
                    object: errHandle,
                    queue: nil
                ) { _ in
                    let data = errHandle.availableData
                    if !data.isEmpty {
                        errorData.append(data)
                        if let line = String(data: data, encoding: .utf8) {
                            handler(line)
                        }
                        errHandle.waitForDataInBackgroundAndNotify()
                    }
                }
            }
            
            // プロセス実行
            try process.run()
            process.waitUntilExit()
            
            // タスクをキャンセル
            outTask.cancel()
            errTask.cancel()
        } else {
            // プロセス実行
            try process.run()
            process.waitUntilExit()
        }
        
        // 出力の読み取り
        let outData: Data
        let errData: Data
        
        if outputHandler != nil {
            // リアルタイム出力を使用した場合は、既に収集したデータを使用
            outData = outputData.isEmpty ? outPipe.fileHandleForReading.readDataToEndOfFile() : outputData
            errData = errorData.isEmpty ? errPipe.fileHandleForReading.readDataToEndOfFile() : errorData
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

/// BrewInstaller のエラー
public enum BrewInstallerError: Error {
    case invalidURL
    case invalidEncoding
    case installationFailed(exitCode: Int32, stderr: String)
}
