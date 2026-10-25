# Template: Plan

Tool-neutral, saved as `.specs/<capability>/tasks/NNNN-<slug>.md`. **One increment's executable
plan**: every unit that passed the four gates, with its owner, acceptance, evidence and the
test types validation will run. Written by `project-manager`. It is the only spec file an
implementer reads to start work; the other files reach the implementer through the links in
each Task. Rules: `rules.md` in this folder.

## Numbering

`NNNN` is the highest number in `.specs/<capability>/tasks/` plus one, zero-padded to four
digits; the slug names the increment in kebab-case: `0002-approval-expiry.md`. A new increment
in the same capability gets a new plan; a `Ready` plan is never extended with another
increment's Tasks.

Each Task uses the fields and body of `template-task.md`.

## Fields

| Field | Meaning |
| --- | --- |
| `capability` | the slug of `.specs/<capability>/` |
| `plan` | `NNNN` |
| `owner` | `project-manager` |
| `status` | `Draft` · `Ready`, set by the owner; each Task starts when the plan is `Ready` and the inputs that Task cites are accepted |
| `inputs` | each spec file this plan depends on, with its status at the time of writing |
| `budget` | the review budget and wave width: the project's record, or the defaults (at most 300 changed lines, two review families and one owner per Task; four writing Tasks at once) |
| `delivery` | `pr-per-task` (default) · `pr-per-wave`, and whether the owner authorized push and PR |

## Body (copy from here down)

---

### Inputs

| File | Status |
| --- | --- |
| `../requirements.md` | [Approved, plus the amendment this increment depends on, or "not needed: <why>"] |
| `../design.md` | [Accepted, plus the amendment, or "not needed"] |
| `../user-experience.md` | [accepted, plus the amendment, or "not needed"] |
| `../../adr/NNNN-<slug>.md` | [Accepted] |

A Task that cites a file or amendment not yet accepted is not ready; neither is one whose
acceptance depends on a gap still open. Only that Task waits.

### Order

| Wave | Tasks | Waits for |
| --- | --- | --- |
| 0 | [the contract Tasks, and every Task with no dependency] | nothing |
| 1 | [the Tasks whose dependencies are all in wave 0] | [the T-ids each depends on] |

Execution is rolling: a Task starts as soon as its **Depends on** closed in validation, its
inputs are accepted and a slot inside the wave width is free.

### Delivery

- **Mode:** [`pr-per-task`: one branch and one PR per Task, the default · `pr-per-wave`: one PR
  per wave, one commit per Task, reviewed commit by commit]
- **Push and PR:** [the owner's words authorizing push and PR for this plan's Tasks once each
  closes clean, quoted, with the date · or "ask per wave"]. The authorization covers this plan
  only and never covers merging.

### Tasks

- [ ] **T1 · [what this delivers, verb-first] [ENGINEERING] [STORY-<capability>-NNN]**
  - **Owner:** [`frontend-developer` · `backend-developer` · `devops-security`; never "fullstack"]
  - **Depends on:** [T-ids, or "none"]
  - **Wave:** [the wave from **Order**]
  - **Inputs:** [the sections of the PRD, design or UX this Task implements, by link]
  - **Scope · Surface · Size · Risk · Edges answered · Evidence · Test types · Out of this Task · Ships alone safely because:** [as in `template-task.md`]
  - **Acceptance:** [one observable condition per line, including each edge the PRD answered for this Task; a shared contract adds its shape test from the design]
- [ ] **T2 · [...]**

The checkbox is ticked by the implementer when validation closes the Task, never before.

### Board items

[Only when the project keeps a board; otherwise delete this section. The text published to the
tracker, word for word: the Epic (existing id, or a new body from the Epic template), the
Stories this increment opens (from the PRD's stories), and each Task above.]

### Done when

- Every Task names one owner, its dependencies and its inputs.
- Every Task has a written acceptance criterion and an evidence plan.
- Every Task names its test types, and none sits above the cheapest that catches its defect
  without a sentence saying why.
- Every input is accepted and every gap a Task depends on is closed, or that Task waits.
- Every Task names its wave, Surface, Size and risk class, and fits the budget.
- No two Tasks that can run side by side share a file in their Surface, except a contract an
  earlier Task lands.
- **Delivery** names the mode, and either quotes the owner's push-and-PR authorization or says
  "ask per wave".

### Out of this file

| Belongs in | What |
| --- | --- |
| the PRD | why the capability exists, goals, stories |
| a design doc or RFC | boundaries and contracts |
| a user-experience doc | flows, states, accessibility |
| the board, when the project has one | the items written under **Board items**, plus the Tasks; no id is written back here |
