# S2J CozyBrew - CHANGELOG

## unreleased

## 1.0.19 - 2026-11-22

* SPM pin: `s2j-source-list` → `1f7375e`、`s2j-about-window` → `290fbff` (`main`)
* **リファクタ**: Tap / Cakebrew / 履歴記録を `BrewManager+TapAndMigration.swift` に分割 (`replaceOperationHistory`)
* **品質**: `lint:swift` 通過 — `type_body_length`、行長、`optional_data_string_conversion`、`repeatedGuard` (`BrewGitHubReadmeFetcher`)
* **docs**: `architecture.md` に `BrewManager+TapAndMigration` を追記

* **Service**: `BrewOperationHistoryStore`、tap/untap (`addTap` / `removeTap`)、`CakebrewMigration`、`BrewGitHubReadmeFetcher` (`Package.infoMarkdown`)
* **UI**: `ProductShouldViews` (History、Cakebrew シート)、サイドバー History、詳細 README セクション
* **テスト**: `BrewOperationHistoryTests`、`BrewGitHubReadmeFetcherTests`、`CozyBrewUITests` `@MainActor` (Swift v6)
* **docs**: `status.md` プロダクトゴール (Should) 100%、`ux_flows_spec` / `brew_integration_spec` / `architecture` / `testing_spec` 同期

## 1.0.18 - 2026-11-22

* **UI**: サイドバー フェーズ2、`InstallFlowView`、`Upgrade All`、**Taps** (add/untap)、**History**、詳細 **README**、**Cakebrew** 移行シート
* **L10n/A11y**: `CozyBrewL10n` + en/ja `Localizable.strings`、主要画面の `accessibilityLabel`
* **テスト**: [docs/testing_spec.md](docs/testing_spec.md)、`BrewServiceIntegrationTests`、`CozyBrewUIComponentsTests` (`UISnapshotRenderTests`)、`CozyBrewUITests` (XCUITest、ローカル)
* **ビルド**: `Package.swift` / `project.yml` — UI リソース、`CozyBrewUIComponentsTests`、`knownLocalizations` en/ja
* **docs**: `status.md` 各セクション100%追跡、`SPEC.md` / `overview` / `ux_flows` / `architecture` / `security_spec` / `specs.md` 同期

## 1.0.17 - 2026-11-21

* CI `lint-swift`: Periphery を GitHub Release `3.8.0` + `DYLD_LIBRARY_PATH` (Xcode `libIndexStore.dylib`) で導入。Homebrew formula は upstream アーカイブにより deprecated 注釈が出るため

## 1.0.16 - 2026-11-21

* CI `lint-swift`: Periphery を `brew install periphery` (core formula、bottled) で導入。cask / GitHub Release 直置きは `libIndexStore.dylib` 未解決で `periphery version` が abort するため

## 1.0.15 - 2026-11-21

* GitHub Actions `swift-quality.yml` (`version:check` on Ubuntu、`lint:swift` on macOS)
* `docs/status.md` の **CI、ローカル品質** を100% に更新、`docs/SPEC.md` の CI/CD 記述を同期
* `package.json` を v1.0.15 (build: 4) に更新

## 1.0.14 - 2026-11-21

* `package.json` を v1.0.14 (build: 4) に更新
* SPM pin 更新 (`s2j-source-list` revision `0002d648` / `main`、`s2j-about-window` revision `f885a3bf` / `main`)
* ローカル Xcode 向け `CozyBrew.xcodeproj` / `CozyBrewApp` スキームメタデータの同期 (`LastUpgradeVersion` 等)
* npm devDependencies 更新 (`@s2j/acknowledgements` ^0.1.17、`@s2j/docs-linter` ^1.0.34)
* `ACKNOWLEDGEMENTS.md` を再生成 (2026-11-21)

## 1.0.13 - 2026-11-20

* Upgrade 失敗 UI を一覧先頭から **対象行の直下** に移動 (`PackageUpgradeFailurePanel` + `BrewUpgradeTerminalFallbackView`、詳細も同パネル)
* ツールバー **Refresh** を `refreshApplicationState()` に変更 (`brew update` → インストール済み、Outdated、services 再取得、`isLoading` でスピナー)。ターミナルで Cask を上げた後の Outdated 反映向け
* `refreshInstalledPackages` / `refreshOutdatedPackages` に `managingLoading` を追加 (一括 Refresh 時の二重トグル防止)
* Refresh 後に失敗行が Outdated から消えた場合、行下の失敗パネルを自動クリア
* 仕様同期: `brew_integration_spec` §5.3–5.4、`ux_flows_spec` §3.0/§4、`SPEC.md`、`architecture.md`、`overview.md`、`models_spec.md`、`security_spec.md`、`status.md`

