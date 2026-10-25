---
tags: [elysia, elysia-eden]
max_turns: 50
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Bug reports from the order screen:

- for an order that doesn't exist we render an empty card instead of the "not found" state;
- the error toast literally says "[object Object]";
- the orders list re-renders on every background refetch even when nothing changed.

The client layer is in `web/`, the server in `server/`. Fix the client layer (keep TanStack Query — we use `@tanstack/query-core` here so it runs headless), and add tests that prove each fix.

Input files: package.json, server/app.ts, tsconfig.json, web/api.ts, web/orders.test.ts, web/orders.ts
