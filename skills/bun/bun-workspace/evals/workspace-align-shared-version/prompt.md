---
tags: [bun, bun-workspace]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Our monorepo has `zod` declared in three places with three different ranges (packages/core, packages/api, apps/web) and we keep hitting "two copies of zod" type errors. Align it to a single version across the workspace in the way Bun's package manager expects, make sure it can't drift again, and tell me if anything else about the workspace layout is off.

Input files: package.json, packages/core/package.json, packages/api/package.json, apps/web/package.json, bun.lock
