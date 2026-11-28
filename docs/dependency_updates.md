# S2J CozyBrew — 依存モジュールの更新

本リポジトリでは、用途の異なる2系統の依存を管理します。

| 種別 | 定義ファイル | ロックファイル | 取得先 (npm の `node_modules` 相当) |
| --- | --- | --- | --- |
| ドキュメント lint (npm) | `package.json` | `package-lock.json` | `node_modules/` |
| Swift ライブラリ (SPM) | `Package.swift` | `Package.resolved` | `.build/` (通常は Git 管理外) |

Xcode プロジェクト利用時は、ルートの `Package.resolved` に加え、下記もそろえます。

* `CozyBrew.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`

### CozyBrew の開発用 npm スクリプト (抜粋) `{@dependency_updates:s-cozybrew-npm}`

| スクリプト | 用途 |
| --- | --- |
| `npm run xcode:generate` | `project.yml` から `CozyBrew.xcodeproj` を再生成 (`Sources/` に `.swift` を追加したあと必須) |
| `npm run lint:swift` | `xcode:generate` → SwiftLint → SwiftFormat → Periphery (`lint:periphery`) |
| `npm run lint:periphery` | `periphery scan --strict` (`.periphery.yml`)。PATH 上の `periphery` バイナリが必要 |
| `npm run test:local:macOS` | `swift test` 等 ([testing_spec.md](testing_spec.md) の層どおり) |
| `npm run swift:install` | SPM の入れ直し (`Package.resolved` 更新 + Xcode 側にコピー)。**lint のたびには実行しない** |
| `npm run version:sync` | `package.json` の `version` / `buildNumber` → `project.yml`・`Info.plist` → `xcodegen` (アプリケーションの Version / Build の正本) |
| `npm run version:check` | 上記が同期済みか確認 (CI 向け) |
| `npm run version:bump-build` | `buildNumber` を +1してから `version:sync` 相当 |
| `npm run swift:pin-diff` | `Package.resolved` の Git 差分と identity 単位の要約 |
| `npm run release:after-spm-update` | SPM 更新後: `swift:ncu` → `xcode:generate` → `lint:build` |
| `npm run release:before-release-build` | Xcode **Release Build** の直前 |
| `npm run release:after-release-build` | Release ビルド後: `ack:doctor` → `ack:generate` |
| `npm run release:before-tag-push` | `git tag` / GitHub Release の直前 |
| `npm run build:release` | Release を `build/DerivedData` にビルドのみ |
| `npm run build:release:clean` | 上記の前に `build/DerivedData` を削除 (フル Release。Finder の日付を新しくしたいとき) |
| `npm run install:applications` | Release `.app` を `/Applications/CozyBrew.app` に ditto (実行中は中止、`--build` でビルド併用) |
| `npm run install:applications:build` | 上記と同じ (Release ビルド → 複製) |
| `npm run install:applications:build:clean` | クリーン後に Release ビルド → `/Applications` に複製 (`--build --clean`) |

### 版番号の正本 (CozyBrewApp) `{@dependency_updates:s-cozybrewapp}`

| 項目 | 正本 | 備考 |
| --- | --- | --- |
| 表示版 (`MARKETING_VERSION`) | `package.json` → `version` | SemVer。プレリリースは当面想定しない |
| ビルド (`CURRENT_PROJECT_VERSION`) | `package.json` → `buildNumber` | **配布物を出すたび** に更新 (同じ `version` の再配布は Build のみ +1) |
| Run Number | **使わない** | ローカル Release + `ack:generate` と整合させるため |

**リリースチェックリスト (配布用)**

1. 依存: 必要なら `ncu` 系 / `swift:ncu` → `swift:ncu:update` → `swift:install` → **`npm run release:after-spm-update`**
2. 版: `package.json` の `version` / `buildNumber` を更新 (Build のみなら **`npm run version:bump-build`**)
3. 同期: **`npm run version:sync`** (`bump-build` はここまで含む)
4. 品質: **`npm run lint:swift`** (日常どおり)
5. Xcode: Clean / Package / Signing → **Release Build** の前に **`npm run release:before-release-build`**
6. ビルド後: **`npm run release:after-release-build`** → Run でスモーク
7. 公開前: CHANGELOG 追記 → commit → **`npm run release:before-tag-push`** → `git tag v*`

`lint:swift` のたびに `version:sync` は不要です。**配布・タグの直前** だけ上記マイルストーンを使います。

