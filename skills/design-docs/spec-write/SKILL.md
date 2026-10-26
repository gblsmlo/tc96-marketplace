---
name: spec-write
description: Writes one feature's `spec.md` in the delivery flow v2 — what it consumes, each item matched to the exact section of its provider's `spec.md`; what it provides, each with a shape a consumer can code against before the feature merges, its invariants and its errors; the repo facts it reuses or changes with file:line from Search's evidence file; boundary decisions; and a UX section with the four screen states exactly when the contract gives the design lane work — as a `Draft`, with an executable check, citing `SDD-SPEC-01`–`SDD-SPEC-03`. Also writes the spec of a new item and of a fast-lane fix that changes an interface. In a project on the delivery flow v2 (`story.md` bundles), use when `workflow-plan` hands `spec-writer` a feature, or someone asks to write, fix or check a feature's interfaces, data shapes or UX states. Not for the story (story-write), the checks and lanes (contract-write), a decision that outlives the feature (spec-adr), nor the screens themselves (product-designer).
type: skill
family: design-docs
language: en
source: "[Rules](references/rules.md)"
tags:
  - skill
  - workflow
  - spec
---

# spec-write

> **Who runs it.** `spec-writer`, after `story-write` and before `contract-write`: the contract proves the invariants this file declares. It writes one file and flags, never records, a decision that outlives the feature.
> **Self-contained.** The template is `references/template.md`; the rule text and the defaults it applies are `references/rules.md`; the check is `scripts/self-check.sh`. Nothing here needs another skill to run.
> **Status.** Draft. Implements the `spec.md` row of `workflow/foundations/phases.md` §2.

`spec.md` answers one question: **what does this feature expose and consume?** Template: `references/template.md`.

## Inputs

| Input | From | Missing → |
| --- | --- | --- |
| the feature's PRD row: what it provides and consumes, with each provider | `.specs/PRD.md` | return the gap |
| the feature's `story.md` | `story-write` | write it first |
| each provider's `spec.md` | `.specs/features/<provider>/` | return the gap: the provider's bundle comes first |
| repo facts for this feature | the evidence file, "Repo facts" (`H4`) | ask `workflow-plan` for one bounded `repo-explorer` question |
| ADRs in force | `.specs/adr/` | none is fine |

## Step 1: Consumes

One row per item the PRD says the feature consumes. **Where it is defined** is the provider's `spec.md` section, or `file:line` when the item already exists in the code. The item name is the provider's, letter for letter; the script matches it under the provider's **Provides**. An item the provider does not provide is a gap, not a guess: the PRD's provider for it is wrong, or the provider's spec is short.

## Step 2: Provides

One `####` block per item the PRD says the feature provides:

| Field | Holds | Not enough |
| --- | --- | --- |
| **Shape** | the type, schema, route with method, status codes and body, or event and payload, so a consumer needs nothing else | "returns the invitation" |
| **Invariants** | what is always true of it; each becomes a check in `contract.md` | "is valid" |
| **Errors** | each failure the consumer can see and what it means | "throws on error" |

Write the shape a consumer codes against today: this feature is a placeholder for its consumers until it merges (`SDD-PRD-02`).

## Step 3: What already exists and boundary decisions

1. **What already exists.** Copy the facts from the evidence file that this feature reuses, changes, or whose callers it affects, each with `file:line` (`SDD-SPEC-01`). Code read now that the evidence file did not hold goes through `repo-explorer`, then into the evidence file.
2. **Boundary decisions.** Where each rule lives (browser, BFF, backend) and why, one line each. A decision that outlives the feature is flagged to `workflow-plan` for `spec-adr` and cited as `ADR-NNNN (Proposed)`.

## Step 4: UX, only when the design lane has work

When the feature has an interface a person uses, write the UX section: the flow in steps, the four states (loading, empty, error, success), and accessibility a check can observe. The section is required exactly when `contract.md` marks `design` as `small` or `large`; `contract-write` sets the lane from this section, so the two must agree. The design lane draws from this section and adds no state it does not list.

## Step 5: Self-check

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/spec-write/scripts/self-check.sh .specs/features/F03-invitations
```

The script checks the frontmatter, that each consumed item appears under its provider's **Provides**, that each provided item has Shape, Invariants and Errors, that each repo fact carries `file:line`, and, once `contract.md` exists, that the UX section matches the design lane and lists the four states. Fix every `FAIL`. Then, by reading:

| # | Check | Rule |
| --- | --- | --- |
| 1 | a consumer could write its code from **Shape** alone | `SDD-SPEC-03` |
| 2 | every invariant is observable, so a check can prove it | `SDD-SPEC-05` |
| 3 | no step order, Surface or check is in this file | `SDD-SPEC-02` |

## Examples

**Happy path.** F03 consumes `requireRole(role)` from F01 (F01 spec.md › Provides › requireRole) and `sendEmail(template, to)` from F02. Provides `POST /invitations`: Shape `POST /invitations {email} → 201 {id, token, expiresAt}`; Invariants "one pending invitation per (workspace, email)"; Errors `403` not admin, `422` invalid email. What already exists: "members are inserted only by POST /members — src/members/route.ts:22".

**Robust variant.** F05 pending invites list has a screen: UX section with loading (skeleton rows), empty ("No pending invites" and the invite button), error (retry), success (list with resend); `contract.md` marks `design: small`. A new item `F03.1` that only fixes time-zone expiry changes no shape, so it has no `spec.md` at all (`SDD-SPEC-09`).

**Anti-pattern and correction.**

```markdown
#### POST /invitations
- **Shape:** creates an invitation and returns it.
```

F04 cannot code against this; it would guess the token field, and the reviewer has no invariant to check. The script fails "no **Invariants:**, no **Errors:**". Corrected:

```markdown
#### POST /invitations
- **Shape:** `POST /invitations` body `{ email: string }` → `201 { id: uuid, token: string, expiresAt: ISO 8601 }`
- **Invariants:** one pending invitation per (workspace, email); `expiresAt` is 7 days after creation, UTC
- **Errors:** `403` caller is not admin; `422` email invalid; `409` never: a repeat returns the existing invitation
```

## Output

To `workflow-plan`, at most 4 lines: the file path, items provided, ADRs flagged, open gaps.
