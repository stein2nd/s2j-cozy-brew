import CozyBrewService
import Foundation

/// CozyBrewUIComponents 用ローカライズ文字列 (`Localizable.strings` / `Bundle.module`)
public enum CozyBrewL10n: Sendable {
    private static let bundle: Bundle = {
        #if SWIFT_PACKAGE
            Bundle.module
        #else
            Bundle(for: BundleLocator.self)
        #endif
    }()

    private static func tr(_ key: String, _ args: CVarArg...) -> String {
        let format = String(
            localized: String.LocalizationValue(key),
            bundle: bundle,
            comment: ""
        )
        guard !args.isEmpty else { return format }
        return String(format: format, locale: Locale.current, arguments: args)
    }

    // MARK: - Sidebar

    public static var sidebarWarnings: String {
        tr("sidebar.warnings")
    }

    public static var sidebarInstalled: String {
        tr("sidebar.installed")
    }

    public static var sidebarOutdated: String {
        tr("sidebar.outdated")
    }

    public static var sidebarHistory: String {
        tr("sidebar.history")
    }

    public static var sidebarTaps: String {
        tr("sidebar.taps")
    }

    public static var sidebarFormulae: String {
        tr("sidebar.formulae")
    }

    public static var sidebarCasks: String {
        tr("sidebar.casks")
    }

    public static var sidebarGroupInstalledPackages: String {
        tr("sidebar.group.installed_packages")
    }

    public static var sidebarGroupCatalog: String {
        tr("sidebar.group.catalog")
    }

    public static var navigationTitle: String {
        tr("app.navigation_title")
    }

    // MARK: - Toolbar & search

    public static var refresh: String {
        tr("toolbar.refresh")
    }

    public static var refreshHelp: String {
        tr("toolbar.refresh.help")
    }

    public static var upgradeAll: String {
        tr("toolbar.upgrade_all")
    }

    public static var upgradeAllHelp: String {
        tr("toolbar.upgrade_all.help")
    }

    public static var back: String {
        tr("toolbar.back")
    }

    public static var searchPlaceholder: String {
        tr("search.placeholder")
    }

    // MARK: - Package actions

    public static var actionInstall: String {
        tr("action.install")
    }

    public static var actionUninstall: String {
        tr("action.uninstall")
    }

    public static var actionUpgrade: String {
        tr("action.upgrade")
    }

    public static var actionCancel: String {
        tr("action.cancel")
    }

    public static var actionOK: String {
        tr("action.ok")
    }

    // MARK: - Package list / detail

    public static var badgeUpdateAvailable: String {
        tr("package.badge.update_available")
    }

    public static var badgeDeprecated: String {
        tr("package.badge.deprecated")
    }

    public static var typeFormula: String {
        tr("package.type.formula")
    }

    public static var typeCask: String {
        tr("package.type.cask")
    }

    public static var loadingPackageInfo: String {
        tr("detail.loading")
    }

    public static var sectionDescription: String {
        tr("detail.section.description")
    }

    public static var sectionInstalledVersion: String {
        tr("detail.section.installed_version")
    }

    public static var sectionHomepage: String {
        tr("detail.section.homepage")
    }

    public static var sectionInstallation: String {
        tr("detail.section.installation")
    }

    public static var sectionFrom: String {
        tr("detail.section.from")
    }

    public static var sectionLicense: String {
        tr("detail.section.license")
    }

    public static var sectionDependencies: String {
        tr("detail.section.dependencies")
    }

    public static var sectionBuildDependencies: String {
        tr("detail.section.build_dependencies")
    }

    public static var sectionReadme: String {
        tr("detail.section.readme")
    }

    public static var sectionBrewVersionLine: String {
        tr("detail.section.brew_version")
    }

    public static var sectionInstalledKegs: String {
        tr("detail.section.installed_kegs")
    }

    public static var sectionRecursiveRuntime: String {
        tr("detail.section.recursive_runtime")
    }

    public static var sectionOptions: String {
        tr("detail.section.options")
    }

    public static var sectionAnalytics: String {
        tr("detail.section.analytics")
    }

    public static var runtimeDependencyDirect: String {
        tr("detail.runtime.direct")
    }

    public static var sectionStatus: String {
        tr("detail.section.status")
    }

    public static var statusNotInstalled: String {
        tr("detail.status.not_installed")
    }

    public static var statusInstalledUpdate: String {
        tr("detail.status.installed_update")
    }

    public static var statusInstalled: String {
        tr("detail.status.installed")
    }

    // MARK: - Install flow

    public static func installConfirmTitle(_ name: String) -> String {
        tr("install.confirm.title", name)
    }

