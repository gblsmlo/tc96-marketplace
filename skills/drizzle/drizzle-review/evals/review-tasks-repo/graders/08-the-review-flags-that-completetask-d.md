---
type: llm
focus: trace
weight: 1
---

The review flags that completeTask decides on a task row read outside the transaction, so two concurrent completions can both pass the done check (DRZ-TX-05 or an explicit race explanation)
