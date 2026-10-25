---
tags: [bun, bun-migrate]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

We want to move this Node service to Bun. Assess the migration: what blocks it outright, what needs a change, and what just works. Give me the plan with the order to do things in. The dependencies are installed (node_modules is in the repo copy).

Input files: package.json, src/index.ts, src/crypto.ts, src/cluster.ts, Dockerfile, node_modules/fake-apm/index.js, node_modules/fake-apm/package.json
