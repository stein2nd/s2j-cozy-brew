# S2J CozyBrew — Brew CLI 連携仕様

本ドキュメントでは、Homebrew (brew) との連携に関する仕様を定義します。BrewCore (CozyBrewCore) モジュールの責務と API を明文化します。

---

## 1. 概要

* brew の内部実装は再作成しません。CLI をラップします。
* 実行は `/usr/bin/env brew ...` 形式で、環境 PATH を尊重します。
* 非同期実行 (`async/await`) を標準とします。
* **非対話**: すべての brew 実行で `HOMEBREW_NO_ASK=1` / `NONINTERACTIVE=1` を付与します。`install` / `upgrade` には `--yes` を付け、依存 Formula も含めたアップグレード確認 (`Do you want to proceed…`) でブロックしないようにします。

---

## 2. BrewBinaryLocator (バイナリ検出)

### 2.1. 検出パス

| アーキテクチャ | 優先パス | フォールバック |
| --- | --- | --- |
| Apple Silicon | `/opt/homebrew/bin/brew` | `which brew` |
| Intel | `/usr/local/bin/brew` | `which brew` |

### 2.2. 検出ロジック

1. 実行環境 (Apple Silicon / Intel) を判定します。
2. 上記の優先パスが存在するか確認します。
3. 存在しない場合、`/usr/bin/which brew` の結果を使用します。
4. いずれも見つからない場合は「brew 未導入」と判定します。

### 2.3. 環境 PATH の補正

* `HOMEBREW_PREFIX` 等の環境変数を把握し、brew 実行時に適切な PATH が通るようにします。
* Apple Silicon / Intel に応じた PATH 設定を検証します。

---

## 3. BrewProcess (プロセス実行ラッパー)

### 3.1. API 設計

```swift
public struct BrewResult {
    public let stdout: String
    public let stderr: String
    public let code: Int32
}

public final class BrewProcess {
    public static func run(_ args: [String], environment: [String:String]? = nil) async throws -> BrewResult
}
```

### 3.2. 実行方式

* 実行体: `/usr/bin/env`
* 引数: `["brew"] + args`
* 標準出力・標準エラーを Pipe で分離し、終了後に文字列として取得します。

### 3.3. 実行例 (概念)

```swift
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
```

### 3.4. エンコーディング

* 出力は UTF-8 で解釈します。
* 解釈に失敗した部分は適宜フォールバックします。

### 3.5. リアルタイム・ログ

* 標準入出力をストリームに流す設計とし、インストール進捗等でリアルタイム表示に対応します。
* `InstallProgressView` 等でログを逐次表示できるようにします。

---

## 4. BrewInstaller (Homebrew インストール補助)

### 4.1. 目的

brew 未導入ユーザーに対して、公式インストール・スクリプトの実行を補助します。

### 4.2. 公式インストール・スクリプト

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

* ダウンロード先 URL は固定し、ユーザーに提示します。
* 実行は **ユーザーの明示的承諾** を必須とします (opt-in)。

### 4.3. 責務

* ユーザー許諾確認
* ログのリアルタイム表示
* 失敗時の対処説明
* 導入スクリプト実行ロジック (ユーザー承認の UI フローが前提)

### 4.4. 設計上の注意

* 自動導入は opt-in、ユーザー承諾必須です。
* 強制的な sudo は避けます。
* スクリプト実行は標準出力で行い、エラーをリアルタイム表示します。
* 失敗時のログ保存を行います。
* インストール中は明確な進捗とロールバック手順を表示します。

---

## 5. パッケージ詳細 (`brew info`)

* 詳細画面表示時に `brew info --json=v2 <name>` を実行します (Cask は `--cask` を付与)。
* 一覧・Outdated 由来の `Package` (インストール状態・`installed_versions` 等) とマージし、**説明 (`desc`)**・**homepage**・**dependencies** を補完します。
* 取得失敗時は一覧データのみ表示し、警告メッセージを出します。

---

## 6. brew services 連携

### 5.1. 一覧の照合

* 起動時に `brew services list --json` を実行し、`Name` を Formula 名として保持します。
* Installed / Outdated / Formulae 一覧では、`brew services` に登録がある Formula を **上位に表示** します (`started` > `error` > その他)。
* Installed / Formulae / Casks 表示時は `brew outdated` と照合し、該当行に Update Available / [Upgrade] を付与します。
* 行バッジ `Service · {status}` で状態を示します。

### 5.2. アップグレード

