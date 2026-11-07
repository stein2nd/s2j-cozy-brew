import Foundation

/// Formulae / Casks カタログの先頭文字によるページ
public enum CatalogPageRange: String, CaseIterable, Identifiable, Sendable {
    case aThroughE = "A – E"
    case fThroughJ = "F – J"
    case kThroughO = "K – O"
    case pThroughT = "P – T"
    case uThroughZ = "U – Z"
    case oneThroughFive = "1 – 5"
    case sixThroughZero = "6 – 0"

    public var id: String {
        rawValue
    }

    public func matches(_ package: Package) -> Bool {
        Self.page(for: package) == self
    }

    public static func page(for package: Package) -> CatalogPageRange? {
        guard let character = bucketCharacter(for: package) else { return nil }
        return CatalogPageRange.allCases.first { $0.contains(character) }
    }

    private func contains(_ character: Character) -> Bool {
        if let scalar = character.unicodeScalars.first, CharacterSet.decimalDigits.contains(scalar) {
            switch self {
            case .oneThroughFive:
                return ["1", "2", "3", "4", "5"].contains(String(character))
            case .sixThroughZero:
                return ["6", "7", "8", "9", "0"].contains(String(character))
            default:
                return false
            }
        }
        guard let letter = character.unicodeScalars.first,
              CharacterSet.letters.contains(letter)
        else {
            return false
        }
        let upper = String(character).uppercased()
        guard let code = upper.unicodeScalars.first?.value,
              (65 ... 90).contains(code)
        else {
            return false
        }
        switch self {
        case .aThroughE: return (65 ... 69).contains(code)
        case .fThroughJ: return (70 ... 74).contains(code)
        case .kThroughO: return (75 ... 79).contains(code)
        case .pThroughT: return (80 ... 84).contains(code)
        case .uThroughZ: return (85 ... 90).contains(code)
        case .oneThroughFive, .sixThroughZero: return false
        }
    }

    private static func bucketCharacter(for package: Package) -> Character? {
        firstBucketCharacter(in: package.name) ?? firstBucketCharacter(in: package.fullName)
    }

    private static func firstBucketCharacter(in text: String) -> Character? {
        for scalar in text.unicodeScalars {
            if CharacterSet.letters.contains(scalar) || CharacterSet.decimalDigits.contains(scalar) {
                return Character(scalar)
            }
        }
        return nil
    }
}

/// formulae.brew.sh カタログとローカルインストール状態の合成
public enum BrewCatalog {
    public static func packages(from formulae: [Formula]) -> [Package] {
        formulae.map { Package.from($0) }
    }

    public static func packages(from casks: [Cask]) -> [Package] {
        casks.map { Package.from($0) }
    }

    /// カタログ行に、ローカル `brew list` 由来のインストール情報を反映する (名前で照合)
    public static func overlayLocalInstalled(
        _ catalog: [Package],
        installed: [Package],
        type: PackageType
    ) -> [Package] {
        let localByKey = localPackageLookup(installed.filter { $0.type == type })
        return catalog.map { item in
            guard let local = localByKey[item.name]
                ?? localByKey[item.fullName]
                ?? localByKey[item.id]
            else {
                return item
            }
            return item.mergingLocalInstall(from: local)
        }
    }

    public static func sortedByName(_ packages: [Package]) -> [Package] {
        packages.sorted {
            $0.name.lowercased() < $1.name.lowercased()
        }
    }

    /// カタログをページ別に分割 (一覧は 1 ページ分だけ UI に渡す)
    public static func partitionByPage(_ packages: [Package]) -> [CatalogPageRange: [Package]] {
        var buckets: [CatalogPageRange: [Package]] = [:]
        for range in CatalogPageRange.allCases {
            buckets[range] = []
        }
        for package in packages {
            guard let page = CatalogPageRange.page(for: package) else { continue }
            buckets[page, default: []].append(package)
        }
        for range in CatalogPageRange.allCases {
            buckets[range] = sortedByName(buckets[range] ?? [])
        }
        return buckets
    }

    private static func localPackageLookup(_ packages: [Package]) -> [String: Package] {
        var map: [String: Package] = [:]
        for package in packages {
            map[package.name] = package
            map[package.fullName] = package
            map[package.id] = package
        }
        return map
    }
}
