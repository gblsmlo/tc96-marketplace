---
tags: [elysia, elysia-diagnose]
max_turns: 50
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Two odd things in this service: every `GET /reports` shows up twice in our request log (`src/logger.ts`), while `/orders` shows up once, and `test/reports.test.ts` fails with 404 for `GET /reports` even though `curl localhost:3000/reports` works fine with `bun run src/index.ts`. Find the causes, fix them, and prove each fix with a test.

Input files: package.json, src/app.ts, src/index.ts, src/logger.ts, src/orders.ts, src/reports.ts, test/reports.test.ts, tsconfig.json
