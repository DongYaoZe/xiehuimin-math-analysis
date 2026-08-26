#!/usr/bin/env python3
"""Build the unified inline-solution edition.

The source layers stay authoritative:
  chapters/chXX.tex   original transcription
  solutions/chXX.tex  reviewed solution corpus

This script parses problem groups and solution units, validates their mapping, and
writes generated inline chapters.  It deliberately refuses silent drops: every
mapped solution is recorded in a manifest and every unresolved unit is reported.

The parser is intentionally conservative and tailored to this repository's
regular LaTeX conventions rather than attempting to be a general TeX parser.
"""
from __future__ import annotations

from dataclasses import dataclass, asdict
from pathlib import Path
import argparse
import json
import re
import sys
from typing import Iterable

ROOT = Path(__file__).resolve().parents[1]
BODY_DIR = ROOT / "chapters"
SOL_DIR = ROOT / "solutions"
OUT_DIR = ROOT / "inline" / "chapters"
REPORT_DIR = ROOT / "inline"

PROBLEM_ENVS = ("xexercise", "xthought", "xreferenceproblem")
KIND_WORDS = ("思考题", "练习题", "参考题")
QUALIFIERS = ("第一组参考题", "第二组参考题")


@dataclass
class Heading:
    start: int
    end: int
    level: str
    starred: bool
    title: str
    chapter: int
    section: int
    subsection: int
    subsubsection: int

    @property
    def rank(self) -> int:
        return {"section": 1, "subsection": 2, "subsubsection": 3, "paragraph": 4}[self.level]

    @property
    def numeric_path(self) -> str:
        if self.level == "section":
            return f"{self.chapter}.{self.section}"
        if self.level in {"subsection", "paragraph"}:
            if self.subsection:
                return f"{self.chapter}.{self.section}.{self.subsection}"
            return f"{self.chapter}.{self.section}"
        if self.subsubsection:
            return f"{self.chapter}.{self.section}.{self.subsection}.{self.subsubsection}"
        return f"{self.chapter}.{self.section}.{self.subsection}"


@dataclass
class Block:
    env: str
    start: int
    end: int
    content_start: int
    content_end: int
    label: str | None
    text: str


@dataclass
class BodyUnit:
    chapter: int
    group_id: str
    group_title: str
    number: int
    sublabel: str
    start: int
    end: int
    mode: str
    text: str


@dataclass
class BodyGroup:
    chapter: int
    group_id: str
    numeric_path: str
    title: str
    kind: str
    qualifier: str
    context: str
    start: int
    end: int
    mode: str
    units: list[BodyUnit]


@dataclass
class SolutionUnit:
    chapter: int
    group_hint: str
    group_kind: str
    qualifier: str
    context: str
    number: int
    sublabel: str
    title: str
    start: int
    end: int
    body: str
    mode: str


@dataclass
class Mapping:
    chapter: int
    group_id: str
    problem: int
    solution_count: int
    solution_titles: list[str]
    method: str


def norm_ws(s: str) -> str:
    s = s.replace("　", " ").replace("§", "")
    s = s.replace("\\quad", " ").replace("\\qquad", " ")
    s = re.sub(r"\s+", " ", s)
    return s.strip()


def plain_key(s: str) -> str:
    s = norm_ws(s)
    s = re.sub(r"\\[A-Za-z@]+\*?(?:\[[^\]]*\])?", "", s)
    s = s.replace("{", "").replace("}", "")
    s = re.sub(r"[：:，,。；;（）()\[\]【】—–\-\s]+", "", s)
    return s


def get_kind(s: str) -> str:
    for q in QUALIFIERS:
        if q in s:
            return "参考题"
    for k in KIND_WORDS:
        if k in s:
            return k
    # Common short labels in reviewed solution files.
    if re.search(r"(?:^|\s)题\s*\d+", norm_ws(s)):
        return "练习题"
    return ""


def get_qualifier(s: str) -> str:
    for q in QUALIFIERS:
        if q in s:
            return q
    return ""


def numeric_prefix(s: str, chapter: int) -> str:
    s2 = norm_ws(s)
    m = re.search(rf"(?<!\d)({chapter}(?:\.\d+){{1,3}})(?!\d)", s2)
    return m.group(1) if m else ""


def problem_number_from_label(label: str, kind: str = "") -> tuple[int | None, str]:
    """Return base problem number and a trailing sublabel, if identifiable."""
    s = norm_ws(label)
    # A leading ``3. ...`` paragraph is the most reliable form.  Require the
    # punctuation to be followed by a non-digit so a source path such as
    # ``18.2.5 ...`` is never mistaken for problem 18.
    m = re.match(r"^\s*(\d+)\s*[.．、]\s*(?!\d)(.*)$", s)
    if m:
        return int(m.group(1)), ""
    m = re.match(r"^\s*(\d+)\s*$", s)
    if m:
        return int(m.group(1)), ""

    # Then accept explicit problem-word labels.  Do not include a generic
    # ``题`` alternative: it would match descriptive text such as
    # ``命题 18.2.1 ...`` and turn a referenced theorem number into a problem
    # number.
    patterns = [
        r"(?:第一组参考题|第二组参考题|课堂练习题|参考练习题|练习题|思考题|参考题)\s*[：:]?\s*(\d+)(.*)$",
        r"^题\s*[：:]?\s*(\d+)(.*)$",
        r"(?:习题讲评|例题|练习|子列性质|单元测验)\s*[：:]?\s*(\d+(?:\.\d+)?)(.*)$",
    ]
    for pat in patterns:
        m = re.search(pat, s)
        if m:
            token = m.group(1)
            # For labels such as 1.2 (example number), the first component is the problem slot.
            base = int(token.split(".")[0])
            tail = m.group(2).strip()
            # Keep only an immediate subpart marker; descriptive names are not sublabels.
            sm = re.match(r"([（(]\s*\d+\s*[)）](?:[（(]\s*[ivxIVX]+\s*[)）])?|[（(]\s*\d+\s*[)）]\s*[—-]\s*[（(]\s*\d+\s*[)）])", tail)
            return base, sm.group(1) if sm else ""
    return None, ""


