# S2J CozyBrew — コード構造と責務

## 1. モジュール分割 (推奨) `{@architecture:s1}`

* **CozyBrewApp (App Target)**

  * 目的:
    * アプリケーション固有のリソース (Assets、Info.plist、App Sandbox/entitlements、メニュー定義、配布設定) を管理します。
  * 依存:
    * `s2j-cozy-brew` (ライブラリ製品) と外部 S2J パッケージ群です。

* **s2j-cozy-brew (Swift Package)**

  * ライブラリ製品:
    * `CozyBrewCore` (library): BrewCore (Process ラッパー、バイナリ検出、インストーラ)、型定義
    * `CozyBrewService` (library): BrewService (JSON パース、キャッシュ、ViewModel/ObservableObject)
    * `CozyBrewUIComponents` (library): 再利用可能な SwiftUI コンポーネント (PackageRow, PackageDetail, InstallFlow)
  * 目的:
    * 他プロジェクトでも利用可能なロジックと UI 部品を提供します。

* **外部依存パッケージ**

  * `s2j-source-list` (サイドバー)
  * `s2j-about-window` (About ウィンドウ)

* **依存関係の更新**

  * npm (`@s2j/docs-linter`) と SPM (上記2パッケージ) の更新手順は [dependency_updates.md](dependency_updates.md) にまとめています。
  * SPM の推奨: `npm run swift:ncu` で確認 → `npm run swift:ncu:update` で最新化 → `swift build` で確認。
  * 現在は `Package.swift` で各リポジトリの `main` を参照し、確定 revision は `Package.resolved` に記録します。
  * サイドバー利用時は **`s2j-source-list` v2.0.14以降** を前提とします (SwiftUI の選択警告を修正。詳細は [dependency_updates.md](dependency_updates.md))。
  * ローカル Swift lint: `npm run lint:swift` (先頭で `npm run xcode:generate` を実行)。

---

## 2. 主要コンポーネント (ディレクトリ構造) `{@architecture:s2}`

```
`s2j-cozy-brew`/
├─ LICENSE
├─ README.md
├─ Package.swift  # Swift Package 定義
├─ Package.resolved  # 依存関係解決結果
├─ package.json  # Docs Linter 設定
├┬─ docs/  # ドキュメント類
│├─ specs.md  # 仕様の起点
│├─ overview.md
│├─ architecture.md
│├─ brew_integration_spec.md
│├─ models_spec.md
│├─ ux_flows_spec.md
│├─ security_spec.md
│├─ design_spec.md
│└─ SPEC.md  # 実装状況サマリ・Backlog 等
├┬─ tools/
│└─ docs-linter  # Git サブモジュール『Docs Linter』
├┬─ scripts/
│├─ test-local_macOS.sh
│└─ test-local.sh
├┬─ CozyBrew.xcodeproj  # Xcode プロジェクト (XcodeGen で生成済み)
│├─ project.pbxproj
│└┬─ project.xcworkspace/
│　├─ contents.xcworkspacedata
│　├── xcuserdata/
│　└┬─ xcshareddata/
│　　├─ WorkspaceSettings.xcsettings
│　　├┬─ swiftpm/
│　　│├─ Package.resolved
│　　│└─ configuration/
│　　└┬─ xcschemes/
│　　　└─ CozyBrewApp.xcscheme
├┬─ CozyBrewApp/  # アプリケーション・プロジェクト (SwiftUI App Target `CozyBrew.app`)
│├─ CozyBrewApp.swift  # アプリケーション・エントリーポイント (Homebrew 未検出時のインストール・フロー含む)
│├─ CozyBrewApp.entitlements  # アプリケーション・リソース (作成済み)
│├─ ContentView.swift  # メイン・コンテンツ・ビュー
│├─ Info.plist  # アプリケーション・リソース (作成済み)
│└┬─ Assets.xcassets/  # アプリケーション・リソース (作成済み)
│　├┬─ AppIcon.appiconset
│　│└─ Contents.json
│　└─ Contents.json
├┬ Sources/  # Swift Package ソースコード
│├┬─ CozyBrewCore/  # コア・モジュール (brew バイナリ検出、プロセス実行、インストーラ)
││├─ BrewBinaryLocator.swift  # brew バイナリ検出 (Apple Silicon/Intel 対応)
││├─ BrewInstaller.swift  # Homebrew インストール補助
││├─ BrewProcess.swift  # 非同期 brew コマンド実行ラッパー
││└─ BrewResult.swift  # 実行結果の型定義
│├┬─ CozyBrewService/  # サービス・モジュール (モデル、ViewModel、キャッシュ)
││├─ BrewCache.swift  # JSON キャッシュ機構 (TTL 対応)
││├─ BrewManager.swift  # ObservableObject ViewModel (パッケージ管理、`refreshApplicationState`)
││├─ BrewCaskTerminalFallback.swift / BrewUserMessage.swift  # Cask 失敗・ターミナル委譲
││├─ BrewCatalog.swift / BrewFormulaeAPIClient.swift  # formulae.brew.sh カタログ
││├─ BrewDoctorParser.swift  # `brew doctor` パース
││└─ Models.swift  # Formula、Cask、Tap、Package モデル定義
│└┬─ CozyBrewUIComponents/  # UI コンポーネント・モジュール
│　├─ MainWindowView.swift  # メイン・ウィンドウ (macOS 15.0+)
│　├─ S2JSourceListAdapter.swift  # S2J Source List 橋渡し (サイドバー)
│　├─ BrewOperationOverlay.swift  # Upgrade 等のオーバーレイ
│　├─ BrewAlertView.swift  # エラー表示
│　├─ InstallFlowView.swift  # インストール・フロー
│　├─ InstallProgressView.swift  # インストール進捗表示
│　├─ PackageDetailView.swift  # パッケージ詳細表示
│　├─ PackageRowView.swift  # パッケージ一覧の行表示
│　├─ PackageUpgradeFailurePanel.swift  # Upgrade 失敗 UI (行下)
│　├─ BrewUpgradeTerminalFallbackView.swift / BrewTerminalLauncher.swift
└┬─ Tests/  # テストコード
　├┬─ CozyBrewCoreTests/
　│├─ BrewBinaryLocatorTests.swift
　│└─ BrewProcessTests.swift
　└┬─ CozyBrewServiceTests/
　　├─ BrewCacheTests.swift
　　├─ BrewCatalogTests.swift / BrewDoctorParserTests.swift  # カタログ・doctor
　　└─ ModelsTests.swift
```

