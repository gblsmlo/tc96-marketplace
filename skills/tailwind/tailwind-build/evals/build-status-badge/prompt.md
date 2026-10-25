---
tags: [tailwind, tailwind-build]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

add a reusable StatusBadge in src/components/ui/status-badge.tsx for order status (paid | pending | failed | refunded), two sizes (sm, md). the pending one should have a little pulsing dot. callers need to be able to pass className. then use it in src/features/orders/order-row.tsx, and put an icon-only "copy order id" button next to it in the row (lucide icons are installed).

Input files: package.json, src/components/ui/button.tsx, src/features/orders/order-row.tsx, src/lib/utils.ts, src/styles.css, vite.config.ts
