#!/usr/bin/env bash
# Projects the neutral source onto Claude Code plugins, in dist/claude-code/.
#
# What this adapter adds, which the neutral source does not have:
#   - frontmatter: nome->name, descricao->description, capacidades->tools, modelo->model,
#     esforco->effort (map in build/modelos.json)
#   - .claude-plugin/plugin.json
#   - flattened layout: skills/<familia>/<skill>/ -> skills/<skill>/
#   - knowledge-base/ -> referencias/
#   - commands/ -> commands/ (only those declared in PLUGINS)
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${1:-$RAIZ/dist/claude-code}"
VERSAO="${VERSAO:-0.16.0}"   # 0.4: commands/ · 0.5: commands on bun · 0.6: phase 3 on bun test · 0.7: model and effort per role · 0.8: self-contained tc96-tailwind · 0.9: react-component-performance and bench harness · 0.10: .specs/, spec command and workflow-spec · 0.11: repo-operator, cost per point of the flow and gaps with an owner · 0.11.1: a session opened by another passes the model and calls the role as a subagent · 0.12: execution scope, workflow hub in English, no appetite gate · 0.13: small units side by side — waves, review budget, planning bundle, delta re-review · 0.14: Spec Driven Development replaces the four pillars — PRD with waves, feature bundles, spec-writer, orchestrated runs, harness scripts · 0.15: self-contained tanstack family with tanstack-review, Tailwind docs inside each skill with migrate and split-variants · 0.16: design-docs writers plugin, four workflow phase skills, the delivery planned in layers outside in — capabilities PRD, index + layer files + contract, SDD-PLAN-*, layer PRs into the feature branch

rm -rf "$DEST"

RAIZ="$RAIZ" DEST="$DEST" VERSAO="$VERSAO" python3 <<'PYEOF'
import json, os, re, shutil, pathlib

raiz, dest = pathlib.Path(os.environ["RAIZ"]), pathlib.Path(os.environ["DEST"])
versao = os.environ["VERSAO"]

FERR = {"ler": ["Read"], "escrever": ["Write"], "editar": ["Edit"],
        "buscar": ["Grep", "Glob"], "listar": ["Glob"], "executar": ["Bash"],
        "usar-skill": ["Skill"]}
# listar: Glob alone, for an agent that may list a folder but never search contents.
# The explicit `tools:` list only allows the Skill tool when it is named.
ALVO = json.loads((raiz / "build/modelos.json").read_text(encoding="utf-8"))["claude-code"]

