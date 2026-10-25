---
type: llm
focus: trace
weight: 1
---

POST /orders requires both the tenant header and the idempotency key: a POST without `x-tenant` (but with the key) answers 422, shown by a test or by running it
