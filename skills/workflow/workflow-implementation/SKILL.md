---
name: workflow-implementation
description: Runs approved features until their gates are green — picks the ready ones from the PRD's waves (bundle approved, providers merged, no open gap, Surfaces disjoint, a slot free), spawns each in its own worktree through the harness scripts, has the implementer role write the code and the contract's checks, runs the gates, sends a failing gate back without spending a fix round, and resumes the implementer for each fix round the review asks for — holding only one state file per feature, citing `SDD-RUN-*`, `SDD-CORE-*` and `SDD-FLOW-*` IDs. Use when bundles in `.specs/features/` are approved and the person asks to implement, run or continue them, or when workflow-review leaves a feature in `fixing`. Not for writing a bundle (workflow-plan), deciding whether a contract is met or delivering (workflow-review).
type: skill
family: workflow
language: en
source: "[Delivery Flow — Spec Driven Development](../docs/delivery-flow.md)"
tags:
  - skill
  - workflow
  - implementation
  - orchestration
---

# workflow-implementation

> **Delegation (`SDD-CORE-02`).** This phase routes; it writes no code and judges nothing. Each feature's implementer runs detached, in its own worktree, calling its role as a subagent through `references/template-brief.md`. Everything mechanical is a script (`SDD-CORE-05`).
> **Context (`SDD-CORE-04`, `SDD-FLOW-03`).** Hold one state file per feature (`references/template-state.md`) and nothing else: never a diff, a gate log or a review report. Scripts print a short summary; the run leaves one result line. The state file is the only thing this phase passes to `workflow-review`.

Rules this phase implements: [Delivery Flow — Spec Driven Development](../docs/delivery-flow.md) §3, §5.1, §5.2 steps 1–3, §6, `SDD-RUN-01`–`SDD-RUN-03`, `SDD-RUN-05`, `SDD-RUN-07`, `SDD-FLOW-03`.

## Scope

| The state is... | Go to |
| --- | --- |
| approved bundles with no state file, or `waiting` | this phase, Step 1 |
| `running`, `gates-failed` or `fixing` | this phase, Step 3 or Step 4 |
| `in-review`, `contract-met`, or a blocking note | `workflow-review` |
| a bundle that is not `Approved` | `workflow-plan` |

## Step 0: Preconditions

| Check | How | If it fails |
| --- | --- | --- |
| the PRD is `Approved` | the status line of `.specs/PRD.md` | stop: `workflow-plan` |
| the harness exists | `test -x init.sh && ls scripts/` shows the five scripts and `sdd.config.sh` exists | stop: run the `scaffold-sdd-scripts` command |
| `.sdd/` is git-ignored | `git check-ignore -q .sdd` | add `.sdd/` to `.gitignore` |

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

Write the brief from `references/template-brief.md`, first-run body, with the role from `plan.md`'s `owner` field, then run the script. It creates the worktree and branch from the `base` in `plan.md`, runs `init.sh` inside it (which resolves the environment and migrates its own database, `SDD-SCR-03`), starts the agent detached and records its pid (`SDD-RUN-02`). Set the state to `running` and `started` to now.

## Step 3: When a run ends

The run is over when `.sdd/run/<ID>.exit` exists. Read only `.sdd/run/<ID>.result`:

| `.result` | Next |
| --- | --- |
| `done` | `scripts/run-gates <ID>`; write its one-line summary to `gates` |
| `gap: <question>` | state `waiting`, the question under `gaps`; hand it to `workflow-plan` as a new item from a gap, or to the owner when it changes what the product promises (`SDD-RUN-07`) |
| missing, or `.exit` non-zero | state `waiting`; tell the owner the run failed and give the log path, not its content |

| Gates | Next |
| --- | --- |
| `fail` | state `gates-failed`; resume the implementer with the fix-round brief, listing only the failing gates. This does **not** count as a fix round, and `round` does not change (`SDD-RUN-03`) |
| `pass` | state `in-review`. The feature now belongs to `workflow-review` |

## Step 4: A fix round

`workflow-review` leaves a feature in `fixing` with `round` already raised and the unmet `AC-*` and failing checks in `review`. Write the fix-round brief with exactly those IDs, verbatim, and resume the same implementer:

```bash
scripts/spawn-detached F02-approval --brief .sdd/run/F02-approval.brief.md --resume
```

When its `.result` says `done`, go back to Step 3: gates first, then `in-review`. This phase never raises `round` and never decides how many rounds are left; the review does (`SDD-RUN-05`, `SDD-FLOW-03`).

## Step 5: Hand off

When at least one feature is `in-review`, or nothing is `running`, the next phase is `workflow-review`. When it hands features back as `fixing`, or merges a provider so that consumers become ready, this phase runs again from Step 1. Do not load another phase from inside this one (`SDD-FLOW-04`).

Report one line per feature that changed: ID, status, and the next phase.

## Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | no feature started before every provider merged | `SDD-RUN-01` |
| 2 | every feature ran in its own worktree, started by `spawn-detached` | `SDD-RUN-02` |
| 3 | gates ran after every implement and fix run; a gate failure never counted as a round | `SDD-RUN-03` |
| 4 | a fix-round brief listed only the IDs the review wrote to the state file | `SDD-RUN-05` |
| 5 | an implementer's question became a gap, not an answer this phase picked | `SDD-RUN-07` |
| 6 | this conversation holds state files, not diffs, logs or reports | `SDD-CORE-04`, `SDD-FLOW-03` |

## Example

PRD approved; F01 and F02 bundles approved; F02 consumes from F01. Step 0 passes. Step 1: F01 is ready; F02 waits on F01. Step 2: `spawn-detached F01-quote-link`. Step 3: `.result` says `done`, and `run-gates` reports `fail — G1 lint`; state `gates-failed`, the implementer is resumed with G1 only, `round` stays 0. Its next `.result` says `done`, and `run-gates` reports `pass — 6 checks, 2 gates`; state `in-review`. Step 5: the next phase is `workflow-review`. After F01 merges there, this phase runs again: F02 is ready.
