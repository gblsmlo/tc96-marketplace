---
type: llm
focus: trace
weight: 1
---

src/features/pricing/pricing.tsx still compiles against the components: `buttonVariants` is re-exported from src/components/ui/button.tsx, or the pricing import was updated to the variants file
