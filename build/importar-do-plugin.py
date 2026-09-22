#!/usr/bin/env python3
"""Migra o frontend do build hermes-frontend/0.1.5 para a fonte neutra em Workspaces/.

Tres transformacoes:
  1. frontmatter Claude Code -> frontmatter neutro (chaves em PT, capacidades no lugar de tools)
  2. links ../../referencias/X.md -> ../../../knowledge-base/{docs,pages}/X.md
  3. citacoes de Zettels/ removidas do texto (decisao de 2026-09-22)
"""
import hashlib
import re
import shutil
import sys
from pathlib import Path

PLUGIN_FE = Path.home() / ".claude/plugins/cache/hermes/hermes-frontend/0.1.5"
PLUGIN_CORE = Path.home() / ".claude/plugins/cache/hermes/hermes-core/0.1.10"
VAULT = Path.home() / "Sync/Vaults/Notes"
DEST = Path("/home/gabs/Workspaces")

FAMILIA = {
    "react-developer": "react", "react-review": "react",
    "react-structure": "react", "react-hook-form": "react",
    "tanstack-query": "tanstack", "tanstack-router": "tanstack",
    "storybook-setup": "storybook", "storybook-story": "storybook",
    "storybook-test": "storybook",
}
AGENTES = ["frontend-developer"]
# notas citadas que o build 0.1.5 nao projetou
EXTRA_PAGES = ["Frontend roadmap"]


def ler_manifesto():
    """referencia -> (subpasta destino, titulo, caminho no vault)."""
    mapa = {}
    texto = (PLUGIN_FE / "referencias/MANIFESTO.md").read_text(encoding="utf-8")
    for linha in texto.splitlines():
        m = re.match(r"\|\s*`referencias/([^`]+)`\s*\|\s*`([^`]+)`\s*\|", linha)
        if not m:
            continue
        arquivo, origem = m.group(1), m.group(2)
        sub = "pages" if origem.startswith("Pages/") else "docs"
        titulo = Path(origem).stem
        mapa[arquivo] = (sub, titulo, origem)
    return mapa


def sha(caminho):
    return hashlib.sha256(caminho.read_bytes()).hexdigest()[:12]


def slug(titulo):
    s = titulo.lower()
    for de, para in [("á", "a"), ("ã", "a"), ("â", "a"), ("é", "e"), ("ê", "e"),
                     ("í", "i"), ("ó", "o"), ("õ", "o"), ("ô", "o"), ("ú", "u"),
                     ("ç", "c")]:
        s = s.replace(de, para)
    s = re.sub(r"[^a-z0-9]+", "-", s).strip("-")
    return s + ".md"


def tirar_wikilink(texto):
    """[[Nome]] -> Nome.

    O que sobra de wikilink nas skills esta dentro de bloco de codigo (as
    especificacoes de carregamento minimo). E texto literal citando o nome da
    nota, nao link — e `[[...]]` so significa alguma coisa dentro do Obsidian.
    """
    return re.sub(r"\[\[([^\]|#]+?)(?:\|([^\]]+))?\]\]",
                  lambda m: (m.group(2) or m.group(1)), texto)


def tirar_zettels(texto):
    """Remove citacoes de Zettels e limpa a pontuacao que sobra."""
    z = r"`Zettels/[^`]*\.md`"
    # parentese que so continha zettels: "(`Z1`, `Z2`)" -> some
    texto = re.sub(r"\s*\((?:" + z + r")(?:,\s*(?:" + z + r"))*\)", "", texto)
    # zettel dentro de parentese com outras coisas: "(`ID`, `Z`)" -> "(`ID`)"
    texto = re.sub(r",\s*" + z, "", texto)
    texto = re.sub(z + r",\s*", "", texto)
    # sobra solta
    texto = re.sub(r"\s*" + z, "", texto)
    # limpeza de pontuacao orfa
    texto = re.sub(r"\(\s*\)", "", texto)
    texto = re.sub(r"\(\s*,\s*", "(", texto)
    texto = re.sub(r"\s+,", ",", texto)
    texto = re.sub(r" {2,}", " ", texto)
    texto = re.sub(r" +\.", ".", texto)
    texto = re.sub(r" +$", "", texto, flags=re.M)
    return texto


def reescrever_links(texto, extra_nivel, mapa):
    """../../referencias/X.md -> ../../../knowledge-base/<sub>/X.md"""
    def troca(m):
        subidas, arquivo = m.group(1), m.group(2)
        sub = mapa.get(arquivo, ("docs", "", ""))[0]
        return f"]({subidas}{'../' * extra_nivel}knowledge-base/{sub}/{arquivo})"
    return re.sub(r"\]\(((?:\.\./)+)referencias/([^)]+\.md)\)", troca, texto)


