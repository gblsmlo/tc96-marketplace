---
tags: [tanstack, tanstack-router]
max_turns: 60
timeout_seconds: 1500
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

On /invoices the status filter, page and sort are kept in useState and synced to the URL by hand. Refresh mostly works but the back button doesn't, links can't be shared reliably, and ?page=abc breaks the page. Make the URL the real source of these filters with TanStack Router, typed. Also load the list in the route so navigating there doesn't wait for the component to mount; keep TanStack Query as the cache. Clicking an invoice currently does a full page reload.

Input files: package.json, src/http.ts, src/main.tsx, src/router.tsx, src/routes/invoice.tsx, src/routes/invoices.tsx, src/routes/root.tsx, src/types.ts, tsconfig.json
