---
tags: [elysia, elysia-diagnose]
max_turns: 50
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Production incident: `PATCH /profile/rename` works without any token. Our auth tests are green. Find out why, fix it, and prove the fix. Keep the plugin structure (auth → protected → feature modules).

Input files: package.json, src/app.ts, src/auth.ts, src/profile.ts, src/protected.ts, test/auth.test.ts, tsconfig.json
