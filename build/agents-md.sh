#!/usr/bin/env bash
# Projeta a fonte neutra para a convencao AGENTS.md, em dist/agents-md/.
# Alvo: Codex, Jules, Copilot, OpenCode e qualquer runtime que so leia markdown.
#
# O layout e o mesmo da fonte, entao nenhum link precisa ser reescrito.
# O que muda: o frontmatter sai (nenhum runtime generico o interpreta) e a
# descricao, que e o sinal de roteamento, vira blockquote logo abaixo do titulo.
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${1:-$RAIZ/dist/agents-md}"

rm -rf "$DEST"
mkdir -p "$DEST"
cp -r "$RAIZ/knowledge-base" "$DEST/knowledge-base"

RAIZ="$RAIZ" DEST="$DEST" python3 <<'PYEOF'
import os, re, shutil, pathlib

raiz, dest = pathlib.Path(os.environ["RAIZ"]), pathlib.Path(os.environ["DEST"])


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


def sem_frontmatter(campos, corpo):
    """Tira o frontmatter e preserva a descricao como blockquote apos o H1."""
    linhas = corpo.lstrip("\n").splitlines()
    saida, injetado = [], False
    for linha in linhas:
        saida.append(linha)
        if not injetado and linha.startswith("# "):
            saida.append("")
            saida.append(f"> **Quando usar:** {campos['descricao']}")
            injetado = True
    if not injetado:
        saida = [f"> **Quando usar:** {campos['descricao']}", ""] + saida
    return "\n".join(saida) + "\n"


skills, agentes = [], []

for skill_dir in sorted((raiz / "skills").glob("*/*/")):
    fonte = skill_dir / "SKILL.md"
    if not fonte.exists():
        continue
    campos, corpo = partir(fonte.read_text(encoding="utf-8"))
    if not campos or campos.get("tipo") != "skill":
        continue  # familia ainda nao migrada
    familia = campos["familia"]
    alvo = dest / "skills" / familia / skill_dir.name
    shutil.copytree(skill_dir, alvo)
    (alvo / "SKILL.md").write_text(sem_frontmatter(campos, corpo), encoding="utf-8")
    skills.append((familia, skill_dir.name, campos["descricao"],
                   campos.get("docs__lista", [])))

indice = raiz / "skills/README.md"
if indice.exists():
    (dest / "skills").mkdir(parents=True, exist_ok=True)
    # neste alvo o contrato da raiz e o AGENTS.md, nao o README
    (dest / "skills/README.md").write_text(
        indice.read_text(encoding="utf-8").replace("../README.md", "../AGENTS.md"),
        encoding="utf-8")

for readme in sorted((raiz / "skills").glob("*/README.md")):
    alvo = dest / "skills" / readme.parent.name / "README.md"
    if alvo.parent.exists():
        shutil.copy2(readme, alvo)

for agente in sorted((raiz / "agents").glob("*.md")):
    campos, corpo = partir(agente.read_text(encoding="utf-8"))
    if not campos or campos.get("tipo") != "agente":
        continue
    (dest / "agents").mkdir(exist_ok=True)
    (dest / "agents" / agente.name).write_text(sem_frontmatter(campos, corpo), encoding="utf-8")
    agentes.append((campos["nome"], campos["descricao"], campos.get("skills__lista", [])))

# --- AGENTS.md: o roteador -------------------------------------------------
linhas = [
    "# AGENTS.md",
    "",
    "Instruções para agentes de código neste repositório. Três camadas, cada uma com dono:",
    "",
    "| Camada | Onde | Responde |",
    "| --- | --- | --- |",
    "| **papel** | `agents/` | *quem* faz, com que contexto, e o que entrega |",
    "| **procedimento** | `skills/` | *como* fazer, em que ordem, e como reportar |",
    "| **regra** | `knowledge-base/` | *o que* é certo, por ID |",
    "",
    "Divergência entre agente e skill é bug do agente; entre skill e regra, bug da skill.",
    "Nenhuma camada copia o texto da camada abaixo — ela **cita por ID**.",
    "",
    "## Papéis",
    "",
]
for nome, desc, skills_do_agente in agentes:
    linhas += [f"### `{nome}`", "", desc, ""]
    if skills_do_agente:
        linhas.append("Carrega, conforme a tarefa: "
                      + " · ".join(f"`{s}`" for s in skills_do_agente) + ".")
        linhas.append("")
    linhas.append(f"Procedimento completo em [`agents/{nome}.md`](agents/{nome}.md).")
    linhas.append("")

linhas += ["## Procedimentos", "",
           "Carregue **uma** skill por tarefa, e só as referências que ela mandar abrir.", ""]
familia_atual = None
for familia, nome, desc, _docs in skills:
    if familia != familia_atual:
        if familia_atual is not None:
            linhas.append("")  # tabela nao cola no proximo heading
        familia_atual = familia
        linhas += [f"### {familia}", "",
                   f"Índice da família: [`skills/{familia}/README.md`](skills/{familia}/README.md)",
                   "", "| Skill | Quando usar |", "| --- | --- |"]
    curta = desc.split("—")[0].strip() if "—" in desc else desc[:120]
    linhas.append(f"| [`{nome}`](skills/{familia}/{nome}/SKILL.md) | {curta} |")
com_docs = [(n, d) for _f, n, _desc, d in skills if d]
if com_docs:
    linhas += ["", "## Superfície de API", "",
               "Assinatura, opção e comportamento por versão **não** moram neste repositório:",
               "resolva pelo Context7, com o library ID que a skill declara. A regra e o ID",
               "de citação continuam vindo de `knowledge-base/`.", "",
               "| Skill | Library ID |", "| --- | --- |"]
    linhas += [f"| `{n}` | {' · '.join('`' + i + '`' for i in d)} |" for n, d in com_docs]
    linhas += ["", "Skill que não declara nada não tem biblioteca upstream — teste e HTTP são",
               "conceito e RFC, não API de ninguém. Ausência aqui é informação, não lacuna."]

linhas += ["", "## Regra", "",
           "`knowledge-base/docs/` é a regra (IDs canônicos) e `knowledge-base/pages/` são os mapas.",
           "Todo achado cita o ID e o arquivo:linha. Cópia de regra dentro de skill vira",
           "réplica desatualizada — por isso as skills **apontam** em vez de repetir.",
           "", "Origem e integridade de cada nota: [`knowledge-base/MANIFESTO.md`](knowledge-base/MANIFESTO.md).",
           ""]

(dest / "AGENTS.md").write_text("\n".join(linhas), encoding="utf-8")
print(f"agents-md: {len(skills)} skills, {len(agentes)} agente(s) -> {dest}")
PYEOF