`CozyBrewUIComponents` の `Localizable.strings` を更新したあとは **`npm run xcode:generate`** で Xcode プロジェクトにリソースを反映してください。

### 署名 (Team / Configuration) `{@dependency_updates:s-signing}`

* **正本:** `project.yml` の `settings.base` に `CODE_SIGN_STYLE: Automatic` と `DEVELOPMENT_TEAM` を置きます。`CozyBrewApp` ターゲットに **空の** `DEVELOPMENT_TEAM: ""` を書くと、Project の Configuration を Debug ↔ Release で切り替えたときに Xcode の **Signing** が None に見えることがあります (ターゲット側の空値が Project より優先されるため)。
* **`npm run xcode:generate` のあと:** Xcode を閉じてから再生成するか、プロジェクトを開き直してください。Team が別 ID なら `project.yml` の `DEVELOPMENT_TEAM` を自分の Team に変えてから `xcodegen` します。
* **Framework の Signing Certificate:** 埋め込み framework (Core / Service / UIComponents) は Xcode 推奨どおり **`Don't Code Sign`** (`CODE_SIGNING_ALLOWED: NO`、`CODE_SIGN_IDENTITY: "-"`)。**Signing UI が None / Don't Code Sign / Sign to Run Locally でも正常**です。実際の署名は `CozyBrew.app` への **Embed Frameworks (CodeSignOnCopy)** で行います。Team は Project 共通の `DEVELOPMENT_TEAM` を参照します。
* **`xcodegen generate` の Unknown key:** 正本は [XcodeGen ProjectSpec](https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md) に合わせる。`LastUpgradeCheck` はルート `attributes`、`resources` は `sources` + `buildPhase: resources`、framework の `PRODUCT_*` は `settings.base`(`groups` と併用時)。`s2j-about-window` の `project.yml` も同型。
* **Release で `bundle format unrecognized` (CodeSign):** 埋め込み framework に **`Versions/A/Resources/Info.plist` がない** と失敗します。`settingGroups.embeddedFramework` に `GENERATE_INFOPLIST_FILE: YES` を含めること (XcodeGen で `groups` のみにしたとき plist 生成が落ちることがある)。修正後は **Clean Build Folder** または `rm -rf build/DerivedData` を推奨。
* **「Update to recommended settings」:** ダイアログの主な内容は次のとおり。**Perform Changes する前に** `project.yml` と重複しないか確認し、正本は `npm run xcode:generate` を推奨します。
  * **Disable Code Signing** (各 framework) — 上記と同じ。`settingGroups.embeddedFramework` で吸収済み。
  * **モジュール Verifier の有効化** — `ENABLE_MODULE_VERIFIER: YES` と `MODULE_VERIFIER_SUPPORTED_LANGUAGE_STANDARDS: gnu11 gnu++14` (framework グループ)。
  * **Missing Localizability** — Project の `CLANG_ANALYZER_LOCALIZABILITY_NONLOCALIZED` (en/ja 向け)。

### Periphery (ローカル vs CI) `{@dependency_updates:s-periphery}`

| 環境 | 推奨 |
| --- | --- |
| **ローカル Mac** | `brew install periphery` (または PATH 上の3.x)。Xcode が入っていれば通常そのまま `npm run lint:swift` 可能 |
| **GitHub Actions** | `.github/workflows/swift-quality.yml` が正本。Release **3.8.0** zip + `DYLD_LIBRARY_PATH` (Xcode toolchain の `libIndexStore.dylib`)。Homebrew formula は deprecated 注釈が Actions に出るほか、過去に Release 直置きのみだと runner で IndexStore 未解決で abort したため CI では使わない |

workflow 内の `PERIPHERY_VERSION` を上げるときは、ローカルでも同じ版を試し、`lint:periphery` が通ることを確認してからコミットします。

### SPM の pin が変わったか見るには `{@dependency_updates:s-spm-pin}`

Xcode のオレンジ表示は **Git / 未保存** 向けで、「このサードパーティだけ古い」とは限りません。時間が経ってから差分をつかむには次が確実です。

| 手がかり | 内容 |
| --- | --- |
| **`npm run swift:ncu`** | リモートより pin が古い／`from:` より新 tag があると **終了コード1** と `↑ パッケージ名` 行 |
| **`npm run swift:pin-diff`** | コミット済み `Package.resolved` との diff と **identity ごとの before → after** |
| **Cursor / Git** | `Package.resolved` を開くと行単位の diff (npm の lock と同様) |

