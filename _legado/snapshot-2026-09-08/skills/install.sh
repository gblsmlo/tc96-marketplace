#!/usr/bin/env bash
# Instala as skills empacotadas (Skills/<familia>/<skill>/) em ~/.claude/skills/<nome>/,
# resolvendo wikilinks. Arquivo solto em Skills/*.md continua sendo instalado à mão.
#
# Regra de resolução, conforme Skills/README.md:
#   [[outra-skill]]  -> link para o SKILL.md instalado dela
#   [[Nota]]         -> link para o caminho absoluto da nota em Docs/ ou Pages/
#   sem correspondência -> fica como está (é prosa, não link)
set -euo pipefail

VAULT="${VAULT:-$HOME/Sync/Vaults/Notes}"
DEST="${DEST:-$HOME/.claude/skills}"
SRC="$VAULT/Skills"

RESOLVER="$(mktemp -t resolver-wikilink)"
trap 'rm -f "$RESOLVER"' EXIT
cat > "$RESOLVER" <<'PYEOF'
import os, re, sys, pathlib

vault, dest = pathlib.Path(os.environ["VAULT"]), pathlib.Path(os.environ["DEST"])
skills = {p.stem for p in (vault / "Skills").glob("*.md") if p.stem != "README"}
skills |= {p.name for p in (vault / "Skills").rglob("*") if (p / "SKILL.md").exists()}
skills |= {p.name for p in dest.glob("*") if (p / "SKILL.md").exists()}


# Skill instalada e nota do vault viram code span, nao link markdown: o skill-validator
# resolve qualquer href relativo ao diretorio da skill e marcaria caminho absoluto como
# "broken internal link". O rodape de cada arquivo diz onde as notas moram.


def troca(m):
    nome, alias = m.group(1), m.group(2)
    if nome in skills:
        return f"`{nome}`"
    for sub in ("Docs", "Pages", "Zettels"):
        if (vault / sub / f"{nome}.md").exists():
            return f"`{sub}/{nome}.md`"
    return m.group(0)


sys.stdout.write(re.sub(r"\[\[([^\]|#]+?)(?:\|([^\]]+))?\]\]", troca, sys.stdin.read()))
PYEOF

for skill in "$SRC"/*/*/; do
  nome="$(basename "$skill")"
  [ -f "$skill/SKILL.md" ] || continue
  rm -rf "${DEST:?}/$nome"
  mkdir -p "$DEST/$nome"
  while IFS= read -r arq; do
    mkdir -p "$DEST/$nome/$(dirname "$arq")"
    VAULT="$VAULT" DEST="$DEST" python3 "$RESOLVER" < "$skill/$arq" > "$DEST/$nome/$arq"
    printf '\n---\n\nSkills citadas em `crase` sao invocaveis pelo nome. Notas `Docs/…` e `Pages/…` moram em `%s/`.\n' "$VAULT" >> "$DEST/$nome/$arq"
  done < <(cd "$skill" && find . -type f -name '*.md')
  if [ -d "$skill/scripts" ]; then
    mkdir -p "$DEST/$nome/scripts"
    cp -p "$skill"/scripts/*.sh "$DEST/$nome/scripts/" 2>/dev/null || true
  fi
  echo "instalado: $DEST/$nome  ($(find "$DEST/$nome" -type f | wc -l | tr -d ' ') arquivos)"
done
