import Foundation

/// `brew info` 詳細取得 (`BrewManager` の本体長を抑えるため分割)
@MainActor
public extension BrewManager {
    /// `brew info --json=v2` で説明・依存関係等を補完した `Package` を返す
    func packageInfo(for package: Package) async throws -> Package {
        guard isBrewAvailable else {
            throw BrewManagerError.brewNotAvailable
        }

        let (jsonStdout, parsedText) = try await fetchBrewInfoOutputs(for: package)
        let response = try JSONDecoder().decode(BrewInfoResponse.self, from: Data(jsonStdout.utf8))
        let listSeed = freshListPackage(matching: package) ?? package
        let enriched = try enrichedPackage(from: response, seed: listSeed, parsedText: parsedText)

        let listed = applyingCurrentLists(to: enriched)
        if let markdown = listed.infoMarkdown, !markdown.isEmpty {
            return listed
        }
        if let readme = await BrewGitHubReadmeFetcher.fetch(homepage: listed.homepage) {
            return listed.withInfoMarkdown(readme)
        }
        return listed
    }

    private func fetchBrewInfoOutputs(
        for package: Package
    ) async throws -> (String, BrewInfoTextParser.ParsedSections) {
        var jsonArgs = ["info", "--json=v2"]
        var textArgs = ["info"]
        if package.type == .cask {
            jsonArgs.append("--cask")
            textArgs.append("--cask")
        }
        jsonArgs.append(package.name)
        textArgs.append(package.name)

        async let jsonResult = brewProcess.run(jsonArgs)
        async let textResult = brewProcess.run(textArgs)

        let result = try await jsonResult
        guard result.isSuccess else {
            throw BrewManagerError.packageInfoFailed(stderr: result.errorMessage)
        }

        let textOutput = try await textResult
        let parsedText = textOutput.isSuccess
            ? BrewInfoTextParser.parse(stdout: textOutput.stdout)
            : BrewInfoTextParser.ParsedSections()
        return (result.stdout, parsedText)
    }

    private func enrichedPackage(
        from response: BrewInfoResponse,
        seed listSeed: Package,
        parsedText: BrewInfoTextParser.ParsedSections
    ) throws -> Package {
        switch listSeed.type {
        case .formula:
            guard let formula = response.formulae?.first else {
                throw BrewManagerError.packageInfoNotFound(name: listSeed.name)
            }
            let detail = Package.from(formula)
            return listSeed.enriched(
                with: detail,
                dependencies: formula.dependencies,
                buildDependencies: formula.buildDependencies
            )
            .withInfoExtras(buildFormulaInfoExtras(formula: formula, parsed: parsedText))
        case .cask:
            guard let cask = response.casks?.first else {
                throw BrewManagerError.packageInfoNotFound(name: listSeed.name)
            }
            let detail = Package.from(cask)
            let installedVersions = cask.installed?.map(\.version) ?? []
            let kegLines = PackageInfoExtrasBuilder.mergeInstalledKegLines(
                textLines: parsedText.installedKegLines,
                formulaName: cask.name,
                linkedKeg: nil,
                installedVersions: installedVersions
            )
            return listSeed.enriched(with: detail).withInfoExtras(
                PackageInfoExtras(
                    installedKegLines: kegLines,
                    options: parsedText.optionLines,
                    analyticsLines: parsedText.analyticsLines
                )
            )
        }
    }

    func buildFormulaInfoExtras(
        formula: Formula,
        parsed: BrewInfoTextParser.ParsedSections
    ) -> PackageInfoExtras {
        let installedNames = Set(installedPackages.map(\.name))
        let runtimeRecords = formula.installedKegRecords?.first?.runtimeDependencies ?? []
        let runtime = PackageInfoExtrasBuilder.runtimeLines(from: runtimeRecords, installedNames: installedNames)
        let installedVersions = formula.installed?.map(\.version) ?? []
        let kegLines = PackageInfoExtrasBuilder.mergeInstalledKegLines(
            textLines: parsed.installedKegLines,
            formulaName: formula.name,
            linkedKeg: formula.linkedKeg,
            installedVersions: installedVersions
        )
        var options = parsed.optionLines
        if options.isEmpty, formula.versions?.head != nil {
            options = [BrewInfoTextParser.BrewInfoOptionLine(flag: "--HEAD", description: "Install HEAD version")]
        }
        return PackageInfoExtras(
            versionSummary: PackageInfoExtrasBuilder.versionSummary(from: formula.versions),
            installedKegLines: kegLines,
            options: options,
            runtimeDependencies: runtime,
            analyticsLines: parsed.analyticsLines
        )
    }

    /// `brew outdated` / `brew list` の結果で `isOutdated` 等を上書きする (`brew info` 単体より優先)
    func applyingCurrentLists(to package: Package) -> Package {
        if let outdated = outdatedPackages.first(where: { $0.id == package.id && $0.type == package.type }) {
            return package.withListPresentation(from: outdated, isOutdated: true)
        }
        if let installed = installedPackages.first(where: { $0.id == package.id && $0.type == package.type }) {
            return package.withListPresentation(from: installed, isOutdated: false)
        }
        return package
    }
}
