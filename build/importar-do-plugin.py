#!/usr/bin/env python3
"""Importa uma familia de skills (ou um agente) do build hermes para a fonte neutra.

    python3 build/importar-do-plugin.py test
    python3 build/importar-do-plugin.py --agente frontend-developer
    python3 build/importar-do-plugin.py --todas

Tres transformacoes:
  1. frontmatter do Claude Code -> frontmatter neutro (chaves em PT, capacidade
     no lugar de nome de ferramenta)
  2. links e globs de script apontando para o vault -> knowledge-base/
  3. citacoes a Zettels/ removidas do texto (decisao de 2026-09-22)

A knowledge-base NAO e tocada aqui: quem a projeta e build/sincronizar.sh, e o
MANIFESTO dela e a autoridade sobre onde cada nota mora.
"""
import re
import shutil
import sys
from pathlib import Path

CACHE = Path.home() / ".claude/plugins/cache/hermes"
RAIZ = Path(__file__).resolve().parent.parent

# familia -> (plugin, skills, nome do indice em referencias/familias/)
FAMILIAS = {
    "react": ("hermes-frontend/0.1.5",
              ["react-developer", "react-review", "react-structure", "react-hook-form"], "react"),
    "tanstack": ("hermes-frontend/0.1.5", ["tanstack-query", "tanstack-router"], "tanstack"),
    "storybook": ("hermes-frontend/0.1.5",
                  ["storybook-setup", "storybook-story", "storybook-test"], "storybook"),
    "test": ("hermes-core/0.1.10", ["teste-design", "teste-review", "teste-diagnose"], "teste"),
    "http": ("hermes-core/0.1.10",
             ["http-contract", "http-cache", "http-diagnose", "http-review"], "http"),
}
AGENTES = {"frontend-developer": "hermes-core/0.1.10"}

FERRAMENTA_PARA_CAPACIDADE = {"Read": "ler", "Write": "escrever", "Edit": "editar",
                              "Grep": "buscar", "Glob": "buscar", "Bash": "executar"}
MODELO_NEUTRO = {"opus": "alto", "sonnet": "medio", "haiku": "rapido"}
ACENTOS = str.maketrans("áãâéêíóõôúüç", "aaaeeiooouuc")


def slug(nome):
    return re.sub(r"[^a-z0-9]+", "-", nome.lower().translate(ACENTOS)).strip("-")


def indice_kb():
    """Do MANIFESTO: arquivo -> subpasta, e origem no vault -> (sub, arquivo)."""
    texto = (RAIZ / "knowledge-base/MANIFESTO.md").read_text(encoding="utf-8")
    por_arquivo, por_origem = {}, {}
    for sub_arq, origem in re.findall(r"\| `([^`]+)` \| `([^`]+)` \| `[^`]+` \|", texto):
        sub, arquivo = sub_arq.split("/", 1)
        por_arquivo[arquivo] = sub
        por_origem[origem] = (sub, arquivo)
        por_origem[Path(origem).stem] = (sub, arquivo)
    return por_arquivo, por_origem


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


def tirar_zettels(texto):
    z = r"`Zettels/[^`]*\.md`"
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


def resolver_wikilinks(texto, subidas, por_arquivo, por_origem):
    """[[Nota]] -> link para a knowledge-base; dentro de bloco de codigo, texto puro.

    `[[...]]` so significa alguma coisa dentro do Obsidian. Fora dele e ruido,
    e dentro de bloco de codigo um link markdown seria pior que o ruido.
    """
    saida, em_bloco = [], False
    for linha in texto.splitlines():
        if linha.lstrip().startswith("```"):
            em_bloco = not em_bloco
            saida.append(linha)
            continue

        def alvo(m):
            nome = m.group(1).strip()
            rotulo = (m.group(3) or nome).strip()
            if em_bloco:
                return rotulo
            destino = por_origem.get(nome)
            if not destino:
                return f"`{rotulo}`"
            sub, arquivo = destino
            return f"[{rotulo}]({'../' * subidas}knowledge-base/{sub}/{arquivo})"

        saida.append(re.sub(r"\[\[([^\]|#]+?)(#[^\]|]+)?(?:\|([^\]]+))?\]\]", alvo, linha))
    return "\n".join(saida) + ("\n" if texto.endswith("\n") else "")


def reescrever_links(texto, subidas, por_arquivo):
    """../../referencias/X.md -> <subidas>knowledge-base/<sub>/X.md.

    Referencia fora deste recorte da knowledge-base vira code span: existe no
    vault, mas nao aqui, e link quebrado e pior que citacao textual.
    """
    def troca(m):
        arquivo, rotulo = m.group(2), m.group(1)
        sub = por_arquivo.get(arquivo)
        if not sub:
            return f"`{rotulo}`"
        return f"[{rotulo}]({'../' * subidas}knowledge-base/{sub}/{arquivo})"
    return re.sub(r"\[([^\]]*)\]\((?:\.\./)+referencias/([^)]+\.md)\)", troca, texto)


