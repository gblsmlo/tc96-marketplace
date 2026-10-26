---
name: workflow-review
description: Runs phase 4 of the delivery flow v2 — for a feature whose gates are green, starts a new `code-reviewer` with `sdd-contract-review` and only the contract, the Surface, the diff and the gate summary, decides met or unmet by `AC-*`, sends a failing check back to the lane that owns it for at most two fix rounds, turns a feature still failing into a new item for Plan, escalates a security defect or a regression of a merged contract to the owner, and on met opens the PR under the owner's authorization and marks the merge so consumers can start, citing handoffs `H12`–`H17` and `SDD-RUN-03`–`SDD-RUN-08`. In a project on the delivery flow v2 (`story.md` bundles), use when a feature's state is `in-review`, or someone asks to review, approve, merge or close a feature of the run. Not for a general code review outside a run (the family review skills), the reviewer's own checklist (sdd-contract-review), nor writing the new item (workflow-plan).
type: skill
family: workflow
language: en
source: "workflow/foundations/phases.md §4 (Draft, 2026-10-26)"
tags:
  - skill
  - workflow
  - review
---

# workflow-review

> **Delegation (`SDD-CORE-02`).** This skill routes; it reviews nothing itself. The verdict comes from a new `code-reviewer` instance with `sdd-contract-review`; a security-class feature adds `devops-security`; a fix goes back to the run that owns the failing check through `workflow-implementation`'s lane brief; a new item goes to `workflow-plan`.
> **Context (`SDD-CORE-04`).** Hold the state file only. Verdicts come back as IDs.
> **Status.** Draft. Review is unchanged from the SDD flow; this skill implements `workflow/foundations/phases.md` §4 and `workflow/foundations/handoffs.md` `H12`–`H17`.

## Step 0: Preconditions

| Check | If it fails |
| --- | --- |
| state `in-review` and `gates: pass` | back to `workflow-implementation`; a red gate never reaches review (`SDD-RUN-03`) |
| push and PR authorization, asked once: "authorize push and PR for this run, or per wave?" | ask; without it, features stop at `contract-met` (`SDD-RUN-08`) |

## Step 1: Review against the contract (`H12`)

Start a **new** `code-reviewer` instance, never one that saw this feature, with `sdd-contract-review` and exactly these inputs (`SDD-RUN-04`):

| Input | Value |
| --- | --- |
| contract | `.specs/features/<ID>-<slug>/contract.md` |
| Surface | the `surface` list of `contract.md`'s frontmatter (default D1) |
| diff | `git -C <worktree> diff <base>...HEAD` (the reviewer runs it) |
| gates | the state file's `gates` line |
| open findings | delta re-review only: the state file's `review` line |

`design.md` is in the diff and in the Surface; the reviewer checks it only through the contract checks that cite it. For `risk: security`, start `devops-security` at the same time on the sensitive path; its result is G3.

## Step 2: Route the verdict

| Verdict | State | Next |
| --- | --- | --- |
| `met`, G3 clean when listed | `contract-met` | Step 4 |
| `unmet`, `round` < 2 | `fixing`, `round` + 1 | Step 3 (`H13`) |
| `unmet`, `round` = 2 | stop fixing (`SDD-RUN-05`) | Step 5 (`H14`) |
| a `blocking` note | `waiting`, the note under `blocking` | ask the owner whether it becomes a new item before merge (`H15`) |

Non-blocking notes go under `notes`; they never fail the review.

## Step 3: Fix round (`H13`)

1. Group the failing checks by the lane tag in `contract.md`; an unmet `AC-*` with no failing check goes to the lane of its checks.
2. For each code run in `runs` that owns a failing check, write the fix-round brief of `template-lane-brief.md` (in `workflow-implementation`) with only its checks, verbatim, and start it with `scripts/spawn-detached <ID> --brief <path> --resume`.
3. When every fix run is `done`, run `scripts/run-gates <ID>`; then a new reviewer, with the open findings (delta re-review). Back to Step 2.

A fix never widens the contract. There is no third round and no move to a higher tier.

## Step 4: Deliver (`H16`, `H17`)

With `authorization` set: push the branch and open the PR, body from `template-pr.md` of `sdd-orchestrator`, filled from the state file and the contract's **Met when** line. One known command each, run here; or `repo-operator` when the body needs reading the bundle. Merge only if the owner's words cover it; otherwise report the PR link. Then `scripts/stop <ID>`, state `merged`, `finished` to now. Every consumer of this feature now re-checks its code start in `workflow-implementation` Step 1.

## Step 5: New item (`H14`)

Run `workflow-plan` in **new item** mode with the feature ID, the failing checks verbatim and the failing branch. The owner approves the new item (state `split`, `next` set; its consumers keep waiting for it) or drops the feature (state `dropped`) (`SDD-RUN-06`).

## Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | gates were green before every review | `SDD-RUN-03` |
| 2 | every review ran in a new instance with only the four inputs | `SDD-RUN-04` |
| 3 | every fix went only to the runs that own a failing check | `H13` |
| 4 | no feature got a third fix round | `SDD-RUN-05` |
| 5 | a feature failing round 2 became a new item or was dropped by the owner | `SDD-RUN-06` |
| 6 | nothing merged without its contract met and the owner's authorization | `SDD-RUN-08` |
| 7 | this conversation holds state files, not diffs or reports | `SDD-CORE-04` |

## Example

F03 `in-review`, `gates: pass`, runs `[backend, frontend+qa]`. Step 1: reviewer returns `unmet — AC-03 unproved, C4 failing`. Step 2: round 1. Step 3: C4 is tagged `backend`; only the backend run resumes, with C4 verbatim. Gates pass; a new reviewer on the delta returns `met`. Step 4: the owner authorized PRs per wave; push, PR, the owner merges; F03 `merged`. F04 and F05 re-check their start.

**Anti-pattern.** Resuming every run of the feature with the whole review report. Corrected: only the run that owns C4, with C4 alone; the others keep their commits untouched.
