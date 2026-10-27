---
name: workflow-review
description: Decides whether each layer in review met its checks, delivers it into the delivery's feature branch, and, once every layer is merged there, validates the whole delivery and opens its one pull request into the trunk — a new code-reviewer instance checks a layer with only its layer file, the diff against the feature branch and the gate summary; devops-security joins for a security-class layer; a met layer becomes a PR into `feat/<delivery>` under the owner's authorization; an unmet one goes back to workflow-implementation for at most two fix rounds and then to workflow-plan as a new layer; the final review checks `contract.md` on the feature branch before the PR into the trunk the owner approves — holding only one state file per layer, citing `SDD-RUN-04`–`SDD-RUN-08`, `SDD-PLAN-07`, `SDD-PLAN-11` and `SDD-FLOW-*` IDs. Use when a layer's state is `in-review`, when every layer of a delivery is merged, when the person asks to review, deliver or open the PR of a run, or for the run's final report. Not for a general code review outside a run (code-reviewer with the family review skills), implementing a fix (workflow-implementation), nor writing the new layer (workflow-plan).
source: "[Delivery Flow — Spec Driven Development](../../docs/workflow/delivery-flow.md)"
tags:
  - skill
  - workflow
  - review
  - orchestration
---

# workflow-review

> **Delegation (`SDD-CORE-02`).** This phase routes; it reviews nothing itself. Each review goes to a new `code-reviewer` instance, called by name as a subagent, with the procedure in `references/contract-review.md`; a security-class layer adds `devops-security`; a PR body that needs reading the plan goes to `repo-operator`.
> **Context (`SDD-CORE-04`, `SDD-FLOW-03`).** Hold one state file per layer and the index's Status column, and nothing else: never a diff, a gate log or a review report. The reviewer returns a verdict; only its IDs reach the state file, and the state file is the only thing this phase passes back to `workflow-implementation`.

Rules this phase implements: [Delivery Flow — Spec Driven Development](../../docs/workflow/delivery-flow.md) §4.3 "The checks", §5.2 steps 4–5, §5.3, §5.4, §5.7, `SDD-PLAN-07`, `SDD-PLAN-11`, `SDD-RUN-04`–`SDD-RUN-08`, `SDD-FLOW-02`, `SDD-FLOW-03`.

## Scope

| The state is... | Go to |
| --- | --- |
| a layer `in-review` with gates `pass` | this phase, Step 1 |
| a layer `checks-met` | this phase, Step 3 |
| every layer of the index `merged` | this phase, Step 4 |
| a `blocking` entry, or `unmet` after round 2 | this phase, Step 5 |
| `waiting`, `running`, `gates-failed` or `fixing` | `workflow-implementation` |
| a review of code outside a run | `code-reviewer`, with the family review skills |

## Step 0: Push and PR authorization

Ask once per delivery, before the first layer PR: "authorize push and the layer PRs into `feat/<delivery>` for this delivery?". Quote the owner's words in each state file's `authorization`. Without them, layers stop at `checks-met`. Merging a layer PR on the owner's behalf is covered only if the owner said so in those words. The delivery's PR into the trunk is never covered: the owner approves it on the PR (`SDD-RUN-08`).

## Step 1: Review a layer

For each layer in `in-review`, start a **new** `code-reviewer` instance — never one that saw this layer before — with exactly these inputs (`SDD-RUN-04`):

| Input | Value |
| --- | --- |
| procedure | the absolute path of `references/contract-review.md`, from this skill's base directory |
| layer file | `.specs/delivery/<id>/plans/<layer>-<slug>.md`: its **Checks**, **Must hold** and **Surface** |
| diff | `git -C <worktree> diff feat/<delivery>...HEAD` (the reviewer runs it; you pass the command) |
| gates | the state file's `gates` line |
| open findings | on a delta re-review only: the state file's `review` line |

For a layer that lists G3, start `devops-security` at the same time on the sensitive path; its result is G3. Reviews of different layers go out side by side; they only read.

## Step 2: Write the verdict

Write the verdict to the state file as IDs only, and the same status to the index's row (`SDD-PLAN-11`):

| Verdict | State | Next |
| --- | --- | --- |
| `met`, and G3 clean when listed | `checks-met` | Step 3 |
| `unmet`, `round` < 2 | `fixing`, `round` + 1; the failing checks and broken rules under `review`, verbatim | `workflow-implementation`, Step 4; after its gates, back here for a delta re-review with the open findings |
| `unmet`, `round` = 2 | stop fixing (`SDD-RUN-05`) | Step 5 |
| any `blocking` note | `waiting`, the note under `blocking` | ask the owner whether it becomes a new layer before merge |

