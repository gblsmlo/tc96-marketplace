---
type: llm
focus: trace
weight: 1
---

packages/core/package.json no longer declares `resolutions`, and if a pin is still wanted it is an `overrides` entry in the root package.json
