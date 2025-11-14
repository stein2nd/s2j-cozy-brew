import Foundation
import Combine
import CozyBrewCore

/// Homebrew 操作を管理する ViewModel
@MainActor
public final class BrewManager: ObservableObject {
    // MARK: - Published Properties
    
    /// インストール済みパッケージ一覧
    @Published public private(set) var installedPackages: [Package] = []
    
    /// アップデート可能なパッケージ一覧
    @Published public private(set) var outdatedPackages: [Package] = []
    
    /// Tap 一覧
    @Published public private(set) var taps: [Tap] = []
    
    /// 検索結果
    @Published public private(set) var searchResults: [Package] = []
    
    /// ローディング状態
    @Published public private(set) var isLoading: Bool = false
    
    /// エラーメッセージ
    @Published public private(set) var errorMessage: String?
    
    /// brew が利用可能かどうか
    @Published public private(set) var isBrewAvailable: Bool = false
    
    /// brew のパス
    @Published public private(set) var brewPath: String?
    
    // MARK: - Private Properties
    
    private let brewProcess: BrewProcess
    private let cache: BrewCache
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// 初期化
    /// - Parameters:
    ///   - brewPath: brew バイナリのパス。nil の場合は自動検出
    ///   - cacheDirectory: キャッシュディレクトリ。nil の場合はデフォルトを使用
    public init(brewPath: String? = nil, cacheDirectory: URL? = nil) {
        // brew パスの検出
        if let brewPath = brewPath {
            self.brewPath = brewPath
            self.brewProcess = BrewProcess(brewPath: brewPath)
            self.isBrewAvailable = FileManager.default.fileExists(atPath: brewPath)
        } else if let located = BrewBinaryLocator.locate() {
            self.brewPath = located.path
            self.brewProcess = BrewProcess(brewPath: located.path)
            self.isBrewAvailable = true
        } else {
            self.brewPath = nil
            self.brewProcess = BrewProcess()
            self.isBrewAvailable = false
        }
        
        self.cache = BrewCache(cacheDirectory: cacheDirectory)
    }
    
    // MARK: - Public Methods
    
