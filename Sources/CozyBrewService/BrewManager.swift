import CozyBrewCore
import Foundation

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

    /// エラーメッセージ (Installed / Outdated 等のパッケージ一覧)
    @Published public private(set) var errorMessage: String?

    /// Tap 一覧取得のエラー (パッケージ一覧の `errorMessage` と分離)
    @Published public private(set) var tapsErrorMessage: String?

    /// brew が利用可能かどうか
    @Published public private(set) var isBrewAvailable: Bool = false

    /// brew のパス
    @Published public private(set) var brewPath: String?

    /// `brew services list` で管理されている Formula (名前 → 状態)
    @Published public private(set) var managedServicesByName: [String: BrewManagedService] = [:]

    /// `brew doctor` の Disclaimer 前文
    @Published public private(set) var doctorPreamble: String?

    /// `brew doctor` の Warning 一覧
    @Published public private(set) var doctorWarnings: [BrewDoctorWarning] = []

    @Published public private(set) var doctorIsLoading: Bool = false

    @Published public private(set) var doctorErrorMessage: String?

    /// Warning ブロック数 (サイドバー・バッジ用)
    public var doctorWarningCount: Int {
        doctorWarnings.count
    }

    /// Formulae カタログ更新の世代 (`@Published` で巨大配列を渡さない)
    @Published public private(set) var catalogFormulaeGeneration: Int = 0

    /// Casks カタログ更新の世代
    @Published public private(set) var catalogCasksGeneration: Int = 0

    @Published public private(set) var catalogFormulaeIsLoading: Bool = false
    @Published public private(set) var catalogCasksIsLoading: Bool = false

    @Published public private(set) var catalogFormulaeErrorMessage: String?
    @Published public private(set) var catalogCasksErrorMessage: String?

    // MARK: - Private Properties

    private let brewProcess: BrewProcess
    private let cache: BrewCache
    private var catalogFormulaeBase: [Package] = []
    private var catalogCasksBase: [Package] = []
    private var catalogFormulaeOverlay: [Package] = []
    private var catalogCasksOverlay: [Package] = []
    private var catalogFormulaeByPage: [CatalogPageRange: [Package]] = [:]
    private var catalogCasksByPage: [CatalogPageRange: [Package]] = [:]
    private let catalogCacheTTL: TimeInterval = 6 * 3600

    public func catalogFormulaeSnapshot() -> [Package] {
        catalogFormulaeOverlay
    }

    public func catalogCasksSnapshot() -> [Package] {
        catalogCasksOverlay
    }

    public func catalogFormulaePage(_ range: CatalogPageRange) -> [Package] {
        catalogFormulaeByPage[range] ?? []
    }

    public func catalogCasksPage(_ range: CatalogPageRange) -> [Package] {
        catalogCasksByPage[range] ?? []
    }

    public var hasCatalogFormulae: Bool {
        !catalogFormulaeOverlay.isEmpty
    }

    public var hasCatalogCasks: Bool {
        !catalogCasksOverlay.isEmpty
    }

    // MARK: - Initialization

    /// 初期化
    /// - Parameters:
    ///   - brewPath: brew バイナリのパス。nil の場合は自動検出
    ///   - cacheDirectory: キャッシュディレクトリ。nil の場合はデフォルトを使用
    public init(brewPath: String? = nil, cacheDirectory: URL? = nil) {
        // brew パスの検出
        if let brewPath {
            self.brewPath = brewPath
            brewProcess = BrewProcess(brewPath: brewPath)
            isBrewAvailable = FileManager.default.fileExists(atPath: brewPath)
        } else if let located = BrewBinaryLocator.locate() {
            self.brewPath = located.path
            brewProcess = BrewProcess(brewPath: located.path)
            isBrewAvailable = true
        } else {
            self.brewPath = nil
            brewProcess = BrewProcess()
            isBrewAvailable = false
        }

        cache = BrewCache(cacheDirectory: cacheDirectory)
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

            let response = try await fetchInstalledListResponse()
            try cache.save(response, forKey: .installedFormulae)
            updateInstalledPackages(from: response)
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

    /// `brew services list --json` で管理サービス一覧を取得
    public func refreshManagedServices() async {
        guard isBrewAvailable else {
            return
        }

        do {
            let result = try await brewProcess.run(["services", "list", "--json"])
            guard result.isSuccess, !result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return
            }
            let decoder = JSONDecoder()
            let services = try decoder.decode([BrewManagedService].self, from: Data(result.stdout.utf8))
            managedServicesByName = Dictionary(uniqueKeysWithValues: services.map { ($0.name, $0) })
        } catch {
            // サービス一覧は補助情報のため、失敗しても他機能は継続する
        }
    }

    /// パッケージに対応する brew services エントリ (名前 / fullName で照合)
    public func managedService(for package: Package) -> BrewManagedService? {
        guard package.type == .formula else { return nil }
        if let service = managedServicesByName[package.name] {
            return service
        }
        if package.fullName != package.name, let service = managedServicesByName[package.fullName] {
            return service
        }
        return nil
    }

    /// Installed / Formulae / Casks 一覧に、`brew outdated` と一致する行の Upgrade 表示用フラグを付与する
    public func annotatingOutdatedStatus(_ packages: [Package]) -> [Package] {
        packages.map { package in
            guard let outdated = outdatedPackages.first(where: {
                $0.id == package.id && $0.type == package.type
            }) else {
                return package
            }
            return package.withListPresentation(from: outdated, isOutdated: true)
        }
    }

    /// 一覧表示用: brew services 登録 Formula を上に並べる
    public func sortedForDisplay(_ packages: [Package]) -> [Package] {
        packages.sorted { lhs, rhs in
            let left = displaySortRank(for: lhs)
            let right = displaySortRank(for: rhs)
            if left != right {
                return left > right
            }
            return lhs.name.lowercased() < rhs.name.lowercased()
        }
    }

    /// Formulae / Casks カタログを名前順に並べる
    public func sortedCatalogAlphabetically(_ packages: [Package]) -> [Package] {
        BrewCatalog.sortedByName(packages)
    }

    /// formulae.brew.sh から Formula カタログを取得
    public func refreshCatalogFormulae() async {
        catalogFormulaeIsLoading = true
        catalogFormulaeErrorMessage = nil
        defer { catalogFormulaeIsLoading = false }

        if let cached = cache.loadData(forKey: .catalogFormulaeAPIJSON, ttl: catalogCacheTTL) {
            await applyCatalogFormulaeData(cached)
        }

        do {
            let data = try await BrewFormulaeAPIClient.fetchFormulaCatalogData()
            try cache.saveData(data, forKey: .catalogFormulaeAPIJSON)
            await applyCatalogFormulaeData(data)
        } catch {
            if !hasCatalogFormulae {
                catalogFormulaeErrorMessage = error.localizedDescription
            }
        }
    }

    /// formulae.brew.sh から Cask カタログを取得
    public func refreshCatalogCasks() async {
        catalogCasksIsLoading = true
        catalogCasksErrorMessage = nil
        defer { catalogCasksIsLoading = false }

        if let cached = cache.loadData(forKey: .catalogCasksAPIJSON, ttl: catalogCacheTTL) {
            await applyCatalogCasksData(cached)
        }

        do {
            let data = try await BrewFormulaeAPIClient.fetchCaskCatalogData()
            try cache.saveData(data, forKey: .catalogCasksAPIJSON)
            await applyCatalogCasksData(data)
        } catch {
            if !hasCatalogCasks {
                catalogCasksErrorMessage = error.localizedDescription
            }
        }
    }

    private func displaySortRank(for package: Package) -> Int {
        guard let service = managedService(for: package) else { return 0 }
        switch service.status {
        case "started":
            return 30
        case "error":
            return 20
        default:
            return 10
        }
    }

    /// `brew doctor` の Warning を取得する
    public func refreshDoctorWarnings() async {
        guard isBrewAvailable else {
            doctorErrorMessage = "Homebrew is not available"
            return
        }

        doctorIsLoading = true
        doctorErrorMessage = nil
        defer { doctorIsLoading = false }

        do {
            let result = try await brewProcess.run(["doctor"])
            let combined = [result.stdout, result.stderr]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: "\n")

            guard !combined.isEmpty else {
                doctorPreamble = nil
                doctorWarnings = []
                if !result.isSuccess {
                    doctorErrorMessage = result.errorMessage
                }
                return
            }

            let parsed = BrewDoctorParser.parse(combined)
            doctorPreamble = parsed.preamble
            doctorWarnings = parsed.warnings
        } catch {
            doctorPreamble = nil
            doctorWarnings = []
            doctorErrorMessage = "Failed to run brew doctor: \(error.localizedDescription)"
        }
    }

    /// Tap 一覧を取得
    public func refreshTaps() async {
        guard isBrewAvailable else {
            tapsErrorMessage = "Homebrew is not available"
            return
        }

        isLoading = true
        tapsErrorMessage = nil

        do {
            if let cached: BrewTapResponse = try cache.load(BrewTapResponse.self, forKey: .taps) {
                taps = cached.taps
            }

            let jsonResult = try await brewProcess.run(["tap", "--json"])
            if jsonResult.isSuccess,
               !jsonResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            {
                let decoder = JSONDecoder()
                let response = try decoder.decode(BrewTapResponse.self, from: Data(jsonResult.stdout.utf8))
                try cache.save(response, forKey: .taps)
                taps = response.taps
            } else {
                let plain = try await brewProcess.run(["tap"])
                guard plain.isSuccess else {
                    tapsErrorMessage = plain.errorMessage
                    return
                }
                let parsed = BrewTapParsing.parsePlainList(plain.stdout)
                taps = parsed
                try cache.save(BrewTapResponse(taps: parsed), forKey: .taps)
            }
        } catch {
            tapsErrorMessage = "Failed to load taps: \(error.localizedDescription)"
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
    public func install(_ package: Package, progressHandler _: ((String) -> Void)? = nil) async throws {
        guard isBrewAvailable else {
            throw BrewManagerError.brewNotAvailable
        }

        var args = ["install", "--yes"]
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

        let service = managedService(for: package)
        let serviceName = service?.name ?? package.name
        let shouldRestartService = service?.shouldStopBeforeUpgrade == true

        if shouldRestartService {
            let stop = try await brewProcess.run(["services", "stop", serviceName])
            if !stop.isSuccess {
                throw BrewManagerError.serviceCommandFailed(command: "stop", stderr: stop.stderr)
            }
        }

        var args = ["upgrade", "--yes"]
        if package.type == .cask {
            args.append("--cask")
        }
        args.append(package.fullName)

        let result = try await brewProcess.run(args)

        if !result.isSuccess {
            if shouldRestartService {
                _ = try? await brewProcess.run(["services", "start", serviceName])
            }
            throw BrewManagerError.upgradeFailed(stderr: result.stderr)
        }

        if shouldRestartService {
            let start = try await brewProcess.run(["services", "start", serviceName])
            if !start.isSuccess {
                throw BrewManagerError.serviceCommandFailed(command: "start", stderr: start.stderr)
            }
        }

        // 一覧を更新
        await refreshInstalledPackages()
        await refreshOutdatedPackages()
        await refreshManagedServices()
    }

    /// `brew info --json=v2` で説明・依存関係等を補完した `Package` を返す
    public func packageInfo(for package: Package) async throws -> Package {
        guard isBrewAvailable else {
            throw BrewManagerError.brewNotAvailable
        }

        var args = ["info", "--json=v2"]
        if package.type == .cask {
            args.append("--cask")
        }
        args.append(package.name)

        let result = try await brewProcess.run(args)
        guard result.isSuccess else {
            throw BrewManagerError.packageInfoFailed(stderr: result.errorMessage)
        }

        let decoder = JSONDecoder()
        let response = try decoder.decode(BrewInfoResponse.self, from: Data(result.stdout.utf8))

        let listSeed = freshListPackage(matching: package) ?? package

        let enriched: Package
        switch package.type {
        case .formula:
            guard let formula = response.formulae?.first else {
                throw BrewManagerError.packageInfoNotFound(name: package.name)
            }
            let detail = Package.from(formula)
            enriched = listSeed.enriched(
                with: detail,
                dependencies: formula.dependencies,
                buildDependencies: formula.buildDependencies
            )
        case .cask:
            guard let cask = response.casks?.first else {
                throw BrewManagerError.packageInfoNotFound(name: package.name)
            }
            let detail = Package.from(cask)
            enriched = listSeed.enriched(with: detail)
        }

        return applyingCurrentLists(to: enriched)
    }

    /// インストール済み / Outdated 一覧から最新の行 `Package` を返す
    public func freshListPackage(matching package: Package) -> Package? {
        outdatedPackages.first { $0.id == package.id && $0.type == package.type }
            ?? installedPackages.first { $0.id == package.id && $0.type == package.type }
    }

    /// `brew outdated` / `brew list` の結果で `isOutdated` 等を上書きする (`brew info` 単体より優先)
    private func applyingCurrentLists(to package: Package) -> Package {
        if let outdated = outdatedPackages.first(where: { $0.id == package.id && $0.type == package.type }) {
            return package.withListPresentation(from: outdated, isOutdated: true)
        }
        if let installed = installedPackages.first(where: { $0.id == package.id && $0.type == package.type }) {
            return package.withListPresentation(from: installed, isOutdated: false)
        }
        return package
    }

    /// すべてのパッケージをアップグレード
    public func upgradeAll() async throws {
        guard isBrewAvailable else {
            throw BrewManagerError.brewNotAvailable
        }

        let result = try await brewProcess.run(["upgrade", "--yes"])

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

    /// インストール済み一覧を取得する (Homebrew 4–6: `--json=v2`、Homebrew 7+: `--versions --json`)
    private func fetchInstalledListResponse() async throws -> BrewListResponse {
        let legacy = try await brewProcess.run(["list", "--json=v2"])
        if legacy.isSuccess, !legacy.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let decoder = JSONDecoder()
            return try decoder.decode(BrewListResponse.self, from: Data(legacy.stdout.utf8))
        }

        let modern = try await brewProcess.run(["list", "--versions", "--json"])
        guard modern.isSuccess, !modern.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            let detail = [modern.stderr, modern.stdout, legacy.stderr]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first(where: { !$0.isEmpty })
                ?? "Unknown brew list error"
            throw BrewManagerError.installedListFailed(stderr: detail)
        }

        let decoder = JSONDecoder()
        let versions = try decoder.decode(BrewInstalledVersionsResponse.self, from: Data(modern.stdout.utf8))
        return versions.asBrewListResponse()
    }

    private func updateInstalledPackages(from response: BrewListResponse) {
        var packages: [Package] = []
        if let formulae = response.formulae {
            packages.append(contentsOf: formulae.map { Package.from($0) })
        }
        if let casks = response.casks {
            packages.append(contentsOf: casks.map { Package.from($0) })
        }
        installedPackages = packages
        rebuildCatalogsIfNeeded()
    }

    private func applyCatalogFormulaeData(_ data: Data) async {
        do {
            let base = try await Task.detached(priority: .userInitiated) {
                try BrewCatalogAPIParsing.packagesFromFormulaCatalog(data)
            }.value
            catalogFormulaeBase = base
            republishCatalogFormulaeOverlay()
        } catch {
            if !hasCatalogFormulae {
                catalogFormulaeErrorMessage = "Failed to decode formulae catalog: \(error.localizedDescription)"
            }
        }
    }

    private func applyCatalogCasksData(_ data: Data) async {
        do {
            let base = try await Task.detached(priority: .userInitiated) {
                try BrewCatalogAPIParsing.packagesFromCaskCatalog(data)
            }.value
            catalogCasksBase = base
            republishCatalogCasksOverlay()
        } catch {
            if !hasCatalogCasks {
                catalogCasksErrorMessage = "Failed to decode casks catalog: \(error.localizedDescription)"
            }
        }
    }

    private func republishCatalogFormulaeOverlay() {
        let overlaid = BrewCatalog.overlayLocalInstalled(
            catalogFormulaeBase,
            installed: installedPackages,
            type: .formula
        )
        catalogFormulaeOverlay = applyingOutdatedAnnotations(to: overlaid)
        catalogFormulaeByPage = BrewCatalog.partitionByPage(catalogFormulaeOverlay)
        catalogFormulaeGeneration += 1
    }

    private func republishCatalogCasksOverlay() {
        let overlaid = BrewCatalog.overlayLocalInstalled(
            catalogCasksBase,
            installed: installedPackages,
            type: .cask
        )
        catalogCasksOverlay = applyingOutdatedAnnotations(to: overlaid)
        catalogCasksByPage = BrewCatalog.partitionByPage(catalogCasksOverlay)
        catalogCasksGeneration += 1
    }

    private func applyingOutdatedAnnotations(to packages: [Package]) -> [Package] {
        packages.map { package in
            guard let outdated = outdatedPackages.first(where: {
                $0.id == package.id && $0.type == package.type
            }) else {
                return package
            }
            return package.withListPresentation(from: outdated, isOutdated: true)
        }
    }

    private func rebuildCatalogsIfNeeded() {
        if !catalogFormulaeBase.isEmpty {
            republishCatalogFormulaeOverlay()
        }
        if !catalogCasksBase.isEmpty {
            republishCatalogCasksOverlay()
        }
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
        rebuildCatalogsIfNeeded()
    }
}

