# S2J CozyBrew — プロジェクト概要

## 1. プロジェクト概要 `{@overview:s1}`

* **名称:** S2J CozyBrew
* **Swift Package 名:** s2j-cozy-brew
* **元リポジトリ:** [Cakebrew](https://github.com/brunophilipe/Cakebrew)
* **目的:** AppKit ベースの「Cakebrew」を SwiftUI / Swift を用いて再実装します。
  * コアロジックや再利用可能な部品は Swift Package 化します (s2j-cozy-brew 等)。
  * アプリケーション本体は Xcode App Target (CozyBrew.app) で管理します。
* **対応 OS:** macOS v15.0以上
* 設計方針の核:
  * **再利用性 (Package) と実行可能アプリケーション (App Target) の分離** です。
  * UI 再利用部品や Brew 操作ロジックは Swift Package として設計・テスト可能にし、アプリケーション固有のバンドル資産、Info.plist、署名等は App Target に置きます。

S2J CozyBrew (Swift Package 名: `s2j-cozy-brew`) は、AppKit で実装された既存の **Cakebrew** を、**SwiftUI / Swift** ベースに再実装してモダナイズすることを目的とします。
ユーザー層は「ターミナル操作に慣れていない一般ユーザー (for the rest of us)」を想定し、Homebrew (以下 brew) をローカルで安全かつ分かりやすく操作できる GUI アプリケーションを提供します。

---

## 2. 要件ゴール `{@overview:s2}`

### 2.1. 機能要件 (プロダクトゴール) `{@overview:s2-1}`

* Homebrew (brew) と安全に連携する SwiftUI macOS アプリケーションを提供します。
* Brew の未導入ユーザーに向けた導入 UX、パッケージ一覧・操作、再利用可能な Swift Package 化を目指します。
* サイドバーは [S2J Source List](https://github.com/stein2nd/s2j-source-list)、About は [S2J About Window](https://github.com/stein2nd/s2j-about-window) を採用します。

詳細な UX は [ux_flows_spec.md](ux_flows_spec.md)、実装状況は [SPEC.md](SPEC.md) §11を参照してください。

### 2.1.1. 現行ビルドでできること / まだのこと `{@overview:s2-1-1}`

| 領域 | プロダクトゴール | 現行実装 (2026-11-22時点、未タグ分含む) |
| --- | --- | --- |
| brew 一覧・検索・詳細 | list / info 相当の GUI | ✅ 一覧・クライアント検索。詳細は `brew info` JSON + テキスト補完 (Keg / Options / Analytics / Runtime)。詳細中は検索バー非表示 |
| install / uninstall / upgrade | GUI から安全に操作 | ✅ 行・詳細から実行。Cask の `sudo`/TTY 失敗時は行下 `PackageUpgradeFailurePanel` |
| `brew update` / doctor | 更新・警告表示 | ✅ ツールバー Refresh (`brew update` + Installed / Outdated / **Taps** 再取得)、Warnings タブ。Cask はターミナル委譲後も Refresh で Outdated 反映 |
| brew 未導入時の導入 | ガイド + opt-in 自動インストール | ✅ `BrewNotAvailableView` (`ContentView` 分岐) |
| 確認付き Install フロー | `InstallFlowView` による統一 UI | ✅ 一覧・詳細の Install |
| tap / untap の操作 | GUI から tap 管理 | ✅ Add Tap + untap 確認 (`brew tap-info` 要約付き) |
| インストール履歴 | 履歴・ログの保持表示 | ✅ 操作履歴 + サイドバー History |
| パッケージ README | Markdown 表示 | ✅ caveats + GitHub README |
| Cakebrew からの移行 | 設定・履歴のオプション取り込み | ✅ 検出シート |
| Upgrade All | 一括アップグレード + 確認 | ✅ Outdated ツールバー + 確認ダイアログ |
| サイドバー S2J | Source List 統合 | ✅ フェーズ2 (`SourceItem.group` 階層) |
| About / License | GPL 系のオフライン表示 | ✅ S2J `AboutWindow` (`CozyBrewAboutPresenter`)。License / Acknowledgements はバンドル |
| ローカライズ en/ja | 初期二言語 | ✅ `CozyBrewL10n` + `Localizable.strings` (主要 UI。メニュー等は一部英語) |
| テスト (エクステンション) | UT / 統合 / UI | ✅ `swift test` + [testing_spec.md](testing_spec.md)。XCUITest はローカル |

### 2.2. 非機能要件 `{@overview:s2-2}`

* brew の内部実装を再作成しません (CLI をラップします)。
* brew が管理するパッケージの完全な CI 自動テストは本プロジェクトの範囲外です (実環境でのインストールはユーザー端末で行います)。
  * Swift Package (`s2j-cozy-brew`) として管理し、SwiftPM でビルド可能とします。
  * UI は SwiftUI (macOS v15.0以上を前提)。
  * セキュリティ: brew 実行は、サンドボックス外のプロセス・コールを行うため、権限/経路の取り扱いを厳密にします。
  * ローカライズ対応 (英語・日本語を初期対応とします)。
  * アクセシビリティ (VoiceOver 等) への対応を実装します。
  * CI: GitHub Actions で macOS ビルド・ユニットテスト、Docs Linter、`swift-quality` (版同期と `lint:swift`) を実行します (Node.js v24対応 Action)。

---

## 3. 準拠仕様 `{@overview:s3}`

### 3.1. 技術スタック `{@overview:s3-1}`

* [COMMON_SPEC.md](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md) に準拠します。

### 3.2. 開発ルール `{@overview:s3-2}`

* [COMMON_SPEC.md](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md) に準拠します。

### 3.3. 国際化・ローカライズ `{@overview:s3-3}`

* [COMMON_SPEC.md](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md) に準拠します。

### 3.4. コーディング規約 `{@overview:s3-4}`

* [COMMON_SPEC.md](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md) に準拠します。

### 3.5. デザイン規約 `{@overview:s3-5}`

* [COMMON_SPEC.md](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md) に準拠します。

### 3.6. テスト方針 `{@overview:s3-6}`

* [COMMON_SPEC.md](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md) に準拠します。