    /// インストール済みパッケージ一覧を取得
    public func refreshInstalledPackages() async {
        guard isBrewAvailable else {
            errorMessage = "Homebrew is not available"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // キャッシュから読み込みを試みる
            if let cached: BrewListResponse = try cache.load(BrewListResponse.self, forKey: .installedFormulae) {
                updateInstalledPackages(from: cached)
            }
            
            // brew list --json=v2 を実行
            let result = try await brewProcess.run(["list", "--json=v2"])
            
            if result.isSuccess {
                let decoder = JSONDecoder()
                let response = try decoder.decode(BrewListResponse.self, from: Data(result.stdout.utf8))
                
                // キャッシュに保存
                try cache.save(response, forKey: .installedFormulae)
                
                updateInstalledPackages(from: response)
            } else {
                errorMessage = result.errorMessage
            }
        } catch {
            errorMessage = "Failed to load installed packages: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// アップデート可能なパッケージ一覧を取得
    public func refreshOutdatedPackages() async {
        guard isBrewAvailable else {
            errorMessage = "Homebrew is not available"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // キャッシュから読み込みを試みる
            if let cached: BrewListResponse = try cache.load(BrewListResponse.self, forKey: .outdatedFormulae) {
                updateOutdatedPackages(from: cached)
            }
            
            // brew outdated --json=v2 を実行
            let result = try await brewProcess.run(["outdated", "--json=v2"])
            
            if result.isSuccess {
                let decoder = JSONDecoder()
                let response = try decoder.decode(BrewListResponse.self, from: Data(result.stdout.utf8))
                
                // キャッシュに保存
                try cache.save(response, forKey: .outdatedFormulae)
                
                updateOutdatedPackages(from: response)
            } else {
                errorMessage = result.errorMessage
            }
        } catch {
            errorMessage = "Failed to load outdated packages: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Tap 一覧を取得
    public func refreshTaps() async {
        guard isBrewAvailable else {
            errorMessage = "Homebrew is not available"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // キャッシュから読み込みを試みる
            if let cached: BrewTapResponse = try cache.load(BrewTapResponse.self, forKey: .taps) {
                taps = cached.taps
            }
            
            // brew tap --json を実行
            let result = try await brewProcess.run(["tap", "--json"])
            
            if result.isSuccess {
                let decoder = JSONDecoder()
                let response = try decoder.decode(BrewTapResponse.self, from: Data(result.stdout.utf8))
                
                // キャッシュに保存
                try cache.save(response, forKey: .taps)
                
                taps = response.taps
            } else {
                errorMessage = result.errorMessage
            }
        } catch {
            errorMessage = "Failed to load taps: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// パッケージを検索
    /// - Parameter query: 検索クエリ
    public func search(_ query: String) async {
        guard isBrewAvailable, !query.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // brew search --json=v2 を実行
            let result = try await brewProcess.run(["search", "--json=v2", query])
            
            if result.isSuccess {
                let decoder = JSONDecoder()
                let response = try decoder.decode(BrewInfoResponse.self, from: Data(result.stdout.utf8))
                
                var packages: [Package] = []
                if let formulae = response.formulae {
                    packages.append(contentsOf: formulae.map { Package.from($0) })
                }
                if let casks = response.casks {
                    packages.append(contentsOf: casks.map { Package.from($0) })
                }
                
                searchResults = packages
            } else {
                errorMessage = result.errorMessage
                searchResults = []
            }
        } catch {
            errorMessage = "Failed to search packages: \(error.localizedDescription)"
            searchResults = []
        }
        
        isLoading = false
    }
    
    /// パッケージをインストール
    /// - Parameters:
    ///   - package: インストールするパッケージ
    ///   - progressHandler: 進捗ハンドラ
    public func install(_ package: Package, progressHandler: ((String) -> Void)? = nil) async throws {
        guard isBrewAvailable else {
            throw BrewManagerError.brewNotAvailable
        }
        
        var args = ["install"]
        if package.type == .cask {
            args.append("--cask")
        }
        args.append(package.fullName)
        
        let result = try await brewProcess.run(args)
        
        if !result.isSuccess {
            throw BrewManagerError.installationFailed(stderr: result.stderr)
        }
        
        // インストール済み一覧を更新
        await refreshInstalledPackages()
    }
    
    /// パッケージをアンインストール
    /// - Parameter package: アンインストールするパッケージ
    public func uninstall(_ package: Package) async throws {
        guard isBrewAvailable else {
            throw BrewManagerError.brewNotAvailable
        }
        
        var args = ["uninstall"]
        if package.type == .cask {
            args.append("--cask")
        }
        args.append(package.fullName)
        
        let result = try await brewProcess.run(args)
        
        if !result.isSuccess {
            throw BrewManagerError.uninstallationFailed(stderr: result.stderr)
        }
        
        // インストール済み一覧を更新
        await refreshInstalledPackages()
    }
    
    /// パッケージをアップグレード
    /// - Parameter package: アップグレードするパッケージ
    public func upgrade(_ package: Package) async throws {
        guard isBrewAvailable else {
            throw BrewManagerError.brewNotAvailable
        }
        
        var args = ["upgrade"]
        if package.type == .cask {
            args.append("--cask")
        }
        args.append(package.fullName)
        
        let result = try await brewProcess.run(args)
        
        if !result.isSuccess {
            throw BrewManagerError.upgradeFailed(stderr: result.stderr)
        }
        
        // 一覧を更新
        await refreshInstalledPackages()
        await refreshOutdatedPackages()
    }
    
    /// すべてのパッケージをアップグレード
    public func upgradeAll() async throws {
        guard isBrewAvailable else {
            throw BrewManagerError.brewNotAvailable
        }
        
        let result = try await brewProcess.run(["upgrade"])
        
        if !result.isSuccess {
            throw BrewManagerError.upgradeFailed(stderr: result.stderr)
        }
        
        // 一覧を更新
        await refreshInstalledPackages()
        await refreshOutdatedPackages()
    }
    
    /// brew update を実行
    public func update() async throws {
        guard isBrewAvailable else {
            throw BrewManagerError.brewNotAvailable
        }
        
        let result = try await brewProcess.run(["update"])
        
        if !result.isSuccess {
            throw BrewManagerError.updateFailed(stderr: result.stderr)
        }
    }
    
    // MARK: - Private Methods
    
    private func updateInstalledPackages(from response: BrewListResponse) {
        var packages: [Package] = []
        if let formulae = response.formulae {
            packages.append(contentsOf: formulae.map { Package.from($0) })
        }
        if let casks = response.casks {
            packages.append(contentsOf: casks.map { Package.from($0) })
        }
        installedPackages = packages
    }
    
    private func updateOutdatedPackages(from response: BrewListResponse) {
        var packages: [Package] = []
        if let formulae = response.formulae {
            packages.append(contentsOf: formulae.map { Package.from($0) })
        }
        if let casks = response.casks {
            packages.append(contentsOf: casks.map { Package.from($0) })
        }
        outdatedPackages = packages
    }
}

/// BrewManager のエラー
public enum BrewManagerError: Error, LocalizedError {
    case brewNotAvailable
    case installationFailed(stderr: String)
    case uninstallationFailed(stderr: String)
    case upgradeFailed(stderr: String)
    case updateFailed(stderr: String)
    
    public var errorDescription: String? {
        switch self {
        case .brewNotAvailable:
            return "Homebrew is not available"
        case .installationFailed(let stderr):
            return "Installation failed: \(stderr)"
        case .uninstallationFailed(let stderr):
            return "Uninstallation failed: \(stderr)"
        case .upgradeFailed(let stderr):
            return "Upgrade failed: \(stderr)"
        case .updateFailed(let stderr):
            return "Update failed: \(stderr)"
        }
    }
}
