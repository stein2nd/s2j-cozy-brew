# S2J CozyBrew — 仕様書の起点

本ドキュメントでは、Swift アプリケーション「S2J CozyBrew」の仕様を細分化した各ファイルへのリンクを提供します。

* 本アプリケーションの設計は、以下の共通 SPEC に準拠します。
    * [Swift/SwiftUI 共通仕様](https://github.com/stein2nd/xcode-common-specs/blob/main/docs/COMMON_SPEC.md)
* 以下は、本アプリケーション固有の仕様をまとめたものです。

---

## 仕様書一覧

| ファイル | 役割 |
|----------|------|
| [overview.md](overview.md) | プロジェクトの存在理由・目的・要件ゴールの明文化 |
| [architecture.md](architecture.md) | コード構造と責務の明文化 |
| [brew_integration_spec.md](brew_integration_spec.md) | brew CLI 契約・バイナリ検出・プロセス実行の定義 |
| [models_spec.md](models_spec.md) | Formula / Cask / Tap モデル（brew info --json=v2）の定義 |
| [ux_flows_spec.md](ux_flows_spec.md) | 初回起動・パッケージ操作の UX フロー定義 |
| [security_spec.md](security_spec.md) | 権限・サンドボックス・スクリプト実行・アクセシビリティの定義 |
| [design_spec.md](design_spec.md) | デザイン・ブランディングの定義 |

---

## その他ドキュメント

* [SPEC.md](SPEC.md) - 実装状況サマリ・Backlog・品質評価・Appendix（従来の統合仕様書）
* [SPEC_STRUCTURE.md](SPEC_STRUCTURE.md) - 仕様書細分化の考え方と S2J Cozy Brew への適用
