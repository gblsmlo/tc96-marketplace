---
name: sdd-orchestrator
description: Runs approved features of the Spec Driven Development flow to merge — picks the ready ones from the PRD's waves (providers merged, bundle approved, Surfaces disjoint, a slot free), spawns each in its own worktree through the harness scripts, runs the gates, has a fresh reviewer check the contract, gives a failed review at most two fix rounds and then hands the feature to the Spec Writer as a new item, and opens the PR under the owner's authorization — holding only one state file per feature, citing `SDD-RUN-*` and `SDD-CORE-*` IDs. Use when bundles in `.specs/features/` are approved and the person asks to implement, run, deliver or continue them. Not for writing the PRD (spec-prd) or a bundle (sdd-spec-writer), nor for reviewing a diff outside a run (code-reviewer).
type: skill
family: sdd
language: en
source: "[Delivery Flow — Spec Driven Development](../../../knowledge-base/fluxo-de-entrega-sdd.md)"
tags:
  - skill
  - sdd
  - orchestration
---

# sdd-orchestrator

> **Delegation (`SDD-CORE-02`).** This skill routes; it writes no code and reviews nothing. Each feature's implementer runs detached, in its own worktree, calling its role as a subagent through `references/template-brief.md`; the review goes to a new `code-reviewer` instance with `sdd-contract-review`; a security-class feature adds `devops-security`; a split goes to `sdd-spec-writer`. Everything mechanical is a script (`SDD-CORE-05`).
> **Context (`SDD-CORE-04`).** Hold one state file per feature (`references/template-state.md`) and nothing else: never a diff, a gate log or a review report. Scripts print a short summary; agents return IDs and one-line verdicts.

Contract this skill implements: [Delivery Flow — Spec Driven Development](../../../knowledge-base/fluxo-de-entrega-sdd.md) §3, §5 and `SDD-RUN-*`.

## Step 0: Preconditions

| Check | How | If it fails |
| --- | --- | --- |
| the PRD is `Approved` | the status line of `.specs/PRD.md` | stop: `spec-prd` |
| the harness exists | `test -x init.sh && ls scripts/` shows the five scripts and `sdd.config.sh` exists | stop: run the `scaffold-sdd-scripts` command |
| `.sdd/` is git-ignored | `git check-ignore -q .sdd` | add `.sdd/` to `.gitignore` |
| push and PR authorization | the owner's words, asked once: "authorize push and PR for this run, or per wave?" | ask; without it, features stop at `contract-met` |

Merging on the owner's behalf is covered only if the owner said so in those words (`SDD-RUN-08`).

## Step 1: Build the ready list

Read the PRD's **Functionalities** and **Dependency Graph** sections only, and every file in `.sdd/state/`. Create a `waiting` state file for each approved folder in `.specs/features/` that has none.

A feature is ready when all hold (`SDD-RUN-01`):