def ajustar_script(texto):
    """Repoe o vault pela knowledge-base, inclusive nos globs por nome de nota."""
    texto = texto.replace(
        'VAULT="${1:-$HOME/Sync/Vaults/Notes}"',
        'BASE="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)/knowledge-base}"')
    texto = texto.replace('DOCS="$VAULT/Docs"', 'DOCS="$BASE/docs"')
    texto = texto.replace('PAGES="$VAULT/Pages"', 'PAGES="$BASE/pages"')
    texto = re.sub(r'FONTE="\$VAULT/Pages/([^"]+)\.md"',
                   lambda m: f'FONTE="$BASE/pages/{slug(m.group(1))}.md"', texto)

    # o arquivo na knowledge-base e slug: "Teste de Software*.md" -> "teste-de-software*.md"
    def troca_glob(m):
        aspas, nome, glob = m.group(1), m.group(2), m.group(3)
        return f'$DOCS{aspas}/{slug(nome.replace(chr(92) + " ", " "))}{glob}.md'
    texto = re.sub(r'\$DOCS("?)/((?:[^/*"\n]|\\ )+?)(\*?)\.md', troca_glob, texto)
    return texto


def frontmatter_skill(campos, corpo, nome, familia):
    novo = ["---", f"nome: {nome}", f"descricao: {campos['description']}",
            "tipo: skill", f"familia: {familia}"]
    if campos.get("fonte"):
        novo.append(f"fonte: {campos['fonte']}")
    if campos.get("tags__lista"):
        novo.append("tags:")
        novo += [f"  - {t}" for t in campos["tags__lista"]]
    novo.append("---\n")
    return "\n".join(novo) + corpo


def frontmatter_agente(campos, corpo):
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
        if campos.get(lista + "__lista"):
            novo.append(f"{lista}:")
            novo += [f"  - {i}" for i in campos[lista + "__lista"]]
    novo.append("---\n")
    return "\n".join(novo) + corpo


def importar_familia(familia, por_arquivo, por_origem):
    plugin, skills, indice = FAMILIAS[familia]
    origem_plugin = CACHE / plugin
    for skill in skills:
        origem, destino = origem_plugin / "skills" / skill, RAIZ / "skills" / familia / skill
        if destino.exists():
            shutil.rmtree(destino)
        shutil.copytree(origem, destino)
        for arq in sorted(destino.rglob("*")):
            if not arq.is_file():
                continue
            texto = arq.read_text(encoding="utf-8")
            if arq.suffix == ".md":
                # profundidade ate a raiz: SKILL.md=3, references/X.md=4
                subidas = len(arq.relative_to(RAIZ).parts) - 1
                texto = tirar_zettels(texto)
                texto = reescrever_links(texto, subidas, por_arquivo)
                texto = resolver_wikilinks(texto, subidas, por_arquivo, por_origem)
                if arq.name == "SKILL.md":
                    campos, corpo = partir(texto)
                    texto = frontmatter_skill(campos, corpo, skill, familia)
                arq.write_text(texto, encoding="utf-8")
            elif arq.suffix == ".sh":
                arq.write_text(ajustar_script(texto), encoding="utf-8")
                arq.chmod(0o755)

    mapa = origem_plugin / "referencias/familias" / f"{indice}.md"
    if mapa.exists():
        texto = tirar_zettels(mapa.read_text(encoding="utf-8"))
        texto = re.sub(r"\[([^\]]*)\]\(\.\./([^)/]+\.md)\)",
                       lambda m: (f"[{m.group(1)}](../../knowledge-base/"
                                  f"{por_arquivo[m.group(2)]}/{m.group(2)})"
                                  if m.group(2) in por_arquivo else f"`{m.group(1)}`"), texto)
        texto = re.sub(r"\[([^\]]*)\]\((?:\.\./)+pages/catalogo-de-skills\.md\)",
                       r"[\1](../README.md)", texto)
        texto = resolver_wikilinks(texto, 2, por_arquivo, por_origem)
        (RAIZ / "skills" / familia / "README.md").write_text(texto, encoding="utf-8")
    print(f"familia {familia}: {len(skills)} skills")


def importar_agente(nome, por_arquivo, por_origem):
    texto = (CACHE / AGENTES[nome] / "agents" / f"{nome}.md").read_text(encoding="utf-8")
    texto = tirar_zettels(texto)
    texto = re.sub(r"`((?:Docs|Pages)/[^`]+\.md)`",
                   lambda m: (f"[{Path(m.group(1)).stem}](../knowledge-base/"
                              f"{por_origem[m.group(1)][0]}/{por_origem[m.group(1)][1]})"
                              if m.group(1) in por_origem else m.group(0)), texto)
    texto = re.sub(r"\[([^\]]*)\]\((?:\.\./)+pages/catalogo-de-skills\.md\)",
                   r"[Skills](../skills/README.md)", texto)
    texto = resolver_wikilinks(texto, 1, por_arquivo, por_origem)
    campos, corpo = partir(texto)
    (RAIZ / "agents" / f"{nome}.md").write_text(frontmatter_agente(campos, corpo),
                                                encoding="utf-8")
    print(f"agente {nome}")


def main():
    args = sys.argv[1:]
    if not args:
        sys.exit(__doc__)
    por_arquivo, por_origem = indice_kb()
    if args[0] == "--todas":
        for familia in FAMILIAS:
            if (RAIZ / "skills" / familia).exists():
                importar_familia(familia, por_arquivo, por_origem)
        for agente in AGENTES:
            importar_agente(agente, por_arquivo, por_origem)
    elif args[0] == "--agente":
        importar_agente(args[1], por_arquivo, por_origem)
    else:
        for familia in args:
            importar_familia(familia, por_arquivo, por_origem)


main()
