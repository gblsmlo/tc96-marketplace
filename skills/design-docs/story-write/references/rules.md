# Rules of story.md

The rule text this skill enforces, copied here so the skill needs no other file. IDs match the
repository's notes (`DOC-*` from the decision-documents note, `SDD-*` from the delivery-flow
note), so a citation resolves either way. Where flow v2 changes a rule, the v2 reading is stated
after it.

## Rules

| ID | Rule |
| --- | --- |
| `DOC-CORE-01` | A document **MUST** answer a single question; a document that answers two is two documents. |
| `SDD-CORE-01` | The PRD **MUST** be the product's single source of truth: every feature, acceptance criterion and dependency traces to it. |
| `SDD-CORE-03` | Every file in `.specs/` **MUST** be born `Draft` and change status only on the owner's explicit reply; the writer approving its own file, or silence counting as approval, **NEVER**. |
| `SDD-PRD-03` | Every acceptance criterion **MUST** carry a PRD-wide ID (`AC-NN`) and an observable outcome in Given / When / Then. |
| `SDD-PRD-04` | The Dependency Graph **MUST** list the foundation features and the execution waves; a cycle **NEVER**. |
| `SDD-SPEC-02` | Each file of the bundle answers only its question; a fact **MUST** live in one file and the others link to it; copying content between files **NEVER**. v2: the files are `story.md`, `spec.md` and `contract.md`. |
| `SDD-SPEC-08` | The bundle of a merged feature is **NEVER** rewritten; a failed contract or a gap **MUST** become a new item in its own folder. |
| `SDD-SPEC-09` | A fix or refactor that changes no product behavior takes the fast lane, with no PRD amendment. |
| `SDD-RUN-06` | A new item traces the same `AC-*` and holds only what the failing checks need. |

## Defaults this skill applies

Flow v2 left this open; until the owner decides, this skill applies:

| # | Default |
| --- | --- |
| D9 | `story.md` quotes the PRD's one-sentence story and lists the `AC-*` IDs with a one-line summary; the Given / When / Then stays in the PRD |

## Lifecycle

`Draft` → `Approved` on the owner's reply, in the one message that approves the bundle. Frozen once
the feature merges (`SDD-SPEC-08`).
