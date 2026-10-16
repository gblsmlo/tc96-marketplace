# Spec template: Tasks

Tool-neutral, saved as `.specs/<capability>/tasks/NNNN-<slug>.md`. It is **one increment's
executable plan**: every unit that passed the four gates (`portoes.md`), with its owner,
acceptance, evidence and the test types the Validation will run. `project-manager` writes it at
the end of `workflow-planning`. It is the only spec file an implementer reads to start work;
the other files reach the implementer through the links in each Task.

## Numbering

`NNNN` is the highest number in `.specs/<capability>/tasks/` plus one, zero-padded to four
digits; the slug names the increment in kebab-case: `0002-approval-expiry.md`. A new increment
in the same capability gets a new plan; a `Ready` plan is never extended with another
increment's Tasks (`WF-SPEC-08`), so the implementer never reads the capability's history.

Each Task uses the fields and body of `template-task.md`; this file only lists them in order and
records what they share.

---

## Fields

| Field | Meaning |
| --- | --- |
| `capability` | the slug of `.specs/<capability>/`: the Epic's `capability` field, or the slug the owner confirmed when no Epic exists yet (hub §5) |
| `plan` | `NNNN`, from **Numbering** |
| `owner` | `project-manager` |
| `status` | `Draft` · `Ready`, set by the owner (`WF-SPEC-06`); each Task starts when the plan is `Ready` and the inputs that Task cites are accepted, so a `Draft` input holds back only the Tasks that cite it (`WF-SPEC-04`) |
| `inputs` | each spec file this plan depends on, with its status at the time of writing |
| `budget` | the review budget and wave width this plan was sized against: the project's record, or the hub defaults — at most 300 changed lines, two review families and one owner per Task; four writing Tasks at once (hub §4.2) |
| `delivery` | `pr-per-task` (default) · `pr-per-wave`, and whether the owner authorized push and PR for this plan's Tasks; detail under **Delivery** |

## Body (copy from here down)

---

### Inputs

| File | Status |
| --- | --- |
| `../requirements.md` | [Approved, plus the amendment this increment depends on, or "not needed: <scope>"] |
| `../design.md` | [Accepted, plus the amendment, or "not needed"] |
| `../user-experience.md` | [accepted, plus the amendment, or "not needed"] |
| `../../adr/NNNN-<slug>.md` | [Accepted] |

A Task that cites a file or an amendment not yet accepted is not ready (`WF-SPEC-04`); neither
is one whose acceptance depends on a gap still open (`WF-CORE-09`). Only that Task waits: the
others start once the plan is `Ready`.

### Order

| Wave | Tasks | Waits for |
| --- | --- | --- |
| 0 | [the contract Tasks (`WF-PLAN-08`), and every Task with no dependency] | nothing |
| 1 | [the Tasks whose dependencies are all in wave 0] | [the T-ids each one depends on] |

Waves are how the plan reads; execution is rolling. A Task starts as soon as its **Depends on**
closed in Validation, its inputs are accepted and a slot inside the wave width is free. Two
Tasks run side by side only when their **Surface** lines share no file, except a contract an
earlier Task landed (hub §4.2 "Waves", `WF-CORE-10`).

### Delivery

- **Mode:** [`pr-per-task` — one branch and one PR per Task, the default · `pr-per-wave` — one PR
  per wave, one commit per Task, reviewed commit by commit]
- **Push and PR:** [the owner's words authorizing push and PR for this plan's Tasks once each
  closes clean in Validation, quoted, with the date · or "ask per wave"]. The authorization covers
  this plan only and never covers merging (hub §5 "Delivery").

### Tasks

- [ ] **T1 · [what this delivers, verb-first] [ENGINEERING] [STORY-<capability>-NNN]**
  - **Owner:** [`frontend-developer` · `backend-developer` · `devops-security`; never "fullstack" (`WF-PLAN-05`)]
  - **Depends on:** [T-ids, or "none"]
  - **Wave:** [the wave from **Order**]
  - **Inputs:** [the sections of `requirements.md`, `design.md` or `user-experience.md` this Task implements, by link; implementation re-reads only the status lines of these files and of the Tasks in **Depends on**]
  - **Scope:** [as in `template-task.md`]
  - **Surface:** [as in `template-task.md`]
  - **Size:** [as in `template-task.md`]
  - **Risk:** [as in `template-task.md`]
  - **Acceptance:** [one observable condition per line (`WF-PLAN-04`), including each edge research answered for this Task (`WF-RES-06`); a shared contract adds its shape test from `design.md`]
  - **Edges answered:** [as in `template-task.md`]
  - **Evidence:** [the command that proves it, and the expected reading]
  - **Test types:** [the types the Validation runs, each at the cheapest level that catches the defect (static · unit · contract · integration · component · E2E · manual), with its cost class from hub §4.2; integration or E2E adds the sentence of what only it catches (`WF-PLAN-06`)]
  - **Out of this Task:** [...]
  - **Ships alone safely because:** [...]
- [ ] **T2 · [...]**

The checkbox is ticked by the implementer when validation closes the Task technically, never
before (`WF-CORE-04`).

### Board items

[Only when the project keeps a board (`project-document-set.md`); otherwise delete this
section. The text `repo-operator` publishes, word for word — it writes nothing of its own:

- **Epic:** the existing item's id, or, for a capability with none yet, its body from
  `template-epic.md`, taken from `../requirements.md`.
- **Stories:** the body of each Story this increment opens, from `template-story.md`, taken
  from the stories in `../requirements.md`.
- **Tasks:** none here; each Task above is published as it is.]

### Done when

- Every Task names one owner from hub §3, its dependencies and its inputs.
- Every Task has a written acceptance criterion and an evidence plan.
- Every Task names its test types, and no type sits above the cheapest that catches its defect
  without a sentence saying why (`WF-PLAN-06`).
- Every input is accepted and every gap a Task depends on is closed, or the Task that needs it
  waits (`WF-CORE-09`).
- Every Task names its wave, Surface, Size and risk class, and fits the budget (`WF-PLAN-07`,
  `WF-PLAN-06`).
- No two Tasks that can run side by side share a file in their Surface, except a contract an
  earlier Task lands (`WF-PLAN-08`, `WF-CORE-10`).
- **Delivery** names the mode, and either quotes the owner's push-and-PR authorization or says
  "ask per wave".

### Out of this file

| Belongs in | What |
| --- | --- |
| `requirements.md` | why the capability exists, goals, stories |
| `design.md` | boundaries and contracts |
| `user-experience.md` | flows, states, accessibility |
| the board, when the project has one | the items written under **Board items**, plus the Tasks; each item links to this file, and no id is written back here (one-way) |

---

## Related

- `../SKILL.md` (`workflow-spec`): the skill that writes this file as a draft and records the owner's approval

- `template-task.md`: the fields and body of each Task
- `template-epic.md` · `template-story.md`: the bodies under **Board items**
- `portoes.md`: the four gates every Task passed
- `workflow-implementation`: reads one Task from this file at a time
- [Delivery Flow — Four Pillars](../../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md) §5: where this file sits in `.specs/`
