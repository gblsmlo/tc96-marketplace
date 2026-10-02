#!/usr/bin/env bash
# Packages every skill of a self-contained family as a .skill (zip) that works on its own.
#
#   bash build/skill-packages.sh            -> dist/skills/<skill>.skill
#   bash build/skill-packages.sh <dest>
#
# A family is self-contained when it has skills/<family>/docs/. In the source, the family's
# skills share those docs and a few scripts between siblings; in the package, each skill
# carries its own copy: only the notes it cites (with the transitive closure between them)
# and the sibling scripts it calls. The duplication lives in the generated artifact, never
# in the source — and dist/skills/ is not versioned (dist/* in .gitignore).
#
# What the package leaves out: the ID-map generators (authoring tools that write into the
# siblings). The frontmatter comes out in the skill-spec format: name, description and
# metadata — docs, fonte and tags move under metadata.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${1:-$ROOT/dist/skills}"
rm -rf "$DEST"
mkdir -p "$DEST"

ROOT="$ROOT" DEST="$DEST" python3 <<'PYEOF'
import os, re, shutil, zipfile, pathlib, tempfile

root, dest = pathlib.Path(os.environ["ROOT"]), pathlib.Path(os.environ["DEST"])
# the skill's own directory, as the SKILL.md commands refer to it
SKILL_DIR = "${CLAUDE_SKILL_DIR}"
NOT_PACKAGED = {"generate-id-map.sh"}
LINK = re.compile(r"\[([^\]]+)\]\(([^)#:\s]+\.md)(#[^)]*)?\)")


def split(text):
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    fields, key = {}, None
    for line in m.group(1).splitlines():
        km = re.match(r"^(\w+):\s*(.*)$", line)
        if km:
            key = km.group(1)
            fields[key] = km.group(2)
        elif key and line.startswith(" "):
            fields.setdefault(key + "__list", []).append(line.strip().lstrip("- "))
    return fields, text[m.end():]


def frontmatter(f):
    fm = ["---", f"name: {f['nome']}", f"description: {f['descricao']}", "metadata:"]
    fm.append(f"  family: {f.get('familia', '')}")
    if f.get("fonte"):
        source = re.sub(r"\]\(\.\./docs/", "](docs/", f["fonte"])
        fm.append(f"  source: {source}")
    for k, name in (("docs", "context7"), ("tags", "tags")):
        if f.get(k + "__list"):
            fm.append(f"  {name}: \"{', '.join(f[k + '__list'])}\"")
    fm.append("---\n")
    return "\n".join(fm)


def cited(text, base_rel):
    """Family notes a file cites, by file name."""
    return {m.group(2).split("/")[-1] for m in LINK.finditer(text) if base_rel in m.group(2)}


