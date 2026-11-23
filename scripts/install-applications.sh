#!/usr/bin/env bash
# Release の CozyBrewApp.app を /Applications に ditto する。
# 既定の導出先は build/DerivedData (Xcode 既定の DerivedData とは別)。
#
# Usage:
#   ./scripts/install-applications.sh              # copy のみ (Release 成果物が build/DerivedData にある前提)
#   ./scripts/install-applications.sh --build      # Release ビルド → copy
#   ./scripts/install-applications.sh --build-only # Release ビルドのみ (copy しない)
#   ./scripts/install-applications.sh --src /path/to/CozyBrewApp.app
#   ./scripts/install-applications.sh --dest /Applications/CozyBrew.app --force
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT="CozyBrew.xcodeproj"
SCHEME="CozyBrewApp"
CONFIGURATION="Release"
DERIVED_DATA="${DERIVED_DATA:-$ROOT/build/DerivedData}"
PRODUCT_NAME="CozyBrewApp.app"
DEFAULT_SRC="$DERIVED_DATA/Build/Products/$CONFIGURATION/$PRODUCT_NAME"
DEST="${INSTALL_DEST:-/Applications/CozyBrew.app}"
DO_BUILD=false
BUILD_ONLY=false
DO_INSTALL=true
FORCE=false
SRC=""

usage() {
  sed -n '3,9p' "$0" | sed 's/^# \{0,1\}//'
  echo ""
  echo "環境変数: INSTALL_DEST (既定 /Applications/CozyBrew.app), DERIVED_DATA"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build)
      DO_BUILD=true
      ;;
    --build-only)
      DO_BUILD=true
      BUILD_ONLY=true
      DO_INSTALL=false
      ;;
    --force) FORCE=true ;;
    --src)
      shift
      SRC="${1:?--src requires a path}"
      ;;
    --dest)
      shift
      DEST="${1:?--dest requires a path}"
      ;;
    -h|--help|help)
      usage
      exit 0
      ;;
    *)
      echo "不明な引数: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [[ "$DO_BUILD" == true ]]; then
  echo "== Release ビルド (derivedDataPath: $DERIVED_DATA) =="
  xcodebuild build \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination 'platform=macOS' \
    -derivedDataPath "$DERIVED_DATA"
fi

if [[ -z "$SRC" ]]; then
  SRC="$DEFAULT_SRC"
fi

if [[ ! -d "$SRC" ]]; then
  cat >&2 <<EOF
エラー: Release .app が見つかりません:
  $SRC

次のいずれかを試してください:
  npm run install:applications -- --build
  npm run install:applications -- --src /path/to/CozyBrewApp.app

Xcode から Release ビルドした場合は、Products の CozyBrewApp.app を --src で指定するか、
--build で本リポジトリの build/DerivedData にビルドしてください。
EOF
  exit 1
fi

if [[ "$DO_INSTALL" != true ]]; then
  echo "OK: Release 成果物: $SRC"
  exit 0
fi

if [[ "$FORCE" != true ]]; then
  if pgrep -xq CozyBrewApp 2>/dev/null; then
    echo "エラー: CozyBrewApp が実行中です。終了するか --force を付けて再実行してください。" >&2
    exit 1
  fi
fi

echo "== /Applications へ複製 =="
echo "  from: $SRC"
echo "  to:   $DEST"
rm -rf "$DEST"
ditto "$SRC" "$DEST"

echo "OK: $DEST にインストールしました。"