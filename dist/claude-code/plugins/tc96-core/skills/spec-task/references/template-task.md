# Template: Task

Tool-neutral. Task is the **executable cut**: the only level an implementer reads to do work,
and it must ship to production alone without breaking what is already there. A Task with no
parent Story is an orphan. Written by `project-manager`. Rules: `rules.md` in this folder.

## Fields

| Field | Meaning |
| --- | --- |
| `id` | this item's identifier |
| `parent` | the Story this Task delivers part of; required |
| `capability` | inherited from the Story and Epic chain |
| `milestone` | optional roadmap block |
| `cycle` | optional planning-cycle marker (for example an ISO week) |
| `wave` | the wave of the plan this Task belongs to; none outside a plan |
| `discipline` | engineering · design-system · design · UX · UI · product |
| `title` | `<what this delivers, verb-first> [<DISCIPLINE>] [STORY-<capability>-NNN]` |

| Discipline | Delivers |
| --- | --- |
| Engineering | contract, persistence, API, web, test |
| Design system | a primitive or pattern in the shared UI layer |
| Design | flow, screen, state, and interface copy, before code |
| User Experience | research, journey, and experience criteria |
| User Interface | visual composition of an existing surface |
| Product | a decision, specification, or acceptance already decided elsewhere |

A Task never carries an open product question, nor any other open gap: it waits until the gap
closes. A Task that serves more than one Story lists all of them.

## Body (copy from here down)

---

**Scope:** [what this Task delivers, two to four sentences. File names, routes and component
names belong here; whoever reads this is who executes it.]

**Enables scenarios:** [the scenario numbers, from which Story.]

**Surface:** [files, packages, routes and components this Task touches. Two Tasks run side by
side only when their Surfaces share no file, except a contract an earlier Task landed.]

**Size:** [estimated changed lines, tests included, and the review families the diff touches.
Inside the review budget; above it, the Task is re-sliced by acceptance scenario or
expand-migrate-contract step, never by layer or file.]

**Risk:** [`contract` · `security` · `focused`.]

**Edges answered:** [the acceptance lines and decisions that answer this Task's edges, by link
or line. The implementer's question list starts here.]

**Evidence:** [the command that proves it, and the expected reading: a green test with the
exact count, a regenerated artifact, an authenticated screenshot. "Validated manually" with no
date, environment and result is not evidence.]

**Test types:** [the types validation runs, each at the cheapest level that catches the defect
(static · unit · contract · integration · component · E2E · manual); an integration or E2E adds
the sentence of what only it catches.]

**Out of this Task:** [what someone might expect here and belongs to a different Task, and why.]

**Done when:** [one observable condition per line, mirroring the scenarios this Task enables.]

**Ships alone safely because:** [why this cut can merge without the rest of the Story breaking
what is already live.]
