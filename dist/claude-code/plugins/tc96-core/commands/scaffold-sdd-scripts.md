---
description: Writes the six harness scripts of the Spec Driven Development flow at the root of the project — init.sh, scripts/resolve-env, scripts/migrate-dev, scripts/run-gates, scripts/spawn-detached, scripts/stop — plus sdd.config.sh with the commands each one runs
tags:
  - sdd
  - scripts
---
# SDD harness scripts

**Objective:** give the project the six global scripts the delivery flow runs instead of an agent
(`SDD-CORE-05`, `SDD-SCR-*` in [Delivery Flow — Spec Driven Development](../referencias/fluxo-de-entrega-sdd.md) §6).
**Constraint:** preserve an existing `sdd.config.sh`; overwrite the scripts, which carry no
project-specific content. A script only one feature needs does not belong here: it lives in that
feature's `plan.md`.

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
| `SDD_TRUNK` | `spawn-detached` | the branch a feature starts from when `plan.md` names no `base` |
| `SDD_WORKTREES` | `spawn-detached`, `run-gates`, `stop` | where feature worktrees live, relative to the main checkout |
| `SDD_INSTALL` | `init.sh` | the dependency install |
| `SDD_MIGRATE` | `migrate-dev` | the migration command; it reads the variables `resolve-env` wrote |
| `SDD_ENV_FILE` | `resolve-env`, `migrate-dev` | the file the app loads for this checkout's port and database |
| `SDD_PORT_BASE`, `SDD_DB_PREFIX`, `SDD_DATABASE_URL_TEMPLATE`, `SDD_DB_CREATE` | `resolve-env` | how a checkout's port, database name, URL and database creation are derived; `{db}` is replaced by the name |
| `SDD_GATE_<TYPE>` | `run-gates` | the command for each gate type a contract can name |
| `SDD_AGENT`, `SDD_AGENT_RESUME` | `spawn-detached` | the agent CLI, reading the brief on stdin; the resume form continues the feature's last session |

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
# Usage: run-gates <feature> | --baseline
set -uo pipefail
main="$(cd "$(git rev-parse --path-format=absolute --git-common-dir)/.." && pwd)"
. "$main/sdd.config.sh"
target="${1:?usage: run-gates <feature> | --baseline}"
if [ "$target" = "--baseline" ]; then
  dir="$(git rev-parse --show-toplevel)"
  types="static unit"
  label="baseline"
else
  dir="$main/$SDD_WORKTREES/$target"
  contract="$dir/.specs/features/$target/contract.md"
  [ -f "$contract" ] || { echo "run-gates: fail — no contract at $contract"; exit 2; }
  types="$( { echo static; echo unit;
    grep -E '^- \[[ x]\] \*\*[CG][0-9]+' "$contract" | grep -oE '`[a-z0-9]+`[[:space:]]*$' | tr -d '` \t'; } \
    | awk '!seen[$0]++' | tr '\n' ' ')"
  label="$target"
fi
mkdir -p "$main/.sdd/logs"
log="$main/.sdd/logs/gates-$label-$(date +%Y%m%dT%H%M%S).log"
summary=""; failed=0
for type in $types; do
  case "$type" in manual|review) summary="$summary $type:skipped"; continue ;; esac
  var="SDD_GATE_$(printf '%s' "$type" | tr 'a-z' 'A-Z')"
  cmd="${!var:-}"
  if [ -z "$cmd" ]; then
    if [ "$target" = "--baseline" ]; then summary="$summary $type:none"; continue; fi
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
# Usage: spawn-detached <feature> --brief <file> [--resume]
set -euo pipefail
main="$(cd "$(git rev-parse --path-format=absolute --git-common-dir)/.." && pwd)"
cd "$main"
. ./sdd.config.sh
feature="${1:?usage: spawn-detached <feature> --brief <file> [--resume]}"; shift
brief=""; agent="$SDD_AGENT"
while [ $# -gt 0 ]; do
  case "$1" in
    --brief) brief="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"; shift 2 ;;
    --resume) agent="${SDD_AGENT_RESUME:-$SDD_AGENT}"; shift ;;
    *) echo "spawn-detached: fail — unknown argument $1"; exit 2 ;;
  esac
done
[ -f "$brief" ] || { echo "spawn-detached: fail — no brief"; exit 2; }
run="$main/.sdd/run"; mkdir -p "$run" "$main/.sdd/logs"
if [ -f "$run/$feature.pid" ] && kill -0 "$(cat "$run/$feature.pid")" 2>/dev/null; then
  echo "spawn-detached: running — $feature already has pid $(cat "$run/$feature.pid")"
  exit 0