def line_offsets(text: str) -> list[int]:
    offsets = [0]
    for m in re.finditer(r"\n", text):
        offsets.append(m.end())
    return offsets


def parse_headings(text: str, chapter: int) -> list[Heading]:
    """Parse structural headings with balanced title braces and counters.

    Titles may contain nested macros such as ``\\texorpdfstring{...}{...}``, so
    a flat ``[^}]`` capture is not sufficient.
    """
    out: list[Heading] = []
    sec = sub = subsub = 0
    pat = re.compile(r"(?m)^[ \t]*\\(section|subsection|subsubsection|paragraph)(\*?)\{")

    def escaped(pos: int) -> bool:
        n = 0
        j = pos - 1
        while j >= 0 and text[j] == "\\":
            n += 1
            j -= 1
        return bool(n % 2)

    for m in pat.finditer(text):
        level, star = m.groups()
        content_start = m.end()
        depth = 1
        i = content_start
        while i < len(text) and depth:
            ch = text[i]
            if ch == "{" and not escaped(i):
                depth += 1
            elif ch == "}" and not escaped(i):
                depth -= 1
                if depth == 0:
                    break
            i += 1
        if depth:
            raise ValueError(f"unbalanced heading at offset {m.start()} in chapter {chapter}")
        title = text[content_start:i]
        end = i + 1
        while end < len(text) and text[end] in " \t":
            end += 1
        starred = bool(star)
        if not starred:
            if level == "section":
                sec += 1
                sub = subsub = 0
            elif level == "subsection":
                sub += 1
                subsub = 0
            elif level == "subsubsection":
                subsub += 1
        out.append(Heading(m.start(), end, level, starred, title, chapter, sec, sub, subsub))
    return out


def heading_at(headings: list[Heading], pos: int) -> Heading | None:
    last = None
    for h in headings:
        if h.start >= pos:
            break
        last = h
    return last


def context_path(headings: list[Heading], pos: int) -> str:
    """Return human-readable current section/subsection breadcrumbs."""
    parts: list[str] = []
    for h in headings:
        if h.start >= pos:
            break
        if h.level == "section" and not h.starred:
            parts = [norm_ws(h.title)]
        elif h.level == "subsection" and not h.starred:
            if parts:
                parts = parts[:1] + [norm_ws(h.title)]
            else:
                parts = [norm_ws(h.title)]
    return " / ".join(parts)


def find_env_blocks(text: str, env: str) -> list[Block]:
    """Find non-nested blocks of one named environment.

    Repository sources do not nest an environment inside another environment of
    the same name; a lazy pattern is therefore reliable and much simpler than a
    full TeX parser.
    """
    pat = re.compile(
        rf"\\begin\{{{re.escape(env)}\}}(?:\[([^\]]*)\])?(.*?)\\end\{{{re.escape(env)}\}}",
        re.S,
    )
    out = []
    for m in pat.finditer(text):
        out.append(Block(env, m.start(), m.end(), m.start(2), m.end(2), m.group(1), m.group(2)))
    return out


def first_enumerate(text: str, offset: int = 0) -> tuple[int, int, list[tuple[int, int, str]]] | None:
    """Return the first enumerate block and its depth-1 item spans."""
    token = re.compile(r"\\begin\{enumerate\}(?:\[[^\]]*\])?|\\end\{enumerate\}|\\item\b")
    depth = 0
    begin = None
    item_starts: list[int] = []
    for m in token.finditer(text, offset):
        t = m.group(0)
        if t.startswith("\\begin"):
            depth += 1
            if depth == 1 and begin is None:
                begin = m.start()
        elif t.startswith("\\end"):
            if depth == 1 and begin is not None:
                end = m.end()
                spans = []
                for j, st in enumerate(item_starts):
                    en = item_starts[j + 1] if j + 1 < len(item_starts) else m.start()
                    spans.append((st, en, text[st:en]))
                return begin, end, spans
            depth = max(0, depth - 1)
        elif depth == 1 and begin is not None:
            item_starts.append(m.start())
    return None


def raw_numbered_spans(text: str) -> list[tuple[int, int, str, int]]:
    """Split raw top-level '1. ... 2. ...' problem lists used in later chapters."""
    ms = list(re.finditer(r"(?m)^[ \t]*(\d+)\.[ \t]+", text))
    out = []
    for i, m in enumerate(ms):
        end = ms[i + 1].start() if i + 1 < len(ms) else len(text)
        out.append((m.start(), end, text[m.start():end], int(m.group(1))))
    return out


