# workflow evals

Seven cases, at least one per phase, in the layout `claude plugin eval` reads (`prompt.md`,
`case.yaml`, `graders/`, and a `place-files.sh` scaffold). They measure one thing the four
phase skills depend on: **can the model of the main session run the phase's procedure?** The
phases run on whatever model the person chose (`delivery-flow.md` §3), so each model is run as
the main session, and the agents the phases call keep their own tier.

| Case | Phase | What it stresses |
| --- | --- | --- |
| `search-export-admins` | `workflow-search` | five-axis slices; the record answers the product slice (Out of Scope) and the admin rule (ADR-0002) before any code question; one round to `repo-explorer`; the route puts the amendment before the delivery plan, backend before frontend; stops after the triage, with no delivery plan written |
| `search-negative-discount` | `workflow-search` | a fix that restores AC-07 goes to the fast lane, with no amendment and no invented frontend slice, although the delivery lists the discount layer as merged |
| `search-status-exists` | `workflow-search` | every slice already exists (PRD, merged layer L4a, code): nothing to plan, no plan-phase agent |
| `plan-amendment-draft` | `workflow-plan` | the route's first stop is a `Draft` amendment: put it in front of the owner as it is and stop, with no subagent and no delivery plan written |
| `implementation-ready-list` | `workflow-implementation` | the ready list over the index's layers: with L1a and L2a merged, L3a and L4a start, L3b waits on the Surface it shares with L3a, L4b on L3b; briefs name the owner role and the layer's skills; no gate before a run ends |
| `implementation-gates-failed` | `workflow-implementation` | L4a's run ended and `run-gates 2026-10-26-quotes L4a` fails on G1: `gates-failed`, a resume with only G1, round still 0, gates again, `in-review`; no gate log read |
| `review-unmet-contract` | `workflow-review` | a layer review: a new `code-reviewer` with only the layer file, the diff against the feature branch, the gates and the procedure (never `contract.md`); L3b's unproved check C10 (AC-03) makes it `fixing`, round 1; no push |

## How a run is set up

- **Target.** An eval run loads agents only from the plugin under test, never from a project
  `.claude/`, so `run-evals.sh` copies `dist/claude-code/plugins/tc96-core` to a temporary
  directory, places these cases in it, and runs `claude plugin eval` there. Build first
  (`bash build/claude-code.sh`) after changing a skill or an agent.
- **Fixture.** `fixtures/quotes-app/` is one small product: an approved PRD (capabilities
  `CAP-1`–`CAP-4`, `AC-01`–`AC-07`, exporting quotes Out of Scope), two ADRs, one approved delivery
  `.specs/delivery/2026-10-26-quotes/` (the index `plan.md`, six layer files `L1a` contracts, `L2a`
  repository, `L3a` quotes routes, `L3b` approval route with the signed link, `L4a` quotes list
  screen, `L4b` approval screen, and `contract.md` mapping each `AC-*` to checks `C01`–`C17`, `I1`,
  `I2`; every layer `merged`), a `CLAUDE.md`, `sdd.config.sh` and a few source files. The
  implementation and review cases override the index's Status column and add the state files under
  `.sdd/state/2026-10-26-quotes/` for the moment they test.
  Each case's `place-files.sh` copies it, lays the case's `files/` over it, commits it on `main`,
  and runs the case's `setup.sh` when there is one.
- **Harness stand-ins.** The implementation cases ship the six harness scripts as stand-ins that
  take the real arguments (`spawn-detached <delivery> <layer> --brief <file> [--resume]`,
  `run-gates <delivery> <layer>`, `stop <delivery> <layer>`) and only print their one-line summary;
  `spawn-detached` refuses a call without a brief file, as the real one does. In
  `implementation-gates-failed`, L4a's run has already ended (`.sdd/run/2026-10-26-quotes/L4a.exit`
  and `.result`), and `run-gates` fails it on G1 until the session has recorded that failure under
  `.sdd/`, so the resume is what makes the next gate run pass.
