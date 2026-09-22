#!/usr/bin/env bash
# Projeta a fonte neutra para um plugin do Claude Code, em dist/claude-code/.
#
# O que este adaptador acrescenta, e que a fonte neutra nao tem:
#   - frontmatter: nome->name, descricao->description, capacidades->tools, modelo->model
#   - .claude-plugin/plugin.json
#   - layout achatado: skills/<familia>/<skill>/ -> skills/<skill>/
#   - knowledge-base/ -> referencias/
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${1:-$RAIZ/dist/claude-code}"
VERSAO="${VERSAO:-0.3.0}"   # 0.3.0: hermes -> twincam, nome de plugin e de marketplace

rm -rf "$DEST"

RAIZ="$RAIZ" DEST="$DEST" VERSAO="$VERSAO" python3 <<'PYEOF'
import json, os, re, shutil, pathlib

raiz, dest = pathlib.Path(os.environ["RAIZ"]), pathlib.Path(os.environ["DEST"])
versao = os.environ["VERSAO"]

FERR = {"ler": ["Read"], "escrever": ["Write"], "editar": ["Edit"],
        "buscar": ["Grep", "Glob"], "executar": ["Bash"]}
MODELO = {"alto": "opus", "medio": "sonnet", "rapido": "haiku"}

# Um plugin por recorte habilitavel em projeto. Familia sem plugin declarado
# nao sai no build.
PLUGINS = {
    "twincam-core": {
        "familias": ["test", "http"],
        "agentes": ["code-reviewer", "software-architect", "qa-engineer",
                    "product-manager", "product-designer", "project-manager",
                    "devops-security", "ai-engineer", "monorepo-auditor"],
        "descricao": "Teste e contrato HTTP, e os papéis que atravessam qualquer stack. "
                     "Habilite sempre.",
        "keywords": ["teste", "http", "review", "arquitetura"],
    },
    "twincam-frontend": {
        "familias": ["react", "tanstack", "storybook"],
        "agentes": ["frontend-developer"],
        "descricao": "React, TanStack Router e Query, React Hook Form e Storybook no stack "
                     "desta casa — escrita, estrutura e revisão de interface. "
                     "Habilite em projeto com frontend.",
        "keywords": ["react", "tanstack", "storybook", "frontend"],
    },
    "twincam-backend": {
        "familias": ["bun", "elysia", "drizzle"],
        "agentes": ["backend-developer"],
        "descricao": "Runtime Bun, Elysia e Drizzle — serviço HTTP, persistência e "
                     "dependências. Habilite em projeto com backend.",
        "keywords": ["bun", "elysia", "drizzle", "backend"],
    },
    "twincam-e2e": {
        "familias": ["playwright"],
        "agentes": [],
        "descricao": "Playwright — escrita, auditoria e diagnóstico de teste E2E. "
                     "Habilite em projeto com suíte E2E.",
        "keywords": ["playwright", "e2e", "teste"],
    },
}


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
    return campos, texto[m.end():]


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
    """Quais notas da knowledge-base este arquivo referencia."""
    return set(re.findall(r"knowledge-base/((?:docs|pages)/[^)\s]+\.md)", texto))


def citadas_entre_notas(caminho):
    """Links de uma nota para outra dentro da knowledge-base, normalizados."""
    sub = caminho.parent.name
    saida = set()
    for alvo in re.findall(r"\]\(([^)#:]+\.md)\)", caminho.read_text(encoding="utf-8")):
        if alvo.startswith("../"):
            saida.add(alvo[3:])          # ../pages/x.md -> pages/x.md
        elif "/" not in alvo:
            saida.add(f"{sub}/{alvo}")   # irma no mesmo diretorio
    return saida


