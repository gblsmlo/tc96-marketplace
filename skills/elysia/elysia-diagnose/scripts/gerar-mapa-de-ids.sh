#!/usr/bin/env bash
# Regenerates references/mapa-de-ids.md for the three Elysia skills, from elysia*.
# An index, not a copy: ID -> satellite -> section.
set -euo pipefail

BASE="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)/knowledge-base}"
# The map is generated at authoring time and committed: source and destination are
# both this repository (pass another knowledge-base path as $1 if you need to).
FAMILIA="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DOCS="$BASE"

# Title of each note, from the `titulo:` field in the file itself — the link label.
titulos() {
  awk 'FNR == 1 { nome = FILENAME; sub(/.*\//, "", nome); sub(/\.md$/, "", nome) }
       /^titulo: / { print nome "\t" substr($0, 9); nextfile }' "$DOCS"/*.md
}

# Rewrites a note's own relative links to how they are seen from
# <family>/<skill>/references/ — nothing here points outside the project.
links() {
  sed -E -e 's#\]\(\.\./pages/#](../../../../knowledge-base/#g' \
         -e 's#\]\(([^)/]+\.md)#](../../../../knowledge-base/\1#g'
}
HUB="$DOCS/elysia.md"

scan() {
  for f in "$DOCS"/elysia*.md; do
    base="$(basename "$f" .md)"
    awk -v sat="$base" -v hub="elysia" '
      /^## / { h2 = $0; sub(/^## /, "", h2) }
      /^#{2,4} / { h = $0; sub(/^#+ /, "", h) }
      {
        if (match($0, /ELYSIA-[A-Z0-9]+-[0-9]+/) == 0) next
        id = substr($0, RSTART, RLENGTH)
        rank = -1
        if ($0 ~ /^#{2,4} `ELYSIA-[A-Z0-9]+-[0-9]+`/)   rank = 0
        else if ($0 ~ /^\| `ELYSIA-[A-Z0-9]+-[0-9]+`/) {
          if ($0 ~ /MUST|NEVER/) rank = (sat == hub ? 2 : 1)
          else                   rank = 3
        }
        if (rank < 0) next
        sec = (rank == 3 ? h : h2)
        printf "%s\t%d\t%s\t%s\n", id, rank, sat, (sec == "" ? "—" : sec)
      }
    ' "$f"
  done
}

TMP="$(mktemp)"
{
  echo "---"
  echo "gerado-por: skills/elysia/elysia-diagnose/scripts/gerar-mapa-de-ids.sh"
  echo "gerado-em: $(date +%F)"
  echo "---"
  echo
  echo "# ID map \`ELYSIA-*\`"
  echo
  echo "> An index, not a copy: it says **where** the rule is declared, never what it says."
  echo "> Regenerate with \`bash skills/elysia/elysia-diagnose/scripts/gerar-mapa-de-ids.sh\` —"
  echo "> the same file is written into all three Elysia skills."
  echo
  echo "## Partial aliases — this family's quirk"
  echo
  awk '/^### 6\.2/,/^### Famílias/' "$HUB" | grep -vE '^### ' | cat -s | links || true
  echo
  echo "## Full index"
  echo
  echo "| ID | Declared in | Body in the satellite | Section of the body |"
  echo "| --- | --- | --- | --- |"
  scan | sort -t$'\t' -k1,1 -k2,2n \
    | awk -F'\t' -v hub="elysia" '
    function nota(s) { return "[" (s in titulo ? titulo[s] : s) "](../../../../knowledge-base/" s ".md)" }
    NR == FNR { titulo[$1] = $2; next }
    {
      if (!( $1 in decl )) { decl[$1] = $3; ordem[++k] = $1 }
      if ($3 != hub && !( $1 in corpo )) { corpo[$1] = $3; sec[$1] = $4 }
    }
    END {
      for (i = 1; i <= k; i++) {
        id = ordem[i]
        printf "| `%s` | %s | %s | %s |\n", id, nota(decl[id]),
          (id in corpo ? nota(corpo[id]) : "— (ELYSIA-APP-* family, hub only)"),
          (id in sec ? sec[id] : "—")
      }
    }' <(titulos) -
} > "$TMP"

for s in build schema diagnose; do
  cp "$TMP" "$FAMILIA/elysia-$s/references/mapa-de-ids.md"
done
rm -f "$TMP"
echo "written into 3 skills ($(grep -c '^| `ELYSIA' "$FAMILIA/elysia-build/references/mapa-de-ids.md") IDs)"
