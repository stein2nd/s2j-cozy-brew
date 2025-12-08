#!/bin/bash
# ローカルでテストを実行するスクリプト (macOS専用版)
# コミット前に CI/CD と同じテストを実行して問題を早期発見
# 
# このスクリプトは macOS 専用プロジェクト用です。
# S2J CozyBrew は macOS のみをサポートしているため、iOS/iPadOS テストは含まれていません。
# 
# シェルについて:
#   - bash を使用している理由:
#     * CI/CD 環境 (GitHub Actions など) との互換性を確保
#     * Linux や他の Unix 系システムでも動作する移植性
#     * 広範な環境で利用可能な標準的なシェル
#   - macOS では zsh がデフォルトですが、このスクリプトは bash で実行されます
#   - zsh でも動作する可能性はありますが、bash での動作を保証します
# 
# 使用方法:
#   ./scripts/test-local_macOS.sh [オプション]
#   npm run test:local -- [オプション]
# 
# オプション:
#   -s, --scheme-name <name>        Xcodeスキーム名
#   --enable-xcode-project          Xcodeプロジェクト生成とテストを有効化
#   --xcode-project-name <name>     Xcodeプロジェクト名
#   --xcodegen-auto-install         xcodegenを自動インストール
#   -h, --help                      ヘルプを表示
# 
# 優先順位: 1. コマンドライン引数 > 2. 自動検出 (Package.swift から) > 3. 環境変数 > 4. デフォルト値
# 
# 環境変数でもカスタマイズ可能 (引数と自動検出が優先されます):
#   - SCHEME_NAME: Xcodeスキーム名 (デフォルト: Package.swiftから自動検出)
#   - ENABLE_XCODE_PROJECT: Xcodeプロジェクト生成とテストを有効にする場合は "true" を設定 (デフォルト: project.ymlが存在する場合に自動有効化)
#   - XCODE_PROJECT_NAME: Xcodeプロジェクト名 (デフォルト: Package.swiftから自動検出、またはパッケージ名)
#   - XCODEGEN_AUTO_INSTALL: xcodegenを自動インストールする場合は "true" を設定 (デフォルト: "false")

set -e

echo "🧪 ローカルテスト実行スクリプト (macOS専用版)"
echo "================================"

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# エラーカウント
ERROR_COUNT=0

# テスト結果を記録
test_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
    else
        echo -e "${RED}❌ $1${NC}"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi
}

# Package.swiftからパッケージ名を取得
get_package_name() {
    if [ -f "Package.swift" ]; then
        grep -E "^[[:space:]]*name:" Package.swift | head -1 | sed -E 's/.*name:[[:space:]]*"([^"]+)".*/\1/' | xargs
    else
        echo ""
    fi
}

# Package.swiftからライブラリ名 (スキーム名) を取得
get_library_name() {
    if [ -f "Package.swift" ]; then
        # .library(name: "LibraryName", ...) からライブラリ名を取得
        # 複数行にわたる可能性があるため、-A オプションで次の数行も取得
        grep -A 3 "\.library" Package.swift | grep -E "name:[[:space:]]*\"" | head -1 | sed -E 's/.*name:[[:space:]]*"([^"]+)".*/\1/' | xargs
    else
        echo ""
    fi
}

# Xcodeプロジェクト名を検出 (.xcodeprojディレクトリから)
get_xcode_project_name() {
    # 既存の.xcodeprojを検索
    local project_file=$(find . -maxdepth 2 -name "*.xcodeproj" -type d | head -1)
    if [ -n "$project_file" ]; then
        basename "$project_file" .xcodeproj
    else
        # project.ymlから検出を試行
        if [ -f "project.yml" ]; then
            # 引用符あり/なしの両方に対応
            local name_line=$(grep -E "^name:" project.yml | head -1)
            if [ -n "$name_line" ]; then
                # 引用符付きの場合: name: "project-name"
                if echo "$name_line" | grep -qE '^name:[[:space:]]*"'; then
                    echo "$name_line" | sed -E 's/^name:[[:space:]]*"([^"]+)".*/\1/' | xargs
                else
                    # 引用符なしの場合: name: project-name
                    echo "$name_line" | sed -E 's/^name:[[:space:]]*([^[:space:]]+).*/\1/' | xargs
                fi
            else
                echo ""
            fi
        else
            echo ""
        fi
    fi
}