**依存パッケージ** (Package.swift で定義)
* `s2j-source-list` - サイドバー実装用 (GitHub から取得)
* `s2j-about-window` - About ウィンドウ実装用 (GitHub から取得)

---

## 3. コンポーネント責務の概要 `{@architecture:s3}`

### 3.1. マイグレーションと互換性 / Cakebrew からの留意点 `{@architecture:s3-1}`

* Cakebrew は Objective-C / AppKit 実装です。そのため、UI ロジックをそのまま移植せず、**概念 (機能) を再解釈**して SwiftUI に適した状態駆動の設計に変換します。
* Cakebrew のコード (Objective-C) でのライセンス、リソース (アイコン、翻訳) を確認し、再利用条件を満たします。
* Cakebrew の preferences やインストール履歴を引き継ぐ場合:
  * 初回起動時に `Cakebrew` の設定ファイル (保存場所や形式) を検出し、移行ウィザードを表示します (オプション)。

### 3.2. About Window `{@architecture:s3-2}`

* [S2J About Window](https://github.com/stein2nd/s2j-about-window) (≥ v3.0.0) の `AboutView` を `CozyBrewAboutSheet` (`CozyBrewApp/CozyBrewAbout.swift`) 経由でシート表示します。
* アイコン・タイトル・バージョン・著作権はライブラリヘッダー、本文は Markdown (GitHub)。**License** / **Acknowledgements** でバンドル `LICENSE.txt` と `ACKNOWLEDGEMENTS.md` をアプリケーション内表示。メニュー **About CozyBrew** と同一 UI です。

### 3.3. BrewUIComponents (CozyBrewUIComponents) `{@architecture:s3-3}`

* **UI 要素**
  * `PackageRowView`: アイコン、名前、バージョン、バッジ表示 (アップデート有無)、インストール/アンインストール・ボタンを表示します。
  * `PackageDetailView`: `brew info` 情報、依存関係ツリー、README 表示 (Markdown)、ホームページ・リンクを表示します。
  * `InstallProgressView`: ログストリーム、キャンセルボタンを表示します。
  * `BrewAlertView`: friendly error + raw log toggle を表示します。
  * `MainWindow`: Sidebar (S2J Source List) + Content Area (パッケージ一覧、検索、ステータスバー) を表示します。
  * `InstallFlowView`: 確認ダイアログ、進行状況 (ログ表示)、失敗時のロールバック案内 (**View 部品はあるが未配線** — 現状は `PackageRowView` / `PackageDetailView` から直実行)。
  * `BrewOperationOverlay`: Upgrade 等の blocking オーバーレイ (Cask は `passwordFriendly`)。
  * `PackageUpgradeFailurePanel` / `BrewUpgradeTerminalFallbackView`: Cask Upgrade のターミナル委譲 (一覧は対象行の直下)。

* **メインウィンドウ・ツールバー**
  * Warnings 以外: **Refresh** → `BrewManager.refreshApplicationState()` (`brew update` + インストール済み、Outdated 再取得、`isLoading`)。

* **サイドバー**
  * `S2JSourceListAdapter` / `CozyBrewSourceListSidebar` が `S2JSourceList.SidebarView` を `MainWindowView` に載せます。
    * フェーズ1: フラット6セクション (`SidebarItem` 順)。Warnings は `customRowContent` でオレンジバッジ。
    * フェーズ2 (未了): `SourceItem.group` による階層分類 (Installed packages / Catalog 等)。

### 3.4. CozyBrew App Target `{@architecture:s3-4}`

* **責務**
  * アプリケーションメニュー、環境設定、アプリケーションレベルの権限設定と Info.plist を管理します。
  * ビルド設定として、配布用のコード署名 / notarize などを実施します。
  * ローカルユーザーデータの保存 (UserDefaults や App Group 選択に伴う設計) を実装します。
