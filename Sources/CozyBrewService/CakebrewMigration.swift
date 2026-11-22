import Foundation

/// 検出した Cakebrew (`com.brunophilipe.Cakebrew`) のレガシー設定
public struct CakebrewLegacyPreferences: Sendable {
    public let plistURL: URL
    public let shortVersion: String?
    public let historyLines: [String]

    public init(plistURL: URL, shortVersion: String?, historyLines: [String]) {
        self.plistURL = plistURL
        self.shortVersion = shortVersion
        self.historyLines = historyLines
    }
}

/// Cakebrew からのオプション移行 (設定検出・履歴の取り込み)
public enum CakebrewMigration {
    public static let preferencesRelativePath = "Library/Preferences/com.brunophilipe.Cakebrew.plist"
    public static let cozyBrewUserDefaultsSuite = "dev.s2j.cozybrew"
    private static let migrationCompletedKey = "cakebrew.migration.completed"

    public static func legacyPreferencesURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(preferencesRelativePath)
    }

    public static func detectLegacyPreferences() -> CakebrewLegacyPreferences? {
        let url = legacyPreferencesURL()
        guard FileManager.default.isReadableFile(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else {
            return nil
        }

        let shortVersion = plist["CFBundleShortVersionString"] as? String
        let history = extractHistoryLines(from: plist)
        return CakebrewLegacyPreferences(plistURL: url, shortVersion: shortVersion, historyLines: history)
    }

    public static func hasCompletedMigration() -> Bool {
        UserDefaults(suiteName: cozyBrewUserDefaultsSuite)?.bool(forKey: migrationCompletedKey) == true
    }

    public static func markMigrationCompleted() {
        let defaults = UserDefaults(suiteName: cozyBrewUserDefaultsSuite) ?? .standard
        defaults.set(true, forKey: migrationCompletedKey)
    }

    public static func importLegacy(
        _ legacy: CakebrewLegacyPreferences,
        historyStore: BrewOperationHistoryStore = BrewOperationHistoryStore()
    ) throws -> [BrewOperationRecord] {
        var imported: [BrewOperationRecord] = []
        let versionLabel = legacy.shortVersion.map { " (v\($0))" } ?? ""

        imported.append(
            BrewOperationRecord(
                kind: .migration,
                title: "Imported Cakebrew preferences\(versionLabel)",
                detail: legacy.plistURL.path
            )
        )

        for line in legacy.historyLines {
            imported.append(
                BrewOperationRecord(
                    kind: .migration,
                    title: line,
                    detail: "From Cakebrew"
                )
            )
        }

        let current = historyStore.load()
        return try historyStore.mergeCakebrewImported(imported, into: current)
    }

    private static func extractHistoryLines(from plist: [String: Any]) -> [String] {
        for (key, value) in plist {
            let lowered = key.lowercased()
            guard lowered.contains("history") || lowered.contains("log") else { continue }
            if let lines = value as? [String] {
                return lines.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            }
            if let text = value as? String, !text.isEmpty {
                return text
                    .split(separator: "\n", omittingEmptySubsequences: true)
                    .map(String.init)
            }
        }
        return []
    }
}