    public static var installTypeLabel: String {
        tr("install.type_label")
    }

    public static var installVersionLabel: String {
        tr("install.version_label")
    }

    public static var installFailedTitle: String {
        tr("install.failed.title")
    }

    public static func installProgressTitle(_ name: String) -> String {
        tr("install.progress.title", name)
    }

    // MARK: - Upgrade all / doctor

    public static var upgradeAllDialogTitle: String {
        tr("upgrade_all.dialog.title")
    }

    public static var upgradeAllDialogConfirm: String {
        tr("upgrade_all.dialog.confirm")
    }

    public static func upgradeAllDialogMessage(_ count: Int) -> String {
        tr("upgrade_all.dialog.message", count)
    }

    public static var upgradeAllFailedTitle: String {
        tr("upgrade_all.failed.title")
    }

    public static var upgradingAllOverlay: String {
        tr("upgrade_all.overlay.title")
    }

    public static var doctorCouldNotRun: String {
        tr("doctor.could_not_run")
    }

    public static var doctorNoWarnings: String {
        tr("doctor.no_warnings")
    }

    // MARK: - Upgrade failure / terminal

    public static var upgradeFailed: String {
        tr("upgrade.failed.title")
    }

    public static var showDetails: String {
        tr("upgrade.show_details")
    }

    public static var continueInTerminal: String {
        tr("terminal.continue")
    }

    public static var runInTerminal: String {
        tr("terminal.run")
    }

    // MARK: - Taps

    public static var tapAdd: String {
        tr("tap.add")
    }

    public static var tapAddTitle: String {
        tr("tap.add.title")
    }

    public static var tapAddPlaceholder: String {
        tr("tap.add.placeholder")
    }

    public static var tapAddConfirm: String {
        tr("tap.add.confirm")
    }

    public static var tapUntap: String {
        tr("tap.untap")
    }

    public static var tapUntapTitle: String {
        tr("tap.untap.title")
    }

    public static func tapUntapMessage(_ name: String) -> String {
        tr("tap.untap.message", name)
    }

    public static func tapUntapSummary(_ summary: TapRemovalSummary) -> String {
        let installedList = summary.installedNames.joined(separator: ", ")
        if summary.installedNames.isEmpty {
            return tr(
                "tap.untap.summary.no_installed",
                summary.formulaCount,
                summary.caskCount
            )
        }
        return tr(
            "tap.untap.summary",
            summary.formulaCount,
            summary.caskCount,
            summary.installedNames.count,
            installedList
        )
    }

    public static var tapUntapConfirm: String {
        tr("tap.untap.confirm")
    }

    public static var tapActionFailed: String {
        tr("tap.action_failed")
    }

    public static var tapWorking: String {
        tr("tap.working")
    }

    // MARK: - Operation history

    public static var historyEmpty: String {
        tr("history.empty")
    }

    public static var historyNoMatches: String {
        tr("history.no_matches")
    }

    public static var historyKindInstall: String {
        tr("history.kind.install")
    }

    public static var historyKindUninstall: String {
        tr("history.kind.uninstall")
    }

    public static var historyKindUpgrade: String {
        tr("history.kind.upgrade")
    }

    public static var historyKindUpgradeAll: String {
        tr("history.kind.upgrade_all")
    }

    public static var historyKindTap: String {
        tr("history.kind.tap")
    }

    public static var historyKindUntap: String {
        tr("history.kind.untap")
    }

    public static var historyKindMigration: String {
        tr("history.kind.migration")
    }

    // MARK: - Cakebrew migration

    public static var cakebrewMigrationTitle: String {
        tr("cakebrew_migration.title")
    }

    public static func cakebrewMigrationMessage(_ version: String?) -> String {
        if let version, !version.isEmpty {
            return tr("cakebrew_migration.message_version", version)
        }
        return tr("cakebrew_migration.message")
    }

    public static func cakebrewMigrationHistoryCount(_ count: Int) -> String {
        tr("cakebrew_migration.history_count", count)
    }

    public static var cakebrewMigrationImport: String {
        tr("cakebrew_migration.import")
    }

    public static var cakebrewMigrationSkip: String {
        tr("cakebrew_migration.skip")
    }

    // MARK: - Homebrew not installed (App からも利用)

    public static var brewNotFoundTitle: String {
        tr("brew_missing.title")
    }

    public static var brewNotFoundMessage: String {
        tr("brew_missing.message")
    }

    public static var brewInstallInstructionsTitle: String {
        tr("brew_missing.instructions_title")
    }

    public static var brewInstallAutoButton: String {
        tr("brew_missing.install_auto")
    }

    // MARK: - Settings

