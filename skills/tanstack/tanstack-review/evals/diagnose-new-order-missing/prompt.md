---
tags: [tanstack, tanstack-review]
max_turns: 60
timeout_seconds: 1500
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

After I create an order, the orders list doesn't show it. React Query devtools shows the new order in the cache though! If I wait a while or reload, it appears. My teammate suggested setting staleTime: 0 and refetchOnWindowFocus: true everywhere. Can you find out what's going on and fix it?

Input files: package.json, src/features/orders/queries.ts, src/features/orders/useCreateOrder.ts, src/http.ts, src/queryClient.ts, src/router.tsx, src/routes/orders.tsx, src/routes/root.tsx, src/types.ts, tsconfig.json
