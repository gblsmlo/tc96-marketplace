---
type: llm
focus: trace
weight: 1
---

Every data-access function the run adds or changes takes db: Database first and its other inputs as one typed object when there are two or more of them (no new positional inputs after db)
