---
description: Writes the six harness scripts of the Spec Driven Development flow at the root of the project — init.sh, scripts/resolve-env, scripts/migrate-dev, scripts/run-gates, scripts/spawn-detached, scripts/stop — plus sdd.config.sh with the commands each one runs
tags:
  - sdd
  - scripts
---
# SDD harness scripts

**Objective:** give the project the six global scripts the delivery flow runs instead of an agent
(`SDD-CORE-05`, `SDD-SCR-*` in [Delivery Flow — Spec Driven Development](../docs/workflow/delivery-flow.md) §6).
**Constraint:** preserve an existing `sdd.config.sh`; overwrite the scripts, which carry no
project-specific content. The scripts take a delivery ID and a layer ID: the delivery's index
(`.specs/delivery/<delivery>/plan.md`) names the trunk and the feature branch, and each layer file
(`plans/<layer>-<slug>.md`) names the checks and their levels.

Every script is idempotent and non-interactive, exits `0` on success and non-zero on failure,
prints one summary line, and writes its full output to `.sdd/logs/` in the main checkout
(`SDD-SCR-02`). Each worktree gets its own port block and its own database (`SDD-SCR-03`).

---

## Step 1: Config

Write only if missing. These are the only project-specific lines; adjust them to the stack.

```bash
[ -f sdd.config.sh ] || cat > sdd.config.sh <<'EOF'
# Commands the SDD harness runs. Empty means the step or gate type does not exist here.
SDD_TRUNK="main"
SDD_WORKTREES="../.worktrees"
SDD_INSTALL="bun install"
SDD_MIGRATE=""
SDD_ENV_FILE=".env.sdd"
SDD_PORT_BASE=3100
SDD_DB_PREFIX="app_dev"
SDD_DATABASE_URL_TEMPLATE="postgres://localhost:5432/{db}"
SDD_DB_CREATE=""
SDD_GATE_STATIC="bun run typecheck && bun run lint"
SDD_GATE_UNIT="bun test"
SDD_GATE_CONTRACT=""
SDD_GATE_INTEGRATION=""
SDD_GATE_COMPONENT=""
SDD_GATE_E2E=""
SDD_AGENT="claude -p --model sonnet --permission-mode acceptEdits"
SDD_AGENT_RESUME="claude -p --continue --model sonnet --permission-mode acceptEdits"
EOF
```

| Variable | Used by | Holds |
| --- | --- | --- |
| `SDD_TRUNK` | `spawn-detached` | the trunk a delivery's feature branch is cut from when the index names no `trunk` |
| `SDD_WORKTREES` | `spawn-detached`, `run-gates`, `stop` | where layer worktrees live, relative to the main checkout |
| `SDD_INSTALL` | `init.sh` | the dependency install |
| `SDD_MIGRATE` | `migrate-dev` | the migration command; it reads the variables `resolve-env` wrote |
| `SDD_ENV_FILE` | `resolve-env`, `migrate-dev` | the file the app loads for this checkout's port and database |
| `SDD_PORT_BASE`, `SDD_DB_PREFIX`, `SDD_DATABASE_URL_TEMPLATE`, `SDD_DB_CREATE` | `resolve-env` | how a checkout's port, database name, URL and database creation are derived; `{db}` is replaced by the name |
| `SDD_GATE_<TYPE>` | `run-gates` | the command for each level a layer's checks can name; `static` is G1 and `unit` is G2, so set them to the whole lint-and-types and test commands |
| `SDD_AGENT`, `SDD_AGENT_RESUME` | `spawn-detached` | the agent CLI, reading the brief on stdin; the resume form continues the layer's last session |

The agent CLI needs permission to edit files and run `git commit` inside the worktree. Grant that
in the project's agent settings, not with a flag that skips every prompt.

## Step 2: Ignore runtime state

```bash
for line in ".sdd/" ".env.sdd"; do
  grep -qxF "$line" .gitignore 2>/dev/null || echo "$line" >> .gitignore
done
```

## Step 3: The scripts