def is_problem_heading(title: str) -> bool:
    t = norm_ws(title)
    if t in {"思考题", "练习题", "参考题", "第一组参考题", "第二组参考题"}:
        return True
    if any(t.endswith(x) for x in ("课堂练习题", "参考练习题", "单元测验")):
        return True
    # Numbered lesson-review headings can hold original problems.
    if re.match(r"^[一二三四五六七八九十]+、(?:课堂练习题|单元测验)", t):
        return True
    return False


def candidate_body_heading_groups(text: str, chapter: int) -> list[tuple[Heading, int]]:
    hs = parse_headings(text, chapter)
    candidates: list[Heading] = [h for h in hs if is_problem_heading(h.title)]
    out: list[tuple[Heading, int]] = []
    for h in candidates:
        # Generic 参考题 heading is only a parent when it immediately contains
        # 第一组/第二组参考题 child headings.
        if norm_ws(h.title) == "参考题":
            child = next((c for c in candidates if c.start > h.start), None)
            if child and child.rank > h.rank and child.start < next_structural_end(hs, h, len(text)) and get_qualifier(child.title):
                continue
        end = next_structural_end(hs, h, len(text))
        # A deeper candidate child starts a separate group even though ordinary
        # non-problem paragraphs/subheadings do not.
        for c in candidates:
            if c.start > h.start and c.start < end and c.rank > h.rank:
                end = c.start
                break
        out.append((h, end))
    return out


def next_structural_end(headings: list[Heading], h: Heading, default: int) -> int:
    for h2 in headings:
        if h2.start <= h.start:
            continue
        if h2.rank <= h.rank:
            return h2.start
    return default


def body_group_id(ch: int, path: str, title: str, context: str, serial: int) -> str:
    q = get_qualifier(title)
    k = get_kind(title)
    descriptor = q or k or norm_ws(title)
    return f"{path}|{descriptor}|{serial}"


def extract_body_groups(chapter: int) -> list[BodyGroup]:
    path = BODY_DIR / f"ch{chapter:02d}.tex"
    text = path.read_text(encoding="utf-8")
    hs = parse_headings(text, chapter)
    raw_groups: list[tuple[int, int, str, str, str, str]] = []
    # start, end, numeric_path, title, context, source mode
    for h, end in candidate_body_heading_groups(text, chapter):
        raw_groups.append((h.end, end, h.numeric_path, h.title, context_path(hs, h.start), "heading"))

    # Standalone xthought blocks are original problem groups even when the source
    # book did not typeset a separate "思考题" subsection heading.
    heading_ranges = [(s, e) for s, e, *_ in raw_groups]
    standalone_thought_groups: list[tuple[int, int, str, str, str, str]] = []
    for b in find_env_blocks(text, "xthought"):
        if any(s <= b.start < e for s, e in heading_ranges):
            continue
        h = heading_at(hs, b.start)
        if not h:
            prefix = f"{chapter}.0"
        else:
            # Match by chapter.section prefix; the solution heading carries the
            # original printed subsubsection number when TeX source omitted it.
            prefix = f"{chapter}.{h.section}"
        # Keep the whole existing xthought wrapper.  Consecutive standalone
        # xthought blocks with only whitespace between them are one logical
        # group; the structural normalizer deliberately emits this form when
        # splitting an older aggregate wrapper into one explicit environment
        # per thought question.
        ctx = context_path(hs, b.start)
        if standalone_thought_groups:
            ps, pe, pp, pt, pc, pm = standalone_thought_groups[-1]
            if pp == prefix and pc == ctx and not text[pe:b.start].strip():
                standalone_thought_groups[-1] = (ps, b.end, pp, pt, pc, pm)
                continue
        standalone_thought_groups.append((b.start, b.end, prefix, "思考题", ctx, "xthought"))

    raw_groups.extend(standalone_thought_groups)

    raw_groups.sort(key=lambda x: x[0])
    groups: list[BodyGroup] = []
    serials: dict[tuple[str, str], int] = {}
    for start, end, numpath, title, ctx, source_mode in raw_groups:
        block = text[start:end]
        kind = get_kind(title)
        qual = get_qualifier(title)
        key = (numpath, qual or kind or norm_ws(title))
        serials[key] = serials.get(key, 0) + 1
        gid = body_group_id(chapter, numpath, title, ctx, serials[key])
        units, mode = extract_body_units(chapter, gid, title, block, start)
        groups.append(BodyGroup(chapter, gid, numpath, title, kind, qual, ctx, start, end, mode, units))
    return groups


