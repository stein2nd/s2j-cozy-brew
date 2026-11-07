import Foundation

/// Homebrew パッケージの基本型
public protocol BrewPackage: Codable, Identifiable {
    var id: String { get }
    var name: String { get }
    var fullName: String { get }
    var desc: String? { get }
    var homepage: String? { get }
    var version: String? { get }
    var installed: [InstalledVersion]? { get }
}

/// インストール済みバージョン情報
public struct InstalledVersion: Codable {
    public let version: String
    public let installedOnRequest: Bool
    public let installedAsDependency: Bool

    public init(version: String, installedOnRequest: Bool, installedAsDependency: Bool) {
        self.version = version
        self.installedOnRequest = installedOnRequest
        self.installedAsDependency = installedAsDependency
    }

    private enum CodingKeys: String, CodingKey {
        case version
        case installedOnRequest = "installed_on_request"
        case installedAsDependency = "installed_as_dependency"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = JSONLenient.decodeString(from: container, forKey: .version) ?? ""
        installedOnRequest = try container.decodeIfPresent(Bool.self, forKey: .installedOnRequest) ?? false
        installedAsDependency = try container.decodeIfPresent(Bool.self, forKey: .installedAsDependency) ?? false
    }
}

/// `brew info` の `versions` オブジェクト
private struct BrewVersionSpec: Codable {
    let stable: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stable = JSONLenient.decodeString(from: container, forKey: .stable)
    }

    private enum CodingKeys: String, CodingKey {
        case stable
    }
}

enum HomebrewMetadata {
    /// `tap` + `ruby_source_path` から Formula 定義の GitHub URL を組み立てる
    static func formulaSourceURL(tap: String?, rubySourcePath: String?) -> String? {
        guard let rubySourcePath, !rubySourcePath.isEmpty else { return nil }
        let repoName: String
        if let tap, let slash = tap.firstIndex(of: "/") {
            let owner = String(tap[..<slash])
            let repo = String(tap[tap.index(after: slash)...])
            repoName = owner == "homebrew" ? "homebrew-\(repo)" : "\(owner)-\(repo)"
        } else {
            repoName = "homebrew-core"
        }
        return "https://github.com/Homebrew/\(repoName)/blob/HEAD/\(rubySourcePath)"
    }
}

/// Formula (ソースからビルドするパッケージ)
public struct Formula: BrewPackage {
    public let id: String
    public let name: String
    public let fullName: String
    public let desc: String?
    public let homepage: String?
    public let version: String?
    public let installed: [InstalledVersion]?
    public let dependencies: [String]?
    public let buildDependencies: [String]?
    public let conflictsWith: [String]?
    public let pinned: Bool?
    public let outdated: Bool?
    public let deprecated: Bool?
    public let deprecationReason: String?
    public let disabled: Bool?
    public let disableReason: String?
    public let license: String?
    public let tap: String?
    public let rubySourcePath: String?

    public init(
        id: String,
        name: String,
        fullName: String,
        desc: String? = nil,
        homepage: String? = nil,
        version: String? = nil,
        installed: [InstalledVersion]? = nil,
        dependencies: [String]? = nil,
        buildDependencies: [String]? = nil,
        conflictsWith: [String]? = nil,
        pinned: Bool? = nil,
        outdated: Bool? = nil,
        deprecated: Bool? = nil,
        deprecationReason: String? = nil,
        disabled: Bool? = nil,
        disableReason: String? = nil,
        license: String? = nil,
        tap: String? = nil,
        rubySourcePath: String? = nil
    ) {
        self.id = id
        self.name = name
        self.fullName = fullName
        self.desc = desc
        self.homepage = homepage
        self.version = version
        self.installed = installed
        self.dependencies = dependencies
        self.buildDependencies = buildDependencies
        self.conflictsWith = conflictsWith
        self.pinned = pinned
        self.outdated = outdated
        self.deprecated = deprecated
        self.deprecationReason = deprecationReason
        self.disabled = disabled
        self.disableReason = disableReason
        self.license = license
        self.tap = tap
        self.rubySourcePath = rubySourcePath
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case desc
        case homepage
        case version
        case installed
        case dependencies
        case buildDependencies = "build_dependencies"
        case conflictsWith = "conflicts_with"
        case pinned
        case outdated
        case deprecated
        case deprecationReason = "deprecation_reason"
        case disabled
        case disableReason = "disable_reason"
        case license
        case tap
        case rubySourcePath = "ruby_source_path"
    }

