---
name: workflow-implementation
description: Runs the layers of an approved delivery until their gates are green — picks the ready ones from the plan's index (delivery approved, the layers they depend on merged into the feature branch, no open gap, Surfaces disjoint, a slot free), spawns each in its own worktree on a branch cut from the delivery's feature branch through the harness scripts, has the layer's owner load the skills the layer names and build it, runs the gates, sends a failing gate back without spending a fix round, resumes the implementer for each fix round the review asks for, and keeps the index's Status column — holding only one state file per layer, citing `SDD-RUN-*`, `SDD-PLAN-11`, `SDD-CORE-*` and `SDD-FLOW-*` IDs. Use when a delivery in `.specs/delivery/` is approved and the person asks to implement, run or continue it, or when workflow-review leaves a layer in `fixing`. Not for writing the plan (workflow-plan), deciding whether a layer or the delivery is met, nor delivering (workflow-review).
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

> **Delegation (`SDD-CORE-02`).** This phase routes; it writes no code and judges nothing. Each layer's implementer runs detached, in its own worktree, calling its owner role as a subagent through `references/template-brief.md`. Everything mechanical is a script (`SDD-CORE-05`).
> **Context (`SDD-CORE-04`, `SDD-FLOW-03`).** Hold one state file per layer (`references/template-state.md`) and the index's Status column, and nothing else: never a diff, a gate log or a review report. Scripts print a short summary; the run leaves one result line. The state file is the only thing this phase passes to `workflow-review`.

Rules this phase implements: [Delivery Flow — Spec Driven Development](../docs/delivery-flow.md) §3, §5.1, §5.2 steps 1–3, §6, `SDD-RUN-01`–`SDD-RUN-03`, `SDD-RUN-05`, `SDD-RUN-07`, `SDD-PLAN-11`, `SDD-FLOW-03`.

## Scope

| The state is... | Go to |
| --- | --- |
| an approved delivery with layers that have no state file, or `waiting` | this phase, Step 1 |
| `running`, `gates-failed` or `fixing` | this phase, Step 3 or Step 4 |
| `in-review`, `checks-met`, a blocking note, or every layer `merged` | `workflow-review` |
| a delivery that is not `Approved` | `workflow-plan` |

## Step 0: Preconditions

| Check | How | If it fails |
| --- | --- | --- |
| the delivery is `Approved` | the status line of `.specs/delivery/<id>/plan.md` | stop: `workflow-plan` |
| the harness exists | `test -x init.sh && ls scripts/` shows the five scripts and `sdd.config.sh` exists | stop: run the `scaffold-sdd-scripts` command |
| `.sdd/` is git-ignored | `git check-ignore -q .sdd` | add `.sdd/` to `.gitignore` |

## Step 1: Build the ready list

Read the index's frontmatter and layers table only (`.specs/delivery/<id>/plan.md`), and every file in `.sdd/state/<id>/`. Create a `waiting` state file for each layer row that has none.

A layer is ready when all hold (`SDD-RUN-01`):

