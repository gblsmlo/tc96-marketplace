---
type: llm
focus: trace
weight: 1
---

Identifies that invalidateQueries({ queryKey: ['order'] }) matches no orders query, citing TSQ-MUT-07, and fixes the key so it covers ['orders', 'list']
