#!/usr/bin/env bash
# Runs the workflow evals with one model as the main session, against the built tc96-core plugin.
#
#   bash skills/workflow/evals/run-evals.sh <model> [claude plugin eval options...]
#   bash skills/workflow/evals/run-evals.sh haiku --case 'search-*' --runs 1
#   EVAL_TAG=rerun bash skills/workflow/evals/run-evals.sh opus --case 'plan-*'
#
# The phases call plugin agents (repo-explorer, code-reviewer, ...), and an eval run only loads
# agents from the plugin under test, so the target is a temporary copy of
# dist/claude-code/plugins/tc96-core with these evals placed in it. Results land in
# skills/workflow/evals/results/<model>/ (git-ignored); model-accuracy.py compares them. With
# EVAL_TAG set, the run writes result-<tag>.json beside result.json, and its cases replace the
# same cases of earlier files.
set -euo pipefail
model="${1:?usage: run-evals.sh <model> [options]}"; shift
evals="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$evals/../../.." && pwd)"
plugin="$root/dist/claude-code/plugins/tc96-core"
[ -d "$plugin" ] || bash "$root/build/claude-code.sh" >/dev/null
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
cp -R "$plugin" "$tmp/tc96-core"
mkdir -p "$tmp/tc96-core/evals"
for d in "$evals"/*/; do
  name="$(basename "$d")"
  [ "$name" = results ] || cp -R "$d" "$tmp/tc96-core/evals/$name"
done
out="$evals/results/$model"
name="result${EVAL_TAG:+-$EVAL_TAG}"
mkdir -p "$out"
claude plugin eval "$tmp/tc96-core" \
  --model "$model" --ablation none --scaffold --trust-plugin --no-publish \
  --allow-tools Bash Write Edit \
  --json "$out/$name.json" --output-dir "$out" --report "$out/$name.html" \
  "$@"