def extract_body_units(chapter: int, gid: str, title: str, block: str, base: int) -> tuple[list[BodyUnit], str]:
    envs: list[Block] = []
    for env in PROBLEM_ENVS:
        envs += find_env_blocks(block, env)
    envs.sort(key=lambda b: b.start)

    # Multiple explicit problem environments are authoritative.  A single
    # unlabeled environment is commonly only a wrapper around a raw enumerate.
    explicit_authoritative = len(envs) >= 2 or (len(envs) == 1 and envs[0].label)
    if explicit_authoritative:
        units = []
        for idx, b in enumerate(envs, 1):
            num, sub = problem_number_from_label(b.label or "")
            num = num or idx
            units.append(BodyUnit(chapter, gid, title, num, sub, base + b.start, base + b.end, b.env, b.text))
        return units, "environment"

    # Some later chapters (notably ch24) print top-level problems as naked
    # ``1. ... 2. ...`` paragraphs while individual problems contain nested
    # enumerate environments for their subparts.  Prefer the naked top-level
    # numbering when it begins before the first enumerate; otherwise the inner
    # subparts would be mistaken for separate exercises.
    raw = raw_numbered_spans(block)
    enum = first_enumerate(block)
    if len(raw) >= 2 and (enum is None or raw[0][0] < enum[0]):
        units = [BodyUnit(chapter, gid, title, n, "", base + st, base + en, "raw-numbered", txt) for st, en, txt, n in raw]
        return units, "raw-numbered"

    if enum and len(enum[2]) >= 1:
        units = []
        for idx, (st, en, txt) in enumerate(enum[2], 1):
            units.append(BodyUnit(chapter, gid, title, idx, "", base + st, base + en, "enumerate", txt))
        return units, "enumerate"

    if raw:
        units = [BodyUnit(chapter, gid, title, n, "", base + st, base + en, "raw-numbered", txt) for st, en, txt, n in raw]
        return units, "raw-numbered"

    if len(envs) == 1:
        b = envs[0]
        return [BodyUnit(chapter, gid, title, 1, "", base + b.start, base + b.end, b.env, b.text)], "environment-single"

    return [], "unparsed"


def solution_heading_events(text: str, chapter: int) -> list[Heading]:
    return parse_headings(text, chapter)


def solution_anchor_state(headings: list[Heading], pos: int, chapter: int) -> tuple[str, str, str, str]:
    """Return numeric path, kind, qualifier, context at a solution-unit position."""
    path = kind = qual = ""
    context_parts: list[str] = []
    for h in headings:
        if h.start >= pos:
            break
        t = norm_ws(h.title)
        # Paragraphs are commonly individual solution labels (e.g.
        # ``3. 命题 18.2.1 中...``), not group anchors.  Let their text be
        # parsed later as the unit label, but never allow referenced theorem or
        # example numbers inside them to replace the structural group state.
        if h.level != "paragraph":
            np = numeric_prefix(t, chapter)
            hk = get_kind(t)
            hq = get_qualifier(t)
            if np and re.match(rf"^{chapter}(?:\.\d+){{1,3}}(?:\b|\s)", t):
                # Keep numeric context only when the printed path starts the
                # heading.  Descriptive child headings may mention theorem or
                # example numbers without opening a new solution group.
                path = np
            if hk:
                kind = hk
            if hq:
                qual = hq
                kind = "参考题"
            elif hk and hk != "参考题":
                qual = ""
        if h.level == "section":
            context_parts = [t]
        elif h.level == "subsection":
            context_parts = context_parts[:1] + [t]
        elif h.level == "subsubsection":
            context_parts = context_parts[:2] + [t]
    return path, kind, qual, " / ".join(context_parts)


def parse_group_from_unit_label(label: str, chapter: int, inherited: tuple[str, str, str, str]) -> tuple[str, str, str, str]:
    ipath, ikind, iqual, ictx = inherited
    t = norm_ws(label)
    p, k, q = ipath, ikind, iqual

    # Structural solution headings are authoritative.  A unit label may
    # override them only when it *starts* with an explicit source-group label,
    # e.g. ``18.2.5 练习题 3``.  References inside a descriptive title such as
    # ``3. 命题 18.2.1 中...`` must not change the inherited 18.2.5 group.
    explicit = re.match(
        rf"^(?:§\s*)?({chapter}(?:\.\d+){{1,3}})\s*(第一组参考题|第二组参考题|思考题|练习题|参考题)\b",
        t,
    )
    if explicit:
        p = explicit.group(1)
        word = explicit.group(2)
        if word in QUALIFIERS:
            q = word
            k = "参考题"
        else:
            k = word
            if word != "参考题":
                q = ""
    else:
        # A leading qualifier/problem word without a numeric path can refine
        # the kind while retaining the inherited path.
        lead = re.match(r"^(第一组参考题|第二组参考题|思考题|练习题|参考题)\b", t)
        if lead:
            word = lead.group(1)
            if word in QUALIFIERS:
                q = word
                k = "参考题"
            else:
                k = word
                if word != "参考题":
                    q = ""
    return p, k, q, ictx


def nearest_preceding_paragraph(text: str, pos: int, floor: int) -> tuple[str, int] | None:
    matches = list(re.finditer(r"(?m)^[ \t]*\\paragraph\{([^\n}]*)\}[ \t]*$", text[floor:pos]))
    if not matches:
        return None
    m = matches[-1]
    return m.group(1), floor + m.start()


