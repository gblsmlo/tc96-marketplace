---
tags: [tanstack, tanstack-router]
max_turns: 60
timeout_seconds: 1500
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Three router problems. 1) /settings and /dashboard should only be reachable when logged in; right now settings flashes and then bounces, and dashboard isn't protected at all. After signing in, people should land back on the page they were trying to open. 2) The dashboard's charts bundle is huge; keep it out of the initial load. 3) Navigating to /invoices feels slow even though the page is tiny.

Input files: package.json, src/auth.tsx, src/features/dashboard/Charts.tsx, src/http.ts, src/main.tsx, src/router.tsx, src/routes/dashboard.tsx, src/routes/home.tsx, src/routes/invoices.tsx, src/routes/login.tsx, src/routes/root.tsx, src/routes/settings.tsx, src/types.ts, tsconfig.json
