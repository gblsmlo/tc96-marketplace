#!/usr/bin/env bash
# Projeta as notas do vault para knowledge-base/, num sentido so.
#
#   bash build/sincronizar.sh             projeta e regenera o MANIFESTO
#   bash build/sincronizar.sh --verificar nao escreve; falha se a origem mudou
#
# A regra mora no vault. Aqui e copia gerada: editar knowledge-base/ e trabalho
# perdido na proxima sincronizacao. O que entra esta em knowledge-base/dominio.txt.
#
# Zettels/ nao e projetado, e as citacoes a eles sao removidas do texto
# (decisao de 2026-09-22).
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VAULT="${VAULT:-$HOME/Sync/Vaults/Notes}"
MODO="${1:-projetar}"

[ -d "$VAULT" ] || { echo "vault não encontrado: $VAULT" >&2; exit 1; }

RAIZ="$RAIZ" VAULT="$VAULT" MODO="$MODO" python3 <<'PYEOF'
import hashlib, os, re, sys, pathlib

raiz = pathlib.Path(os.environ["RAIZ"])
vault = pathlib.Path(os.environ["VAULT"])
verificar = os.environ["MODO"] == "--verificar"
kb = raiz / "knowledge-base"

ACENTOS = str.maketrans("áãâéêíóõôúüç", "aaaeeiooouuc")


def slug(nome):
    s = nome.lower().translate(ACENTOS)
    return re.sub(r"[^a-z0-9]+", "-", s).strip("-") + ".md"


def sha(dados):
    return hashlib.sha256(dados).hexdigest()[:12]


def tirar_zettels(texto):
    z = r"`Zettels/[^`]*\.md`"
    # linha que e so um caminho de Zettel, em texto puro dentro de bloco de
    # codigo: sai a linha inteira, senao sobra um "+" orfao
    texto = re.sub(r"^[ \t]*[-+]?[ \t]*Zettels/[^\n]*\.md[ \t]*\n", "", texto, flags=re.M)
    texto = re.sub(r"\s*\((?:" + z + r")(?:,\s*(?:" + z + r"))*\)", "", texto)
    texto = re.sub(r",\s*" + z, "", texto)
    texto = re.sub(z + r",\s*", "", texto)
    texto = re.sub(r"\s*" + z, "", texto)
    texto = re.sub(r"\(\s*\)", "", texto)
    texto = re.sub(r"\(\s*,\s*", "(", texto)
    texto = re.sub(r"\s+,", ",", texto)
    texto = re.sub(r" {2,}", " ", texto)
    texto = re.sub(r" +\.", ".", texto)
    return re.sub(r" +$", "", texto, flags=re.M)


def resolver_wikilinks(texto, sub_atual, indice, zettels):
    """[[Nota]] -> link relativo se estiver no dominio; code span se nao estiver.

    Wikilink para Zettel e removido junto com o parentese que o cercava, pela
    mesma decisao que tira as citacoes em code span.
    """
    def alvo(m):
        nome, secao, alias = m.group(1).strip(), m.group(2), m.group(3)
        rotulo = (alias or nome).strip()
        if nome in zettels:
            return "\x00"          # marcado para remocao no passo seguinte
        destino = indice.get(nome)
        if not destino:
            return f"`{rotulo}`"   # existe no vault, nao neste recorte
        sub, arquivo = destino
        prefixo = "" if sub == sub_atual else f"../{sub}/"
        ancora = ""
        return f"[{rotulo}]({prefixo}{arquivo}{ancora})" + (f" {secao}" if secao else "")

    texto = re.sub(r"\[\[([^\]|#]+?)(#[^\]|]+)?(?:\|([^\]]+))?\]\]", alvo, texto)
    # ancora de secao do Obsidian: [[#Titulo]] -> [Titulo](#titulo)
    texto = re.sub(r"\[\[#([^\]|]+)\]\]",
                   lambda m: f"[{m.group(1)}](#{re.sub(r'[^a-z0-9]+', '-', m.group(1).lower().translate(ACENTOS)).strip('-')})",
                   texto)
    # limpa os marcadores de Zettel e a pontuacao que sobrou
    texto = re.sub(r"\s*\(\x00(?:,\s*\x00)*\)", "", texto)
    texto = re.sub(r",\s*\x00", "", texto)
    texto = re.sub(r"\x00,\s*", "", texto)
    texto = re.sub(r"\s*\x00", "", texto)
    texto = re.sub(r"\(\s*\)", "", texto)
    texto = re.sub(r"\(\s*,\s*", "(", texto)
    texto = re.sub(r"\s+,", ",", texto)
    texto = re.sub(r" {2,}", " ", texto)
    return re.sub(r" +$", "", texto, flags=re.M)


