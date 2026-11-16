# S2J CozyBrew — 実装状況

| 項目 | 内容 |
| --- | --- |
| 最終更新 | 2026-11-16 |
| アプリ版 (正本) | `package.json` → **1.0.12** (build **4**) |
| SPM pin | `s2j-source-list` @ **2.0.14** (revision)、`s2j-about-window` @ `main` |

---

## 概要 `{@status:s-h001}`

本ドキュメントは **現時点の実装スナップショット** を一ヵ所で確認するための索引です。細部の根拠、算出式、Backlog 全文は持ちません。

## 目的 `{@status:s-h002}`

* モジュール別の完了度と、**今フォーカスすべき未了** を短時間で把握する。
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

**運用:** マイルストーン完了・完了率の再計算のたびに本ファイルの **最終更新** と下表を更新し、詳細は `SPEC.md` §11を同期する。

---

## 全体 `{@status:s-h005}`

**実装完了率 (算術平均): 約85%** (端数 **84.7%**、9カテゴリー、`SPEC.md` §11.4と同じ)

| カテゴリー | 完了率 | ひと言 |
| --- | --- | --- |
| Swift Package 基盤 | 100% | SPM、`lint:swift`、`version:sync` |
| CozyBrewCore | 100% | 検出・プロセス・インストーラ |
| CozyBrewService | 100% | Manager、カタログ、doctor |
| CozyBrewUIComponents | 92% | S2J サイドバー フェーズ1、オーバーレイ。InstallFlow **未配線** |
| CozyBrewApp Target | 100% | About、brew 未導入ガイド、App Icon |
| テストコード | 75% | Core/Service UT。UI、統合なし |
| ローカライズ | 0% | 未着手 |
| CI/CD | 95% | `swift test` + docs lint。`lint:swift` はローカルのみ |
| Xcode プロジェクト | 100% | XcodeGen、署名用土台 |

**主な引き下げ要因:** ローカライズ (0%)、テストの深さ (75%)、UI の InstallFlow 未統合。

---

## 機能スナップショット `{@status:s-h006}`

| 領域 | 状態 | メモ |
| --- | --- | --- |
| サイドバー (S2J Source List) | ✅ フェーズ1 | v2.0.14前提。フェーズ2階層は未了 |
| カタログ Formulae/Casks | ✅ | ページ分割・キャッシュ |
| brew 一覧 / 検索 / 詳細 | ✅ | クライアント検索 |
| install / uninstall / upgrade | ✅ | 行・詳細から直実行 |
| `BrewOperationOverlay` | ✅ | Upgrade 中心の blocking UI |
| `InstallFlowView` 統合 | ⚠️ | 部品のみ・未配線 |
| Upgrade All 確認 UI | ❌ | API のみ |
| brew 未導入 UX | ✅ | `BrewNotAvailableView` |
| tap / untap GUI | ⚠️ | Tap 一覧のみ |
| インストール履歴 | ❌ | — |
| About / License / Acknowledgements | ✅ | S2J About Window v3+ |
| バージョン同期 (`version` / `buildNumber`) | ✅ | `npm run version:sync` |

---

## 進行中の focus (短期) `{@status:s-h007}`

`SPEC.md` §12.1と同期。優先は上から検討。

| # | initiative | 状態 |
| --- | --- | --- |
| 1 | S2J Source List **フェーズ2** (階層 `SourceItem.group`) | 未着手 |
| 2 | **`InstallFlowView` 本番配線** + Upgrade All 確認 | 未着手 |
| 3 | brew 未導入 UI の **手動/ DEBUG 検証** 手順の実装 (§3.4) | 文書のみ → 要 DEBUG 等 |
| 4 | ローカライズ (en / ja) 初期 | 未着手 |
| 5 | CI への `lint:swift` / `version:check` 組込み | 未着手 |

---

## 直近までに完了したもの (参考) `{@status:s-h008}`

詳細は `CHANGELOG.md` / `SPEC.md` §11.1を参照。

* S2J Source List サイドバー統合 (フェーズ1)、`s2j-source-list` v2.0.14
* About / License / Acknowledgements (バンドル連携)
* Formulae/Casks カタログ API、`brew doctor` Warnings タブ
* `package.json` 正本の Version / Build 同期 (`version:sync`、`release:*` マイルストーン)
* GitHub Actions: Swift テスト、docs lint

---

## 関連リンク `{@status:s-h009}`

* [specs.md](specs.md) — 仕様書一覧
* [dependency_updates.md](dependency_updates.md) — 依存更新・リリースチェックリスト
