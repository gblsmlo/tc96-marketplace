# The project's document set — one question, recorded once

Which documents a project keeps is the owner's decision, made once and read on every run
(`WF-SPEC-07`). The scope still decides which files a given capability needs (`WF-SPEC-03`); the
record only says which of those this project writes at all.

---

## Where the record lives, in reading order

| Order | Location | When |
| --- | --- | --- |
| 1 | `## Specs` section in the project's `AGENTS.md` | the owner said yes to writing there |
| 2 | `.specs/README.md` | the owner said no, or the project has no `AGENTS.md` |
| 3 | none | ask the question below, then write to 1 or 2 |

Read 1, then 2. The first one found wins; never ask when either exists.

## The question, asked once

Ask in one message, with this table, and take the answer per row. A row left unanswered keeps
its default.

| Document | File | Default | Can be off |
| --- | --- | --- | --- |
| PRD | `.specs/<capability>/requirements.md` | on | yes |
| Design doc or RFC | `.specs/<capability>/design.md` | on | yes |
| ADR | `.specs/adr/NNNN-<slug>.md` | on | yes |
| User experience | `.specs/<capability>/user-experience.md` | on | yes |
| Plan | `.specs/<capability>/tasks/NNNN-<slug>.md` | on | **no** — the implementer reads only the current plan |
| Board items (Epic, Story, Task) | the project's tracker | off | yes |

Then the second question, separately: "May I record this in `AGENTS.md`, under a `## Specs`
section?" Write there only on an explicit yes; on no, write `.specs/README.md`. On no to both,
run with the defaults and say so in the envelope's `lacunas`.

## What off means

A document marked off is not written, and its decision is not lost: the owning agent states
it in one line, which goes to the plan under **Origin** and to the envelope's `decisoes`.
Off never removes a gate: a product scope still needs the owner's decision before planning
(`WF-CORE-03`); it only changes where that decision is recorded.

## The section, as written

Short, so that every agent session reads it in one pass. Dates are absolute.

```markdown
## Specs

Spec files live in `.specs/`, written as `Draft` and approved by the owner in the conversation
(`WF-SPEC-06`). Decided on YYYY-MM-DD.

| Document | Keep | File |
| --- | --- | --- |
| PRD | on | `.specs/<capability>/requirements.md` |
| Design doc or RFC | on | `.specs/<capability>/design.md` |
| ADR | on | `.specs/adr/NNNN-<slug>.md` |
| User experience | off | — |
| Plan | on | `.specs/<capability>/tasks/NNNN-<slug>.md` |
| Board items | off | — |
```

In `.specs/README.md` the same block goes under a `# Specs` title. Changing a row later is an
owner decision: edit the record, and note the date.

---

## Related

- `../SKILL.md` Step 2 — where this record is read
- [Fluxo de Entrega — Quatro Pilares](../../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md) §5 — the files and the scope table
