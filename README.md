# S2J CozyBrew

[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-3.0.en.html)
[![Xcode](https://img.shields.io/badge/Xcode-26.5%2B-blue?logo=Xcode&logoColor=white)](https://developer.apple.com/xcode/)
[![Swift](https://img.shields.io/badge/Swift-6.3-blue?logo=Swift&logoColor=white)](https://www.swift.org)
[![macOS](https://img.shields.io/badge/macOS-15.0%2B-blue?logo=Apple&logoColor=white)](https://www.apple.com/macos/)

## Description

<!-- 
S2J CozyBrew is a modern, SwiftUI-based macOS application for managing Homebrew packages. This application has been ported from the popular [Cakebrew](https://github.com/brunophilipe/Cakebrew) project by Bruno Philipe, bringing its functionality to the SwiftUI ecosystem. It provides a user-friendly GUI for managing Homebrew packages without requiring terminal knowledge, making it accessible to users who prefer graphical interfaces.

The application offers a comprehensive set of features for managing Homebrew packages, including package listing, search, installation, uninstallation, updates, and more. It also includes a guided installation flow for users who don't have Homebrew installed yet.
 -->

S2J CozyBrew は、Homebrew パッケージを管理するためのモダンな SwiftUI ベースの macOS アプリケーションです。本アプリケーションは、Bruno Philipe 制作の人気プロジェクト [Cakebrew](https://github.com/brunophilipe/Cakebrew) から移植され、その機能を SwiftUI エコシステムにもたらしています。ターミナルの知識を必要とせず、Homebrew パッケージを管理できるユーザーフレンドリーな GUI を提供し、グラフィカルインターフェースを好むユーザーにもアクセス可能にしています。

本アプリケーションは、パッケージ一覧、検索、インストール、アンインストール、アップデートなど、Homebrew パッケージを管理するための包括的な機能セットを提供します。また、Homebrew がまだインストールされていないユーザー向けのガイド付きインストールフローも含まれています。

## Features

<!-- 
* **User-friendly GUI**: Perform everyday Homebrew (Formula / Cask) operations without any terminal knowledge
* **Sidebar ([S2J Source List](https://github.com/stein2nd/s2j-source-list))**: Catalogs of Installed / Outdated / Taps / Formulae / Casks, **Warnings** (`brew doctor`), **History** (command history)
* **Listing & Search**: Instant client-side filtering. Package details via `brew info` (JSON + text autocomplete: Keg / Options / Analytics / Runtime) and README (caveats / GitHub)
* **Install / Uninstall / Upgrade**: Execute from the row or details view. **Install** can be reviewed in `InstallFlowView`. From the “Outdated” section, **Upgrade All** (with confirmation)
* **Cask Fallback**: Upgrades that cannot be completed via the GUI (due to lack of `sudo` or TTY, etc.) are delegated to the terminal via the panel below the row (Copy Command / Run in Terminal)
* **Tap Management**: Add Taps; confirmation with a summary from `brew tap-info` before untapping
* **Toolbar Refresh**: Retrieves Installed / Outdated / Taps after `brew update`
* **Brew Not Installed**: Full-screen `BrewNotAvailableView` (official installation script can be run via opt-in)
* **Migration from Cakebrew**: Optionally imports history and other data when detecting old Cakebrew settings
* **Settings…** (⌘,): Cozy Brew-specific (`CozyBrewSettingsView` — version and build number, **Homebrew Environment…** shortcuts, reimport Cakebrew settings, and opt-in for telemetry data saving only)
* **Homebrew Environment…** (⇧⌘ E): Displays `brew config`, key paths, and CozyBrew data in read-only mode (Copy / Finder / Terminal, jump to **Warnings**) — [ux_flows_spec §6](docs/ux_flows_spec.md)
* **About / License**: Display the `AboutView` from the [S2J About Window](https://github.com/stein2nd/s2j-about-window) (v3.0.12 and later) using a SwiftUI `Window` — Classic horizontal header (`classicHorizontal`), version + build number, and **GitHub Repository** at the bottom (`primaryLink`). GPL / Acknowledgments are available offline via a bundled file (`CozyBrewAbout`)
* **Localization**: English and Japanese (`CozyBrewL10n` + `Localizable.strings`. Some menu items, etc., remain in English)
* **Swift Package**: Reusable as `CozyBrewCore` / `CozyBrewService` / `CozyBrewUIComponents`
 -->

* **ユーザーフレンドリーな GUI**: ターミナルの知識なしで Homebrew (Formula / Cask) を日常操作
* **サイドバー ([S2J Source List](https://github.com/stein2nd/s2j-source-list))**: Installed / Outdated / Taps / Formulae / Casks カタログ、**Warnings** (`brew doctor`)、**History** (操作履歴)
* **一覧・検索**: クライアント側の即時フィルター。パッケージ詳細は `brew info` (JSON + テキスト補完: Keg / Options / Analytics / Runtime) と README (caveats / GitHub)
* **Install / uninstall / upgrade**: 行・詳細から実行。**Install** は `InstallFlowView` で確認。Outdated から **Upgrade All** (確認付き)
* **Cask のフォールバック**: `sudo` / TTY 不足などで GUI 完了できない Upgrade は行下パネルからターミナルに委譲 (Copy Command / Run in Terminal)
* **Tap 管理**: Tap の追加、untap 前の `brew tap-info` 要約付き確認
* **ツールバー Refresh**: `brew update` のあと Installed / Outdated / Taps を再取得
* **brew 未導入**: 全画面 `BrewNotAvailableView` (opt-in で公式インストールスクリプト実行可)
* **Cakebrew からの移行**: 旧 Cakebrew 設定の検出時にオプションで履歴などを取り込み
* **Settings…** (⌘,): Cozy Brew 専用 (`CozyBrewSettingsView` — 版・ビルド番号、**Homebrew 環境…** ショートカット、Cakebrew 再取り込み、テレメトリ opt-in 保存のみ)
* **Homebrew 環境…** (⇧⌘ E): `brew config`、主要パス、CozyBrew データを read-only 表示 (コピー / Finder / ターミナル、**Warnings** にジャンプ) — [ux_flows_spec §6](docs/ux_flows_spec.md)
* **About / License**: [S2J About Window](https://github.com/stein2nd/s2j-about-window) (v3.0.12以降) の `AboutView` を SwiftUI `Window` で表示 — クラシック横ヘッダー (`classicHorizontal`)、版 + ビルド番号、下段 **GitHub Repository** (`primaryLink`)。GPL / Acknowledgements はバンドルからオフライン表示 (`CozyBrewAbout`)
* **ローカライズ**: 英語・日本語 (`CozyBrewL10n` + `Localizable.strings`。メニュー等は一部英語)
* **Swift Package**: `CozyBrewCore` / `CozyBrewService` / `CozyBrewUIComponents` として再利用可能

## License

<!-- 
This project is licensed under the GPL v3.0 or later. For details, please refer to the [LICENSE](LICENSE) file.
 -->

本プロジェクトは GPL3.0以降ライセンスの下で提供されています。詳細は [LICENSE](LICENSE) ファイルを参照してください。

## Support and Contact

<!-- 
For support, feature requests, or bug reports, please visit the [GitHub Issues](https://github.com/stein2nd/s2j-cozy-brew/issues) page.
 -->

サポート、機能リクエスト、またはバグ報告については、[GitHub Issues](https://github.com/stein2nd/s2j-cozy-brew/issues) ページをご覧ください。

---

## Installation

### Requirements

<!-- 
* macOS v15.0 or later
* Xcode v26.5 or later
* Swift v6.3 or later
* **Homebrew** must be installed in your runtime environment (the `brew` command must be found in your PATH). Even if it is not installed, the application will launch and display the installation guide.
 -->

* macOS v15.0+
* Xcode v26.5+
* Swift v6.3+
* 実行環境に **Homebrew** (`brew` が PATH 上で検出できること)。未導入でもアプリケーションは起動し、導入ガイドを表示します

### Building from Source

<!-- 
To build the application from source:
 -->

ソースからアプリケーションをビルドするには:

<!-- 
1. Clone the repository:
 -->

1. リポジトリをクローンします:

   ```zsh
   git clone https://github.com/stein2nd/s2j-cozy-brew.git
   cd s2j-cozy-brew
   ```

<!-- 
2. Create an Xcode project (if necessary):
 -->

2. Xcode プロジェクトを生成します (必要な場合):

   ```zsh
   xcodegen generate
   ```

<!-- 
3. Open the project in Xcode:
 -->

3. Xcode でプロジェクトを開きます:

   ```zsh
   open CozyBrew.xcodeproj
   ```

<!-- 
4. Build and run the application in Xcode.
 -->

4. Xcode でアプリケーションをビルドして実行します

### Using as a Swift Package

<!-- 
CoreLogic is available as a Swift package. Add the following to your `Package.swift` file:
 -->

コアロジックは Swift Package として利用可能です。`Package.swift` ファイルに下記を追加します:

```swift
dependencies: [
    .package(url: "https://github.com/stein2nd/s2j-cozy-brew.git", branch: "main")
]
```

<!-- 
This package provides the following products:
 -->

パッケージは下記の製品を提供します:

<!-- 
* `CozyBrewCore` - Core functionality for Homebrew operations
* `CozyBrewService` - Service layer with models and ViewModels
* `CozyBrewUIComponents` - Reusable SwiftUI components
 -->

* `CozyBrewCore` - Homebrew の操作に関する中核機能
* `CozyBrewService` - モデルと ViewModel を含むサービス層
* `CozyBrewUIComponents` - 再利用可能な SwiftUI コンポーネント

## Usage

### First Launch

<!-- 
When you launch S2J CozyBrew for the first time, the application checks to see if Homebrew is installed on your system. If Homebrew is not found, a guided installation process will appear to help you install Homebrew safely.
 -->

S2J CozyBrew を初めて起動すると、アプリケーションはシステムに Homebrew がインストールされているか確認します。Homebrew が見つからない場合、Homebrew を安全にインストールするためのガイド付きインストールフローが表示されます。

### Managing Packages

<!-- 
If Homebrew is installed and detected:
 -->

Homebrew がインストールされ、検出されると:

<!-- 
* **Sidebar**: Switch between sections to view the list. Under **Warnings**, you can view the results of `brew doctor`, and under **History**, you can check the history of operations such as install, upgrade, and tap.
* **Search**: Filter by name in the list (searches as you type). The search bar is hidden when viewing details.
* **Actions**: Install (confirmation dialog), uninstall, and upgrade can be performed from a row or the details view. In the “Outdated” section, you can also use **Upgrade All**
* **Details**: Dependencies, `brew info` supplementary section, and README. Use the **Refresh** button in the toolbar to update the main list and run `brew update`
* **Settings & Diagnostics**: **Settings…** (⌘,) and **Homebrew Environment…** (⇧⌘ E); edit paths in Terminal. **About CozyBrew** opens About (version/build, GitHub link, License, Acknowledgements)
 -->

* **サイドバー**: セクションを切り替えて一覧を表示します。**Warnings** で `brew doctor` の結果、**History** で install / upgrade / tap 等の操作履歴を確認できます
* **検索**: 一覧上で名前フィルター (入力即時)。詳細表示中は検索バーを隠します
* **操作**: Install (確認シート) / uninstall / upgrade は行または詳細から。Outdated では **Upgrade All** も利用できます
* **詳細**: 依存関係、`brew info` 補足セクション、README。ツールバー **Refresh** で `brew update` と主要一覧を更新します
* **設定・診断**: **Settings…** (⌘,) でアプリケーション設定 (環境ウィンドウへのショートカット含む)、**Homebrew 環境…** (⇧⌘ E) で `brew config` 等を参照 (編集はターミナル)。**About CozyBrew** で About (版・ビルド、GitHub、License / Acknowledgements)

<!-- 
For implementation details, see [docs/overview.md](docs/overview.md) §2.1.1 and [docs/ux_flows_spec.md](docs/ux_flows_spec.md).
 -->

実装の詳細は [docs/overview.md](docs/overview.md) §2.1.1と [docs/ux_flows_spec.md](docs/ux_flows_spec.md) を参照してください。

## Development

### Project Structure

<!-- 
This project follows a hybrid structure that includes both a Swift package and an Xcode app target:
 -->

このプロジェクトは、Swift Package と Xcode App Target の両方を持つハイブリッド構造に従っています:

<!-- 
* `Sources/` — Swift Package source code
* `CozyBrewCore/` — `brew` binary detection, asynchronous `BrewProcess`, and installation assistance when not yet installed
  * `CozyBrewService/` — `BrewManager`, models, cache, doctor / catalog API, operation history, environment snapshots (`BrewEnvironmentInfo`), `CozyBrewAppSettings`
  * `CozyBrewUIComponents/` — Main window, Install flow, Details and Failure UI, `CozyBrewSettingsView` / `BrewEnvironmentView`, en/ja resources
* `CozyBrewApp/` — SwiftUI `@main` (`WindowGroup` + `Settings` + About / `Window` for environment), `CozyBrewAbout` (body text, `primaryLink`, License / Ack resource names)
* `scripts/install-applications.sh` — Builds the Release `.app` and copies it to `/Applications` (`npm run build:release` / `install:applications*`)
* `Tests/` — `CozyBrewCoreTests` / `CozyBrewServiceTests` / `CozyBrewUIComponentsTests` / `CozyBrewUITests` (XCUITest is local)
* `docs/` — Specifications and status ([docs/status.md](docs/status.md), [docs/SPEC.md](docs/SPEC.md))
* `Package.swift` / `Package.resolved` — SPM (Dependencies: `s2j-source-list`, `s2j-about-window`)
* `project.yml` — XcodeGen (Generates `CozyBrew.xcodeproj` with `npm run xcode:generate`)
* `package.json` — Official version numbers (`version` / `buildNumber`), lint / test / release npm scripts
 -->

* `Sources/` — Swift Package ソースコード
  * `CozyBrewCore/` — `brew` バイナリ検出、非同期 `BrewProcess`、未導入時インストール補助
  * `CozyBrewService/` — `BrewManager`、モデル、キャッシュ、doctor / カタログ API、操作履歴、環境スナップショット (`BrewEnvironmentInfo`)、`CozyBrewAppSettings`
  * `CozyBrewUIComponents/` — メインウィンドウ、Install フロー、詳細・失敗 UI、`CozyBrewSettingsView` / `BrewEnvironmentView`、en/ja リソース
* `CozyBrewApp/` — SwiftUI `@main` (`WindowGroup` + `Settings` + About / 環境用 `Window`)、`CozyBrewAbout` (本文、`primaryLink`、License / Ack リソース名)
* `scripts/install-applications.sh` — Release `.app` のビルド、`/Applications` への `ditto` (`npm run build:release` / `install:applications*`)
* `Tests/` — `CozyBrewCoreTests` / `CozyBrewServiceTests` / `CozyBrewUIComponentsTests` / `CozyBrewUITests` (XCUITest はローカル)
* `docs/` — 仕様・状態 ([docs/status.md](docs/status.md)、[docs/SPEC.md](docs/SPEC.md))
* `Package.swift` / `Package.resolved` — SPM (依存: `s2j-source-list`、`s2j-about-window`)
* `project.yml` — XcodeGen (`npm run xcode:generate` で `CozyBrew.xcodeproj` を生成)
* `package.json` — バージョン番号正本 (`version` / `buildNumber`)、lint / テスト / リリース用 npm スクリプト

### Setting Up Development Environment

<!-- 
To set up the development environment for this project:
 -->

このプロジェクトの開発環境をセットアップするには:

<!-- 
1. Clone the repository:
 -->

1. リポジトリをクローンします:

   ```zsh
   git clone https://github.com/stein2nd/s2j-cozy-brew.git
   cd s2j-cozy-brew
   ```

<!-- 
2. Install the dependencies:
 -->

2. 依存関係をインストールします:

   ```zsh
   npm install
   ```

<!-- 
3. Create an Xcode project:
 -->

3. Xcode プロジェクトを生成します:

   ```zsh
   xcodegen generate
   ```

<!-- 
4. Open the project in Xcode:
 -->

4. Xcode でプロジェクトを開きます:

   ```zsh
   open CozyBrew.xcodeproj
   ```

<!-- 
5. Build the project:
 -->

5. プロジェクトをビルドします:

   ```zsh
   swift build
   ```

<!-- 
6. Run the test:
 -->

6. テストを実行します:

   ```zsh
   npm run test:local:macOS
   # or
   swift test
   ```

### Building and Testing

```zsh
swift build
swift test
swift test --enable-code-coverage
```

<!-- 
Daily quality checks (similar to CI's `swift-quality` / `docs-lint`):
 -->

日常の品質チェック (CI の `swift-quality` / `docs-lint` に近い):

```zsh
npm run lint:docs          # README / CHANGELOG / docs (textlint)
npm run lint:swift         # xcodegen → SwiftLint → SwiftFormat → Periphery
npm run version:check      # Are the “package.json” file and the Xcode version/build number synchronized?
npm run build:release      # Build “Release” only in build/DerivedData
npm run install:applications:build   # Copy the Release build to /Applications/CozyBrew.app
```

<!-- 
* **CI**: Run `swift test`, documentation linting, and `lint:swift` / `version:check` using GitHub Actions ([docs/testing_spec.md](docs/testing_spec.md))
* **XCUITest**: `CozyBrewUITests` is for local macOS testing (not integrated into CI)
* Batch script: `npm run test:local:macOS` or `./scripts/test-local_macOS.sh`
 -->

* **CI**: GitHub Actions で `swift test`、ドキュメント lint、`lint:swift` / `version:check` を実行 ([docs/testing_spec.md](docs/testing_spec.md))
* **XCUITest**: `CozyBrewUITests` は macOS ローカル向け (CI 未組込み)
* 一括スクリプト: `npm run test:local:macOS` または `./scripts/test-local_macOS.sh`

### Updating Dependency Modules

<!-- 
The official source for the procedures and release milestones for npm (document lint) and SPM (`s2j-source-list` / `s2j-about-window`) is [docs/dependency_updates.md](docs/dependency_updates.md). For information on signing, Release CodeSign, and `xcodegen`, please refer to the “Signing” section of that document.
 -->

npm (ドキュメント lint) と SPM (`s2j-source-list` / `s2j-about-window`) の手順・リリースマイルストーンは [docs/dependency_updates.md](docs/dependency_updates.md) が正本です。署名、Release CodeSign、`xcodegen` の注意も同ドキュメント§署名を参照してください。

**SPM:**

```zsh
npm run swift:ncu          # pin Check for updates
npm run swift:ncu:update   # Update → install (Package.resolved / Xcode workspace)
npm run swift:install      # resolve + Copy Package.resolved to the workspace
npm run xcode:generate     # Still required even after adding .swift files to Sources/
swift build
```

<!-- 
When you open the `s2j-about-window`, please verify that the `AboutHeaderOptions` / pin in the About section matches the [CHANGELOG](CHANGELOG.md) (current version is v3.0.12 series · `classicHorizontal` / build number / `primaryLink`).
 -->

`s2j-about-window` を上げたときは About の `AboutHeaderOptions` / pin が [CHANGELOG](CHANGELOG.md) とそろっているか確認してください (現行は v3.0.12系・`classicHorizontal` / ビルド番号 / `primaryLink`)。

<!-- 
**npm** (`@s2j/docs-linter`, etc.):
 -->

**npm** (`@s2j/docs-linter` 等):

<!-- 
`ncu` → `ncu -u` → `npm install` (see the documentation above for details).
 -->

`ncu` → `ncu -u` → `npm install` (詳細は上記ドキュメント)。

<!-- 
**Application Version Number**:
 -->

**アプリケーションのバージョン番号**:

<!-- 
The `version` and `buildNumber` in `package.json` are the official values (synced with the version and build numbers displayed in the “About” section). Before distribution, run `npm run version:sync` (or `version:bump-build`). For milestones immediately before tagging, follow the checklist in [dependency_updates.md](docs/dependency_updates.md), such as `npm run release:before-tag-push`.
 -->

`package.json` の `version` / `buildNumber` が正本です (About の版・ビルド表示とも連動)。配布前は `npm run version:sync` (または `version:bump-build`)。タグ直前のマイルストーンは `npm run release:before-tag-push` など [dependency_updates.md](docs/dependency_updates.md) のチェックリストどおりです。

## Contributing

<!-- 
We welcome your contributions. Please follow these steps:
 -->

貢献をお待ちしています。下記の手順に従ってください。

<!-- 
1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/amazing-feature`).
3. Commit your changes (`git commit -m 'Add some amazing feature'`).
4. Push to the feature branch (`git push origin feature/amazing-feature`).
5. Open a Pull Request.
 -->

1. リポジトリをフォークしてください。
2. 機能ブランチを作成してください (`git checkout -b feature/amazing-feature`)。
3. 変更をコミットしてください (`git commit -m 'Add some amazing feature'`)。
4. 機能ブランチにプッシュしてください (`git push origin feature/amazing-feature`)。
5. Pull Request を開いてください。

<!-- 
*For detailed information, please refer to the [docs/SPEC.md](docs/SPEC.md) file.*
 -->

*詳細な情報については、[docs/SPEC.md](docs/SPEC.md) ファイルを参照してください。*

## Contributors & Developers

<!-- 
**"S2J CozyBrew"** is open-source software. The following individuals have contributed to this project:
 -->

**"S2J CozyBrew"** はオープンソース・ソフトウェアです。下記の皆様がこのプロジェクトに貢献しています。

<!-- 
* **Developer**: Koutarou ISHIKAWA
 -->

* **開発者**: Koutarou ISHIKAWA

## Acknowledgments

<!-- 
* Based on [Cakebrew](https://github.com/brunophilipe/Cakebrew) by Bruno Philipe
* Built with SwiftUI and Swift Package Manager
 -->

* Bruno Philipe 制作 [Cakebrew](https://github.com/brunophilipe/Cakebrew) をもとに作成
* SwiftUI および Swift Package Manager で構築
