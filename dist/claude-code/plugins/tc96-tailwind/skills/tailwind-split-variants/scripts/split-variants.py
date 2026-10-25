#!/usr/bin/env python3
"""Move a component's cva/tv declarations into a sibling variants file.

  split-variants.py detect <root>                 convention in use + components with inline variants
  split-variants.py split <file.tsx>... [--write] [--suffix variants|styles]
  split-variants.py check <file-or-dir>...        what is still inline, and what the variants file must not hold

`split` is a dry run unless --write is given. It moves top-level `const x = cva(...)`/`tv(...)`, the
`VariantProps<typeof x>` aliases, and the top-level constants only they use; it never rewrites JSX.
"""
import argparse, pathlib, re, sys

DECL = re.compile(r"^(export\s+)?const\s+([A-Za-z_$][\w$]*)\s*=\s*(cva|tv)\s*\(", re.M)
CONST = re.compile(r"^(export\s+)?const\s+([A-Za-z_$][\w$]*)\b", re.M)
ALIAS = re.compile(r"^(export\s+)?type\s+([A-Za-z_$][\w$]*)\s*=\s*VariantProps<\s*typeof\s+([A-Za-z_$][\w$]*)\s*>\s*;?[ \t]*\n?", re.M)
IMPORT = re.compile(r"^import\s+(type\s+)?(.+?)\s+from\s+(['\"][^'\"]+['\"])[ \t]*;?[ \t]*\n", re.M | re.S)
EXPORT_LIST = re.compile(r"^export\s*\{([^}]*)\}\s*;?[ \t]*$", re.M)
CLASS_CONST = re.compile(r"""^(export\s+)?const\s+([A-Za-z_$][\w$]*)\s*=\s*(['"])([^'"\n]*)\3[ \t]*;?[ \t]*$""", re.M)
CLASS_TOKEN = re.compile(r"^!?(?:[\w@*\[\]()&>~=.,'%#/-]+:)*-?[a-z][\w\[\]().%#/!-]*$")
SKIP_DIRS = {"node_modules", ".git", "dist", "build", ".next", ".output", "coverage", "storybook-static"}


def code_mask(text):
    """Same length as text, with string, template and comment contents blanked (template ${} kept)."""
    out, i, n, stack = list(text), 0, len(text), []
    while i < n:
        c = text[i]
        if stack and stack[-1] == "`":
            if c == "\\":
                out[i] = " "; i += 1
                if i < n: out[i] = " "
            elif c == "`":
                stack.pop()
            elif text.startswith("${", i):
                stack.append("{"); i += 1
            else:
                out[i] = " " if c != "\n" else "\n"
            i += 1; continue
        if text.startswith("//", i):
            j = text.find("\n", i); j = n if j < 0 else j
            for k in range(i, j): out[k] = " "
            i = j; continue
        if text.startswith("/*", i):
            j = text.find("*/", i + 2); j = n if j < 0 else j + 2
            for k in range(i, j): out[k] = " " if text[k] != "\n" else "\n"
            i = j; continue
        if c in "'\"":
            j = i + 1
            while j < n and text[j] != c and text[j] != "\n":
                j += 2 if text[j] == "\\" else 1
            for k in range(i + 1, min(j, n)): out[k] = " "
            i = j + 1; continue
        if c == "`":
            stack.append("`")
        elif c == "{" and stack:
            stack.append("{")
        elif c == "}" and stack and stack[-1] == "{":
            stack.pop()
        i += 1
    return "".join(out)


def statement_end(text, mask, open_paren):
    depth = 0
    for i in range(open_paren, len(mask)):
        if mask[i] in "([{": depth += 1
        elif mask[i] in ")]}":
            depth -= 1
            if depth == 0:
                j = i + 1
                while j < len(text) and text[j] in " \t;": j += 1
                return j + 1 if j < len(text) and text[j] == "\n" else j
    raise ValueError("unbalanced declaration")


def const_end(text, mask, start):
    """End of a top-level `const x = ...` statement: first newline at depth 0 after the `=`."""
    depth, i = 0, mask.index("=", start)
    while i < len(mask):
        ch = mask[i]
        if ch in "([{": depth += 1
        elif ch in ")]}": depth -= 1
        elif ch == "\n" and depth == 0:
            nxt = text[i + 1:i + 2]
            if nxt not in (".", "?", ":", "+", "|", "&") and not text[:i].rstrip().endswith(("=", "+", ",", "(", "[", "{", "?", ":")):
                return i + 1
        i += 1
    return len(text)


