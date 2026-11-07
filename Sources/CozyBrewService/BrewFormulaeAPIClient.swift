import Foundation

/// Homebrew 公式カタログ API (formulae.brew.sh)
public enum BrewFormulaeAPIClient {
    public static let formulaCatalogURL = URL(string: "https://formulae.brew.sh/api/formula.json")!
    public static let caskCatalogURL = URL(string: "https://formulae.brew.sh/api/cask.json")!

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 300
        config.waitsForConnectivity = true
        // CFNetwork は User-Agent 組み立て時に Info.plist の値を文字列として扱う。
        // 先に明示 UA を渡しておく (CFBundleVersion が数値型だと `-[__NSCFNumber length]` で落ちうる)。
        config.httpAdditionalHeaders = [
            "User-Agent": cozyBrewUserAgent(),
        ]
        return URLSession(configuration: config)
    }()

    private static func cozyBrewUserAgent() -> String {
        let bundle = Bundle.main
        let name = (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String) ?? "CozyBrew"
        let version = stringBundleValue("CFBundleShortVersionString") ?? "0"
        let build = stringBundleValue("CFBundleVersion") ?? "0"
        return "\(name)/\(version) (build \(build); macOS) CozyBrew"
    }

    private static func stringBundleValue(_ key: String) -> String? {
        guard let raw = bundle.object(forInfoDictionaryKey: key) else { return nil }
        if let string = raw as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if let number = raw as? NSNumber {
            return number.stringValue
        }
        return String(describing: raw)
    }

    private static var bundle: Bundle {
        .main
    }

    public enum FetchError: Error, LocalizedError {
        case invalidResponse
        case httpStatus(Int)

        public var errorDescription: String? {
            switch self {
            case .invalidResponse:
                "Invalid response from formulae.brew.sh"
            case let .httpStatus(code):
                "formulae.brew.sh returned HTTP \(code)"
            }
        }
    }

    public static func fetchFormulaCatalogData() async throws -> Data {
        try await fetchCatalogData(from: formulaCatalogURL)
    }

    public static func fetchCaskCatalogData() async throws -> Data {
        try await fetchCatalogData(from: caskCatalogURL)
    }

    private static func fetchCatalogData(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw FetchError.invalidResponse
        }
        guard (200 ... 299).contains(http.statusCode) else {
            throw FetchError.httpStatus(http.statusCode)
        }
        return data
    }
}