/// BrewManager のエラー
public enum BrewManagerError: Error, LocalizedError {
    case brewNotAvailable
    case installedListFailed(stderr: String)
    case serviceCommandFailed(command: String, stderr: String)
    case installationFailed(stderr: String)
    case uninstallationFailed(stderr: String)
    case upgradeFailed(stderr: String)
    case updateFailed(stderr: String)
    case packageInfoFailed(stderr: String)
    case packageInfoNotFound(name: String)

    public var errorDescription: String? {
        switch self {
        case .brewNotAvailable:
            "Homebrew is not available"
        case let .installedListFailed(stderr):
            "Failed to load installed packages: \(stderr)"
        case let .serviceCommandFailed(command, stderr):
            "brew services \(command) failed: \(stderr)"
        case let .installationFailed(stderr):
            "Installation failed: \(stderr)"
        case let .uninstallationFailed(stderr):
            "Uninstallation failed: \(stderr)"
        case let .upgradeFailed(stderr):
            "Upgrade failed: \(stderr)"
        case let .updateFailed(stderr):
            "Update failed: \(stderr)"
        case let .packageInfoFailed(stderr):
            "Failed to load package info: \(stderr)"
        case let .packageInfoNotFound(name):
            "Package not found: \(name)"
        }
    }
}
