---
nome: workflow-spec
descricao: Writes and records one spec document in `.specs/` — PRD, design or RFC, ADR, user experience, tasks, or a board item (Epic, Story, Task) — from the template it owns, in the project's recorded document set, as a `Draft` the owner reviews before any status moves to approved, citing `WF-SPEC-*` and `DOC-*` IDs. Use when a pillar needs a file written, when the owner asks for an ADR or a story outside a run, or when a project has not yet decided which documents it keeps. Do not use to decide what the document says — that is the owning agent (`product-manager`, `software-architect`, `product-designer`, `project-manager`). Do not use to decide whether a document is needed at all — that is the scope from `workflow-research`.
tipo: skill
familia: workflow
idioma: en
fonte: "[Fluxo de Entrega — Quatro Pilares](../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md) §5 e [Documentos de Decisão — PRD, RFC e ADR](../../../knowledge-base/documentos-de-decisao-prd-rfc-adr.md)"
tags:
  - skill
  - workflow
  - spec
  - documentation
---

# workflow-spec

> **Source of this skill:** [Fluxo de Entrega — Quatro Pilares](../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md) §5 and the `WF-SPEC-*` rules in §6; [Documentos de Decisão — PRD, RFC e ADR](../../../knowledge-base/documentos-de-decisao-prd-rfc-adr.md) §2–§5.
> This skill **does not contain** the text of the rules — it says which file to write, from which template, by whom, and how the owner approves it.

> **Delegation, read first (`WF-CORE-06`, `WF-CORE-07`).** The content of every file is written
> by its owning agent — `product-manager`, `software-architect`, `product-designer`,
> `project-manager` — started with the envelope, the template path and the writing rules in
> Step 3, never with this conversation. The agent returns the path and the open gaps, not the
> file. This skill runs in the orchestrating conversation because only that conversation can
> ask the owner: which documents the project keeps, whether `AGENTS.md` may be written, and
> whether a `Draft` is approved.

> **Design note.** This is **not a fifth pillar**. The four pillars decide *when* a document is
> needed and the scope decides *which* (`WF-SPEC-03`); the owning agent decides *what it says*;
> this skill decides *form, location, status and review*. It exists so the templates, the
> project's document set and the approval protocol live in one place, and so a person can ask
> for one document — "write an ADR for this" — without running a pillar.

---

## When to use

| Situation | Go to |
| --- | --- |
| a pillar needs `requirements.md`, `design.md`, an ADR, `user-experience.md` or `tasks.md` | this skill, called by that pillar |
| the owner asks for one document outside a run ("record this as an ADR") | this skill, standalone |
| the project has no record of which documents it keeps | this skill, Step 2 |
| the question is what the document should say | the owning agent in Step 1's table |
| the question is whether the change needs a document at all | `workflow-research` (scope), `DOC-CORE-02` |
| the document is a PR | `workflow-validation`, `references/template-pr.md` there |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Fluxo de Entrega — Quatro Pilares](../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md) §5 and `WF-SPEC-*` | where each file lives, and the seven rules this skill enforces |
| 2 | [Documentos de Decisão — PRD, RFC e ADR](../../../knowledge-base/documentos-de-decisao-prd-rfc-adr.md) §2, §3 | which document answers which question, and when it freezes |
| 3 | Same note, the `DOC-*` family of the document being written | only that family: `DOC-PRD-*` for a PRD, `DOC-RFC-*` for a design, `DOC-ADR-*` for an ADR |

**Never load** hub §4.1–§4.4. The pillar that called this skill already decided the scope and
the gates; this skill does not reopen them.

References in this skill:

| File | What for |
| --- | --- |
| `references/project-document-set.md` | the one question that records which documents the project keeps, and where the answer is saved (Step 2) |
| `references/owner-review.md` | the status protocol: `Draft`, the owner's review, what moves a status (Step 4) |
| `references/template-requirements.md` | `.specs/<feature>/requirements.md`, the PRD |
| `references/template-design.md` | `.specs/<feature>/design.md`, RFC or design doc |
| `references/template-adr.md` | `.specs/adr/NNNN-<slug>.md`, one per decision that outlives the feature |
| `references/template-user-experience.md` | `.specs/<feature>/user-experience.md` |
| `references/template-tasks.md` | `.specs/<feature>/tasks.md`, one Task per unit |
| `references/template-epic.md` · `references/template-story.md` · `references/template-task.md` | tool-neutral board items, when the project keeps a tracker |

---

## Step 1 — Name the document, its owner and its template

The caller says which file it needs; a standalone request says which question is open. One
file, one question, one owner (`DOC-CORE-01`, `WF-SPEC-02`):

| Question open | Document | File | Owner agent | Template |
| --- | --- | --- | --- | --- |
| what to build, and why | PRD | `.specs/<feature>/requirements.md` | `product-manager` | `template-requirements.md` |
| how to build it, boundaries and contracts | design doc or RFC | `.specs/<feature>/design.md` | `software-architect` | `template-design.md` |
| what was decided, lasting past the feature | ADR | `.specs/adr/NNNN-<slug>.md` | `software-architect` | `template-adr.md` |
| how the person moves through it, every screen state | UX | `.specs/<feature>/user-experience.md` | `product-designer` | `template-user-experience.md` |
| who does what, with which acceptance and evidence | tasks | `.specs/<feature>/tasks.md` | `project-manager` | `template-tasks.md` |
| the same, as items in the project's tracker | Epic, Story, Task | the tracker | `project-manager` | `template-epic.md` · `template-story.md` · `template-task.md` |

If no row's question is open, no document is written (`DOC-CORE-02`): say so and return. If
the caller is a pillar, the scope it classified decides the set of files (`WF-SPEC-03`); do not
add a file the scope does not list.

