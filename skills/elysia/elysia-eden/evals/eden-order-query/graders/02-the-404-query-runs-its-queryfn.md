---
type: llm
focus: trace
weight: 1
---

The 404 query runs its queryFn exactly once — 4xx are not retried (retry limited to 5xx, or disabled for 4xx) — shown by a test
