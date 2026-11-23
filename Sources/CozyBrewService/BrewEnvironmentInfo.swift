import CozyBrewCore
import Foundation

/// Homebrew 実行環境のスナップショット (read-only 表示用)
public struct BrewEnvironmentSnapshot: Sendable, Equatable {
    public let brewBinaryPath: String?
    public let architectureLabel: String?
    public let brewVersionOutput: String?
    public let brewConfigOutput: String?
    public let prefixPath: String?
    public let cellarPath: String?
    public let repositoryPath: String?
    public let operationHistoryPath: String
    public let cacheDirectoryPath: String
    public let appBundlePath: String?
    /// `brew` サブコマンドごとの stderr 等 (部分失敗)
    public let fetchErrors: [String: String]

    public init(
        brewBinaryPath: String?,
        architectureLabel: String?,
        brewVersionOutput: String?,
        brewConfigOutput: String?,
        prefixPath: String?,
        cellarPath: String?,
        repositoryPath: String?,
        operationHistoryPath: String,
        cacheDirectoryPath: String,
        appBundlePath: String?,
        fetchErrors: [String: String] = [:]
    ) {
        self.brewBinaryPath = brewBinaryPath
        self.architectureLabel = architectureLabel
        self.brewVersionOutput = brewVersionOutput
        self.brewConfigOutput = brewConfigOutput
        self.prefixPath = prefixPath
        self.cellarPath = cellarPath
        self.repositoryPath = repositoryPath
        self.operationHistoryPath = operationHistoryPath
        self.cacheDirectoryPath = cacheDirectoryPath
        self.appBundlePath = appBundlePath
        self.fetchErrors = fetchErrors
    }
}

public enum BrewEnvironmentFetcher {
    /// `brew config` 等を実行してスナップショットを組み立てる
    public static func fetch(
        brewProcess: BrewProcess,
        isBrewAvailable: Bool,
        operationHistoryPath: String,
        cacheDirectoryPath: String,
        appBundlePath: String?
    ) async -> BrewEnvironmentSnapshot {
        let located = BrewBinaryLocator.locate()
        let binaryPath = located?.path
        let archLabel = located.map(\.architecture).map(architectureLabel(for:))

        guard isBrewAvailable else {
            return BrewEnvironmentSnapshot(
                brewBinaryPath: binaryPath,
                architectureLabel: archLabel,
                brewVersionOutput: nil,
                brewConfigOutput: nil,
                prefixPath: nil,
                cellarPath: nil,
                repositoryPath: nil,
                operationHistoryPath: operationHistoryPath,
                cacheDirectoryPath: cacheDirectoryPath,
                appBundlePath: appBundlePath,
                fetchErrors: ["detection": "Homebrew is not available"]
            )
        }

        var errors: [String: String] = [:]

        async let versionTask = runBrew(brewProcess, args: ["--version"])
        async let configTask = runBrew(brewProcess, args: ["config"])
        async let prefixTask = runBrew(brewProcess, args: ["--prefix"])
        async let cellarTask = runBrew(brewProcess, args: ["--cellar"])
        async let repositoryTask = runBrew(brewProcess, args: ["--repository"])

        let versionResult = await versionTask
        let configResult = await configTask
        let prefixResult = await prefixTask
        let cellarResult = await cellarTask
        let repositoryResult = await repositoryTask

        mergeBrewResult(versionResult, key: "version", into: &errors)
        mergeBrewResult(configResult, key: "config", into: &errors)
        mergeBrewResult(prefixResult, key: "prefix", into: &errors)
        mergeBrewResult(cellarResult, key: "cellar", into: &errors)
        mergeBrewResult(repositoryResult, key: "repository", into: &errors)

        let versionOut = versionResult.output
        let configOut = configResult.output
        let prefixOut = prefixResult.output
        let cellarOut = cellarResult.output
        let repositoryOut = repositoryResult.output

        return BrewEnvironmentSnapshot(
            brewBinaryPath: binaryPath,
            architectureLabel: archLabel,
            brewVersionOutput: versionOut,
            brewConfigOutput: configOut,
            prefixPath: prefixOut,
            cellarPath: cellarOut,
            repositoryPath: repositoryOut,
            operationHistoryPath: operationHistoryPath,
            cacheDirectoryPath: cacheDirectoryPath,
            appBundlePath: appBundlePath,
            fetchErrors: errors
        )
    }

    public static func architectureLabel(for architecture: BrewBinaryLocator.BrewPath.Architecture) -> String {
        switch architecture {
        case .appleSilicon:
            "Apple Silicon"
        case .intel:
            "Intel"
        case let .custom(path):
            "Custom (\(path))"
        }
    }

    private struct BrewCommandResult: Sendable {
        let output: String?
        let failureMessage: String?
    }

    private static func runBrew(_ process: BrewProcess, args: [String]) async -> BrewCommandResult {
        do {
            let result = try await process.run(args)
            guard result.exitCode == 0 else {
                let message = result.errorMessage.isEmpty ? "exit \(result.exitCode)" : result.errorMessage
                return BrewCommandResult(output: nil, failureMessage: message)
            }
            let trimmed = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            let output = trimmed.isEmpty ? nil : trimmed
            return BrewCommandResult(output: output, failureMessage: nil)
        } catch {
            return BrewCommandResult(output: nil, failureMessage: error.localizedDescription)
        }
    }

    private static func mergeBrewResult(
        _ result: BrewCommandResult,
        key: String,
        into errors: inout [String: String]
    ) {
        if let failureMessage = result.failureMessage {
            errors[key] = failureMessage
        }
    }
}