def refs(mask_chunk, name):
    return re.search(rf"(?<![\w$.]){re.escape(name)}(?![\w$])", mask_chunk) is not None


def pascal(name, suffix):
    base = name[0].upper() + name[1:]
    return base if base.endswith(("Variants", "Styles")) else base + suffix.capitalize()


def target_for(path, suffix):
    stem = path.name.rsplit(".", 1)[0]
    return path.with_name(f"{stem}.{suffix}.ts")


def split(path, suffix, write):
    text = path.read_text(encoding="utf-8")
    mask = code_mask(text)
    target = target_for(path, suffix)
    decls = [(m.start(), statement_end(text, mask, m.end() - 1), m.group(2), bool(m.group(1))) for m in DECL.finditer(mask)]
    kinds = [m.group(3) for m in DECL.finditer(mask)]
    inline = [m.group(0).strip() for m in re.finditer(r"^[ \t]+(?:const|let)\s+\w+\s*=\s*(?:cva|tv)\s*\(", mask, re.M)]
    if not decls:
        return f"{path}: no top-level cva/tv" + (f" ({len(inline)} inside a function: move by hand)" if inline else "")
    if target.exists():
        return f"{path}: {target.name} already exists, nothing moved"
    moved = {name for _, _, name, _ in decls}
    spans = [(s, e) for s, e, _, _ in decls]
    exported = {name for _, _, name, exp in decls if exp}

    aliases = []
    for m in ALIAS.finditer(mask):
        if m.group(3) in moved:
            aliases.append((m.start(), m.end(), m.group(2), bool(m.group(1))))
            spans.append((m.start(), m.end()))
            if m.group(1): exported.add(m.group(2))
    alias_for = {ALIAS.match(mask, s).group(3): name for s, _, name, _ in aliases}

    # top-level constants the moved code uses travel with it; the component imports back the ones it shares
    shared = []
    changed = True
    while changed:
        changed = False
        moved_mask = "".join(mask[s:e] for s, e in spans)
        rest = "".join(mask[a:b] for a, b in gaps(spans, len(text)))
        for m in CONST.finditer(mask):
            name, s = m.group(2), m.start()
            if name in moved or any(a <= s < b for a, b in spans) or not refs(moved_mask, name):
                continue
            e = const_end(text, mask, s)
            rest_wo = "".join(mask[a:b] for a, b in gaps(spans + [(s, e)], len(text)))
            if refs(rest_wo, name):
                shared.append(name)
            spans.append((s, e)); moved.add(name); changed = True
            if m.group(1): exported.add(name)

    # top-level class-string constants the component uses directly are styles too: they move and come back as imports
    for m in CLASS_CONST.finditer(text):
        name, value = m.group(2), m.group(4).split()
        if name in moved or not value or any(a <= m.start() < b for a, b in spans):
            continue
        if all(CLASS_TOKEN.match(tok) for tok in value) and any("-" in tok or ":" in tok for tok in value):
            spans.append((m.start(), min(m.end() + 1, len(text)))); moved.add(name); shared.append(name)
            if m.group(1): exported.add(name)
    spans.sort()

    moved_text = "\n".join(text[s:e].strip("\n") + "\n" for s, e in spans)
    moved_mask = "".join(mask[s:e] for s, e in spans)
    remaining = "".join(text[a:b] for a, b in gaps(spans, len(text)))

    # the generated alias replaces VariantProps<typeof x> in the component
    new_aliases = []
    for _, _, name, _ in decls:
        if name not in alias_for:
            alias = pascal(name, suffix)
            if refs(code_mask(remaining), alias):
                alias = alias + "Props"
            alias_for[name] = alias
            new_aliases.append(f"export type {alias} = VariantProps<typeof {name}>\n")
    for name, alias in alias_for.items():
        remaining = re.sub(rf"VariantProps<\s*typeof\s+{re.escape(name)}\s*>", alias, remaining)

    # imports: what the moved code references goes with it; what the component no longer uses leaves it
    rem_mask = code_mask(remaining)
    var_imports, imports_out = [], remaining
    for m in IMPORT.finditer(remaining):
        whole, type_kw, clause, src = m.group(0), m.group(1) or "", m.group(2), m.group(3)
        names = parse_clause(clause)
        if not names:
            continue
        need_var = [n for n in names if refs(moved_mask, n[1]) or (n[1] == "VariantProps" and new_aliases)]
        rest_mask = rem_mask.replace(code_mask(whole), " " * len(whole), 1)
        keep = [n for n in names if refs(rest_mask, n[1])]
        if need_var:
            var_imports.append(render_import(type_kw, need_var, src))
        if len(keep) != len(names):
            imports_out = imports_out.replace(whole, render_import(type_kw, keep, src) if keep else "", 1)
    remaining = imports_out
    # a generated alias needs VariantProps even when the component never imported it
    if new_aliases and not any(re.search(r"\bVariantProps\b", i) for i in var_imports):
        lib = {"cva": "'class-variance-authority'", "tv": "'tailwind-variants'"}[kinds[0]]
        var_imports.append(f"import type {{ VariantProps }} from {lib}\n")

    rem_mask = code_mask(remaining)
    used = sorted(n for n in moved if refs(rem_mask, n))
    used_types = sorted({a for a in alias_for.values() if refs(rem_mask, a)})
    reexport = sorted(n for n in exported if n not in used and n not in used_types)
    listed = {x.strip().split(" as ")[0].strip() for m in EXPORT_LIST.finditer(rem_mask) for x in m.group(1).split(",")}
    still_export = sorted(n for n in exported if n not in listed)

    rel = f"./{target.name[:-3]}"
    lines = []
    if used or used_types:
        names = used + [f"type {n}" for n in used_types] if used else used_types
        kw = "" if used else "type "
        lines.append(f"import {kw}{{ {', '.join(names)} }} from '{rel}'\n")
    head_end = last_import_end(remaining)
    after = remaining[head_end:].lstrip("\n")
    remaining = remaining[:head_end] + "".join(lines) + ("\n" if head_end or lines else "") + after
    if still_export:
        values = [n for n in still_export if n in moved]
        types = [n for n in still_export if n not in moved]
        tail = []
        if values: tail.append(f"export {{ {', '.join(values)} }} from '{rel}'\n")
        if types: tail.append(f"export type {{ {', '.join(types)} }} from '{rel}'\n")
        remaining = remaining.rstrip("\n") + "\n\n" + "".join(tail)
    remaining = re.sub(r"\n{3,}", "\n\n", remaining)

    body = re.sub(r"^(?!export\s)(const|type)\s", r"export \1 ", moved_text, flags=re.M)
    variants = "".join(sorted(set(var_imports), key=var_imports.index)) + "\n" + re.sub(r"\n{3,}", "\n\n", body).strip("\n") + "\n"
    if new_aliases:
        variants += "\n" + "".join(new_aliases)

    report = [f"{path} -> {target.name}",
              f"  moved: {', '.join(sorted(moved))}" + (f" · types: {', '.join(sorted(set(alias_for.values())))}" if alias_for else "")]
    if reexport or still_export:
        report.append(f"  still exported from {path.name}: {', '.join(still_export) or '—'}")
    if shared:
        report.append(f"  shared with the component, now imported from {target.name}: {', '.join(shared)}")
    if inline:
        report.append(f"  {len(inline)} cva/tv inside a function: move by hand")
    if write:
        target.write_text(variants, encoding="utf-8")
        path.write_text(remaining, encoding="utf-8")
    else:
        report.append("  (dry run: --write to apply)")
        report.append("  --- " + target.name + "\n" + "\n".join("  | " + l for l in variants.splitlines()))
    return "\n".join(report)


