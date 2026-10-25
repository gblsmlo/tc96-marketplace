---
tags: [drizzle, drizzle-zod]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Security flagged that GET /me returns fields it shouldn't, and last week PATCH /me/settings stored garbage (`{ "theme": 42 }`). Also users report they can't remove their bio — the app sends `bio: null` and gets a 400. Add proper schemas in `src/me.ts` with drizzle-zod: a response schema for /me, a validator for settings, and fix the profile patch. We're stuck on zod 3.25 this sprint — don't upgrade it. Add tests.

Input files: package.json, src/db/client.ts, src/db/schema.ts, src/db/test-db.ts, src/me.ts, test/me.test.ts, tsconfig.json
