---
name: contract-write
description: Writes one feature's `contract.md` in the delivery flow v2, the reviewer's only checklist — what it traces, consumes and provides; one check per line, each naming its `AC-*`, the lane that writes it and the cheapest gate type that catches the defect; the seven-category edge sweep turned into checks; the non-functional gates by risk; the Met when line per `AC-*`; and the fields that replace `plan.md`: base branch, owner, Surface, Size within budget, and the lane map (each of seven lanes none, small or large) — as a `Draft`, with an executable check, citing `SDD-SPEC-04`–`SDD-SPEC-07` and defaults D1, D4, D5. Also writes the contract of a new item and of a fast-lane fix. In a project on the delivery flow v2 (`story.md` bundles), use when `workflow-plan` hands `spec-writer` a feature, or someone asks to write, fix or check a feature's checks, lanes, Surface or Met when line. Not for the story (story-write), the interfaces (spec-write), nor judging a diff against it (sdd-contract-review).
type: skill
family: design-docs
language: en
source: "[Rules](references/rules.md)"
tags:
  - skill
  - workflow
  - spec
  - contract
---

# contract-write

> **Critical instruction.** The reviewer checks what this file lists and nothing else, so whatever is left out goes unverified. **A contract is met only when it proves that every acceptance criterion it traces was met** (`SDD-SPEC-06`): green checks that cover no `AC-*` do not close it, and an `AC-*` with no passing check does not either.
> **Who runs it.** `spec-writer`, last of the three bundle files, after `story.md` and `spec.md` exist.
> **Self-contained.** The template is `references/template.md`; the rule text and the defaults it applies are `references/rules.md`; the check is `scripts/self-check.sh`. Nothing here needs another skill to run.
> **Status.** Draft. Implements the `contract.md` row of `workflow/foundations/phases.md` §2.

Template: `references/template.md`.

## Inputs

| Input | From | Missing → |
| --- | --- | --- |
| the feature's `story.md` | `story-write` | write it first |
| the feature's `spec.md` | `spec-write` | write it first (fast lane: may not exist) |
| the evidence file's repo facts | Search (`H4`) | ask `workflow-plan` |
| new item: the failing checks and the failing branch | the state file | return the gap |

## Step 1: Traces and interface

1. `traces`: the `AC-*` of `story.md`, exactly. The script compares the two.
2. **Interface**: the Consumes and Provides item names from `spec.md`, one per line.
3. `risk`: `security` for authentication, authorization or sensitive data; `contract` when a provided item is already consumed by a merged feature; otherwise `focused`.

| Mode | What changes |
| --- | --- |
| new item | `base` is the failing branch; checks only for what the failing checks need, plus the gates (`SDD-RUN-06`) |
| fast lane | traces the `AC-*` the fix protects, or holds one check that reproduces the defect with `(—)` (`SDD-SPEC-09`) |

## Step 2: Checks, one per line

```
- [ ] **C<n>** (AC-NN) <given input> → <observed outcome> · lane `<lane>` · `<gate>`
```

| Part | Rule |
| --- | --- |
| `AC-NN` | one traced `AC-*`; a check that proves no AC and is not a gate is cut, it proves nothing |
| outcome | observable from outside the code: a status, a row count, a rendered state, an emitted event |
| lane | the one of `design`, `frontend`, `backend`, `ai`, `devops`, `tooling`, `qa` that writes this check |
| gate | the cheapest level that catches the defect: `static` · `unit` · `contract` · `integration` · `component` · `e2e` · `manual`, always last (`run-gates` reads it); an `integration` or `e2e` check says before its lane what a cheaper level would miss |

Each invariant of `spec.md` gets at least one check. Then run every `AC-*` and every rule once through the seven edge categories (`SDD-SPEC-07`):

| Category | Ask |
| --- | --- |
| boundary | exactly at the limit: in or out? zero, negative, rounding? |
| time | counted from when, expires when, which time zone, events out of order? |
| empty | empty list, missing optional field, first use? |
| repetition | the same action twice, two people at once? |
| permission | which role, owner, tenant; a visitor with no session? |
| failure | a dependency down, stopped halfway: what does the person see, what is undone? |
| what already exists | data stored before the change, a client on the previous version? |

