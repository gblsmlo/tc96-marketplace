---
type: llm
focus: trace
weight: 1
---

The client reads `error.value.sku` only after narrowing `error.status === 409`, with no `any`, `as unknown as` or `@ts-ignore` to get past the types