* Cask Upgrade が `sudo` / TTY 不足等で GUI 内完了できないとき、一覧・詳細に **Continue in Terminal** を表示 (`MainWindowView` / `PackageDetailView`)
* **Copy Command** / **Run in Terminal** (`BrewUpgradeTerminalFallbackView`、`BrewTerminalLauncher`)。`BrewBinaryLocator` と同じ絶対パスで `brew upgrade --yes --cask` (先頭に `sudo brew` は付けない)
* 失敗ログのヒューリスティクスとコマンド組み立て (`BrewCaskTerminalFallback`)、失敗意訳の更新 (`BrewUserMessage`)
* Terminal 制御用 `NSAppleEventsUsageDescription` を `Info.plist` / `project.yml` に追加
* 仕様・状態: `brew_integration_spec` §5.3、`security_spec` §7、`ux_flows_spec` §2.4、`status.md`
* `BrewCaskTerminalFallbackTests` を追加

## 1.0.12 - 2026-11-16

* メインウィンドウのサイドバーを `S2JSourceList` + `S2JSourceListAdapter` に統合 (`s2j-source-list` v2.0.14以降を前提)
* アプリケーションのバージョンを `package.json` の `version` / `buildNumber` から同期 (`MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`、`scripts/sync-app-version.mjs`、`npm run version:sync` / `version:check` / `version:bump-build`)
* リリース向け npm マイルストーン (`release:after-spm-update` 等、`scripts/release-milestones.sh`) と SPM pin 差分表示 (`npm run swift:pin-diff`)
* `package.json` を v1.0.12 (build: 4) に更新、`project.yml` / `Info.plist` を `$(MARKETING_VERSION)` 参照に変更
* `docs/status.md` を追加 (実装スナップショットの入口)。`docs/*` を現行実装に合わせて更新 (`InstallFlowView` 未配線、`overview` のゴール vs 実装表、完了率の再計算等)
* SPM 依存の pin 更新 (`s2j-source-list` revision `02e3ec4` / `main`、`s2j-about-window` revision `b6a31e1` / `main`。サイドバーは v2.0.14以降を前提)
* 仕様ドキュメント向け見出しタグ付与 (`scripts/apply-heading-tags.py`、`npm run docs:heading-tags`)
* `.textlintrc.json` を `@s2j/docs-linter` base preset + `preset-wp-docs-ja` に更新

## 1.0.11 - 2026-11-13

* デプロイターゲットを **macOS v15.0** に引き上げ (`Package.swift`、`project.yml`、`Info.plist`)
* `s2j-about-window` を **`main` 追従** (v3 / Textual。`s2j-source-list` と同様、`Package.resolved` で revision 固定)
* About で `LICENSE.txt` と `ACKNOWLEDGEMENTS.md` をバンドル同梱し、`licenseResourceName` / `acknowledgementsResourceName` でシート表示
* OSS Notice 生成: `@s2j/acknowledgements` (`ack:doctor` / `ack:generate`)、`ack.config.json` / `onot.yaml`、出力先 `CozyBrewApp/Resources/ACKNOWLEDGEMENTS.md`
* Python v3.13用 `.python-version`、ローカル `venv/` と `build/oss-notice/` を `.gitignore` に追加
* `README.md` の要件表記を macOS v15.0+ に更新
* `docs/SPEC.md`、`docs/overview.md`、`docs/architecture.md` を v15 / About v3 / Acknowledgements 前提に更新
* `docs/dependency_updates.md` に Xcode (`project.yml` → `xcodegen`) と `Package.swift` の SPM 二重管理の手順を追記
* SPM 依存を更新 (`s2j-about-window` → `dafc738` / `main`、`Package.resolved` 同期)

## 1.0.10 - 2026-11-08

* `Package.swift` の最小 macOS を v14.6に上げ、SPM 依存 (S2JSourceList / S2JAboutWindow) との整合を修正
* `lint-docs` ワークフローを Node.js v24・`actions/setup-node@v5`・`ubuntu-24.04` に更新

