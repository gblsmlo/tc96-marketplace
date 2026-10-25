---
type: llm
focus: trace
weight: 1
---

The dashboard component and its Charts import are code-split (createLazyRoute with .lazy(), or lazyRouteComponent), while the dashboard loader stays in the critical route definition
