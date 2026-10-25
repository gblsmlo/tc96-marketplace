#!/usr/bin/env bash
# Dependency and workspace probes under Bun. Usage: bash probes.sh [root]
#
# S1 is the one that breaks the whole build and fails at RUNTIME, far from the cause.
# S1 and S4 read EVERY package.json of the workspace, not only the root: the package whose
# install script gets turned off usually lives in apps/* or packages/*, and an ignored
# `overrides`/`resolutions` key only exists outside the root.
set -uo pipefail
ROOT="${1:-.}"; cd "$ROOT" 2>/dev/null || { echo "root does not exist" >&2; exit 1; }
title() { printf '\n\033[1m== %s\033[0m  %s\n' "$1" "${2:-}"; }
none() { echo "   (nothing)"; }
or_empty() {  # prints the input; when it comes back empty, the message
  local out; out="$(cat)"
  if [ -n "$out" ]; then printf '%s\n' "$out"; else echo "   ${1:-(nothing)}"; fi
}

# The default trust list, from the binary itself when it is there (367 packages on Bun 1.4.3).
DEFAULT_TRUSTED="$(bun pm default-trusted 2>/dev/null | sed -n 's/^ - //p')"
export DEFAULT_TRUSTED

title "S1. trustedDependencies REPLACES the default list" "BUN-PKG-04 — it does not extend it"
python3 - <<'PYJSON' 2>/dev/null || echo "   (python3 missing: check trustedDependencies by hand, in EVERY package.json)"
import glob, json, os, pathlib, sys

def load(p):
    try:
        return json.loads(pathlib.Path(p).read_text())
    except Exception as e:
        print(f"   {p} could not be read: {e}")
        return None

root = load("package.json")
if root is None:
    sys.exit(0)

# every workspace package.json, from the root's "workspaces" globs
ws = root.get("workspaces", [])
patterns = ws.get("packages", []) if isinstance(ws, dict) else ws
files = ["package.json"] + sorted({f for pat in patterns for f in glob.glob(os.path.join(pat, "package.json"))})

default = [l for l in os.environ.get("DEFAULT_TRUSTED", "").splitlines() if l]
source = f"the binary's list ({len(default)} packages)"
if not default:
    default = ["sharp", "esbuild", "better-sqlite3", "puppeteer", "canvas", "bcrypt", "node-sass", "sqlite3"]
    source = "a fallback of 8 well-known packages (bun not on PATH — run `bun pm default-trusted`)"

td = root.get("trustedDependencies")
print(f"   read {len(files)} package.json: " + ", ".join(files))
for f in files[1:]:
    p = load(f)
    if p and "trustedDependencies" in p:
        print(f"   ⚠ {f} declares trustedDependencies — the docs describe it at the root; confirm with `bun pm untrusted` that it has any effect")
if td is None:
    print("   trustedDependencies not declared at the root — Bun's default list is in force (ok)")
    sys.exit(0)
print(f"   declared at the root: {td}")

off = []
for f in files:
    p = load(f) or {}
    for name in {**p.get("dependencies", {}), **p.get("devDependencies", {}), **p.get("optionalDependencies", {})}:
        if name in default and name not in td:
            off.append(f"{name} ({f})")
if off:
    print("   ⚠ INSTALL SCRIPTS TURNED OFF for: " + ", ".join(sorted(set(off))))
    print("   -> the symptom is not an install error: it is an uncompiled binary, failing at runtime")
    print("   -> add the ones you still need back into the SAME list")
else:
    print(f"   no direct dependency on {source} was left out (transitive ones: read `bun pm untrusted`)")
PYJSON
echo "   -- what is blocked today, and the command for each (run it yourself):"
echo "   $ bun pm untrusted"
echo "   -> it exits 0 even when something is blocked: read the list, do not trust the exit code"
echo "   -> BUN-PKG-03: a PR adding an entry there carries this output in its body"

