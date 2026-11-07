import Foundation

/// formulae.brew.sh カタログ JSON を `NSDictionary` 経由で安全にパースする (NSNumber → String)
enum BrewCatalogAPIParsing {
    static func packagesFromFormulaCatalog(_ data: Data) throws -> [Package] {
        let rows = try jsonObjectArray(from: data)
        var packages: [Package] = []
        packages.reserveCapacity(rows.count)
        for row in rows {
            guard let package = parseFormulaRow(row) else { continue }
            packages.append(package)
        }
        return packages
    }

    static func packagesFromCaskCatalog(_ data: Data) throws -> [Package] {
        let rows = try jsonObjectArray(from: data)
        var packages: [Package] = []
        packages.reserveCapacity(rows.count)
        for row in rows {
            guard let package = parseCaskRow(row) else { continue }
            packages.append(package)
        }
        return packages
    }

    private static func jsonObjectArray(from data: Data) throws -> [[String: Any]] {
        let object = try JSONSerialization.jsonObject(with: data)
        guard let array = object as? [[String: Any]] else {
            throw BrewFormulaeAPIClient.FetchError.invalidResponse
        }
        return array
    }

    private static func parseFormulaRow(_ row: [String: Any]) -> Package? {
        guard let name = anyToString(row["name"]), !name.isEmpty else { return nil }
        let fullName = anyToString(row["full_name"]) ?? name
        let versions = row["versions"] as? [String: Any]
        let stable = anyToString(versions?["stable"])
        return Package(
            id: name,
            name: name,
            fullName: fullName,
            type: .formula,
            desc: PackageText.normalizeOptional(anyToString(row["desc"])),
            homepage: PackageText.normalizeOptional(anyToString(row["homepage"])),
            version: PackageText.normalizeOptional(stable),
            isInstalled: false,
            isDeprecated: anyToBool(row["deprecated"]) ?? false,
            license: anyToLicenseString(row["license"]),
            formulaSourceURL: HomebrewMetadata.formulaSourceURL(
                tap: anyToString(row["tap"]),
                rubySourcePath: anyToString(row["ruby_source_path"])
            )
        )
    }

    private static func parseCaskRow(_ row: [String: Any]) -> Package? {
        let token = anyToString(row["token"])
        let name: String? = if let names = row["name"] as? [Any] {
            names.compactMap { anyToString($0) }.first
        } else {
            anyToString(row["name"])
        }
        guard let resolvedName = name ?? token, !resolvedName.isEmpty else { return nil }
        let fullName = anyToString(row["full_name"]) ?? anyToString(row["full_token"]) ?? resolvedName
        return Package(
            id: token ?? resolvedName,
            name: resolvedName,
            fullName: fullName,
            type: .cask,
            desc: anyToString(row["desc"]),
            homepage: anyToString(row["homepage"]),
            version: anyToString(row["version"]),
            isInstalled: false,
            isDeprecated: anyToBool(row["deprecated"]) ?? false
        )
    }

    static func anyToString(_ value: Any?) -> String? {
        switch value {
        case let string as String:
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        case let number as NSNumber:
            return number.stringValue
        case let int as Int:
            return String(int)
        case let double as Double:
            if double.rounded(.towardZero) == double {
                return String(Int(double))
            }
            return String(double)
        case let bool as Bool:
            return bool ? "true" : "false"
        case let array as [Any]:
            return array.compactMap { anyToString($0) }.first
        default:
            return nil
        }
    }

    private static func anyToBool(_ value: Any?) -> Bool? {
        switch value {
        case let flag as Bool:
            flag
        case let number as NSNumber:
            number.boolValue
        default:
            nil
        }
    }

    private static func anyToLicenseString(_ value: Any?) -> String? {
        switch value {
        case let string as String:
            return string
        case let array as [Any]:
            let joined = array.compactMap { anyToString($0) }.joined(separator: " AND ")
            return joined.isEmpty ? nil : joined
        default:
            return anyToString(value)
        }
    }
}