```bash
mkdir -p scripts

cat > init.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
. ./sdd.config.sh
main="$(cd "$(git rev-parse --path-format=absolute --git-common-dir)/.." && pwd)"
mkdir -p "$main/.sdd/logs"
log="$main/.sdd/logs/init-$(basename "$PWD")-$(date +%Y%m%dT%H%M%S).log"
steps() {
  { [ -z "$SDD_INSTALL" ] || bash -c "$SDD_INSTALL"; } &&
    scripts/resolve-env &&
    scripts/migrate-dev &&
    scripts/run-gates --baseline
}
if steps >"$log" 2>&1; then
  echo "init: pass — $log"
else
  echo "init: fail — $log"
  exit 1
fi
EOF

cat > scripts/resolve-env <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
root="$(git rev-parse --show-toplevel)"
cd "$root"
. ./sdd.config.sh
if [ -f "$SDD_ENV_FILE" ] && grep -q '^SDD_RESOLVED=1$' "$SDD_ENV_FILE"; then
  echo "resolve-env: kept — $SDD_ENV_FILE"
  exit 0
fi
name="$(basename "$root" | tr 'A-Z' 'a-z' | tr -c 'a-z0-9\n' '_')"
port=$(( SDD_PORT_BASE + ($(printf '%s' "$name" | cksum | cut -d' ' -f1) % 400) * 10 ))
while (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null; do
  port=$(( port + 10 ))
done
db="${SDD_DB_PREFIX}_${name}"
url="${SDD_DATABASE_URL_TEMPLATE//\{db\}/$db}"
{
  echo "SDD_RESOLVED=1"
  echo "PORT=$port"
  echo "DB_NAME=$db"
  echo "DATABASE_URL=$url"
} > "$SDD_ENV_FILE"
if [ -n "$SDD_DB_CREATE" ]; then
  DB_NAME="$db" DATABASE_URL="$url" bash -c "$SDD_DB_CREATE" >/dev/null 2>&1 || true
fi
echo "resolve-env: wrote — $SDD_ENV_FILE (port $port, db $db)"
EOF

cat > scripts/migrate-dev <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
root="$(git rev-parse --show-toplevel)"
cd "$root"
. ./sdd.config.sh
if [ -z "$SDD_MIGRATE" ]; then
  echo "migrate-dev: skip — SDD_MIGRATE is empty"
  exit 0
fi
[ -f "$SDD_ENV_FILE" ] || scripts/resolve-env >/dev/null
set -a; . "./$SDD_ENV_FILE"; set +a
main="$(cd "$(git rev-parse --path-format=absolute --git-common-dir)/.." && pwd)"
mkdir -p "$main/.sdd/logs"
log="$main/.sdd/logs/migrate-$(basename "$root")-$(date +%Y%m%dT%H%M%S).log"
if bash -c "$SDD_MIGRATE" >"$log" 2>&1; then
  echo "migrate-dev: pass — $log"
else
  echo "migrate-dev: fail — $log"
  exit 1
fi
EOF

cat > scripts/run-gates <<'EOF'
#!/usr/bin/env bash
# Usage: run-gates <delivery> <layer> | <delivery> --all | --baseline
set -uo pipefail
main="$(cd "$(git rev-parse --path-format=absolute --git-common-dir)/.." && pwd)"
. "$main/sdd.config.sh"
delivery="${1:?usage: run-gates <delivery> <layer> | <delivery> --all | --baseline}"
levels() { grep -hE '^- \*\*[CI][0-9]+(\.[0-9]+)?\*\*' "$@" | grep -oE '`[a-z0-9]+`[[:space:]]*$' | tr -d '` \t'; }
if [ "$delivery" = "--baseline" ]; then
  dir="$(git rev-parse --show-toplevel)"
  types="static unit"
  label="baseline"
else
  layer="${2:?usage: run-gates <delivery> <layer> | <delivery> --all}"
  if [ "$layer" = "--all" ]; then
    dir="$main/$SDD_WORKTREES/$delivery"
    if [ ! -d "$dir" ]; then
      git -C "$main" worktree add "$dir" "feat/$delivery" >/dev/null 2>&1 || { echo "run-gates: fail — no worktree for feat/$delivery"; exit 2; }
    fi
    git -C "$dir" pull --ff-only >/dev/null 2>&1 || true
    files="$(ls "$dir/.specs/delivery/$delivery/plans/"*.md 2>/dev/null)"
  else
    dir="$main/$SDD_WORKTREES/$delivery-$layer"
    files="$(ls "$dir/.specs/delivery/$delivery/plans/$layer"-*.md 2>/dev/null | head -1)"
  fi
  [ -n "$files" ] || { echo "run-gates: fail — no layer file for $delivery $layer"; exit 2; }
  types="$( { echo static; echo unit; levels $files; } | awk '!seen[$0]++' | tr '\n' ' ')"
  label="$delivery-${layer#--}"