---

## Step 2 — Read the project's document set, or record it once

`references/project-document-set.md`. Look, in this order, for the record of which
documents this project keeps: the `## Specs` section of the project's `AGENTS.md`, then
`.specs/README.md`. Found: use it, do not ask (`WF-SPEC-07`). Not found: ask the owner the one
question in that reference, then ask whether the answer may be written to `AGENTS.md`;
on no, write it to `.specs/README.md`.

Two things the record never changes: `tasks.md` is always kept, and a document marked off does
not drop its decision — the decision goes as one line to `tasks.md` under **Origin** and to the
envelope's `decisoes`. If the document named in Step 1 is off, stop here and return that line
instead of a file.

---

## Step 3 — Delegate the writing to the owner agent

Start the owner agent from Step 1 with exactly four things: the envelope that produced the
need, the paths of the spec files that already exist for this feature, the absolute path of
the template, and the rules below. Not this conversation (`WF-CORE-06`). The agent writes the
file with `status: Draft` and returns its path, the one-sentence problem or decision, and the
open gaps — not the content (`WF-CORE-07`).

Rules the agent writes under, in the delegation prompt:

| # | Rule | Why |
| --- | --- | --- |
| 1 | copy the template from "Body" down; delete every bracketed hint; fill every field or write `none` | a field left as a hint is an unmade decision hiding as a template |
| 2 | one sentence, one claim; every fact cites its source (`file:line`, ticket, data) | `WF-RES-04`; the owner verifies before approving |
| 3 | tables and lists over prose; no adjective that a number or a source could replace | the owner reads it in one pass |
| 4 | link the other spec files by path; never restate their content | `WF-SPEC-02` |
| 5 | answer only this file's question; a second question is a second file | `DOC-CORE-01`, `DOC-PRD-03` |
| 6 | `status: Draft`, never approved by the writer | `WF-SPEC-06` |
| 7 | what only the owner can decide goes under **Open gaps**, never silently chosen | `WF-CORE-05` |

An ADR takes `Proposed` instead of `Draft`, and its number is the next in `.specs/adr/`
(`template-adr.md`, "Numbering").

---

## Step 4 — Put it in front of the owner

`references/owner-review.md`. Return to the owner, in one message: the path, the
one-sentence problem or decision, the open gaps, and the question "approve, change, or
reject?". Then stop. The status moves only on the owner's explicit answer in the conversation
(`WF-SPEC-06`): approve → `Approved` (PRD) or `Accepted` (design, ADR, UX); change → the owner
agent revises and the file stays `Draft`; reject → the file keeps `Draft` or becomes
`Rejected`, and the run returns to the pillar that owns the gap (`WF-VAL-04` applies by analogy).

Silence is not approval. A spec-only run with an unapproved file ends with that file under
`lacunas`, not with an approval the agent gave itself.

---

## Step 5 — Self-check before returning

| # | Check | Rule |
| --- | --- | --- |
| 1 | the file answers one question, and that question was open | `DOC-CORE-01`, `DOC-CORE-02` |
| 2 | the project's document set was read before writing, and asked at most once | `WF-SPEC-07` |
| 3 | the file is the one the scope lists, written by its owner agent | `WF-SPEC-01`, `WF-SPEC-03` |
| 4 | it links the other files, copies none | `WF-SPEC-02` |
| 5 | no bracketed hint survived; every field is filled or `none` | Step 3, rule 1 |
| 6 | every claim has a source | `WF-RES-04` |
| 7 | the status is `Draft` or `Proposed` until the owner answered | `WF-SPEC-06` |
| 8 | the owner saw path, sentence, gaps and the question, in one message | Step 4 |
| 9 | this conversation holds the path and the envelope, not the file | `WF-CORE-07` |
| 10 | `AGENTS.md` was written only after the owner said yes | `WF-SPEC-07` |

---

## Step 6 — Return

To the pillar that called, or to the owner when standalone, the envelope from hub §5 with the
file's path in `artefato` and its status in `resultado`:

```yaml
pilar: "<the calling pillar, or the one that owns this document>"
resultado: "<file> written, status <Draft | Approved | Accepted | Proposed>"
artefato: ".specs/<feature>/<file>"
evidencia: [the sources the file cites]
decisoes: [the one-sentence decision, when approved]
lacunas: ["awaiting owner approval: <path>", any open gap in the file]
proximo: "<the calling pillar's next step, or none>"
```

The calling pillar continues only when `lacunas` holds no unapproved file it depends on
(`WF-SPEC-04`).

---

## Example

*`workflow-planning` needs an ADR: "sessions stay in PostgreSQL, not Redis".* Step 1: ADR,
`software-architect`, `template-adr.md`. Step 2: the project's `AGENTS.md` has a `## Specs`
section with ADR on — no question asked. Step 3: `software-architect` writes
`.specs/adr/0004-keep-sessions-in-postgres.md`, `Proposed`, with the axis (operating cost),
one real alternative and its cost, and returns the path. Step 4: the owner reads it and answers
"approve" — only then the status becomes `Accepted`, and `design.md` lists `ADR-0004`
(`DOC-RFC-04`). Had the owner said nothing, the run would return with
`lacunas: ["awaiting owner approval: .specs/adr/0004-keep-sessions-in-postgres.md"]`.

---

## Related

- [Fluxo de Entrega — Quatro Pilares](../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md) §5 — where each file lives, `WF-SPEC-*`
- [Documentos de Decisão — PRD, RFC e ADR](../../../knowledge-base/documentos-de-decisao-prd-rfc-adr.md) — what each decision document is, `DOC-*`
- `workflow-research` · `workflow-planning` — the pillars that call this skill
- `workflow-validation` — owns the PR template, the one change artifact not written here
