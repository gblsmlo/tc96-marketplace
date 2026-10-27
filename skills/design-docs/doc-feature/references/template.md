# Template: Feature

Tool-neutral: the body works in any tracker, or as a file when the caller names a path. A feature
is the **smallest slice that ships and can be proved alone**: it delivers a benefit, fits one
release and one review, and its criteria are what its tests prove. Hints in brackets are deleted
when filled.

## Fields

| Field | Meaning |
| --- | --- |
| `title` | `[<ID> · ]<what it delivers, verb-first>` — the ID is the PRD's `CAP-n` or the tracker's, when the input gives one |
| `parent` | the epic, by ID, when the input names one; otherwise delete |
| `prd` | `CAP-n` and the `AC-*` it satisfies, when it comes from a PRD; otherwise delete |

## Body (copy from here down)

---

### What it delivers

[One or two sentences: what a person can do once this ships that they cannot do today.]

### Benefit hypothesis

We believe [this feature] will [outcome] for [who]; we will know when [measure].

### Acceptance criteria

- **AC-[NN]** Given [a situation], when [an action], then [an observable outcome].

### Provides and consumes

| Direction | Item, in product words | Provider or consumers |
| --- | --- | --- |
| provides | [what other features can rely on] | [who consumes it, or "none yet"] |
| consumes | [what it needs] | [the one provider feature] |

[Write `none` under the table when the feature stands alone.]

### Out of this feature

- [What someone might expect here and belongs elsewhere, with where. A cut you made is
  `(proposed)`.]

### Children

- [Stories or tasks the input names, by ID; delete when none.]

### Open questions

- [GAP: the question — decides: who. Delete this section when there is none.]
