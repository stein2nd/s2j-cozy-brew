import XCTest
@testable import CozyBrewService

final class BrewCacheTests: XCTestCase {
    var cache: BrewCache!
    var tempDirectory: URL!
    
    override func setUp() {
        super.setUp()
        // 一時ディレクトリを作成
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        cache = BrewCache(cacheDirectory: tempDirectory)
    }
    
    override func tearDown() {
        // 一時ディレクトリを削除
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }
    
    func testSaveAndLoad() throws {
        let testData = ["item1", "item2", "item3"]
        
        // 保存
        try cache.save(testData, forKey: .installedFormulae)
        
        // 読み込み
        let loaded: [String]? = try cache.load([String].self, forKey: .installedFormulae)
        
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded, testData)
    }
    
    func testCacheExpiration() throws {
        let testData = ["item1", "item2"]
        
        // 保存
        try cache.save(testData, forKey: .installedFormulae)
        
        // すぐに読み込み（有効期限内）
        let loaded1: [String]? = try cache.load([String].self, forKey: .installedFormulae, ttl: 3600)
        XCTAssertNotNil(loaded1)
        
        // TTL を 0 にして読み込み（期限切れ）
        let loaded2: [String]? = try cache.load([String].self, forKey: .installedFormulae, ttl: 0)
        XCTAssertNil(loaded2)
    }
    
    func testRemove() throws {
        let testData = ["item1"]
        
        // 保存
        try cache.save(testData, forKey: .installedFormulae)
        
        // 削除
        try cache.remove(forKey: .installedFormulae)
        
        // 読み込み（nil が返るはず）
        let loaded: [String]? = try cache.load([String].self, forKey: .installedFormulae)
        XCTAssertNil(loaded)
    }
    
    func testClearAll() throws {
        let testData1 = ["item1"]
        let testData2 = ["item2"]
        
        // 複数のキャッシュを保存
        try cache.save(testData1, forKey: .installedFormulae)
        try cache.save(testData2, forKey: .installedCasks)
        
        // すべて削除
        try cache.clearAll()
        
        // どちらも nil が返るはず
        let loaded1: [String]? = try cache.load([String].self, forKey: .installedFormulae)
        let loaded2: [String]? = try cache.load([String].self, forKey: .installedCasks)
        XCTAssertNil(loaded1)
        XCTAssertNil(loaded2)
    }
}
