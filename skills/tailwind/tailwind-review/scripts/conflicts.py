#!/usr/bin/env python3
"""Finds two utilities that set the same CSS property, under the same variants, on one element.

Usage: python3 conflicts.py [dir-or-file ...]

Two places are read, and they map to two different rules:
  className="..." / class="..." / className={`...`}  -> TW-UTIL-01 (the conflict reaches the element)
  cn(...) / clsx(...) / twMerge(...) / twJoin(...)    -> TW-COMP-02 (a merge hides an internal conflict)

It is a HEURISTIC over a fixed table of property groups, not a Tailwind parser: a custom
`@utility` or a token outside the default names may be missed, and an expression the scanner
cannot see is ignored. `cva(...)` is skipped on purpose: its variant strings are alternatives.
Exit code 1 when anything is found.
"""
import os
import re
import sys

EXT = {".tsx", ".jsx", ".ts", ".js", ".html", ".vue", ".svelte", ".astro", ".mdx"}
SKIP = {"node_modules", "dist", "build", ".output", ".git", "coverage", "storybook-static"}

DISPLAY = r"(block|inline-block|inline|flex|inline-flex|grid|inline-grid|hidden|contents|table|flow-root|list-item)"
POSITION = r"(static|fixed|absolute|relative|sticky)"
SIZE_TEXT = r"(xs|sm|base|lg|xl|[2-9]xl|\[[\d.]+(px|rem|em)\]|\(length:[^)]*\))"
ALIGN = r"(left|center|right|justify|start|end)"
WEIGHT = r"(thin|extralight|light|normal|medium|semibold|bold|extrabold|black)"
BG_NOT_COLOR = r"(opacity|linear|radial|conic|none|fixed|local|scroll|clip|origin|repeat|no-repeat|cover|contain|auto|center|top|bottom|left|right|blend|size|position|\[url)"

# (group, pattern over the bare utility) — first match wins
GROUPS = [
    ("display", rf"^{DISPLAY}$"),
    ("position", rf"^{POSITION}$"),
    ("flex-direction", r"^flex-(row|col)(-reverse)?$"),
    ("align-items", r"^items-"),
    ("justify-content", r"^justify-(?!items|self)"),
    ("text-align", rf"^text-{ALIGN}$"),
    ("font-size", rf"^text-{SIZE_TEXT}(/.*)?$"),
    ("font-weight", rf"^font-{WEIGHT}$"),
    ("font-family", r"^font-(sans|serif|mono)$"),
    ("text-color", r"^text-(?!ellipsis|clip|wrap|nowrap|balance|pretty|shadow|opacity)"),
    ("background-color", rf"^bg-(?!{BG_NOT_COLOR})"),
    ("border-width", r"^border(-[0-9]+)?$"),
    ("border-radius", r"^rounded(-(none|xs|sm|md|lg|xl|[2-4]xl|full|\[.*\]))?$"),
    ("box-shadow", r"^shadow(-(none|xs|sm|md|lg|xl|2xl|inner))?$"),
]
for k in sorted(("p", "px", "py", "pt", "pr", "pb", "pl", "ps", "pe",
          "m", "mx", "my", "mt", "mr", "mb", "ml", "ms", "me",
          "gap", "gap-x", "gap-y", "w", "h", "size", "min-w", "max-w", "min-h", "max-h",
          "inset", "top", "right", "bottom", "left", "z", "opacity", "leading", "tracking",
          "grid-cols", "grid-rows", "col-span", "row-span"), key=len, reverse=True):
    GROUPS.append((k, rf"^-?{re.escape(k)}-[^-]"))
GROUPS = [(g, re.compile(p)) for g, p in GROUPS]

ATTRIBUTE = re.compile(r"""\b(?:className|class)\s*=\s*(?:"([^"]*)"|'([^']*)'|\{\s*["'`]([^"'`]*)["'`]\s*\})""")
CALL = re.compile(r"\b(cn|clsx|twMerge|twJoin|cx)\(")
LITERAL = re.compile(r"""(["'`])((?:(?!\1).)*)\1""", re.S)