title "S2. Lockfile and CI" "BUN-PKG-01, BUN-PKG-02 — bun ci, not bun install"
ls bun.lock bun.lockb 2>/dev/null | sed 's|^|   |' | or_empty "NO COMMITTED LOCKFILE (BUN-PKG-01) — and \`bun ci\` without one does NOT fail"
{ grep -nE 'bun install|bun ci' .github/workflows/*.y*ml 2>/dev/null || true; } | sed 's|^|   |' | or_empty "(no CI workflow found)"
echo "   -> \`bun install\` in CI may update the lockfile; \`bun ci\` fails when it diverges"

title "S3. Workspace declared" "monorepo"
{ grep -n -A4 '"workspaces"' package.json 2>/dev/null || true; } | sed 's|^|   |' | or_empty "not a workspace"

title "S4. Catalogs and overrides" "BUN-PKG-06, BUN-PKG-08 — overrides only count at the root"
{ grep -n -A4 -E '"catalog"|"catalogs"|"overrides"|"resolutions"' package.json 2>/dev/null || true; } | sed 's|^|   root: |' | or_empty "root: no catalog and no overrides"
python3 - <<'PYWS' 2>/dev/null || true
import glob, json, os, pathlib
root = json.loads(pathlib.Path("package.json").read_text())
ws = root.get("workspaces", [])
patterns = ws.get("packages", []) if isinstance(ws, dict) else ws
found, versions = False, {}
for f in sorted({f for pat in patterns for f in glob.glob(os.path.join(pat, "package.json"))}):
    p = json.loads(pathlib.Path(f).read_text())
    for key in ("overrides", "resolutions"):
        if key in p:
            found = True
            print(f"   ⚠ {f} declares \"{key}\" — Bun IGNORES it outside the root (BUN-PKG-08); move it to the root as \"overrides\"")
    for name, spec in {**p.get("dependencies", {}), **p.get("devDependencies", {})}.items():
        if not spec.startswith(("workspace:", "catalog:")):
            versions.setdefault(name, set()).add(spec)
if not found:
    print("   no overrides/resolutions outside the root")
shared = {n: v for n, v in versions.items() if len(v) > 1}
for n, v in sorted(shared.items()):
    print(f"   ⚠ {n} declared with {len(v)} different ranges ({', '.join(sorted(v))}) — a catalog candidate (BUN-PKG-06)")
PYWS
echo "   -> \"resolutions\" is Yarn's name; Bun accepts it at the root, and the key it documents is \"overrides\""
echo "   -> a catalog aligns what is DECLARED; it does not stop someone from re-adding a literal range later."
echo "      If drift has to be impossible, add a CI check that every workspace uses \"catalog:\" for that package"

title "S5. Linker" "BUN-PKG-10 — isolated x hoisted changes what a package can see"
{ grep -nE 'linker' bunfig.toml package.json 2>/dev/null || true; } | sed 's|^|   |' | or_empty "not declared — the default is in force"

title "S6. Committed patch" "BUN-PKG-09 — bun patch"
ls -d patches 2>/dev/null && ls patches | sed 's|^|   |' || echo "   no patches/"

title "S7. bunx without a pinned version" "BUN-PKG-11 — running a remote package with no pin"
{ grep -nE 'bunx ' package.json .github/workflows/*.y*ml 2>/dev/null || true; } | grep -vE '@[0-9]' | sed 's|^|   |' | or_empty
echo "   -> bunx without @version runs whatever is published at that moment"

title "S8. Bun version pinned" "BUN-TEST-15 and local x CI parity"
{ grep -nE 'bun-version|BUN_VERSION|"packageManager"' .github/workflows/*.y*ml package.json .tool-versions 2>/dev/null || true; } | sed 's|^|   |' | or_empty "NOT PINNED"
{ grep -nE 'bun-version:[[:space:]]*latest' .github/workflows/*.y*ml 2>/dev/null || true; } | sed 's|^|   ✗ |'

printf '\n\033[1m== Done.\033[0m S1 is the one that breaks the whole build — and the symptom shows up at runtime, not at install.\n'
