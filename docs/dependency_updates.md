# 依存モジュールの更新

本リポジトリでは、用途の異なる2系統の依存を管理します。

| 種別 | 定義ファイル | ロックファイル | 取得先 (npm の `node_modules` 相当) |
| --- | --- | --- | --- |
| ドキュメント lint (npm) | `package.json` | `package-lock.json` | `node_modules/` |
| Swift ライブラリ (SPM) | `Package.swift` | `Package.resolved` | `.build/` (通常は git 管理外) |

Xcode プロジェクト利用時は、ルートの `Package.resolved` に加え、下記も揃えます。

* `CozyBrew.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`

---

## npm (`@s2j/docs-linter` など)

他 S2J リポジトリと同様、**確認 → 要件更新 → 入れ直し** の順で行います。

1. **更新があるか確認** (`ncu` 相当)

   ```zsh
   ncu
   ```

2. **`package.json` のバージョン範囲を最新に更新** (`ncu -u` 相当)

   ```zsh
   ncu -u
   ```

3. **その時点の最新で入れ直し** (`npm install` 相当)

   ```zsh
   rm -rf node_modules package-lock.json
   npm install
   ```

初回セットアップや lock のみ再生成する場合は、手順3のみ (`npm install`) で構いません。

---

## SPM (`s2j-source-list` / `s2j-about-window`)

npm / Composer と同じ考え方を、`scripts/swift-deps.sh` と `package.json` のスクリプトで行います。

| 目的 | npm | SPM (本リポジトリ) |
| --- | --- | --- |
| 更新があるか確認 | `ncu` | `npm run swift:ncu` |
| 要件を最新にして入れ直し | `ncu -u` のあと `npm install` | `npm run swift:ncu:update` |
| ロックを捨てて入れ直し | `rm -rf node_modules package-lock.json && npm install` | `npm run swift:install` |

### 推奨フロー

```zsh
# 1. 更新があるか (更新ありなら終了コード 1)
npm run swift:ncu

# 2. 最新に更新して解決し直し
npm run swift:ncu:update

# 3. ビルドで確認
swift build
```

`swift:ncu:update` の内部では、おおむね下記を実行します。

* `Package.swift` で `from: "x.y.z"` 指定がある場合のみ、最新 tag に書き換え (`ncu -u` 相当)
* `swift package reset` → `Package.resolved` 削除 → `swift package update` (`npm install` 相当)
* Xcode 用 `Package.resolved` をルートと同期

### 現在の `Package.swift` (`branch: "main"`)

`s2j-source-list` と `s2j-about-window` は **`main` ブランチ追従**です。

* **`swift:ncu`:** `Package.resolved` の revision と GitHub の `main` 先頭を比較します。
* **`swift:ncu:update`:** `Package.swift` は変更不要 (`branch: main` のため)。続けて `swift:install` 相当で最新 `main` を取得します。

semver で pin したい場合は、`Package.swift` を例えば `.package(url: "...", from: "2.0.0")` に変更すると、`swift:ncu:update` が最新 tag への `from` 更新も試みます。

### その他のコマンド

```zsh
npm run swift:update      # swift package update のみ (クリーン入れ直しなし)
npm run swift:resolve     # 既存 lock を満たす範囲で解決
npm run swift:show-deps   # 依存ツリー表示
```

Xcode から更新する場合: `File → Packages → Update to Latest Package Versions`

---

## 更新後

* `swift build` または Xcode でビルド・テスト
* 変更した lock (`package-lock.json` / `Package.resolved` および Xcode 側) をコミット
* リリース時は `CHANGELOG.md` に追記

---

## 関連

* [architecture.md](architecture.md) — モジュール構成と外部パッケージの位置づけ
* [README.md](../README.md) — ビルド手順
