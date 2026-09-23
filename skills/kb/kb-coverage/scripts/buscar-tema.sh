#!/usr/bin/env bash
# Searches knowledge-base/ and every skill's frontmatter for a topic, and prints ranked
# candidates: direct text hits, hits with a rule ID nearby, skills whose description
# matches, and skills whose `fonte:` points at a matched doc.
#
# It finds candidates. It does not judge coverage — that is Step 3 in SKILL.md
# (references/mentioned-vs-developed.md). A hit here is a lead, not a verdict.
set -u

TEMA="${1:-}"
if [ -z "$TEMA" ]; then
  echo "usage: buscar-tema.sh \"<tema>\" [<repo-root>]" >&2
  echo 'tip: the term is matched as extended regex (grep -E) — a literal "+" or "."' >&2
  echo '     needs escaping, or rerun with -F semantics by quoting a plain phrase.' >&2
  exit 1
fi

RAIZ="${2:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)}"
KB="$RAIZ/knowledge-base"
SKILLS="$RAIZ/skills"
AGENTES="$RAIZ/agents"

[ -d "$KB" ] || { echo "knowledge-base not found at $KB" >&2; exit 1; }

echo "# Search: \"$TEMA\""
echo "root: $RAIZ"
echo

echo "## 1. Direct hits in knowledge-base/"
echo
HITS="$(grep -rniE --exclude=MANIFESTO.md -- "$TEMA" "$KB" 2>/dev/null)"
if [ -z "$HITS" ]; then
  echo "(none — try a narrower term, the other language, or a concrete symptom instead"
  echo " of the concept name; see SKILL.md Step 2)"
else
  echo "$HITS" | sed "s#$KB/#  #"
fi
echo

echo "## 2. Rule IDs within 3 lines of a hit"
echo
IDHITS="$(grep -rniE -B3 -A3 --exclude=MANIFESTO.md -- "$TEMA" "$KB" 2>/dev/null | grep -E '`[A-Z]+(-[A-Z0-9]+)*-[0-9]+`')"
if [ -z "$IDHITS" ]; then
  echo "(none within 3 lines of a hit — that is a signal toward 'Parcial' or 'Gap',"
  echo " not a conclusion by itself: read references/mentioned-vs-developed.md before deciding)"
else
  echo "$IDHITS" | sort -u
fi
echo

echo "## 3. Skills whose description or fonte: mentions it"
echo
SKILLHITS="$(grep -rliE -- "$TEMA" "$SKILLS"/*/*/SKILL.md 2>/dev/null)"
if [ -z "$SKILLHITS" ]; then
  echo "(none — the topic may live only in knowledge-base/, with no skill built on it yet)"
else
  echo "$SKILLHITS" | sed "s#$RAIZ/#  #"
fi
echo

echo "## 4. Skills whose fonte: points at a matched doc"
echo
if [ -n "$HITS" ]; then
  DOC_BASENAMES="$(echo "$HITS" | cut -d: -f1 | xargs -n1 basename 2>/dev/null | sort -u)"
  FOUND=""
  while IFS= read -r base; do
    [ -z "$base" ] && continue
    MATCH="$(grep -l "$base" "$SKILLS"/*/*/SKILL.md 2>/dev/null || true)"
    [ -n "$MATCH" ] && FOUND="${FOUND}${MATCH}
"
  done <<< "$DOC_BASENAMES"
  if [ -z "$FOUND" ]; then
    echo "(no skill declares fonte: on a doc that hit above)"
  else
    echo "$FOUND" | sort -u | sed "/^$/d" | sed "s#$RAIZ/#  #"
  fi
else
  echo "(skipped — no doc hits in step 1)"
fi
echo

echo "## 5. Dangling references — agents/ or docs citing a note that may not exist"
echo
AGENTHITS="$(grep -rniE -- "$TEMA" "$AGENTES" 2>/dev/null || true)"
if [ -n "$AGENTHITS" ]; then
  echo "$AGENTHITS" | sed "s#$RAIZ/#  #"
  echo
  echo "For each citation above, confirm the note it names actually resolves to a file"
  echo "under knowledge-base/ — a name that only exists in prose is a gap, per"
  echo "references/mentioned-vs-developed.md."
else
  echo "(no agent cites this term directly)"
fi
