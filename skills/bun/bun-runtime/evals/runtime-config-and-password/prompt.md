---
tags: [bun, bun-runtime]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

This is a small Bun service (see the files). I need two things added:

1. `src/config.ts`: load `DATABASE_URL`, `PORT` and `ADMIN_PASSWORD` from the environment at startup, validate them (fail fast if something is missing or malformed), and write a `cache/config-snapshot.json` with the non-secret values so the ops team can inspect what the process booted with.
2. `src/auth/password.ts`: `hashPassword(plain)` and `verifyPassword(plain, hash)` for the admin password.

Use Bun's own APIs where they fit, wire the config into `src/server.ts`, and tell me about anything else in the repo you think I should fix while you're here.

Input files: package.json, tsconfig.json, .env.example, src/server.ts, .github/workflows/ci.yml
