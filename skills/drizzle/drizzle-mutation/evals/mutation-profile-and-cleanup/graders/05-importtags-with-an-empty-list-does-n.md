---
type: llm
focus: trace
weight: 1
---

importTags with an empty list does not throw, and a list repeating a name or containing an existing tag does not fail (dedupe and onConflictDoNothing or equivalent), proven by tests
