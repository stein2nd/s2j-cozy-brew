import Foundation

/// `brew doctor` の 1 件の Warning ブロック
public struct BrewDoctorWarning: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let bodyLines: [String]
    public let items: [String]

    public init(id: String, title: String, bodyLines: [String], items: [String]) {
        self.id = id
        self.title = title
        self.bodyLines = bodyLines
        self.items = items
    }
}

/// `brew doctor` テキスト出力のパース
public enum BrewDoctorParser {
    public struct Result: Sendable {
        public let preamble: String?
        public let warnings: [BrewDoctorWarning]
    }

    public static func parse(_ text: String) -> Result {
        let lines = text.components(separatedBy: .newlines)
        var preambleLines: [String] = []
        var warnings: [BrewDoctorWarning] = []
        var currentTitle: String?
        var bodyLines: [String] = []
        var items: [String] = []

        func flush() {
            guard let currentTitle else { return }
            let id = "\(currentTitle)-\(warnings.count)"
            warnings.append(
                BrewDoctorWarning(
                    id: id,
                    title: currentTitle,
                    bodyLines: bodyLines,
                    items: items
                )
            )
        }

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .newlines)
            if line.hasPrefix("==>") {
                continue
            }
            if line.hasPrefix("Warning:") {
                flush()
                currentTitle = line
                    .dropFirst("Warning:".count)
                    .trimmingCharacters(in: .whitespaces)
                bodyLines = []
                items = []
                continue
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                continue
            }

            if currentTitle == nil {
                if !trimmed.hasPrefix("✔") {
                    preambleLines.append(trimmed)
                }
                continue
            }

            if isItemLine(rawLine) {
                items.append(trimmed)
            } else {
                bodyLines.append(trimmed)
            }
        }
        flush()

        let preamble = preambleLines.isEmpty
            ? nil
            : preambleLines.joined(separator: "\n")

        return Result(preamble: preamble, warnings: warnings)
    }

    private static func isItemLine(_ line: String) -> Bool {
        guard line.hasPrefix("  ") || line.hasPrefix("\t") else { return false }
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        return !trimmed.contains(":") && !trimmed.hasPrefix("You should")
    }
}
