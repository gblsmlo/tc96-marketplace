#!/usr/bin/env bash
# Checks the neutral source and, when they exist, the targets in dist/.
#
#   bash build/verificar.sh
#
# Checks what reading misses: a relative link that does not resolve, surviving vault
# syntax, a path pointing outside the repository, incomplete frontmatter, and a skill an
# agent declares that does not exist. Exits != 0 when any group fails.
set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

RAIZ="$RAIZ" python3 <<'PYEOF'
import os, re, sys, pathlib

raiz = pathlib.Path(os.environ["RAIZ"])
falhas = []


def sondar(titulo, achados, detalhe=8):
    marca = "ok  " if not achados else "FAIL"
    print(f"[{marca}] {titulo}: {len(achados)}")
    for a in achados[:detalhe]:
        print(f"         {a}")
    if achados:
        falhas.append(titulo)


def mds(*raizes):
    for r in raizes:
        base = raiz / r
        if base.exists():
            for md in base.rglob("*.md"):
                yield md


# --- 1. relative links ------------------------------------------------------
for escopo, pastas in [("source", ("agents", "skills", "commands", "knowledge-base")),
                       ("dist/claude-code", ("dist/claude-code",)),
                       ("dist/agents-md", ("dist/agents-md",))]:
    if not any((raiz / p).exists() for p in pastas):
        continue
    quebrados, total = [], 0
    for md in mds(*pastas):
        for m in re.finditer(r"\]\(([^)#:]+\.md)\)", md.read_text(encoding="utf-8")):
            total += 1
            if not (md.parent / m.group(1)).resolve().exists():
                quebrados.append(f"{md.relative_to(raiz)} -> {m.group(1)}")
    sondar(f"links that resolve in {escopo} (of {total})", quebrados)

# --- 2. surviving vault syntax ---------------------------------------------
vazados = []
for md in mds("agents", "skills", "commands", "knowledge-base"):
    texto = md.read_text(encoding="utf-8")
    campos = re.match(r"^---\n(.*?)\n---\n", texto, re.S)
    migrado = campos and re.search(r"^(tipo|type): (skill|agente)$", campos.group(1), re.M)
    if md.parts[-2:][0] == "knowledge-base" or "knowledge-base" in str(md) or migrado:
        for linha_n, linha in enumerate(texto.splitlines(), 1):
            if "`" in linha:
                continue  # a wikilink inside a code span is a citation, not a link
            if re.search(r"\[\[[^\]]+\]\]", linha):
                vazados.append(f"{md.relative_to(raiz)}:{linha_n}")
sondar("wikilinks [[...]] outside a code span", vazados)

zettels = [f"{md.relative_to(raiz)}" for md in mds("agents", "skills", "commands", "knowledge-base")
           if "Zettels/" in md.read_text(encoding="utf-8")
           and "MANIFESTO" not in md.name and "README" not in md.name]
sondar("citations of Zettels/ (should be gone)", sorted(set(zettels)))

# --- 2b. nothing points outside the project --------------------------------
# vault folder syntax and absolute machine paths. `~/.claude` is left out on
# purpose: it is a real, documented runtime path, not a source link.
FORA = re.compile(r"(?<![\w/])(?:Docs|Pages|Zettels|Classroom|Weblink)/"
                  r"|(?<![\w])/home/")
de_fora = []
for md in mds("agents", "skills", "commands", "knowledge-base"):
    for linha_n, linha in enumerate(md.read_text(encoding="utf-8").splitlines(), 1):
        m = FORA.search(linha)
        if m:
            de_fora.append(f"{md.relative_to(raiz)}:{linha_n}: {m.group(0)}")
sondar("paths outside the project", de_fora)

# --- 3. complete neutral frontmatter ---------------------------------------
faltando, declaradas, existentes = [], {}, set()
for skill in sorted((raiz / "skills").glob("*/*/SKILL.md")):
    campos = dict(re.findall(r"^(\w+):\s*(.*)$",
                             re.match(r"^---\n(.*?)\n---\n", skill.read_text(encoding="utf-8"),
                                      re.S).group(1), re.M))
    for en, pt in (("name", "nome"), ("description", "descricao"), ("type", "tipo"), ("family", "familia")):
        campos.setdefault(pt, campos.get(en, ""))
    if campos.get("tipo") != "skill":
        continue  # family not migrated
    existentes.add(campos.get("nome", ""))
    for chave in ("nome", "descricao", "tipo", "familia"):
        if not campos.get(chave):
            faltando.append(f"{skill.relative_to(raiz)}: missing `{chave}`")
    if campos.get("nome") != skill.parent.name:
        faltando.append(f"{skill.relative_to(raiz)}: name != directory")
