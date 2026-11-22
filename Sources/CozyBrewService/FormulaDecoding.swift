import Foundation

/// `Formula` の `Decodable` 補助 (`Models.swift` の行数制限のため分割)
enum FormulaDecoding {
    typealias InstalledFields = (kegRecords: [FormulaInstalledKegRecord]?, versions: [InstalledVersion]?)

    static func installedFields(
        from container: KeyedDecodingContainer<Formula.CodingKeys>,
        outdatedContainer: KeyedDecodingContainer<Formula.OutdatedJSONKeys>
    ) -> InstalledFields {
        var decodedKegRecords: [FormulaInstalledKegRecord]?
        if let kegRecords = try? container.decode([FormulaInstalledKegRecord].self, forKey: .installed) {
            decodedKegRecords = kegRecords
        }

        var decodedInstalled: [InstalledVersion]?
        if let kegRecords = decodedKegRecords, !kegRecords.isEmpty {
            decodedInstalled = kegRecords.map { $0.asInstalledVersion() }
        }
        if decodedInstalled == nil,
           let installedArray = try? container.decode([InstalledVersion].self, forKey: .installed)
        {
            decodedInstalled = installedArray
        }
        if decodedInstalled == nil,
           let versionStrings = JSONLenient.decodeStringArray(from: outdatedContainer, forKey: .installedVersions)
        {
            decodedInstalled = versionStrings.map {
                InstalledVersion(version: $0, installedOnRequest: true, installedAsDependency: false)
            }
        }
        return (decodedKegRecords, decodedInstalled)
    }

    static func license(from container: KeyedDecodingContainer<Formula.CodingKeys>) -> String? {
        if let licenseString = try? container.decodeIfPresent(String.self, forKey: .license) {
            return licenseString
        }
        if let licenseList = try? container.decodeIfPresent([String].self, forKey: .license) {
            return licenseList.joined(separator: " AND ")
        }
        return nil
    }
}