    private enum OutdatedJSONKeys: String, CodingKey {
        case installedVersions = "installed_versions"
        case currentVersion = "current_version"
    }

    private enum InfoJSONKeys: String, CodingKey {
        case versions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let outdatedContainer = try decoder.container(keyedBy: OutdatedJSONKeys.self)
        let infoContainer = try decoder.container(keyedBy: InfoJSONKeys.self)

        // `id` は API から返らないため `name` で代用する
        let decodedName = JSONLenient.decodeString(from: container, forKey: .name) ?? ""
        guard !decodedName.isEmpty else {
            throw DecodingError.keyNotFound(
                CodingKeys.name,
                .init(codingPath: decoder.codingPath, debugDescription: "Formula name missing")
            )
        }
        name = decodedName
        id = JSONLenient.decodeString(from: container, forKey: .id) ?? decodedName
        fullName = JSONLenient.decodeString(from: container, forKey: .fullName) ?? decodedName
        desc = JSONLenient.decodeString(from: container, forKey: .desc)
        homepage = JSONLenient.decodeString(from: container, forKey: .homepage)

        var decodedVersion = JSONLenient.decodeString(from: container, forKey: .version)
        if decodedVersion == nil,
           let spec = try infoContainer.decodeIfPresent(BrewVersionSpec.self, forKey: .versions)
        {
            decodedVersion = spec.stable
        }
        if decodedVersion == nil {
            decodedVersion = JSONLenient.decodeString(from: outdatedContainer, forKey: .currentVersion)
        }
        version = decodedVersion

        var decodedInstalled: [InstalledVersion]?
        if let installedArray = try? container.decode([InstalledVersion].self, forKey: .installed) {
            decodedInstalled = installedArray
        }
        if decodedInstalled == nil,
           let versionStrings = JSONLenient.decodeStringArray(from: outdatedContainer, forKey: .installedVersions)
        {
            decodedInstalled = versionStrings.map {
                InstalledVersion(version: $0, installedOnRequest: true, installedAsDependency: false)
            }
        }
        installed = decodedInstalled

        dependencies = JSONLenient.decodeStringArray(from: container, forKey: .dependencies)
        buildDependencies = JSONLenient.decodeStringArray(from: container, forKey: .buildDependencies)
        conflictsWith = try container.decodeIfPresent([String].self, forKey: .conflictsWith)
        pinned = try container.decodeIfPresent(Bool.self, forKey: .pinned)

        var decodedOutdated = try container.decodeIfPresent(Bool.self, forKey: .outdated)
        if decodedOutdated == nil, let decodedInstalled, !decodedInstalled.isEmpty,
           decodedVersion != nil
        {
            decodedOutdated = true
        }
        outdated = decodedOutdated
        deprecated = try container.decodeIfPresent(Bool.self, forKey: .deprecated)
        deprecationReason = try container.decodeIfPresent(String.self, forKey: .deprecationReason)
        disabled = try container.decodeIfPresent(Bool.self, forKey: .disabled)
        disableReason = try container.decodeIfPresent(String.self, forKey: .disableReason)
        tap = try container.decodeIfPresent(String.self, forKey: .tap)
        rubySourcePath = try container.decodeIfPresent(String.self, forKey: .rubySourcePath)
        if let licenseString = try? container.decodeIfPresent(String.self, forKey: .license) {
            license = licenseString
        } else if let licenseList = try? container.decodeIfPresent([String].self, forKey: .license) {
            license = licenseList.joined(separator: " AND ")
        } else {
            license = nil
        }
    }
}

