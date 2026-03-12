<!-- 
目的：「プロジェクトの存在理由」の明文化
 -->
# S2J CozyBrew — プロジェクト概要

## 1. プロジェクト概要

* **名称:** S2J CozyBrew
* **Swift Package 名:** s2j-cozy-brew
* **元リポジトリ:** [Cakebrew](https://github.com/brunophilipe/Cakebrew)
* **目的:** AppKit ベースの「Cakebrew」を SwiftUI / Swift を用いて再実装します。
  * コアロジックや再利用可能な部品は Swift Package 化します (s2j-cozy-brew 等)。
  * アプリケーション本体は Xcode App Target (CozyBrew.app) で管理します。
* **対応 OS:** macOS v12.0以上 (可能なら macOS v13+ の API をオプションで活用)
* 設計方針の核:
  * **再利用性 (Package) と実行可能アプリケーション (App Target) の分離** です。
  * UI 再利用部品や Brew 操作ロジックは Swift Package として設計・テスト可能にし、アプリケーション固有のバンドル資産、Info.plist、署名等は App Target に置きます。

S2J CozyBrew (Swift Package 名: `s2j-cozy-brew`) は、AppKit で実装された既存の **Cakebrew** を、**SwiftUI / Swift** ベースに再実装してモダナイズすることを目的とします。
ユーザー層は「ターミナル操作に慣れていない一般ユーザー (for the rest of us)」を想定し、Homebrew (以下 brew) をローカルで安全かつ分かりやすく操作できる GUI アプリケーションを提供します。

---

## 2. 要件ゴール

### 2.1. 機能要件

* Homebrew (brew) と安全に連携する SwiftUI macOS アプリケーションを提供します。
  * brew のコマンド実行 (list / info / install / uninstall / update / upgrade / tap / untap 等) を GUI から行えるようにします。
* Brew の未導入ユーザーに対して、安全で理解しやすい導入 UX を提供します。
  * brew が未導入の場合、公式インストール手順に沿って導入をガイドします (自動化オプションあり)。
  * brew の更新 (アップグレード) 処理は、初心者が安全に実行できる UX を提供します (説明付き、自動バックアップ/ロールバックの考慮)。
  * パッケージ一覧・検索・詳細表示・インストール履歴・ログ表示を提供します。
* コアロジックや UI コンポーネント (サイドバー、About ウィンドウ連携等) を再利用可能な Swift Package として整備します。
  * サイドバーは [S2J Source List](https://github.com/stein2nd/s2j-source-list) を用いて実装します。
  * About ウィンドウは [S2J About Window](https://github.com/stein2nd/s2j-about-window) を採用します。

### 2.2. 非機能要件

* brew の内部実装を再作成しません (CLI をラップします)。
* brew が管理するパッケージの完全な CI 自動テストは本プロジェクトの範囲外です (実環境でのインストールはユーザー端末で行います)。
  * Swift Package (`s2j-cozy-brew`) として管理し、SwiftPM でビルド可能とします。
  * UI は SwiftUI (可能なら macOS v13の `Observation` を利用しますが、最低限 macOS v12対応を保ちます)。
  * セキュリティ: brew 実行は、サンドボックス外のプロセス・コールを行うため、権限/経路の取り扱いを厳密にします。
  * ローカライズ対応 (英語・日本語を初期対応とします)。
  * アクセシビリティ (VoiceOver 等) への対応を実装します。
  * CI: GitHub Actions を用いて macOS ビルド・ユニットテストを実行します。

---

## 3. 準拠仕様

### 3.1. 技術スタック

* [COMMON_SPEC.md](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md) に準拠します。

### 3.2. 開発ルール

* [COMMON_SPEC.md](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md) に準拠します。

### 3.3. 国際化・ローカライズ

* [COMMON_SPEC.md](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md) に準拠します。

### 3.4. コーディング規約

* [COMMON_SPEC.md](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md) に準拠します。

### 3.5. デザイン規約

* [COMMON_SPEC.md](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md) に準拠します。

### 3.6. テスト方針

* [COMMON_SPEC.md](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md) に準拠します。
