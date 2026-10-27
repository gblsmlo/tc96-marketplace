# Rules of contract.md

The rule text this skill enforces, copied here so the skill needs no other file. IDs match the
repository's notes (`SDD-*` from the delivery-flow note, `TS-*` from the software-testing note),
so a citation resolves either way. Where flow v2 changes a rule, the v2 reading is stated after it.

## Rules

| ID | Rule |
| --- | --- |
| `SDD-CORE-03` | Every file in `.specs/` **MUST** be born `Draft` and change status only on the owner's explicit reply; the writer approving its own file, or silence counting as approval, **NEVER**. |
| `SDD-SPEC-02` | Each file of the bundle answers only its question; a fact **MUST** live in one file and the others link to it; copying content between files **NEVER**. |
| `SDD-SPEC-04` | The feature **MUST** state its Surface, Size, base branch and commands, plus any script only it needs, and **MUST** fit the review budget (default: 300 changed lines, two review families, one owner); a larger feature is split in the PRD by acceptance criterion, splitting by layer or file **NEVER**. v2: these fields live in `contract.md` (default D1). |
| `SDD-SPEC-05` | `contract.md` **MUST** list one check per line, each citing the `AC-*` it proves and the gate type that runs it at the cheapest level that catches the defect; every `AC-*` the feature traces **MUST** have at least one check, and the non-functional gates — static checks, the touched suite, and the security class when the feature touches authentication, authorization or sensitive data — **MUST** be listed. |
| `SDD-SPEC-06` | A contract is met **only** when it proves that every acceptance criterion it traces was met, as its **Met when** line states per `AC-*`; green checks that cover no `AC-*` **NEVER** close a contract, and an `AC-*` with no passing check **NEVER** does either. |
| `SDD-SPEC-07` | The writer **MUST** run each `AC-*` and rule of the feature through the seven edge categories once, and each edge that applies **MUST** end as a check, an Out of Scope line through a PRD amendment, or a gap for the owner; the implementer re-deriving the sweep **NEVER**. |
| `SDD-SPEC-08` | The bundle of a merged feature is **NEVER** rewritten; a failed contract or a gap **MUST** become a new item in its own folder. |
| `SDD-SPEC-09` | A fix or refactor that changes no product behavior takes the fast lane: its contract traces the `AC-*` it protects, or reproduces the defect. |
| `SDD-RUN-06` | A new item traces the same `AC-*`, starts from the failing branch, and holds only what the failing checks need. |
| `TS-CORE-02` | Each assertion **MUST** sit at the cheapest level that still catches the defect; checking end to end a condition already checked by a unit test **NEVER**. |

## Defaults this skill applies

Flow v2 left these open; until the owner decides, this skill applies:

| # | Default |
| --- | --- |
| D1 | base branch, owner role, Surface, Size and the lane map live in `contract.md` frontmatter; commands and local scripts in its **Delivery** section |
| D4 | a lane is `large` when that lane alone is estimated above 150 changed lines, half the review budget |
| D5 | the `tooling` lane is never `large` |

## Lanes

`design`, `frontend`, `backend`, `ai`, `devops`, `tooling`, `qa`. Every check names one. A lane
with no check is `none`, except `design`, which follows the UX section of `spec.md`.

## Lifecycle

`Draft` → `Approved` on the owner's reply, in the one message that approves the bundle. Frozen once
the feature merges (`SDD-SPEC-08`).
