---
type: llm
focus: trace
weight: 1
---

There is a mechanism that fails when a workspace package re-declares zod with a literal range (a CI check, a script or a lint rule), and the response shows it failing on such a change
