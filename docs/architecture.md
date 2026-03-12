<!-- 
目的：「コード構造と責務」の明文化
 -->
# S2J CozyBrew — コード構造と責務

## 1. モジュール分割 (推奨)

* **CozyBrewApp (App target)**

  * 目的:
    * アプリケーション固有のリソース (Assets、Info.plist、App Sandbox/entitlements、メニュー定義、配布設定) を管理します。
  * 依存:
    * `s2j-cozy-brew` (ライブラリ製品) と外部 S2J パッケージ群です。

* **s2j-cozy-brew (Swift Package)**

  * ライブラリ製品:
    * `CozyBrewCore` (library): BrewCore (Process ラッパー、バイナリ検出、インストーラー)、型定義
    * `CozyBrewService` (library): BrewService (JSON パース、キャッシュ、ViewModel/ObservableObject)
    * `CozyBrewUIComponents` (library): 再利用可能な SwiftUI コンポーネント (PackageRow, PackageDetail, InstallFlow)
  * 目的:
    * 他プロジェクトでも利用可能なロジックと UI 部品を提供します。

* **外部依存パッケージ**

  * `s2j-source-list` (サイドバー)
  * `s2j-about-window` (About ウィンドウ)

* **依存関係の更新方法**

  * 本プロジェクトでは、Swift Package Manager (SPM) を使用して外部依存パッケージを管理しています。
  * 依存関係の定義は `Package.swift` に記載されており、現在は各パッケージの `main` ブランチを参照しています。
  * 依存関係を最新の状態に更新するには、以下の方法があります:

    * **方法1: npm スクリプトを使用 (推奨)**
      ```zsh
      npm run swift:update
      ```
      * `package.json` に定義されたスクリプトを使用して、すべての依存関係を最新の `main` ブランチに更新します。

    * **方法2: Swift Package Manager を直接使用**
      ```zsh
      swift package update
      ```
      * Swift Package Manager のコマンドを直接実行して依存関係を更新します。

    * **方法3: Xcode から更新**
      * Xcode でプロジェクトを開き、`File → Packages → Update to Latest Package Versions` を選択します。

    * **依存関係の状態確認**
      ```zsh
      npm run swift:show-deps
      ```
      * 現在の依存関係ツリーを表示します。

  * **注意事項**:
    * 現在の設定では、`Package.swift` で `branch: main` を指定しているため、`swift package update` を実行すると、常に各リポジトリの `main` ブランチの最新コミットを取得します。
    * 特定のバージョンに固定したい場合は、`Package.swift` でバージョンやタグを指定できます (例: `.package(url: "...", from: "1.0.0")`)。
    * 現在のリビジョンは `Package.resolved` に記録されているため、いつでも確認できます。

---

## 2. 主要コンポーネント (ディレクトリ構造)

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
│├┬─ CozyBrewCore/  # コア・モジュール (brew バイナリ検出、プロセス実行、インストーラー)
││├─ BrewBinaryLocator.swift  # brew バイナリ検出 (Apple Silicon/Intel 対応)
││├─ BrewInstaller.swift  # Homebrew インストール補助
││├─ BrewProcess.swift  # 非同期 brew コマンド実行ラッパー
││└─ BrewResult.swift  # 実行結果の型定義
│├┬─ CozyBrewService/  # サービス・モジュール (モデル、ViewModel、キャッシュ)
││├─ BrewCache.swift  # JSON キャッシュ機構 (TTL 対応)
││├─ BrewManager.swift  # ObservableObject ViewModel (パッケージ管理)
││└─ Models.swift  # Formula、Cask、Tap、Package モデル定義
│└┬─ CozyBrewUIComponents/  # UI コンポーネント・モジュール
│　├─ MainWindowView.swift  # メイン・ウィンドウ (macOS 12.0/13.0 対応)
│　├─ BrewAlertView.swift  # エラー表示
│　├─ InstallFlowView.swift  # インストール・フロー
│　├─ InstallProgressView.swift  # インストール進捗表示
│　├─ PackageDetailView.swift  # パッケージ詳細表示
│　└─ PackageRowView.swift  # パッケージ一覧の行表示
└┬─ Tests/  # テストコード
　├┬─ CozyBrewCoreTests/
　│├─ BrewBinaryLocatorTests.swift
　│└─ BrewProcessTests.swift
　└┬─ CozyBrewServiceTests/
　　├─ BrewCacheTests.swift
　　└─ ModelsTests.swift
```

**依存パッケージ** (Package.swift で定義)
* `s2j-source-list` - サイドバー実装用 (GitHub から取得)
* `s2j-about-window` - About ウィンドウ実装用 (GitHub から取得)

---

## 3. コンポーネント責務の概要

### 3.1. マイグレーションと互換性 / Cakebrew からの留意点

* Cakebrew は Objective-C / AppKit 実装です。そのため、UI ロジックをそのまま移植せず、**概念 (機能) を再解釈**して SwiftUI に適した状態駆動の設計へ変換します。
* Cakebrew のコード (Objective-C) でのライセンス、リソース (アイコン、翻訳) を確認し、再利用条件を満たします。
* Cakebrew の preferences やインストール履歴を引き継ぐ場合:
  * 初回起動時に `Cakebrew` の設定ファイル (保存場所や形式) を検出し、移行ウィザードを表示します (オプション)。

### 3.2. About Window

* [S2J About Window](https://github.com/stein2nd/s2j-about-window) を組込み、`About` ボタンから `S2JAboutWindow` を表示します。About の Contents に `CozyBrew` ロゴ、ライセンス、サポート・リンクを含めます。

### 3.3. BrewUIComponents (CozyBrewUIComponents)

* **UI 要素**
  * `PackageRowView`: アイコン、名前、バージョン、バッジ表示 (アップデート有無)、インストール/アンインストール・ボタンを表示します。
  * `PackageDetailView`: `brew info` 情報、依存関係ツリー、README 表示 (Markdown)、ホームページ・リンクを表示します。
  * `InstallProgressView`: ログストリーム、キャンセルボタンを表示します。
  * `BrewAlertView`: friendly error + raw log toggle を表示します。
  * `MainWindow`: Sidebar (S2J Source List) + Content Area (パッケージ一覧、検索、ステータスバー) を表示します。
  * `InstallFlowView`: 確認ダイアログ、進行状況 (ログ表示)、失敗時のロールバック案内を表示します。

* **サイドバー**
  * `S2JSourceListAdapter` は既存の S2J Source List を SwiftUI から利用しやすくする薄い適合レイヤを提供します。
    * 目的: サイドバーのセクション管理、アイコン・バッジ、フォルダー/タブのような分類 (Installed / Outdated / Taps / Casks / Formulae) を実装します。

### 3.4. CozyBrew App Target

* **責務**
  * アプリケーションメニュー、環境設定、アプリケーションレベルの権限設定と Info.plist を管理します。
  * ビルド設定として、配布用のコード署名 / notarize などを実施します。
  * ローカルユーザーデータの保存 (UserDefaults や App Group 選択に伴う設計) を実装します。
