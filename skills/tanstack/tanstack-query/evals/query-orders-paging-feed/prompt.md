---
tags: [tanstack, tanstack-query]
max_turns: 60
timeout_seconds: 1500
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Two things on the orders screen. The table flashes empty every time I change page; move it to TanStack Query with page navigation that doesn't let people skip pages by double-clicking Next. The activity feed should become a proper infinite list with "Load more", and it can get long, so don't let memory grow forever. The QueryClient is already set up in main.tsx.

Input files: package.json, src/features/orders/ActivityFeed.tsx, src/features/orders/OrdersTable.tsx, src/http.ts, src/main.tsx, src/types.ts, tsconfig.json
