---
tags: [drizzle, drizzle-review]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Review the persistence layer of this repo before we ship: `src/db` and `src/tasks`, plus how the schema gets to production. Blockers first. Don't fix anything, I want the review.

Input files: .github/workflows/deploy.yml, package.json, src/db/client.ts, src/db/schema.ts, src/tasks/repository.ts, src/tasks/schemas.ts, tsconfig.json
