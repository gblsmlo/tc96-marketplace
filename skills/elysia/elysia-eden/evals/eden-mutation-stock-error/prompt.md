---
tags: [elysia, elysia-eden]
max_turns: 50
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

When a customer orders more than we have in stock, the order form should say "Out of stock for <SKU>" next to the SKU field. Right now it always shows "Something went wrong", and when I try to read `error.value.sku` TypeScript says the property doesn't exist. Fix it end to end (server in `server/`, client in `web/`), fully typed, with tests.

Input files: package.json, server/app.ts, tsconfig.json, web/api.ts, web/create-order.test.ts, web/create-order.ts
