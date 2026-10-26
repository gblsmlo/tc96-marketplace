# Template: Story

Tool-neutral: the body works in any tracker, or as a file when the caller names a path. A story is
the **acceptance unit**: what one user can do, why, and the criteria a test executes. Hints in
brackets are deleted when filled.

## Fields

| Field | Meaning |
| --- | --- |
| `title` | `[US-<n> · ]<what the user gets, verb-first>` |
| `parent` | the feature or epic, by ID, when the input names one; otherwise delete |
| `traces` | the PRD's `AC-*`, when the story comes from a PRD; otherwise delete |

## Body (copy from here down)

---

As a [role], I want [action], so that [outcome].

<!-- or, for a job story: When [situation], I want to [motivation], so I can [outcome]. -->

### Context

[Two to four sentences from the input: what exists today, what this changes, who can do it.]

### Acceptance criteria

- **AC-[n]** Given [a situation], when [an action], then [an observable outcome].

### Notes

[Dependencies on other stories, constraints the input states, links it gives. Delete when none.]

### Out of this story

- [What the input excluded, and where it belongs. An exclusion you add yourself is marked `(proposed)`. Delete when none.]

### Done when

- Every acceptance criterion is proved by an executable test, green, with the run linked.
- [Any other condition the input states; delete this line when none.]

### Open questions

- [GAP: the question — decides: who. Delete this section when there is none.]
