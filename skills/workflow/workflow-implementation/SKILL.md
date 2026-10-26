---
name: workflow-implementation
description: Runs phase 3 of the delivery flow v2 — starts each approved feature in the order of the PRD's provider → consumer graph, the design lane as soon as the bundle is approved and the code lanes only once every provider has merged, splits the feature's work into the lanes its contract marks (design, frontend, backend, AI, DevOps, tooling, QA), gives the small lanes to one feature implementer and each large lane to its discipline agent, runs them in one worktree through the harness scripts, and hands the feature to Review only with `run-gates` green, citing handoffs `H7`–`H12` and `SDD-RUN-01`–`SDD-RUN-03`. Holds one state file per feature. In a project on the delivery flow v2 (`story.md` bundles), use when bundles are approved and someone asks to implement, build, run, start or continue the features, or asks which feature can start now. Not for writing a bundle (workflow-plan), checking the contract (workflow-review), nor writing the code itself (the lane agents).
type: skill
family: workflow
language: en
source: "workflow/foundations/phases.md §3 (Draft, 2026-10-26)"
tags:
  - skill
  - workflow
  - orchestration
---

# workflow-implementation

> **Delegation (`SDD-CORE-02`).** This skill routes; it writes no code. Each code run is detached in the feature's worktree through `scripts/spawn-detached` and `references/template-lane-brief.md`; the design lane goes to `product-designer` as a subagent. Everything mechanical is a script (`SDD-CORE-05`).
> **Context (`SDD-CORE-04`).** Hold one state file per feature (`template-state.md` of `sdd-orchestrator`, plus the `lanes` and `run` fields below) and nothing else: never code, a diff or a gate log.
> **Status.** Draft. Implements `workflow/foundations/phases.md` §3 and `workflow/foundations/handoffs.md` `H7`–`H12`.

## Step 0: Preconditions

| Check | How | If it fails |
| --- | --- | --- |
| the PRD is `Approved` | its status line | stop: `workflow-search` |
| the harness exists | `test -x init.sh && ls scripts/` shows the five scripts, and `sdd.config.sh` exists | stop: run the `scaffold-sdd-scripts` command |
| `.sdd/` is git-ignored | `git check-ignore -q .sdd` | add `.sdd/` to `.gitignore` |

## Step 1: Build the ready list

Read the PRD's **Functionalities** and **Dependency Graph** only, each approved bundle's `contract.md` frontmatter, and every file in `.sdd/state/`. Create a `waiting` state file for each approved folder that has none, with:

```yaml
lanes: { design: small, frontend: small, backend: large, ai: none, devops: none, tooling: none, qa: small }
runs: [backend, frontend+qa]   # the code runs, in order (Step 3)
run: 0                         # index of the current code run
design: ""                     # waiting | running | done, or none
```

Two start conditions per feature (`H7`, `H8`):

| Lane | Starts when |
| --- | --- |
| design (not `none`) | the bundle is `Approved` |
| code lanes | the bundle is `Approved`; every feature it consumes from is `merged` (`SDD-RUN-01`); no open `gaps` or `blocking`; its `surface` shares no path with a `running`, `fixing` or `in-review` feature; fewer than the wave width (default 4) are `running` or `fixing` |

Ready features start in PRD priority order. A ready feature in `W2` does not wait for an unrelated `W1` feature. While a provider is in a fix round, its consumers' code waits; if it becomes a new item, they wait for that item to merge.

## Step 2: Design lane (`H7`, `H9`)

Start `product-designer` as a subagent with the feature's `story.md`, the UX section of `spec.md`, and the instruction to return screens and states (loading, empty, error, success) for this feature only. Default D8: it writes `.sdd/design/<ID>-<slug>.md`. Set `design: done` when it returns. A gap goes to Step 5.

## Step 3: Group the code lanes into runs

Default D2: the code lanes run in sequence in one worktree, in this order: backend, AI, DevOps, tooling, frontend, QA. Default D3: one worktree and one PR per feature.

1. Drop every lane marked `none`.
2. Each `large` lane is its own run, with its discipline agent.
3. Consecutive `small` lanes form one run, with the feature implementer (the contract's `owner`).

| Lane | Agent when `large` |
| --- | --- |
| backend | `backend-developer` |
| AI | `ai-engineer` |
| DevOps | `devops-security` |
| tooling | never large (default D5) |
| frontend | `frontend-developer` |
| QA | `qa-engineer` |

Write the order to `runs`. A frontend run starts only with `design: done` when the design lane is not `none`.

## Step 4: Start a run

Write the brief from `references/template-lane-brief.md` for run `runs[run]`, then:

```bash
scripts/spawn-detached F03-invitations --brief .sdd/run/F03-invitations.brief.md
```

The first run creates the worktree and branch from the contract's `base` and runs `init.sh` inside it (`SDD-RUN-02`, `SDD-SCR-03`); later runs reuse the same worktree. Set the state to `running`. When the frontend run starts, copy `.sdd/design/<ID>-<slug>.md` into the brief's read list; the run commits it as `.specs/features/<ID>-<slug>/design.md`, so it is reviewed with the PR.

## Step 5: When a run ends

The run is over when `.sdd/run/<ID>.exit` exists. Read only `.sdd/run/<ID>.result`:

| `.result` | Next |
| --- | --- |
| `done`, more runs left | `run` + 1; Step 4 |
| `done`, last run | `scripts/run-gates <ID>`; its one-line summary goes to `gates` |
| `gap: <question>` | state `waiting`, the question under `gaps` (`H10`): a product change goes to the owner, then `workflow-search`; any other gap to `workflow-plan`, new item mode |
| missing, or `.exit` non-zero | state `waiting`; tell the owner the run failed and give the log path, not its content |

Gates `fail` → state `gates-failed`; resume the run that owns the failing gate's files with `--resume` and only the failing gates (`H11`). This is not a fix round (`SDD-RUN-03`). Gates `pass` → state `in-review`; the next step is `workflow-review` (`H12`).

## Step 6: Report

When nothing is ready and nothing is running, report one line per feature: ID, status, current run, open gaps. Nothing else.

## Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | no code run started before every provider merged; design started on approval | `SDD-RUN-01`, `H7`, `H8` |
| 2 | every lane with checks ran, under its agent; no agent ran for a `none` lane | — |
| 3 | every code run of a feature ran in its one worktree, started by `spawn-detached` | `SDD-RUN-02` |
| 4 | gates ran before Review; a gate failure never counted as a fix round | `SDD-RUN-03` |
| 5 | every gap stopped the feature and went to Plan or the owner | `SDD-RUN-07` |
| 6 | this conversation holds state files, not diffs, logs or design content | `SDD-CORE-04` |

## Example

F01 and F02 merged; F03 approved with `backend: large`, `frontend: small`, `qa: small`, `design: small`. Step 1: F03's code is ready; its design lane too. Step 2: `product-designer` returns invite dialog states. Step 3: `runs: [backend, frontend+qa]`; the implementer is `frontend-developer`. Step 4: run 0, `backend-developer` writes C1, C2, C4. Step 5: `done`; run 1, `frontend-developer` writes the dialog, C3 and the QA checks, and commits `design.md`. Last run `done`; `run-gates` → `pass — 4 checks, 2 gates`; state `in-review`.

**Anti-pattern.** Starting F04's backend because F03's backend run finished. Corrected: F04's code waits for F03 to merge after Review; only F04's design lane may start early.
