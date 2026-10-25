---
tags: [elysia, elysia-openapi]
max_turns: 50
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Our `/openapi/json` started answering 500 after we tried to hide internal routes with `exclude: { tags: ['internal'] }`. While you're in there: in the docs every admin route shows the summary "Admin" instead of its own, `POST /orders` shows up as `/orders/`, and we want `GET /orders` to document the `x-ratelimit-remaining` response header (we already set it). Fix the docs and add a test that would catch these regressions.

Input files: package.json, src/app.ts, test/app.test.ts, tsconfig.json
