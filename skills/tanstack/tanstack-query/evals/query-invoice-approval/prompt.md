---
tags: [tanstack, tanstack-query]
max_turns: 60
timeout_seconds: 1500
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Our invoices page still fetches with useEffect. Move it to TanStack Query (the package is already installed): the status filter, the pending summary and the customer names. Then add an optimistic Approve: the row should flip to approved right away, roll back if the server rejects it, and the list and the pending summary must end up correct. Keep it type-safe.

Input files: package.json, src/App.tsx, src/features/invoices/InvoicesPage.tsx, src/http.ts, src/main.tsx, src/types.ts, tsconfig.json