sondar("complete neutral frontmatter in skills", faltando)

falta_cmd = []
for cmd in sorted((raiz / "commands").glob("*.md")):
    if cmd.name == "README.md":
        continue
    m = re.match(r"^---\n(.*?)\n---\n", cmd.read_text(encoding="utf-8"), re.S)
    campos = dict(re.findall(r"^(\w+):\s*(.*)$", m.group(1), re.M)) if m else {}
    if campos.get("tipo") != "comando":
        falta_cmd.append(f"{cmd.relative_to(raiz)}: missing `tipo: comando`")
        continue
    for chave in ("nome", "descricao"):
        if not campos.get(chave):
            falta_cmd.append(f"{cmd.relative_to(raiz)}: missing `{chave}`")
    if campos.get("nome") != cmd.stem:
        falta_cmd.append(f"{cmd.relative_to(raiz)}: name != file")
sondar("complete neutral frontmatter in commands", falta_cmd)

# --- 4. an agent declares a skill that exists ------------------------------
orfas = []
for agente in sorted((raiz / "agents").glob("*.md")):
    m = re.match(r"^---\n(.*?)\n---\n", agente.read_text(encoding="utf-8"), re.S)
    if not m or "tipo: agente" not in m.group(1):
        continue
    bloco = re.search(r"^skills:\n((?:  - .*\n)+)", m.group(1) + "\n", re.M)
    if not bloco:
        continue
    for linha in bloco.group(1).splitlines():
        nome = linha.strip().lstrip("- ").strip()
        if nome not in existentes:
            orfas.append(f"{agente.relative_to(raiz)}: declares `{nome}`, which does not exist")
sondar("skills declared by agents that exist", orfas)

# --- 5. cost per role --------------------------------------------------------
import json
mapa = json.loads((raiz / "build/modelos.json").read_text(encoding="utf-8"))
tiers = set.intersection(*(set(a["modelo"]) for a in mapa.values()))
niveis = set.intersection(*(set(a["esforco"]) for a in mapa.values()))
sem_tier, preload_pesado = [], []
for agente in sorted((raiz / "agents").glob("*.md")):
    m = re.match(r"^---\n(.*?)\n---\n", agente.read_text(encoding="utf-8"), re.S)
    if not m or "tipo: agente" not in m.group(1):
        continue
    campos = dict(re.findall(r"^(\w+):\s*(.*)$", m.group(1), re.M))
    if campos.get("modelo") not in tiers:
        sem_tier.append(f"{agente.relative_to(raiz)}: modelo `{campos.get('modelo')}`")
    if campos.get("esforco") not in niveis:
        sem_tier.append(f"{agente.relative_to(raiz)}: esforco `{campos.get('esforco')}`")
    bloco = re.search(r"^skills:\n((?:  - .*\n)+)", m.group(1) + "\n", re.M)
    if bloco and len(bloco.group(1).splitlines()) > 2:
        preload_pesado.append(f"{agente.relative_to(raiz)}: "
                              f"{len(bloco.group(1).splitlines())} preloaded skills")
sondar("agents with model and effort mapped in every target", sem_tier)
sondar("agents with at most 2 preloaded skills", preload_pesado)

delegacao = []
for skill in sorted((raiz / "skills/workflow").glob("*/SKILL.md")):
    linhas = skill.read_text(encoding="utf-8").splitlines()
    if not any("SDD-CORE-02" in l for l in linhas[:30]):
        delegacao.append(f"{skill.relative_to(raiz)}: no delegation block at the top")
    for n, l in enumerate(linhas, 1):
        if re.search(r"\ba fresh agent\b", l, re.I):
            delegacao.append(f"{skill.relative_to(raiz)}:{n}: unnamed agent")
sondar("steps delegated to a named agent (SDD-CORE-02)", delegacao)

