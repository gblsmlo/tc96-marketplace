---
tags: [drizzle, drizzle-review]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Before we cut the release, check that our migrations and schema are consistent. CI runs `drizzle-kit migrate` on deploy; locally people use `bun run db:push`. Something felt off after last sprint's card-status change (we added `archived`) and the activity-feed work. Review `src/db`, `drizzle/` and the scripts — findings by severity, and tell me what you actually ran.

Input files: drizzle.config.ts, drizzle/0000_init.sql, drizzle/0001_archived_status.sql, drizzle/meta/0000_snapshot.json, drizzle/meta/_journal.json, package.json, src/db/schema.ts, tsconfig.json
