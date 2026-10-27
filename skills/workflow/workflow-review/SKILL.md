---
name: workflow-review
description: Decides whether each feature in review met its contract and delivers it — a new code-reviewer instance checks the contract with only `contract.md`, the Surface, the diff and the gate summary, devops-security joins for a security-class feature, a met contract becomes a pushed branch and a PR under the owner's authorization, an unmet one goes back to workflow-implementation for at most two fix rounds and then to workflow-plan as a new item — holding only one state file per feature, citing `SDD-RUN-04`–`SDD-RUN-08`, `SDD-SPEC-06` and `SDD-FLOW-*` IDs. Use when a feature's state is `in-review`, when the person asks to review, deliver or open the PR of a run, or for the run's final report. Not for a general code review outside a run (code-reviewer with the family review skills), implementing a fix (workflow-implementation), nor writing the new item (workflow-plan).
type: skill
family: workflow
language: en
source: "[Delivery Flow — Spec Driven Development](../docs/delivery-flow.md)"
tags:
  - skill
  - workflow
  - review
  - orchestration
---

# workflow-review

> **Delegation (`SDD-CORE-02`).** This phase routes; it reviews nothing itself. The review goes to a new `code-reviewer` instance, called by name as a subagent, with the procedure in `references/contract-review.md`; a security-class feature adds `devops-security`; a PR body that needs reading the bundle goes to `repo-operator`.
> **Context (`SDD-CORE-04`, `SDD-FLOW-03`).** Hold one state file per feature and nothing else: never a diff, a gate log or a review report. The reviewer returns a verdict; only its IDs reach the state file, and the state file is the only thing this phase passes back to `workflow-implementation`.

Rules this phase implements: [Delivery Flow — Spec Driven Development](../docs/delivery-flow.md) §4.3 "The contract", §5.2 steps 4–5, §5.3, §5.6, `SDD-SPEC-06`, `SDD-RUN-04`–`SDD-RUN-08`, `SDD-FLOW-02`, `SDD-FLOW-03`.

## Scope

| The state is... | Go to |
| --- | --- |
| `in-review` with gates `pass` | this phase, Step 1 |
| `contract-met` | this phase, Step 3 |
| a `blocking` entry, or `unmet` after round 2 | this phase, Step 4 |
| `waiting`, `running`, `gates-failed` or `fixing` | `workflow-implementation` |
| a review of code outside a run | `code-reviewer`, with the family review skills |

## Step 0: Push and PR authorization

Ask once per run, before the first delivery: "authorize push and PR for this run, or per wave?". Quote the owner's words in each state file's `authorization`. Without them, features stop at `contract-met`. Merging on the owner's behalf is covered only if the owner said so in those words (`SDD-RUN-08`).

## Step 1: Review against the contract

For each feature in `in-review`, start a **new** `code-reviewer` instance — never one that saw this feature before — with exactly these inputs (`SDD-RUN-04`):

| Input | Value |
| --- | --- |
| procedure | the absolute path of `references/contract-review.md`, from this skill's base directory |
| contract | `.specs/features/<ID>-<slug>/contract.md` |
| Surface | the Surface lines of `plan.md` |
| diff | `git -C <worktree> diff <base>...HEAD` (the reviewer runs it; you pass the command) |
| gates | the state file's `gates` line |
| open findings | on a delta re-review only: the state file's `review` line |

For `risk: security`, start `devops-security` at the same time on the sensitive path; its result is G3. Reviews of different features go out side by side; they only read.

## Step 2: Write the verdict

Write the verdict to the state file as IDs only:

| Verdict | State | Next |
| --- | --- | --- |
| `met`, and G3 clean when listed | `contract-met` | Step 3 |
| `unmet`, `round` < 2 | `fixing`, `round` + 1; the unmet `AC-*` and failing checks under `review`, verbatim | `workflow-implementation`, Step 4; after its gates, back here for a delta re-review with the open findings |
| `unmet`, `round` = 2 | stop fixing (`SDD-RUN-05`) | Step 4 |
| any `blocking` note | `waiting`, the note under `blocking` | ask the owner whether it becomes a new item before merge |

Non-blocking notes go under `notes`; they never fail the review. This phase owns `round`: it raises it, and it is the only phase that reads it to decide (`SDD-FLOW-03`).

## Step 3: Deliver

With `authorization` set, push the branch and open the PR, its body from `references/template-pr.md` filled from the state file and the contract's **Met when** line. Run one known command each, here; use `repo-operator` when the body needs reading the bundle. Merge only if the owner's words cover it; otherwise report the PR link and leave the merge to the owner. Then `scripts/stop <ID>`, state `merged`, `finished` to now. Every consumer of this feature may now be ready: that is `workflow-implementation`'s Step 1.

## Step 4: New item or gap

Nothing goes back to search, and no bundle is reopened (`SDD-FLOW-02`):

| Case | Next |
| --- | --- |
| `unmet` after round 2 | hand `workflow-plan` a **new item**: the feature ID, the failing checks and the branch. The owner approves the new item (state `split`, `next` set) or drops the feature (state `dropped`) (`SDD-RUN-06`) |
| a blocking note the owner turns into a new item | the same, with the note as the input |
| a gap that changes what the product promises | ask the owner; the answer goes to `workflow-plan` as a PRD amendment |

There is no third fix round and no move to a higher tier.

## Step 5: Report and hand off

When nothing is `in-review` or `contract-met`, report one line per feature: ID, status, PR link or `next`, and the open owner questions. Nothing else. Then name the next phase: `workflow-implementation` when features are `fixing` or newly ready, `workflow-plan` when a new item is waiting to be written. Do not load another phase from inside this one (`SDD-FLOW-04`).

## Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | every review ran in a new instance with only the four inputs and the procedure | `SDD-RUN-04` |
| 2 | a contract counted as met only when every traced `AC-*` was proved | `SDD-SPEC-06` |
| 3 | no feature got a third fix round | `SDD-RUN-05` |
| 4 | a feature failing round 2 became a new item or was dropped by the owner; nothing went back to search | `SDD-RUN-06`, `SDD-FLOW-02` |
| 5 | nothing merged without its contract met and the owner's authorization | `SDD-RUN-08` |
| 6 | only IDs and one-line verdicts reached the state file | `SDD-CORE-04`, `SDD-FLOW-03` |

## Example

Step 0: the owner answers "pode abrir PR por onda", quoted in each state file. F01 is `in-review` with `pass — 6 checks, 2 gates`. Step 1: a new `code-reviewer` with the procedure path, F01's contract, Surface, diff command and gates line. It says `met`. Step 3: push, PR; the owner merges; F01 `merged`; next phase `workflow-implementation`, where F02 becomes ready. Later, F02's first review: `unmet — AC-05 unproved, C5 failing`; state `fixing`, `round` 1; back to `workflow-implementation`. The delta re-review: still `unmet — C5 failing`; `round` 2. After the second fix: still failing. Step 4: `workflow-plan` gets a new item from F02's failing checks and branch; it writes `F02.1-expiry-timezone`; the owner approves it; F02 `split`, `next: F02.1`.
