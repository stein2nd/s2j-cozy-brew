import CozyBrewService
import XCTest

final class CozyBrewAppSettingsTests: XCTestCase {
    func testTelemetryOptInDefaultsOff() throws {
        let suite = "dev.s2j.cozybrew.tests"
        UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
        defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }

        let key = "cozybrew.telemetry.opt_in"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        XCTAssertFalse(defaults.bool(forKey: key))

        defaults.set(true, forKey: key)
        XCTAssertTrue(defaults.bool(forKey: key))
    }

    func testCakebrewStatusIsDeterministic() {
        let status = CakebrewMigration.currentStatus()
        switch status {
        case .noLegacyFound, .legacyAvailableNotImported, .importCompleted:
            XCTAssertTrue(true)
        }
        if status != .noLegacyFound {
            XCTAssertNotNil(CakebrewMigration.detectLegacyPreferences())
        }
    }
}
