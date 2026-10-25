---
type: llm
focus: trace
weight: 1
---

input.tsx no longer declares cva, imports from './input.styles', and still composes `cn(inputStyles({ size, invalid }), className)`