1. its bundle's three files (or two, in the fast lane) are `Approved`;
2. every feature it consumes from is `merged`;
3. its state file has no open `gaps` and no `blocking` entry;
4. the Surface line of its `plan.md` shares no path with a `running`, `fixing` or `in-review` feature;
5. fewer than the wave width (default 4, or the project's recorded value) are `running` or `fixing`.

Ready features start in PRD priority order inside their wave. Waves are how the PRD reads; a ready feature in `W2` does not wait for an unrelated `W1` feature.

## Step 2: Start a feature

```bash
scripts/spawn-detached F02-approval --brief .sdd/run/F02-approval.brief.md
```

Write the brief from `references/template-brief.md`, first-run body, with the role from `plan.md`'s `owner` field, then run the script. A fix round passes the fix-round brief and `--resume`. It creates the worktree and branch from the `base` in `plan.md`, runs `init.sh` inside it (which resolves the environment and migrates its own database, `SDD-SCR-03`), starts the agent detached, and records its pid. Set the state to `running`, `started` to now.

## Step 3: When the run ends

The run is over when `.sdd/run/<ID>.exit` exists. Read only `.sdd/run/<ID>.result`:

| `.result` | Next |
| --- | --- |
| `done` | `scripts/run-gates <ID>`; write its one-line summary to `gates` |
| `gap: <question>` | state `waiting`, the question under `gaps`; Step 6 |
| missing, or `.exit` non-zero | state `waiting`; tell the owner the run failed and give the log path, not its content |

Gates `fail` → state `gates-failed`; resume the implementer with the fix-round brief, listing only the failing gates; this does **not** count as a fix round (`SDD-RUN-03`). Gates `pass` → Step 4.

## Step 4: Review against the contract

Start a **new** `code-reviewer` instance — never one that saw this feature before — with the skill `sdd-contract-review` and exactly these inputs (`SDD-RUN-04`):

| Input | Value |
| --- | --- |
| contract | `.specs/features/<ID>-<slug>/contract.md` |
| Surface | the Surface lines of `plan.md` |
| diff | `git -C <worktree> diff <base>...HEAD` (the reviewer runs it; you pass the command) |
| gates | the state file's `gates` line |
| open findings | on a re-review only: the state file's `review` line |

For `risk: security`, start `devops-security` at the same time on the sensitive path; its result is G3.

Write the verdict to the state file as IDs only:

| Verdict | State |
| --- | --- |
| `met` (and G3 clean, when listed) | `contract-met`; Step 5 |
| `unmet`, `round` < 2 | `fixing`, `round` + 1; resume the implementer with the fix-round brief, listing the unmet `AC-*` and failing checks verbatim; when its `.result` says `done`, back to Step 3's gates, then a new reviewer with the open findings (delta re-review) |
| `unmet`, `round` = 2 | stop fixing (`SDD-RUN-05`); Step 6 |
| any `blocking` note | `waiting`, the note under `blocking`; ask the owner whether it becomes a new item before merge |

Non-blocking notes go under `notes`; they never fail the review.

## Step 5: Deliver

With `authorization` set: push the branch and open the PR, body from `references/template-pr.md` filled from the state file and the contract's **Met when** line. One known command each, run here; or `repo-operator` when the body needs reading the bundle. Merge only if the owner's words cover it; otherwise report the PR link and leave the merge to the owner. Then `scripts/stop <ID>`, state `merged`, `finished` to now, and back to Step 1: every consumer of this feature may now be ready.

## Step 6: Split or gap

| Case | Next |
| --- | --- |
| `unmet` after round 2 | run `sdd-spec-writer` in **new item** mode with the feature ID, the failing checks and the branch; the owner approves the new item (state `split`, `next` set) or drops the feature (state `dropped`) (`SDD-RUN-06`) |
| a gap that changes what the product promises | ask the owner; the answer goes to `spec-prd` as an amendment |
| any other gap | run `sdd-spec-writer` in **new item** mode with the gap (`SDD-RUN-07`) |

There is no third fix round and no move to a higher tier.

## Step 7: Report

When nothing is ready and nothing is running, report one line per feature: ID, status, PR link or `next`, and the open owner questions. Nothing else.

## Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | no feature started before every provider merged | `SDD-RUN-01` |
| 2 | every feature ran in its own worktree, started by `spawn-detached` | `SDD-RUN-02` |
| 3 | gates ran before every review; a gate failure never counted as a round | `SDD-RUN-03` |
| 4 | every review ran in a new instance with only the four inputs | `SDD-RUN-04` |
| 5 | no feature got a third fix round | `SDD-RUN-05` |
| 6 | a feature failing round 2 became a new item or was dropped by the owner | `SDD-RUN-06` |
| 7 | nothing merged without its contract met and the owner's authorization | `SDD-RUN-08` |
| 8 | this conversation holds state files, not diffs, logs or reports | `SDD-CORE-04` |

## Example

PRD approved; F01 and F02 bundles approved; F02 consumes from F01. Step 0: the owner answers "pode abrir PR por onda". Step 1: F01 ready, F02 waiting on F01. Step 2: `spawn-detached F01-quote-link`. Step 3: `.result` says `done`; `run-gates` → `pass — 6 checks, 2 gates`. Step 4: reviewer says `met`. Step 5: push, PR, the owner merges; F01 `merged`. Step 1 again: F02 ready. Its first review: `unmet — AC-05 unproved, C5 failing`. Round 1: still `unmet — C5 failing`. Round 2: still failing. Step 6: `sdd-spec-writer` writes `F02.1-expiry-timezone` from the failing branch; the owner approves it; F02 `split`, `next: F02.1`, and F02.1 enters the ready list.
