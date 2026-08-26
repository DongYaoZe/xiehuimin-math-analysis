#!/usr/bin/env python3
"""Normalize original problem lists into explicit x* problem environments.

This is intentionally narrow: only regions already identified by
build_inline_edition.py as problem groups are rewritten.  Ordinary prose lists,
theorem lists, and subpart enumerations inside a problem are left alone.

Supported conversions:
  * top-level enumerate problem lists -> one xexercise/xthought/xreferenceproblem
    per top-level item;
  * naked ``1. ... 2. ...`` problem lists -> the same explicit environments;
  * a single unlabeled x* wrapper around a whole enumerate list is removed and
    replaced by one environment per actual problem.

Run without --write for a dry audit.  The script is idempotent: already
normalized groups are reported as structured and not rewritten.
"""
from __future__ import annotations

from collections import Counter
from pathlib import Path
import argparse
import importlib.util
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
BODY_DIR = ROOT / "chapters"
BUILDER_PATH = ROOT / "scripts" / "build_inline_edition.py"


def load_builder():
    spec = importlib.util.spec_from_file_location("xie_inline_builder", BUILDER_PATH)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {BUILDER_PATH}")
    mod = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = mod
    spec.loader.exec_module(mod)
    return mod


B = load_builder()


def env_for_group(group) -> str:
    if group.kind == "思考题":
        return "xthought"
    if group.kind == "参考题" or group.qualifier:
        return "xreferenceproblem"
    return "xexercise"


def strip_outer_item(item: str) -> str:
    """Remove only the depth-1 item marker; nested items remain untouched."""
    m = re.match(r"\s*\\item(?:\s*\[[^\]]*\])?\s*", item, flags=re.S)
    if not m:
        raise ValueError("top-level enumerate unit does not start with \\item")
    return item[m.end():].strip()


def strip_raw_number(segment: str, expected: int) -> str:
    m = re.match(rf"\s*{expected}\s*[.．、]\s*", segment, flags=re.S)
    if not m:
        raise ValueError(f"raw problem does not begin with expected number {expected}")
    return segment[m.end():].strip()


def render_problem(env: str, number: int, body: str) -> str:
    body = body.strip()
    return f"\\begin{{{env}}}[{number}]\n{body}\n\\end{{{env}}}"


def enumerate_edit(text: str, group):
    block = text[group.start:group.end]
    enum = B.first_enumerate(block)
    if not enum:
        raise ValueError(f"{group.group_id}: enumerate mode but no enumerate block")
    enum_start, enum_end, spans = enum
    if len(spans) != len(group.units):
        raise ValueError(
            f"{group.group_id}: enumerate items={len(spans)} != parsed units={len(group.units)}"
        )
    env = env_for_group(group)
    rendered = []
    for unit, (_, _, item) in zip(group.units, spans):
        rendered.append(render_problem(env, unit.number, strip_outer_item(item)))
    replacement = "\n\n".join(rendered)

    # Older transcription chapters sometimes wrapped the whole list in one
    # unlabeled xexercise/xthought/xreferenceproblem.  Replacing only the inner
    # enumerate would create illegal nested same-purpose environments, so remove
    # that aggregate wrapper as well while preserving any text around the list.
    wrappers = []
    for name in B.PROBLEM_ENVS:
        wrappers.extend(B.find_env_blocks(block, name))
    containing = [w for w in wrappers if w.start <= enum_start and enum_end <= w.end and not w.label]
    if len(containing) == 1:
        w = containing[0]
        before = block[w.content_start:enum_start].strip()
        after = block[enum_end:w.content_end].strip()
        parts = [x for x in (before, replacement, after) if x]
        return group.start + w.start, group.start + w.end, "\n\n".join(parts), len(rendered), "wrapped-enumerate"

    return group.start + enum_start, group.start + enum_end, replacement, len(rendered), "enumerate"


def raw_edits(text: str, group):
    env = env_for_group(group)
    out = []
    for unit in group.units:
        segment = text[unit.start:unit.end]
        body = strip_raw_number(segment, unit.number)
        out.append((unit.start, unit.end, render_problem(env, unit.number, body) + "\n\n"))
    return out


def normalize_chapter(chapter: int, write: bool) -> tuple[Counter, list[str]]:
    path = BODY_DIR / f"ch{chapter:02d}.tex"
    text = path.read_text(encoding="utf-8")
    groups = B.extract_body_groups(chapter)
    edits: list[tuple[int, int, str]] = []
    stats = Counter()
    diagnostics: list[str] = []

    for group in groups:
        stats[f"mode:{group.mode}"] += 1
        try:
            if group.mode == "enumerate":
                a, b, repl, n, flavor = enumerate_edit(text, group)
                edits.append((a, b, repl))
                stats[f"normalized:{flavor}"] += 1
                stats["problem_units_normalized"] += n
            elif group.mode == "raw-numbered":
                rs = raw_edits(text, group)
                edits.extend(rs)
                stats["normalized:raw-numbered"] += 1
                stats["problem_units_normalized"] += len(rs)
            elif group.mode in {"environment", "environment-single"}:
                stats["already_structured"] += 1
            elif group.mode == "unparsed":
                diagnostics.append(
                    f"UNPARSED ch{chapter:02d} {group.numeric_path} {group.title!r}"
                )
            else:
                diagnostics.append(
                    f"UNSUPPORTED ch{chapter:02d} {group.numeric_path} {group.title!r} mode={group.mode}"
                )
        except Exception as exc:
            diagnostics.append(
                f"FAILED ch{chapter:02d} {group.numeric_path} {group.title!r}: {exc}"
            )

    # Assert rewrite ranges do not overlap.  This catches accidental attempts to
    # normalize both an aggregate wrapper and one of its child regions.
    ordered = sorted(edits, key=lambda x: x[0])
    for left, right in zip(ordered, ordered[1:]):
        if left[1] > right[0]:
            diagnostics.append(
                f"OVERLAP ch{chapter:02d}: {left[0]}:{left[1]} with {right[0]}:{right[1]}"
            )
    if diagnostics:
        return stats, diagnostics

    if write and edits:
        out = text
        for a, b, repl in sorted(edits, key=lambda x: x[0], reverse=True):
            out = out[:a] + repl + out[b:]
        path.write_text(out, encoding="utf-8", newline="\n")
        stats["chapters_written"] += 1
    return stats, diagnostics


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true")
    args = ap.parse_args()

    total = Counter()
    diagnostics: list[str] = []
    for ch in range(1, 27):
        stats, diags = normalize_chapter(ch, args.write)
        total.update(stats)
        diagnostics.extend(diags)
        print(
            f"ch{ch:02d}: groups={sum(v for k,v in stats.items() if k.startswith('mode:'))} "
            f"normalized={stats['problem_units_normalized']} structured={stats['already_structured']} "
            f"diag={len(diags)}"
        )
    print("summary", dict(total))
    if diagnostics:
        for d in diagnostics:
            print(d, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
