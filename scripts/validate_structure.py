from __future__ import annotations

from collections import Counter
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]

EXPECTED_SECTIONS = {
    1: 4, 2: 8, 3: 7, 4: 5, 5: 7, 6: 4, 7: 3, 8: 8, 9: 3,
    10: 5, 11: 5, 12: 5, 13: 5, 14: 5, 15: 3, 16: 5, 17: 3,
    18: 3, 19: 5, 20: 5, 21: 6, 22: 6, 23: 4, 24: 5, 25: 5, 26: 3,
}

REQUIRED = [
    "frontmatter/upper.tex",
    "frontmatter/lower.tex",
    "backmatter/upper.tex",
    "backmatter/lower.tex",
    "STYLE_GUIDE.md",
    "examples/style-example.tex",
    "TASKS.md",
]

FORBIDDEN_CHAPTER_COMMANDS = (
    r"\usepackage",
    r"\documentclass",
    r"\newcommand",
    r"\renewcommand",
    r"\providecommand",
    r"\DeclareMathOperator",
    r"\NewDocumentEnvironment",
    r"\newenvironment",
)


def active_tex(text: str) -> str:
    lines: list[str] = []
    for line in text.splitlines():
        out: list[str] = []
        i = 0
        while i < len(line):
            if line[i] == "%":
                backslashes = 0
                j = i - 1
                while j >= 0 and line[j] == "\\":
                    backslashes += 1
                    j -= 1
                if backslashes % 2 == 0:
                    break
            out.append(line[i])
            i += 1
        lines.append("".join(out))
    return "\n".join(lines)


def environment_order_errors(text: str) -> list[str]:
    stack: list[str] = []
    problems: list[str] = []
    for match in re.finditer(r"\\(begin|end)\{([^}]+)\}", text):
        kind, env = match.group(1), match.group(2)
        if kind == "begin":
            stack.append(env)
        elif not stack or stack[-1] != env:
            problems.append(
                f"environment order mismatch: end{{{env}}}, "
                f"top={stack[-1] if stack else 'none'}"
            )
            break
        else:
            stack.pop()
    if stack:
        problems.append(f"unclosed environments: {stack[-5:]}")
    return problems


def brace_depth(text: str) -> int:
    depth = 0
    for i, char in enumerate(text):
        if char not in "{}":
            continue
        backslashes = 0
        j = i - 1
        while j >= 0 and text[j] == "\\":
            backslashes += 1
            j -= 1
        if backslashes % 2:
            continue
        depth += 1 if char == "{" else -1
        if depth < 0:
            return depth
    return depth


errors: list[str] = []
warnings: list[str] = []
labels: list[tuple[str, Path]] = []
refs: list[tuple[str, Path]] = []

for rel in REQUIRED:
    if not (ROOT / rel).exists():
        errors.append(f"missing {rel}")

for n, expected_sections in EXPECTED_SECTIONS.items():
    path = ROOT / "chapters" / f"ch{n:02d}.tex"
    if not path.exists():
        errors.append(f"missing {path.relative_to(ROOT)}")
        continue

    text = path.read_text(encoding="utf-8")
    active = active_tex(text)
    rel = path.relative_to(ROOT)

    controls = [hex(ord(c)) for c in text if ord(c) < 32 and c not in "\t\n\r"]
    if controls:
        errors.append(f"{rel}: control chars {controls[:5]}")

    chapter_count = len(re.findall(r"\\chapter\s*\{", active))
    if chapter_count != 1:
        errors.append(f"{rel}: expected 1 chapter, found {chapter_count}")

    section_count = len(re.findall(r"\\section\s*\{", active))
    if section_count != expected_sections:
        errors.append(
            f"{rel}: expected {expected_sections} top-level sections from source TOC, "
            f"found {section_count}"
        )

    for command in FORBIDDEN_CHAPTER_COMMANDS:
        if command in active:
            errors.append(f"{rel}: forbidden local global-format command {command}")

    if re.search(r"\\(?:mathrm|operatorname)\{[^}]*[\u3400-\u9fff]", active):
        errors.append(f"{rel}: CJK text inside \\mathrm/\\operatorname")

    depth = brace_depth(active)
    if depth != 0:
        errors.append(f"{rel}: brace depth {depth}")

    for problem in environment_order_errors(active):
        errors.append(f"{rel}: {problem}")

    for image in re.findall(r"\\includegraphics(?:\[[^\]]*\])?\{([^}]+)\}", active):
        if not (ROOT / image).exists():
            errors.append(f"{rel}: missing image {image}")

    labels.extend((value, path) for value in re.findall(r"\\label\{([^}]+)\}", active))
    refs.extend(
        (value, path)
        for value in re.findall(r"\\(?:ref|eqref|autoref)\{([^}]+)\}", active)
    )

    checks = text.count("CHECK-SOURCE")
    if checks:
        warnings.append(f"{rel}: unresolved CHECK-SOURCE markers = {checks}")

label_counts = Counter(value for value, _ in labels)
for value, count in label_counts.items():
    if count > 1:
        errors.append(f"duplicate label {value}: {count} occurrences")

known_labels = set(label_counts)
for value, path in refs:
    if value not in known_labels:
        errors.append(f"{path.relative_to(ROOT)}: unresolved reference {value}")

print(f"errors={len(errors)} warnings={len(warnings)}")
for error in errors:
    print(f"ERROR: {error}")
for warning in warnings:
    print(f"WARN: {warning}")

sys.exit(1 if errors else 0)
