# Contract review — the reviewer's procedure

> **Who reads this.** A new `code-reviewer` instance, called by name as a subagent and independent
> of the feature's author (`SDD-CORE-02`). `workflow-review` hands it this file's absolute path
> together with the four inputs below. It decides one thing: is the contract met? It never fixes,
> never widens the contract, and never reads the conversation that produced the change
> (`CC-SES-07`).

Rules this procedure implements: [Delivery Flow — Spec Driven Development](../../../docs/workflow/delivery-flow.md)
§4.3 "The contract", §5.3, `SDD-SPEC-06`, `SDD-RUN-04`.

## Input

Exactly these, and nothing else. A missing one is the first line of the verdict, not a guess.

| Input | What it holds |
| --- | --- |
| contract | the path to the feature's `contract.md` |
| Surface | the Surface lines of `plan.md` |
| diff | the command that produces it, `git -C <worktree> diff <base>...HEAD` |
| gates | the one-line summary from `run-gates` |
| open findings | delta re-review only: the previous verdict's unmet `AC-*` and check IDs |

## Step 1: Gates first

The gate summary must say `pass`. If it says `fail`, return `unmet — gates failed` and stop: `workflow-review` should not have sent it (`SDD-RUN-03`).

## Step 2: Surface

Run `git -C <worktree> diff --name-only <base>...HEAD` and compare with the Surface. Each file outside it is a finding, with the path, before reading any code.

## Step 3: Each check

For each check in **Checks** and **Non-functional gates**:

1. Find what implements it in the diff: the test, the assertion, or for `static` the gate line in the summary.
2. Confirm the gate type matches the contract's (a check declared `unit` proved only by an E2E is a finding: the cost the contract chose was not respected).
3. Confirm it **observes the outcome the line states**, the one a person would see, not an internal call or a private field. A test that would pass with the behavior broken does not prove the check.

Mark each check `proved` or `unproved`, with the `file:line` of what proves it, or what is missing.

## Step 4: Each acceptance criterion (`SDD-SPEC-06`)

Go through **Met when**, one `AC-*` at a time. An `AC-*` is **met** only when every check that line names is `proved` and passing. Then:

- an `AC-*` the `traces` field lists but **Met when** does not name is unmet: `AC-NN has no check`;
- a check that names no `AC-*` and is not a non-functional gate proves nothing; it does not count toward any criterion.

The contract is met only when every traced `AC-*` is met and every non-functional gate is green. Green checks that cover no `AC-*` never close it.

## Step 5: Outside the contract

What you notice outside the contract and the Surface is a **note**, one line, non-blocking. Two exceptions block the merge, as **blocking**: a security defect (an unauthenticated path to data, a secret in code, an injection), and a regression of a contract that already merged (a provided shape another feature consumes, changed). Neither counts as a fix round; the owner decides.

Do not load the family review skills for a full audit: that is not this review's question. Load one only when a check names a family rule as its proof.

## Output format

At most 25 lines:

```
## Verdict: met | unmet

## Unmet
- AC-NN — C2 unproved: <what is missing, one line> — path:line
- C4 — gate type: declared unit, proved only by e2e — path:line
- outside Surface: path

## Proved
- AC-NN by C1 (path:line), C2 (path:line)

## Notes (non-blocking)
- <one line>

## Blocking
- security | regression: <one line> — path:line
```

`## Unmet` is empty on `met`. `workflow-review` copies only the IDs into the state file.

## Delta re-review

After a fix round, a new instance receives the open findings and reads the diff since the last reviewed commit:

1. Run Steps 1 and 2 on the fix diff.
2. For each open `AC-*` and check: `proved` (cite the fix's `file:line`) or still `unproved`.
3. Raise a new item under **Unmet** only where the fix broke a check that was proved before.
4. Re-read the whole change only when the fix diff leaves the Surface or touches a provided shape; say why in the verdict.

## Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | only the four inputs were used; no conversation, no PRD | `SDD-RUN-04` |
| 2 | every traced `AC-*` got a met or unmet line | `SDD-SPEC-06` |
| 3 | no check that names no `AC-*` was counted toward a criterion | `SDD-SPEC-06` |
| 4 | nothing outside the contract failed the review, except a blocking security defect or regression | `SDD-RUN-04` |
| 5 | every line cites `file:line` or names what is missing | `CC-SES-10` |

## Example

Contract of `F02-approval`: traces `AC-01`–`AC-05`; **Met when** names C1–C5 and G1–G3. Gates: `pass`. Surface: all files inside. C1–C4 proved by `approval.test.ts:12-58`. C5 ("approving at 00:00 on day 31 returns 410") has a test, but it builds the date in UTC, while the line states the seller's time zone: it would pass with the time-zone rule broken, so C5 is `unproved`. `AC-05` is unmet. Note: "the 410 body has no error code; consumers may want one" — non-blocking.

```
## Verdict: unmet

## Unmet
- AC-05 — C5 unproved: test builds the deadline in UTC, the line states the seller's time zone — src/quotes/approval.test.ts:61

## Proved
- AC-01 by C1 (src/quotes/approval.test.ts:12) … AC-04 by C4 (src/quotes/approval.test.ts:50)

## Notes (non-blocking)
- 410 body carries no error code
```
