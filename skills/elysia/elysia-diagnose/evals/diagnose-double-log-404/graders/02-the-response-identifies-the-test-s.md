---
type: llm
focus: trace
weight: 1
---

The response identifies the test's one-label origin `http://x` as the cause of the 404 (Elysia slices the path from a fixed index, so short origins break routing), and the test passes after switching to an origin such as http://localhost