1. the delivery is `Approved`;
2. every layer in its **Depends on** cell is `merged`;
3. its state file has no open `gaps` and no `blocking` entry;
4. the Surface of its layer file shares no path with a `running`, `fixing` or `in-review` layer;
5. fewer than the width (default 4, or the project's recorded value) are `running` or `fixing`.

Ready layers start in the index's order. A ready layer never waits for an unrelated one.

## Step 2: Start a layer

```bash
scripts/spawn-detached 2026-10-27-quote-approval L2a --brief .sdd/run/2026-10-27-quote-approval/L2a.brief.md
```

Write the brief from `references/template-brief.md`, first-run body, with the layer's `owner` and the skill names on its **Skills** line, verbatim, then run the script. It creates the delivery's feature branch from the trunk when it does not exist yet, then the layer's worktree on `feat/<delivery>-<layer>` cut from the feature branch, runs `init.sh` inside it (which resolves the environment and migrates its own database, `SDD-SCR-03`), starts the agent detached and records its pid (`SDD-RUN-02`). Set the state to `running` and `started` to now.

**The index's progress (`SDD-PLAN-11`).** This phase is the only writer of the index's Status column while layers run: `running` when a layer starts, `in-review` when its gates pass, `gates-failed`, `fixing` or `waiting` as its state file says. Each change is one cell, committed on the feature branch. A layer run never touches `plan.md`.

## Step 3: When a run ends

The run is over when `.sdd/run/<id>/<layer>.exit` exists. Read only `.sdd/run/<id>/<layer>.result`:

| `.result` | Next |
| --- | --- |
| `done` | `scripts/run-gates <id> <layer>`; write its one-line summary to `gates` |
| `gap: <question>` | state `waiting`, the question under `gaps`; hand it to `workflow-plan` as a new layer from a gap, or to the owner when it changes what the product promises (`SDD-RUN-07`) |
| missing, or `.exit` non-zero | state `waiting`; tell the owner the run failed and give the log path, not its content |

| Gates | Next |
| --- | --- |
| `fail` | state `gates-failed`; resume the implementer with the fix-round brief, listing only the failing gates. This does **not** count as a fix round, and `round` does not change (`SDD-RUN-03`) |
| `pass` | state `in-review`. The layer now belongs to `workflow-review` |

## Step 4: A fix round

`workflow-review` leaves a layer in `fixing` with `round` already raised and the failing checks and broken rules in `review`. Write the fix-round brief with exactly those IDs, verbatim, and resume the same implementer:

```bash
scripts/spawn-detached 2026-10-27-quote-approval L2a --brief .sdd/run/2026-10-27-quote-approval/L2a.brief.md --resume
```

When its `.result` says `done`, go back to Step 3: gates first, then `in-review`. This phase never raises `round` and never decides how many rounds are left; the review does (`SDD-RUN-05`, `SDD-FLOW-03`).

## Step 5: Hand off

When at least one layer is `in-review`, every layer is `merged`, or nothing is `running`, the next phase is `workflow-review`. When it hands layers back as `fixing`, or merges a layer so that others become ready, this phase runs again from Step 1. Do not load another phase from inside this one (`SDD-FLOW-04`).

Report one line per layer that changed: layer, status, and the next phase.

## Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | no layer started before every layer it depends on merged into the feature branch | `SDD-RUN-01` |
| 2 | every layer ran in its own worktree, on a branch cut from the feature branch by `spawn-detached`, with a brief naming its skills | `SDD-RUN-02` |
| 3 | gates ran after every implement and fix run; a gate failure never counted as a round | `SDD-RUN-03` |
| 4 | a fix-round brief listed only the IDs the review wrote to the state file | `SDD-RUN-05` |
| 5 | an implementer's question became a gap, not an answer this phase picked | `SDD-RUN-07` |
| 6 | only this phase and the review wrote the index's Status cells; no layer run edited `plan.md` | `SDD-PLAN-11` |
| 7 | this conversation holds state files, not diffs, logs or reports | `SDD-CORE-04`, `SDD-FLOW-03` |

## Example

Delivery `2026-10-27-quote-approval` approved; index rows `L1a` (—), `L2a` (L1a), `L3a` (L2a), `L4a` (L1a, L3a). Step 0 passes. Step 1: `L1a` is ready; the others wait. Step 2: `spawn-detached 2026-10-27-quote-approval L1a`; the script cuts `feat/2026-10-27-quote-approval` from `main`, then `feat/2026-10-27-quote-approval-L1a` from it; the brief names `tc96-backend:drizzle-mutation` and `tc96-backend:bun-test-build`; the index's `L1a` Status becomes `running`. Step 3: `.result` says `done`, and `run-gates` reports `fail — static:fail unit:ok`; state `gates-failed`, the implementer is resumed with G1 only, `round` stays 0. Its next `.result` says `done`, and `run-gates` reports `pass`; state and Status `in-review`. Step 5: the next phase is `workflow-review`. After `L1a` merges into the feature branch there, this phase runs again: `L2a` is ready.
