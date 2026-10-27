# Contract review — the reviewer's procedure

> **Who reads this.** A new `code-reviewer` instance, called by name as a subagent and independent
> of the author (`SDD-CORE-02`). `workflow-review` hands it this file's absolute path together with
> the inputs below, in one of two modes: a **layer** review (are this layer's checks and rules
> met?) or the **delivery** review (is the contract met on the feature branch?). It never fixes,
> never widens what it checks, and never reads the conversation that produced the change
> (`CC-SES-07`).

Rules this procedure implements: [Delivery Flow — Spec Driven Development](../../docs/delivery-flow.md)
§4.3 "The checks", §5.3, §5.4, `SDD-PLAN-07`, `SDD-RUN-04`.

## Input

Exactly these, and nothing else. A missing one is the first line of the verdict, not a guess.

| Input | Layer review | Delivery review |
| --- | --- | --- |
| what to check | the layer file: its **Checks**, **Must hold** and **Surface** | `contract.md`, and the layer files its rows point to (their **Checks** only) |
| diff | `git -C <worktree> diff feat/<delivery>...HEAD` | `git diff <trunk>...feat/<delivery>` |
| gates | the one-line summary from `run-gates <delivery> <layer>` | the one-line summary from `run-gates <delivery> --all` |
| open findings | delta re-review only: the previous verdict's IDs | — |

## Step 1: Gates first

The gate summary must say `pass`. If it says `fail`, return `unmet — gates failed` and stop: `workflow-review` should not have sent it (`SDD-RUN-03`).

## Step 2: Surface (layer review)

Run the diff with `--name-only` and compare with the layer's Surface. Each file outside it is a finding, with the path, before reading any code.

## Step 3: Each check

For each check the input names:

1. Find what implements it in the diff: the test, the assertion, or for `static` the gate line in the summary.
2. Confirm the level matches the check's (a check declared `unit` proved only by an E2E is a finding: the cost the plan chose was not respected).
3. Confirm it **observes the outcome the line states**, the one a person would see, not an internal call or a private field. A test that would pass with the behavior broken does not prove the check.

Mark each check `proved` or `unproved`, with the `file:line` of what proves it, or what is missing.

## Step 4: Each rule, or each acceptance criterion

**Layer review.** For each **Must hold** line, confirm the diff holds it, with `file:line`; a rule the code breaks is a finding even when no check covers it. A **Provides** shape the diff changes from what the layer file states is a finding: another layer codes against it.

**Delivery review (`SDD-PLAN-07`).** Go through `contract.md` one `AC-*` row at a time. An `AC-*` is **met** only when every check its row names is `proved` and passing on the feature branch. An `AC-*` the `traces` field lists with no row, or a row naming a check no layer file holds, is unmet. The contract is met only when every row is met and the gates are green.

## Step 5: Outside what you check

What you notice outside the checks, the rules and the Surface is a **note**, one line, non-blocking. Two exceptions block the merge, as **blocking**: a security defect (an unauthenticated path to data, a secret in code, an injection), and a regression of a layer that already merged (a provided shape another layer consumes, changed). Neither counts as a fix round; the owner decides.

Do not load the family review skills for a full audit: that is not this review's question. Load one only when a check names a family rule as its proof.

## Output format

At most 25 lines:

```
## Verdict: met | unmet

## Unmet
- C7 (AC-05) unproved: <what is missing, one line> — path:line
- Must hold "<rule>" (ADR-0002 §3) broken — path:line
- outside Surface: path

## Proved
- C1 (AC-01) path:line · C2 (AC-03) path:line

## Notes (non-blocking)
- <one line>

## Blocking
- security | regression: <one line> — path:line
```

`## Unmet` is empty on `met`. `workflow-review` copies only the IDs into the state file.

## Delta re-review

After a fix round, a new instance receives the open findings and reads the diff since the last reviewed commit:

1. Run Steps 1 and 2 on the fix diff.
2. For each open check and rule: `proved` (cite the fix's `file:line`) or still `unproved`.
3. Raise a new item under **Unmet** only where the fix broke something proved before.
4. Re-read the whole change only when the fix diff leaves the Surface or touches a **Provides** shape; say why in the verdict.

## Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | only the inputs of the mode were used; no conversation, no PRD | `SDD-RUN-04` |
| 2 | layer: every check and **Must hold** line got a proved or unproved line | `SDD-RUN-04` |
| 3 | delivery: every traced `AC-*` got a met or unmet line | `SDD-PLAN-07` |
| 4 | nothing outside what is checked failed the review, except a blocking security defect or regression | `SDD-RUN-04` |
| 5 | every line cites `file:line` or names what is missing | `CC-SES-10` |

## Example

Layer review of `L2a` (people repository). Gates: `pass`. Surface: all files inside `src/db/`. C6 and C8 proved by `people.test.ts:12-58`. C7 ("two writes of one email at once leave one person") has a test, but it awaits the inserts one after the other: it would pass with the race open, so C7 is `unproved`. **Must hold** "creation time is the server clock — AC-02" holds: `created_at` defaults in `schema.ts:14` and the insert never sets it. Note: "`countPeople` scans the table; fine at this size" — non-blocking.

```
## Verdict: unmet

## Unmet
- C7 (AC-29) unproved: the two inserts are awaited in sequence, not at once — src/db/people.test.ts:61

## Proved
- C6 (AC-29) src/db/people.test.ts:12 · C8 (AC-02) src/db/people.test.ts:44

## Notes (non-blocking)
- countPeople scans the table
```
