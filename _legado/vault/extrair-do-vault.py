# -*- coding: utf-8 -*-
"""Extracao unica do vault para knowledge-base/. Provenance, nao build."""
import os, re, sys, pathlib

RAIZ = pathlib.Path("/home/gabs/Workspaces")
VAULT = pathlib.Path("/home/gabs/Sync/Vaults/Notes")
KB = RAIZ / "knowledge-base"
SECO = "--seco" in sys.argv

ACENTOS = str.maketrans("áãâéêíóõôúüç", "aaaeeiooouuc")
def slug(nome):
    return re.sub(r"[^a-z0-9]+", "-", nome.lower().translate(ACENTOS)).strip("-") + ".md"

def tirar_zettels(texto):
    z = r"`Zettels/[^`]*\.md`"
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
    def alvo(m):
        nome, secao, alias = m.group(1).strip(), m.group(2), m.group(3)
        rotulo = (alias or nome).strip()
        if nome in zettels:
            return "\x00"
        destino = indice.get(nome)
        if not destino:
            return f"`{rotulo}`"
        sub, arquivo = destino
        prefixo = "" if sub == sub_atual else f"../{sub}/"
        return f"[{rotulo}]({prefixo}{arquivo})" + (f" {secao}" if secao else "")
    texto = re.sub(r"\[\[([^\]|#]+?)(#[^\]|]+)?(?:\|([^\]]+))?\]\]", alvo, texto)
    def ancora(m):
        alvo_, rot = m.group(1), (m.group(2) or m.group(1)).strip()
        frag = re.sub(r"[^a-z0-9]+", "-", alvo_.lower().translate(ACENTOS)).strip("-")
        return f"[{rot}](#{frag})"
    texto = re.sub(r"\[\[#([^\]|]+?)(?:\|([^\]]+))?\]\]", ancora, texto)
    texto = re.sub(r"\s*\(\x00(?:,\s*\x00)*\)", "", texto)
    texto = re.sub(r",\s*\x00", "", texto)
    texto = re.sub(r"\x00,\s*", "", texto)
    texto = re.sub(r"\s*\x00", "", texto)
    texto = re.sub(r"\(\s*\)", "", texto)
    texto = re.sub(r"\(\s*,\s*", "(", texto)
    texto = re.sub(r"\s+,", ",", texto)
    texto = re.sub(r" {2,}", " ", texto)
    return re.sub(r" +$", "", texto, flags=re.M)

def tirar_links_de_fora(texto, arquivos):
    """[rotulo](../Areas/X.md) -> rotulo. Nada aqui aponta para fora do projeto."""
    def alvo(m):
        rotulo, destino = m.group(1), m.group(2)
        if destino.split("/")[-1] in arquivos:
            return m.group(0)
        return rotulo
    # o destino pode ter parenteses no nome ("... (SPA).md"): aceita um nivel
    return re.sub(r"\[([^\]]+)\]\((\.\.?/(?:[^()\s]|\([^()]*\))+\.md)\)", alvo, texto)


def com_titulo(texto, titulo):
    if re.match(r"^---\n", texto):
        if re.search(r"^titulo:", texto, re.M):
            return texto
        return re.sub(r"^---\n", f"---\ntitulo: {titulo}\n", texto, count=1)
    return f"---\ntitulo: {titulo}\n---\n\n" + texto

origens = []
for linha in (RAIZ / "build/dominio.txt").read_text(encoding="utf-8").splitlines():
    linha = linha.strip()
    if not linha or linha.startswith("#"):
        continue
    padrao = linha if linha.endswith(".md") else linha + "*.md"
    achou = sorted(VAULT.glob(padrao))
    if not achou:
        print(f"  ! sem correspondencia: {linha}")
    origens += achou
origens = sorted({o for o in origens if o.stat().st_size > 200})

indice = {o.stem: ("pages" if o.parent.name == "Pages" else "docs", slug(o.stem)) for o in origens}
zettels = {z.stem for z in (VAULT / "Zettels").glob("*.md")}
arquivos = {a for _, a in indice.values()}

novas, iguais, mudadas = [], 0, []
for origem in origens:
    sub = "pages" if origem.parent.name == "Pages" else "docs"
    destino = KB / sub / slug(origem.stem)
    conteudo = resolver_wikilinks(tirar_zettels(origem.read_text(encoding="utf-8")), sub, indice, zettels)
    conteudo = com_titulo(tirar_links_de_fora(conteudo, arquivos), origem.stem)
    if not destino.exists():
        novas.append(f"{sub}/{destino.name}")
    elif destino.read_text(encoding="utf-8") == conteudo:
        iguais += 1
    else:
        mudadas.append(f"{sub}/{destino.name}")
    if not SECO:
        destino.parent.mkdir(parents=True, exist_ok=True)
        destino.write_text(conteudo, encoding="utf-8")

print(f"origens: {len(origens)} · novas: {len(novas)} · iguais: {iguais} · mudadas: {len(mudadas)}")
for m in mudadas[:12]: print("  muda:", m)
for n in novas[:60]: print("  nova:", n)