sem_link = []
for modelo in sorted((raiz / "skills/workflow").glob("*/references/template-*.md")):
    skill = modelo.parent.parent / "SKILL.md"
    if f"references/{modelo.name}" not in skill.read_text(encoding="utf-8"):
        sem_link.append(f"{modelo.relative_to(raiz)}: not cited in {skill.relative_to(raiz)}")
sondar("workflow templates cited by their own skill", sem_link)

# --- 6. every .skill package stands alone -----------------------------------
# Runs only when dist/skills/ exists (bash build/skill-packages.sh). Each package is
# unzipped into an empty directory with nothing else around it, and must still
# resolve every link, find every script it calls and keep no path into the repo.
import zipfile, tempfile, subprocess, shutil
pacotes = sorted((raiz / "dist/skills").glob("*.skill"))
if pacotes:
    isolado = []
    LINK_MD = re.compile(r"\]\(([^)#:\s]+\.md)(?:#[^)]*)?\)")
    ESCAPE = re.compile(r"knowledge-base/|CLAUDE_PLUGIN_ROOT|\]\(\.\./\.\./\.\./|authoring:|generate-id-map|gerar-mapa|scripts/instalar|plugins/tc96-")
    SCRIPT = re.compile(r"\$\{CLAUDE_SKILL_DIR\}/scripts/([A-Za-z0-9._-]+)")
    for pacote in pacotes:
        tmp = pathlib.Path(tempfile.mkdtemp(prefix="skill-"))
        with zipfile.ZipFile(pacote) as z:
            z.extractall(tmp)
        topo = [p for p in tmp.iterdir() if p.is_dir()]
        if len(topo) != 1 or not (topo[0] / "SKILL.md").exists():
            isolado.append(f"{pacote.name}: expected one top-level directory with SKILL.md")
            shutil.rmtree(tmp)
            continue
        skill = topo[0]
        fm = re.match(r"^---\n(.*?)\n---\n", (skill / "SKILL.md").read_text(encoding="utf-8"), re.S)
        campos = dict(re.findall(r"^(\w+):\s*(.*)$", fm.group(1), re.M)) if fm else {}
        if campos.get("name") != skill.name or not campos.get("description"):
            isolado.append(f"{pacote.name}: frontmatter needs `name: {skill.name}` and `description`")
        for md in skill.rglob("*.md"):
            texto = md.read_text(encoding="utf-8")
            for m in LINK_MD.finditer(texto):
                alvo = (md.parent / m.group(1)).resolve()
                if not alvo.exists() or not alvo.is_relative_to(skill.resolve()):
                    isolado.append(f"{pacote.name}: {md.relative_to(skill)} -> {m.group(1)} leaves the package")
            for n, linha in enumerate(texto.splitlines(), 1):
                m = ESCAPE.search(linha)
                if m:
                    isolado.append(f"{pacote.name}: {md.relative_to(skill)}:{n}: `{m.group(0)}`")
            for m in SCRIPT.finditer(texto):
                if not (skill / "scripts" / m.group(1)).exists():
                    isolado.append(f"{pacote.name}: {md.relative_to(skill)} calls scripts/{m.group(1)}, which is not in the package")
        vazio = tmp / "empty-project"
        vazio.mkdir()
        for sh in sorted(skill.rglob("scripts/*.sh")):
            if subprocess.run(["bash", "-n", str(sh)], capture_output=True).returncode:
                isolado.append(f"{pacote.name}: scripts/{sh.name} does not parse")
                continue
            try:
                r = subprocess.run(["bash", str(sh), str(vazio)], capture_output=True, text=True,
                                   timeout=60, cwd=vazio)
                err = r.stderr
            except subprocess.TimeoutExpired:
                err = "timed out after 60s"
            if re.search(r"No such file|command not found|timed out", err):
                isolado.append(f"{pacote.name}: scripts/{sh.name} on an empty project: {err.strip().splitlines()[-1][:120]}")
        shutil.rmtree(tmp)
    sondar(f".skill packages that stand alone (of {len(pacotes)})", isolado)

print()
if falhas:
    print(f"{len(falhas)} failing group(s): " + ", ".join(falhas))
    sys.exit(1)
print("all green")
PYEOF
