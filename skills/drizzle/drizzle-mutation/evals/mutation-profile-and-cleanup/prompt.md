---
tags: [drizzle, drizzle-mutation]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Four bug reports on `src/profile.ts`: (1) users can't remove their bio — the app sends `bio: null` and nothing happens; (2) a user deleted someone else's draft by guessing its id; (3) last night the admin cron called `purgeOldDrafts()` with no arguments by mistake and it wiped published posts too; (4) `importTags` crashes on some CSV uploads (empty files, and files that repeat a tag we already have). Fix them and add tests for each. Also, the app sometimes sends an empty PATCH body — make sure that doesn't 500.

Input files: package.json, src/db/client.ts, src/db/schema.ts, src/db/test-db.ts, src/profile.ts, test/profile.test.ts, tsconfig.json