resumo, publicados = [], []
for plugin, cfg in PLUGINS.items():
    skills, agentes, notas = [], [], set()

    for familia in cfg["familias"]:
        for skill_md in sorted((raiz / "skills" / familia).glob("*/SKILL.md")):
            campos, corpo = neutro(skill_md, "skill")
            if not campos:
                continue  # familia ainda no formato antigo
            skills.append((skill_md.parent, campos, corpo))

    for nome in cfg["agentes"]:
        arq = raiz / "agents" / f"{nome}.md"
        if not arq.exists():
            continue
        campos, corpo = neutro(arq, "agente")
        if campos:
            agentes.append((nome, campos, corpo))

    if not skills and not agentes:
        continue  # nada migrado ainda para este recorte

    alvo = dest / "plugins" / plugin
    (alvo / ".claude-plugin").mkdir(parents=True, exist_ok=True)

    for origem, campos, corpo in skills:
        destino = alvo / "skills" / origem.name
        shutil.copytree(origem, destino)
        for arq in destino.rglob("*.md"):
            t = arq.read_text(encoding="utf-8")
            notas |= citadas(t)
            # a familia sai do caminho: uma subida a menos
            t = t.replace("../../../knowledge-base/", "../../referencias/")
            t = t.replace("../../../../knowledge-base/", "../../../referencias/")
            t = t.replace("](../README.md)", "](../../skills/)")
            if arq.name == "SKILL.md":
                c, corpo_arq = partir(t)
                fm = ["---", f"name: {c['nome']}", f"description: {c['descricao']}"]
                if c.get("fonte"):
                    fm.append(f"fonte: {c['fonte']}")
                fm += listas(c, ["docs", "tags"])
                fm.append("---\n")
                t = "\n".join(fm) + corpo_arq
            arq.write_text(t, encoding="utf-8")
        for sh in destino.rglob("*.sh"):
            s = sh.read_text(encoding="utf-8")
            # os scripts sobem ate a raiz do plugin, nao ate a raiz da fonte
            s = s.replace('/../../../.." && pwd)/knowledge-base',
                          '/../../.." && pwd)/referencias')
            # e o link que ELES escrevem tem de ter a mesma profundidade que o
            # adaptador deu aos .md — senao regenerar o mapa quebra os links
            s = s.replace("../../../../knowledge-base/", "../../../referencias/")
            sh.write_text(s, encoding="utf-8")
            sh.chmod(0o755)

    for nome, campos, corpo in agentes:
        notas |= citadas(corpo) | citadas("\n".join(campos.get("fontes__lista", [])))
        ferramentas = []
        for c in campos.get("capacidades__lista", []):
            for f in FERR.get(c, []):
                if f not in ferramentas:
                    ferramentas.append(f)
        fm = ["---", f"name: {campos['nome']}", f"description: {campos['descricao']}",
              f"tools: {', '.join(ferramentas)}",
              f"model: {MODELO.get(campos.get('modelo', 'alto'), 'opus')}"]
        fm += listas(campos, ["skills", "tags", "fontes"])
        fm.append("---\n")
        texto = ("\n".join(fm) + corpo)
        texto = texto.replace("../knowledge-base/", "../referencias/")
        texto = texto.replace("](../skills/README.md)", "](../skills/)")
        (alvo / "agents").mkdir(exist_ok=True)
        (alvo / "agents" / f"{nome}.md").write_text(texto, encoding="utf-8")

    # fecho transitivo: as notas se citam entre si, e link quebrado no plugin
    # e pior que nota a mais
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
    for extra in ("MANIFESTO.md",):
        if (raiz / "knowledge-base" / extra).exists():
            shutil.copy2(raiz / "knowledge-base" / extra, alvo / "referencias" / extra)

    (alvo / ".claude-plugin/plugin.json").write_text(json.dumps({
        "name": plugin, "version": versao, "description": cfg["descricao"],
        "author": {"name": "Gabriel Melo"}, "keywords": cfg["keywords"],
    }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    publicados.append({"name": plugin, "source": f"./plugins/{plugin}",
                       "description": cfg["descricao"]})
    resumo.append(f"  {plugin}: {len(skills)} skills · {len(agentes)} agente(s) · "
                  f"{len(notas)} notas")

(dest / ".claude-plugin").mkdir(parents=True, exist_ok=True)
(dest / ".claude-plugin/marketplace.json").write_text(json.dumps({
    "name": "twincam",
    "owner": {"name": "Gabriel Melo", "email": "gblsmlo@gmail.com"},
    "metadata": {"description": "Agentes, skills e regra do stack desta casa.",
                 "version": versao},
    "plugins": publicados,
}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

print(f"claude-code -> {dest}")
print("\n".join(resumo))
PYEOF
