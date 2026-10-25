---
type: llm
focus: trace
weight: 1
---

After the fix, PATCH /profile/rename without a token answers 401 — the scope reaches through the intermediate `protected` plugin (scoped on both levels, `.as('scoped')` on `protected`, or global) — shown by a test
