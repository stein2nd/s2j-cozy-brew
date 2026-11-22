@testable import CozyBrewService
import XCTest

final class BrewOperationHistoryTests: XCTestCase {
    func testAppendAndLoadRoundTrip() throws {
        let temp = FileManager.default.temporaryDirectory
        let directory = temp.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = directory.appendingPathComponent("history.json")
        let store = BrewOperationHistoryStore(fileURL: fileURL)

        let first = BrewOperationRecord(kind: .install, title: "wget")
        let loaded = try store.append(first, to: [])
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.title, "wget")

        let second = BrewOperationRecord(kind: .tap, title: "user/repo")
        let merged = try store.append(second, to: loaded)
        XCTAssertEqual(merged.count, 2)
        XCTAssertEqual(store.load().first?.kind, .tap)
    }

    func testCakebrewHistoryExtraction() throws {
        let temp = FileManager.default.temporaryDirectory
        let directory = temp.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let plistURL = directory.appendingPathComponent("com.brunophilipe.Cakebrew.plist")
        let plist: [String: Any] = [
            "InstallHistory": ["wget", "curl"],
            "CFBundleShortVersionString": "1.3",
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: plistURL)

        let legacy = CakebrewLegacyPreferences(
            plistURL: plistURL,
            shortVersion: "1.3",
            historyLines: ["wget", "curl"]
        )
        let store = BrewOperationHistoryStore(fileURL: directory.appendingPathComponent("history.json"))
        let merged = try CakebrewMigration.importLegacy(legacy, historyStore: store)
        XCTAssertGreaterThanOrEqual(merged.count, 3)
        XCTAssertTrue(merged.contains { $0.kind == .migration })
    }
}