Each edge that applies becomes a check, a gap for the owner, or a proposed Out of Scope line that `workflow-plan` sends to `workflow-search`.

## Step 3: Gates and Met when

1. **G1** static on the Surface and **G2** the touched suites, always; **G3** `devops-security` review only when `risk: security`.
2. **Met when**, one clause per traced `AC-*` naming the checks that prove it, then the gates: `Met when: AC-01 proved by C1 and C2; AC-02 proved by C3; G1 and G2 green.`

## Step 4: Delivery fields (default D1)

| Field | How |
| --- | --- |
| `base` | the trunk; for a new item, the failing branch |
| `surface` | every path or glob the checks and the spec's repo facts point to; a file outside it is a review finding |
| `size` | estimated changed lines, tests included; above 300 the feature does not fit: return the gap "split F<NN> in the PRD by acceptance criterion" (`SDD-SPEC-04`) |
| `lanes` | each of the seven lanes: `none` when no check is tagged with it (design: when `spec.md` has no UX section); `large` with `lines` when that lane alone is estimated above 150 lines (D4); otherwise `small`; `tooling` is never `large` (D5) |
| `owner` | `frontend-developer` or `backend-developer`: the role of the code lane with most checks among the `small` ones |

## Step 5: Self-check

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/contract-write/scripts/self-check.sh .specs/features/F03-invitations
```

The script checks the frontmatter fields, the budget, the lane map against D4 and D5, every check's AC, lane and gate type, that every traced `AC-*` has a check and appears in Met when, that Met when cites only real checks, that every code lane with work has a check, that the gates match the risk, and that `traces` equals `story.md`. Fix every `FAIL`. Then, by reading:

| # | Check | Rule |
| --- | --- | --- |
| 1 | each check, if it passed on wrong code, would be a broken check: it observes the AC's outcome, not an implementation detail | `SDD-SPEC-06` |
| 2 | each gate type is the cheapest that catches the defect | `TS-CORE-02` |
| 3 | every invariant of `spec.md` has a check | `SDD-SPEC-05` |
| 4 | no design rationale is in this file | `SDD-SPEC-02` |

## Examples

**Happy path.** F03 traces AC-01–AC-03. Checks: `C1 (AC-01) admin invites a new email → 201 and one row pending · lane backend · contract`; `C2 (AC-01) the same call → sendEmail called once with the token · lane backend · unit`; `C3 (AC-02) member without admin role invites → 403, zero rows, zero emails; a unit test with a mocked guard would miss the route wiring · lane backend · integration`; `C4 (AC-01) dialog submit shows the pending invite · lane frontend · component`; the repetition edge of AC-03 gives `C5 (AC-03) inviting E twice → same id, one row, one resend · lane backend · integration`. Lanes: backend large (180 lines), frontend small, design small, the rest none. Met when: AC-01 proved by C1, C2 and C4; AC-02 proved by C3; AC-03 proved by C5. Size 260.

**Robust variant.** The time edge of AC-03 gives `C6 (AC-03) re-invite at expiresAt + 1s → new token · lane backend · unit`. `risk: security` because the token grants access without a session, so G3 is listed. A new item `F03.1` for C6 has `base: feat/F03-invitations`, traces only AC-03 and holds C6 plus the gates.

**Anti-pattern and correction.**

```markdown
- [ ] **C1** (—) invitation service has 90% coverage · `unit`
Met when: all checks green.
```

Coverage proves no AC; the reviewer could approve a feature where non-admins can invite. The script fails "every traced AC-* has a check" and "Met when names every traced AC-*". Corrected: one check per AC outcome, as in the happy path, and a Met when clause per AC.

## Output

To `workflow-plan`, at most 4 lines: the file path, the lane map, the size, open gaps and edges proposed for Out of Scope.
