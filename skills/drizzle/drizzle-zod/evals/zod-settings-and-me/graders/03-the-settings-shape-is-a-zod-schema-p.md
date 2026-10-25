---
type: llm
focus: trace
weight: 1
---

The settings shape is a Zod schema passed through the drizzle-zod refinement (not left as the generated any-JSON), and it is declared once — ideally the column's $type is derived from it with z.infer
