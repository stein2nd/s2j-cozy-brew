# S2J CozyBrew - CHANGELOG

## unreleased

## 1.0.1 - 2026-06-11

* Swift v6.3.x および Xcode v26.x に対応
* `CozyBrew.xcodeproj` を Xcode v26.3形式（`objectVersion` 77）に更新し、推奨ビルド設定を適用
* `swift-tools-version` を v6.0に更新
* `BrewInstaller` のリアルタイム出力処理を Swift v6の並行性チェックに対応
* Xcode プロジェクトを SPM ローカル参照からネイティブ framework ターゲット構成に変更（パッケージ二重読み込み、リンクエラーを解消）
* framework ターゲットに `GENERATE_INFOPLIST_FILE` を追加（CodeSign 警告を解消）
* デプロイメントターゲットを macOS v14.6に統一（`Info.plist` の `LSMinimumSystemVersion` を含む）
* `Cask` の `name` デコードを配列、文字列の両形式に対応
* `ModelsTests.testCaskDecoding` をデコード検証に修正
* `README.md` に macOS、Xcode バッジを追加