def extract_xsolution_units(chapter: int, text: str, headings: list[Heading]) -> list[SolutionUnit]:
    xsols = find_env_blocks(text, "xsolution")
    probs: list[Block] = []
    for e in PROBLEM_ENVS:
        probs += find_env_blocks(text, e)
    probs.sort(key=lambda b: b.end)
    out: list[SolutionUnit] = []
    prev_end = 0
    ordinal_by_group: dict[tuple[str, str, str], int] = {}
    for xb in xsols:
        inherited = solution_anchor_state(headings, xb.start, chapter)
        # A repeated problem env directly before the solution has the strongest label.
        preceding = None
        for pb in probs:
            if pb.end <= xb.start and pb.end >= prev_end:
                gap = text[pb.end:xb.start]
                if len(gap.strip()) <= 2:
                    preceding = pb
        label = ""
        title = ""
        mode = "xsolution"
        if preceding and preceding.label:
            label = preceding.label
            title = preceding.label
            mode = f"{preceding.env}+xsolution"
        else:
            para = nearest_preceding_paragraph(text, xb.start, prev_end)
            if para:
                label, _ = para
                title = label
                mode = "paragraph+xsolution"
        gpath, gkind, gqual, ctx = parse_group_from_unit_label(label, chapter, inherited)
        num, sub = problem_number_from_label(label, gkind)
        gkey = (gpath, gkind, gqual)
        if num is None:
            ordinal_by_group[gkey] = ordinal_by_group.get(gkey, 0) + 1
            num = ordinal_by_group[gkey]
        else:
            ordinal_by_group[gkey] = max(ordinal_by_group.get(gkey, 0), num)
        out.append(SolutionUnit(chapter, gpath, gkind, gqual, ctx, num, sub, title, xb.start, xb.end, xb.text.strip(), mode))
        prev_end = xb.end
    return out


def heading_is_solution_group_anchor(h: Heading, chapter: int) -> bool:
    t = norm_ws(h.title)
    # A group anchor must *begin* with its source path.  Descriptive child
    # headings may mention theorem/example numbers later in the title (e.g.
    # ``参考题 4：命题 19.3.1--19.3.4``); those references are not anchors.
    if not re.match(rf"^(?:§\s*)?{chapter}(?:\.\d+){{1,3}}\b", t):
        return False
    return bool(get_kind(t) or re.search(rf"^{chapter}\.\d+\b", t))


def extract_raw_solution_units(chapter: int, text: str, headings: list[Heading], occupied: list[tuple[int, int]]) -> list[SolutionUnit]:
    """Extract non-xsolution review formats (ch09, ch12, ch19, ch26)."""
    def is_occupied(a: int, b: int) -> bool:
        return any(not (b <= x or a >= y) for x, y in occupied)

    out: list[SolutionUnit] = []
    anchors = [h for h in headings if heading_is_solution_group_anchor(h, chapter)]
    for ai, a in enumerate(anchors):
        start = a.end
        end = anchors[ai + 1].start if ai + 1 < len(anchors) else len(text)
        block = text[start:end]
        if is_occupied(start, end):
            # xsolution-based chapters are handled by the primary extractor;
            # raw material between those solutions is not a separate answer.
            continue
        inherited = solution_anchor_state(headings, start, chapter)
        gpath, gkind, gqual, ctx = inherited

        # Child problem headings (ch19/ch26) take priority over paragraphs/enumerates.
        child_pat = re.compile(r"(?m)^[ \t]*\\(?:subsection|subsubsection)\*\{([^\n}]*)\}[ \t]*$")
        cms = list(child_pat.finditer(block))
        child_units = []
        for j, m in enumerate(cms):
            label = m.group(1)
            n, sub = problem_number_from_label(label, gkind)
            if n is None:
                continue
            cend = cms[j + 1].start() if j + 1 < len(cms) else len(block)
            body = block[m.end():cend].strip()
            if body:
                child_units.append(SolutionUnit(chapter, gpath, gkind, gqual, ctx, n, sub, label, start + m.start(), start + cend, body, "subheading-raw"))
        if child_units:
            out.extend(child_units)
            continue

        pms = list(re.finditer(r"(?m)^[ \t]*\\paragraph\{([^\n}]*)\}[ \t]*$", block))
        paragraph_units = []
        for j, m in enumerate(pms):
            label = m.group(1)
            n, sub = problem_number_from_label(label, gkind)
            if n is None:
                continue
            pend = pms[j + 1].start() if j + 1 < len(pms) else len(block)
            body = block[m.end():pend].strip()
            if body:
                paragraph_units.append(SolutionUnit(chapter, gpath, gkind, gqual, ctx, n, sub, label, start + m.start(), start + pend, body, "paragraph-raw"))
        if paragraph_units:
            out.extend(paragraph_units)
            continue

        enum = first_enumerate(block)
        if enum and enum[2]:
            for j, (st, en, item) in enumerate(enum[2], 1):
                # Keep the whole reviewed item as a safe fallback.  During merge,
                # an exact normalized problem prefix is removed when possible.
                body = re.sub(r"^\\item\b", "", item, count=1).strip()
                out.append(SolutionUnit(chapter, gpath, gkind, gqual, ctx, j, "", f"{gkind} {j}", start + st, start + en, body, "enumerate-raw"))
    return out


def extract_solution_units(chapter: int) -> list[SolutionUnit]:
    p = SOL_DIR / f"ch{chapter:02d}.tex"
    text = p.read_text(encoding="utf-8")
    hs = solution_heading_events(text, chapter)
    primary = extract_xsolution_units(chapter, text, hs)
    occupied = [(u.start, u.end) for u in primary]
    raw = extract_raw_solution_units(chapter, text, hs, occupied)
    all_units = primary + raw
    all_units.sort(key=lambda u: u.start)
    return all_units


