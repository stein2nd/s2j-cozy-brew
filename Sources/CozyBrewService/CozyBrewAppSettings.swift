import Foundation

/// Cozy Brew アプリ専用の `UserDefaults` (Settings 画面の正本)
public enum CozyBrewAppSettings {
    public static let suiteName = CakebrewMigration.cozyBrewUserDefaultsSuite
    private static let telemetryOptInKey = "cozybrew.telemetry.opt_in"

    public static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    /// 匿名統計の opt-in。未実装のため現状はどこにも送信しない (デフォルトオフ)
    public static var isTelemetryOptIn: Bool {
        get { defaults.bool(forKey: telemetryOptInKey) }
        set { defaults.set(newValue, forKey: telemetryOptInKey) }
    }
}

public extension CakebrewMigration {
    enum Status: Sendable, Equatable {
        case noLegacyFound
        case legacyAvailableNotImported
        case importCompleted
    }

    static func currentStatus() -> Status {
        guard detectLegacyPreferences() != nil else { return .noLegacyFound }
        if hasCompletedMigration() {
            return .importCompleted
        }
        return .legacyAvailableNotImported
    }
}
