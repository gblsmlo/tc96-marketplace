---
type: llm
focus: trace
weight: 1
---

The server declares 409 (with the sku) in the route's response map, so the client's error union includes it — the form helper reads `error.value.sku` under `strict` without casts
