# S2J CozyBrew — ポーティング個別仕様書 (Swift Package + App Target 方針)

## はじめに

* 本ドキュメントでは、Swift アプリケーション「S2J CozyBrew」の専用仕様を定義します。
* 本アプリケーションの設計は、以下の共通 SPEC に準拠します。
    * [Swift/SwiftUI 共通仕様](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md)
* 以下は、本アプリケーション固有の仕様をまとめたものです。

## 1. プロジェクト概要

* **名称:** S2J CozyBrew
* **Swift Package 名:** s2j-cozy-brew
* **元リポジトリ:** [Cakebrew](https://github.com/brunophilipe/Cakebrew)
* **目的:** AppKit ベースの「Cakebrew」を SwiftUI / Swift を用いて再実装します。
  * コアロジックや再利用可能な部品は Swift Package 化します (s2j-cozy-brew 等)。
  * アプリケーション本体は Xcode App Target (CozyBrew.app) で管理します。
* **対応 OS:** macOS v12.0以上 (可能なら macOS v13+ の API をオプションで活用)
* 設計方針の核:
  * **再利用性 (Package) と実行可能アプリケーション (App Target) の分離** です。
  * UI 再利用部品や Brew 操作ロジックは Swift Package として設計・テスト可能にし、アプリケーション固有のバンドル資産、Info.plist、署名等は App Target に置きます。

S2J CozyBrew (Swift Package 名: `s2j-cozy-brew`) は、AppKit で実装された既存の **Cakebrew** を、**SwiftUI / Swift** ベースに再実装してモダナイズすることを目的とします。
ユーザー層は「ターミナル操作に慣れていない一般ユーザー (for the rest of us)」を想定し、Homebrew (以下 brew) をローカルで安全かつ分かりやすく操作できる GUI アプリケーションを提供します。

---

## 2. 要件ゴール

### 2.1. 機能要件

* Homebrew (brew) と安全に連携する SwiftUI macOS アプリケーションを提供します。
  * brew のコマンド実行 (list / info / install / uninstall / update / upgrade / tap / untap 等) を GUI から行えるようにします。
* Brew の未導入ユーザーに対して、安全で理解しやすい導入 UX を提供します。
  * brew が未導入の場合、公式インストール手順に沿って導入をガイドします (自動化オプションあり)。
  * brew の更新 (アップグレード) 処理は、初心者が安全に実行できる UX を提供します (説明付き、自動バックアップ/ロールバックの考慮)。
  * パッケージ一覧・検索・詳細表示・インストール履歴・ログ表示を提供します。
* コアロジックや UI コンポーネント (サイドバー、About ウィンドウ連携等) を再利用可能な Swift Package として整備します。
  * サイドバーは [S2J Source List](https://github.com/stein2nd/s2j-source-list) を用いて実装します。
  * About ウィンドウは [S2J About Window](https://github.com/stein2nd/s2j-about-window) を採用します。

### 2.2. 非機能要件

* brew の内部実装を再作成しません (CLI をラップします)。
* brew が管理するパッケージの完全な CI 自動テストは本プロジェクトの範囲外です (実環境でのインストールはユーザー端末で行います)。
  * Swift Package (`s2j-cozy-brew`) として管理し、SwiftPM でビルド可能とします。
  * UI は SwiftUI (可能なら macOS v13の `Observation` を利用しますが、最低限 macOS v12対応を保ちます)。
  * セキュリティ: brew 実行は、サンドボックス外のプロセス・コールを行うため、権限/経路の取り扱いを厳密にします。
  * ローカライズ対応 (英語・日本語を初期対応とします)。
  * アクセシビリティ (VoiceOver 等) への対応を実装します。
  * CI: GitHub Actions を用いて macOS ビルド・ユニットテストを実行します。

## 3. 準拠仕様

### 3.1. 技術スタック

* [COMMON_SPEC.md](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md) に準拠します。

### 3.2. 開発ルール

* [COMMON_SPEC.md](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md) に準拠します。

### 3.3. 国際化・ローカライズ

* [COMMON_SPEC.md](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md) に準拠します。

### 3.4. コーディング規約

* [COMMON_SPEC.md](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md) に準拠します。

### 3.5. デザイン規約

* [COMMON_SPEC.md](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md) に準拠します。

### 3.6. テスト方針

* [COMMON_SPEC.md](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md) に準拠します。

## 4. 個別要件

### 4.1. モジュール分割 (推奨)

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

### 4.2. 主要コンポーネント (アーキテクチャー)

```
`s2j-cozy-brew`/
├─ LICENSE
├─ README.md
├─ Package.swift  # Swift Package 定義
├─ Package.resolved  # 依存関係解決結果
├─ package.json  # Docs Linter 設定
├┬─ docs/  # ドキュメント類
│└─ `SPEC.md`  # 本ドキュメント
├┬─ tools/
│└─ docs-linter  # Git サブモジュール『Docs Linter』
├┬─ CozyBrew.xcodeproj  # Xcode プロジェクト (XcodeGen で生成済み)
│└─ Info.plist, Assets.xcassets, CozyBrewApp.entitlements  # アプリリソース (作成済み)
├┬─ CozyBrewApp/  # アプリプロジェクト (SwiftUI App Target `CozyBrew.app`)
│├─ CozyBrewApp.swift  # アプリエントリーポイント (Homebrew 未検出時のインストールフロー含む)
│└─ ContentView.swift  # メインコンテンツビュー
├┬─ Sources/  # Swift Package ソースコード
│├┬─ CozyBrewCore/  # コアモジュール (brew バイナリ検出、プロセス実行、インストーラー)
││├─ BrewBinaryLocator.swift  # brew バイナリ検出 (Apple Silicon/Intel 対応)
││├─ BrewProcess.swift  # 非同期 brew コマンド実行ラッパー
││├─ BrewInstaller.swift  # Homebrew インストール補助
││└─ BrewResult.swift  # 実行結果型定義
│├┬─ CozyBrewService/  # サービスモジュール (モデル、ViewModel、キャッシュ)
││├─ Models.swift  # Formula、Cask、Tap、Package モデル定義
││├─ BrewManager.swift  # ObservableObject ViewModel (パッケージ管理)
││└─ BrewCache.swift  # JSON キャッシュ機構 (TTL 対応)
│└┬─ CozyBrewUIComponents/  # UI コンポーネントモジュール
│　├─ PackageRowView.swift  # パッケージ一覧の行表示
│　├─ PackageDetailView.swift  # パッケージ詳細表示
│　├─ InstallProgressView.swift  # インストール進捗表示
│　├─ BrewAlertView.swift  # エラー表示
│　├─ MainWindowView.swift  # メインウィンドウ (macOS 12.0/13.0 対応)
│　└─ InstallFlowView.swift  # インストールフロー
└┬─ Tests/  # テストコード
　├┬─ CozyBrewCoreTests/
　│├─ BrewBinaryLocatorTests.swift
　│└─ BrewProcessTests.swift
　└┬─ CozyBrewServiceTests/
　　├─ ModelsTests.swift
　　└─ BrewCacheTests.swift
```

**依存パッケージ** (Package.swift で定義)
* `s2j-source-list` - サイドバー実装用 (GitHub から取得)
* `s2j-about-window` - About ウィンドウ実装用 (GitHub から取得)

### 4.3. 詳細設計

### 4.3.1. マイグレーションと互換性 / Cakebrew からの留意点

* Cakebrew は Objective-C / AppKit 実装です。そのため、UI ロジックをそのまま移植せず、**概念 (機能) を再解釈**して SwiftUI に適した状態駆動の設計へ変換します。
* Cakebrew のコード (Objective-C) でのライセンス、リソース (アイコン、翻訳) を確認し、再利用条件を満たします。
* Cakebrew の preferences やインストール履歴を引き継ぐ場合:
  * 初回起動時に `Cakebrew` の設定ファイル (保存場所や形式) を検出し、移行ウィザードを表示します (オプション)。

### 4.3.2. About Window

* [S2J About Window](https://github.com/stein2nd/s2j-about-window) を組込み、`About` ボタンから `S2JAboutWindow` を表示します。About の Contents に `CozyBrew` ロゴ、ライセンス、サポート・リンクを含めます。

### 4.3.3. BrewCore (s2j-cozy-brew / CozyBrewCore)

* **機能**
  * brew バイナリ検出 (`BrewBinaryLocator`):
    * Apple Silicon (`/opt/homebrew/bin/brew`) と Intel (`/usr/local/bin/brew`) を判定し、`which brew` の代替として機能します。環境 PATH の補正ロジックを実装します。
  * `Process` コマンド実行ラッパー (`BrewCommand` / `BrewProcess`):
    * brew 実行、環境 PATH 解決、出力エンコーディング、エラー処理を一元化します。
    * `/usr/bin/env brew ...` を非同期に実行し stdout/stderr/exitCode を返します。標準入出力をストリームへ流すため、リアルタイム・ログに対応します。
  * 権限・実行コンテキスト管理:
    * brew の実行ユーザー権限、環境変数 (HOMEBREW_PREFIX) を把握します。
  * インストーラー (`BrewInstaller`):
    * brew 未導入時の公式インストール・スクリプトの実行補助を行います (ユーザー許諾確認、ログ表示、失敗時の対処説明を含みます)。
    * 導入スクリプト実行ロジックを実装します (ユーザー承認の UI フローを前提とします)。

* **API 設計 (例)**

```swift
public struct BrewResult { public let stdout: String; public let stderr: String; public let code: Int32 }

public final class BrewProcess {
    public static func run(_ args: [String], environment: [String:String]? = nil) async throws -> BrewResult
}
```

**例: BrewCommand (非同期)**

```swift
struct BrewCommand {
    static func run(_ args: [String], env: [String:String]? = nil) async throws -> (stdout: String, stderr: String, exitCode: Int32) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["brew"] + args
        if let env = env { process.environment = env }

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        try process.run()
        process.waitUntilExit()

        let out = String(data: outPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return (out, err, process.terminationStatus)
    }
}
```

### 4.3.4. BrewService (s2j-cozy-brew / CozyBrewService)

* **機能**
  * `Package` / `Formula` / `Cask` / `Tap` を表現する `Codable` モデルを実装します (`brew info --json=v2` の構造に合わせます)。
  * キャッシュ機構 (`BrewCache`):
    * JSON とローカル DB (軽量: SQLite or realm or simple file) によるキャッシュ管理を実装します。
    * ローカル JSON キャッシュ + TTL を持たせます。オプションで SQLite (GRDB 等) を選択可能とします。
  * Manager / ViewModel (`BrewManager`: `ObservableObject`):
    * ViewModel 層への公開 API (`@Published var installed: [Package]` など) を提供します。
    * UI 側に `@Published` プロパティで状態を公開します (installed, outdated, taps, searchResults など)。
  * Installer / Upgrader:
    * インストール、アンインストール、アップデートの実行と進行管理を実装します。

* **失敗ハンドリング**
  * ユーザー向けメッセージ翻訳レイヤを挟みます (dev message → friendly message)。
  * 詳細ログは UI から "Show log" で閲覧可能です。

### 4.3.5. BrewUIComponents (s2j-cozy-brew / CozyBrewUIComponents)

* **UI 要素**
  * `PackageRowView`:
    * アイコン、名前、バージョン、バッジ表示 (アップデート有無)、インストール/アンインストール・ボタンを表示します。
  * `PackageDetailView`:
    * `brew info` 情報、依存関係ツリー、README 表示 (Markdown)、ホームページ・リンクを表示します。
  * `InstallProgressView`:
    * ログストリーム、キャンセルボタンを表示します。
  * `BrewAlertView`:
    * friendly error + raw log toggle を表示します。
  * `MainWindow`:
    * Sidebar (S2J Source List) + Content Area (パッケージ一覧、検索、ステータスバー) を表示します。
  * `InstallFlowView`:
    * 確認ダイアログ、進行状況 (ログ表示)、失敗時のロールバック案内を表示します。

* **サイドバー**
  * `S2JSourceListAdapter` は既存の S2J Source List を SwiftUI から利用しやすくする薄い適合レイヤを提供します。
    * 目的:
      * サイドバーのセクション管理、アイコン・バッジ、フォルダー/タブのような分類 (Installed / Outdated / Taps / Casks / Formulae) を実装します。

### 4.3.6. CozyBrew App Target

* **責務**
  * アプリケーションメニュー、環境設定、アプリケーションレベルの権限設定と Info.plist を管理します。
  * ビルド設定として、配布用のコード署名 / notarize などを実施します。
  * ローカルユーザーデータの保存 (UserDefaults や App Group 選択に伴う設計) を実装します。

* **エントリー (例)**

```swift
@main
struct CozyBrewApp: App {
    @StateObject var manager = BrewManager()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(manager)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About CozyBrew") { /* show s2j-about-window */ }
            }
        }
    }
}
```

### 4.3.7. パッケージ記述例 (Package.swift 抜粋)

```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "s2j-cozy-brew",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "CozyBrewCore", targets: ["CozyBrewCore"]),
        .library(name: "CozyBrewService", targets: ["CozyBrewService"]),
        .library(name: "CozyBrewUIComponents", targets: ["CozyBrewUIComponents"]),
        .executable(name: "CozyBrewApp", targets: ["CozyBrewApp"]) // App target for development
    ],
    dependencies: [
        // S2J packages
        .package(url: "https://github.com/stein2nd/s2j-source-list.git", from: "0.1.0"),
        .package(url: "https://github.com/stein2nd/s2j-about-window.git", from: "0.1.0"),
    ],
    targets: [
        .target(name: "CozyBrewCore", dependencies: []),
        .target(name: "CozyBrewService", dependencies: ["CozyBrewCore"]),
        .target(name: "CozyBrewUIComponents", dependencies: ["CozyBrewService","s2j-source-list","s2j-about-window"]),
        .target(name: "CozyBrewApp", dependencies: ["CozyBrewService","s2j-source-list","s2j-about-window"], resources: [.process("Resources")]),
        .testTarget(name: "CozyBrewTests", dependencies: ["CozyBrewCore","CozyBrewService"])   
    ]
)
```

### 4.3.8. UX フロー (主要ケース)

### 4.3.8.1. 初回起動

1. アプリケーション起動 → BrewBinaryLocator で、Brew を検出します。
2. 未導入:
  * ユーザーに「Homebrew が見つかりません」と表示し、導入手順を説明します (なぜ必要か、ダウンロード元、必要な権限)。
   * "Install Homebrew" ボタンで公式インストール・スクリプト (`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`) を実行するオプションを提示します。
   * セキュリティ注意喚起と、必要な権限 (パスワード入力) を明記します。
   * ユーザー選択で、公式スクリプトを実行します (実行中はログをリアルタイム表示します)。
   * インストール成功後、環境を再検出し BrewManager を初期化します (brew パスを検出しサービスを起動します)。
3. 導入済:
  * バージョン取得と、Apple Silicon / Intel に応じた PATH 設定を検証します。
  * `brew update` の実行案内 (自動 or 手動選択)。「初心者向けの説明 (何が起きるか)」を表示します。

**設計上の注意**:
  * 自動導入は *opt-in*、つまり、ユーザー承諾必須です。強制的な sudo は避けます。
  * スクリプトの実行は標準出力で行います。エラーをリアルタイム表示し、失敗時のログ保存を行います。
  * インストール中は明確な進捗とロールバック手順を表示します。

### 4.3.8.2. 一般的フロー (パッケージ操作)

* 検索 → 一覧 → 詳細 → Install / Uninstall / Upgrade を実行します。
  * インストールを含む各操作は、非同期でプログレス表示し、完了/失敗通知を UI に反映します (キャンセル可能とします)。
* Upgrade All は明確な確認プロンプトを表示します (依存関係の大きな変更に対する注意喚起)。
* 失敗時は CLI のエラーメッセージをフレンドリーな文に意訳して提示しつつ、"Show raw log" も表示します。

### 4.4. セキュリティ / 権限 / プライバシー

* **実行権限**:
  * brew 自体は通常ユーザー権限で動作します。sudo を要求しない設計をまず目指します (brew は通常 sudo を要求しません)。
* **スクリプト実行**:
  * 公式インストール・スクリプトはネットワークから取得するため、その実行は、**ユーザーの明示的承諾** を必須とします。ダウンロード先 URL は固定し、ユーザーに提示します。
  * 実行ログはローカルに保存し、ユーザーに提示しますが、デフォルトで送信しません (クラッシュ/クラッシュログ等も同様です)。
* **プライバシー**:
  * デフォルトでテレメトリー/クラッシュ・レポートはオフです。送る場合は opt-in にします。
  * もし匿名統計を送る場合は opt-in の設定を提供し、プライバシーポリシーを同梱します。

### 4.5. アクセシビリティとローカライズ

* 初期ロケール:
  * 英語 (en) / 日本語 (ja)。`Localizable.strings`、`Localizable.stringsdict` を用意します。
* UI (すべてのインタラクティブ要素) には、VoiceOver 対応の AccessibilityLabel を必ず設定します。
* コントラストとフォントサイズ可変 (Dynamic Type 相当) を考慮した配色とレイアウト (macOS システム設定に準拠します)。

---

## 5. デザイン・チップ (Cozy ブランド)

* ロゴ: 角丸、シンプルなカップ/湯気モチーフ (前出の CozyBrew ロゴ案を参照します)。
* アプリケーション・アイコン: 1024×1024px PNG / SVG を用意します。
* 配色: ベース色 (Warm beige + Deep brown) に、小さなアクセント色 (ソフトブルーやミント) を検討します。
* フォント: SF Rounded 系か Nunito。UI では Apple の San Francisco を優先し、ブランディング用ロゴで丸みフォントを使用します。

## 6. テスト戦略

* **ユニットテスト** (swift test):
  * BrewCore (コマンド構築・パース)、BrewService (JSON パース)、ViewModel ロジックをテストします。
* **擬似 Integration テスト (モック & フェイク)**:
  * `brew` コマンド呼び出しは (実際に呼ばずに) モック可能なインターフェイスを提供して CI 上で deterministic な (エンド・ツー・エンドの振る舞い確認) テストを実行します。
* **UI テスト**:
  * XCUITest による主要フロー (起動、検索、インストールフロー) を自動化します。ただし brew 実行は実機環境ではモックかスキップして実行します。

## 7. CI / CD

* Swift Package のビルド成果物 (バイナリ / XCFramework) は Git 管理対象外です。
* Tag ルール:
  * `vMAJOR.MINOR.PATCH`
* **GitHub Actions**:
  * ワークフロー (macOS runner) で `swift build` / `swift test` を実行します。
  * Pull Request に対して「SwiftLint」と「ビルド確認」を実行します。
* **Release**:
  * Xcode の Archive を利用したビルド `xcodebuild` (Universal Binary 推奨) を実行します。
  * Notarize / Notarization ステップは手順化します (可能なら自動化スクリプトを提供します)。
  * 生成されたリリース用ビルドは、Artifacts として管理します。
  * リリース・アセット: ソース + API Reference ドキュメントを含みます。

## 8. 開発スケジュール (提案)

* Phase0 (1–2週間): 仕様確定、リポジトリ骨組み、Package レイアウト、BrewCore 基本実装
* Phase1 (3–6週間): BrewService / Model の実装、キャッシュ、サンプル UI (一覧・検索)
* Phase2 (3–5週間): 詳細ビュー、インストール・フロー、S2J Source List / S2J About 統合
* Phase3 (2–4週間): ローカライズ、アクセシビリティ、テスト整備、CI 設定
* Phase4 (1–2週間): CI/Release build、Notarize、リリース準備

## 9. 開発上のチェックリスト (短縮)

* brew バイナリ検出ロジック実装
* BrewProcess (非同期) 実装
* JSON モデル (`brew info --json=v2`) 実装
* BrewManager (ObservableObject) 実装
* S2J Source List Adapter 実装
* S2J About Window 統合
* 初回起動時インストールフロー実装 (opt-in)
* CI (macOS) ワークフロー実装
* ローカライズ (en/ja) 実装

## 11. 実装状況サマリー

本章では、「現在の実装状況」を記載します。

**主要な成果**:

### 11.1. 完全実装済み機能 (100% 完了)

#### 11.1.1. Swift Package 基盤
* ✅ `Package.swift` - Swift Package 定義 (CozyBrewCore、CozyBrewService、CozyBrewUIComponents)
  * ✅ `swift-tools-version: 5.9` に更新済み
* ✅ 依存関係の管理 (s2j-source-list、s2j-about-window)
* ✅ 依存関係の更新スクリプト (`package.json` に `swift:update`、`swift:resolve`、`swift:show-deps` を追加)
* ✅ ビルド成功確認

#### 11.1.2. CozyBrewCore モジュール
* ✅ `BrewBinaryLocator` - brew バイナリ検出 (Apple Silicon `/opt/homebrew/bin/brew`、Intel `/usr/local/bin/brew`、`which brew` フォールバック)
* ✅ `BrewProcess` - 非同期 brew コマンド実行ラッパー (環境変数に対応、stdout/stderr 分離)
* ✅ `BrewInstaller` - Homebrew インストール補助 (リアルタイム・ログ出力対応)
* ✅ `BrewResult` - 実行結果の型定義

#### 11.1.3. CozyBrewService モジュール
* ✅ `Models` - Formula、Cask、Tap、Package モデル定義 (Codable 準拠、`brew info --json=v2` 対応)
* ✅ `BrewManager` - ObservableObject ViewModel (@MainActor、非同期処理)
  * ✅ インストール済みパッケージ一覧取得
  * ✅ アップデート可能パッケージ一覧取得
  * ✅ Tap 一覧取得
  * ✅ パッケージ検索
  * ✅ インストール/アンインストール/アップグレード操作
  * ✅ brew update 実行
* ✅ `BrewCache` - JSON キャッシュ機構 (TTL 対応、メタデータ管理)

#### 11.1.4. CozyBrewUIComponents モジュール
* ✅ `PackageRowView` - パッケージ一覧の行表示 (アイコン、バッジ、アクションボタン)
* ✅ `PackageDetailView` - パッケージ詳細表示 (説明、バージョン、ホームページ、アクションボタン)
* ✅ `InstallProgressView` - インストール進捗表示 (ログストリーム、キャンセルボタン)
* ✅ `BrewAlertView` - エラー表示 (friendly メッセージ + raw log toggle)
* ✅ `MainWindowView` - メインウィンドウ (macOS v12.0用 HSplitView、macOS v13.0用 `NavigationSplitView`)
* ✅ `InstallFlowView` - インストール・フロー (確認ダイアログ、進行状況、エラー処理)

#### 11.1.5. CozyBrewApp Target
* ✅ `CozyBrewApp.swift` - アプリエントリーポイント
  * ✅ Homebrew 未検出時のインストールフロー実装
  * ✅ 自動インストールオプション (opt-in)
  * ✅ About ウィンドウ統合準備
  * ✅ About ウィンドウの Close ボタン動作実装 (`@Environment(\.dismiss)` を使用)
  * ✅ `AppDelegate` クラスの実装 - macOS アプリのライフサイクル管理
    * ✅ `applicationDidFinishLaunching` - アプリ起動時にウィンドウを前面に表示
    * ✅ `applicationShouldHandleReopen` - Dock アイコンクリック時にウィンドウを表示
    * ✅ `@NSApplicationDelegateAdaptor` を使用して SwiftUI アプリに統合
* ✅ `ContentView.swift` - メインコンテンツビュー
  * ✅ ウィンドウ表示の改善 (`onAppear` でウィンドウを確実に前面に表示)
* ✅ `CozyBrew.xcodeproj` - Xcode プロジェクトファイル (XcodeGen で生成)
* ✅ `Info.plist` - アプリケーション情報設定
* ✅ `Assets.xcassets` - アセットカタログ (アイコン、画像)
* ✅ `CozyBrewApp.entitlements` - アプリケーション権限設定

#### 11.1.6. テストコード
* ✅ `CozyBrewCoreTests` - BrewBinaryLocator、BrewProcess の基本テスト
* ✅ `CozyBrewServiceTests` - Models、BrewCache の基本テスト

#### 11.1.7. CI/CD ワークフロー
* ✅ `.github/workflows/swift-test.yml` - Swift テスト・ワークフロー
  * ✅ `test-swift-package` ジョブ: Swift Package テスト (`swift test --enable-code-coverage`)
  * ✅ `test-xcode-project` ジョブ: Xcode プロジェクトテスト (XcodeGen で生成後、`xcodebuild test`)
    * ✅ XcodeGen の自動インストール (`brew install xcodegen`)
    * ✅ スキーム `CozyBrewApp` でのテスト実行
  * ✅ `build-release` ジョブ: リリースビルド (`xcodebuild build`)
  * ✅ コードカバレッジの Codecov へのアップロード (各ジョブで個別にアップロード)
* ✅ `scripts/test-local.sh` - ローカル・テスト実行スクリプト (統合版)
  * ✅ macOS/iPadOS 対応の汎用スクリプト
  * ✅ Swift Package テストの実行
  * ✅ Xcode プロジェクト生成とテスト (`project.yml` が存在する場合に自動有効化)
  * ✅ iOS/iPadOS シミュレーターでのテスト (オプション)
  * ✅ 環境変数によるカスタマイズ対応 (`SCHEME_NAME`、`ENABLE_XCODE_PROJECT`、`XCODEGEN_AUTO_INSTALL` など)
  * ✅ Package.swift からのデフォルト値自動検出
  * ✅ 優先順位: 1. コマンドライン引数 (npm スクリプトからの引数含む) > 2. 自動検出 (Package.swift から) > 3. 環境変数 > 4. デフォルト値

### 11.2. ほとんど実装済み機能 (85-95% 完了)

#### 11.2.1. About Window 統合
* ⚠️ S2J About Window の統合準備は完了 (プレースホルダー実装)
* ✅ About ウィンドウの Close ボタン動作を実装済み (`@Environment(\.dismiss)` を使用)
* ⚠️ 実際の S2JAboutWindow API に合わせた調整が必要
* ⚠️ `CozyBrewApp.swift` で `S2JAboutWindow` をインポートしているが、`AboutWindowView` は独自実装のプレースホルダー

#### 11.2.2. サイドバー実装
* ⚠️ `S2JSourceList` は `Package.swift` で依存関係として定義されているが、実際のコードでは使用されていない
* ⚠️ `MainWindowView.swift` では独自のサイドバー実装 (`SidebarView`) を使用
* ⚠️ 仕様では `S2JSourceList` を使用することが想定されているが、現状は標準の SwiftUI `List` を使用

### 11.3. 未実装機能

#### 11.3.1. ローカライズ
* ❌ 英語 (en) ローカライズ
* ❌ 日本語 (ja) ローカライズ
* ❌ `Localizable.strings`、`Localizable.stringsdict`

#### 11.3.2. CI/CD
* ✅ `.github/workflows/` ディレクトリを作成済み
* ✅ `.github/workflows/swift-test.yml` - Swift テスト・ワークフロー (Swift Package テスト、Xcode プロジェクトテスト、リリースビルド)
  * ✅ 3つのジョブ構成: `test-swift-package`、`test-xcode-project`、`build-release`
  * ✅ XcodeGen の自動インストールとプロジェクト生成
  * ✅ コードカバレッジの Codecov へのアップロード (各ジョブで個別にアップロード)
* ✅ `scripts/test-local.sh` - ローカルテスト実行スクリプト (統合版)
  * ✅ コミット前にCI/CDと同じテストを実行して問題を早期発見
  * ✅ macOS/iPadOS 対応の汎用スクリプト
  * ✅ Package.swift からのデフォルト値自動検出
  * ✅ 優先順位: 1. コマンドライン引数 (npm スクリプトからの引数含む) > 2. 自動検出 (Package.swift から) > 3. 環境変数 > 4. デフォルト値
  * ✅ 環境変数による柔軟なカスタマイズ
* ❌ `.github/workflows/docs-linter.yml` - ドキュメント・リント・ワークフロー

#### 11.3.3. その他
* ❌ Cakebrew からの設定移行の機能
* ❌ アクセシビリティ (VoiceOver) 対応の詳細実装
* ❌ UI スナップショット・テスト

### 11.4. 実装完了率

**実装完了率の算出方法**:
* 各機能を、0% (未実装)、50% (部分実装)、100% (完全実装) で評価
* カテゴリー別に重み付け平均を算出
* 全体はカテゴリー別完了率の平均

**カテゴリー別完了率**:

| カテゴリー | 完了率 | 備考 |
|---|---|---|
| Swift Package 基盤 | 100% | Package.swift、ビルド成功 |
| CozyBrewCore | 100% | 全機能を実装済み |
| CozyBrewService | 100% | 全機能を実装済み |
| CozyBrewUIComponents | 90% | 全 UI コンポーネント実装済み、S2JSourceList 未統合 |
| CozyBrewApp Target | 98% | 基本の実装完了、リソース作成済み、About ウィンドウの Close ボタン動作実装済み、AppDelegate によるウィンドウ表示問題解決済み、S2JAboutWindow 未統合 |
| テストコード | 70% | 基本テスト実装済み、カバレッジ向上が必要 |
| ローカライズ | 0% | 未実装 |
| CI/CD | 75% | Swift テスト・ワークフロー実装済み、ローカル・テストスクリプト追加済み、ドキュメント・リント・ワークフロー未実装 |
| Xcode プロジェクト | 100% | XcodeGen で生成済み、リソース作成済み |

**全体実装の完了率**: **約80%**

* コア機能 (Package、Core、Service) は、100% 完了
* UI Components は実装済みだが、S2JSourceList の統合が未完了
* アプリケーション・リソース (Xcode プロジェクト、Info.plist、Assets、entitlements) は作成済み
* About ウィンドウの Close ボタン動作は実装済み
* AppDelegate によるウィンドウ表示問題を解決済み (Xcode で Run ボタンをクリックしたときにウィンドウが表示される)
* 依存関係の更新スクリプトを追加済み
* テスト・カバレッジは基本実装のみ
* CI/CD ワークフロー: Swift テスト・ワークフローを実装済み (`.github/workflows/swift-test.yml`)
  * 3つのジョブ構成 (`test-swift-package`、`test-xcode-project`、`build-release`)
  * コード・カバレッジの Codecov へのアップロード
* ローカル・テストスクリプト: `scripts/test-local.sh` を追加済み (macOS/iPadOS 対応の汎用スクリプト)
  * Package.swift からのデフォルト値自動検出機能を実装済み
  * 優先順位: 1. コマンドライン引数 (npm スクリプトからの引数含む) > 2. 自動検出 (Package.swift から) > 3. 環境変数 > 4. デフォルト値
* ローカライズは未実装

### 11.5. 品質評価

* **コード品質**: ✅ 良好
  * Swift のモダンな機能 (async/await、@MainActor) を適切に使用
  * エラーハンドリングを実装
  * 型安全性を確保

* **アーキテクチャー**: ✅ 良好
  * モジュール分割が適切 (Core、Service、UI Components)
  * 依存関係が明確
  * 再利用性を考慮した設計

* **テスト**: ⚠️ 改善の余地あり
  * 基本テストは実装済み
  * カバレッジ向上が必要
  * 統合テスト、UI テストは未実装

* **ドキュメント**: ✅ 良好
  * コードにコメントを記載
  * SPEC.md で仕様を明確化

---

## 12. Backlog

本章では、「今後の予定」を記載します。

**残りの未実装・部分実装の機能**:

### 12.1. 短期での改善予定 (1-3ヵ月)

#### 12.1.1. 外部パッケージ統合の完成
* **S2J About Window 統合**
  * S2J About Window の実際の API に合わせた統合
  * CozyBrew ロゴの追加
  * ライセンス情報の表示
  * サポートリンクの設定
* **S2J Source List 統合**
  * `MainWindowView` のサイドバーを `S2JSourceList` に置き換え
  * 仕様に沿ったサイドバー実装への移行

#### 12.1.2. ローカライズ (初期対応)
* 英語 (en) ローカライズ
  * `Localizable.strings` の作成
  * 主要 UI 要素の翻訳
* 日本語 (ja) ローカライズ
  * `Localizable.strings` の作成
  * 主要 UI 要素の翻訳

#### 12.1.3. CI/CD ワークフロー
* ✅ `.github/workflows/swift-test.yml` の作成 (完了)
  * ✅ `test-swift-package` ジョブ: Swift Package テスト (`swift test --enable-code-coverage`)
  * ✅ `test-xcode-project` ジョブ: Xcode プロジェクトテスト (XcodeGen で生成後、`xcodebuild test`)
  * ✅ `build-release` ジョブ: リリースビルド (`xcodebuild build`)
  * ✅ コード・カバレッジの Codecov へのアップロード (各ジョブで個別にアップロード)
* ✅ `scripts/test-local.sh` の作成 (完了)
  * ✅ macOS/iPadOS 対応の汎用ローカルテストスクリプト
  * ✅ Swift Package テスト、Xcode プロジェクト生成とテスト、iOS/iPadOS テストを統合
  * ✅ Package.swift からのデフォルト値自動検出機能を実装
  * ✅ 優先順位: 1. コマンドライン引数 (npm スクリプトからの引数含む) > 2. 自動検出 (Package.swift から) > 3. 環境変数 > 4. デフォルト値
  * ✅ 環境変数によるカスタマイズ対応
* ❌ `.github/workflows/docs-linter.yml` の作成 (未実装)
* ⚠️ テストカバレッジレポートの生成 (部分実装 - Codecov へのアップロードは実装済み)

#### 12.1.4. テストカバレッジ向上
* BrewManager の統合テスト
* UI コンポーネントのユニットテスト
* エッジケースのテスト追加

### 12.2. 中期での改善予定 (3-6ヵ月)

#### 12.2.1. アクセシビリティ対応
* VoiceOver 対応の詳細実装
* すべてのインタラクティブ要素に AccessibilityLabel を設定
* キーボードショートカットの実装
* コントラスト比の確認と改善

#### 12.2.2. パフォーマンス最適化
* 大量パッケージ一覧の表示最適化 (仮想化)
* キャッシュ戦略の見直し
* 非同期処理の最適化

#### 12.2.3. エラーハンドリング強化
* より詳細なエラーメッセージの実装
* エラーログの保存機能
* クラッシュレポートの統合 (opt-in)

#### 12.2.4. UI/UX 改善
* パッケージ検索のリアルタイム更新
* インストール履歴の表示
* 依存関係ツリーの可視化
* ダークモード対応の確認と調整

#### 12.2.5. Cakebrew からの移行機能
* Cakebrew 設定ファイルの検出
* 移行ウィザードの実装
* インストール履歴の移行

### 12.3. 長期での改善予定 (6ヵ月以上)

以下の機能は、将来の拡張として検討する項目です。

#### 12.3.1. 高度な機能
* パッケージのバックアップ/リストア機能
* カスタム Tap の管理強化
* パッケージの依存関係の分析ツール
* バッチ操作 (複数パッケージの一括インストール/アンインストール)

#### 12.3.2. 統合機能
* ターミナル統合 (brew コマンドの実行ログ表示)
* 通知機能 (アップデート通知、インストール完了通知)
* 統計情報の表示 (インストール済みパッケージ数、ディスク使用量など)

#### 12.3.3. プラットフォーム拡張
* iPadOS 対応の検討
* iOS 対応の検討 (リモート管理など)

#### 12.3.4. コミュニティ機能
* パッケージレビュー機能
* おすすめパッケージの表示
* コミュニティフィードバックの収集

---

## Appendix A: Xcode プロジェクト作成ウィザード推奨選択肢リスト

* [COMMON_SPEC.md](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md) に準拠します。

**補足**:
* 本プロジェクトは Swift Package として他アプリケーションに組み込まれることを前提とします。そのため、Xcode ウィザードで「App」テンプレートを選ぶ必要はありません。
* macOS/iPadOS 両対応の Swift Package として作成する場合は、「Framework」または「Swift Package」テンプレートを使用し、対応プラットフォームを .macOS (.v12)、.iOS (.v15) と指定します。
* また、本リポジトリでは Git サブモジュール [Docs Linter](https://github.com/stein2nd/docs-linter) を導入し、ドキュメント品質 (表記揺れや用語統一) の検証を CI で実施します。
* **注意**: 実際のプロジェクトでは、XcodeGen (`project.yml`) を使用して Xcode プロジェクトを生成しています。このセクションは、手動で Xcode プロジェクトを作成する場合の参考情報です。

### 1. テンプレート選択

* **Platform**: Multiplatform (macOS、iPadOS)
* **Template**: Framework または Swift Package

### 2. プロジェクト設定

| 項目 | 推奨値 | 理由 |
|---|---|---|
| Product Name | `s2j-cozy-brew` | `SPEC.md` のプロダクト名と一致 |
| Team | Apple ID に応じて設定 | コード署名のため |
| Organization Identifier | `com.s2j` | ドメイン逆引き規則、一貫性確保 |
| Interface | SwiftUI | SwiftUI ベースを前提 |
| Language | Swift (Swift v7.0) | Xcode v26.0.1に同梱される Swift バージョン (Objective-C は不要) |
| Use Core Data | Off | データ永続化不要 |
| Include Tests | On | `SPEC.md` にもとづきテストを考慮 |
| Include CloudKit | Off | 不要 |
| Include Document Group | Off | Document-based App ではない |
| Source Control | On (Git) | `SPEC.md` / GitHub 運用をリンクさせるため |

### 3. デプロイ設定

| 項目 | 推奨値 | 理由 |
|---|---|---|
| macOS Deployment Target | macOS v12.0以上 | SwiftUI の `List` / `OutlineGroup` API が安定するバージョン |
| iOS Deployment Target | iPadOS v15.0以上 | `.sheet` / `.popover` の SwiftUI API が安定するバージョン |

### 4. 実行確認の環境 (推奨)

| プラットフォーム | 実行確認ターゲット | 理由 |
|---|---|---|
| macOS | macOS v13 (Ventura) 以降 | `List` / `OutlineGroup` の動作確認 |
| iPadOS | iPadOS v16以降 (iPad Pro シミュレーター) | `List` の UI 挙動確認 |

### 5. CI ワークフロー補足

**実装状況**: ⚠️ **部分実装** - Swift テスト・ワークフローは実装済み、ドキュメント・リント・ワークフローは未実装

* 本プロジェクトでは、以下の GitHub Actions ワークフローを導入しています。
    * ✅ `swift-test.yml`: Swift Package のユニットテストおよび Xcode プロジェクトテストの自動実行 (実装済み)
      * **`test-swift-package` ジョブ**:
        * Swift Package テスト (`swift test --enable-code-coverage`)
        * コードカバレッジの Codecov へのアップロード (`swift-package` フラグ)
      * **`test-xcode-project` ジョブ**:
        * XcodeGen の自動インストール (`brew install xcodegen`)
        * Xcode プロジェクト生成 (`xcodegen generate`)
        * Xcode プロジェクトテスト (`xcodebuild test -scheme CozyBrewApp`)
        * コードカバレッジの Codecov へのアップロード (`xcode-project` フラグ)
      * **`build-release` ジョブ**:
        * `test-swift-package` と `test-xcode-project` の成功後に実行
        * Xcode プロジェクト生成
        * リリースビルド (`xcodebuild build -configuration Release`)
        * ビルド成果物のアップロード (Artifacts)
    * ❌ `docs-linter.yml`: Markdown ドキュメントの表記揺れ検出 (Docs Linter) (未実装)
* **ローカルテストスクリプト**:
  * ✅ `scripts/test-local.sh`: コミット前にCI/CDと同じテストを実行して問題を早期発見
    * macOS/iPadOS 対応の汎用スクリプト
    * Swift Package テスト、Xcode プロジェクト生成とテスト、iOS/iPadOS テストを統合
    * Package.swift からのデフォルト値自動検出機能を実装
    * 優先順位: 1. コマンドライン引数 (npm スクリプトからの引数含む) > 2. 自動検出 (Package.swift から) > 3. 環境変数 > 4. デフォルト値
    * 環境変数によるカスタマイズ対応 (`SCHEME_NAME`、`ENABLE_XCODE_PROJECT`、`XCODEGEN_AUTO_INSTALL` など)
    * **利用例**:
      ```zsh
      # 基本的な使用方法 (Package.swift から自動検出)
      ./scripts/test-local.sh

      # npm スクリプトから引数を渡す場合
      npm run test:local -- --skip-ios
      npm run test:local -- --scheme-name MyApp --ios-device "iPhone 15"

      # 環境変数でカスタマイズする場合
      SCHEME_NAME=MyApp IOS_DEVICE="iPhone 15" ./scripts/test-local.sh

      # コマンドライン引数で直接指定する場合
      ./scripts/test-local.sh --scheme-name MyApp --ios-device "iPhone 15" --skip-ios
      ```
* macOS Runner では `swift test --enable-code-coverage` を実行し、テストカバレッジを出力します。
* 本プロジェクトは macOS 専用のため、iPadOS 互換性テストは対象外です。

## Appendix B: 開発上の留意点 (短文まとめ)

* `brew` コマンドの出力は `--json=v2` を活用してパース安定化を図ります。
* Apple Silicon と Intel の brew パス差に注意し、必ず検出ロジックを入れます。
* 自動実行系 (インストール/アップグレード) は必ずユーザーの明示許可を得る設計にします。
* ユーザーに対するエラーメッセージは "friendly" に書き換えつつ、"詳細ログ表示" を併設します。
