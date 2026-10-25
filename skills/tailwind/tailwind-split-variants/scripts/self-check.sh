#!/usr/bin/env bash
# Self-check after splitting: nothing left inline, variants files hold only styles, no conflicting utilities.
# Usage: bash self-check.sh <file-or-dir>...
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ $# -gt 0 ] || { echo "usage: bash self-check.sh <file-or-dir>..." >&2; exit 1; }

python3 "$HERE/split-variants.py" check "$@"; status=$?

for target in "$@"; do
  CONF="$(python3 "$HERE/../../tailwind-review/scripts/conflicts.py" "$target" </dev/null)"
  if [ -n "$CONF" ]; then
    echo "✗ two utilities on one property (TW-UTIL-01 / TW-COMP-02):"; echo "$CONF" | sed 's|^|   |'; status=1
  fi
done
exit $status
