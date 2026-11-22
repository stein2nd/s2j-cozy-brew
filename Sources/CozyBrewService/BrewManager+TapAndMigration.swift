import Foundation

/// Tap / 履歴 / Cakebrew 移行 (`BrewManager` の型本体長を抑えるため分割)
@MainActor
public extension BrewManager {
    /// Tap を追加 (`brew tap`)
    func addTap(named tapName: String) async throws {
        guard isBrewAvailable else {
            throw BrewManagerError.brewNotAvailable
        }

        let trimmed = tapName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw BrewManagerError.tapInvalidName
        }

        let result = try await brewProcess.run(["tap", trimmed])
        if !result.isSuccess {
            throw BrewManagerError.tapFailed(stderr: result.stderr)
        }

        recordOperation(kind: .tap, title: trimmed)
        await refreshTaps()
    }

    /// Tap を削除 (`brew untap`)
    func removeTap(_ tap: Tap) async throws {
        guard isBrewAvailable else {
            throw BrewManagerError.brewNotAvailable
        }

        if tap.official == true {
            throw BrewManagerError.cannotUntapOfficialTap(tap.name)
        }

        let result = try await brewProcess.run(["untap", tap.name])
        if !result.isSuccess {
            throw BrewManagerError.untapFailed(stderr: result.stderr)
        }

        recordOperation(kind: .untap, title: tap.name)
        await refreshTaps()
    }

    /// untap 確認用に `brew tap-info <name> --json` を要約する
    func tapRemovalSummary(for tap: Tap) async -> TapRemovalSummary? {
        guard isBrewAvailable else { return nil }

        do {
            let result = try await brewProcess.run(["tap-info", tap.name, "--json"])
            guard result.isSuccess,
                  !result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else {
                return nil
            }
            let records = try JSONDecoder().decode([BrewTapInfoRecord].self, from: Data(result.stdout.utf8))
            guard let record = records.first else { return nil }
            return BrewTapInfo.removalSummary(record: record, installedPackages: installedPackages)
        } catch {
            return nil
        }
    }

    /// Cakebrew 設定を検出した場合に履歴へ取り込む
    func performCakebrewMigration() throws {
        guard let legacy = CakebrewMigration.detectLegacyPreferences() else { return }
        let merged = try CakebrewMigration.importLegacy(legacy, historyStore: operationHistoryStore)
        replaceOperationHistory(merged)
        CakebrewMigration.markMigrationCompleted()
    }

    func skipCakebrewMigration() {
        CakebrewMigration.markMigrationCompleted()
    }

    internal func recordOperation(kind: BrewOperationRecord.Kind, title: String, detail: String? = nil) {
        let record = BrewOperationRecord(kind: kind, title: title, detail: detail)
        if let updated = try? operationHistoryStore.append(record, to: operationHistory) {
            replaceOperationHistory(updated)
        }
    }
}
