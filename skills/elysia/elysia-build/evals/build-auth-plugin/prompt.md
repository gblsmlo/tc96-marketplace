---
tags: [elysia, elysia-build]
max_turns: 50
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

We need auth on this API. Bearer tokens are looked up in `src/tokens.ts`. Everything except `/health` must require a valid token (401 otherwise), and everything under `/admin` additionally needs the `admin` role (403 otherwise). Put the auth logic in a reusable plugin in `src/auth.ts` that the feature modules use, and add tests that prove it works.

Input files: package.json, src/admin.ts, src/app.ts, src/index.ts, src/profile.ts, src/tokens.ts, tsconfig.json