# ヘルプを表示
show_help() {
    cat << EOF
使用方法: $0 [オプション]

オプション:
  -s, --scheme-name <name>        Xcodeスキーム名
  --enable-xcode-project          Xcodeプロジェクト生成とテストを有効化
  --xcode-project-name <name>     Xcodeプロジェクト名
  --xcodegen-auto-install         xcodegenを自動インストール
  -h, --help                      このヘルプを表示

優先順位: 1. コマンドライン引数 > 2. 自動検出 (Package.swift から) > 3. 環境変数 > 4. デフォルト値

環境変数でもカスタマイズ可能 (引数と自動検出が優先されます):
  SCHEME_NAME, ENABLE_XCODE_PROJECT, XCODE_PROJECT_NAME, XCODEGEN_AUTO_INSTALL

例:
  $0
  $0 --scheme-name CozyBrewApp
  npm run test:local
EOF
    exit 0
}

# コマンドライン引数を解析
# 引数が指定されていない場合は環境変数から取得
parse_arguments() {
    # 引数用の変数を初期化 (環境変数の値で初期化)
    ARG_SCHEME_NAME=""
    ARG_ENABLE_XCODE_PROJECT=""
    ARG_XCODE_PROJECT_NAME=""
    ARG_XCODEGEN_AUTO_INSTALL=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -s|--scheme-name)
                ARG_SCHEME_NAME="$2"
                shift 2
                ;;
            --enable-xcode-project)
                ARG_ENABLE_XCODE_PROJECT="true"
                shift
                ;;
            --xcode-project-name)
                ARG_XCODE_PROJECT_NAME="$2"
                shift 2
                ;;
            --xcodegen-auto-install)
                ARG_XCODEGEN_AUTO_INSTALL="true"
                shift
                ;;
            -h|--help)
                show_help
                ;;
            *)
                echo "不明なオプション: $1" >&2
                echo "ヘルプを表示するには: $0 --help" >&2
                exit 1
                ;;
        esac
    done
}

# 引数を解析
parse_arguments "$@"

# パッケージ名を取得
PACKAGE_NAME=$(get_package_name)
# ライブラリ名 (スキーム名) を取得 (見つからない場合はパッケージ名を使用)
LIBRARY_NAME=$(get_library_name)

# 優先順位: 1. コマンドライン引数 > 2. 自動検出 (Package.swift から) > 3. 環境変数 > 4. デフォルト値
SCHEME_NAME="${ARG_SCHEME_NAME:-${LIBRARY_NAME:-${SCHEME_NAME:-${PACKAGE_NAME}}}}"

# Xcode プロジェクト関連の設定
if [ -f "project.yml" ]; then
    # project.ymlが存在する場合、デフォルトでXcodeプロジェクト生成を有効化
    # 優先順位: 1. コマンドライン引数 > 2. 環境変数 > 3. デフォルト値 (true)
    if [ -n "$ARG_ENABLE_XCODE_PROJECT" ]; then
        ENABLE_XCODE_PROJECT="$ARG_ENABLE_XCODE_PROJECT"
    else
        ENABLE_XCODE_PROJECT="${ENABLE_XCODE_PROJECT:-true}"
    fi
    # Xcodeプロジェクト名: 優先順位: 1. コマンドライン引数 > 2. 自動検出 (get_xcode_project_name) > 3. 環境変数 > 4. パッケージ名 (デフォルト値)
    AUTO_DETECTED_PROJECT_NAME=$(get_xcode_project_name)
    XCODE_PROJECT_NAME="${ARG_XCODE_PROJECT_NAME:-${AUTO_DETECTED_PROJECT_NAME:-${XCODE_PROJECT_NAME:-${PACKAGE_NAME}}}}"
else
    # 優先順位: 1. コマンドライン引数 > 2. 環境変数 > 3. デフォルト値 (false)
    if [ -n "$ARG_ENABLE_XCODE_PROJECT" ]; then
        ENABLE_XCODE_PROJECT="$ARG_ENABLE_XCODE_PROJECT"
    else
        ENABLE_XCODE_PROJECT="${ENABLE_XCODE_PROJECT:-false}"
    fi
    # Xcode プロジェクト名: 優先順位: 1. コマンドライン引数 > 2. 環境変数 > 3. パッケージ名 (デフォルト値)
    # 注: project.yml が存在しない場合は自動検出がないため、環境変数が優先
    XCODE_PROJECT_NAME="${ARG_XCODE_PROJECT_NAME:-${XCODE_PROJECT_NAME:-${PACKAGE_NAME}}}"
fi

XCODEGEN_AUTO_INSTALL="${ARG_XCODEGEN_AUTO_INSTALL:-${XCODEGEN_AUTO_INSTALL:-false}}"

