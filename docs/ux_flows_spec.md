# S2J CozyBrew — UX フロー仕様

本ドキュメントでは、アプリケーションの主要なユーザーフローを定義します。初回起動からパッケージ操作までの流れを明文化します。

---

## 1. 初回起動フロー `{@ux_flows_spec:s1}`

### 1.1. 起動時の検出 `{@ux_flows_spec:s1-1}`

1. アプリケーション起動
2. `BrewBinaryLocator` で brew を検出
3. 未導入 / 導入済みで分岐

### 1.2. brew 未導入時 `{@ux_flows_spec:s1-2}`

1. ユーザーに「Homebrew が見つかりません」と表示
2. 導入手順を説明:
   * なぜ必要か
   * ダウンロード元
   * 必要な権限 (パスワード入力等)
3. "Install Homebrew" ボタンで公式インストール・スクリプトの実行オプションを提示
4. セキュリティ注意喚起と必要な権限を明記
5. ユーザー選択で公式スクリプトを実行 (実行中はログをリアルタイム表示)
6. インストール成功後、環境を再検出し `BrewManager` を初期化
7. brew パスを検出しサービスを起動

### 1.3. brew 導入済み時 `{@ux_flows_spec:s1-3}`

1. バージョン取得
2. Apple Silicon / Intel に応じた PATH 設定を検証
3. `brew update` の実行案内 (自動 or 手動選択)
4. 「初心者向けの説明 (何が起きるか)」を表示

### 1.4. 設計上の注意 `{@ux_flows_spec:s1-4}`

* 自動導入は **opt-in** (ユーザー承諾必須)。強制的な sudo は避けます。
* スクリプトの実行は標準出力で行い、エラーをリアルタイム表示します。
* 失敗時のログ保存を行います。
* インストール中は明確な進捗とロールバック手順を表示します。

---

## 2. 一般的フロー (パッケージ操作) `{@ux_flows_spec:s2}`

### 2.1. 基本フロー `{@ux_flows_spec:s2-1}`

```
検索 → 一覧 → 詳細 → Install / Uninstall / Upgrade
```

### 2.1.1. 一覧内検索 (フィルター) `{@ux_flows_spec:s2-1-1}`

* 検索バーは **現在のサイドバー一覧をクライアント側で絞り込み** ます (名前、full_name、説明の部分一致、大文字と小文字の無視)。
* Enter や `brew search` は呼びません。0件の場合は **No matching packages** と表示し、別処理 (Tap 取得失敗等) のエラーは混ぜません。

### 2.2. 操作の共通仕様 `{@ux_flows_spec:s2-2}`

* インストール・アンインストール・アップグレードは、非同期でプログレス表示
* **Upgrade** (一覧・詳細とも) は最前面のモーダル風オーバーレイ (`Upgrading…`) で他操作をブロックする
* **Cask の Upgrade** では macOS の管理者認証が入ることがあり、**暗幕付き全画面オーバーレイは使わない** (`passwordFriendly`: 右上の進行カードのみ・背面ヒット透過)。システムのパスワードダイアログが前面に出やすいようにする。一覧・詳細は `disabled` で誤操作を防ぐ。
* 完了 / 失敗通知を UI に反映
* キャンセル可能とする

### 2.3. Upgrade All `{@ux_flows_spec:s2-3}`

* 明確な確認プロンプトを表示
* 依存関係の大きな変更に対する注意喚起

### 2.4. 失敗時 `{@ux_flows_spec:s2-4}`

* CLI のエラーメッセージをフレンドリーな文に意訳して提示 (`BrewUserMessage`)
* Cask Upgrade で `sudo` / TTY 不足等に該当する場合、**失敗した行の直下**に `PackageUpgradeFailurePanel` (Continue in Terminal / Copy / Run in Terminal / App Management)。長文は DisclosureGroup「Show details」
* "Show raw log" で生ログも表示可能 (`BrewAlertView` 等・詳細画面は意訳テキストにログ末尾を含む場合あり)

---

## 3. パッケージ操作フロー `{@ux_flows_spec:s3}`

### 3.0. 現行実装 (2026-11-22時点) `{@ux_flows_spec:s3-0}`

| 操作 | 実装 |
| --- | --- |
| brew 未導入 | `ContentView` → `BrewNotAvailableView` (§1)。**専用「初期設定」シートはなし** (全画面ガイド) |
| install | 一覧・詳細から **`InstallFlowView` シート** (確認 → 進行/失敗)。成功後は一覧を更新 |
| uninstall | `PackageRowView` / `PackageDetailView` から `BrewManager` を **直実行** (事前確認なし) |
| upgrade (単体) | 同上。一覧では `BrewOperationOverlay` (Cask は `passwordFriendly`)。失敗時は対象行下 `PackageUpgradeFailurePanel` |
| ターミナルで Cask を上げた後 | ツールバー **Refresh** → `refreshApplicationState()` で Outdated 再同期 |
| upgrade (一括) | **Outdated** 選択時ツールバー **Upgrade All** → `confirmationDialog` → `BrewManager.upgradeAll` + blocking オーバーレイ |
| tap / untap | **Taps** セクション: ツールバー **Add Tap** シート → `brew tap`、行コンテキストメニュー → `confirmationDialog(isPresented:)` で untap 確認 (`brew tap-info` 要約付き) → `brew untap`。ツールバー **Refresh** で Tap 一覧も再取得 |
| 操作履歴 | サイドバー **History** (`BrewOperationHistoryStore`、install/upgrade/tap 等を記録) |
| パッケージ詳細 README | `brew info` caveats + GitHub README フォールバック (`PackageDetailView`) |
| Cakebrew 移行 | 起動時 `com.brunophilipe.Cakebrew.plist` 検出時オプションシート (`CakebrewMigration`) |