/// Cask (バイナリ配布パッケージ)
public struct Cask: BrewPackage {
    public let id: String
    public let name: String
    public let fullName: String
    public let desc: String?
    public let homepage: String?
    public let version: String?
    public let installed: [InstalledVersion]?
    public let token: String
    public let outdated: Bool?
    public let deprecated: Bool?
    public let deprecationReason: String?
    public let disabled: Bool?
    public let disableReason: String?
    public let appcast: String?
    public let url: String?

    public init(
        id: String,
        name: String,
        fullName: String,
        token: String,
        desc: String? = nil,
        homepage: String? = nil,
        version: String? = nil,
        installed: [InstalledVersion]? = nil,
        outdated: Bool? = nil,
        deprecated: Bool? = nil,
        deprecationReason: String? = nil,
        disabled: Bool? = nil,
        disableReason: String? = nil,
        appcast: String? = nil,
        url: String? = nil
    ) {
        self.id = id
        self.name = name
        self.fullName = fullName
        self.token = token
        self.desc = desc
        self.homepage = homepage
        self.version = version
        self.installed = installed
        self.outdated = outdated
        self.deprecated = deprecated
        self.deprecationReason = deprecationReason
        self.disabled = disabled
        self.disableReason = disableReason
        self.appcast = appcast
        self.url = url
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName = "full_name"
        case desc
        case homepage
        case version
        case installed
        case token
        case outdated
        case deprecated
        case deprecationReason = "deprecation_reason"
        case disabled
        case disableReason = "disable_reason"
        case appcast
        case url
    }

    private enum OutdatedJSONKeys: String, CodingKey {
        case installedVersions = "installed_versions"
        case currentVersion = "current_version"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let outdatedContainer = try decoder.container(keyedBy: OutdatedJSONKeys.self)

        // `id` は存在しないため token を優先、無ければ name の先頭を使用する
        let decodedToken = try container.decodeIfPresent(String.self, forKey: .token)
        let decodedName: String = if let nameArray = try? container.decode([String].self, forKey: .name) {
            nameArray.first ?? ""
        } else {
            try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        }

        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? decodedToken
            ?? decodedName
        token = decodedToken ?? decodedName
        name = decodedName
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName) ?? decodedName
        desc = try container.decodeIfPresent(String.self, forKey: .desc)
        homepage = try container.decodeIfPresent(String.self, forKey: .homepage)

        var decodedVersion = JSONLenient.decodeString(from: container, forKey: .version)
        if decodedVersion == nil {
            decodedVersion = JSONLenient.decodeString(from: outdatedContainer, forKey: .currentVersion)
        }
        version = decodedVersion

        var decodedInstalled: [InstalledVersion]?
        if let installedArray = try? container.decode([InstalledVersion].self, forKey: .installed) {
            decodedInstalled = installedArray
        } else if let installedVersion = JSONLenient.decodeString(from: container, forKey: .installed) {
            decodedInstalled = [
                InstalledVersion(version: installedVersion, installedOnRequest: true, installedAsDependency: false),
            ]
        }
        if decodedInstalled == nil,
           let versionStrings = JSONLenient.decodeStringArray(from: outdatedContainer, forKey: .installedVersions)
        {
            decodedInstalled = versionStrings.map {
                InstalledVersion(version: $0, installedOnRequest: true, installedAsDependency: false)
            }
        }
        installed = decodedInstalled

        var decodedOutdated = try container.decodeIfPresent(Bool.self, forKey: .outdated)
        if decodedOutdated == nil, let decodedInstalled, !decodedInstalled.isEmpty,
           decodedVersion != nil
        {
            decodedOutdated = true
        }
        outdated = decodedOutdated
        deprecated = try container.decodeIfPresent(Bool.self, forKey: .deprecated)
        deprecationReason = JSONLenient.decodeString(from: container, forKey: .deprecationReason)
        disabled = try container.decodeIfPresent(Bool.self, forKey: .disabled)
        disableReason = JSONLenient.decodeString(from: container, forKey: .disableReason)
        appcast = JSONLenient.decodeString(from: container, forKey: .appcast)
        url = JSONLenient.decodeString(from: container, forKey: .url)
    }
}

