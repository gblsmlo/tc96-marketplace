---
name: doc-tasks
description: Writes the task breakdown of work already specified — a checklist of small, verb-first tasks (T1, T2…), each tracing the acceptance criteria it enables, with its surface, its dependencies, a parallel marker when it can run beside others, and a done-when line — grouped in phases (setup, foundation, one per story or criterion, polish) and ordered by the dependencies the input states. Use whenever someone asks to break a story, feature, spec, PRD feature or plan into tasks, write a tasks.md or a to-do checklist for an implementer, or turn acceptance criteria into ordered work. A writer only — it does not read the codebase to find files, estimate, or decide the design. Not for the story or feature itself (doc-story, doc-feature), the technical design (doc-spec), or a PR description (doc-pr).
type: skill
family: design-docs
language: en
source: "[Template: Tasks](references/template.md)"
model: rapido
effort: medio
tags:
  - skill
  - design-docs
  - tasks
---

# doc-tasks

> **A writer.** It follows the [writing contract](../docs/writing-contract.md): it reads the request, the files the request names (the story, feature or spec being broken down) and `references/template.md` — nothing else (`DD-CORE-01`, `DD-CORE-02`). A file path in a task comes from the input; the writer never searches for one, and never opens a path the source cites to check it.

## Scope

A task list answers one question: **in what order is this built, in pieces small enough to finish and prove one at a time?**

| The request is... | Go to |
| --- | --- |
| what the user can do, and its criteria | `doc-story` or `doc-feature` |
| the shapes and design the tasks implement | `doc-spec` |
| describing the finished change | `doc-pr` |

**Anchor:** the source being broken down, with its acceptance (`DD-CORE-06`). Work with no acceptance criteria is `blocked`: return "what must be true when this is done?"

**Default path:** `tasks.md` beside the source when the source is a file (a feature folder, a spec); inline otherwise.

## Step 1: Map the criteria

List every acceptance criterion of the source by ID. Each one must end up enabled by at least one task; a task that enables none is either setup, foundation or polish, or it does not belong. A criterion the input names only by ID, without its text, cannot be traced: write `[GAP: what does AC-NN require? — decides: source owner]` and trace tasks to the behavior the input does describe, never to every criterion at once.

## Step 2: Write

Copy the template from "Body" down.

| # | Rule | Why |
| --- | --- | --- |
| 1 | One line per task: `- [ ] T<n> [P] [AC-…] <verb-first outcome> — <surface>` | a fixed shape is scannable and greppable |
| 2 | A task is a vertical slice that can be finished and proved alone; "add the column" and "use the column" in one task when one is useless without the other | a half-slice cannot be verified |
| 3 | Tests sit inside the task that adds the behavior, never in a final "write tests" task | a task without its proof is not done |
| 4 | Phases: Setup, Foundation, then one per story or criterion group (the first one is the smallest usable result), then Polish; delete an empty phase | the first phase that ships is visible |
| 5 | **Depends on** comes from dependencies the input states, or from one task using what another creates; an order you inferred is `(proposed)` | `DD-CORE-04` |
| 6 | `[P]` only when the task depends on no unfinished task and the input shows it touches a different surface; unknown surface → no `[P]` | two parallel tasks on one file collide |
| 7 | **Surface** is the file, module, route or screen the input names; unnamed → `[GAP: where does this live? — decides: implementer role]`, or the area in words | the writer never looks it up (`DD-CORE-02`) |
| 8 | **Done when** is one observable condition, usually the criterion's outcome | a task closes on evidence, not on effort |

## Step 3: Self-check

| # | Check |
| --- | --- |
| 1 | every acceptance criterion of the source is enabled by at least one task |
| 2 | every task has an ID, a verb-first outcome, a surface (or gap) and a done-when |
| 3 | no task depends on a later task; no cycle |
| 4 | no `[P]` task shares a surface with another `[P]` task of the same phase |
| 5 | no file path, estimate or design choice appears that the input did not give |
| 6 | every gap is inline and again under Open questions; no bracketed hint survived |

## Step 4: Return

The return block of the [writing contract](../docs/writing-contract.md) §5 — outcome (`complete`, `partial` or `blocked`), path or "inline", status, one sentence, then every gap and `(proposed)` item, plus the phases in one line each.

## Example

*"Break F02 into tasks. Criteria AC-01 approve from link, AC-02 reject from link, AC-03 expired after 30 days. Spec says: new `status` column on quotes (src/db/schema.ts), route POST /quotes/:id/decision (src/server/quotes.route.ts), page src/routes/q.$token.tsx."* Foundation: `T1 [AC-01, AC-02, AC-03] Add quote status with migration — src/db/schema.ts`. Phase AC-01/02: `T2 [P] [AC-01, AC-02] Accept a decision on POST /quotes/:id/decision, with tests — src/server/quotes.route.ts` (depends on T1); `T3 [P] [AC-01, AC-02] Approve and reject buttons on the quote page, with component test — src/routes/q.$token.tsx` (depends on T1; T2 and T3 touch different surfaces, so both carry `[P]`). Phase AC-03: `T4 [AC-03] Refuse decisions on quotes older than 30 days, with boundary tests — src/server/quotes.route.ts` (depends on T2). Outcome `complete`.
