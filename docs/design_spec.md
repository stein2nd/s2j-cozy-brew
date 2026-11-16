# S2J CozyBrew — デザイン・ブランディング仕様

本ドキュメントでは、Cozy ブランドにもとづくビジュアル・デザインの指針を定義します。詳細なデザイン規約は [COMMON_SPEC.md](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md) に準拠します。

---

## 1. ロゴ `{@design_spec:s1}`

* 角丸、シンプルなカップ / 湯気モチーフ
* CozyBrew ロゴ案を参照

---

## 2. アプリケーション・アイコン `{@design_spec:s2}`

* 1024×1024px PNG / SVG を用意します。
* `Assets.xcassets` 内の `AppIcon.appiconset` で管理します (実装済み。ソース画像は `CozyBrewApp/Resources/AppIcon-source.jpg` を参照可)。
* About シートおよび Dock はバンドル `AppIcon` (`AboutView` は `NSApplication.shared.applicationIconImage`) を表示します。

---

## 3. 配色 `{@design_spec:s3}`

* ベース色: Warm beige + Deep brown
* アクセント色: ソフトブルーやミントを検討

---

## 4. フォント `{@design_spec:s4}`

* UI: Apple の San Francisco を優先
* ブランディング用ロゴ: 丸みフォント (例: SF Rounded 系、Nunito)

---

## 5. ダークモード `{@design_spec:s5}`

* 完全なダークモード対応を目指します。
* システム設定に準拠した配色とレイアウトとします。