Non-blocking notes go under `notes`; they never fail the review. This phase owns `round`: it raises it, and it is the only phase that reads it to decide (`SDD-FLOW-03`).

## Step 3: Deliver a layer into the feature branch

With `authorization` set, push `feat/<delivery>-<layer>` and open its PR **into `feat/<delivery>`**, never into the trunk, its body from `references/template-pr.md`, layer body, filled from the state file and the layer's checks. Run one known command each, here; use `repo-operator` when the body needs reading the plan. Merge it only if the owner's words cover it; otherwise report the PR link. Then `scripts/stop <delivery> <layer>`, state `merged`, `pr` and `finished` set, and the index's row `merged` with the PR link, committed on the feature branch. Layers that depend on this one may now be ready: that is `workflow-implementation`'s Step 1.

## Step 4: Validate the delivery and open its PR into the trunk

When every row of the index is `merged`:

1. `scripts/run-gates <delivery> --all` on the feature branch. `fail` → the failing levels go to Step 5 as a new layer; nothing is reviewed on a red branch.
2. Start a **new** `code-reviewer` with the procedure, `contract.md`, the layer files its rows point to, `git diff <trunk>...feat/<delivery>` as a command, and that gate line. It answers whether the contract is met: every `AC-*` row with all its checks proved and green (`SDD-PLAN-07`).
3. `met` → push `feat/<delivery>` and open the delivery's PR **into the trunk**, its body from `references/template-pr.md`, delivery body, listing every `AC-*` with the checks and layers that proved it. Report the link and stop: it merges only on the owner's approval on that PR (`SDD-RUN-08`).
4. `unmet` → the failing rows go to Step 5 as a new layer.

## Step 5: New layer or gap

Nothing goes back to search, and no merged file is reopened (`SDD-FLOW-02`):

| Case | Next |
| --- | --- |
| `unmet` after round 2 | hand `workflow-plan` a **new layer**: the layer ID, the failing checks and the branch. The owner approves it (state `split`, `next` set) or drops the layer (state `dropped`) (`SDD-RUN-06`) |
| the delivery's final review `unmet` | the same, with the failing `AC-*` rows and the feature branch |
| a blocking note the owner turns into a new layer | the same, with the note as the input |
| a gap that changes what the product promises | ask the owner; the answer goes to `workflow-plan` as a PRD amendment |

There is no third fix round and no move to a higher tier.

## Step 6: Report and hand off

When nothing is `in-review` or `checks-met`, report one line per layer: layer, status, PR link or `next`; then the delivery's PR link once opened, and the open owner questions. Nothing else. Then name the next phase: `workflow-implementation` when layers are `fixing` or newly ready, `workflow-plan` when a new layer is waiting to be written. Do not load another phase from inside this one (`SDD-FLOW-04`).

## Self-check

| # | Check | Rule |
| --- | --- | --- |
| 1 | every review ran in a new instance with only its inputs and the procedure | `SDD-RUN-04` |
| 2 | a layer counted as met only when every check and rule in its file was proved | `SDD-RUN-04` |
| 3 | the delivery counted as met only when every `AC-*` row of `contract.md` was proved on the feature branch | `SDD-PLAN-07` |
| 4 | no layer got a third fix round | `SDD-RUN-05` |
| 5 | a layer failing round 2 became a new layer or was dropped by the owner; nothing went back to search | `SDD-RUN-06`, `SDD-FLOW-02` |
| 6 | every layer PR went into the feature branch; only the validated delivery's PR went into the trunk, and nothing merged there without the owner | `SDD-RUN-08` |
| 7 | the index's Status and PR cells changed only here and in `workflow-implementation` | `SDD-PLAN-11` |
| 8 | only IDs and one-line verdicts reached the state file | `SDD-CORE-04`, `SDD-FLOW-03` |

## Example

Step 0: the owner answers "pode abrir e mergear os PRs das camadas", quoted in each state file. `L1a` is `in-review` with `pass — static:ok unit:ok`. Step 1: a new `code-reviewer` with the procedure path, `L1a`'s file, the diff command against `feat/2026-10-27-quote-approval` and the gates line. It says `met`. Step 3: PR into `feat/2026-10-27-quote-approval`, merged under the owner's words; `L1a` `merged`, the index updated; next phase `workflow-implementation`, where `L2a` becomes ready. Later, `L2a`'s first review: `unmet — C7 unproved`; state `fixing`, `round` 1. The delta re-review after the fix: `met`. When every row is `merged`, Step 4: `run-gates --all` passes, the final review finds `AC-01`–`AC-05` proved, and the delivery's PR into `main` is opened and reported. The owner approves and merges it.