fi
mkdir -p "$main/.sdd/logs"
log="$main/.sdd/logs/gates-$label-$(date +%Y%m%dT%H%M%S).log"
summary=""; failed=0
for type in $types; do
  case "$type" in manual|review) summary="$summary $type:skipped"; continue ;; esac
  var="SDD_GATE_$(printf '%s' "$type" | tr 'a-z' 'A-Z')"
  cmd="${!var:-}"
  if [ -z "$cmd" ]; then
    if [ "$delivery" = "--baseline" ]; then summary="$summary $type:none"; continue; fi
    summary="$summary $type:no-command"; failed=1; continue
  fi
  echo "### $type: $cmd" >>"$log"
  if (cd "$dir" && bash -c "$cmd") >>"$log" 2>&1; then
    summary="$summary $type:ok"
  else
    summary="$summary $type:fail"; failed=1
  fi
done
if [ "$failed" -eq 0 ]; then
  echo "pass —$summary — $log"
else
  echo "fail —$summary — $log"
  exit 1
fi
EOF

cat > scripts/spawn-detached <<'EOF'
#!/usr/bin/env bash
# Usage: spawn-detached <delivery> <layer> --brief <file> [--resume]
set -euo pipefail
main="$(cd "$(git rev-parse --path-format=absolute --git-common-dir)/.." && pwd)"
cd "$main"
. ./sdd.config.sh
delivery="${1:?usage: spawn-detached <delivery> <layer> --brief <file> [--resume]}"
layer="${2:?usage: spawn-detached <delivery> <layer> --brief <file> [--resume]}"; shift 2
brief=""; agent="$SDD_AGENT"
while [ $# -gt 0 ]; do
  case "$1" in
    --brief) brief="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"; shift 2 ;;
    --resume) agent="${SDD_AGENT_RESUME:-$SDD_AGENT}"; shift ;;
    *) echo "spawn-detached: fail — unknown argument $1"; exit 2 ;;
  esac
done
[ -f "$brief" ] || { echo "spawn-detached: fail — no brief"; exit 2; }
run="$main/.sdd/run/$delivery"; mkdir -p "$run" "$main/.sdd/logs"
if [ -f "$run/$layer.pid" ] && kill -0 "$(cat "$run/$layer.pid")" 2>/dev/null; then
  echo "spawn-detached: running — $delivery $layer already has pid $(cat "$run/$layer.pid")"
  exit 0
fi
index=".specs/delivery/$delivery/plan.md"
trunk="$(awk -F': *' '/^trunk:/{print $2; exit}' "$index" 2>/dev/null)"; trunk="${trunk:-$SDD_TRUNK}"
feature="$(awk -F': *' '/^branch:/{print $2; exit}' "$index" 2>/dev/null)"; feature="${feature:-feat/$delivery}"
if ! git show-ref --verify --quiet "refs/heads/$feature"; then
  git branch "$feature" "$trunk" >/dev/null 2>&1 || { echo "spawn-detached: fail — cannot cut $feature from $trunk"; exit 1; }
fi
wt="$main/$SDD_WORKTREES/$delivery-$layer"
branch="$feature-$layer"
if [ ! -d "$wt" ]; then
  if git show-ref --verify --quiet "refs/heads/$branch"; then
    git worktree add "$wt" "$branch" >/dev/null 2>&1 || { echo "spawn-detached: fail — worktree add $branch"; exit 1; }
  else
    git worktree add -b "$branch" "$wt" "$feature" >/dev/null 2>&1 || { echo "spawn-detached: fail — worktree add from $feature"; exit 1; }
  fi
  (cd "$wt" && ./init.sh) || { echo "spawn-detached: fail — init.sh failed in $wt"; exit 1; }
fi
rm -f "$run/$layer.exit" "$run/$layer.result"
log="$main/.sdd/logs/run-$delivery-$layer-$(date +%Y%m%dT%H%M%S).log"
nohup bash -c 'cd "$1" && bash -c "$2" < "$3"; echo $? > "$4"' _ \
  "$wt" "$agent" "$brief" "$run/$layer.exit" >"$log" 2>&1 &