`swift:ncu` は **今この瞬間に更新可能か**、`pin-diff` は **いつ・どの identity が変わったか** の確認向けです。ack の前は **`swift:ncu` が通ること** をゲートにしてください。

### `s2j-source-list` の最低バージョン `{@dependency_updates:s-s2j-source-list}`

CozyBrew のサイドバーは **`s2j-source-list` v2.0.14以降** を前提とします (サイドバー選択時の SwiftUI 警告修正、`SidebarView` の二重タップ整理。[s2j-source-list#10](https://github.com/stein2nd/s2j-source-list/issues/10))。

`Package.resolved` の revision をコミットし、Xcode と CLI で同じ pin を使ってください。`main` 追従で更新するときは `npm run swift:ncu` / `swift:install` のあとビルド・手動スモーク (サイドバー選択) を行います。

---

## npm (`@s2j/docs-linter` など) `{@dependency_updates:s-npm-s2j-docs-linter}`

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

初回セットアップや lock のみ再生成する場合は、手順3のみ (`npm install`) でかまいません。

---

## SPM (`s2j-source-list` / `s2j-about-window`) `{@dependency_updates:s-spm-s2j-source-list-s2j-about-window}`

npm / Composer と同じ考え方を、`scripts/swift-deps.sh` と `package.json` のスクリプトで行います。

| 目的 | npm | SPM (本リポジトリ) |
| --- | --- | --- |
| 更新があるか確認 | `ncu` | `npm run swift:ncu` |
| 要件を最新にして入れ直し | `ncu -u` のあと `npm install` | `npm run swift:ncu:update` |
| ロックを捨て、入れ直し | `rm -rf node_modules package-lock.json && npm install` | `npm run swift:install` |

### 推奨フロー `{@dependency_updates:s-h007}`

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

### 現在の `Package.swift` (`branch: "main"`) `{@dependency_updates:s-package-swift-branch-main}`

`s2j-source-list` と `s2j-about-window` は **`main` ブランチ追従** です。

* **`swift:ncu`:** `Package.resolved` の revision と GitHub の `main` 先頭を比較します。
* **`swift:ncu:update`:** `Package.swift` は変更不要 (`branch: main` のため)。続けて `swift:install` 相当で最新 `main` を取得します。

semver で pin したい場合は、`Package.swift` をたとえば `.package(url: "...", from: "2.0.0")` に変更すると、`swift:ncu:update` が最新 tag への `from` 更新も試みます。

### その他のコマンド `{@dependency_updates:s-h009}`

```zsh
npm run swift:update      # swift package update のみ (クリーン入れ直しなし)
npm run swift:resolve     # 既存 lock を満たす範囲で解決
npm run swift:show-deps   # 依存ツリー表示
```

Xcode から更新する場合: `File → Packages → Update to Latest Package Versions`

### Xcode と `Package.swift` の二重管理 (重要) `{@dependency_updates:s-xcode-package-swift}`

CozyBrew では SPM 依存が **2経路** あります。

| 経路 | 定義 | ロック |
| --- | --- | --- |
| **CLI / `swift build`** | ルート `Package.swift` | ルート `Package.resolved` |
| **Xcode (`CozyBrew.xcodeproj`)** | `project.yml` の `packages:` → `xcodegen` が `project.pbxproj` に書く | `CozyBrew.xcodeproj/.../swiftpm/Package.resolved` |

`project.yml` で `branch: main` にしても、**`xcodegen generate` 前の `project.pbxproj` に `minimumVersion` が残っている** と、Xcode の **`Reset Package Caches`** 後に **semver (例: 3.0.1) 表示に戻ります**。

**`main` 追従にそろえたあと**

1. `project.yml` で `branch: main` を確認
2. `npm run xcode:generate` (`pbxproj` の `requirement` が `kind = branch` になること)
3. `npm run swift:install` (ルート `Package.resolved` を更新し、Xcode 側にコピー)

Xcode の Package Dependencies パネルでは、`main` 指定でも **近い tag 番号が併記される** ことがあります。正は **`Package.resolved` の `state.branch`** です。

---

## 更新後 `{@dependency_updates:s-h011}`

* `swift build` または Xcode でビルド・テスト
* 変更した lock (`package-lock.json` / `Package.resolved` および Xcode 側) をコミット
* リリース時は `CHANGELOG.md` に追記

---

## 関連 `{@dependency_updates:s-h012}`

* [architecture.md](architecture.md) — モジュール構成と外部パッケージの位置付け
* [README.md](../README.md) — ビルド手順
