<!-- 
目的：Formula / Cask / Tap モデル (brew info --json=v2) の定義
 -->
# S2J CozyBrew — モデル定義仕様

本ドキュメントでは、Homebrew パッケージを表現する `Codable` モデルと、`brew info --json=v2` の構造への対応を定義します。BrewService (CozyBrewService) モジュールの型定義を明文化します。

---

## 1. 概要

* `Package` / `Formula` / `Cask` / `Tap` を表現するモデルを実装します。
* `brew info --json=v2` の JSON 構造に合わせます。
* パース安定化のため、`--json=v2` を標準で利用します。

---

## 2. 基本プロトコル

### 2.1. BrewPackage

```swift
public protocol BrewPackage: Codable, Identifiable {
    var id: String { get }
    var name: String { get }
    var fullName: String { get }
    var desc: String? { get }
    var homepage: String? { get }
    var version: String? { get }
    var installed: [InstalledVersion]? { get }
}
```

---

## 3. 共通型

### 3.1. InstalledVersion

インストール済みバージョン情報です。

| プロパティ | 型 | JSON キー | 説明 |
|------------|-----|-----------|------|
| version | String | `version` | バージョン文字列 |
| installedOnRequest | Bool | `installed_on_request` | ユーザー要求でインストールされたか |
| installedAsDependency | Bool | `installed_as_dependency` | 依存関係としてインストールされたか |

---

## 4. Formula (ソースからビルドするパッケージ)

### 4.1. 主要プロパティ

| プロパティ | 型 | 説明 |
|------------|-----|------|
| id | String | 一意識別子 |
| name | String | パッケージ名 |
| fullName | String | 完全名 (Tap 付き) |
| desc | String? | 説明文 |
| homepage | String? | ホームページ URL |
| version | String? | バージョン |
| installed | [InstalledVersion]? | インストール済みバージョン |
| dependencies | [String]? | 依存パッケージ |
| buildDependencies | [String]? | ビルド時依存 |
| conflictsWith | [String]? | 競合パッケージ |
| pinned | Bool? | ピン留め有無 |
| outdated | Bool? | アップデート可能か |
| deprecated | Bool? | 非推奨か |
| deprecationReason | String? | 非推奨理由 |
| disabled | Bool? | 無効化されているか |
| disableReason | String? | 無効化理由 |

### 4.2. CodingKeys

* `buildDependencies` → `build_dependencies`
* `conflictsWith` → `conflicts_with`
* `deprecationReason` → `deprecation_reason`
* `disableReason` → `disable_reason`
* その他 snake_case 対応

---

## 5. Cask (バイナリ配布パッケージ)

### 5.1. 主要プロパティ

Formula と共通の基本プロパティに加え、Cask 固有のプロパティがあります。

| プロパティ | 型 | 説明 |
|------------|-----|------|
| tap | String? | 属する Tap |
| token | String? | Cask トークン |
| artst | [String]? | アプリ名等 |
| その他 | — | `brew info --json=v2` の出力に合わせる |

---

## 6. Tap (リポジトリ)

### 6.1. 主要プロパティ

| プロパティ | 型 | 説明 |
|------------|-----|------|
| name | String | Tap 名 |
| fullName | String | 完全名 |
| その他 | — | `brew tap` / `brew info` の出力に合わせる |

---

## 7. Package (統一型)

* Formula と Cask を同一の `Package` 型として扱う場合、`fullName` や `tap` で区別します。
* ` brew list --json=v2` / `brew info --json=v2` の出力形式に従います。

---

## 8. BrewCache (キャッシュ機構)

### 8.1. 責務

* JSON とローカルファイルによるキャッシュ管理を実装します。
* TTL (Time To Live) を持たせます。
* オプションで SQLite (GRDB 等) を選択可能とします。

### 8.2. メタデータ

* キャッシュの有効期限
* 取得元 (`brew list` / `brew info` 等) の識別

---

## 9. BrewManager (ViewModel)

### 9.1. 公開 API (@Published)

| プロパティ | 型 | 説明 |
|------------|-----|------|
| installed | [Package] | インストール済みパッケージ一覧 |
| outdated | [Package] | アップデート可能パッケージ一覧 |
| taps | [Tap] | Tap 一覧 |
| searchResults | [Package] | 検索結果 |

### 9.2. 操作

* インストール、アンインストール、アップデートの実行と進行管理
* `brew update` の実行
* パッケージ検索

### 9.3. 失敗ハンドリング

* ユーザー向けメッセージ翻訳レイヤを挟みます (dev message → friendly message)。
* 詳細ログは UI から "Show log" で閲覧可能にします。

---

## 10. JSON 取得コマンド例

| 用途 | コマンド |
|------|----------|
| インストール済み Formula | `brew list --formula --json=v2` |
| インストール済み Cask | `brew list --cask --json=v2` |
| パッケージ詳細 | `brew info --json=v2 <name>` |
| 検索 | `brew search --json=v2 <query>` |

* 出力形式は Homebrew の仕様に依存するため、破壊的変更がある場合は本 spec を更新します。
