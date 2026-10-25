---
tags: [react]
max_turns: 60
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Add an orders panel to the shop app: a new `orders` feature with an OrdersPanel component that lists orders from GET /api/orders (id, customer, status, total), lets the user filter by status (the filter must survive a refresh and be shareable by link), lets them select orders with checkboxes, and shows how many are selected and their summed total. We use TanStack Router and TanStack Query. Write the code into the repo and a short delivery note to delivery.md.

Input files: shop-app repository (package.json, biome.json, tsconfig.json, src/)
