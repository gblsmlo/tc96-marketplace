---
type: llm
focus: trace
weight: 1
---

__root.tsx links the stylesheet through an `?url` import in the route's `head().links`, not a bare `import '../styles.css'`