if [ -n "$PACKAGE_NAME" ]; then
    echo -e "${BLUE}📦 パッケージ名: ${PACKAGE_NAME}${NC}"
    echo -e "${BLUE}📋 スキーム名: ${SCHEME_NAME}${NC}"
    if [ "$ENABLE_XCODE_PROJECT" = "true" ]; then
        echo -e "${BLUE}📱 Xcodeプロジェクト名: ${XCODE_PROJECT_NAME}${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Package.swiftが見つかりません。Swift Package Managerプロジェクトであることを確認してください。${NC}"
fi

# 1. Swift Package テスト (macOS)
echo ""
echo -e "${BLUE}📦 Swift Package テストを実行中 (macOS) ...${NC}"

# Xcode のパスを確認して設定
if [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
    export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
fi

# xcrun のパスを確認
XCRUN_PATH_MACOS=$(which xcrun 2>/dev/null || echo "")
if [ -z "$XCRUN_PATH_MACOS" ] && [ -n "$DEVELOPER_DIR" ]; then
    XCRUN_PATH_MACOS="$DEVELOPER_DIR/usr/bin/xcrun"
fi

# macOS SDK パスを取得して明示的に macOS プラットフォームで実行
if [ -n "$XCRUN_PATH_MACOS" ] && [ -x "$XCRUN_PATH_MACOS" ]; then
    MACOS_SDK_PATH=$("$XCRUN_PATH_MACOS" --show-sdk-path --sdk macosx 2>/dev/null || echo "")
else
    MACOS_SDK_PATH=$(xcrun --show-sdk-path --sdk macosx 2>/dev/null || echo "")
fi
SWIFT_TEST_SUCCESS=false
SWIFT_TEST_ERROR=""

# iOS 関連の環境変数を一時的にクリア (macOS テストを確実に実行するため)
OLD_SWIFT_PLATFORM="$SWIFT_PLATFORM"
OLD_SDKROOT="$SDKROOT"
unset SWIFT_PLATFORM
export SDKROOT=""

if [ -n "$MACOS_SDK_PATH" ]; then
    # macOS SDK を明示的に設定
    export SDKROOT="$MACOS_SDK_PATH"

    # macOS SDK が利用可能な場合、明示的に macOS プラットフォームで実行
    # まず arm64 を試行、次に x86_64、最後にデフォルト
    echo "macOS SDK を使用してテストを実行中: $MACOS_SDK_PATH"
    SWIFT_TEST_OUTPUT=$(swift test --enable-code-coverage \
        -Xswiftc -sdk \
        -Xswiftc "$MACOS_SDK_PATH" \
        -Xswiftc -target \
        -Xswiftc "arm64-apple-macosx12.0" 2>&1)
    SWIFT_TEST_EXIT_CODE=$?
    if [ $SWIFT_TEST_EXIT_CODE -eq 0 ]; then
        SWIFT_TEST_SUCCESS=true
    else
        SWIFT_TEST_ERROR="$SWIFT_TEST_OUTPUT"
        # x86_64 を試行
        SWIFT_TEST_OUTPUT=$(swift test --enable-code-coverage \
            -Xswiftc -sdk \
            -Xswiftc "$MACOS_SDK_PATH" \
            -Xswiftc -target \
            -Xswiftc "x86_64-apple-macosx12.0" 2>&1)
        SWIFT_TEST_EXIT_CODE=$?
        if [ $SWIFT_TEST_EXIT_CODE -eq 0 ]; then
            SWIFT_TEST_SUCCESS=true
        else
            SWIFT_TEST_ERROR="$SWIFT_TEST_OUTPUT"
            # デフォルトを試行
            SWIFT_TEST_OUTPUT=$(swift test --enable-code-coverage 2>&1)
            SWIFT_TEST_EXIT_CODE=$?
            if [ $SWIFT_TEST_EXIT_CODE -eq 0 ]; then
                SWIFT_TEST_SUCCESS=true
            else
                SWIFT_TEST_ERROR="$SWIFT_TEST_OUTPUT"
            fi
        fi
    fi
else
    # macOS SDK が利用できない場合、通常の swift test を実行
    echo "macOS SDK が見つかりません。デフォルト設定でテストを実行中..."
    SWIFT_TEST_OUTPUT=$(swift test --enable-code-coverage 2>&1)
    SWIFT_TEST_EXIT_CODE=$?
    if [ $SWIFT_TEST_EXIT_CODE -eq 0 ]; then
        SWIFT_TEST_SUCCESS=true
    else
        SWIFT_TEST_ERROR="$SWIFT_TEST_OUTPUT"
    fi
fi

# 環境変数を復元
if [ -n "$OLD_SWIFT_PLATFORM" ]; then
    export SWIFT_PLATFORM="$OLD_SWIFT_PLATFORM"
fi
if [ -n "$OLD_SDKROOT" ]; then
    export SDKROOT="$OLD_SDKROOT"
fi

if [ "$SWIFT_TEST_SUCCESS" = "true" ]; then
    test_result "Swift Package テスト (macOS)"
else
    # swift test が失敗した場合、エラーメッセージを表示
    echo -e "${YELLOW}⚠️  swift test に失敗しました。${NC}"
    if [ -n "$SWIFT_TEST_ERROR" ]; then
        echo -e "${YELLOW}エラー詳細:${NC}"
        echo "$SWIFT_TEST_ERROR" | head -20
    fi

    # xcodebuild test を試行
    echo -e "${YELLOW}xcodebuild test を試行します...${NC}"
    if command -v xcodebuild &> /dev/null && [ -n "$SCHEME_NAME" ]; then
        # まず Xcode プロジェクトが存在するか確認
        if [ "$ENABLE_XCODE_PROJECT" = "true" ] && [ -d "${XCODE_PROJECT_NAME}.xcodeproj" ]; then
            # Xcode プロジェクトを使用
            XCODEBUILD_OUTPUT=$(xcodebuild test \
                -project "${XCODE_PROJECT_NAME}.xcodeproj" \
                -scheme "$SCHEME_NAME" \
                -destination 'platform=macOS' \
                -enableCodeCoverage YES \
                2>&1)
            XCODEBUILD_EXIT_CODE=$?
        else
            # Swift Package として試行
            set +e
            XCODEBUILD_OUTPUT=$(xcodebuild test \
                -package . \
                -scheme "$SCHEME_NAME" \
                -destination 'platform=macOS' \
                -enableCodeCoverage YES \
                2>&1)
            XCODEBUILD_EXIT_CODE=$?
            set -e
        fi
        if [ $XCODEBUILD_EXIT_CODE -eq 0 ]; then
            test_result "Swift Package テスト (macOS - xcodebuild)"
        else
            test_result "Swift Package テスト (macOS)"
            echo -e "${YELLOW}⚠️  xcodebuild test も失敗しました。${NC}"
            # -package オプションがサポートされていない場合のエラーメッセージを確認
            if echo "$XCODEBUILD_OUTPUT" | grep -q "invalid option.*-package"; then
                echo -e "${YELLOW}   xcodebuild -package はこの環境ではサポートされていません${NC}"
                if [ "$ENABLE_XCODE_PROJECT" = "true" ] && [ ! -d "${XCODE_PROJECT_NAME}.xcodeproj" ]; then
                    echo -e "${YELLOW}   Xcode プロジェクトを生成してください: xcodegen generate${NC}"
                fi
            else
                echo "$XCODEBUILD_OUTPUT" | grep -i "error" | head -10
            fi
            if [ -z "$MACOS_SDK_PATH" ]; then
                echo -e "${YELLOW}   macOS SDK が見つかりません。Xcode がインストールされているか確認してください。${NC}"
                echo -e "${YELLOW}   コマンドラインツールをインストール: xcode-select --install${NC}"
            fi
        fi
    else
        test_result "Swift Package テスト (macOS)"
        echo -e "${YELLOW}⚠️  xcodebuild が見つかりません。Xcode がインストールされているか確認してください。${NC}"
        if [ -z "$MACOS_SDK_PATH" ]; then
            echo -e "${YELLOW}   macOS SDK が見つかりません。${NC}"
            echo -e "${YELLOW}   コマンドラインツールをインストール: xcode-select --install${NC}"
        fi
    fi
fi

# 2. Xcodeプロジェクトの生成とテスト (macOS) - オプション
if [ "$ENABLE_XCODE_PROJECT" = "true" ]; then
    echo ""
    echo -e "${BLUE}📱 Xcodeプロジェクトの生成とテストを実行中 (macOS) ...${NC}"

    # xcodegenの確認とインストール
    if ! command -v xcodegen &> /dev/null; then
        if [ "$XCODEGEN_AUTO_INSTALL" = "true" ]; then
            echo -e "${YELLOW}⚠️  xcodegen が見つかりません。インストールを試みます...${NC}"
            if command -v brew &> /dev/null; then
                brew install xcodegen
                test_result "xcodegen インストール"
            else
                echo -e "${YELLOW}⚠️  brew が見つかりません。xcodegen を手動でインストールしてください: brew install xcodegen${NC}"
                echo -e "${YELLOW}⚠️  Xcodeプロジェクトテストをスキップします。${NC}"
                ENABLE_XCODE_PROJECT="false"
            fi
        else
            echo -e "${YELLOW}⚠️  xcodegen が見つかりません。${NC}"
            echo -e "${YELLOW}   インストールするには: brew install xcodegen${NC}"
            echo -e "${YELLOW}   または環境変数 XCODEGEN_AUTO_INSTALL=true を設定してください。${NC}"
            echo -e "${YELLOW}⚠️  Xcodeプロジェクトテストをスキップします。${NC}"
            ENABLE_XCODE_PROJECT="false"
        fi
    fi

    if [ "$ENABLE_XCODE_PROJECT" = "true" ]; then
        # project.ymlの確認
        if [ -f "project.yml" ]; then
            echo -e "${GREEN}✅ project.yml が見つかりました${NC}"

            # Xcodeプロジェクトの生成
            echo ""
            echo "Xcodeプロジェクトを生成中..."
            if xcodegen generate; then
                test_result "Xcodeプロジェクト生成"

                # 生成されたプロジェクトファイルを確認
                XCODE_PROJECT_PATH="${XCODE_PROJECT_NAME}.xcodeproj"
                if [ -d "$XCODE_PROJECT_PATH" ] || [ -f "$XCODE_PROJECT_PATH/project.pbxproj" ]; then
                    echo ""
                    echo "Xcode プロジェクトのテストを実行中 (macOS) ..."
                    # macOS 専用スキームを使用 (存在する場合)
                    MACOS_SCHEME="${SCHEME_NAME}-macOS"
                    # xcodebuild -list の出力からスキーム一覧を取得
                    AVAILABLE_SCHEMES=$(xcodebuild -project "$XCODE_PROJECT_PATH" -list 2>/dev/null | sed -n '/^[[:space:]]*Schemes:/,/^[[:space:]]*$/p' | grep -v "^[[:space:]]*Schemes:" | grep -v "^[[:space:]]*$" | sed 's/^[[:space:]]*//' || echo "")
                    if echo "$AVAILABLE_SCHEMES" | grep -q "^${MACOS_SCHEME}$"; then
                        TEST_SCHEME="$MACOS_SCHEME"
                        echo "macOS 専用スキームを使用: $TEST_SCHEME"
                    else
                        TEST_SCHEME="$SCHEME_NAME"
                    fi
                    # macOS テストのみを実行
                    if xcodebuild test \
                        -project "$XCODE_PROJECT_PATH" \
                        -scheme "$TEST_SCHEME" \
                        -destination 'platform=macOS' \
                        -enableCodeCoverage YES \
                        -quiet; then
                        test_result "Xcodeプロジェクトテスト (macOS)"
                    else
                        test_result "Xcodeプロジェクトテスト (macOS)"
                        echo -e "${YELLOW}⚠️  Xcodeプロジェクトのテストに失敗しました。${NC}"
                    fi
                else
                    echo -e "${YELLOW}⚠️  ${XCODE_PROJECT_PATH} が見つかりません。Xcodeプロジェクトの生成に失敗した可能性があります。${NC}"
                    ERROR_COUNT=$((ERROR_COUNT + 1))
                fi
            else
                test_result "Xcodeプロジェクト生成"
                echo -e "${YELLOW}⚠️  Xcodeプロジェクトの生成に失敗しました。${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  project.yml が見つかりません。Xcodeプロジェクトテストをスキップします。${NC}"
        fi
    fi
fi

# 結果サマリー
echo ""
echo "================================"
if [ $ERROR_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅ すべてのテストが成功しました！${NC}"
    exit 0
else
    echo -e "${RED}❌ $ERROR_COUNT 個のテストが失敗しました${NC}"
    echo ""
    echo "💡 ヒント:"
    echo "   - XcodeでPackage.swiftを開いてテストを実行: open Package.swift"
    if [ -n "$PACKAGE_NAME" ]; then
        echo "   - 特定のテストのみ実行: swift test --filter <TestClassName>"
    fi
    if [ "$ENABLE_XCODE_PROJECT" = "true" ] && [ -d "${XCODE_PROJECT_NAME}.xcodeproj" ]; then
        echo "   - Xcodeプロジェクトを開く: open ${XCODE_PROJECT_NAME}.xcodeproj"
    fi
    echo "   - 環境変数でカスタマイズ:"
    echo "     SCHEME_NAME=<scheme> ENABLE_XCODE_PROJECT=true XCODEGEN_AUTO_INSTALL=true \\"
    echo "     ./scripts/test-local_macOS.sh"
    exit 1
fi
