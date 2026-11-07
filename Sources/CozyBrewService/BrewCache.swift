import Foundation

/// キャッシュ管理機構
public final class BrewCache {
    private let cacheDirectory: URL
    private let fileManager = FileManager.default
    private let defaultTTL: TimeInterval = 3600 // 1時間

    /// キャッシュキー
    public enum CacheKey: String {
        case installedFormulae = "installed_formulae.json"
        case installedCasks = "installed_casks.json"
        case outdatedFormulae = "outdated_formulae.json"
        case outdatedCasks = "outdated_casks.json"
        case taps = "taps.json"
        case catalogFormulaeAPIJSON = "catalog_formulae_api.json"
        case catalogCasksAPIJSON = "catalog_casks_api.json"
        case searchResults = "search_results"
    }

    /// 初期化
    /// - Parameter cacheDirectory: キャッシュディレクトリ。nil の場合はデフォルトを使用
    public init(cacheDirectory: URL? = nil) {
        if let cacheDirectory {
            self.cacheDirectory = cacheDirectory
        } else {
            let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.cacheDirectory = appSupport.appendingPathComponent("com.s2j.CozyBrew", isDirectory: true)
        }

        // キャッシュディレクトリを作成
        try? fileManager.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)
    }

    /// 生 JSON 等を保存する (カタログ API 用)
    public func saveData(_ data: Data, forKey key: CacheKey) throws {
        let url = cacheDirectory.appendingPathComponent(key.rawValue)
        try data.write(to: url, options: .atomic)
        let metadata = CacheMetadata(timestamp: Date())
        let metadataURL = cacheDirectory.appendingPathComponent("\(key.rawValue).meta")
        let metadataData = try JSONEncoder().encode(metadata)
        try metadataData.write(to: metadataURL)
    }

    public func loadData(forKey key: CacheKey, ttl: TimeInterval? = nil) -> Data? {
        let url = cacheDirectory.appendingPathComponent(key.rawValue)
        let metadataURL = cacheDirectory.appendingPathComponent("\(key.rawValue).meta")
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        if let metadataData = try? Data(contentsOf: metadataURL),
           let metadata = try? JSONDecoder().decode(CacheMetadata.self, from: metadataData)
        {
            let ttlValue = ttl ?? defaultTTL
            if Date().timeIntervalSince(metadata.timestamp) > ttlValue {
                try? fileManager.removeItem(at: url)
                try? fileManager.removeItem(at: metadataURL)
                return nil
            }
        }
        return try? Data(contentsOf: url)
    }

    /// キャッシュを保存する
    /// - Parameters:
    ///   - data: 保存するデータ
    ///   - key: キャッシュキー
    public func save(_ data: some Codable, forKey key: CacheKey) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encoded = try encoder.encode(data)
        let url = cacheDirectory.appendingPathComponent(key.rawValue)
        try encoded.write(to: url)

        // メタデータ (タイムスタンプ) を保存
        let metadata = CacheMetadata(timestamp: Date())
        let metadataURL = cacheDirectory.appendingPathComponent("\(key.rawValue).meta")
        let metadataData = try JSONEncoder().encode(metadata)
        try metadataData.write(to: metadataURL)
    }

    /// キャッシュを読み込む
    /// - Parameters:
    ///   - type: データ型
    ///   - key: キャッシュキー
    ///   - ttl: 有効期限 (秒)。nil の場合はデフォルト TTL を使用
    /// - Returns: キャッシュされたデータ。見つからないか期限切れの場合は nil
    public func load<T: Codable>(_: T.Type, forKey key: CacheKey, ttl: TimeInterval? = nil) throws -> T? {
        let url = cacheDirectory.appendingPathComponent(key.rawValue)
        let metadataURL = cacheDirectory.appendingPathComponent("\(key.rawValue).meta")

        // ファイルが存在するか確認
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        // メタデータを確認 (TTL チェック)
        if let metadataData = try? Data(contentsOf: metadataURL),
           let metadata = try? JSONDecoder().decode(CacheMetadata.self, from: metadataData)
        {
            let ttlValue = ttl ?? defaultTTL
            if Date().timeIntervalSince(metadata.timestamp) > ttlValue {
                // 期限切れ
                try? fileManager.removeItem(at: url)
                try? fileManager.removeItem(at: metadataURL)
                return nil
            }
        }

        // データを読み込む
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(T.self, from: data)
    }

    /// キャッシュを削除する
    /// - Parameter key: キャッシュキー
    public func remove(forKey key: CacheKey) throws {
        let url = cacheDirectory.appendingPathComponent(key.rawValue)
        let metadataURL = cacheDirectory.appendingPathComponent("\(key.rawValue).meta")
        try? fileManager.removeItem(at: url)
        try? fileManager.removeItem(at: metadataURL)
    }

    /// すべてのキャッシュを削除する
    public func clearAll() throws {
        let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for url in contents {
            try? fileManager.removeItem(at: url)
        }
    }
}

/// キャッシュメタデータ
private struct CacheMetadata: Codable {
    let timestamp: Date
}
