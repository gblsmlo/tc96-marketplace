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
| `discipline` | one of: engineering · design-system · design · UX · UI · product |
| `title` | `<what this delivers, verb-first> [<DISCIPLINE>] [STORY-<capability>-NNN]` |

### Discipline, and what it delivers

| Discipline | Delivers |
| --- | --- |
| Engineering | contract, persistence, API, web, test |
| Design system | a primitive or pattern in the shared UI layer, with a Storybook story |
| Design | flow, screen, state, and interface copy, before code |
| User Experience | research, journey, and experience criteria |
| User Interface | visual composition of an existing surface |
| Product | a decision, specification, or acceptance already decided elsewhere |

A Task never carries an open product question — that belongs in `workflow-research`. A Task
that serves more than one Story lists all of them.

## Body (copy from here down)

---

**Scope:** [what this Task delivers, two to four sentences, with the rule IDs it exercises.
File names, routes, and component names belong here — whoever reads this is who executes it.]

**Enables scenarios:** [the scenario numbers, from which Story.]

**Surface:** [files, packages, routes, and components this Task touches.]

**Evidence:** [the command that proves it, and the expected reading — a green test with the
exact count, a regenerated status artifact, an authenticated screenshot. "Validated manually"
with no date, environment, and result is not evidence — see `WF-VAL-02`, proportional to
risk, never absent.]

**Out of this Task:** [what someone might expect here and belongs to a different Task, and
why.]

**Done when:** [one observable condition per line, mirroring the scenarios this Task
enables.]

**Ships alone safely because:** [why this cut can merge without the rest of the Story
breaking what is already live.]

---

## Related

- `template-story.md` — the parent this Task delivers part of
- `workflow-implementation` — the skill that carries out what this template describes, `WF-IMPL-*`
- Reference model: lemind `docs/product/templates/task.md`