def group_solution_units(units: list[SolutionUnit]) -> dict[tuple[str, str, str], list[SolutionUnit]]:
    d: dict[tuple[str, str, str], list[SolutionUnit]] = {}
    for u in units:
        d.setdefault((u.group_hint, u.group_kind, u.qualifier), []).append(u)
    return d


def body_group_match_score(g: BodyGroup, skey: tuple[str, str, str]) -> int:
    spath, skind, squal = skey
    score = 0
    if g.kind and skind and g.kind == skind:
        score += 20
    elif g.kind and skind:
        return -1000
    if g.qualifier or squal:
        if g.qualifier == squal:
            score += 25
        else:
            return -1000
    if spath and g.numeric_path:
        if spath == g.numeric_path:
            score += 100
        elif g.numeric_path.startswith(spath + ".") or spath.startswith(g.numeric_path + "."):
            score += 50
        elif ".".join(spath.split(".")[:2]) == ".".join(g.numeric_path.split(".")[:2]):
            score += 10
    return score


def match_solution_groups(body_groups: list[BodyGroup], sol_units: list[SolutionUnit]) -> tuple[dict[str, list[SolutionUnit]], list[SolutionUnit], list[str]]:
    sg = group_solution_units(sol_units)
    assignments: dict[str, list[SolutionUnit]] = {g.group_id: [] for g in body_groups}
    diagnostics: list[str] = []
    used_keys: set[tuple[str, str, str]] = set()

    # First pass: strong numeric/kind matches.
    for skey, units in sg.items():
        candidates = sorted(((body_group_match_score(g, skey), g) for g in body_groups), key=lambda x: x[0], reverse=True)
        if candidates and candidates[0][0] >= 70 and (len(candidates) == 1 or candidates[0][0] > candidates[1][0]):
            assignments[candidates[0][1].group_id].extend(units)
            used_keys.add(skey)

    # Second pass: remaining groups in reading order, kind/qualifier + context/prefix.
    remaining_skeys = [k for k in sg if k not in used_keys]
    remaining_groups = [g for g in body_groups if not assignments[g.group_id]]
    for skey in list(remaining_skeys):
        units = sg[skey]
        scores = []
        for g in remaining_groups:
            sc = body_group_match_score(g, skey)
            if sc < 0:
                continue
            # Context title overlap helps lesson-group mappings.
            sample_ctx = plain_key(units[0].context)
            gctx = plain_key(g.context + " " + g.title)
            if sample_ctx and gctx:
                common = sum(1 for token in re.findall(r"[A-Za-z]+|[\u4e00-\u9fff]{2,}", units[0].context) if token and token in g.context)
                sc += min(common, 10)
            scores.append((sc, g))
        scores.sort(key=lambda x: x[0], reverse=True)
        if scores and scores[0][0] >= 20 and (len(scores) == 1 or scores[0][0] > scores[1][0]):
            assignments[scores[0][1].group_id].extend(units)
            remaining_groups.remove(scores[0][1])
            used_keys.add(skey)

    # Explicit title/context fallback for lesson paragraphs: infer from solution-unit titles.
    for skey in [k for k in sg if k not in used_keys]:
        units = sg[skey]
        sample = plain_key(" ".join(u.title for u in units[:2]))
        best: tuple[int, BodyGroup] | None = None
        for g in remaining_groups:
            gk = plain_key(g.context + g.title)
            score = 0
            for marker in ("第一次习题课", "第二次习题课", "第三次习题课", "第四次习题课", "课堂练习题", "单元测验"):
                if plain_key(marker) in sample and plain_key(marker) in gk:
                    score += 20
            if g.kind and any(g.kind in u.title for u in units[:3]):
                score += 10
            if best is None or score > best[0]:
                best = (score, g)
        if best and best[0] >= 20:
            assignments[best[1].group_id].extend(units)
            remaining_groups.remove(best[1])
            used_keys.add(skey)

    # Some standalone one-line problem environments occur immediately after a
    # numbered thought/exercise group, while the reviewed solution file appends
    # their answers as extra numbered units of that preceding sibling group.
    # Rehome those extras only when the evidence is exact: within one printed
    # chapter.section prefix, the number of unassigned standalone groups must
    # equal the number of solution numbers that are absent from the sibling's
    # body numbering.  This covers the three chapter-4 thought questions without
    # fuzzy text matching or chapter-specific hard-coding.
    by_prefix: dict[tuple[str, str, str], list[BodyGroup]] = {}
    for g in body_groups:
        if assignments[g.group_id] or len(g.units) != 1 or g.mode != "environment-single":
            continue
        prefix = ".".join(g.numeric_path.split(".")[:2])
        by_prefix.setdefault((prefix, g.kind, g.qualifier), []).append(g)

    for (prefix, kind, qual), singles in by_prefix.items():
        donor_candidates: list[tuple[BodyGroup, list[SolutionUnit]]] = []
        for donor in body_groups:
            if donor.kind != kind or donor.qualifier != qual:
                continue
            if not donor.numeric_path.startswith(prefix + "."):
                continue
            assigned = assignments[donor.group_id]
            if not assigned or not donor.units:
                continue
            body_numbers = {u.number for u in donor.units}
            extras = [u for u in assigned if u.number not in body_numbers]
            if extras:
                donor_candidates.append((donor, extras))
        total_extras = sum(len(extras) for _, extras in donor_candidates)
        if total_extras != len(singles):
            continue
        ordered_extras = sorted(
            [(u, donor) for donor, extras in donor_candidates for u in extras],
            key=lambda x: (x[0].start, x[0].number),
        )
        for single, (src, donor) in zip(sorted(singles, key=lambda g: g.start), ordered_extras):
            assignments[donor.group_id] = [u for u in assignments[donor.group_id] if u is not src]
            assignments[single.group_id] = [
                SolutionUnit(
                    src.chapter, src.group_hint, src.group_kind, src.qualifier, src.context,
                    1, src.sublabel, src.title, src.start, src.end, src.body,
                    src.mode + "+standalone-rehome",
                )
            ]

    unmatched = [u for k, us in sg.items() if k not in used_keys for u in us]
    for g in body_groups:
        if not assignments[g.group_id] and g.units:
            diagnostics.append(f"NO SOLUTION GROUP: ch{g.chapter:02d} {g.numeric_path} {g.title!r} units={len(g.units)} mode={g.mode}")
    return assignments, unmatched, diagnostics


