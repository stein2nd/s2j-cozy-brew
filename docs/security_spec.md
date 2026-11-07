# S2J CozyBrew — セキュリティ・権限・プライバシー仕様

本ドキュメントでは、実行権限、スクリプト実行、プライバシー、アクセシビリティに関する仕様を定義します。

---

## 1. 実行権限

* brew 自体は通常ユーザー権限で動作します。
* sudo を要求しない設計をまず目指します (brew は通常 sudo を要求しません)。
* brew 実行はサンドボックス外のプロセス・コールを行うため、権限 / 経路の取り扱いを厳密にします。

---

## 2. スクリプト実行

### 2.1. 公式インストール・スクリプト

* 公式インストール・スクリプトはネットワークから取得するため、その実行は **ユーザーの明示的承諾** を必須とします。
* ダウンロード先 URL は固定し、ユーザーに提示します。
* 実行ログはローカルに保存し、ユーザーに提示しますが、デフォルトで外部に送信しません (クラッシュ / クラッシュログ等も同様)。

### 2.2. opt-in の原則

* 自動導入は opt-in。ユーザー承諾必須です。
* 強制的な sudo は避けます。

---

## 3. プライバシー

* デフォルトでテレメトリー / クラッシュ・レポートはオフです。
* 送る場合は opt-in にします。
* 匿名統計を送る場合は opt-in の設定を提供し、プライバシーポリシーを同梱します。

---

## 4. アクセシビリティとローカライズ

### 4.1. ローカライズ

* 初期ロケール: 英語 (en) / 日本語 (ja)
* `Localizable.strings`、`Localizable.stringsdict` を用意します。
* [COMMON_SPEC.md](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md) に準拠します。

### 4.2. VoiceOver

* UI (すべてのインタラクティブ要素) には、VoiceOver 対応の AccessibilityLabel を必ず設定します。
* すべてのインタラクティブ要素に AccessibilityLabel を設定することを目標とします。

### 4.3. コントラスト・フォント

* コントラストとフォントサイズ可変 (Dynamic Type 相当) を考慮した配色とレイアウトとします。
* macOS システム設定に準拠します。

---

## 5. Entitlements

* `CozyBrewApp.entitlements` でアプリケーション権限を管理します。
* 配布用のコード署名 / notarize は App Target のビルド設定で実施します。
* サンドボックス外で brew を実行するため、必要に応じて entitlement を設定します (例: ネットワークアクセス、特定ディレクトリへのアクセス)。

---

## 6. カタログ HTTP と Info.plist

* formulae.brew.sh への HTTPS は App Transport Security 既定（任意ロードなし）のまま行います。
* `BrewFormulaeAPIClient` はリクエストごとに **User-Agent** を設定し、バンドル識別子・バージョンを文字列で含めます。
* `CozyBrewApp/Info.plist` の `CFBundleVersion` は **`<string>`** とし、数値のみの plist 型で CFNetwork が User-Agent 組み立てに失敗しないようにします。

---

## 7. macOS「アプリの管理」(App Management)

* Cask の Upgrade / Install で **他のアプリ** (`/Applications` 内など) を書き換えると、macOS は **プライバシーとセキュリティ** の通知で変更を阻止することがあります。
* これは TCC の **App Management** によるもので、CozyBrew 単体の entitlement では自動付与できず、**ユーザーがシステム設定で CozyBrew を許可**する必要があります。
* 手順 (日本語 UI): **システム設定 → プライバシーとセキュリティ → アプリの管理** で CozyBrew をオン。
* 許可後に同じ Cask を再度 Upgrade する。拒否を続ける場合は Terminal で `brew upgrade --cask <name>` を案内する。
