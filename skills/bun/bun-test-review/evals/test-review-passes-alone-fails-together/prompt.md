---
tags: [bun, bun-test-review]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

`bun test test/unit/formatter.test.ts` passes, but `bun test` fails on that same file every time. A teammate opened a PR that wraps the tests in `test.serial` to "fix the ordering". Diagnose what is actually happening, say whether the PR is the right fix, and fix it properly.

Input files: package.json, tsconfig.json, bunfig.toml, src/registry.ts, src/formatter.ts, test/locale.test.ts, test/unit/formatter.test.ts, PR.md