Uninstall / 単体 Upgrade は従来どおり直実行 (オーバーレイは Upgrade 時)。Install のみ `InstallFlowView` に統合済み。

### 3.1. 目標 UX (`InstallFlowView` 統合後) `{@ux_flows_spec:s3-1}`

#### 3.1.1. 確認ダイアログ `{@ux_flows_spec:s3-1-1}`

* 操作内容 (インストール / アンインストール / アップグレード) を明示
* 対象パッケージ名を表示
* ユーザー承認後に実行

#### 3.1.2. 進行状況 `{@ux_flows_spec:s3-1-2}`

* ログストリームをリアルタイム表示
* キャンセルボタンを表示

#### 3.1.3. 失敗時 `{@ux_flows_spec:s3-1-3}`

* ロールバック案内を表示
* 詳細ログへの導線を提供

### 3.4. brew 未導入環境の手動検証 (開発マシンに brew がある場合) `{@ux_flows_spec:s3-4}`

日々の開発環境には brew が入っているため、§1.2の UI は **意図的に再現しないと試せません**。CI の `swift test` も brew 前提の統合テストは行いません (overview の非機能要件どおり)。

| 方法 | 概要 | 向き |
| --- | --- | --- |
| **A. 別 macOS ユーザー** | システム設定で標準ユーザーを追加し、そのユーザーの **未使用ホーム** で Run (brew 未インストールに近い) | 本番に近い手動スモーク |
| **B. ゲスト / クリーン VM** | macOS 仮想環境 (UTM / Parallels 等) で新規インストール後、Xcode で Run | 繰り返し可能だが重い |
| **C. 起動時の検出の上書き (将来)** | 例: `-COZYBREW_FORCE_BREW_UNAVAILABLE=1` や DEBUG 専用メニューで `BrewManager.isBrewAvailable = false` | 日常開発向け (要実装) |
| **D. ユニットテスト** | `BrewBinaryLocator.locate()` をモック注入できるようにする (現状は固定ファイル/which) | 自動化の種 (要リファクタ) |

**おすすめの段階:** 機能を足す前に **C または D のどちらか一方** を Backlog で決める → 本番同等の確認は **A または B をリリース前に1回**。

`~/.zshrc` がほぼない状態は **A/B の新規ユーザー** で自然に近付きます。brew インストールスクリプト側がシェル設定を書き換えるため、**導入後** の検証は通常の開発ユーザーに戻って行います。

---

## 4. サイドバー・ナビゲーション `{@ux_flows_spec:s4}`

* サイドバー: **Warnings** (トップレベル)、**Installed packages** グループ (Installed / Outdated)、**Taps**、**Catalog** グループ (Formulae / Casks)。`SourceItem.group` 階層 (`S2JSourceListAdapter`)
* **Outdated** 選択時: ツールバー **Upgrade All** (確認ダイアログ → `brew upgrade --yes`)
* **Warnings**: `brew doctor` の出力をパースして表示。起動時とタブ選択時に `refreshDoctorWarnings()`。Warning ブロック数をオレンジのバッジで表示。検索バーは非表示。ツールバー Refresh で再実行。
* **それ以外のセクション**: ツールバー Refresh は `BrewManager.refreshApplicationState()` (`brew update` → インストール済み、Outdated 再取得、`isLoading` で一覧にスピナー)。ターミナルで行った Cask Upgrade 後の Outdated 反映に使う。
* S2J Source List を用いた分類表示
* 選択に応じてコンテンツエリアを切り替え
* **Formulae / Casks**: `formulae.brew.sh` の JSON API から全件を取得 (キャッシュあり)。一覧は **先頭文字のページ** (`A–E` / `F–J` / … / `1–5` / `6–0`) で分割表示し、常に1ページ分だけ `List` に載せる。検索入力時は全ページ横断でフィルター。

### 4.1. 一覧 → 詳細 → 戻る `{@ux_flows_spec:s4-1}`

* 行タップで詳細を表示しても、**サイドバーで選んでいるセクション** (Installed / Outdated 等) は維持します。
* 詳細表示中は **検索バーを非表示** にします (一覧でのフィルターは入力を即時反映。詳細で Enter を押しても何も起きない混乱を避ける)。
* **[戻る]** では同一セクションの一覧に戻ります (別タブには自動遷移しません)。
* 詳細のナビゲーションタイトルは **パッケージ名** のみです。直前が Outdated 由来か Installed 由来かは、サイドバーのハイライトで判別します。
* 詳細の Upgrade / Status は `brew outdated` 一覧と照合した結果を優先し、操作後の再読み込みで更新します。

### 4.2. Installed 一覧での Upgrade `{@ux_flows_spec:s4-2}`

* `brew list` 単体では `isOutdated` が付かないため、表示時に **`brew outdated` と名前・種別 (Formula/Cask) を照合** し、一致する行に Update Available バッジと [Upgrade] を出します。

---

## 5. エラー表示 (BrewAlertView) `{@ux_flows_spec:s5}`

* friendly メッセージを主表示
* raw log のトグル表示
* "Show log" で詳細を展開
