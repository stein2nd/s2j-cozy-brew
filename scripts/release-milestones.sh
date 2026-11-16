#!/usr/bin/env bash
# リリース／配布のマイルストーンごとに実行する npm スクリプトの実体。
#
#   after-spm-update     — swift:install 等のあと (pin 確認 → xcodegen → CLI ビルド)
#   before-release-build — Xcode Release Build の直前
#   after-release-build  — Release Build のあと (Acknowledgements)
#   before-tag-push      — git tag push / GitHub Release の直前
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

usage() {
  cat <<'EOF'
Usage: ./scripts/release-milestones.sh <milestone>

  after-spm-update     SPM 更新後: swift:ncu → xcode:generate → lint:build
  before-release-build 配布用 Release の前: version:check → swift:ncu
  after-release-build  Release ビルド後: ack:doctor → ack:generate
  before-tag-push      タグ push 前: version:check → swift:ncu → lint:docs
EOF
}

run_npm() {
  npm run --silent "$@" 2>&1
}

milestone="${1:-}"
case "$milestone" in
  after-spm-update)
    echo "== after-spm-update: SPM pin が最新であること → プロジェクト再生成 → ビルド確認 =="
    run_npm swift:ncu
    run_npm xcode:generate
    run_npm lint:build
    echo "OK: SPM 更新後のゲートを通過しました。続けて Xcode でスモーク (Package / Signing / Run) を推奨します。"
    ;;
  before-release-build)
    echo "== before-release-build: 配布用 Release の前 =="
    echo "ヒント: package.json の version / buildNumber を更新したら npm run version:sync を実行してください。"
    echo "       同じ version で再配布だけなら buildNumber を +1 (npm run version:bump-build) できます。"
    run_npm version:check
    run_npm swift:ncu
    echo "OK: Xcode で Release Build を実行できます。"
    ;;
  after-release-build)
    echo "== after-release-build: Release ビルド直後 (ack.config の Release .app を前提) =="
    run_npm ack:doctor
    run_npm ack:generate
    echo "OK: ACKNOWLEDGEMENTS を更新しました。Run でスモークし、変更をコミットしてください。"
    ;;
  before-tag-push)
    echo "== before-tag-push: git tag / GitHub Release の前 =="
    run_npm version:check
    run_npm swift:ncu
    run_npm lint:docs
    echo "OK: CHANGELOG.md 追記・コミット・tag v\$(node -p \"require('./package.json').version\") を忘れずに。"
    ;;
  ""|-h|--help|help)
    usage
    exit 0
    ;;
  *)
    echo "不明なマイルストーン: $milestone" >&2
    usage >&2
    exit 2
    ;;
esac