def gaps(spans, n):
    out, pos = [], 0
    for s, e in sorted(spans):
        if s > pos: out.append((pos, s))
        pos = max(pos, e)
    if pos < n: out.append((pos, n))
    return out


def parse_clause(clause):
    """[(type_only, local_name, original_text)] for named imports; default/namespace imports are ignored."""
    m = re.search(r"\{([^}]*)\}", clause, re.S)
    if not m:
        return []
    out = []
    for part in m.group(1).split(","):
        part = part.strip()
        if not part: continue
        t = part.startswith("type ")
        core = part[5:].strip() if t else part
        local = core.split(" as ")[-1].strip()
        out.append((t, local, part))
    return out


def render_import(type_kw, names, src):
    return f"import {type_kw}{{ {', '.join(n[2] for n in names)} }} from {src}\n"


def last_import_end(text):
    end = 0
    for m in IMPORT.finditer(text):
        end = m.end()
    if end == 0:
        d = re.match(r"^(['\"]use (client|server)['\"];?\s*\n)", text)
        end = d.end() if d else 0
    return end


def files(paths, pattern):
    for p in map(pathlib.Path, paths):
        if p.is_file():
            yield p
        else:
            for f in sorted(p.rglob(pattern)):
                if not SKIP_DIRS & set(f.parts):
                    yield f


