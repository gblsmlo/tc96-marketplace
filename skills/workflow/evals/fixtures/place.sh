#!/usr/bin/env bash
# Places one eval case in the current (scaffold) directory: the shared quotes-app fixture, the
# case's own files/ over it, a git repository with one commit on main, then the case's setup.sh.
# Eval runs load no project .claude/ or CLAUDE.md, so the agents come from the plugin under test
# (run-evals.sh), and CLAUDE.md here is only a file the record step may read.
# Usage, from a case's place-files.sh:  bash "$here/../fixtures/place.sh" "$here"
set -eu
case_dir="$1"
evals="$(cd "$case_dir/.." && pwd)"
cp -R "$evals/fixtures/quotes-app/." .
if [ -d "$case_dir/files" ]; then cp -R "$case_dir/files/." .; fi
git init -q -b main
git -c user.name=eval -c user.email=eval@example.com add -A
git -c user.name=eval -c user.email=eval@example.com commit -q -m "fixture"
if [ -f "$case_dir/setup.sh" ]; then bash "$case_dir/setup.sh"; fi
