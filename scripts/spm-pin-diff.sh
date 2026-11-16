#!/usr/bin/env bash
# Package.resolved の差分から、どの SPM パッケージの pin が変わったか表示する。
# Cursor / Git の diff 補助用 (swift:ncu の「更新あり」と併用)。
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

RESOLVED=(
  "$ROOT/Package.resolved"
  "$ROOT/CozyBrew.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
)

for f in "${RESOLVED[@]}"; do
  if [[ ! -f "$f" ]]; then
    continue
  fi
  rel="${f#$ROOT/}"
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "$rel: (git 管理外のため比較できません)"
    continue
  fi
  if git diff --quiet HEAD -- "$f" 2>/dev/null && git diff --quiet -- "$f" 2>/dev/null; then
    echo "$rel: 変更なし (作業ツリー・HEAD とも同一)"
    continue
  fi
  echo "=== $rel ==="
  git diff HEAD -- "$f" 2>/dev/null | sed -n '1,120p' || git diff -- "$f" | sed -n '1,120p'
done

export ROOT
python3 - <<'PY'
import json
import os
import subprocess
import sys
from pathlib import Path

root = Path(os.environ["ROOT"])

resolved = root / "Package.resolved"
if not resolved.is_file():
    sys.exit(0)

def load_pin(path: Path) -> dict:
    data = json.loads(path.read_text())
    out = {}
    for pin in data.get("pins", []):
        ident = pin.get("identity", "")
        state = pin.get("state", {})
        kind = "version" if "version" in state else "branch" if "branch" in state else "revision"
        if "version" in state:
            val = state["version"]
        elif "branch" in state:
            val = f"{state['branch']}@{state.get('revision', '')[:12]}"
        else:
            val = state.get("revision", "")[:12]
        out[ident] = (kind, val)
    return out

def git_show(path: str) -> str | None:
    try:
        return subprocess.check_output(
            ["git", "show", f"HEAD:{path}"],
            text=True,
            stderr=subprocess.DEVNULL,
        )
    except subprocess.CalledProcessError:
        return None

head_text = git_show("Package.resolved")
if head_text is None:
    print("\n(HEAD に Package.resolved が無いため、identity 単位の要約はスキップ)")
    sys.exit(0)

import tempfile
head_path = Path(tempfile.gettempdir()) / "cozybrew-package-resolved-head.json"
head_path.write_text(head_text)
current = load_pin(resolved)
previous = load_pin(head_path)
all_ids = sorted(set(current) | set(previous))
changes = []
for ident in all_ids:
    c = current.get(ident)
    p = previous.get(ident)
    if c != p:
        changes.append((ident, p, c))
if not changes:
    print("\n要約: pin 差分なし (HEAD と現在)")
else:
    print("\n要約: 変動した identity")
    for ident, p, c in changes:
        p_s = f"{p[0]} {p[1]}" if p else "(なし)"
        c_s = f"{c[0]} {c[1]}" if c else "(削除)"
        print(f"  • {ident}: {p_s} → {c_s}")
PY