/// 一覧のクライアント側フィルタ
public enum PackageListFilter {
    public static func matches(_ package: Package, query: String) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return true }
        if package.name.lowercased().contains(needle.lowercased()) {
            return true
        }
        if package.fullName.lowercased().contains(needle.lowercased()) {
            return true
        }
        if let desc = package.desc, desc.lowercased().contains(needle.lowercased()) {
            return true
        }
        return false
    }
}

/// `brew tap` テキスト一覧のパース
public enum BrewTapParsing {
    public static func parsePlainList(_ stdout: String) -> [Tap] {
        stdout
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { line in
                let parts = line.split(separator: "/")
                if parts.count >= 2 {
                    let user = String(parts[0])
                    let repo = String(parts[1])
                    return Tap(id: line, name: line, user: user, repo: repo, path: "")
                }
                return Tap(id: line, name: line, user: "", repo: line, path: "")
            }
    }
}

/// Tap (リポジトリ)
public struct Tap: Codable, Identifiable {
    public let id: String
    public let name: String
    public let user: String
    public let repo: String
    public let path: String
    public let remote: String?
    public let official: Bool?
    public let customRemote: Bool?
    public let pinned: Bool?

    public init(
        id: String,
        name: String,
        user: String,
        repo: String,
        path: String,
        remote: String? = nil,
        official: Bool? = nil,
        customRemote: Bool? = nil,
        pinned: Bool? = nil
    ) {
        self.id = id
        self.name = name
        self.user = user
        self.repo = repo
        self.path = path
        self.remote = remote
        self.official = official
        self.customRemote = customRemote
        self.pinned = pinned
    }
}

/// brew info --json=v2 のレスポンス構造
public struct BrewInfoResponse: Codable {
    public let formulae: [Formula]?
    public let casks: [Cask]?

    public init(formulae: [Formula]? = nil, casks: [Cask]? = nil) {
        self.formulae = formulae
        self.casks = casks
    }
}

/// brew list --json=v2 のレスポンス構造
public struct BrewListResponse: Codable {
    public let formulae: [Formula]?
    public let casks: [Cask]?

    public init(formulae: [Formula]? = nil, casks: [Cask]? = nil) {
        self.formulae = formulae
        self.casks = casks
    }
}

/// Homebrew 7+ の `brew list --versions --json` レスポンス (Formula 行)
public struct BrewInstalledFormulaVersions: Codable, Sendable {
    public let name: String
    public let versions: [String]
    public let linkedVersion: String?
    public let optlinkedVersion: String?
    public let pinnedVersion: String?

    public init(
        name: String,
        versions: [String],
        linkedVersion: String? = nil,
        optlinkedVersion: String? = nil,
        pinnedVersion: String? = nil
    ) {
        self.name = name
        self.versions = versions
        self.linkedVersion = linkedVersion
        self.optlinkedVersion = optlinkedVersion
        self.pinnedVersion = pinnedVersion
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case versions
        case linkedVersion = "linked_version"
        case optlinkedVersion = "optlinked_version"
        case pinnedVersion = "pinned_version"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        versions = JSONLenient.decodeStringArray(from: container, forKey: .versions) ?? []
        linkedVersion = JSONLenient.decodeString(from: container, forKey: .linkedVersion)
        optlinkedVersion = JSONLenient.decodeString(from: container, forKey: .optlinkedVersion)
        pinnedVersion = JSONLenient.decodeString(from: container, forKey: .pinnedVersion)
    }
}

/// Homebrew 7+ の `brew list --versions --json` レスポンス (Cask 行)
public struct BrewInstalledCaskVersions: Codable, Sendable {
    public let token: String
    public let versions: [String]
    public let pinnedVersion: String?

    public init(token: String, versions: [String], pinnedVersion: String? = nil) {
        self.token = token
        self.versions = versions
        self.pinnedVersion = pinnedVersion
    }