def base_number_groups(units: list[SolutionUnit]) -> dict[int, list[SolutionUnit]]:
    d: dict[int, list[SolutionUnit]] = {}
    for u in units:
        d.setdefault(u.number, []).append(u)
    return d


def split_exact_aggregate_solution(group: BodyGroup, units: list[SolutionUnit]) -> list[SolutionUnit]:
    """Expand one aggregate reviewed solution into per-problem chunks safely.

    Some early solution files deliberately use one ``xsolution`` whose body is
    a top-level enumerate answering an entire problem group (notably ch01
    section 1.4).  Split only when there is exactly one reviewed unit and the
    enumerate item count exactly equals the number of original problems.  Any
    prose before/after the enumerate is preserved on the first/last chunk.
    """
    if len(group.units) <= 1 or len(units) != 1:
        return units
    src = units[0]
    enum = first_enumerate(src.body)
    if not enum or len(enum[2]) != len(group.units):
        return units
    estart, eend, items = enum
    prefix = src.body[:estart].strip()
    suffix = src.body[eend:].strip()
    expanded: list[SolutionUnit] = []
    for idx, ((_, _, item), problem) in enumerate(zip(items, group.units)):
        body = re.sub(r"^\s*\\item(?:\s*\[[^\]]*\])?\s*", "", item, count=1, flags=re.S).strip()
        if idx == 0 and prefix:
            body = prefix + "\n\n" + body
        if idx == len(items) - 1 and suffix:
            body = body + "\n\n" + suffix
        expanded.append(
            SolutionUnit(
                src.chapter,
                src.group_hint,
                src.group_kind,
                src.qualifier,
                src.context,
                problem.number,
                "",
                f"{src.title or group.title} {problem.number}",
                src.start,
                src.end,
                body,
                src.mode + "+aggregate-enumerate-split",
            )
        )
    return expanded


def normalize_problem_text(s: str) -> str:
    # Used only to remove an exact/reviewed repeated prompt prefix from raw
    # enumerate solution items.  Do not use fuzzy deletion.
    s = re.sub(r"^\\item\b", "", s.strip())
    return norm_ws(s)


def strip_exact_prompt_prefix(body_problem: str, raw_solution: str) -> str:
    """Conservatively drop a repeated prompt only when its TeX text is an exact prefix."""
    b = re.sub(r"^\\item\b", "", body_problem.strip()).strip()
    r = raw_solution.strip()
    # Exact textual prefix after whitespace normalization cannot be sliced safely,
    # so first try literal whitespace-flexible matching token by token.
    tokens = re.split(r"(\s+)", b)
    if not b or len(b) < 8:
        return r
    pattern = "".join(r"\s+" if t.isspace() else re.escape(t) for t in tokens)
    m = re.match(pattern, r, flags=re.S)
    if m:
        return r[m.end():].lstrip()
    return r


def solution_tex_for_problem(problem: BodyUnit, chunks: list[SolutionUnit]) -> str:
    pieces = []
    for u in chunks:
        body = u.body.strip()
        if u.mode == "enumerate-raw":
            body = strip_exact_prompt_prefix(problem.text, body)
        if u.sublabel:
            body = f"\\textbf{{{u.sublabel}}}\\quad\n{body}"
        pieces.append(body)
    content = "\n\n".join(pieces).strip()
    return "\n\\begin{xsolution}\n" + content + "\n\\end{xsolution}\n"


