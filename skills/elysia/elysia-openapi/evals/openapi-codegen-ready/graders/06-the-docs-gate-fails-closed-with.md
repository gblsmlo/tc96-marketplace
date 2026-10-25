---
type: llm
focus: trace
weight: 1
---

The docs gate fails closed: with the environment variable that enables them unset (and with NODE_ENV=production), /openapi/json answers 404 or 401 — shown by a test
