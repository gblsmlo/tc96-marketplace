---
type: llm
focus: trace
weight: 1
---

Each component imports its variants from the sibling file and still composes `cn(xVariants({ ... }), className)` with className last