echo $! > "$run/$layer.pid"
echo "spawn-detached: started — $delivery $layer pid $! — $log"
EOF

cat > scripts/stop <<'EOF'
#!/usr/bin/env bash
# Usage: stop <delivery> <layer> [--clean] | --all
set -euo pipefail
main="$(cd "$(git rev-parse --path-format=absolute --git-common-dir)/.." && pwd)"
cd "$main"
. ./sdd.config.sh
first="${1:?usage: stop <delivery> <layer> [--clean] | --all}"
tree() {
  local child
  for child in $(pgrep -P "$1" 2>/dev/null); do tree "$child"; done
  echo "$1"
}
stop_one() {
  local d="$1" l="$2" clean="${3:-}" pidf pid pids
  pidf="$main/.sdd/run/$d/$l.pid"
  if [ -f "$pidf" ]; then
    pid="$(cat "$pidf")"
    if kill -0 "$pid" 2>/dev/null; then
      pids="$(tree "$pid")"
      kill $pids 2>/dev/null || true
      for _ in 1 2 3 4 5; do kill -0 "$pid" 2>/dev/null || break; sleep 1; done
      kill -9 $pids 2>/dev/null || true
    fi
    rm -f "$pidf"
  fi
  if [ "$clean" = "--clean" ] && [ -d "$main/$SDD_WORKTREES/$d-$l" ]; then
    git worktree remove --force "$main/$SDD_WORKTREES/$d-$l" >/dev/null 2>&1 || true
  fi
  echo "stop: stopped — $d $l"
}
if [ "$first" = "--all" ]; then
  for p in "$main"/.sdd/run/*/*.pid; do
    [ -e "$p" ] && stop_one "$(basename "$(dirname "$p")")" "$(basename "$p" .pid)"
  done
  exit 0
fi
stop_one "$first" "${2:?usage: stop <delivery> <layer> [--clean]}" "${3:-}"
EOF

chmod +x init.sh scripts/resolve-env scripts/migrate-dev scripts/run-gates scripts/spawn-detached scripts/stop
```

---

## Script reference

| Script | Call | Prints |
| --- | --- | --- |
| `init.sh` | `./init.sh`, once per checkout or worktree | `init: pass — <log>` |
| `scripts/resolve-env` | `scripts/resolve-env`; keeps an existing resolved file | `resolve-env: wrote — .env.sdd (port 3240, db app_dev_2026_10_27_quotes_l2a)` |
| `scripts/migrate-dev` | `scripts/migrate-dev` | `migrate-dev: pass — <log>` |
| `scripts/run-gates` | `scripts/run-gates 2026-10-27-quotes L2a`; `scripts/run-gates 2026-10-27-quotes --all` on the feature branch; `--baseline` for static and unit only | `pass — static:ok unit:ok integration:ok — <log>` |
| `scripts/spawn-detached` | `scripts/spawn-detached 2026-10-27-quotes L2a --brief <file> [--resume]` | `spawn-detached: started — 2026-10-27-quotes L2a pid 4242 — <log>` |
| `scripts/stop` | `scripts/stop 2026-10-27-quotes L2a [--clean]`, or `--all` | `stop: stopped — 2026-10-27-quotes L2a` |

`run-gates` reads the level at the end of each check line in the layer file (`` · `unit` ``), or in
every layer file with `--all`, always adds `static` (G1) and `unit` (G2), and fails a level a check
names when `sdd.config.sh` has no command for it. `manual` and `review` are reported as skipped: a
person or `devops-security` covers them. `spawn-detached` cuts the delivery's feature branch from
the trunk the first time, then the layer's branch `feat/<delivery>-<layer>` from the feature
branch; it writes `.sdd/run/<delivery>/<layer>.pid` at start and `.sdd/run/<delivery>/<layer>.exit`
when the agent ends; the brief tells the agent to write `.sdd/run/<delivery>/<layer>.result`.

---

## Verification checkpoint

- [ ] `bash -n` passes on the six scripts.
- [ ] `./init.sh` prints `init: pass` on the main checkout.
- [ ] `scripts/resolve-env` run twice prints `kept` the second time.
- [ ] `.sdd/` and `.env.sdd` are in `.gitignore`.
- [ ] `sdd.config.sh` has a command for every level the project's layer files will name.
