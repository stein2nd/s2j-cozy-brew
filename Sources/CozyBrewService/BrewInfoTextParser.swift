import Foundation

/// `brew info` のプレーンテキストから、JSON に無いセクションを抽出する
public enum BrewInfoTextParser {
    public struct ParsedSections: Sendable, Hashable {
        public let installedKegLines: [String]
        public let optionLines: [BrewInfoOptionLine]
        public let analyticsLines: [String]

        public init(
            installedKegLines: [String] = [],
            optionLines: [BrewInfoOptionLine] = [],
            analyticsLines: [String] = []
        ) {
            self.installedKegLines = installedKegLines
            self.optionLines = optionLines
            self.analyticsLines = analyticsLines
        }
    }

    public struct BrewInfoOptionLine: Sendable, Hashable {
        public let flag: String
        public let description: String

        public init(flag: String, description: String) {
            self.flag = flag
            self.description = description
        }
    }

    /// `brew info` 標準出力をパースする
    public static func parse(stdout: String) -> ParsedSections {
        let lines = stdout
            .split(whereSeparator: \.isNewline)
            .map { String($0) }

        let installed = sectionBody(
            in: lines,
            headers: ["==> Installed Kegs and Versions", "==> Installed Versions", "==> Installed Kegs"]
        )
        let options = parseOptions(sectionBody(in: lines, headers: ["==> Options"]))
        let analytics = sectionBody(in: lines, headers: ["==> Analytics"])

        return ParsedSections(
            installedKegLines: installed,
            optionLines: options,
            analyticsLines: analytics
        )
    }

    private static func sectionBody(in lines: [String], headers: [String]) -> [String] {
        guard let startIndex = lines.firstIndex(where: { line in
            headers.contains(where: { line.hasPrefix($0) })
        }) else {
            return []
        }
        var body: [String] = []
        for index in lines.index(after: startIndex) ..< lines.count {
            let line = lines[index]
            if line.hasPrefix("==> ") {
                break
            }
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                continue
            }
            body.append(trimmed)
        }
        return body
    }

    private static func parseOptions(_ lines: [String]) -> [BrewInfoOptionLine] {
        var options: [BrewInfoOptionLine] = []
        var index = 0
        while index < lines.count {
            let flag = lines[index].trimmingCharacters(in: .whitespacesAndNewlines)
            if flag.hasPrefix("--") {
                let nextLine = index + 1 < lines.count ? lines[index + 1] : ""
                let next = nextLine.trimmingCharacters(in: .whitespacesAndNewlines)
                if !next.isEmpty, !next.hasPrefix("--") {
                    options.append(BrewInfoOptionLine(flag: flag, description: next))
                    index += 2
                    continue
                }
                options.append(BrewInfoOptionLine(flag: flag, description: ""))
            }
            index += 1
        }
        return options
    }
}

/// パッケージ詳細の CLI 寄せ表示 (`brew info` 補完)
public struct PackageInfoExtras: Sendable, Hashable {
    public let versionSummary: String?
    public let installedKegLines: [String]
    public let options: [BrewInfoTextParser.BrewInfoOptionLine]
    public let runtimeDependencies: [BrewRuntimeDependencyLine]
    public let analyticsLines: [String]

    public init(
        versionSummary: String? = nil,
        installedKegLines: [String] = [],
        options: [BrewInfoTextParser.BrewInfoOptionLine] = [],
        runtimeDependencies: [BrewRuntimeDependencyLine] = [],
        analyticsLines: [String] = []
    ) {
        self.versionSummary = versionSummary
        self.installedKegLines = installedKegLines
        self.options = options
        self.runtimeDependencies = runtimeDependencies
        self.analyticsLines = analyticsLines
    }
}

public struct BrewRuntimeDependencyLine: Sendable, Hashable {
    public let name: String
    public let isInstalled: Bool
    public let declaredDirectly: Bool