def split_variants(classe):
    """'md:hover:px-4!' -> ('md:hover', 'px-4'), ignoring ':' inside brackets."""
    depth, cut = 0, -1
    for i, c in enumerate(classe):
        if c in "[(":
            depth += 1
        elif c in "])":
            depth -= 1
        elif c == ":" and depth == 0:
            cut = i
    variants, bare = (classe[:cut], classe[cut + 1:]) if cut >= 0 else ("", classe)
    return variants, bare.strip("!")


def group_of(bare):
    for name, pattern in GROUPS:
        if pattern.search(bare):
            return name
    return None


def find_conflicts(classes):
    seen, found = {}, []
    for c in classes:
        if "${" in c or not c:
            continue
        variants, bare = split_variants(c)
        g = group_of(bare)
        if not g:
            continue
        # size-* sets width AND height: it collides with w-* and h-* under the same variants
        for gg in (("w", "h") if g == "size" else (g, "size") if g in ("w", "h") else (g,)):
            key = (variants, gg)
            if key in seen and seen[key] != c:
                found.append(f"{g}{' under ' + variants + ':' if variants else ''}: {seen[key]} × {c}")
                break
        for gg in (("w", "h", "size") if g == "size" else (g,)):
            seen.setdefault((variants, gg), c)
    return found


def closing_paren(text, start):
    depth = 0
    for i in range(start, len(text)):
        if text[i] == "(":
            depth += 1
        elif text[i] == ")":
            depth -= 1
            if depth == 0:
                return i
    return len(text)


def scan_file(path):
    try:
        text = open(path, encoding="utf-8").read()
    except (UnicodeDecodeError, OSError):
        return []
    line_of = lambda pos: text.count("\n", 0, pos) + 1
    out = []
    for m in ATTRIBUTE.finditer(text):
        value = next(g for g in m.groups() if g is not None)
        for a in find_conflicts(value.split()):
            out.append(("TW-UTIL-01", f"{path}:{line_of(m.start())}", a))
    for m in CALL.finditer(text):
        end = closing_paren(text, m.end() - 1)
        always, options = [], []        # options: one list of alternative branches per argument
        for arg in split_top(text[m.end():end], ","):
            branches = ternary_branches(arg)
            if len(branches) > 1:
                options.append([literals(b) for b in branches])
            else:
                always += literals(arg)
        found = set(find_conflicts(always))
        # each branch is checked against what is always there, never against its sibling branch
        for alternatives in options:
            for branch in alternatives:
                found |= {a for a in find_conflicts(always + branch)}
        for a in sorted(found):
            out.append(("TW-COMP-02", f"{path}:{line_of(m.start())}", f"{m.group(1)}(…) {a}"))
    return out


def literals(chunk):
    return [c for lit in LITERAL.finditer(chunk) for c in lit.group(2).split()]


def split_top(chunk, sep):
    """Split on `sep` outside (), [], {} and quotes."""
    parts, depth, quote, start = [], 0, None, 0
    for i, c in enumerate(chunk):
        if quote:
            if c == quote and chunk[i - 1] != "\\":
                quote = None
        elif c in "'\"`":
            quote = c
        elif c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        elif c == sep and depth == 0:
            parts.append(chunk[start:i]); start = i + 1
    parts.append(chunk[start:])
    return parts


def ternary_branches(arg):
    """`cond ? 'a' : 'b'` -> ['a' side, 'b' side]; anything else -> [arg]."""
    q = split_top(arg, "?")
    if len(q) < 2:
        return [arg]
    rest = "?".join(q[1:])
    branches = split_top(rest, ":")
    return branches if len(branches) >= 2 else [arg]


def iter_files(targets):
    for target in targets:
        if os.path.isfile(target):
            yield target
            continue
        for root, dirs, names in os.walk(target):
            dirs[:] = [d for d in dirs if d not in SKIP]
            for n in names:
                if os.path.splitext(n)[1] in EXT:
                    yield os.path.join(root, n)


def main():
    targets = sys.argv[1:] or ["src"]
    found = [a for f in iter_files(targets) for a in scan_file(f)]
    for rule, where, text in found:
        print(f"   {rule}  {where}  {text}")
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main())
