#!/usr/bin/env bash
# Mede o orçamento de contexto de cada skill e atualiza a seção "Orçamento de contexto"
# do README de cada grupo. Uso:
#   bash Skills/tokens.sh            # atualiza os READMEs
#   bash Skills/tokens.sh --mostrar  # só imprime, sem escrever
#
# A medida vem do skill-validator (tiktoken). O que importa não é o total: é quanto
# entra no contexto ANTES de a skill decidir o que abrir — a linha `SKILL.md`.
set -uo pipefail

VAULT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATOR="${SKILL_VALIDATOR:-$HOME/go/bin/skill-validator}"
[ -x "$VALIDATOR" ] || VALIDATOR="$(command -v skill-validator)" || {
  echo "skill-validator não encontrado — instale com:" >&2
  echo "  go install github.com/agent-ecosystem/skill-validator/cmd/skill-validator@latest" >&2
  exit 1; }

MOSTRAR=0; [ "${1:-}" = "--mostrar" ] && MOSTRAR=1

fmt() { awk -v n="$1" 'BEGIN{
  s = ""; while (length(n) > 3) { s = "." substr(n, length(n)-2) s; n = substr(n, 1, length(n)-3) }
  print n s
}'; }

medir() { # $1 = diretório da skill; imprime "skill<TAB>skillmd<TAB>maiorref<TAB>nomeref<TAB>total<TAB>nrefs"
  local d="$1" saida
  saida="$("$VALIDATOR" check "$d" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | sed -n '/^Tokens/,/Total:/p')"
  awk -v skill="$(basename "$d")" '
    /SKILL\.md body:/ { gsub(/,/, "", $(NF-1)); skillmd = $(NF-1) }
    /^  references\// {
      gsub(/,/, "", $(NF-1)); v = $(NF-1) + 0
      nome = $1; sub(/references\//, "", nome); sub(/:$/, "", nome)
      n++; soma += v
      if (v > maior) { maior = v; maiornome = nome }
    }
    /Total:/ { gsub(/,/, "", $(NF-1)); total = $(NF-1) }
    END { printf "%s\t%d\t%d\t%s\t%d\t%d\n", skill, skillmd, maior, (maiornome == "" ? "—" : maiornome), total, n }
  ' <<< "$saida"
}

tabela() { # $1 = grupo
  echo "| Skill | \`SKILL.md\` | maior \`references/\` | total | refs |"
  echo "| --- | ---: | --- | ---: | ---: |"
  local somaskill=0 somatotal=0
  while IFS=$'\t' read -r s a b c t n; do
    printf '| [[%s]] | %s | `%s` (%s) | %s | %s |\n' "$s" "$(fmt "$a")" "$c" "$(fmt "$b")" "$(fmt "$t")" "$n"
    somaskill=$((somaskill + a)); somatotal=$((somatotal + t))
  done < <(for d in "$VAULT/Skills/$1"/*/; do medir "$d"; done | sort)
  echo
  printf 'Carregar as %s skills deste grupo de uma vez custaria **%s tokens** só de `SKILL.md`,\n' \
    "$(ls -d "$VAULT/Skills/$1"/*/ | wc -l | tr -d ' ')" "$(fmt "$somaskill")"
  printf 'e **%s** com todas as referências. É por isso que cada skill declara o que **nunca** carregar.\n' \
    "$(fmt "$somatotal")"
}

secao() { # $1 = grupo
  cat <<CAB
<!-- tokens:inicio -->
## Orçamento de contexto

Medido por \`skill-validator\` (tiktoken), em $(date +%F). **O número que importa é o da
coluna \`SKILL.md\`**: é o que entra no contexto antes de a skill decidir o que abrir.
As referências carregam sob demanda, uma por vez.

CAB
  tabela "$1"
  cat <<'ROD'

Regenerar: `bash Skills/tokens.sh`
<!-- tokens:fim -->
ROD
}

for g in "$VAULT"/Skills/*/; do
  grupo="$(basename "$g")"
  [ -f "$g/README.md" ] || continue
  if [ "$MOSTRAR" -eq 1 ]; then
    printf '\n\033[1m### %s\033[0m\n' "$grupo"; secao "$grupo"
    continue
  fi
  tmp="$(mktemp)"
  secao "$grupo" > "$tmp"
  python3 - "$g/README.md" "$tmp" <<'PYTOK'
import pathlib, sys, re
readme, bloco = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2]).read_text()
s = readme.read_text()
if "<!-- tokens:inicio -->" in s:
    s = re.sub(r"<!-- tokens:inicio -->.*?<!-- tokens:fim -->\n", bloco, s, flags=re.S)
else:
    marca = "\n## Relacionados"
    s = s.replace(marca, "\n" + bloco + marca, 1) if marca in s else s.rstrip() + "\n\n" + bloco
readme.write_text(s)
PYTOK
  rm -f "$tmp"
  echo "atualizado: Skills/$grupo/README.md"
done