* SPM 依存を更新 (`s2j-about-window` → `97d4d26` / v2.0.12、`s2j-source-list` → `b700ea4` / v2.0.10)
* About ウィンドウを `S2JAboutWindow.AboutView` に統合し、プレースホルダー `AboutWindowView` を削除 (`CozyBrewAbout.swift`)
* アプリケーションアイコンを `Assets.xcassets` に追加 (Dock 表示用)
* Formulae / Casks サイドバーで未インストールパッケージのカタログ表示を追加 (`formulae.brew.sh` API、`BrewFormulaeAPIClient`、カタログ用モデル・パース)
* カタログ一覧の `A–E` 等ページ切替と検索、読み込み・エラー表示を `MainWindowView` に実装
* カタログ取得時のクラッシュ対策 (`Info.plist` の `CFBundleVersion` を文字列化、明示的 `User-Agent`)
* Swift 向け lint / ビルド用 npm スクリプトをエクステンション (`lint:swiftlint`、`lint:swiftformat`、`lint:periphery`、`lint:build` 等) と設定ファイル (`.swiftlint.yml`、`.periphery.yml`、`.swift-version`)
* Xcode ビルド・解析スキームを `CozyBrewApp` に統一
* カタログ、API パース、モデル周りのユニットテストを追加・更新
* 仕様ドキュメント (`docs/*`) をカタログ UI、Homebrew 連携の実装に合わせて更新
* バージョンを v1.0.10に更新 (`package.json`)

## 1.0.9 - 2026-11-06

* GitHub Actions を Node.js v24対応に更新 (`actions/checkout@v5`、`codecov/codecov-action@v7`、`actions/upload-artifact@v6`)
* `docs-lint` ワークフローの Node.js を v24に更新
* CI 仕様を `docs/SPEC.md` / `overview.md` に反映
* バージョンを v1.0.9に更新 (`package.json`)

## 1.0.8 - 2026-11-06

* SPM 依存を更新 (`s2j-about-window` → `94a9690` / v2.0.10、`s2j-source-list` → `696ecd5` / v2.0.8)
* `scripts/swift-deps.sh` を追加 (`swift:ncu` / `swift:ncu:update` / `swift:install` — npm の `ncu` 相当フロー)
* `docs/dependency_updates.md` を追加し、README / 各仕様から依存更新の手順を参照
* `package.json` に `overrides` を追加 (`glob`、`minimatch`)
* バージョンを v1.0.8に更新 (`package.json`)

## 1.0.7 - 2026-11-06

* `MainWindowView` の `#available` 分岐を削除し、`NavigationSplitView` のみに統一 (`ViewBuilder` の availability 警告を解消)
* `@s2j/docs-linter` を v1.0.32に更新
* バージョンを v1.0.7に更新 (`package.json`)

## 1.0.6 - 2026-10-02

* `@s2j/docs-linter` を v1.0.26に更新
* `.gitignore` に `*.code-workspace` を追加 (ローカル workspace を除外)
* 非推奨の `npm.enableScriptExplorer` を削除 (`.vscode/settings.json`)
* バージョンを v1.0.6に更新 (`package.json`)

## 1.0.5 - 2026-08-31

* `@s2j/docs-linter` を v1.0.23に更新
* SPM 依存を更新 (`s2j-about-window` → `721db87` / v2.0.6、`s2j-source-list` → `8036167` / v2.0.4)
* バージョンを v1.0.5に更新 (`package.json`)

## 1.0.4 - 2026-08-10

* `@s2j/docs-linter` を v1.0.22に更新
* `package.json` に `allowScripts` を追加 (`@s2j/docs-linter` のスクリプト実行を許可)
* バージョンを v1.0.4に更新 (`package.json`)

## 1.0.3 - 2026-07-23

* `@s2j/docs-linter` を v1.0.21に更新
* `.npmrc` を追加 (`legacy-peer-deps=true`、`allow-git=all` — npm v12+ で transitive GitHub 依存を許可)

## 1.0.2 - 2026-06-11

* `project.yml` に `projectFormat: xcode16_3` を追加し、`CozyBrew.xcodeproj` を Xcode v26.3形式 (`objectVersion` 90) に更新
* バージョンを v1.0.2に更新 (`package.json`、`project.yml`、About 画面を含む)
* `README.md` の macOS バッジを v14.0+に修正

## 1.0.1 - 2026-06-11

* Swift v6.3.x および Xcode v26.x に対応
* `CozyBrew.xcodeproj` を Xcode v26.3形式 (`objectVersion` 77) に更新し、推奨ビルド設定を適用
* `swift-tools-version` を v6.0に更新
* `BrewInstaller` のリアルタイム出力処理を Swift v6の並行性チェックに対応
* Xcode プロジェクトを SPM ローカル参照からネイティブ framework ターゲット構成に変更 (パッケージ二重読み込み、リンクエラーを解消)
* framework ターゲットに `GENERATE_INFOPLIST_FILE` を追加 (CodeSign 警告を解消)
* デプロイターゲットを macOS v14.6に統一 (`Info.plist` の `LSMinimumSystemVersion` を含む)
* `Cask` の `name` デコードを配列、文字列の両形式に対応
* `ModelsTests.testCaskDecoding` をデコード検証に修正
* `README.md` に macOS、Xcode バッジを追加