def detect(root):
    root = pathlib.Path(root)
    variants = [f for f in files([root], "*.variants.ts*")]
    styles = [f for f in files([root], "*.styles.ts")]
    inline = [f for f in files([root], "*.tsx") if re.search(r"(?<![\w$.])(cva|tv)\s*\(", code_mask(f.read_text(encoding="utf-8")))]
    if len(styles) > len(variants):
        conv = "styles"
    else:
        conv = "variants"
    folder = sum(1 for f in variants + styles if f.parent.name == f.name.split(".")[0])
    print(f"CONVENTION: {conv}" + (" (existing)" if variants or styles else " (default: none found)"))
    print(f"  *.variants.ts: {len(variants)} · *.styles.ts: {len(styles)} · inside a component folder: {folder}")
    print(f"  components with inline cva/tv: {len(inline)}")
    for f in inline:
        print(f"    {f}")


def check(paths):
    bad = 0
    for f in files(paths, "*.ts*"):
        t = f.read_text(encoding="utf-8")
        m = code_mask(t)
        if f.name.endswith((".variants.ts", ".styles.ts")):
            stem = f.name.split(".")[0]
            if re.search(r"from\s+['\"](react|react/jsx-runtime)['\"]", t) or re.search(r"<[A-Z][\w.]*[\s/>]", m):
                print(f"✗ {f}: React or JSX in a variants file — it holds only cva/tv, their types and class strings"); bad += 1
            if re.search(rf"from\s+['\"]\./{re.escape(stem)}['\"]", t):
                print(f"✗ {f}: imports its own component — import cycle"); bad += 1
            # composing complete class constants (`${base} ${focus}`) is fine; gluing a fragment to a name is not
            for s in re.finditer(r"`[^`]*(?:[\w-]\$\{|\}[\w-])[^`]*`", t):
                print(f"✗ {f}: class name built by interpolation (TW-SRC-01): {s.group(0)[:60]}"); bad += 1
            if not re.search(r"^export\s", t, re.M):
                print(f"✗ {f}: exports nothing"); bad += 1
        elif f.suffix == ".tsx" and re.search(r"(?<![\w$.])(cva|tv)\s*\(", m):
            lines = sorted({m.count("\n", 0, x.start()) + 1 for x in re.finditer(r"(?<![\w$.])(cva|tv)\s*\(", m)})
            print(f"✗ {f}: cva/tv still called in the component (line {', '.join(map(str, lines))})"); bad += 1
    print("✓ variants are split" if not bad else f"{bad} problem(s)")
    return 1 if bad else 0


def main():
    ap = argparse.ArgumentParser()
    sub = ap.add_subparsers(dest="cmd", required=True)
    d = sub.add_parser("detect"); d.add_argument("root", nargs="?", default=".")
    s = sub.add_parser("split"); s.add_argument("files", nargs="+"); s.add_argument("--write", action="store_true")
    s.add_argument("--suffix", default="variants", choices=["variants", "styles"])
    c = sub.add_parser("check"); c.add_argument("paths", nargs="+")
    a = ap.parse_args()
    if a.cmd == "detect":
        detect(a.root)
    elif a.cmd == "split":
        for f in files(a.files, "*.tsx"):
            if f.suffix == ".tsx":
                print(split(f, a.suffix, a.write))
    else:
        sys.exit(check(a.paths))


if __name__ == "__main__":
    main()
