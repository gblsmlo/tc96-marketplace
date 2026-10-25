---
tags: [tanstack, tanstack-review]
max_turns: 60
timeout_seconds: 1500
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Can you review this PR before I merge it? It adds the orders page with cancel, an account page, and the query client setup. Just the review, no code changes.

Input files: package.json, src/features/account/AccountPage.tsx, src/features/customers/customersQuery.ts, src/features/orders/queries.ts, src/features/orders/useCancelOrder.ts, src/http.ts, src/queryClient.ts, src/router.tsx, src/routes/orders.tsx, src/routes/root.tsx, src/types.ts, tsconfig.json
