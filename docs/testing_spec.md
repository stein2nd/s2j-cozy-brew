# S2J CozyBrew — テスト戦略と CI 範囲

正本: [status.md §テスト拡張](status.md#テストエクステンション-ui--統合-status-s-status-quality-ui)、[overview.md §2](overview.md) (brew 完全自動テストは範囲外)

---

## 1. テストの層 `{@testing_spec:s1}`

| 層 | 実行コマンド | CI (GitHub Actions) | 実 brew 必須 |
| --- | --- | --- | --- |
| **SPM ユニット** | `swift test` | ✅ `swift-test.yml` | 一部のみ (`BrewProcessTests.testBrewCommandRun` は brew 未導入時スキップ相当) |
| **サービス統合** | `swift test` (`BrewServiceIntegrationTests`) | ✅ 同上 (モック・フィクスチャのみ) | ❌ |
| **UI コンポーネント** | `swift test` (`CozyBrewUIComponentsTests`) | ✅ 同上 (レンダリング・メトリクス) | ❌ |
| **XCUITest (macOS)** | `xcodebuild test -scheme CozyBrewApp` | ❌ (未組込み・ローカル / 手動) | 起動のみ (brew なくても可) |
| **実 brew E2E** | 開発者 Mac で手動スモーク | ❌ | ✅ |

**原則:** CI では **決定的** な `swift test` のみをゲートとする。実機の `brew install` 等は本リポジトリの CI 範囲外 ([overview.md](overview.md))。

**ビルド注意:** `CozyBrewUIComponents` は SPM ターゲットとしても `swift test` / Periphery がコンパイルする。macOS 向け SwiftUI の一部 API (例: `confirmationDialog(item:)`) は Xcode アプリケーション・ターゲットと可用性が異なる場合があるため、ライブラリ側は `isPresented` 等の互換パターンを優先する。

---

## 2. ターゲット一覧 `{@testing_spec:s2}`

| テストターゲット | パス | 内容 |
| --- | --- | --- |
| `CozyBrewCoreTests` | `Tests/CozyBrewCoreTests/` | バイナリ検出、プロセス env |
| `CozyBrewServiceTests` | `Tests/CozyBrewServiceTests/` | モデル、キャッシュ、カタログ API、doctor、**統合**、操作履歴 (`BrewOperationHistoryTests`)、GitHub README URL パース、`brew info` テキスト (`BrewInfoTextParserTests`)、`brew tap-info` 要約 (`BrewTapInfoTests`)、環境スナップショット (`BrewEnvironmentFetcherTests`)、CozyBrew 設定 (`CozyBrewAppSettingsTests`) |
| `CozyBrewUIComponentsTests` | `Tests/CozyBrewUIComponentsTests/` | SwiftUI レンダリング・**UI スナップショット風**メトリクス |
| `CozyBrewUITests` | `Tests/CozyBrewUITests/` | アプリケーション起動・ウィンドウ表示 (XCUITest) |

ローカル一括: `npm run test:local:macOS` → `scripts/test-local.sh`(`swift test` + 任意で Xcode テスト)。

---

## 3. brew 連携の「統合テスト」の意味 `{@testing_spec:s3}`

本プロジェクトでの **brew 連携統合** は、CLI を実際にたたかず次を結びます。

* カタログ JSON / doctor 出力などの **フィクスチャ**
* `BrewCatalog` / `BrewDoctorParser` / `BrewCaskTerminalFallback` / `BrewUserMessage` の連鎖

実 `brew` を使う検証は **ローカル手動** (Upgrade、Cask ターミナル委譲等) と [ux_flows_spec.md §3.4](ux_flows_spec.md) を参照。

---

## 4. UI スナップショット `{@testing_spec:s4}`

* **CI:** `CozyBrewUIComponentsTests` で `NSHostingView` に載せ、ビットマップ生成とサイズを検証 (ピクセル一致のゴールデンファイルは未採用)。
* **将来:** `swift-snapshot-testing` 等への移行は Backlog。

---

## 5. UI テスト (XCUITest) `{@testing_spec:s5}`

* `CozyBrewUITests` は **アプリケーション起動とメインウィンドウの存在** を確認するスモーク (`@MainActor`、Swift6コンカレンシー)。
* GitHub Actions には未組込み (macOS ランナーでの署名、GUI 安定性のため)。リリース前のローカル `xcodebuild test` を推奨。