    public init(name: String, isInstalled: Bool, declaredDirectly: Bool) {
        self.name = name
        self.isInstalled = isInstalled
        self.declaredDirectly = declaredDirectly
    }
}

public enum PackageInfoExtrasBuilder {
    public static func versionSummary(from versions: BrewFormulaVersions?) -> String? {
        guard let versions else { return nil }
        var parts: [String] = []
        if let stable = versions.stable, !stable.isEmpty {
            var segment = "stable \(stable)"
            if versions.bottle == true {
                segment += " (bottled)"
            }
            parts.append(segment)
        }
        if let head = versions.head, !head.isEmpty {
            parts.append(head)
        }
        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: ", ")
    }

    public static func runtimeLines(
        from records: [FormulaRuntimeDependency],
        installedNames: Set<String>
    ) -> [BrewRuntimeDependencyLine] {
        records.map { dep in
            BrewRuntimeDependencyLine(
                name: dep.fullName,
                isInstalled: installedNames.contains(dep.fullName),
                declaredDirectly: dep.declaredDirectly ?? false
            )
        }
    }

    public static func mergeInstalledKegLines(
        textLines: [String],
        formulaName: String,
        linkedKeg: String?,
        installedVersions: [String]
    ) -> [String] {
        if !textLines.isEmpty {
            return textLines
        }
        guard !installedVersions.isEmpty else { return [] }
        return installedVersions.map { version in
            let linked = linkedKeg == version ? " [Linked]" : ""
            return "\(formulaName) \(version)\(linked)"
        }
    }
}

/// `brew info --json=v2` の `versions` オブジェクト
public struct BrewFormulaVersions: Codable, Sendable, Hashable {
    public let stable: String?
    public let head: String?
    public let bottle: Bool?

    public init(stable: String? = nil, head: String? = nil, bottle: Bool? = nil) {
        self.stable = stable
        self.head = head
        self.bottle = bottle
    }

    private enum CodingKeys: String, CodingKey {
        case stable
        case head
        case bottle
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stable = JSONLenient.decodeString(from: container, forKey: .stable)
        head = JSONLenient.decodeString(from: container, forKey: .head)
        bottle = try container.decodeIfPresent(Bool.self, forKey: .bottle)
    }
}

/// インストール済み Keg 行の runtime 依存 (JSON)
public struct FormulaRuntimeDependency: Codable, Sendable, Hashable {
    public let fullName: String
    public let declaredDirectly: Bool?

    private enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case declaredDirectly = "declared_directly"
    }

    public init(fullName: String, declaredDirectly: Bool? = nil) {
        self.fullName = fullName
        self.declaredDirectly = declaredDirectly
    }
}

/// `brew info` の `installed[]` 1 行 (runtime_dependencies を含む)
public struct FormulaInstalledKegRecord: Codable, Sendable {
    public let version: String
    public let installedOnRequest: Bool?
    public let installedAsDependency: Bool?
    public let runtimeDependencies: [FormulaRuntimeDependency]?

    private enum CodingKeys: String, CodingKey {
        case version
        case installedOnRequest = "installed_on_request"
        case installedAsDependency = "installed_as_dependency"
        case runtimeDependencies = "runtime_dependencies"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = JSONLenient.decodeString(from: container, forKey: .version) ?? ""
        installedOnRequest = try container.decodeIfPresent(Bool.self, forKey: .installedOnRequest)
        installedAsDependency = try container.decodeIfPresent(Bool.self, forKey: .installedAsDependency)
        runtimeDependencies = try container.decodeIfPresent(
            [FormulaRuntimeDependency].self,
            forKey: .runtimeDependencies
        )
    }

    public func asInstalledVersion() -> InstalledVersion {
        InstalledVersion(
            version: version,
            installedOnRequest: installedOnRequest ?? false,
            installedAsDependency: installedAsDependency ?? false
        )
    }
}
