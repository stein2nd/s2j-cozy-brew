#!/usr/bin/env bash
# SPM 依存の確認・要件更新・入れ直し (npm: ncu / ncu -u / npm install に相当)
#
# 使用方法:
#   ./scripts/swift-deps.sh check    # 更新があるか確認 (ncu)
#   ./scripts/swift-deps.sh update   # Package.swift の from: を最新 tag に上げてから入れ直し (ncu -u + install)
#   ./scripts/swift-deps.sh install  # クリーンに解決・取得 (npm install)
#
# npm スクリプト:
#   npm run swift:ncu
#   npm run swift:ncu:update
#   npm run swift:install

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PACKAGE_SWIFT="$ROOT/Package.swift"
PACKAGE_RESOLVED="$ROOT/Package.resolved"
XCODE_RESOLVED="$ROOT/CozyBrew.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"

latest_semver_tag() {
  local url="$1"
  git ls-remote --tags "$url" 2>/dev/null \
    | awk '{print $2}' \
    | sed 's|refs/tags/||' \
    | grep -Ev '\^{}$' \
    | grep -E '^[0-9]+\.[0-9]+\.[0-9]+' \
    | sort -V \
    | tail -1
}

remote_branch_revision() {
  local url="$1"
  local branch="$2"
  git ls-remote "$url" "refs/heads/$branch" 2>/dev/null | awk '{print $1}'
}

sync_xcode_resolved() {
  if [[ -f "$PACKAGE_RESOLVED" && -f "$XCODE_RESOLVED" ]]; then
    cp "$PACKAGE_RESOLVED" "$XCODE_RESOLVED"
  fi
}

cmd_check() {
  local outdated=0

  if [[ ! -f "$PACKAGE_RESOLVED" ]]; then
    echo "Package.resolved がありません。npm install 相当: ./scripts/swift-deps.sh install"
    exit 1
  fi

  python3 - "$PACKAGE_SWIFT" "$PACKAGE_RESOLVED" <<'PY'
import json
import re
import subprocess
import sys
from pathlib import Path

package_swift = Path(sys.argv[1]).read_text()
resolved = json.loads(Path(sys.argv[2]).read_text())
pins = {p["identity"]: p for p in resolved.get("pins", [])}

def remote_main(url: str) -> str:
    out = subprocess.check_output(
        ["git", "ls-remote", url, "refs/heads/main"],
        text=True,
        stderr=subprocess.DEVNULL,
    ).strip()
    return out.split()[0] if out else ""

def latest_tag(url: str) -> str:
    out = subprocess.check_output(
        ["git", "ls-remote", "--tags", url],
        text=True,
        stderr=subprocess.DEVNULL,
    )
    tags = []
    for line in out.splitlines():
        parts = line.split()
        if len(parts) < 2 or parts[1].endswith("^{}"):
            continue
        tag = parts[1].removeprefix("refs/tags/")
        if re.match(r"^\d+\.\d+\.\d+", tag):
            tags.append(tag)
    if not tags:
        return ""
    tags.sort(key=lambda t: [int(x) for x in re.findall(r"\d+", t)])
    return tags[-1]

branch_deps = re.findall(
    r'\.package\(url:\s*"([^"]+)",\s*branch:\s*"([^"]+)"\)',
    package_swift,
)
from_deps = re.findall(
    r'\.package\(url:\s*"([^"]+)",\s*from:\s*"([^"]+)"\)',
    package_swift,
)

def _cmp(a: str, b: str) -> int:
    def parts(v: str):
        return [int(x) for x in re.findall(r"\d+", v)]
    pa, pb = parts(a), parts(b)
    return (pa > pb) - (pa < pb)

outdated = False

for url, branch in branch_deps:
    identity = url.rstrip("/").rsplit("/", 1)[-1].removesuffix(".git")
    pin = pins.get(identity, {})
    current = pin.get("state", {}).get("revision", "(未解決)")
    remote = remote_main(url) if branch == "main" else ""
    if not remote:
        print(f"? {identity}: remote {branch} を取得できません ({url})")
        continue
    if current != remote:
        outdated = True
        print(f"↑ {identity}: {current[:7]} → {remote[:7]} ({branch})")
        tag = latest_tag(url)
        if tag:
            print(f"  latest tag: {tag}")
    else:
        print(f"✓ {identity}: {current[:7]} ({branch} は最新)")

for url, req in from_deps:
    identity = url.rstrip("/").rsplit("/", 1)[-1].removesuffix(".git")
    tag = latest_tag(url)
    if not tag:
        print(f"? {identity}: tag を取得できません ({url})")
        continue
    if _cmp(tag, req) > 0:
        outdated = True
        print(f"↑ {identity}: Package.swift from \"{req}\" → 最新 tag \"{tag}\" に更新可能")
    else:
        print(f"✓ {identity}: from \"{req}\" (最新 tag {tag})")

sys.exit(1 if outdated else 0)
PY
}

cmd_bump_package_swift() {
  python3 - "$PACKAGE_SWIFT" <<'PY'
import re
import subprocess
import sys
from pathlib import Path

path = Path(sys.argv[1])
content = path.read_text()
original = content

def latest_tag(url: str) -> str:
    out = subprocess.check_output(["git", "ls-remote", "--tags", url], text=True)
    tags = []
    for line in out.splitlines():
        parts = line.split()
        if len(parts) < 2 or parts[1].endswith("^{}"):
            continue
        tag = parts[1].removeprefix("refs/tags/")
        if re.match(r"^\d+\.\d+\.\d+", tag):
            tags.append(tag)
    if not tags:
        return ""
    tags.sort(key=lambda t: [int(x) for x in re.findall(r"\d+", t)])
    return tags[-1]

def cmp(a: str, b: str) -> int:
    pa = [int(x) for x in re.findall(r"\d+", a)]
    pb = [int(x) for x in re.findall(r"\d+", b)]
    return (pa > pb) - (pa < pb)

pattern = re.compile(
    r'(\.package\(url:\s*")([^"]+)(",\s*from:\s*")([^"]+)("\))'
)

changed = False

def repl(m: re.Match) -> str:
    global changed
    prefix, url, mid, current, suffix = m.group(1), m.group(2), m.group(3), m.group(4), m.group(5)
    tag = latest_tag(url)
    if tag and cmp(tag, current) > 0:
        changed = True
        identity = url.rstrip("/").rsplit("/", 1)[-1].removesuffix(".git")
        print(f"Package.swift: {identity} from \"{current}\" → \"{tag}\"")
        return f"{prefix}{url}{mid}{tag}{suffix}"
    return m.group(0)

content = pattern.sub(repl, content)
if changed:
    path.write_text(content)
else:
    branch_count = len(re.findall(r'branch:\s*"', content))
    if branch_count:
        print("Package.swift: branch 指定の依存は manifest 変更不要 (main 追従)")
    else:
        print("Package.swift: from: の更新は不要")
PY
}

cmd_install() {
  echo "swift package reset"
  swift package reset
  rm -f "$PACKAGE_RESOLVED"
  echo "swift package update"
  swift package update
  sync_xcode_resolved
  echo "完了: Package.resolved を更新しました"
}

cmd_update() {
  cmd_bump_package_swift
  cmd_install
}

usage() {
  sed -n '2,12p' "$0"
}

case "${1:-}" in
  check)
    cmd_check
    ;;
  update)
    cmd_update
    ;;
  install)
    cmd_install
    ;;
  -h|--help|help|"")
    usage
    exit 0
    ;;
  *)
    echo "不明なコマンド: $1" >&2
    usage
    exit 1
    ;;
esac
