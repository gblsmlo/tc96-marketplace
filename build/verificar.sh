#!/usr/bin/env bash
# Verifica a fonte neutra e, se existirem, os alvos em dist/.
#
#   bash build/verificar.sh
#
# Checa o que a leitura nao pega: link relativo que nao resolve, sintaxe de vault
# que sobreviveu a projecao, frontmatter incompleto, e skill declarada por agente
# que nao existe. Sai != 0 no primeiro grupo com falha.
set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

RAIZ="$RAIZ" python3 <<'PYEOF'
import os, re, sys, pathlib

raiz = pathlib.Path(os.environ["RAIZ"])
falhas = []


def sondar(titulo, achados, detalhe=8):
    marca = "ok  " if not achados else "FALHA"
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


# --- 1. links relativos ----------------------------------------------------
for escopo, pastas in [("fonte", ("agents", "skills", "knowledge-base")),
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
    sondar(f"links que resolvem em {escopo} (de {total})", quebrados)

# --- 2. sintaxe de vault que sobreviveu ------------------------------------
vazados = []
for md in mds("agents", "skills", "knowledge-base"):
    texto = md.read_text(encoding="utf-8")
    campos = re.match(r"^---\n(.*?)\n---\n", texto, re.S)
    migrado = campos and re.search(r"^tipo: (skill|agente)$", campos.group(1), re.M)
    if md.parts[-2:][0] == "knowledge-base" or "knowledge-base" in str(md) or migrado:
        for linha_n, linha in enumerate(texto.splitlines(), 1):
            if "`" in linha:
                continue  # wikilink dentro de code span e citacao, nao link
            if re.search(r"\[\[[^\]]+\]\]", linha):
                vazados.append(f"{md.relative_to(raiz)}:{linha_n}")
sondar("wikilinks [[...]] fora de code span", vazados)

zettels = [f"{md.relative_to(raiz)}" for md in mds("agents", "skills", "knowledge-base")
           if "Zettels/" in md.read_text(encoding="utf-8")
           and "MANIFESTO" not in md.name and "README" not in md.name]
sondar("citacoes a Zettels/ (devem ter saido)", sorted(set(zettels)))

# --- 3. frontmatter neutro completo ----------------------------------------
faltando, declaradas, existentes = [], {}, set()
for skill in sorted((raiz / "skills").glob("*/*/SKILL.md")):
    campos = dict(re.findall(r"^(\w+):\s*(.*)$",
                             re.match(r"^---\n(.*?)\n---\n", skill.read_text(encoding="utf-8"),
                                      re.S).group(1), re.M))
    if campos.get("tipo") != "skill":
        continue  # familia nao migrada
    existentes.add(campos.get("nome", ""))
    for chave in ("nome", "descricao", "tipo", "familia"):
        if not campos.get(chave):
            faltando.append(f"{skill.relative_to(raiz)}: sem `{chave}`")
    if campos.get("nome") != skill.parent.name:
        faltando.append(f"{skill.relative_to(raiz)}: nome != diretório")
sondar("frontmatter neutro completo nas skills", faltando)

# --- 4. agente declara skill que existe ------------------------------------
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
            orfas.append(f"{agente.relative_to(raiz)}: declara `{nome}`, que não existe")
sondar("skills declaradas por agente que existem", orfas)

print()
if falhas:
    print(f"{len(falhas)} grupo(s) com falha: " + ", ".join(falhas))
    sys.exit(1)
print("tudo verde")
PYEOF