* `brew services` に登録され、状態が `started` または `error` の Formula を Upgrade する場合:
  1. `brew services stop <name>`
  2. `brew upgrade <name>`
  3. `brew upgrade` 成功後に `brew services start <name>` (再起動)
* Upgrade 失敗時は、可能なら `brew services start` でサービスを復旧します。
* Cask は `brew services` の対象外のため、従来どおり `brew upgrade --cask` のみです。

### 5.3. Cask と管理者パスワード

* `/Applications` への配置などで Homebrew が `sudo` を使う Cask では、Upgrade 中に **macOS 標準の管理者パスワードダイアログ** が出ることがあります (CozyBrew 側では `NONINTERACTIVE` / `--yes` でも抑止できません)。
* UI は Cask Upgrade 中に「パスワードを求められることがある」旨を **右上の進行カード** で案内します (全画面の暗幕オーバーレイは使わず、管理者ダイアログが前面に来やすくする)。
* ダイアログをキャンセルした・CLI が失敗した場合は、意訳メッセージと生ログを表示し、必要なら Terminal で `brew upgrade --cask <name>` を案内します。
* **「アプリの変更が阻止されました」** (App Management): Cask が他アプリを更新する際、macOS が CozyBrew を拒否することがあります。**システム設定 → プライバシーとセキュリティ → アプリの管理** で CozyBrew をオンにし、再度 Upgrade します (CozyBrew から admin パスワードだけでは足りない場合があります)。

---

## 7. 権限・実行コンテキスト

* brew の実行ユーザー権限を把握します。
* 環境変数 (`HOMEBREW_PREFIX` 等) を把握します。
* brew 自体は通常ユーザー権限で動作し、sudo を要求しない設計を目指します (brew は通常 sudo を要求しません)。

---

## 8. `brew doctor` (Warnings タブ)

* コマンド: `["doctor"]`（JSON API なし、プレーンテキストのみ）。
* **stdout と stderr を結合** して `BrewDoctorParser` に渡します（Warning 本文は stderr に出ることが多い）。
* **終了コード 1** でも Warning がパースできれば成功扱いとし、`doctorErrorMessage` は立てません。
* Disclaimer 行は `preamble`、各 `Warning:` ブロックは `BrewDoctorWarning`（`title` / `bodyLines` / 先頭インデント行の `items`）に分割します。
* 空出力かつ非ゼロ終了のみを実行失敗とみなします。

---

## 9. Formulae / Casks カタログタブ

* **Formulae** / **Casks** タブは [formulae.brew.sh](https://formulae.brew.sh/) の JSON API から取得します (`/api/formula.json` / `/api/cask.json`)。Web ページの HTML ではなく API を使用します。
* 応答を `Formula` / `Cask` としてデコードし `Package` 化。ローカル `brew list` と名前照合してインストール状態を上書きします。
* 一覧は **名前順**。UI では先頭文字の **7 ページ** (A–E … 6–0) に分割し、検索なし時は 1 ページ分のみ表示する (全件を 1 つの `List` に載せない)。
* 生 JSON を 6 時間キャッシュ。decode はバックグラウンド、`Package` 配列を UI に反映します。
* HTTP は `BrewFormulaeAPIClient` が `URLSession` で取得します。**`User-Agent` を明示**（`cozyBrewUserAgent()`）。`Info.plist` の `CFBundleShortVersionString` / `CFBundleVersion` は **文字列型** とし、CFNetwork がバージョンを文字列として読めるようにします（`CFBundleVersion` が整数のみだと HTTPS 初期化時にクラッシュしうる）。

---

## 10. 利用例 (コマンド)

| 用途 | 引数例 |
| --- | --- |
| 環境診断 (Warnings) | `["doctor"]` |
| Formulae カタログ (HTTP) | `https://formulae.brew.sh/api/formula.json` |
| Casks カタログ (HTTP) | `https://formulae.brew.sh/api/cask.json` |
| インストール済み一覧 | `["list", "--formula"]` / `["list", "--cask"]` |
| パッケージ情報 | `["info", "--json=v2", name]` |
| インストール | `["install", "--yes", name]` |
| アンインストール | `["uninstall", name]` |
| アップグレード | `["upgrade", "--yes", name]` または `["upgrade", "--yes"]` |
| リポジトリ更新 | `["update"]` |
| 検索 | `["search", query]` |
| Tap 一覧 | `["tap"]` |

* 詳細は [models_spec.md](models_spec.md) の JSON 形式と合わせて参照してください。
