---
type: llm
focus: trace
weight: 1
---

Auth reaches beforeLoad through router context (createRootRouteWithContext plus RouterProvider context or router.update), not by calling a hook inside beforeLoad
