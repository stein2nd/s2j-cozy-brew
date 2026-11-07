import Foundation

/// `Package` の表示用文字列を Foundation 型として正規化する
enum PackageText {
    static func normalizeRequired(_ value: String) -> String {
        normalizeOptional(value) ?? ""
    }

    static func normalizeOptional(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = String(value).trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
