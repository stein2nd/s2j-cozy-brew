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
}

/// Formula（ソースからビルドするパッケージ）
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
        disableReason: String? = nil
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
    }
}

/// Cask（バイナリ配布パッケージ）
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
}

/// Tap（リポジトリ）
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

/// brew tap --json のレスポンス構造
public struct BrewTapResponse: Codable {
    public let taps: [Tap]
    
    public init(taps: [Tap]) {
        self.taps = taps
    }
}

/// パッケージの種類
public enum PackageType {
    case formula
    case cask
}

/// パッケージの統一表現（UI 表示用）
public struct Package: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let fullName: String
    public let type: PackageType
    public let desc: String?
    public let homepage: String?
    public let version: String?
    public let isInstalled: Bool
    public let isOutdated: Bool
    public let isDeprecated: Bool
    
    public init(
        id: String,
        name: String,
        fullName: String,
        type: PackageType,
        desc: String? = nil,
        homepage: String? = nil,
        version: String? = nil,
        isInstalled: Bool = false,
        isOutdated: Bool = false,
        isDeprecated: Bool = false
    ) {
        self.id = id
        self.name = name
        self.fullName = fullName
        self.type = type
        self.desc = desc
        self.homepage = homepage
        self.version = version
        self.isInstalled = isInstalled
        self.isOutdated = isOutdated
        self.isDeprecated = isDeprecated
    }
    
    /// Formula から Package を作成
    public static func from(_ formula: Formula) -> Package {
        Package(
            id: formula.id,
            name: formula.name,
            fullName: formula.fullName,
            type: .formula,
            desc: formula.desc,
            homepage: formula.homepage,
            version: formula.version,
            isInstalled: formula.installed != nil && !formula.installed!.isEmpty,
            isOutdated: formula.outdated ?? false,
            isDeprecated: formula.deprecated ?? false
        )
    }
    
    /// Cask から Package を作成
    public static func from(_ cask: Cask) -> Package {
        Package(
            id: cask.id,
            name: cask.name,
            fullName: cask.fullName,
            type: .cask,
            desc: cask.desc,
            homepage: cask.homepage,
            version: cask.version,
            isInstalled: cask.installed != nil && !cask.installed!.isEmpty,
            isOutdated: cask.outdated ?? false,
            isDeprecated: cask.deprecated ?? false
        )
    }
}
