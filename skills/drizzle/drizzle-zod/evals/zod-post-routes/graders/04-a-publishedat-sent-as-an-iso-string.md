---
type: llm
focus: trace
weight: 1
---

A publishedAt sent as an ISO string is accepted and stored as a Date by the schema itself (coercion or a transform inside the drizzle-zod refinement — not a new Date() in the handler), proven by a test
