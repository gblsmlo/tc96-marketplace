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
DEST="${1:-$RAIZ/dist/claude-code/hermes-frontend}"
VERSAO="${VERSAO:-0.2.0}"

rm -rf "$DEST"
mkdir -p "$DEST/.claude-plugin" "$DEST/skills" "$DEST/agents" "$DEST/referencias"

cp -r "$RAIZ/knowledge-base/." "$DEST/referencias/"

RAIZ="$RAIZ" DEST="$DEST" VERSAO="$VERSAO" python3 <<'PYEOF'
import json, os, re, shutil, pathlib

raiz, dest = pathlib.Path(os.environ["RAIZ"]), pathlib.Path(os.environ["DEST"])
FERR = {"ler": ["Read"], "escrever": ["Write"], "editar": ["Edit"],
        "buscar": ["Grep", "Glob"], "executar": ["Bash"]}
MODELO = {"alto": "opus", "medio": "sonnet", "rapido": "haiku"}


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
        itens = campos.get(c + "__lista", [])
        if itens:
            saida.append(f"{c}:")
            saida += [f"  - {i}" for i in itens]
    return saida


def links(texto, de, para):
    return texto.replace(de, para)


# --- skills: skills/<familia>/<skill>/ -> skills/<skill>/ -------------------
nomes = []
for skill_dir in sorted((raiz / "skills").glob("*/*/")):
    fonte_skill = skill_dir / "SKILL.md"
    if not fonte_skill.exists():
        continue
    campos_skill, _ = partir(fonte_skill.read_text(encoding="utf-8"))
    if not campos_skill or campos_skill.get("tipo") != "skill":
        continue  # familia ainda no formato antigo, nao migrada
    nome = skill_dir.name
    nomes.append(nome)
    alvo = dest / "skills" / nome
    shutil.copytree(skill_dir, alvo)
    for arq in alvo.rglob("*.md"):
        t = arq.read_text(encoding="utf-8")
        # a familia sai do caminho: uma subida a menos, e o nome da pasta muda
        t = links(t, "../../../knowledge-base/", "../../referencias/")
        t = links(t, "../../../../knowledge-base/", "../../../referencias/")
        if arq.name == "SKILL.md":
            campos, corpo = partir(t)
            fm = ["---", f"name: {campos['nome']}", f"descricao: {campos['descricao']}"]
            fm[2] = f"description: {campos['descricao']}"
            if campos.get("fonte"):
                fm.append(f"fonte: {campos['fonte']}")
            fm += listas(campos, ["tags"])
            fm.append("---\n")
            t = "\n".join(fm) + corpo
        arq.write_text(t, encoding="utf-8")

# --- agentes ---------------------------------------------------------------
for agente in sorted((raiz / "agents").glob("*.md")):
    campos, corpo = partir(agente.read_text(encoding="utf-8"))
    if not campos or campos.get("tipo") != "agente":
        continue  # legado ainda nao migrado
    corpo = links(corpo, "../knowledge-base/", "../referencias/")
    corpo = links(corpo, "../skills/README.md", "../skills/")
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
    # fontes carregam link: precisam da mesma reescrita do corpo
    cabecalho = links("\n".join(fm), "../knowledge-base/", "../referencias/")
    (dest / "agents" / agente.name).write_text(cabecalho + corpo, encoding="utf-8")

# --- packaging -------------------------------------------------------------
(dest / ".claude-plugin/plugin.json").write_text(json.dumps({
    "name": "hermes-frontend",
    "version": os.environ["VERSAO"],
    "description": "React, TanStack Router e Query, React Hook Form e Storybook no stack "
                   "desta casa — escrita, estrutura e revisão de interface. "
                   "Habilite em projeto com frontend.",
    "author": {"name": "Gabriel Melo"},
    "keywords": ["react", "tanstack", "storybook", "frontend"],
}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

print(f"claude-code: {len(nomes)} skills, "
      f"{len(list((dest / 'agents').glob('*.md')))} agente(s) -> {dest}")
PYEOF