    private enum CodingKeys: String, CodingKey {
        case token
        case versions
        case pinnedVersion = "pinned_version"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        token = try container.decode(String.self, forKey: .token)
        versions = JSONLenient.decodeStringArray(from: container, forKey: .versions) ?? []
        pinnedVersion = JSONLenient.decodeString(from: container, forKey: .pinnedVersion)
    }
}

/// `brew list --versions --json` のレスポンス構造
public struct BrewInstalledVersionsResponse: Codable, Sendable {
    public let formulae: [BrewInstalledFormulaVersions]
    public let casks: [BrewInstalledCaskVersions]

    public init(
        formulae: [BrewInstalledFormulaVersions] = [],
        casks: [BrewInstalledCaskVersions] = []
    ) {
        self.formulae = formulae
        self.casks = casks
    }

    /// 既存の `BrewListResponse` / `Package` 変換ロジックと互換の形へ正規化する
    public func asBrewListResponse() -> BrewListResponse {
        let formulae = formulae.map { entry -> Formula in
            let installed = entry.versions.map {
                InstalledVersion(version: $0, installedOnRequest: true, installedAsDependency: false)
            }
            return Formula(
                id: entry.name,
                name: entry.name,
                fullName: entry.name,
                version: entry.linkedVersion ?? entry.optlinkedVersion ?? entry.versions.first,
                installed: installed,
                pinned: entry.pinnedVersion != nil
            )
        }
        let casks = casks.map { entry -> Cask in
            let installed = entry.versions.map {
                InstalledVersion(version: $0, installedOnRequest: true, installedAsDependency: false)
            }
            return Cask(
                id: entry.token,
                name: entry.token,
                fullName: entry.token,
                token: entry.token,
                version: entry.versions.first,
                installed: installed
            )
        }
        return BrewListResponse(formulae: formulae, casks: casks)
    }
}

/// `brew services list --json` の 1 行
public struct BrewManagedService: Codable, Sendable, Identifiable, Hashable {
    public let name: String
    public let status: String
    public let user: String?
    public let file: String?
    public let exitCode: Int?

    public var id: String {
        name
    }

    public init(
        name: String,
        status: String,
        user: String? = nil,
        file: String? = nil,
        exitCode: Int? = nil
    ) {
        self.name = PackageText.normalizeRequired(name)
        self.status = PackageText.normalizeRequired(status)
        self.user = PackageText.normalizeOptional(user)
        self.file = PackageText.normalizeOptional(file)
        self.exitCode = exitCode
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case status
        case user
        case file
        case exitCode = "exit_code"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = PackageText.normalizeRequired(JSONLenient.decodeString(from: container, forKey: .name) ?? "")
        status = PackageText.normalizeRequired(JSONLenient.decodeString(from: container, forKey: .status) ?? "unknown")
        user = JSONLenient.decodeString(from: container, forKey: .user)
        file = JSONLenient.decodeString(from: container, forKey: .file)
        exitCode = try container.decodeIfPresent(Int.self, forKey: .exitCode)
    }

    /// アップグレード前に `brew services stop` すべき状態か
    public var shouldStopBeforeUpgrade: Bool {
        status == "started" || status == "error"
    }
}

/// brew tap --json のレスポンス構造
public struct BrewTapResponse: Codable {
    public let taps: [Tap]

    public init(taps: [Tap]) {
        self.taps = taps
    }
}

/// パッケージの種類
public enum PackageType: Sendable {
    case formula
    case cask
}