# One plugin per slice a project can enable. A family with no declared plugin
# is left out of the build.
PLUGINS = {
    "tc96-core": {
        "familias": ["test", "http", "workflow"],
        "agentes": ["code-reviewer", "software-architect", "qa-engineer",
                    "product-manager", "product-designer", "project-manager",
                    "devops-security", "ai-engineer", "monorepo-auditor",
                    "repo-explorer", "repo-operator", "spec-writer"],
        # a command is a named entry point the person invokes — not a fourth
        # layer of the chain but a fourth kind of artifact beside skill and
        # agent. Like agents, it enters by name, not by family.
        "comandos": ["scaffold-projeto",
                     "scaffold-01-tanstack-start", "scaffold-02-biome",
                     "scaffold-03-bun-test", "scaffold-04-git-hooks",
                     "scaffold-05-fba", "scaffold-06-shadcn",
                     "scaffold-07-workos-authkit", "scaffold-08-scripts",
                     "scaffold-09-feature-exemplo", "scaffold-10-verificacao",
                     "scaffold-fba-01-start", "scaffold-fba-02-biome",
                     "scaffold-fba-03-bun-test", "scaffold-fba-04-git-hooks",
                     "scaffold-fba-05-fba",
                     "configurar-antigravity", "spec", "scaffold-sdd-scripts"],
        "descricao": "Testing and HTTP contract, the delivery flow in four phases, and the roles "
                     "that cross any stack. Always enable.",
        "keywords": ["testing", "http", "review", "architecture"],
    },
    "tc96-frontend": {
        "familias": ["react", "tanstack", "storybook"],
        "agentes": ["frontend-developer"],
        "descricao": "React, TanStack Router and Query, React Hook Form and Storybook in this "
                     "house's stack — writing, structure and review of interfaces. "
                     "Enable in a project with a frontend.",
        "keywords": ["react", "tanstack", "storybook", "frontend"],
    },
    "tc96-backend": {
        "familias": ["bun", "elysia", "drizzle"],
        "agentes": ["backend-developer"],
        "descricao": "Bun runtime, Elysia and Drizzle — HTTP service, persistence and "
                     "dependencies. Enable in a project with a backend.",
        "keywords": ["bun", "elysia", "drizzle", "backend"],
    },
    # Self-contained: each skill carries its own docs in skills/tailwind/<skill>/docs/ and
    # cites no knowledge-base note, so it can be enabled without the rest of tc96.
    "tc96-tailwind": {
        "familias": ["tailwind"],
        "agentes": [],
        "descricao": "Tailwind CSS v4: setup, migration, build, variant split and review skills, each with its own "
                     "normative docs (TW-*). Self-contained: enable alone or with tc96-frontend.",
        "keywords": ["tailwind", "css", "design-system", "frontend"],
    },
    # Self-contained: the writing contract lives in skills/design-docs/docs/ and no skill cites
    # a knowledge-base note by link. The SDD flow in tc96-core calls doc-prd and doc-adr by name.
    "tc96-design-docs": {
        "familias": ["design-docs"],
        "agentes": ["doc-writer", "doc-writer-deep"],
        "descricao": "Writing-only document skills: PRD, ADR, epic, feature, story, tasks, bug, spec and PR, "
                     "each with its template and model tier, and the doc-writer agents that run them in a "
                     "fresh context with no search or shell. Self-contained: enable with tc96-core or alone.",
        "keywords": ["prd", "adr", "user-story", "spec", "documentation"],
    },
    "tc96-e2e": {
        "familias": ["playwright"],
        "agentes": [],
        "descricao": "Playwright — writing, auditing and diagnosing E2E tests. "
                     "Enable in a project with an E2E suite.",
        "keywords": ["playwright", "e2e", "testing"],
    },
}


# frontmatter keys moved to English; families not yet migrated still use the Portuguese ones
LEGACY = {"name": "nome", "description": "descricao", "type": "tipo", "family": "familia",
          "language": "idioma", "source": "fonte", "title": "titulo",
          "model": "modelo", "effort": "esforco"}


def legacy(fields):
    for en, pt in LEGACY.items():
        if en in fields and pt not in fields:
            fields[pt] = fields[en]
        if en + "__lista" in fields and pt + "__lista" not in fields:
            fields[pt + "__lista"] = fields[en + "__lista"]
        if en + "__list" in fields and pt + "__list" not in fields:
            fields[pt + "__list"] = fields[en + "__list"]
    return fields


def partir(texto):
    m = re.match(r"^---\n(.*?)\n---\n", texto, re.S)
    if not m:
        return None, texto
    campos, chave = {}, None
    for linha in m.group(1).splitlines():
        cm = re.match(r"^(\w+):\s*(.*)$", linha)
        if cm:
            chave = cm.group(1)
            campos[chave] = cm.group(2)
        elif chave and linha.startswith(" "):
            campos.setdefault(chave + "__lista", []).append(linha.strip().lstrip("- "))
    return legacy(campos), texto[m.end():]


def listas(campos, chaves):
    saida = []
    for c in chaves:
        if campos.get(c + "__lista"):
            saida.append(f"{c}:")
            saida += [f"  - {i}" for i in campos[c + "__lista"]]
    return saida


def neutro(caminho, tipo):
    campos, corpo = partir(caminho.read_text(encoding="utf-8"))
    if not campos or campos.get("tipo") != tipo:
        return None, None
    return campos, corpo


def citadas(texto):
    """Which knowledge-base notes this file references."""
    return {n for n in re.findall(r"knowledge-base/([^)\s]+\.md)", texto) if n != "MANIFESTO.md"}


def citadas_entre_notas(caminho):
    """Links from one note to another inside the knowledge-base: always a sibling in the same directory."""
    return {alvo for alvo in re.findall(r"\]\(([^)#:]+\.md)\)", caminho.read_text(encoding="utf-8"))
            if "/" not in alvo}


