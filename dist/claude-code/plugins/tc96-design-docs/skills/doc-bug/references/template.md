# Template: Bug

Tool-neutral: the body works in any tracker, or as a file when the caller names a path. A bug
report is **what fails, where, and how someone else sees it fail**: one defect per report. Hints in
brackets are deleted when filled.

## Fields

| Field | Meaning |
| --- | --- |
| `title` | `<what fails> when <condition>` |
| `severity` | technical impact: `blocker` · `critical` · `major` · `minor` · `trivial` |
| `priority` | urgency, set by whoever triages: `P0`…`P3`, or `untriaged` |
| `affects` | the feature, story or release, by ID, when the input names it; otherwise delete |

## Body (copy from here down)

---

### Summary

[One or two sentences: what fails, for whom, since when, from the input.]

### Environment

- **Version or build:** [...]
- **Platform:** [OS, browser and version, device]
- **Account or role:** [who was signed in, with what permissions; masked]
- **Data:** [the record, tenant or configuration involved; masked]

[Delete a line the input does not touch, unless the steps cannot be followed without it: then it
is a gap.]

### Steps to reproduce

1. [One action per step, from a state someone else can reach.]

### Expected result

[What should have happened, as the input states it.]

### Actual result

[What happened instead, observable.]

### Unchanged behavior

- [What must keep working once this is fixed. Delete the section when the input names none.]

### Frequency

[Always · intermittent (N of M tries) · once; from the input.]

### Evidence

```
[errors, logs, stack traces, request IDs — verbatim, trimmed, secrets masked]
```

[Screenshots or recordings the input attached, by name. Delete the section when none.]

### Workaround

[What users can do meanwhile, from the input. Delete when none is known.]

### Notes

[Context the reporter gave: when it started, what changed, their hypothesis as `(hypothesis)`.
Delete when none.]

### Open questions

- [GAP: the question — decides: reporter or a role. Delete this section when there is none.]