# --- expande o dominio -----------------------------------------------------
origens = []
for linha in (kb / "dominio.txt").read_text(encoding="utf-8").splitlines():
    linha = linha.strip()
    if not linha or linha.startswith("#"):
        continue
    padrao = linha if linha.endswith(".md") else linha + "*.md"
    origens += sorted(vault.glob(padrao))
origens = sorted(set(origens))

if not origens:
    sys.exit("nenhuma nota casou com knowledge-base/dominio.txt")

indice = {o.stem: ("pages" if o.parent.name == "Pages" else "docs", slug(o.stem))
          for o in origens}
zettels = {z.stem for z in (vault / "Zettels").glob("*.md")}

linhas, divergentes, novas = [], [], []
for origem in origens:
    sub = "pages" if origem.parent.name == "Pages" else "docs"
    destino = kb / sub / slug(origem.stem)
    bruto = origem.read_bytes()
    h = sha(bruto)
    linhas.append((f"{sub}/{destino.name}", f"{origem.parent.name}/{origem.name}", h))
    if verificar:
        if not destino.exists():
            novas.append(str(origem.relative_to(vault)))
        continue
    destino.parent.mkdir(parents=True, exist_ok=True)
    conteudo = tirar_zettels(bruto.decode("utf-8"))
    conteudo = resolver_wikilinks(conteudo, sub, indice, zettels)
    destino.write_text(conteudo, encoding="utf-8")

if verificar:
    atual = (kb / "MANIFESTO.md").read_text(encoding="utf-8")
    registrado = dict(re.findall(r"\| `([^`]+)` \| `[^`]+` \| `([^`]+)` \|", atual))
    for arquivo, origem, h in linhas:
        if registrado.get(arquivo) not in (h, None) :
            divergentes.append(f"{origem} mudou no vault (manifesto: {registrado[arquivo]}, agora: {h})")
        elif arquivo not in registrado:
            novas.append(origem)
    for d in divergentes:
        print("DIVERGENTE: " + d)
    for n in sorted(set(novas)):
        print("NOVA: " + n)
    print(f"verificado: {len(linhas)} notas · {len(divergentes)} divergentes · {len(set(novas))} novas")
    sys.exit(1 if divergentes or novas else 0)

# --- manifesto -------------------------------------------------------------
linhas.sort()
man = ["# Manifesto da knowledge-base", "",
       "Gerado por `build/sincronizar.sh`. Toda linha é cópia **gerada** do vault —",
       "para mudar a regra, edite a nota na origem e rode o script de novo.",
       "`bash build/sincronizar.sh --verificar` falha quando a origem mudou.", "",
       "Camadas: `docs/` é a regra (IDs canônicos), `pages/` são os mapas.",
       "O `Zettels/` do vault **não** é projetado, e as citações a ele são removidas",
       "do texto (decisão de 2026-09-22).", "",
       f"Origem: `{vault}` · o que entra: `knowledge-base/dominio.txt`", "",
       "| Arquivo | Origem no vault | sha256 |", "| --- | --- | --- |"]
man += [f"| `{a}` | `{o}` | `{h}` |" for a, o, h in linhas]
(kb / "MANIFESTO.md").write_text("\n".join(man) + "\n", encoding="utf-8")
print(f"sincronizado: {len(linhas)} notas -> {kb}")
PYEOF
