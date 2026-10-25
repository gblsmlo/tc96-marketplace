---
type: llm
focus: trace
weight: 1
---

The approve mutation's onMutate calls cancelQueries on the list key before writing the optimistic value with setQueryData or setQueriesData
