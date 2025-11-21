# S2J CozyBrew

[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-3.0.en.html)                         
[![Swift](https://img.shields.io/badge/Swift-5.9-blue?logo=Swift&logoColor=white)](https://www.swift.org)                                                       

## Description

<!-- 
S2J CozyBrew is a modern, SwiftUI-based macOS application for managing Homebrew packages. This application has been ported from the popular [Cakebrew](https://github.com/brunophilipe/Cakebrew) project by Bruno Philipe, bringing its functionality to the SwiftUI ecosystem. It provides a user-friendly GUI for managing Homebrew packages without requiring terminal knowledge, making it accessible to users who prefer graphical interfaces.                          

The application offers a comprehensive set of features for managing Homebrew packages, including package listing, search, installation, uninstallation, updates, and more. It also includes a guided installation flow for users who don't have Homebrew installed yet.                    
 -->

S2J CozyBrew は、Homebrew パッケージを管理するためのモダンな SwiftUI ベースの macOS アプリケーションです。本アプリケーションは、Bruno Philipe 制作の人気プロジェクト [Cakebrew](https://github.com/brunophilipe/Cakebrew) から移植され、その機能を SwiftUI エコシステムにもたらしています。ターミナルの知識を必要とせず、Homebrew パッケージを管理できるユーザーフレンドリーな GUI を提供し、グラフィカルインターフェースを好むユーザーにもアクセス可能にしています。     

本アプリケーションは、パッケージ一覧、検索、インストール、アンインストール、アップデートなど、Homebrew パッケージを管理するための包括的な機能セットを提供します。また、Homebrew がまだインストールされていないユーザー向けのガイド付きインストールフローも含まれています。         

## Features

<!-- 
* **User-Friendly GUI**: Manage Homebrew packages without terminal knowledge
* **Package Management**: List, search, install, uninstall, and update packages
* **Homebrew Installation Guide**: Guided installation flow for users without Homebrew
* **Real-time Progress**: View installation and update progress with real-time logs
* **Package Details**: View detailed information about packages including dependencies
* **Dark Mode**: Full dark mode support
* **Localization**: Built-in support for multiple languages (English, Japanese)
* **SwiftUI Native**: Built entirely with SwiftUI for modern UI
* **Swift Package**: Core logic available as reusable Swift Package
 -->

* **ユーザーフレンドリーな GUI**: ターミナルの知識なしで Homebrew パッケージを管理
* **パッケージ管理**: パッケージの一覧表示、検索、インストール、アンインストール、アップデート
* **Homebrew インストールガイド**: Homebrew が未導入のユーザー向けのガイド付きインストールフロー
* **リアルタイム進捗**: リアルタイムログでインストールとアップデートの進捗を表示
* **パッケージ詳細**: 依存関係を含むパッケージの詳細情報を表示
* **ダークモード**: 完全なダークモード対応
* **ローカライズ**: 複数言語 (英語、日本語) の組込みサポート
* **SwiftUI ネイティブ**: モダン UI を実現する SwiftUI 完全構築
* **Swift Package**: 再利用可能な Swift Package としてコアロジックを提供

## License

<!-- 
This project is licensed under the GPL 3.0+ License. See the [LICENSE](LICENSE) file for details.                                                               
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

* macOS v12.0+
* Xcode v14.0+
* Swift v5.9+

### Building from Source

<!-- 
To build the application from source:
 -->

ソースからアプリケーションをビルドするには:

<!-- 
1. Clone the repository:

   ```bash
   git clone https://github.com/stein2nd/s2j-cozy-brew.git
   cd s2j-cozy-brew
   ```

2. Generate the Xcode project (if needed):

   ```bash
   xcodegen generate
   ```

3. Open the project in Xcode:

   ```bash
   open CozyBrew.xcodeproj
   ```

4. Build and run the application in Xcode
 -->

1. リポジトリをクローンします:

   ```bash
   git clone https://github.com/stein2nd/s2j-cozy-brew.git
   cd s2j-cozy-brew
   ```

2. Xcode プロジェクトを生成します (必要な場合):

   ```bash
   xcodegen generate
   ```

3. Xcode でプロジェクトを開きます:

   ```bash
   open CozyBrew.xcodeproj
   ```

4. Xcode でアプリケーションをビルドして実行します

### Using as a Swift Package

<!-- 
The core logic is available as a Swift Package. Add the following to your `Package.swift` file:
 -->

コアロジックは Swift Package として利用可能です。`Package.swift` ファイルに以下を追加します:

```swift
dependencies: [
    .package(url: "https://github.com/stein2nd/s2j-cozy-brew.git", branch: "main")
]
```

<!-- 
The package provides the following products:
 -->

パッケージは以下の製品を提供します:

* `CozyBrewCore` - Core functionality for Homebrew operations
* `CozyBrewService` - Service layer with models and ViewModels
* `CozyBrewUIComponents` - Reusable SwiftUI components

## Usage

<!-- 
### First Launch
 -->

### 初回起動

<!-- 
When you first launch S2J CozyBrew, the application will check if Homebrew is installed on your system. If Homebrew is not found, you'll be presented with a guided installation flow that helps you install Homebrew safely.
 -->

S2J CozyBrew を初めて起動すると、アプリケーションはシステムに Homebrew がインストールされているか確認します。Homebrew が見つからない場合、Homebrew を安全にインストールするためのガイド付きインストールフローが表示されます。

<!-- 
### Managing Packages
 -->

### パッケージの管理

<!-- 
Once Homebrew is installed and detected:
 -->

Homebrew がインストールされ、検出されると:

<!-- 
* **Browse Packages**: View installed packages, available packages, and outdated packages
* **Search**: Search for packages by name
* **Install**: Install packages with a single click
* **Uninstall**: Remove packages you no longer need
* **Update**: Update individual packages or all packages at once
* **View Details**: See detailed information about packages including dependencies and descriptions
 -->

* **パッケージの閲覧**: インストール済みパッケージ、利用可能なパッケージ、アップデート可能なパッケージを表示
* **検索**: 名前でパッケージを検索
* **インストール**: ワンクリックでパッケージをインストール
* **アンインストール**: 不要になったパッケージを削除
* **アップデート**: 個別のパッケージまたはすべてのパッケージを一度にアップデート
* **詳細表示**: 依存関係や説明を含むパッケージの詳細情報を表示

## Development

<!-- 
### Project Structure
 -->

### プロジェクト構造

<!-- 
The project follows a hybrid structure with both Swift Package and Xcode App Target:
 -->

このプロジェクトは、Swift Package と Xcode App Target の両方を持つハイブリッド構造に従っています:

<!-- 
* `Sources/` - Swift Package source code
  * `CozyBrewCore/` - Core functionality (binary detection, process execution, installer)
  * `CozyBrewService/` - Service layer (models, ViewModels, cache)
  * `CozyBrewUIComponents/` - Reusable SwiftUI components
* `CozyBrewApp/` - Application target (App resources, Info.plist, Assets)
* `Tests/` - Test files
* `Package.swift` - Package configuration
* `project.yml` - XcodeGen configuration
 -->

* `Sources/` - Swift Package ソースコード
  * `CozyBrewCore/` - コア機能 (バイナリ検出、プロセス実行、インストーラー)
  * `CozyBrewService/` - サービス層 (モデル、ViewModel、キャッシュ)
  * `CozyBrewUIComponents/` - 再利用可能な SwiftUI コンポーネント
* `CozyBrewApp/` - アプリケーションターゲット (アプリリソース、Info.plist、Assets)
* `Tests/` - テストファイル
* `Package.swift` - パッケージ設定
* `project.yml` - XcodeGen 設定

<!-- 
### Setting Up Development Environment
 -->

### 開発環境のセットアップ

<!-- 
To set up the development environment for this project:
 -->

このプロジェクトの開発環境をセットアップするには:

<!-- 
1. Clone the repository:

   ```bash
   git clone https://github.com/stein2nd/s2j-cozy-brew.git
   cd s2j-cozy-brew
   ```

2. Install dependencies:

   ```bash
   npm install
   ```

3. Generate the Xcode project:

   ```bash
   xcodegen generate
   ```

4. Open the project in Xcode:

   ```bash
   open CozyBrew.xcodeproj
   ```

5. Build the project:

   ```bash
   swift build
   ```

6. Run tests:

   ```bash
   swift test
   ```
 -->

1. リポジトリをクローンします:

   ```bash
   git clone https://github.com/stein2nd/s2j-cozy-brew.git
   cd s2j-cozy-brew
   ```

2. 依存関係をインストールします:

   ```bash
   npm install
   ```

3. Xcode プロジェクトを生成します:

   ```bash
   xcodegen generate
   ```

4. Xcode でプロジェクトを開きます:

   ```bash
   open CozyBrew.xcodeproj
   ```

5. プロジェクトをビルドします:

   ```bash
   swift build
   ```

6. テストを実行します:

   ```bash
   swift test
   ```

<!-- 
### Building and Testing
 -->

### ビルドとテスト

<!-- 
To build the project, use:
 -->

プロジェクトをビルドするには:

```bash
swift build
```

<!-- 
To run tests with code coverage:
 -->

コードカバレッジ付きでテストを実行するには:

```bash
swift test --enable-code-coverage
```

<!-- 
To update Swift Package dependencies:
 -->

Swift Package の依存関係を更新するには:

```bash
npm run swift:update
```

## Contributing

<!-- 
We welcome your contributions. Please follow these steps:
 -->

貢献をお待ちしています。以下の手順に従ってください。

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

**"S2J CozyBrew"** はオープンソース・ソフトウェアです。以下の皆様がこのプロジェクトに貢献しています。                                                        

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
