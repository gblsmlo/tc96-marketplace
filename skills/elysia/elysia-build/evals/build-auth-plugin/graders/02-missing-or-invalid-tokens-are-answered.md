---
type: llm
focus: trace
weight: 1
---

Missing or invalid tokens are answered with a returned status(401, …) and a non-admin on /admin with status(403, …) — no thrown error, and a test shows 401 rather than 500
