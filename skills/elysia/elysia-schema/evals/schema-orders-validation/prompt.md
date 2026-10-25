---
tags: [elysia, elysia-schema]
max_turns: 50
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

This orders API validates almost nothing. Please add Elysia schemas to every route:

- the list takes `page` and `pageSize` from the query string, and the frontend needs to know whether there is a next page;
- `quantity` must be a positive integer;
- every request must carry the tenant header — clients say we reject them even when they send `X-Tenant`;
- `POST /orders` also needs an `Idempotency-Key` header;
- `internalCost` must never reach a client.

Replace the hand-written types where you can, and add tests for the edge cases.

Input files: package.json, src/app.ts, test/orders.test.ts, tsconfig.json
