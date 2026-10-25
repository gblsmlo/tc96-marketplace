---
type: llm
focus: trace
weight: 1
---

The file name from the query string is validated before use: a value containing a path separator or `..` and a value starting with `-` are rejected with a 4xx, or the command passes `--` before it
