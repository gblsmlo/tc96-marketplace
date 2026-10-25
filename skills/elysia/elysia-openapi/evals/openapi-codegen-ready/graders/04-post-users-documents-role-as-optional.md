---
type: llm
focus: trace
weight: 1
---

POST /users documents `role` as optional in its request body (it has a default) — the `mapJsonSchema: { zod: z.toJSONSchema }` that produced the output view is removed or given `io: 'input'`
