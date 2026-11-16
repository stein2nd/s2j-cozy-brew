#!/usr/bin/env python3
"""Append cross-doc heading tags (`{@<doc>:s...}`) to Markdown ATX headings.

Skips the first ATX heading in each file (document title). Does not tag inside fenced code blocks.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

# s2j-source-list と同型: `{@spec:s3-1}`（ファイル名 stem の小文字 + 節番号）
HEADING_TAG_RE = re.compile(r"\s+`\{@([^:]+):([^}]+)\}`\s*$")
LEGACY_TAG_RE = re.compile(r"\s+`tag:s2j\.[^`]+`\s*$")
HEADING_RE = re.compile(r"^(#{1,6})\s+(.+)$")
NUM_PREFIX_RE = re.compile(r"^(\d+(?:\.\d+)*)\.?\s*")
VERSION_HEADING_RE = re.compile(r"^(\d+\.\d+\.\d+)\s*-\s*\d{4}-\d{2}-\d{2}$")
EN_WORDS_RE = re.compile(r"[A-Za-z][A-Za-z0-9_-]*")
MANUAL_SUFFIXES = frozenset({"heading-tags", "heading-tags-anchors", "quick-ref"})

TARGETS = [
    "docs/architecture.md",
    "docs/brew_integration_spec.md",
    "docs/dependency_updates.md",
    "docs/design_spec.md",
    "docs/models_spec.md",
    "docs/overview.md",
    "docs/security_spec.md",
    "docs/SPEC_STRUCTURE.md",
    "docs/SPEC.md",
    "docs/specs.md",
    "docs/ux_flows_spec.md",
]


def doc_id_for(path: Path) -> str:
    """拡張子を除いたファイル名（小文字）。"""
    stem = path.stem.lower()
    if path.parent.name == "docs_mod":
        return f"docs_mod_{stem}"
    return stem


def strip_tags(title: str) -> str:
    title = HEADING_TAG_RE.sub("", title)
    title = LEGACY_TAG_RE.sub("", title)
    return title.strip()


def suffix_from_title(title: str, seq: int, level: int) -> str:
    title = strip_tags(title)
    m = NUM_PREFIX_RE.match(title)
    if m:
        return "s" + m.group(1).replace(".", "-")

    vm = VERSION_HEADING_RE.match(title.strip())
    if vm:
        return "s" + vm.group(1).replace(".", "-")

    lower = title.lower().strip()
    if lower == "unreleased":
        return "s-unreleased"
    if lower in {"changed", "fixed", "added", "removed"}:
        return f"s-{lower}"

    words = EN_WORDS_RE.findall(title)
    if words and len(words) <= 4:
        slug = "-".join(w.lower() for w in words[:5])
        slug = re.sub(r"[^a-z0-9-]", "", slug)
        if slug:
            return f"s-{slug[:44]}"

    return f"s-h{seq:03d}"


def parse_existing_tag(title: str) -> tuple[str, str] | None:
    m = HEADING_TAG_RE.search(title)
    if not m:
        return None
    return m.group(1), m.group(2)


def process_file(path: Path, root: Path) -> int:
    doc_id = doc_id_for(path)
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines(keepends=True)
    out: list[str] = []
    in_fence = False
    fence_char = ""
    used_suffixes: set[str] = set()
    heading_seq = 0
    changed = 0
    first_heading_in_file = True

    for line in lines:
        stripped = line.rstrip("\n\r")
        fence = stripped.strip()
        if fence.startswith("```"):
            if not in_fence:
                in_fence = True
                fence_char = fence[:3]
            elif fence.startswith(fence_char):
                in_fence = False
                fence_char = ""
            out.append(line)
            continue

        if in_fence:
            out.append(line)
            continue

        hm = HEADING_RE.match(stripped)
        if not hm:
            out.append(line)
            continue

        hashes, title = hm.group(1), hm.group(2)
        level = len(hashes)
        existing = parse_existing_tag(title)
        title = strip_tags(title)

        if first_heading_in_file:
            first_heading_in_file = False
            new_line = f"{hashes} {title}\n"
            if new_line != line:
                changed += 1
            out.append(new_line)
            continue

        heading_seq += 1

        suffix: str
        tag_doc = doc_id
        if existing:
            tag_doc, cand_suffix = existing
            if tag_doc == doc_id and cand_suffix in MANUAL_SUFFIXES:
                suffix = cand_suffix
            else:
                suffix = suffix_from_title(title, heading_seq, level)
        else:
            suffix = suffix_from_title(title, heading_seq, level)

        base_suffix = suffix
        key = f"{tag_doc}:{suffix}"
        n = 2
        while key in used_suffixes:
            suffix = f"{base_suffix}-{n}"
            key = f"{tag_doc}:{suffix}"
            n += 1
        used_suffixes.add(key)

        marker = f"`{{@{tag_doc}:{suffix}}}`"
        new_line = f"{hashes} {title} {marker}\n"
        if new_line != line:
            changed += 1
        out.append(new_line)

    path.write_text("".join(out), encoding="utf-8")
    return changed


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    total = 0
    for rel in TARGETS:
        path = root / rel
        if not path.is_file():
            print(f"skip (missing): {rel}", file=sys.stderr)
            continue
        n = process_file(path, root)
        total += n
        print(f"{rel}: {n} headings tagged")
    print(f"total: {total}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())