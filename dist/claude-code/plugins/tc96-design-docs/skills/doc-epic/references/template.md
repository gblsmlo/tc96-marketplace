# Template: Epic

Tool-neutral: the body works in any tracker, or as a file when the caller names a path. An epic is
the **capability** level: it groups features and stories, closes when every child closes, and
reopens when the capability gains a new rule. Hints in brackets are deleted when filled.

## Fields

| Field | Meaning |
| --- | --- |
| `title` | `EPIC-<slug> · <capability name>` |
| `parent` | the initiative or roadmap item, when the input names one; otherwise delete |
| `milestone` | the roadmap block, when the input names one; otherwise delete |

## Body (copy from here down)

---

### Who this is for

[The roles that exercise this capability and what each does with it, one line per role.]

### The problem it solves

[Two to four sentences, in the user's words: what goes wrong today without this capability, with
the evidence and its source from the input, or `(hypothesis)`. No screen, table or component.]

### Hypothesis

If we deliver [the capability], then [who] will [the change in behavior or outcome], measured by
[the metric] reaching [the target] within [the window].

**Leading indicators:** [early signals the input names that the hypothesis is holding; delete when
none.]

### What a person can do once this epic is ready

- [Verb-first, one line per capability the input names. Each becomes a feature or story.]

### Out of this epic

- [What someone might expect here and is excluded, with why.]

### Non-functional requirements

[Only those the input states: performance, security, compliance, accessibility. Delete when none.]

### Children

- [Feature or story IDs the input gives, or "none yet".]

### Sources

- [The PRD, decision, research or conversation that authorized this capability, from the input.]

### Open questions

- [GAP: the question — decides: who. Delete this section when there is none.]
