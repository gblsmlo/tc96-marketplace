---
tags: [elysia, elysia-build]
max_turns: 50
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Add an orders module to this Elysia service:

- `POST /orders` with `{ sku, quantity }` creates an order when there is enough stock (reserve it with `src/stock.ts`), and answers 409 with the sku when there isn't.
- `GET /orders/:id` returns the order, or 404.
- `GET /orders/export` returns `exportAll()` from `src/db.ts`.

The frontend will call this through Eden and needs to tell the 404 and the 409 apart, typed. Also, a security review flagged that our error responses leak internals — fix that while you're here. Add tests.

Input files: package.json, src/app.ts, src/catalog.ts, src/db.ts, src/index.ts, src/stock.ts, test/catalog.test.ts, tsconfig.json
