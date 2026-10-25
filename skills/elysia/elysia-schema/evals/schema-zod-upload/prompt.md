---
tags: [elysia, elysia-schema]
max_turns: 50
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Three bug reports on the users service:

1. The avatar upload accepts any file — someone uploaded an `.exe` renamed to `.png`. It must accept only real PNG or JPEG images.
2. The frontend says `createdAt` is missing from the `POST /users` response, even though the handler clearly returns it.
3. Security found that when sign-up fails validation, the 422 response contains the password the user typed — in production too.

Keep using the shared Zod schema in `src/shared/user.ts`; the frontend imports it. Fix all three, with tests.

Input files: package.json, src/app.ts, src/repo.ts, src/shared/user.ts, test/users.test.ts, tsconfig.json