resumo, publicados = [], []
for plugin, cfg in PLUGINS.items():
    skills, agentes, comandos, notas = [], [], [], set()

    for familia in cfg["familias"]:
        for skill_md in sorted((raiz / "skills" / familia).glob("*/SKILL.md")):
            campos, corpo = neutro(skill_md, "skill")
            if not campos:
                continue  # family still in the old format
            skills.append((skill_md.parent, campos, corpo))

    for nome in cfg["agentes"]:
        arq = raiz / "agents" / f"{nome}.md"
        if not arq.exists():
            continue
        campos, corpo = neutro(arq, "agente")
        if campos:
            agentes.append((nome, campos, corpo))

    for nome in cfg.get("comandos", []):
        arq = raiz / "commands" / f"{nome}.md"
        if not arq.exists():
            continue
        campos, corpo = neutro(arq, "comando")
        if campos:
            comandos.append((nome, campos, corpo))

    if not skills and not agentes and not comandos:
        continue  # nothing migrated yet for this slice

    alvo = dest / "plugins" / plugin
    (alvo / ".claude-plugin").mkdir(parents=True, exist_ok=True)

    # the family's own docs (skills/<familia>/docs/) -> <plugin>/docs/<familia>/
    for familia in cfg["familias"]:
        doc_familia = raiz / "skills" / familia / "docs"
        if doc_familia.is_dir():
            shutil.copytree(doc_familia, alvo / "docs" / familia, ignore=shutil.ignore_patterns("SOURCES.md"))

    for origem, campos, corpo in skills:
        destino = alvo / "skills" / origem.name
        familia = origem.parent.name
        doc_na_familia = (raiz / "skills" / familia / "docs").is_dir()
        # evals/ is authoring material (claude plugin eval reads it from the source); it does not ship
        shutil.copytree(origem, destino, ignore=shutil.ignore_patterns("evals", "*-workspace"))
        for arq in destino.rglob("*.md"):
            t = arq.read_text(encoding="utf-8")
            notas |= citadas(t)
            # the family's docs move up to docs/<familia>/ at the plugin root;
            # references/ first, because "../../docs/" contains "../docs/"
            if doc_na_familia:
                t = t.replace("](../../docs/", f"](../../../docs/{familia}/")
                t = t.replace("](../docs/", f"](../../docs/{familia}/")
            # the family leaves the path: one level up fewer
            t = t.replace("../../../knowledge-base/", "../../referencias/")
            t = t.replace("../../../../knowledge-base/", "../../../referencias/")
            t = t.replace("](../README.md)", "](../../skills/)")
            if arq.name == "SKILL.md":
                c, corpo_arq = partir(t)
                fm = ["---", f"name: {c['nome']}", f"description: {c['descricao']}"]
                if c.get("fonte"):
                    fm.append(f"source: {c['fonte']}")
                # a skill that declares its tier runs on it while active; one that does not inherits
                if c.get("modelo"):
                    fm.append(f"model: {ALVO['modelo'][c['modelo']]}")
                if c.get("esforco"):
                    fm.append(f"effort: {ALVO['esforco'][c['esforco']]}")
                fm += listas(c, ["docs", "tags"])
                fm.append("---\n")
                t = "\n".join(fm) + corpo_arq
            arq.write_text(t, encoding="utf-8")
        for sh in destino.rglob("*.sh"):
            s = sh.read_text(encoding="utf-8")
            # scripts climb to the plugin root, not to the source root
            s = s.replace('/../../../.." && pwd)/knowledge-base',
                          '/../../.." && pwd)/referencias')
            # and the link THEY write must have the depth the adapter gave the
            # .md files — otherwise regenerating the map breaks the links
            s = s.replace("../../../../knowledge-base/", "../../../referencias/")
            # the family's own docs live in <plugin>/docs/<familia>/ in the target
            if doc_na_familia:
                s = s.replace('/../.." && pwd)/docs}', f'/../../.." && pwd)/docs/{familia}}}')
                s = s.replace("](../../docs/", f"](../../../docs/{familia}/")
            sh.write_text(s, encoding="utf-8")
            sh.chmod(0o755)

    for nome, campos, corpo in agentes:
        notas |= citadas(corpo) | citadas("\n".join(campos.get("fontes__lista", [])))
        ferramentas = []
        for c in campos.get("capacidades__lista", []):
            for f in FERR.get(c, []):
                if f not in ferramentas:
                    ferramentas.append(f)
        modelo = ALVO["modelo"][campos.get("modelo", "alto")]
        fm = ["---", f"name: {campos['nome']}", f"description: {campos['descricao']}",
              f"tools: {', '.join(ferramentas)}",
              f"model: {modelo}"]
        if modelo not in ALVO["sem_esforco"] and campos.get("esforco"):
            fm.append(f"effort: {ALVO['esforco'][campos['esforco']]}")
        fm += listas(campos, ["skills", "tags", "fontes"])
        fm.append("---\n")
        texto = ("\n".join(fm) + corpo)
        texto = texto.replace("../knowledge-base/", "../referencias/")
        texto = texto.replace("](../skills/README.md)", "](../skills/)")
        # the family's own docs live in <plugin>/docs/<familia>/ in the target
        for familia in cfg["familias"]:
            texto = texto.replace(f"](../skills/{familia}/docs/", f"](../docs/{familia}/")
        (alvo / "agents").mkdir(exist_ok=True)
        (alvo / "agents" / f"{nome}.md").write_text(texto, encoding="utf-8")

    for nome, campos, corpo in comandos:
        notas |= citadas(corpo)
        fm = ["---", f"description: {campos['descricao']}"]
        fm += listas(campos, ["tags"])
        fm.append("---\n")
        texto = ("\n".join(fm) + corpo).replace("../knowledge-base/", "../referencias/")
        # the family's own docs live in <plugin>/docs/<familia>/ in the target
        for familia in cfg["familias"]:
            texto = texto.replace(f"](../skills/{familia}/docs/", f"](../docs/{familia}/")
        (alvo / "commands").mkdir(exist_ok=True)
        (alvo / "commands" / f"{nome}.md").write_text(texto, encoding="utf-8")

    # transitive closure: notes cite each other, and a broken link in the plugin
    # is worse than one note too many
    fila = list(notas)
    while fila:
        atual = fila.pop()
        origem = raiz / "knowledge-base" / atual
        if not origem.exists():
            continue
        for vizinha in citadas_entre_notas(origem):
            if vizinha not in notas:
                notas.add(vizinha)
                fila.append(vizinha)

    for nota in sorted(notas):
        origem = raiz / "knowledge-base" / nota
        if origem.exists():
            destino = alvo / "referencias" / nota
            destino.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(origem, destino)
    for extra in ("MANIFESTO.md",) if notas else ():
        if (raiz / "knowledge-base" / extra).exists():
            shutil.copy2(raiz / "knowledge-base" / extra, alvo / "referencias" / extra)

    (alvo / ".claude-plugin/plugin.json").write_text(json.dumps({
        "name": plugin, "version": versao, "description": cfg["descricao"],
        "author": {"name": "Gabriel Melo"}, "keywords": cfg["keywords"],
    }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    publicados.append({"name": plugin, "source": f"./plugins/{plugin}",
                       "description": cfg["descricao"]})
    resumo.append(f"  {plugin}: {len(skills)} skills · {len(agentes)} agent(s) · "
                  + (f"{len(comandos)} command(s) · " if comandos else "")
                  + f"{len(notas)} notes")

(dest / ".claude-plugin").mkdir(parents=True, exist_ok=True)
(dest / ".claude-plugin/marketplace.json").write_text(json.dumps({
    "name": "tc96-marketplace",
    "owner": {"name": "Gabriel Melo", "email": "gblsmlo@gmail.com"},
    "metadata": {"description": "Agents, skills and rules for this house's stack.",
                 "version": versao},
    "plugins": publicados,
}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

# Manifest at the repository root: it is what `/plugin marketplace add gblsmlo/tc96-marketplace`
# reads. The plugins stay in dist/, so each source points there.
if dest.is_relative_to(raiz):
    rel = dest.relative_to(raiz).as_posix()
    (raiz / ".claude-plugin").mkdir(exist_ok=True)
    raiz_plugins = [{**p, "source": f"./{rel}/" + p["source"].removeprefix("./")}
                    for p in publicados]
    (raiz / ".claude-plugin/marketplace.json").write_text(json.dumps({
        "name": "tc96-marketplace",
        "owner": {"name": "Gabriel Melo", "email": "gblsmlo@gmail.com"},
        "metadata": {"description": "Agents, skills and rules for this house's stack.",
                     "version": versao},
        "plugins": raiz_plugins,
    }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

print(f"claude-code -> {dest}")
print("\n".join(resumo))
PYEOF
