#!/usr/bin/env bash
# Dependency and workspace probes under Bun. Usage: bash sondas.sh [root]
#
# The first one is the one that breaks the whole build and fails at RUNTIME, far from the cause.
set -uo pipefail
RAIZ="${1:-.}"; cd "$RAIZ" 2>/dev/null || { echo "root does not exist" >&2; exit 1; }
titulo() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
vazio() { echo "   (nothing)"; }
ou_vazio() {  # prints the input; when it comes back empty, the message
  local saida; saida="$(cat)"
  if [ -n "$saida" ]; then printf '%s
' "$saida"; else echo "   ${1:-(nothing)}"; fi
}

titulo "S1. trustedDependencies REPLACES the default list" "BUN-PKG-04 — it does not extend it"
python3 - <<'PYJSON' 2>/dev/null || echo "   (python3 missing: check trustedDependencies by hand)"
import json, sys, pathlib
try:
    pkg = json.loads(pathlib.Path("package.json").read_text())
except Exception as e:
    print(f"   package.json could not be read: {e}"); sys.exit(0)
td = pkg.get("trustedDependencies")
if td is None:
    print("   trustedDependencies not declared — Bun's default list is in force (ok)"); sys.exit(0)
print(f"   declared: {td}")
deps = {**pkg.get("dependencies", {}), **pkg.get("devDependencies", {})}
padrao = ["sharp", "esbuild", "better-sqlite3", "puppeteer", "canvas", "bcrypt", "node-sass", "sqlite3"]
desligados = [p for p in padrao if p in deps and p not in td]
if desligados:
    print("   \u26a0 INSTALL SCRIPTS TURNED OFF for: " + ", ".join(desligados))
    print("   -> the symptom is not an install error: it is an uncompiled binary, failing at runtime")
    print("   -> add the ones you still need back into the SAME list")
else:
    print("   no known package from the default list was left out")
PYJSON
echo "   -- what is blocked today, and the command for each (run it yourself):"
echo "   $ bun pm untrusted"
echo "   -> BUN-PKG-03: a PR adding an entry there carries this output in its body"

titulo "S2. Lockfile and CI" "BUN-PKG-02 — bun ci, not bun install"
ls bun.lock bun.lockb 2>/dev/null | sed 's|^|   |' | ou_vazio "NO COMMITTED LOCKFILE"
rg -n --no-messages 'bun install|bun ci' .github/workflows/*.y*ml 2>/dev/null | sed 's|^|   |' | ou_vazio
echo "   -> \`bun install\` in CI may update the lockfile; \`bun ci\` fails when it diverges"

titulo "S3. Workspace declared" "monorepo"
rg -n --no-messages -A4 '"workspaces"' package.json 2>/dev/null | sed 's|^|   |' | ou_vazio "not a workspace"

titulo "S4. Catalogs and overrides" "a shared version, and a forced resolution"
rg -n --no-messages -A4 '"catalog"|"catalogs"|"overrides"|"resolutions"' package.json 2>/dev/null | sed 's|^|   |' | ou_vazio
echo "   -> \"resolutions\" is Yarn's; in Bun the key is \"overrides\""

titulo "S5. Linker" "isolated x hoisted changes what a package can see"
rg -n --no-messages 'linker' bunfig.toml package.json 2>/dev/null | sed 's|^|   |' | ou_vazio "not declared — the default is in force"

titulo "S6. Committed patch" "bun patch"
ls -d patches 2>/dev/null && ls patches | sed 's|^|   |' || echo "   no patches/"

titulo "S7. bunx without a pinned version" "running a remote package with no pin"
rg -n --no-messages 'bunx ' package.json .github/workflows/*.y*ml 2>/dev/null | rg -v '@[0-9]' || vazio
echo "   -> bunx without @version runs whatever is published at that moment"

titulo "S8. Bun version pinned" "BUN-TEST-15 and local x CI parity"
rg -n --no-messages 'bun-version|BUN_VERSION|"packageManager"' .github/workflows/*.y*ml package.json .tool-versions 2>/dev/null | sed 's|^|   |' | ou_vazio "NOT PINNED"

printf '\n\033[1m== Done.\033[0m S1 is the one that breaks the whole build — and the symptom shows up at runtime, not at install.\n'
