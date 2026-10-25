---
type: llm
focus: trace
weight: 1
---

The snapshot is returned from onMutate and the rollback in onError reads it from the third argument (onMutateResult), not from a ref, a module variable or the fourth context argument
