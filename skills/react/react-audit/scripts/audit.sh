#!/usr/bin/env bash
# Codebase-wide React audit: runs every probe set of the family once and aggregates hits per probe.
# Usage: bash audit.sh [target] [out-dir]   (target: src, or . when src does not exist; out-dir: .react-audit)
#
# The summary ranks probes by hit count and names the file with most hits. A hit is a lead,
# not a finding: confirm by sampling (SKILL.md, Step 3) before reporting anything.
set -uo pipefail

TARGET="${1:-}"
if [ -z "$TARGET" ]; then [ -d src ] && TARGET=src || TARGET=.; fi
OUT="${2:-.react-audit}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$OUT"

run() {  # family, script
  local family="$1" script="$2"
  if [ ! -f "$script" ]; then echo "   $family: probe script not found ($script), skipped"; return; fi
  bash "$script" "$TARGET" 2>/dev/null | sed $'s/\033\\[[0-9;]*m//g' > "$OUT/$family.txt"
}

printf '\n== Inventory  %s\n' "$TARGET"
FILES=$(rg --files --type-add 'rx:*.{ts,tsx,js,jsx}' -trx -g '!*.gen.ts' "$TARGET" 2>/dev/null | wc -l | tr -d ' ')
TSX=$(rg --files -g '*.tsx' -g '*.jsx' "$TARGET" 2>/dev/null | wc -l | tr -d ' ')
TESTS=$(rg --files -g '*.test.*' -g '*.spec.*' "$TARGET" 2>/dev/null | wc -l | tr -d ' ')
STORIES=$(rg --files -g '*.stories.*' "$TARGET" 2>/dev/null | wc -l | tr -d ' ')
echo "   source files: $FILES · components (tsx/jsx): $TSX · tests: $TESTS · stories: $STORIES"
FORMS=$(rg -l --no-messages 'useForm\(' "$TARGET" 2>/dev/null | wc -l | tr -d ' ')

run review      "$HERE/../../react-review/scripts/probes.sh"
run structure   "$HERE/../../react-structure/scripts/import-probes.sh"
if [ "$FORMS" -gt 0 ]; then
  run forms     "$HERE/../../react-hook-form/scripts/probes.sh"
else
  echo "   forms: no useForm( in the target, RHF probes skipped"
fi
run rerender    "$HERE/../../react-component-performance/scripts/probes.sh"

OUT="$OUT" python3 - <<'PY'
import os, re, pathlib
out = pathlib.Path(os.environ["OUT"])
HEAD = re.compile(r"^== (\d+)\. (.+?)\s{2,}(.*)$")
PATH = re.compile(r"(?:^|\s)(\.?/?[\w@.\-/\[\]()$+]+\.(?:tsx|ts|jsx|js|json|jsonc))(?::(\d+))?")
rows, env = [], []
for family in ("review", "structure", "forms", "rerender"):
    f = out / f"{family}.txt"
    if not f.exists():
        continue
    block = None
    for line in f.read_text(encoding="utf-8", errors="replace").splitlines():
        m = HEAD.match(line)
        if m:
            block = {"family": family, "n": int(m.group(1)), "title": m.group(2), "id": m.group(3), "hits": 0, "files": {}}
            if block["n"] == 0:
                env.append(f"-- {family}")
            else:
                rows.append(block)
            continue
        if block is None or line.startswith("== Done"):
            continue
        if block["n"] == 0:
            if line.strip():
                env.append(line)
            continue
        for p, _ in PATH.findall(line):
            if "(nothing)" in line:
                break
            block["hits"] += 1
            block["files"][p] = block["files"].get(p, 0) + 1
            break

print("\n== Environment and enforcement (decides the verdict of every row below)")
seen = set()
for l in env:
    if l not in seen:
        print(l); seen.add(l)

print("\n== Hits per probe, highest first (lead, not finding)\n")
print("| family | probe | rule | hit lines | files | top file |")
print("| --- | --- | --- | ---: | ---: | --- |")
for r in sorted(rows, key=lambda r: (-r["hits"], r["family"], r["n"])):
    if r["hits"] == 0:
        continue
    top = max(r["files"].items(), key=lambda kv: kv[1])
    rid = r["id"].split(" — ")[0][:60]
    print(f"| {r['family']} | {r['n']}. {r['title']} | {rid} | {r['hits']} | {len(r['files'])} | `{top[0]}` ({top[1]}) |")
quiet = [f"{r['family']}#{r['n']}" for r in rows if r["hits"] == 0]
print(f"\nProbes with no hit: {', '.join(quiet) or 'none'}")

hot = {}
for r in rows:
    for p, c in r["files"].items():
        hot.setdefault(p, [0, set()]); hot[p][0] += c; hot[p][1].add(f"{r['family']}#{r['n']}")
print("\n== Hotspots: files hit by the most distinct probes\n")
for p, (c, probes) in sorted(hot.items(), key=lambda kv: (-len(kv[1][1]), -kv[1][0]))[:10]:
    print(f"   {p}  — {len(probes)} probes, {c} hits: {', '.join(sorted(probes))}")
print(f"\nRaw output per family: {out}/<family>.txt")
PY
