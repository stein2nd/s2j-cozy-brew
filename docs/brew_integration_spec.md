<!-- 
目的：brew CLI との連携・バイナリ検出・プロセス実行の定義
 -->
# S2J CozyBrew — Brew CLI 連携仕様

本ドキュメントでは、Homebrew (brew) との連携に関する仕様を定義します。BrewCore (CozyBrewCore) モジュールの責務と API を明文化します。

---

## 1. 概要

* brew の内部実装は再作成しません。CLI をラップします。
* 実行は `/usr/bin/env brew ...` 形式で、環境 PATH を尊重します。
* 非同期実行 (`async/await`) を標準とします。

---

## 2. BrewBinaryLocator (バイナリ検出)

### 2.1. 検出パス

| アーキテクチャ | 優先パス | フォールバック |
|----------------|----------|----------------|
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

* 標準入出力をストリームへ流す設計とし、インストール進捗等でリアルタイム表示に対応します。
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

## 5. 権限・実行コンテキスト

* brew の実行ユーザー権限を把握します。
* 環境変数 (`HOMEBREW_PREFIX` 等) を把握します。
* brew 自体は通常ユーザー権限で動作し、sudo を要求しない設計を目指します (brew は通常 sudo を要求しません)。

---

## 6. 利用例 (コマンド)

| 用途 | 引数例 |
|------|--------|
| インストール済み一覧 | `["list", "--formula"]` / `["list", "--cask"]` |
| パッケージ情報 | `["info", "--json=v2", name]` |
| インストール | `["install", name]` |
| アンインストール | `["uninstall", name]` |
| アップグレード | `["upgrade", name]` または `["upgrade"]` |
| リポジトリ更新 | `["update"]` |
| 検索 | `["search", query]` |
| Tap 一覧 | `["tap"]` |

* 詳細は [models_spec.md](models_spec.md) の JSON 形式と合わせて参照してください。
