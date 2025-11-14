import Foundation

/// Homebrew バイナリの検出とパス解決を行う
public enum BrewBinaryLocator {
    /// Apple Silicon Mac での Homebrew の標準パス
    private static let appleSiliconPath = "/opt/homebrew/bin/brew"
    
    /// Intel Mac での Homebrew の標準パス
    private static let intelPath = "/usr/local/bin/brew"
    
    /// 検出された brew バイナリのパス
    public struct BrewPath {
        public let path: String
        public let architecture: Architecture
        
        public enum Architecture {
            case appleSilicon
            case intel
            case custom(String)
        }
    }
    
    /// brew バイナリを検出する
    /// - Returns: 検出された brew のパス情報。見つからない場合は nil
    public static func locate() -> BrewPath? {
        // まず標準パスを確認
        if FileManager.default.fileExists(atPath: appleSiliconPath) {
            return BrewPath(path: appleSiliconPath, architecture: .appleSilicon)
        }
        
        if FileManager.default.fileExists(atPath: intelPath) {
            return BrewPath(path: intelPath, architecture: .intel)
        }
        
        // which brew で検索
        if let whichPath = findBrewWithWhich() {
            let arch: BrewPath.Architecture
            if whichPath.contains("/opt/homebrew") {
                arch = .appleSilicon
            } else if whichPath.contains("/usr/local") {
                arch = .intel
            } else {
                arch = .custom(whichPath)
            }
            return BrewPath(path: whichPath, architecture: arch)
        }
        
        return nil
    }
    
    /// `which brew` コマンドで brew を検索
    private static func findBrewWithWhich() -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["brew"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !output.isEmpty {
                    return output
                }
            }
        } catch {
            // エラー時は nil を返す
        }
        
        return nil
    }
    
    /// Homebrew のプレフィックスパスを取得
    /// - Parameter brewPath: brew バイナリのパス
    /// - Returns: HOMEBREW_PREFIX の値。取得できない場合は nil
    public static func getHomebrewPrefix(brewPath: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [brewPath, "--prefix"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !output.isEmpty {
                    return output
                }
            }
        } catch {
            // エラー時は nil を返す
        }
        
        return nil
    }
}
