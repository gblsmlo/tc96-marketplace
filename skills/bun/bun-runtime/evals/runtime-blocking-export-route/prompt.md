---
tags: [bun, bun-runtime]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Users report that the whole API freezes for everyone whenever someone hits `/export`, and separately that the admin password we set in `.env` "doesn't work" in staging even though it is copied correctly. Both are in this repo. Please fix the export route and whatever else you find wrong in this code, and explain each change.

Input files: package.json, tsconfig.json, .env, src/server.ts, src/routes/export.ts