    public static var settingsTabGeneral: String {
        tr("settings.tab.general")
    }

    public static var settingsTabMigration: String {
        tr("settings.tab.migration")
    }

    public static var settingsTabPrivacy: String {
        tr("settings.tab.privacy")
    }

    public static var settingsSectionApplication: String {
        tr("settings.section.application")
    }

    public static var settingsSectionEnvironment: String {
        tr("settings.section.environment")
    }

    public static var settingsSectionCakebrew: String {
        tr("settings.section.cakebrew")
    }

    public static var settingsAppVersion: String {
        tr("settings.app_version")
    }

    public static var settingsAppBuild: String {
        tr("settings.app_build")
    }

    public static var settingsCakebrewStatus: String {
        tr("settings.cakebrew.status")
    }

    public static var settingsCakebrewStatusNone: String {
        tr("settings.cakebrew.status.none")
    }

    public static var settingsCakebrewStatusPending: String {
        tr("settings.cakebrew.status.pending")
    }

    public static var settingsCakebrewStatusDone: String {
        tr("settings.cakebrew.status.done")
    }

    public static var settingsCakebrewImport: String {
        tr("settings.cakebrew.import")
    }

    public static var settingsCakebrewImportSuccess: String {
        tr("settings.cakebrew.import_success")
    }

    public static var settingsTelemetryToggle: String {
        tr("settings.telemetry.toggle")
    }

    public static var settingsTelemetryFooter: String {
        tr("settings.telemetry.footer")
    }

    public static var a11ySettingsOpenEnvironment: String {
        tr("a11y.settings.open_environment")
    }

    public static var a11ySettingsTelemetry: String {
        tr("a11y.settings.telemetry")
    }

    // MARK: - Homebrew Environment

    public static var environmentWindowTitle: String {
        tr("environment.window_title")
    }

    public static var menuHomebrewEnvironment: String {
        tr("environment.menu")
    }

    public static var environmentLoading: String {
        tr("environment.loading")
    }

    public static var environmentSectionDetection: String {
        tr("environment.section.detection")
    }

    public static var environmentSectionVersion: String {
        tr("environment.section.version")
    }

    public static var environmentSectionConfig: String {
        tr("environment.section.config")
    }

    public static var environmentSectionHomebrewPaths: String {
        tr("environment.section.homebrew_paths")
    }

    public static var environmentSectionCozyBrewData: String {
        tr("environment.section.cozybrew_data")
    }

    public static var environmentSectionShortcuts: String {
        tr("environment.section.shortcuts")
    }

    public static var environmentBrewNotDetected: String {
        tr("environment.brew_not_detected")
    }

    public static var environmentArchitecture: String {
        tr("environment.architecture")
    }

    public static var environmentPathPrefix: String {
        tr("environment.path.prefix")
    }

    public static var environmentPathCellar: String {
        tr("environment.path.cellar")
    }

    public static var environmentPathRepository: String {
        tr("environment.path.repository")
    }

    public static var environmentCopy: String {
        tr("environment.copy")
    }

    public static var environmentCopyConfig: String {
        tr("environment.copy.config")
    }

    public static var environmentRevealInFinder: String {
        tr("environment.reveal_in_finder")
    }

    public static var environmentOpenTerminalConfig: String {
        tr("environment.open_terminal_config")
    }

    public static var environmentShowWarnings: String {
        tr("environment.show_warnings")
    }

    public static var a11yEnvironmentRefresh: String {
        tr("a11y.environment.refresh")
    }

    public static var a11yEnvironmentTerminalConfig: String {
        tr("a11y.environment.terminal_config")
    }

    public static var a11yEnvironmentShowWarnings: String {
        tr("a11y.environment.show_warnings")
    }

    public static func a11yEnvironmentReveal(_ path: String) -> String {
        tr("a11y.environment.reveal", path)
    }

    // MARK: - Accessibility

    public static func a11yPackageRow(_ name: String, type: String, installed: Bool) -> String {
        let status = installed ? tr("a11y.installed") : tr("a11y.not_installed")
        return tr("a11y.package_row", name, type, status)
    }

    public static var a11ySearchField: String {
        tr("a11y.search_field")
    }

    public static var a11yRefresh: String {
        tr("a11y.refresh")
    }

    public static var a11yUpgradeAll: String {
        tr("a11y.upgrade_all")
    }

    public static var a11yBack: String {
        tr("a11y.back")
    }

    public static var a11yInstalled: String {
        tr("a11y.installed")
    }

    public static var a11yNotInstalled: String {
        tr("a11y.not_installed")
    }
}

private final class BundleLocator: NSObject {}
