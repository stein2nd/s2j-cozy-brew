import Foundation

/// CozyBrew が記録する操作履歴 (インストール・Tap 等)
public struct BrewOperationRecord: Codable, Identifiable, Sendable, Hashable {
    public enum Kind: String, Codable, Sendable {
        case install
        case uninstall
        case upgrade
        case upgradeAll
        case tap
        case untap
        case migration
    }

    public let id: UUID
    public let date: Date
    public let kind: Kind
    public let title: String
    public let detail: String?

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        kind: Kind,
        title: String,
        detail: String? = nil
    ) {
        self.id = id
        self.date = date
        self.kind = kind
        self.title = title
        self.detail = detail
    }
}

/// `Application Support` 配下に JSON で永続化する操作履歴ストア
public struct BrewOperationHistoryStore: Sendable {
    private static let maxEntries = 500
    private let fileURL: URL

    public init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            let directory = base.appendingPathComponent("S2JCozyBrew", isDirectory: true)
            self.fileURL = directory.appendingPathComponent("operation-history.json")
        }
    }

    public func load() -> [BrewOperationRecord] {
        guard let data = try? Data(contentsOf: fileURL) else {
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let records = try? decoder.decode([BrewOperationRecord].self, from: data) else {
            return []
        }
        return records.sorted { $0.date > $1.date }
    }

    public func save(_ records: [BrewOperationRecord]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let trimmed = Array(records.sorted { $0.date > $1.date }.prefix(Self.maxEntries))
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(trimmed)
        try data.write(to: fileURL, options: [.atomic])
    }

    public func append(
        _ record: BrewOperationRecord,
        to existing: [BrewOperationRecord]
    ) throws -> [BrewOperationRecord] {
        let next = [record] + existing
        try save(next)
        return load()
    }

    public func mergeCakebrewImported(
        _ imported: [BrewOperationRecord],
        into existing: [BrewOperationRecord]
    ) throws -> [BrewOperationRecord] {
        let existingIDs = Set(existing.map(\.id))
        let novel = imported.filter { !existingIDs.contains($0.id) }
        var next = novel + existing
        next.sort { $0.date > $1.date }
        try save(next)
        return load()
    }
}
