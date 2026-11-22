import Foundation

/// `brew tap-info <tap> --json` の 1 行 (v1)
public struct BrewTapInfoRecord: Codable, Sendable {
    public let name: String
    public let formulaNames: [String]?
    public let caskTokens: [String]?

    public init(name: String, formulaNames: [String]? = nil, caskTokens: [String]? = nil) {
        self.name = name
        self.formulaNames = formulaNames
        self.caskTokens = caskTokens
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case formulaNames = "formula_names"
        case caskTokens = "cask_tokens"
    }
}

/// untap 確認ダイアログ用の要約
public struct TapRemovalSummary: Sendable, Equatable {
    public let formulaCount: Int
    public let caskCount: Int
    public let installedNames: [String]

    public init(formulaCount: Int, caskCount: Int, installedNames: [String]) {
        self.formulaCount = formulaCount
        self.caskCount = caskCount
        self.installedNames = installedNames
    }
}

public enum BrewTapInfo {
    /// `brew tap-info` の JSON をパースし、インストール済みパッケージと照合する
    public static func removalSummary(
        record: BrewTapInfoRecord,
        installedPackages: [Package]
    ) -> TapRemovalSummary {
        let formulaNames = record.formulaNames ?? []
        let caskTokens = record.caskTokens ?? []
        let installedSet = Set(installedPackages.map(\.fullName))
        let installedFromTap = (formulaNames + caskTokens).filter { installedSet.contains($0) }
        return TapRemovalSummary(
            formulaCount: formulaNames.count,
            caskCount: caskTokens.count,
            installedNames: installedFromTap.sorted()
        )
    }
}