fi
wt="$main/$SDD_WORKTREES/$feature"
branch="feat/$feature"
if [ ! -d "$wt" ]; then
  plan=".specs/features/$feature/plan.md"
  base="$(awk -F': *' '/^base:/{print $2; exit}' "$plan" 2>/dev/null)"
  base="${base:-$SDD_TRUNK}"
  if git show-ref --verify --quiet "refs/heads/$branch"; then
    git worktree add "$wt" "$branch" >/dev/null 2>&1 || { echo "spawn-detached: fail — worktree add $branch"; exit 1; }
  else
    git worktree add -b "$branch" "$wt" "$base" >/dev/null 2>&1 || { echo "spawn-detached: fail — worktree add from $base"; exit 1; }
  fi
  (cd "$wt" && ./init.sh) || { echo "spawn-detached: fail — init.sh failed in $wt"; exit 1; }
fi
rm -f "$run/$feature.exit" "$run/$feature.result"
log="$main/.sdd/logs/run-$feature-$(date +%Y%m%dT%H%M%S).log"
nohup bash -c 'cd "$1" && bash -c "$2" < "$3"; echo $? > "$4"' _ \
  "$wt" "$agent" "$brief" "$run/$feature.exit" >"$log" 2>&1 &
echo $! > "$run/$feature.pid"
echo "spawn-detached: started — $feature pid $! — $log"
EOF

cat > scripts/stop <<'EOF'
#!/usr/bin/env bash
# Usage: stop <feature> [--clean] | --all
set -euo pipefail
main="$(cd "$(git rev-parse --path-format=absolute --git-common-dir)/.." && pwd)"
cd "$main"
. ./sdd.config.sh
run="$main/.sdd/run"
target="${1:?usage: stop <feature> [--clean] | --all}"
clean="${2:-}"
tree() {
  local child
  for child in $(pgrep -P "$1" 2>/dev/null); do tree "$child"; done
  echo "$1"
}
stop_one() {
  local f="$1" pid pids
  if [ -f "$run/$f.pid" ]; then
    pid="$(cat "$run/$f.pid")"
    if kill -0 "$pid" 2>/dev/null; then
      pids="$(tree "$pid")"
      kill $pids 2>/dev/null || true
      for _ in 1 2 3 4 5; do kill -0 "$pid" 2>/dev/null || break; sleep 1; done
      kill -9 $pids 2>/dev/null || true
    fi
    rm -f "$run/$f.pid"
  fi
  if [ "$clean" = "--clean" ] && [ -d "$main/$SDD_WORKTREES/$f" ]; then
    git worktree remove --force "$main/$SDD_WORKTREES/$f" >/dev/null 2>&1 || true
  fi
  echo "stop: stopped — $f"
}
if [ "$target" = "--all" ]; then
  for p in "$run"/*.pid; do [ -e "$p" ] && stop_one "$(basename "$p" .pid)"; done
  exit 0
fi
stop_one "$target"
EOF

chmod +x init.sh scripts/resolve-env scripts/migrate-dev scripts/run-gates scripts/spawn-detached scripts/stop
```

---

## Script reference

| Script | Call | Prints |
| --- | --- | --- |
| `init.sh` | `./init.sh`, once per checkout or worktree | `init: pass — <log>` |
| `scripts/resolve-env` | `scripts/resolve-env`; keeps an existing resolved file | `resolve-env: wrote — .env.sdd (port 3240, db app_dev_f02_approval)` |
| `scripts/migrate-dev` | `scripts/migrate-dev` | `migrate-dev: pass — <log>` |
| `scripts/run-gates` | `scripts/run-gates F02-approval`, or `--baseline` for static and unit only | `pass — static:ok unit:ok contract:ok review:skipped — <log>` |
| `scripts/spawn-detached` | `scripts/spawn-detached F02-approval --brief <file> [--resume]` | `spawn-detached: started — F02-approval pid 4242 — <log>` |
| `scripts/stop` | `scripts/stop F02-approval [--clean]`, or `--all` | `stop: stopped — F02-approval` |

`run-gates` reads the gate type at the end of each check line in the feature's `contract.md`
(`` · `unit` ``), always adds `static` and `unit`, and fails a gate type the contract names when
`sdd.config.sh` has no command for it. `manual` and `review` are reported as skipped: a person or
`devops-security` covers them. `spawn-detached` writes `.sdd/run/<feature>.pid` at start and
`.sdd/run/<feature>.exit` when the agent ends; the brief tells the agent to write
`.sdd/run/<feature>.result`.

---

## Verification checkpoint

- [ ] `bash -n` passes on the six scripts.
- [ ] `./init.sh` prints `init: pass` on the main checkout.
- [ ] `scripts/resolve-env` run twice prints `kept` the second time.
- [ ] `.sdd/` and `.env.sdd` are in `.gitignore`.
- [ ] `sdd.config.sh` has a command for every gate type the project's contracts will name.