def frontmatter_skill(texto, nome, familia, mapa):
    """name/description/tags/fonte -> nome/descricao/tipo/familia/fonte/tags."""
    m = re.match(r"^---\n(.*?)\n---\n", texto, re.S)
    if not m:
        sys.exit(f"sem frontmatter: {nome}")
    corpo, resto = m.group(1), texto[m.end():]
    campos, chave = {}, None
    for linha in corpo.splitlines():
        cm = re.match(r"^(\w+):\s*(.*)$", linha)
        if cm:
            chave = cm.group(1)
            campos[chave] = cm.group(2)
        elif chave and linha.startswith(" "):
            campos.setdefault(chave + "__lista", []).append(linha.strip().lstrip("- "))
    novo = ["---", f"nome: {nome}", f"descricao: {campos.get('description', '')}",
            "tipo: skill", f"familia: {familia}"]
    if campos.get("fonte"):
        novo.append(f"fonte: {campos['fonte']}")
    tags = campos.get("tags__lista", [])
    if tags:
        novo.append("tags:")
        novo += [f"  - {t}" for t in tags]
    novo.append("---\n")
    return "\n".join(novo) + resto


FERRAMENTA_PARA_CAPACIDADE = {"Read": "ler", "Write": "escrever", "Edit": "editar",
                              "Grep": "buscar", "Glob": "buscar", "Bash": "executar"}
MODELO_NEUTRO = {"opus": "alto", "sonnet": "medio", "haiku": "rapido"}


def frontmatter_agente(texto):
    """tools/model do Claude Code -> capacidades/modelo neutros."""
    m = re.match(r"^---\n(.*?)\n---\n", texto, re.S)
    corpo, resto = m.group(1), texto[m.end():]
    campos, chave = {}, None
    for linha in corpo.splitlines():
        cm = re.match(r"^(\w+):\s*(.*)$", linha)
        if cm:
            chave = cm.group(1)
            campos[chave] = cm.group(2)
        elif chave and linha.startswith(" "):
            campos.setdefault(chave + "__lista", []).append(linha.strip().lstrip("- "))
    caps = []
    for f in [x.strip() for x in campos.get("tools", "").split(",") if x.strip()]:
        c = FERRAMENTA_PARA_CAPACIDADE.get(f)
        if c and c not in caps:
            caps.append(c)
    novo = ["---", f"nome: {campos['name']}", f"descricao: {campos['description']}",
            "tipo: agente", "capacidades:"]
    novo += [f"  - {c}" for c in caps]
    novo.append(f"modelo: {MODELO_NEUTRO.get(campos.get('model', ''), 'alto')}")
    for lista in ("skills", "fontes", "tags"):
        itens = campos.get(lista + "__lista", [])
        if itens:
            novo.append(f"{lista}:")
            novo += [f"  - {i}" for i in itens]
    novo.append("---\n")
    return "\n".join(novo) + resto


