---
tags: [bun, bun-test-build]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Write the tests for `src/session.ts` in this project: a session must expire 30 minutes after the last access (not before), and the expiry must be audited exactly once even if `sessionExpired` is called repeatedly. Follow the conventions the suite already uses, run what you can, and tell me what you ran.

Input files: package.json, tsconfig.json, bunfig.toml, src/session.ts, src/audit.ts, test/setup.ts, test/audit.test.ts
