#!/usr/bin/env bash
# Confere os library IDs de build/context7.json contra o catalogo do Context7.
#
#   bash build/context7.sh --verificar   falha se um ID sumiu ou foi renomeado
#   bash build/context7.sh               lista o que cada skill declara
#
# ID errado no frontmatter falha em silencio no runtime: o agente pede a doc,
# nao vem nada, e ele responde de memoria. Por isso isto e verificavel.
set -uo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODO="${1:-listar}"

RAIZ="$RAIZ" MODO="$MODO" python3 <<'PYEOF'
import json, os, sys, urllib.parse, urllib.request, pathlib

raiz = pathlib.Path(os.environ["RAIZ"])
reg = json.loads((raiz / "build/context7.json").read_text(encoding="utf-8"))
verificar = os.environ["MODO"] == "--verificar"

if not verificar:
    for skill, libs in sorted(reg["skills"].items()):
        ids = " · ".join(reg["bibliotecas"][b]["id"] for b in libs if b in reg["bibliotecas"])
        print(f"  {skill:<22} {ids}")
    for skill, porque in sorted(reg["sem_biblioteca"].items()):
        print(f"  {skill:<22} — {porque}")
    sys.exit(0)


def buscar(termo):
    url = "https://context7.com/api/v1/search?" + urllib.parse.urlencode({"query": termo})
    with urllib.request.urlopen(url, timeout=20) as r:
        return json.load(r).get("results", [])


falhas = []
for chave, lib in sorted(reg["bibliotecas"].items()):
    try:
        achados = buscar(lib["titulo"])
    except Exception as e:
        print(f"[erro ] {chave}: não deu para consultar ({e.__class__.__name__})")
        falhas.append(chave)
        continue
    casado = next((r for r in achados if r.get("id") == lib["id"]), None)
    if not casado:
        outros = ", ".join(r.get("id", "?") for r in achados[:3])
        print(f"[FALHA] {chave}: `{lib['id']}` não aparece mais. Candidatos: {outros}")
        falhas.append(chave)
        continue
    agora, antes = casado.get("totalSnippets", 0), lib.get("snippets", 0)
    deriva = "" if not antes else f" (registro: {antes})"
    print(f"[ok   ] {chave:<16} {lib['id']:<38} snippets={agora}{deriva}")

print()
if falhas:
    print(f"{len(falhas)} biblioteca(s) com problema: " + ", ".join(falhas))
    sys.exit(1)
print(f"{len(reg['bibliotecas'])} bibliotecas confirmadas no catálogo")
PYEOF
