---
tags: [drizzle, drizzle-zod]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Clean up the validation in `src/posts/handlers.ts`. The schemas are hand-written and keep drifting from the table, the mobile app gets 400s whenever it sends `publishedAt` (it sends an ISO string), and last week someone created a post as another user. Use drizzle-zod. Keep the slug and title rules we have. PATCH must still allow unpublishing by sending `publishedAt: null`, and an empty PATCH body should be a 400, not a 500. Add tests for what you change.

Input files: package.json, src/db/client.ts, src/db/schema.ts, src/db/test-db.ts, src/posts/handlers.ts, test/handlers.test.ts, tsconfig.json
