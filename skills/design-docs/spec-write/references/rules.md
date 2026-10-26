# Rules of spec.md

The rule text this skill enforces, copied here so the skill needs no other file. IDs match the
repository's notes (`DOC-*` from the decision-documents note, `SDD-*` from the delivery-flow
note), so a citation resolves either way. Where flow v2 changes a rule, the v2 reading is stated
after it.

## Rules

| ID | Rule |
| --- | --- |
| `DOC-CORE-01` | A document **MUST** answer a single question; a document that answers two is two documents. |
| `SDD-CORE-03` | Every file in `.specs/` **MUST** be born `Draft` and change status only on the owner's explicit reply; the writer approving its own file, or silence counting as approval, **NEVER**. |
| `SDD-PRD-02` | Every feature **MUST** declare what it provides and what it consumes, and every consumed item **MUST** name exactly one provider feature. |
| `SDD-SPEC-01` | Before writing a bundle, the writer **MUST** have the repo facts bounded to the feature — what exists for each interface it provides, every caller of what it changes, the tests and conventions around it — and cite them with `file:line`; a bundle written from the PRD alone **NEVER**. v2: the facts come from Search's evidence file; a missing fact is one bounded `repo-explorer` question. |
| `SDD-SPEC-02` | Each feature **MUST** have one folder, `.specs/features/<ID>-<slug>/`, each file answering only its question; a fact **MUST** live in one file and the others link to it; copying content between files **NEVER**. v2: the files are `story.md`, `spec.md` and `contract.md`. |
| `SDD-SPEC-03` | `spec.md` **MUST** hold what the feature exposes and consumes — interfaces, data shapes, invariants, boundary decisions — and a UX section only when the feature has an interface that needs one; step order or checks in `spec.md` **NEVER**. |
| `SDD-SPEC-08` | The bundle of a merged feature is **NEVER** rewritten; a later change, a failed contract or a gap **MUST** become a new item in its own folder. |
| `SDD-SPEC-09` | A fix or refactor that changes no product behavior **MUST** take the fast lane: `spec.md` only when an interface changes. |

## Defaults this skill applies

Flow v2 left these open; until the owner decides, this skill applies:

| # | Default |
| --- | --- |
| D2 | the design lane works from the UX section and adds no state it does not list |
| UX | the UX section exists exactly when `contract.md` marks the `design` lane `small` or `large` |

## Lifecycle

`Draft` → `Approved` on the owner's reply, in the one message that approves the bundle. Frozen once
the feature merges (`SDD-SPEC-08`).
