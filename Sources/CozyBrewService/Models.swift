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
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // `id` は API から返らないため `name` で代用する
        self.id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? container.decode(String.self, forKey: .name)
        self.name = try container.decode(String.self, forKey: .name)
        self.fullName = try container.decodeIfPresent(String.self, forKey: .fullName) ?? name
        self.desc = try container.decodeIfPresent(String.self, forKey: .desc)
        self.homepage = try container.decodeIfPresent(String.self, forKey: .homepage)
        self.version = try container.decodeIfPresent(String.self, forKey: .version)
        self.installed = try container.decodeIfPresent([InstalledVersion].self, forKey: .installed)
        self.dependencies = try container.decodeIfPresent([String].self, forKey: .dependencies)
        self.buildDependencies = try container.decodeIfPresent([String].self, forKey: .buildDependencies)
        self.conflictsWith = try container.decodeIfPresent([String].self, forKey: .conflictsWith)
        self.pinned = try container.decodeIfPresent(Bool.self, forKey: .pinned)
        self.outdated = try container.decodeIfPresent(Bool.self, forKey: .outdated)
        self.deprecated = try container.decodeIfPresent(Bool.self, forKey: .deprecated)
        self.deprecationReason = try container.decodeIfPresent(String.self, forKey: .deprecationReason)
        self.disabled = try container.decodeIfPresent(Bool.self, forKey: .disabled)
        self.disableReason = try container.decodeIfPresent(String.self, forKey: .disableReason)
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // `id` は存在しないため token を優先、無ければ name の先頭を使用する
        let decodedToken = try container.decodeIfPresent(String.self, forKey: .token)
        let decodedNameArray = try container.decodeIfPresent([String].self, forKey: .name)
        let decodedName = try container.decodeIfPresent(String.self, forKey: .name)
            ?? decodedNameArray?.first
            ?? ""

        self.id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? decodedToken
            ?? decodedName
        self.token = decodedToken ?? decodedName
        self.name = decodedName
        self.fullName = try container.decodeIfPresent(String.self, forKey: .fullName) ?? decodedName
        self.desc = try container.decodeIfPresent(String.self, forKey: .desc)
        self.homepage = try container.decodeIfPresent(String.self, forKey: .homepage)
        self.version = try container.decodeIfPresent(String.self, forKey: .version)
        self.installed = try container.decodeIfPresent([InstalledVersion].self, forKey: .installed)
        self.outdated = try container.decodeIfPresent(Bool.self, forKey: .outdated)
        self.deprecated = try container.decodeIfPresent(Bool.self, forKey: .deprecated)
        self.deprecationReason = try container.decodeIfPresent(String.self, forKey: .deprecationReason)
        self.disabled = try container.decodeIfPresent(Bool.self, forKey: .disabled)
        self.disableReason = try container.decodeIfPresent(String.self, forKey: .disableReason)
        self.appcast = try container.decodeIfPresent(String.self, forKey: .appcast)
        self.url = try container.decodeIfPresent(String.self, forKey: .url)
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
