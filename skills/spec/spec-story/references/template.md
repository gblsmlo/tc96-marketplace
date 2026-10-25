# Template: Story

Tool-neutral. The **acceptance unit**: what a role can do, and why, with scenarios a test can
execute. Written by `project-manager`. Rules: `rules.md` in this folder.

## Fields

| Field | Meaning |
| --- | --- |
| `id` | this item's identifier |
| `parent` | the Epic this Story belongs to; a Story with no parent is an orphan |
| `capability` | inherited from the parent Epic |
| `milestone` | optional roadmap block |
| `title` | `<what this delivers, verb-first> [STORY-<capability>-NNN]` |

## Body (copy from here down)

---

As a [role], I want [action, domain verb], so that [outcome for the business or the person].

### Context

[Two to four sentences: what already exists, what this action changes, who can perform it.]

### Acceptance scenarios

1. Given [a starting situation reachable in a real environment], when [the person's action],
   then [what they see or stop seeing].
2. [...]

[Three to eight scenarios. Cover the main path, a refusal, who cannot do it, and what changes
when the data changes. A scenario describes a situation and an observable result; it never
restates the rule's own text.]

### Done when

- Every Task linked to this Story is complete.
- The scenarios above are covered by an executable test, green, reviewed, with the run linked
  as evidence. No scenario is accepted by hand-checking.

### Open gaps

- [an edge that applies and has no answer yet — decided by: owner or a role — must close
  before: this Story is ready. Delete the section when empty.]

### Tasks

[Filled by whoever implements: the Task items that cite this Story, and what shipped each one.]

### Origin

[The PRD, decision record, or Epic this Story decomposes from.]
