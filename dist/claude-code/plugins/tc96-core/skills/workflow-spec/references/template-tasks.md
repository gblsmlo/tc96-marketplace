# Spec template: Tasks

Tool-neutral, saved as `.specs/<feature>/tasks.md`. It is the feature's **executable plan**:
every unit that passed the five gates (`portoes.md`), with its owner, acceptance and evidence.
`project-manager` writes it at the end of `workflow-planning`. It is the only spec file an
implementer reads to start work; the other files reach the implementer through the links in
each Task.

Each Task uses the fields and body of `template-task.md`; this file only lists them in order and
records what they share.

---

## Fields

| Field | Meaning |
| --- | --- |
| `feature` | the slug of `.specs/<feature>/` |
| `owner` | `project-manager` |
| `status` | `Draft` · `Ready`; the first Task starts only on `Ready`, set by the owner (`WF-SPEC-04`, `WF-SPEC-06`) |
| `appetite` | how much this feature is worth, decided before any estimate (`WF-PLAN-01`) |
| `inputs` | each spec file this plan depends on, with its status at the time of writing |

## Body (copy from here down)

---

### Inputs

| File | Status |
| --- | --- |
| `requirements.md` | [Approved, or "not needed: <scope>"] |
| `design.md` | [Accepted, or "not needed"] |
| `user-experience.md` | [accepted, or "not needed"] |
| `../adr/NNNN-<slug>.md` | [Accepted] |

A Task that cites a file not yet accepted is not ready (`WF-SPEC-04`).

### Order

[The dependency order between Tasks, as a list or a small diagram. Tasks with no dependency
between them can run in parallel.]

### Tasks

- [ ] **T1 · [what this delivers, verb-first] [ENGINEERING] [STORY-<capability>-NNN]**
  - **Owner:** [`frontend-developer` · `backend-developer` · `devops-security`; never "fullstack" (`WF-PLAN-05`)]
  - **Depends on:** [T-ids, or "none"]
  - **Inputs:** [the sections of `requirements.md`, `design.md` or `user-experience.md` this Task implements, by link]
  - **Scope:** [as in `template-task.md`]
  - **Acceptance:** [one observable condition per line (`WF-PLAN-04`); a shared contract adds its shape test from `design.md`]
  - **Evidence:** [the command that proves it, and the expected reading]
  - **Out of this Task:** [...]
  - **Ships alone safely because:** [...]
- [ ] **T2 · [...]**

The checkbox is ticked by the implementer when validation closes the Task technically, never
before (`WF-CORE-04`).

### Done when

- Every Task names one owner from hub §3, its dependencies and its inputs.
- Every Task has a written acceptance criterion and an evidence plan.
- Every input is accepted, or the Task that needs it waits.
- The sum of the Tasks fits the appetite; if it does not, the plan returns to the decision
  table instead of growing (`WF-PLAN-02`).

### Out of this file

| Belongs in | What |
| --- | --- |
| `requirements.md` | why the feature exists, goals, stories |
| `design.md` | boundaries and contracts |
| `user-experience.md` | flows, states, accessibility |
| the board, when the project has one | the same Tasks as items; this file stays the source the item links to |

---

## Related

- `../SKILL.md` (`workflow-spec`): the skill that writes this file as a draft and records the owner's approval

- `template-task.md`: the fields and body of each Task
- `portoes.md`: the five gates every Task passed
- `workflow-implementation`: reads one Task from this file at a time
- [Fluxo de Entrega — Quatro Pilares](../../../referencias/fluxo-de-entrega-quatro-pilares.md) §5: where this file sits in `.specs/`
