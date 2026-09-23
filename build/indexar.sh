#!/usr/bin/env bash
# Regenera knowledge-base/MANIFESTO.md a partir das proprias notas do projeto.
#
#   bash build/indexar.sh             reescreve o MANIFESTO
#   bash build/indexar.sh --verificar nao escreve; falha se o indice estiver velho
#
# A knowledge-base e conteudo do projeto, nao projecao de um vault: o indice e
# derivado do que esta em knowledge-base/, e de mais nada fora daqui.
set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODO="${1:-}"

RAIZ="$RAIZ" MODO="$MODO" python3 <<'PYEOF'
import hashlib, os, re, sys, pathlib

raiz = pathlib.Path(os.environ["RAIZ"])
base = raiz / "knowledge-base"
alvo = base / "MANIFESTO.md"
verificar = os.environ.get("MODO") == "--verificar"

def titulo_de(p):
    m = re.match(r"^---\n(.*?)\n---\n", p.read_text(encoding="utf-8"), re.S)
    if m:
        t = re.search(r"^titulo:\s*(.+)$", m.group(1), re.M)
        if t:
            return t.group(1).strip()
    return p.stem

notas = sorted(p for p in base.glob("*.md") if p.name != "MANIFESTO.md")
linhas = []
for p in notas:
    rel = p.relative_to(base).as_posix()
    sha = hashlib.sha256(p.read_bytes()).hexdigest()[:12]
    linhas.append(f"| `{rel}` | {titulo_de(p)} | `{sha}` |")

texto = f"""# Manifesto da knowledge-base

Indice gerado por `build/indexar.sh` a partir das notas deste repositorio.
`bash build/indexar.sh --verificar` falha quando o indice esta velho.

Uma camada so: cada nota mora direto em `knowledge-base/`, sem subpasta. O
titulo de cada nota vem do campo `titulo:` no proprio arquivo — e o rotulo
que as skills usam ao linkar para ela.

Notas: {len(notas)}

| Arquivo | Titulo | sha256 |
| --- | --- | --- |
""" + "\n".join(linhas) + "\n"

if verificar:
    atual = alvo.read_text(encoding="utf-8") if alvo.exists() else ""
    if atual != texto:
        print("MANIFESTO velho: rode bash build/indexar.sh")
        sys.exit(1)
    print(f"indice em dia: {len(notas)} notas")
else:
    alvo.write_text(texto, encoding="utf-8")
    print(f"MANIFESTO regenerado: {len(notas)} notas")
PYEOF