- **A real review.** `review-unmet-contract`'s `setup.sh` builds the feature branch
  `feat/2026-10-26-quotes` (L1a's schemas and L2a's repository merged), cuts
  `feat/2026-10-26-quotes-L3b` from it with the approval routes and tests for C08, C09, C11, C12 and
  I1 but not C10, and saves the diff against the feature branch at
  `.sdd/run/2026-10-26-quotes/L3b.diff`, so the `code-reviewer` the phase starts has a real change to
  judge.
- **The run's shell is read-only.** On the machine these were written on (Fedora, SELinux
  enforcing, bubblewrap 0.12), a run's Bash sees a read-only file system and cannot execute `git`;
  only the Write and Edit tools write. The cases are shaped around it: scripts write nothing, the
  scaffold (which runs outside the sandbox) makes the diff, and the prompts of the implementation
  and review cases state the limit. On a machine whose sandbox lets Bash write the workspace, the
  same cases still hold.

## Graders

Most graders are deterministic: `file_exists` for what must or must not be written, `regex` over a
file the run leaves (`.sdd/state/<delivery>/<layer>.md`, the PRD), `regex` over the trace for what
the triage file or a brief says (the Write call's content), for what the main session itself read
(its calls carry `"parent_tool_use_id":null`; a subagent's carry the id of the Agent call) and for
"no delivery plan written" (no Write or Edit under `.specs/delivery/`, which the fixture already
holds), and `tool_used` with `input_match` for which agents and commands ran. `input_match` runs on
the call's input as compact JSON, so the script graders stay inside one JSON string
(`(?:[^"}\\]|\\.)*`) and still catch a call made from a shell loop, and the reviewer count matches
`subagent_type`, not a prompt that only mentions `code-reviewer`. `llm` graders judge only what
needs judgment. They read the `last_message`, or the `trace` where what they judge sits at its end:
the judge sees only the first and last 12 messages of a trace, and the triage file's Write call is
among the last.
`focus: files` would not do, since it hands the judge the paths a run created, not their content.

## Running them

```bash
bash skills/workflow/evals/run-evals.sh haiku --runs 2 -j 2 --max-cost-usd 4
bash skills/workflow/evals/run-evals.sh sonnet --runs 2 -j 2 --max-cost-usd 10
bash skills/workflow/evals/run-evals.sh opus --runs 2 -j 2 --max-cost-usd 15
python3 skills/workflow/evals/model-accuracy.py
```

Each call writes `results/<model>/result.json` and an HTML report. To rerun some cases after a
fix, set `EVAL_TAG`: the run writes `result-<tag>.json`, and its cases replace the same cases of
the earlier file. `model-accuracy.py` merges them and writes `results/model-accuracy.md`: pass
rate per case and per phase, cost and time, per model. `results/` is git-ignored; the section
below records what a run found.

## Results

> **2026-10-27, after the migration to delivery plans.** The cases now test the layered delivery
> flow: one delivery `.specs/delivery/<date>-<slug>/` with an index, layer files and a contract,
> capabilities in the PRD, scripts that take `<delivery> <layer>`, state under
> `.sdd/state/<delivery>/`, and `SDD-PLAN-*` rules. The results below were measured on the previous
> plan format (per-feature bundles in `.specs/features/`, features F01–F04 with waves) and must be
> re-run after this migration; they stay here as history.
>
> **First pass on the new format — Haiku 5.5, one run per case ($0.21).** 5 of 7 cases passed,
> score 95%. `review-unmet-contract` failed because the fixture's signed link fell back to an empty
> key, which the reviewer rightly flagged as a blocking security defect and so held the layer for
> the owner instead of a fix round. The link now requires `LINK_KEY`. In a rerun with two runs
> ($0.76), one run passed every grader and the other missed only `10-session-read-no-diff`, the
> same miss as the earlier runs. `search-status-exists` missed `02-session-read-no-source`: the
> session read `src/` itself instead of leaving it to `repo-explorer`.
>
> **Sonnet 5.5, one run per case ($2.23).** 4 of 7 cases passed, score 95%. The three misses did
> not repeat on rerun: `search-negative-discount` skipped `repo-explorer` once and then passed 2/2
> ($0.37), and `implementation-ready-list` made one Bash call naming L3b beside `spawn-detached` and
> then passed 1/1 ($0.20). `plan-amendment-draft` started `product-manager` instead of putting the
> Draft amendment already in `.specs/PRD.md` in front of the owner, the same miss as one of two runs
> before the migration. Opus is not re-run yet.

### 2026-10-27, Claude Code 2.1.310

Each model ran as the main session on all seven cases, two runs each (14 runs per model). After the
first full pass, `search-status-exists` and `review-unmet-contract` were rerun because the fixture
itself had holes the stronger models rightly flagged (a session stub that never returned a user,
a decision route with no link check, a test without the `rejected` case). `implementation-ready-list`
was rerun because its regex missed a `spawn-detached` started from a shell loop.

| Phase | Haiku 5.5 | Sonnet 5.5 | Opus 5.5 |
| --- | --- | --- | --- |
| `workflow-search` (3 cases) | 99% (69/70) | 96% (67/70) | 99% (69/70) |
| `workflow-plan` (1 case) | 92% (11/12) | 67% (8/12) → 92% (11/12) | 75% (9/12) → 100% (12/12) |
| `workflow-implementation` (2 cases) | 98% (47/48) | 100% (48/48) | 100% (48/48) |
| `workflow-review` (1 case) | 100% (24/24) | 100% (24/24) | 100% (24/24) |
| **All graders** | **98% (151/154)** | **95% → 97% (150/154)** | **97% → 99% (153/154)** |
| Runs with every grader passed | 11/14 | 9/14 | 11/14 |
| Mean cost per run | $0.029 | $0.213 | $0.420 |
| Mean seconds per run | 42 | 54 | 74 |

Cost is what each run reported for the agent under test, its subagents included; judges added
about $0.002 per run. The kept results cost about $13 in all.

**What the misses say.**

- **`workflow-plan` has an ambiguity, not a weak model.** The triage's first stop is an amendment
  that already exists as `Draft`. Step 0 says to resume at the first stop without an `Approved`
  file, but Step 1 says "when the route has an amendment, start `product-manager`". Sonnet and Opus
  followed Step 1 in all four runs and re-ran `product-manager` over the existing draft (Opus once
  rewrote it); Haiku did so in one run of two. **Fixed the same day:** Step 1 now opens with a table
  — not written yet, start `product-manager`; already `Draft` or `In review`, put it in front of
  the owner as it is; `Approved`, go on — plus a self-check row. Rerun on the three models (the
  arrows above): Opus 12/12, Sonnet and Haiku 11/12, each with one run that still started a
  subagent.
- **Haiku's misses are discipline.** It read `src/quotes/discount.ts` in the session instead of
  asking `repo-explorer` (once), started a subagent in the plan case (once), and `grep`ped a gate
  log under `.sdd/logs/` (once).
- **Sonnet and Opus over-read the request.** In `search-status-exists`, one run each still routed
  something to plan for a feature that already exists; Sonnet sent a slice of the CSV export to an
  ADR in both runs. In the first pass, Sonnet also started F04 although its Surface shares
  `src/server/quotes.route.ts` with F03; the rerun did not repeat it.
- **Two runs per case is a small sample.** A single run moves a case by 4–17 points, so read the
  phase rows and the shared misses, not one cell.

**For the tier question:** every model ran the phases' procedure at 95% or above, and Haiku did it
at about a seventh of Sonnet's cost and a fourteenth of Opus's. The phases do not need the top tier
in the main session; the plan phase needs its Step 1 fixed whatever the model.