summary = []
for family_docs in sorted(root.glob("skills/*/docs")):
    family = family_docs.parent.name
    for source in sorted(family_docs.parent.glob("*/SKILL.md")):
        fields, body = split(source.read_text(encoding="utf-8"))
        if fields.get("tipo") != "skill":
            continue
        name = source.parent.name
        tmp = pathlib.Path(tempfile.mkdtemp())
        target = tmp / name
        shutil.copytree(source.parent, target,
                        ignore=shutil.ignore_patterns("__pycache__", "*.pyc", *NOT_PACKAGED))

        # 1. sibling scripts this skill calls, with transitive closure
        siblings = re.compile(r"(?:\$\{CLAUDE_PLUGIN_ROOT\}/skills/|\$HERE/\.\./\.\./)([a-z0-9-]+)/scripts/([A-Za-z0-9._-]+)")
        queue = [p for p in target.rglob("*") if p.suffix in (".md", ".sh", ".py")]
        while queue:
            file = queue.pop()
            for m in siblings.finditer(file.read_text(encoding="utf-8")):
                sibling, script = m.group(1), m.group(2)
                copy = target / "scripts" / script
                if sibling != name and not copy.exists():
                    copy.parent.mkdir(exist_ok=True)
                    shutil.copy2(family_docs.parent / sibling / "scripts" / script, copy)
                    queue.append(copy)
                    # the copied script may call a neighbor from its original folder ($HERE/x)
                    for nb in re.findall(r"\$HERE/([A-Za-z0-9._-]+\.(?:sh|py))", copy.read_text(encoding="utf-8")):
                        if not (target / "scripts" / nb).exists() and (family_docs.parent / sibling / "scripts" / nb).exists():
                            shutil.copy2(family_docs.parent / sibling / "scripts" / nb, target / "scripts" / nb)
                            queue.append(target / "scripts" / nb)

        # 2. the notes it cites, and the notes those cite
        notes = set()
        for file in target.rglob("*.md"):
            notes |= cited(file.read_text(encoding="utf-8"), "docs/")
        queue = list(notes)
        while queue:
            current = family_docs / queue.pop()
            if not current.exists():
                continue
            for nb in {m.group(2) for m in LINK.finditer(current.read_text(encoding="utf-8")) if "/" not in m.group(2)}:
                if nb not in notes and (family_docs / nb).exists():
                    notes.add(nb)
                    queue.append(nb)
        (target / "docs").mkdir(exist_ok=True)
        for note in sorted(notes):
            if (family_docs / note).exists():
                shutil.copy2(family_docs / note, target / "docs" / note)

        # 3. rewrite paths: the docs and the scripts now live inside the skill
        for file in target.rglob("*"):
            if not file.is_file() or file.suffix not in (".md", ".sh", ".py"):
                continue
            t = file.read_text(encoding="utf-8")
            if file.suffix == ".md":
                # a passage marked as authoring (maintenance in the repository) does not travel
                t = re.sub(r"\n?<!-- authoring:start -->.*?<!-- authoring:end -->\n?", "\n", t, flags=re.S)
            if file.suffix == ".md" and file.parent.name != "docs":
                t = t.replace("](../../docs/", "](../docs/").replace("](../docs/", "](docs/") \
                    if file.parent == target else t.replace("](../../docs/", "](../docs/")
                t = re.sub(r"\$\{CLAUDE_PLUGIN_ROOT\}/skills/[a-z0-9-]+/scripts/", SKILL_DIR + "/scripts/", t)
                # the generator does not travel: the table row announcing it goes, and the
                # instruction to regenerate becomes a note that the map was generated at authoring time
                lines = []
                for l in t.split("\n"):
                    if "generate-id-map.sh" not in l and "build/claude-code.sh" not in l:
                        lines.append(l)
                    elif not l.startswith("|"):
                        notice = "> Generated at authoring time from this skill's docs; the generator is not part of this package."
                        if notice not in lines:
                            lines.append(notice)
                t = "\n".join(lines)
            if file.suffix in (".sh", ".py"):
                t = re.sub(r"\$HERE/\.\./\.\./[a-z0-9-]+/scripts/", "$HERE/", t)
                # in the package, the docs can only be the skill's own: never look outside it
                t = re.sub(r'^(\s*for KB in )"[^\n]*?; do$', r'\1"$HERE/../docs"; do', t, flags=re.M)
            if file.name == "SKILL.md" and file.parent == target:
                f, body_t = split(t)
                t = frontmatter(f) + body_t
            file.write_text(t, encoding="utf-8")

        # 4. safety net: a link that still leaves the package becomes a name in a code span
        loose = 0
        for file in target.rglob("*.md"):
            t = file.read_text(encoding="utf-8")
            turned = []

            def maybe(m):
                link_target = (file.parent / m.group(2)).resolve()
                inside = link_target.exists() and link_target.is_relative_to(target.resolve())
                if inside:
                    return m.group(0)
                turned.append(m.group(1))
                return f"`{m.group(1)}`"

            new = LINK.sub(maybe, t)
            loose += len(turned)
            if new != t:
                file.write_text(new, encoding="utf-8")

        for sh in target.rglob("*.sh"):
            sh.chmod(0o755)
        package = dest / f"{name}.skill"
        with zipfile.ZipFile(package, "w", zipfile.ZIP_DEFLATED) as z:
            for file in sorted(target.rglob("*")):
                if file.is_file():
                    z.write(file, file.relative_to(tmp))
        shutil.rmtree(tmp)
        n_scripts = len([n for n in zipfile.ZipFile(package).namelist() if "/scripts/" in n])
        summary.append(f"  {name:<18} {len(notes):>2} notes · {n_scripts} scripts · "
                       f"{package.stat().st_size // 1024:>4} KB" + (f" · {loose} link(s) turned into a name" if loose else ""))

print(f"skill-packages -> {dest}")
print("\n".join(summary))
PYEOF