def build_chapter(chapter: int, strict: bool = True) -> tuple[str, list[Mapping], list[str]]:
    body_path = BODY_DIR / f"ch{chapter:02d}.tex"
    text = body_path.read_text(encoding="utf-8")
    groups = extract_body_groups(chapter)
    sols = extract_solution_units(chapter)
    assignments, unmatched_sol, diagnostics = match_solution_groups(groups, sols)
    insertions: list[tuple[int, str]] = []
    mappings: list[Mapping] = []

    for g in groups:
        sunits = split_exact_aggregate_solution(g, assignments.get(g.group_id, []))
        bynum = base_number_groups(sunits)
        body_nums = {u.number for u in g.units}
        for p in g.units:
            # If the source has exactly one problem but the reviewed answer was
            # intentionally split into numbered subanswers, keep every chunk
            # under that one original problem instead of discarding later parts.
            chunks = sunits if len(g.units) == 1 and len(sunits) > 1 else bynum.get(p.number, [])
            if not chunks:
                diagnostics.append(f"UNSOLVED BODY UNIT: ch{chapter:02d} {g.title!r} problem={p.number} group={g.numeric_path}")
                continue
            insertions.append((p.end, solution_tex_for_problem(p, chunks)))
            mappings.append(Mapping(chapter, g.group_id, p.number, len(chunks), [u.title for u in chunks], "number-within-group"))
        extras = [] if len(g.units) == 1 and len(sunits) > 1 else sorted(n for n in bynum if n not in body_nums)
        if extras:
            diagnostics.append(f"EXTRA SOLUTION NUMBERS: ch{chapter:02d} {g.title!r} group={g.numeric_path}: {extras}")

    if unmatched_sol:
        # Many unmatched units are intentionally supplemental worked examples; list
        # them for manual classification instead of silently discarding them.
        for u in unmatched_sol:
            diagnostics.append(f"UNMATCHED SOLUTION: ch{chapter:02d} path={u.group_hint!r} kind={u.group_kind!r} q={u.qualifier!r} n={u.number} title={u.title!r} mode={u.mode}")

    # Insert from the end so original offsets remain valid.
    out = text
    for pos, add in sorted(insertions, key=lambda x: x[0], reverse=True):
        out = out[:pos] + add + out[pos:]
    return out, mappings, diagnostics


def audit_all() -> dict:
    result = {"chapters": [], "summary": {}}
    totals = {"body_groups": 0, "body_units": 0, "solution_units": 0, "mapped_problems": 0, "diagnostics": 0}
    for ch in range(1, 27):
        groups = extract_body_groups(ch)
        sols = extract_solution_units(ch)
        _, mappings, diagnostics = build_chapter(ch, strict=False)
        row = {
            "chapter": ch,
            "body_groups": len(groups),
            "body_units": sum(len(g.units) for g in groups),
            "solution_units": len(sols),
            "mapped_problems": len(mappings),
            "diagnostics": diagnostics,
            "groups": [
                {
                    "group_id": g.group_id,
                    "numeric_path": g.numeric_path,
                    "title": g.title,
                    "kind": g.kind,
                    "qualifier": g.qualifier,
                    "context": g.context,
                    "mode": g.mode,
                    "body_numbers": [u.number for u in g.units],
                }
                for g in groups
            ],
        }
        result["chapters"].append(row)
        totals["body_groups"] += row["body_groups"]
        totals["body_units"] += row["body_units"]
        totals["solution_units"] += row["solution_units"]
        totals["mapped_problems"] += row["mapped_problems"]
        totals["diagnostics"] += len(diagnostics)
    result["summary"] = totals
    return result


def write_outputs(strict: bool) -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_DIR.mkdir(parents=True, exist_ok=True)
    all_maps: list[Mapping] = []
    all_diags: list[str] = []
    for ch in range(1, 27):
        out, maps, diags = build_chapter(ch, strict=False)
        (OUT_DIR / f"ch{ch:02d}.tex").write_text(out, encoding="utf-8", newline="\n")
        all_maps.extend(maps)
        all_diags.extend(diags)
    (REPORT_DIR / "INLINE_SOLUTION_MANIFEST.json").write_text(
        json.dumps([asdict(m) for m in all_maps], ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    (REPORT_DIR / "INLINE_MAPPING_DIAGNOSTICS.txt").write_text("\n".join(all_diags) + ("\n" if all_diags else ""), encoding="utf-8")
    blockers = [d for d in all_diags if d.startswith("UNSOLVED BODY UNIT") or d.startswith("NO SOLUTION GROUP")]
    print(f"generated_chapters=26 mapped_problems={len(all_maps)} diagnostics={len(all_diags)} blockers={len(blockers)}")
    if strict and blockers:
        print("strict mode: unmapped original problems remain", file=sys.stderr)
        return 2
    return 0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--audit", action="store_true", help="write/print mapping audit only")
    ap.add_argument("--write", action="store_true", help="generate inline chapters and manifest")
    ap.add_argument("--strict", action="store_true", help="fail if any original problem remains unmapped")
    args = ap.parse_args()
    if args.audit:
        report = audit_all()
        REPORT_DIR.mkdir(parents=True, exist_ok=True)
        (REPORT_DIR / "INLINE_MAPPING_AUDIT.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(report["summary"], ensure_ascii=False))
        for row in report["chapters"]:
            print(f"ch{row['chapter']:02d}: groups={row['body_groups']} body={row['body_units']} sol={row['solution_units']} mapped={row['mapped_problems']} diag={len(row['diagnostics'])}")
        return 0
    if args.write:
        return write_outputs(args.strict)
    ap.print_help()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
