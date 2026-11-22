# S2J CozyBrew — 実装状況

| 項目 | 内容 |
| --- | --- |
| 最終更新 | 2026-11-22 |
| アプリケーション版 (正本) | `package.json` → **1.0.21** (build **4**) |
| SPM pin | `s2j-source-list` revision `1f7375e` / `main`、`s2j-about-window` revision `290fbff` / `main` |

---

## 概要 `{@status:s-h001}`

本ドキュメントは **現時点の実装スナップショット** を一ヵ所で確認するための索引です。細部の根拠、算出式、Backlog 全文は持ちません。

## 目的 `{@status:s-h002}`

* モジュール別の完了度と、**今フォーカスすべき未了** を短時間で把握する。
* **100% 完了条件チェックリスト** で Must / Should を `[x]` / `[ ]` として追跡する。
* 仕様書・コードを開く前の「どこまでできているか」の入口にする。

## 非目的 `{@status:s-h003}`

* タスク本文、受け入れ条件、brew コマンド契約の定義 (各 spec / `SPEC.md` の役割)。
* 完了した initiative の長期アーカイブ (必要なら `CHANGELOG.md` と Git tag を参照)。

## 正本との関係 `{@status:s-h004}`

| トピック | 正本 |
| --- | --- |
| 完了率の定義・カテゴリー表・品質評価 | [SPEC.md §11](SPEC.md#114-実装完了率) |
| Backlog、ロードマップ | [SPEC.md §12](SPEC.md#12-backlog) |
| プロダクトゴール vs 現行実装 | [overview.md §2.1.1](overview.md#211-現行ビルドでできること--まだのこと) |
| UX の現状と目標 | [ux_flows_spec.md §3](ux_flows_spec.md#30-現行実装-2026-11-15-時点) |
| 版番号・リリース手順 | [dependency_updates.md](dependency_updates.md) |

**運用:** マイルストーン完了や完了率の再計算のたびに本ファイルの **最終更新** と下表を更新し、詳細は [SPEC.md §11](SPEC.md) と同期する。

**完了条件列:** 100% 到達用チェックリスト。`[x]` = 満たし済み、`[ ]` = 未。各§のアンカーが正本。実装％は当該§の `[x]` 数 ÷ 全項目数 ([§ゲート外](#status-gates) を除く)。

## 機能一覧 `{@status:s-features}`

| 機能名 | 実装済み/未実装 | 実装％ | 完了条件 (100%) |
| --- | --- | --- | --- |
| 仕様 (`docs/`) | 確定 | 100 | [§仕様・ドキュメント](#status-spec-docs) (7/7) |
| Swift Package 基盤 (Must) | 実装済み | 100 | [§SPM 基盤](#status-spm-base) (7/7) |
| CozyBrewCore (Must) | 実装済み | 100 | [§Core](#status-core) (5/5) |
| CozyBrewService (Must) | 実装済み | 100 | [§Service](#status-service) (7/7) |
| CozyBrewApp ターゲット (Must) | 実装済み | 100 | [§App ターゲット](#status-app) (6/6) |
| 日常 brew GUI (Must) | 実装済み | 100 | [§brew GUI](#status-brew-gui) (8/8) |
| CozyBrewUIComponents | 実装済み | 100 | [§UI コンポーネント](#status-ui) (9/9) |
| CI ・ローカル品質 | 実装済み | 100 | [§CI・品質](#status-s-status-ci) (9/9) |
| ローカライズ・アクセシビリティ | 実装済み | 100 | [§ローカライズ・アクセシビリティ](#status-l10n-a11y) (4/4) |
| テストエクステンション (UI / 統合) | 実装済み | 100 | [§テスト拡張](#status-quality-ui) (4/4) |
| プロダクトゴール (Should) | 実装済み | 100 | [§プロダクト Should](#status-should-product) (7/7) |

**Must 範囲 (上表の先頭6行):** **100%** — macOS アプリケーションとして Homebrew を GUI で日常操作できる水準。

**全体 (Should ・テストエクステンション等を含む):** チェックリスト **76項目中76項目** = **100%** (下記と [SPEC.md §11.4](SPEC.md) のカテゴリー平均は別集計)。

## 100% 完了条件チェックリスト `{@status:s100}`

[s2j-about-window `docs/status.md`](https://github.com/stein2nd/s2j-about-window/blob/main/docs/status.md) 同型。検証は `npm run test:local:macOS` / GitHub Actions (`swift-test.yml`、`docs-lint.yml`、`swift-quality.yml`) を正本とする。

### 仕様・ドキュメント `{@status:s-status-spec-docs}`

* [x] [specs.md](specs.md) 索引
* [x] [status.md](status.md) 実装状況の入口と本チェックリスト
* [x] 細分化 spec と [SPEC.md](SPEC.md) が現行実装と同期 ([overview §2.1.1](overview.md))
* [x] GitHub Actions `docs-lint.yml` (`npm run lint:docs`)
* [x] 見出しタグと `npm run docs:heading-tags`
* [x] [dependency_updates.md](dependency_updates.md) (npm / SPM、リリース手順)
* [x] [testing_spec.md](testing_spec.md) (テスト層 ・ CI 範囲)

### Swift Package 基盤 (Must) `{@status:s-status-spm-base}`

正本: [architecture.md](architecture.md)、[Package.swift](../Package.swift)

* [x] `Package.swift` — macOS **15.0**、`swift-tools-version` 6.0
* [x] `Package.resolved` と Xcode 側 pin をコミット同期
* [x] `npm run swift:ncu` / `swift:install` ([`scripts/swift-deps.sh`](../scripts/swift-deps.sh))
* [x] `npm run version:sync` / `version:check` / `version:bump-build`
* [x] `npm run lint:swift` (xcodegen → SwiftLint / SwiftFormat / Periphery)
* [x] `project.yml` + `npm run xcode:generate`
* [x] 外部 SPM: `s2j-source-list` / `s2j-about-window` (`main` 追従)

### CozyBrewCore (Must) `{@status:s-status-core}`

正本: [brew_integration_spec.md](brew_integration_spec.md)

* [x] `BrewBinaryLocator` (Apple Silicon / Intel / `which`)
* [x] `BrewProcess` (非対話 env、`--yes`)
* [x] `BrewInstaller` (Homebrew 導入スクリプト補助)
* [x] `BrewResult`
* [x] `BrewBinaryLocatorTests` / `BrewProcessTests`

### CozyBrewService (Must) `{@status:s-status-service}`

正本: [models_spec.md](models_spec.md)、[SPEC.md §11.1.3](SPEC.md)

* [x] `Formula` / `Cask` / `Tap` / 一覧モデル
* [x] `BrewManager` (install / uninstall / upgrade / `update` / `refreshApplicationState` / list / outdated)
* [x] `BrewCaskTerminalFallback` / `BrewCaskTerminalFallbackTests`
* [x] `BrewCache` (TTL)
* [x] Formulae/Casks カタログ API (`BrewCatalog` / `BrewFormulaeAPIClient`)
* [x] `BrewDoctorParser` / Warnings タブ連携
* [x] `brew services` 操作 ([brew_integration_spec.md](brew_integration_spec.md))
* [x] Service ユニットテスト (Models / Cache / Catalog / doctor 等)

### CozyBrewApp ターゲット (Must) `{@status:s-status-app}`

* [x] `BrewNotAvailableView` + opt-in 自動インストール ([ux_flows_spec.md](ux_flows_spec.md) §1)
* [x] About / License / Acknowledgements ([design_spec.md](design_spec.md)、S2J `AboutWindow` + `CozyBrewAboutPresenter`)
* [x] `AppDelegate` / ウィンドウ前面表示
* [x] `AppIcon.appiconset`
* [x] `MARKETING_VERSION` / `buildNumber` → `Info.plist`
* [x] Ack 生成 (`ack:doctor` / `ack:generate`、Release `.app` 前提)

### 日常 brew GUI (Must) `{@status:s-status-brew-gui}`

正本: [ux_flows_spec.md](ux_flows_spec.md)、[overview §2.1.1](overview.md)

* [x] サイドバー6セクション (S2J Source List **フェーズ1**)
* [x] Installed / Outdated / Taps / Formulae / Casks 一覧
* [x] クライアント検索 (一覧フィルター、入力の即時反映)
* [x] 詳細表示、Installed / Outdated 照合 (`brew info` JSON + テキスト補完セクション)
* [x] 詳細表示中は検索バー非表示
* [x] install / uninstall / upgrade (行・詳細)
* [x] Cask Upgrade 失敗時のターミナル委譲 (行下 `PackageUpgradeFailurePanel`)
* [x] ツールバー Refresh (`refreshApplicationState`: `brew update` + Installed / Outdated / **Taps**、ローディング表示)
* [x] `BrewOperationOverlay` (Upgrade blocking)
* [x] Formulae/Casks カタログページ分割
* [x] `brew doctor` Warnings + バッジ

### CozyBrewUIComponents `{@status:s-status-ui}`

* [x] `MainWindowView` (`NavigationSplitView`、カタログ・検索)
* [x] `S2JSourceListAdapter` / `CozyBrewSourceListSidebar`
* [x] `PackageRowView` / `PackageDetailView`
* [x] `BrewAlertView` / `InstallProgressView` (部品)
* [x] `BrewOperationOverlay`
* [x] `PackageUpgradeFailurePanel` / `BrewUpgradeTerminalFallbackView` / `BrewTerminalLauncher`
* [x] **`InstallFlowView` 本番配線** (一覧・詳細の **Install** → 確認シート → 進行/失敗) — [ux_flows_spec §3](ux_flows_spec.md)
* [x] S2J Source List **フェーズ2** (`SourceItem.group`: Installed packages / Catalog)
* [x] **Upgrade All** 確認 UI (Outdated 時ツールバー + `confirmationDialog` → `BrewManager.upgradeAll`)

### CI、ローカル品質 `{@status:s-status-ci}`

* [x] `.github/workflows/swift-test.yml` (`swift test`、release ビルド artifact)
* [x] `.github/workflows/docs-lint.yml`
* [x] `.github/workflows/swift-quality.yml` (`npm run version:check` on Ubuntu、`npm run lint:swift` on macOS)
* [x] `lint-swift`: Homebrew で xcodegen / SwiftLint / SwiftFormat、Periphery **3.8.0** は [GitHub Release](https://github.com/peripheryapp/periphery/releases) + `DYLD_LIBRARY_PATH` (Xcode `libIndexStore.dylib`)。Homebrew formula は upstream アーカイブで deprecated のため CI では使わない
* [x] `npm run test:local` / `test:local:macOS`
* [x] `npm run release:*` マイルストーン ([dependency_updates.md](dependency_updates.md))
* [x] `npm run swift:pin-diff`
* [x] CI で `npm run lint:swift`
* [x] CI で `npm run version:check`

### ローカライズ・アクセシビリティ `{@status:s-status-l10n-a11y}`

正本: [security_spec.md](security_spec.md)、[SPEC.md §11.3.1](SPEC.md)

* [x] `Localizable.strings` (en) — `Sources/CozyBrewUIComponents/Resources/en.lproj/Localizable.strings`
* [x] `Localizable.strings` (ja) — `Sources/CozyBrewUIComponents/Resources/ja.lproj/Localizable.strings`
* [x] 主要 UI のローカライズ適用 (`CozyBrewL10n`、サイドバー/一覧/詳細/Install/Upgrade All/brew 未導入)
* [x] VoiceOver / アクセシビリティ — ツールバー、検索、一覧行、操作ボタン、オーバーレイ、Install フローに `accessibilityLabel` 等

### テストエクステンション (UI / 統合) `{@status:s-status-quality-ui}`

* [x] Core / Service ユニットテスト (現状の主テスト、`BrewInfoTextParserTests` / `BrewTapInfoTests` 含む)
* [x] UI テスト (macOS) — `Tests/CozyBrewUITests/` (起動・ウィンドウスモーク、ローカル `xcodebuild test`)
* [x] brew 連携の統合テスト — `BrewServiceIntegrationTests` + [testing_spec.md](testing_spec.md) で CI 範囲を明文化
* [x] UI スナップショット — `UISnapshotRenderTests` (ビットマップ/レイアウトメトリクス、CI の `swift test`)

### プロダクトゴール (Should) `{@status:s-status-should-product}`

正本: [overview.md §2.1](overview.md) (ゴール列)

* [x] brew 未導入ユーザー向け導入 UX
* [x] 一覧・検索・ログ表示 (操作中)
* [x] GPL 系リソース (LICENSE / ACK) のバンドル表示
* [x] tap / **untap** の GUI 操作 — Taps ツールバー + コンテキストメニュー (`BrewManager.addTap` / `removeTap`)
* [x] インストール **履歴** の保持・表示 — `BrewOperationHistoryStore` + サイドバー **History**
* [x] パッケージ詳細での README (Markdown) 表示 — `brew info` caveats + GitHub README フォールバック。Keg / Options / Analytics / Runtime は `BrewInfoTextParser` 補完
* [x] untap 確認に `brew tap-info --json` 要約 (`BrewTapInfo` / `tapRemovalSummary`)
* [x] Cakebrew 設定移行 — `CakebrewMigration` 検出シート + 履歴取り込み

## ゲート外・任意 `{@status:s-status-gates}`

**100% 分母外** (未完了でも `Must` 100% は維持)。

| # | 内容 | 備考 |
| --- | --- | --- |
| G1 | GitHub Release への `.app` / notarize 自動添付 | 配布方針は未確定 ([dependency_updates.md](dependency_updates.md)) |
| G2 | Mac App Store 提出 | Sandbox 見直しが別途必要 |
| G3 | `brew search --json` を GUI 検索に使用 | 現状はクライアントフィルターで十分 |
| G4 | brew 未導入 UI の DEBUG 強制分岐 | [ux_flows_spec §3.4](ux_flows_spec.md) |
| G5 | `InstallFlowView` 相当の「初期設定」専用シート | 現状は `BrewNotAvailableView` が担う |

**補足:** [§全体スナップショット](#status-s-h005) のカテゴリー平均と本チェックリストの機械集計は別集計 (Should / ゲート外を含む項数目線)。

---

## 全体スナップショット (カテゴリー別) `{@status:s-h005}`

[SPEC.md §11.4](SPEC.md) と同期 (2026-11-22時点)。完了条件の機械集計は [§100% チェックリスト](#status-s100) を参照。

| カテゴリー | 完了率 | ひと言 |
| --- | --- | --- |
| Swift Package 基盤 | 100% | SPM、`lint:swift`、`version:sync` |
| CozyBrewCore | 100% | 検出・プロセス・インストーラ |
| CozyBrewService | 100% | Manager、カタログ、doctor |
| CozyBrewUIComponents | 100% | サイドバー フェーズ2階層、`InstallFlowView`、`Upgrade All` 確認 |
| CozyBrewApp Target | 100% | About、brew 未導入ガイド、App Icon |
| テストコード | 100% | SPM UT + 統合 + UI レンダリング。XCUITest はローカル |
| ローカライズ | 100% | `CozyBrewL10n` + en/ja `Localizable.strings` |
| CI/CD | 100% | `swift-test` + `docs-lint` + `swift-quality` (`version:check` / `lint:swift`、Periphery は Release + IndexStore) |
| Xcode プロジェクト | 100% | XcodeGen、署名用土台 |

**全体 (カテゴリー平均): 100%** ([SPEC.md §11.4](SPEC.md) と同期)

---

## 機能スナップショット `{@status:s-h006}`

| 領域 | 状態 | メモ |
| --- | --- | --- |
| サイドバー (S2J Source List) | ✅ フェーズ2 | `SourceItem.group` (Installed packages / Catalog)。v2.0.14+ 前提 |
| カタログ Formulae/Casks | ✅ | ページ分割・キャッシュ |
| brew 一覧 / 検索 / 詳細 | ✅ | クライアント検索 |
| install / uninstall / upgrade | ✅ | 行・詳細から直実行 |
| `BrewOperationOverlay` | ✅ | Upgrade 中心の blocking UI |
| `InstallFlowView` 統合 | ✅ | 一覧・詳細の Install からシート表示 |
| Upgrade All 確認 UI | ✅ | Outdated ツールバー + 確認ダイアログ |
| brew 未導入 UX | ✅ | `BrewNotAvailableView` |
| tap / untap GUI | ✅ | Add Tap シート + untap 確認 |
| インストール履歴 | ✅ | `Application Support` 永続化 + History タブ |
| 詳細 README | ✅ | caveats / GitHub README |
| Cakebrew 移行 | ✅ | 初回検出シート (オプション) |
| About / License / Acknowledgements | ✅ | S2J About Window v3+ |
| バージョン同期 (`version` / `buildNumber`) | ✅ | `npm run version:sync` |

---

## 進行中の focus (短期) `{@status:s-h007}`

[SPEC.md §12.1](SPEC.md) と同期。優先は上から検討。

| # | initiative | 状態 |
| --- | --- | --- |
| 1 | S2J Source List **フェーズ2** (階層 `SourceItem.group`) | 完了 |
| 2 | **`InstallFlowView` 本番配線** + Upgrade All 確認 | 完了 (Install 経路・一括 Upgrade) |
| 3 | brew 未導入 UI の **手動/ DEBUG 検証** 手順の実装 (§3.4) | 文書のみ → 要 DEBUG 等 |
| 4 | ローカライズ (en / ja) 初期 | 完了 (`CozyBrewL10n`) |
| 5 | CI への `lint:swift` / `version:check` 組込み | 完了 (`swift-quality.yml`) |

---

## 直近までに完了したもの (参考) `{@status:s-h008}`

詳細は [CHANGELOG.md](../CHANGELOG.md) / [SPEC.md §11.1](SPEC.md) を参照。

* **v1.0.12** — S2J Source List サイドバー統合、版同期スクリプト、SPM pin 更新
* About / License / Acknowledgements (バンドル連携)
* Formulae/Casks カタログ API、`brew doctor` Warnings タブ
* `package.json` 正本の Version / Build 同期 (`release:*` マイルストーン)
* GitHub Actions: Swift テスト、docs lint、`swift-quality` (`version:check` / `lint:swift`)
* **v1.0.13– v1.0.14** — Cask ターミナル委譲・行下失敗パネル、ツールバー `refreshApplicationState`、SPM pin 更新
* **v1.0.15– v1.0.17** — `swift-quality.yml` 本番運用、CI 上の Periphery 導入 (Release `3.8.0` + IndexStore、`brew install periphery` は非推奨注釈・`libIndexStore` 問題のため不採用)
* **v1.0.19– v1.0.20** — プロダクト Should、L10n、テストエクステンション、CI untap ダイアログ修正

---

## 関連リンク `{@status:s-h009}`

* [specs.md](specs.md) — 仕様書一覧
* [dependency_updates.md](dependency_updates.md) — 依存更新・リリースチェックリスト