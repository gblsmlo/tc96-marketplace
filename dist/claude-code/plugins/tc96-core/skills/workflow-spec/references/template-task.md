# Work-item template — Task

Tool-neutral, sibling of `template-epic.md` and `template-story.md`. Task is the **executable
cut**: the only level an implementer reads to actually do work, and it must ship to
production alone, without breaking what is already there (`WF-IMPL-03`). A Task with no
parent Story is an orphan — outside the backlog until linked, a divergence to resolve, never
guessed at.

---

## Fields

| Field | Meaning |
| --- | --- |
| `id` | this item's identifier |
| `parent` | the Story this Task delivers part of — required |
| `capability` | inherited from the Story/Epic chain |
| `milestone` | optional roadmap block |
| `cycle` | optional planning-cycle marker (e.g. an ISO week), mainly used at Task level |
| `wave` | the wave of the plan this Task belongs to, from its **Order** (hub §4.2 "Waves"); none outside a plan |
| `discipline` | one of: engineering · design-system · design · UX · UI · product |
| `title` | `<what this delivers, verb-first> [<DISCIPLINE>] [STORY-<capability>-NNN]` |

### Discipline, and what it delivers

| Discipline | Delivers |
| --- | --- |
| Engineering | contract, persistence, API, web, test |
| Design system | a primitive or pattern in the shared UI layer — a Storybook story only when the Task instructs the agent to write one |
| Design | flow, screen, state, and interface copy, before code |
| User Experience | research, journey, and experience criteria |
| User Interface | visual composition of an existing surface |
| Product | a decision, specification, or acceptance already decided elsewhere |

A Task never carries an open product question — that belongs in `workflow-research` — nor any
other open gap: it waits until the gap closes (`WF-CORE-09`). A Task that serves more than one
Story lists all of them.

## Body (copy from here down)

---

**Scope:** [what this Task delivers, two to four sentences, with the rule IDs it exercises.
File names, routes, and component names belong here — whoever reads this is who executes it.]

**Enables scenarios:** [the scenario numbers, from which Story.]

**Surface:** [files, packages, routes, and components this Task touches. Two Tasks run side by
side only when their Surfaces share no file, except a contract an earlier Task landed; the
reviewer compares the diff's file list with this line before reading code (hub §4.2, §4.4).]

**Size:** [estimated changed lines, tests included, and the review families the diff touches.
Inside the review budget — by default at most 300 changed lines, two families, one owner;
above it, the Task is re-sliced by acceptance scenario or expand → migrate → contract step,
never by layer or file (`WF-PLAN-07`).]

**Risk:** [`contract` · `security` · `focused` — the hub §4.4 tree, applied when the Task was
planned. Validation reads it, and re-runs the tree only if the diff leaves the Surface or
touches a contract the plan did not foresee (hub §4.4, `WF-PLAN-06`).]

**Edges answered:** [the acceptance lines and the `decisoes` that answer this Task's edges, by
link or line. The implementer's question list starts here instead of sweeping them again
(`WF-IMPL-06`).]

**Evidence:** [the command that proves it, and the expected reading — a green test with the
exact count, a regenerated status artifact, an authenticated screenshot. "Validated manually"
with no date, environment, and result is not evidence — see `WF-VAL-02`, proportional to
risk, never absent.]

**Test types:** [the types the Validation runs, each at the cheapest level that catches the
defect (static · unit · contract · integration · component · E2E · manual); an integration or
E2E adds the sentence of what only it catches (`WF-PLAN-06`).]

**Out of this Task:** [what someone might expect here and belongs to a different Task, and
why.]

**Done when:** [one observable condition per line, mirroring the scenarios this Task
enables.]

**Ships alone safely because:** [why this cut can merge without the rest of the Story
breaking what is already live.]

---

## Related

- `../SKILL.md` (`workflow-spec`): the skill that writes this file as a draft and records the owner's approval

- `template-story.md` — the parent this Task delivers part of
- `workflow-implementation` — the skill that carries out what this template describes, `WF-IMPL-*`
- Reference model: lemind `docs/product/templates/task.md`
