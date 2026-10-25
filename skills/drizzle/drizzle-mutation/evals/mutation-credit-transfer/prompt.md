---
tags: [drizzle, drizzle-mutation]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Support reports double charges when users double-tap "Send" in the app (each tap retries with the same idempotency key), and last week an account went negative after two transfers landed at the same time. Fix `transfer` in `src/credits.ts`. The only test covers the happy path, and it has been hanging locally since the last refactor — add the ones that would have caught these. Tell me what you verified and what you could not.

Input files: package.json, src/credits.ts, src/db/client.ts, src/db/schema.ts, src/db/test-db.ts, test/credits.test.ts, tsconfig.json
