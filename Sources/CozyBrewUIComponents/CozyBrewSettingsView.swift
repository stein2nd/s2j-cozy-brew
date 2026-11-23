import CozyBrewService
import SwiftUI

/// アプリ専用 Settings (⌘,) — ux_flows_spec §6.1
public struct CozyBrewSettingsView: View {
    @ObservedObject private var manager: BrewManager
    private let openHomebrewEnvironment: () -> Void

    @State private var telemetryOptIn: Bool
    @State private var cakebrewStatus: CakebrewMigration.Status = .noLegacyFound
    @State private var migrationMessage: String?
    @State private var migrationIsError = false

    public init(
        manager: BrewManager,
        openHomebrewEnvironment: @escaping () -> Void
    ) {
        self.manager = manager
        self.openHomebrewEnvironment = openHomebrewEnvironment
        _telemetryOptIn = State(initialValue: CozyBrewAppSettings.isTelemetryOptIn)
    }

    public var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label(CozyBrewL10n.settingsTabGeneral, systemImage: "gearshape")
                }
            migrationTab
                .tabItem {
                    Label(CozyBrewL10n.settingsTabMigration, systemImage: "arrow.triangle.2.circlepath")
                }
            privacyTab
                .tabItem {
                    Label(CozyBrewL10n.settingsTabPrivacy, systemImage: "hand.raised")
                }
        }
        .frame(minWidth: 420, minHeight: 280)
        .onAppear {
            refreshCakebrewStatus()
        }
    }

    private var generalTab: some View {
        Form {
            Section(CozyBrewL10n.settingsSectionApplication) {
                LabeledContent(CozyBrewL10n.settingsAppVersion, value: appVersionString)
                LabeledContent(CozyBrewL10n.settingsAppBuild, value: appBuildString)
            }
            Section(CozyBrewL10n.settingsSectionEnvironment) {
                Button(CozyBrewL10n.menuHomebrewEnvironment) {
                    openHomebrewEnvironment()
                }
                .accessibilityLabel(CozyBrewL10n.a11ySettingsOpenEnvironment)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var migrationTab: some View {
        Form {
            Section(CozyBrewL10n.settingsSectionCakebrew) {
                LabeledContent(CozyBrewL10n.settingsCakebrewStatus, value: cakebrewStatusLabel)
                if cakebrewStatus != .noLegacyFound {
                    Button(CozyBrewL10n.settingsCakebrewImport) {
                        runCakebrewImport()
                    }
                }
                if let migrationMessage {
                    Text(migrationMessage)
                        .font(.caption)
                        .foregroundColor(migrationIsError ? .red : .secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var privacyTab: some View {
        Form {
            Section {
                Toggle(CozyBrewL10n.settingsTelemetryToggle, isOn: $telemetryOptIn)
                    .onChange(of: telemetryOptIn) { _, newValue in
                        CozyBrewAppSettings.isTelemetryOptIn = newValue
                    }
                    .accessibilityLabel(CozyBrewL10n.a11ySettingsTelemetry)
            } footer: {
                Text(CozyBrewL10n.settingsTelemetryFooter)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var appVersionString: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var appBuildString: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    private var cakebrewStatusLabel: String {
        switch cakebrewStatus {
        case .noLegacyFound:
            CozyBrewL10n.settingsCakebrewStatusNone
        case .legacyAvailableNotImported:
            CozyBrewL10n.settingsCakebrewStatusPending
        case .importCompleted:
            CozyBrewL10n.settingsCakebrewStatusDone
        }
    }

    private func refreshCakebrewStatus() {
        cakebrewStatus = CakebrewMigration.currentStatus()
    }

    private func runCakebrewImport() {
        migrationIsError = false
        migrationMessage = nil
        do {
            try manager.performCakebrewMigration()
            migrationMessage = CozyBrewL10n.settingsCakebrewImportSuccess
            refreshCakebrewStatus()
        } catch {
            migrationIsError = true
            migrationMessage = error.localizedDescription
        }
    }
}