/// パッケージの統一表現 (UI 表示用)
public struct Package: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let fullName: String
    public let type: PackageType
    public let desc: String?
    public let homepage: String?
    public let version: String?
    /// インストール済みのバージョン (`brew outdated` の `installed_versions` 等)
    public let installedVersion: String?
    public let isInstalled: Bool
    public let isOutdated: Bool
    public let isDeprecated: Bool
    public let dependencies: [String]?
    public let buildDependencies: [String]?
    public let license: String?
    public let formulaSourceURL: String?
    /// `brew info` の installed_on_request / installed_as_dependency 由来
    public let installedOnRequest: Bool?
    public let installedAsDependency: Bool?

    public init(
        id: String,
        name: String,
        fullName: String,
        type: PackageType,
        desc: String? = nil,
        homepage: String? = nil,
        version: String? = nil,
        installedVersion: String? = nil,
        isInstalled: Bool = false,
        isOutdated: Bool = false,
        isDeprecated: Bool = false,
        dependencies: [String]? = nil,
        buildDependencies: [String]? = nil,
        license: String? = nil,
        formulaSourceURL: String? = nil,
        installedOnRequest: Bool? = nil,
        installedAsDependency: Bool? = nil
    ) {
        self.id = PackageText.normalizeRequired(id)
        self.name = PackageText.normalizeRequired(name)
        self.fullName = PackageText.normalizeRequired(fullName)
        self.type = type
        self.desc = PackageText.normalizeOptional(desc)
        self.homepage = PackageText.normalizeOptional(homepage)
        self.version = PackageText.normalizeOptional(version)
        self.installedVersion = PackageText.normalizeOptional(installedVersion)
        self.isInstalled = isInstalled
        self.isOutdated = isOutdated
        self.isDeprecated = isDeprecated
        self.dependencies = dependencies
        self.buildDependencies = buildDependencies
        self.license = PackageText.normalizeOptional(license)
        self.formulaSourceURL = PackageText.normalizeOptional(formulaSourceURL)
        self.installedOnRequest = installedOnRequest
        self.installedAsDependency = installedAsDependency
    }

    /// `brew info` 風のインストール区分ラベル
    /// `List` 用の安定 ID (Formula / Cask と full_name の衝突を避ける)
    public var listRowID: String {
        let kind = type == .formula ? "formula" : "cask"
        return "\(kind)|\(id)|\(fullName)"
    }

    /// カタログ行の表示用メタデータを保ったまま、ローカルインストール状態だけ反映する
    public func mergingLocalInstall(from local: Package) -> Package {
        guard local.isInstalled else { return self }
        let resolvedVersion: String? = if local.isOutdated {
            local.version ?? version
        } else {
            version ?? local.version
        }
        return Package(
            id: id,
            name: name,
            fullName: fullName,
            type: type,
            desc: desc,
            homepage: homepage,
            version: resolvedVersion,
            installedVersion: local.installedVersion ?? installedVersion,
            isInstalled: true,
            isOutdated: local.isOutdated,
            isDeprecated: isDeprecated || local.isDeprecated,
            dependencies: dependencies ?? local.dependencies,
            buildDependencies: buildDependencies ?? local.buildDependencies,
            license: license ?? local.license,
            formulaSourceURL: formulaSourceURL ?? local.formulaSourceURL,
            installedOnRequest: local.installedOnRequest ?? installedOnRequest,
            installedAsDependency: local.installedAsDependency ?? installedAsDependency
        )
    }

    public var installationKindLabel: String? {
        guard isInstalled else { return nil }
        if installedAsDependency == true {
            return "Installed as dependency"
        }
        if installedOnRequest == true {
            return "Installed (on request)"
        }
        return nil
    }

    /// アップグレード先バージョン (`brew outdated` の `current_version` 等)
    public var upgradeTargetVersion: String? {
        guard isOutdated else { return version }
        if let version, let installedVersion, version != installedVersion {
            return version
        }
        return version
    }

    /// 一覧用 `Package` に `brew info` 由来の詳細をマージする (一覧側のインストール状態を優先)
    public func enriched(
        with detail: Package,
        dependencies: [String]? = nil,
        buildDependencies: [String]? = nil
    ) -> Package {
        let resolvedInstalled = installedVersion ?? detail.installedVersion
        let resolvedOutdated = isOutdated || detail.isOutdated
        let resolvedVersion = Self.mergedLatestVersion(
            listVersion: version,
            detailVersion: detail.version,
            installedVersion: resolvedInstalled,
            isOutdated: resolvedOutdated
        )

        return Package(
            id: id,
            name: name,
            fullName: detail.fullName.isEmpty ? fullName : detail.fullName,
            type: type,
            desc: detail.desc ?? desc,
            homepage: detail.homepage ?? homepage,
            version: resolvedVersion,
            installedVersion: resolvedInstalled,
            isInstalled: isInstalled || detail.isInstalled,
            isOutdated: isOutdated || detail.isOutdated,
            isDeprecated: isDeprecated || detail.isDeprecated,
            dependencies: dependencies ?? detail.dependencies,
            buildDependencies: buildDependencies ?? detail.buildDependencies,
            license: detail.license ?? license,
            formulaSourceURL: detail.formulaSourceURL ?? formulaSourceURL,
            installedOnRequest: installedOnRequest ?? detail.installedOnRequest,
            installedAsDependency: installedAsDependency ?? detail.installedAsDependency
        )
    }

    private static func mergedLatestVersion(
        listVersion: String?,
        detailVersion: String?,
        installedVersion: String?,
        isOutdated: Bool
    ) -> String? {
        if isOutdated,
           let listVersion,
           let installedVersion,
           listVersion != installedVersion
        {
            return listVersion
        }
        return detailVersion ?? listVersion
    }

    /// BrewManager の一覧状態に合わせて表示用フィールドを更新する
    public func withListPresentation(from list: Package, isOutdated: Bool) -> Package {
        let installedVersion = list.installedVersion ?? installedVersion
        let version: String? = if isOutdated {
            Self.mergedLatestVersion(
                listVersion: list.version,
                detailVersion: self.version,
                installedVersion: installedVersion,
                isOutdated: true
            )
        } else {
            installedVersion ?? list.version ?? self.version
        }

        return Package(
            id: id,
            name: name,
            fullName: fullName,
            type: type,
            desc: desc,
            homepage: homepage,
            version: version,
            installedVersion: installedVersion,
            isInstalled: true,
            isOutdated: isOutdated,
            isDeprecated: isDeprecated,
            dependencies: dependencies,
            buildDependencies: buildDependencies,
            license: license,
            formulaSourceURL: formulaSourceURL,
            installedOnRequest: installedOnRequest ?? list.installedOnRequest,
            installedAsDependency: installedAsDependency ?? list.installedAsDependency
        )
    }

    /// Formula から Package を作成
    public static func from(_ formula: Formula) -> Package {
        let installedVersions = formula.installed?.map(\.version) ?? []
        let primaryInstall = formula.installed?.first
        return Package(
            id: formula.id,
            name: formula.name,
            fullName: formula.fullName,
            type: .formula,
            desc: formula.desc,
            homepage: formula.homepage,
            version: formula.version,
            installedVersion: installedVersions.first,
            isInstalled: !installedVersions.isEmpty,
            isOutdated: formula.outdated ?? false,
            isDeprecated: formula.deprecated ?? false,
            license: formula.license,
            formulaSourceURL: HomebrewMetadata.formulaSourceURL(
                tap: formula.tap,
                rubySourcePath: formula.rubySourcePath
            ),
            installedOnRequest: primaryInstall?.installedOnRequest,
            installedAsDependency: primaryInstall?.installedAsDependency
        )
    }

    /// Cask から Package を作成
    public static func from(_ cask: Cask) -> Package {
        let installedVersions = cask.installed?.map(\.version) ?? []
        return Package(
            id: cask.id,
            name: cask.name,
            fullName: cask.fullName,
            type: .cask,
            desc: cask.desc,
            homepage: cask.homepage,
            version: cask.version,
            installedVersion: installedVersions.first,
            isInstalled: !installedVersions.isEmpty,
            isOutdated: cask.outdated ?? false,
            isDeprecated: cask.deprecated ?? false
        )
    }

    /// `brew formulae` / `brew casks` の名前のみから一覧用スタブを作る
    public static func catalogStub(name: String, type: PackageType) -> Package {
        let displayName = name.split(separator: "/").last.map(String.init) ?? name
        return Package(
            id: name,
            name: displayName,
            fullName: name,
            type: type,
            isInstalled: false
        )
    }
}