def main():
    mapa = ler_manifesto()
    (DEST / "knowledge-base/docs").mkdir(parents=True, exist_ok=True)
    (DEST / "knowledge-base/pages").mkdir(parents=True, exist_ok=True)

    # --- 1. knowledge-base --------------------------------------------------
    linhas_manifesto, sem_origem = [], []
    for arquivo, (sub, titulo, origem) in sorted(mapa.items()):
        origem_vault = VAULT / origem
        destino = DEST / "knowledge-base" / sub / arquivo
        if origem_vault.exists():
            shutil.copy2(origem_vault, destino)
            h = sha(origem_vault)
        else:
            shutil.copy2(PLUGIN_FE / "referencias" / arquivo, destino)
            h = "—"
            sem_origem.append(origem)
        linhas_manifesto.append((f"{sub}/{arquivo}", origem, h))

    for titulo in EXTRA_PAGES:
        origem_vault = VAULT / "Pages" / f"{titulo}.md"
        if origem_vault.exists():
            arquivo = slug(titulo)
            shutil.copy2(origem_vault, DEST / "knowledge-base/pages" / arquivo)
            mapa[arquivo] = ("pages", titulo, f"Pages/{titulo}.md")
            linhas_manifesto.append((f"pages/{arquivo}", f"Pages/{titulo}.md", sha(origem_vault)))
        else:
            sem_origem.append(f"Pages/{titulo}.md")

    # limpa zettels e reescreve links internos da knowledge-base
    for nota in (DEST / "knowledge-base").rglob("*.md"):
        t = tirar_zettels(nota.read_text(encoding="utf-8"))
        nota.write_text(t, encoding="utf-8")

    linhas_manifesto.sort()
    man = ["# Manifesto da knowledge-base", "",
           "Gerado por `build/sincronizar.sh`. Toda linha é cópia **gerada** do vault —",
           "para mudar a regra, edite a nota na origem e rode o script de novo.",
           "`--verificar` falha quando a origem mudou.", "",
           "Camadas: `docs/` é a regra (IDs canônicos), `pages/` são os mapas.",
           "O `Zettels/` do vault **não** é projetado (decisão de 2026-09-22).", "",
           "| Arquivo | Origem no vault | sha256 |", "| --- | --- | --- |"]
    man += [f"| `{a}` | `{o}` | `{h}` |" for a, o, h in linhas_manifesto]
    (DEST / "knowledge-base/MANIFESTO.md").write_text("\n".join(man) + "\n", encoding="utf-8")

    # --- 2. skills ----------------------------------------------------------
    for skill, familia in sorted(FAMILIA.items()):
        origem = PLUGIN_FE / "skills" / skill
        destino = DEST / "skills" / familia / skill
        if destino.exists():
            shutil.rmtree(destino)
        shutil.copytree(origem, destino)
        for arq in destino.rglob("*"):
            if not arq.is_file():
                continue
            if arq.suffix == ".md":
                t = arq.read_text(encoding="utf-8")
                t = tirar_zettels(t)
                t = tirar_wikilink(t)
                nivel = 1  # +1 por causa do diretorio de familia
                t = reescrever_links(t, nivel, mapa)
                if arq.name == "SKILL.md":
                    t = frontmatter_skill(t, skill, familia, mapa)
                arq.write_text(t, encoding="utf-8")
            elif arq.suffix == ".sh":
                t = arq.read_text(encoding="utf-8")
                t = t.replace('VAULT="${1:-$HOME/Sync/Vaults/Notes}"',
                              'BASE="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)/knowledge-base}"')
                t = t.replace('DOCS="$VAULT/Docs"', 'DOCS="$BASE/docs"')
                t = t.replace('FONTE="$VAULT/Pages/Feature-Based Architecture.md"',
                              'FONTE="$BASE/pages/feature-based-architecture.md"')
                arq.write_text(t, encoding="utf-8")
                arq.chmod(0o755)

    # --- 3. README de familia (vem de referencias/familias/) ----------------
    for fam_md in (PLUGIN_FE / "referencias/familias").glob("*.md"):
        familia = fam_md.stem
        t = tirar_zettels(fam_md.read_text(encoding="utf-8"))
        # familias/X.md apontava para ../NOME.md dentro de referencias/
        def troca_fam(m):
            arquivo = m.group(1)
            sub = mapa.get(arquivo, ("docs", "", ""))[0]
            return f"](../../knowledge-base/{sub}/{arquivo})"
        t = re.sub(r"\]\(\.\./([^)/]+\.md)\)", troca_fam, t)
        t = re.sub(r"\]\((?:\.\./)+pages/catalogo-de-skills\.md\)", "](../README.md)", t)
        (DEST / "skills" / familia / "README.md").write_text(t, encoding="utf-8")

    # --- 4. agentes ---------------------------------------------------------
    por_origem = {origem: (sub, titulo, arquivo)
                  for arquivo, (sub, titulo, origem) in mapa.items()}
    for agente in AGENTES:
        t = (PLUGIN_CORE / "agents" / f"{agente}.md").read_text(encoding="utf-8")
        t = tirar_zettels(t)

        def troca_span(m):
            origem = m.group(1)
            if origem not in por_origem:
                return m.group(0)
            sub, titulo, arquivo = por_origem[origem]
            return f"[{titulo}](../knowledge-base/{sub}/{arquivo})"
        t = re.sub(r"`((?:Docs|Pages)/[^`]+\.md)`", troca_span, t)
        t = t.replace("[Skill](../../../pages/catalogo-de-skills.md)",
                      "[Skills](../skills/README.md)")
        t = frontmatter_agente(t)
        (DEST / "agents" / f"{agente}.md").write_text(t, encoding="utf-8")

    print(f"knowledge-base: {len(linhas_manifesto)} notas")
    print(f"skills: {len(FAMILIA)} em {len(set(FAMILIA.values()))} familias")
    if sem_origem:
        print("SEM ORIGEM NO VAULT (copiado do build):")
        for o in sorted(set(sem_origem)):
            print(f"  {o}")


main()
