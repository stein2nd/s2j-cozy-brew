# S2J CozyBrew — デザイン・ブランディング仕様

本ドキュメントでは、Cozy ブランドに基づくビジュアル・デザインの指針を定義します。詳細なデザイン規約は [COMMON_SPEC.md](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md) に準拠します。

---

## 1. ロゴ

* 角丸、シンプルなカップ / 湯気モチーフ
* CozyBrew ロゴ案を参照

---

## 2. アプリケーション・アイコン

* 1024×1024px PNG / SVG を用意します。
* `Assets.xcassets` 内の `AppIcon.appiconset` で管理します（実装済み。ソース画像は `CozyBrewApp/Resources/AppIcon-source.jpg` を参照可）。
* About シートおよび Dock はバンドル `AppIcon`（`AboutView` は `NSApplication.shared.applicationIconImage`）を表示します。

---

## 3. 配色

* ベース色: Warm beige + Deep brown
* アクセント色: ソフトブルーやミントを検討

---

## 4. フォント

* UI: Apple の San Francisco を優先
* ブランディング用ロゴ: 丸みフォント (例: SF Rounded 系、Nunito)

---

## 5. ダークモード

* 完全なダークモード対応を目指します。
* システム設定に準拠した配色とレイアウトとします。
