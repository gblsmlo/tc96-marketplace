---
title: Delivery Flow — Spec Driven Development
aliases:
  - SDD
  - Spec Driven Development
  - workflow
tags:
  - workflow
  - delivery
  - agent-context
  - reference
source: "Anthropic, Claude Cookbooks — managed_agents/CMA_plan_big_execute_small.ipynb (a frontier model plans and synthesizes, cheaper workers execute in their own contexts; delegation has a floor cost; verification only covers what you put in it); Glenford Myers, The Art of Software Testing (boundary value analysis, behind the edge sweep); Matt Wynne, Introducing Example Mapping (the unanswered question becomes a card, never a guess); Winters/Manshreck/Wright, Software Engineering at Google (review by an independent peer); internal precedent: the owner's SDD draft and decisions of 2026-10-25, which replaced the four-pillar flow, and of 2026-10-26, which cut it into four phase skills"
verified-on: 2026-10-26
---
# Delivery Flow — Spec Driven Development

> **What this doc is.** The delivery flow of this house, and the foundation of the four phase
> skills in `skills/workflow/`: search, plan, implementation and review. The specification is the
> primary artifact and the contract the code must meet. Search triages every request into slices
> and routes each one. A PRD, the product's single source of truth, names every feature, what each
> one provides and consumes, and the order they can run in. A Spec Writer turns each feature into
> three files. Each feature then runs through a fixed loop — implement, gates, review against the
> contract, fix — on cheaper models, driven by scripts.
>
> **What it is not.** It is not a role. It does not replace any agent in `agents/README.md`; it
> says which agent runs at each step and what it receives. It is not a project-management tool:
> no step of this flow writes to a board.
>
> **Why it exists.** The four-pillar flow it replaced had four costs that compounded: the
> orchestrating session held every envelope and reread it on every turn; each unit spawned at
> least four agents; a unit that failed its fix rounds went back to planning, and implementation
> or validation could send work back to research, so whole sequences reran; and the reviewer's
> checklist was every matching review skill, not the unit's acceptance. This flow plans once, up
> front, on the expensive model, gives the reviewer one fixed oracle, and moves every mechanical
> step into a script. Its four phases are a cut of this one flow, not a return of the pillars:
> each phase is a skill the main session loads, one at a time; only the state file passes between
> implementation and review; and nothing goes back except a bounded fix round (`SDD-FLOW-*`).

Sources consulted on **2026-10-25**; the phases (§2, §4.4 "Triage", `SDD-FLOW-*`) on
**2026-10-26**. See [Sources consulted](#sources-consulted).

---

## 0. Before anything else: four distinctions that settle the conversation

**1. Plan big × execute small.** Product and specification decisions are made **once**, before
any code, by the high tier: the PRD by `product-manager`, each feature's bundle by `spec-writer`.
Implementing, fixing and reviewing run on the mid tier, each in a fresh context, and never decide
product or specification (`SDD-CORE-02`). The cookbook pattern this follows puts the frontier
model on planning and synthesis and keeps it away from raw reading; the same split here keeps the
expensive model away from diffs, logs and test output.

**2. Contract met × checks green.** A feature is done when its contract is met, and a contract is
met only when it **proves that every acceptance criterion it traces was met** (`SDD-SPEC-06`). A
green check that covers no acceptance criterion does not close the contract; an acceptance
criterion with no check does not either. Green gates are necessary, never sufficient.

**3. Global × local scripts.** The six harness scripts — environment, migrations, gates, spawning
and stopping a run — live once, at the root of the consuming project, and every feature uses them
(`SDD-SCR-01`). A script only one feature needs is written in that feature's `plan.md`.

**4. Spec × board.** The specification is the work list: PRD features and their waves say what
runs and in what order. Registering work on a board is outside this flow (`SDD-CORE-06`); a
project that keeps one mirrors the PRD by hand or by its own tooling.

---

## 1. How to use this doc

### For a person

Start every request with `workflow-search`. It splits the request into slices, reads what is
already decided, and says where each slice goes next: a PRD amendment, an ADR, a bundle, the fast
lane, or a question for you. `workflow-plan` then writes what the triage asked for and stops at
your approval. Approved bundles run in `workflow-implementation`; a feature whose gates are green
goes to `workflow-review`, which opens the PR you merge. A fix or refactor of something already
built also starts at search; its triage sends it to the fast lane (`SDD-SPEC-09`).

### For a coding agent

Read only the files your step names in §3. An implementer reads its feature folder and the files
`plan.md` cites, never the PRD whole; a reviewer reads `contract.md`, the Surface, the diff and the gate
result, never the conversation that produced the change. A question your files do not answer is a
gap you return (`SDD-RUN-07`), never a guess you write into the code.

### Conventions

`MUST`/`NEVER` are normative, as in the rest of the knowledge base. **†** marks a decision of this
doc, with no direct parallel in a single external source.

---

## 2. Mental model

```
SEARCH (every request · main session + fast tier · decides nothing)
request ─► slices on five axes ─► record first ─► repo-explorer for open slices ─► triage file
                                                                                    │ verdict + next step per slice
PLAN BIG (once, high tier)                 EXECUTE SMALL (per feature, mid tier, fresh context)
──────────────────────────                 ─────────────────────────────────────────────────────
PRD  ── owner approves                     implementer ──► run-gates ──► reviewer (contract.md)
 │  features · provides/consumes                ▲              │ fail         │ contract met
 │  waves · priority · traceability             │              ▼              ▼
 ▼                                              └──── fixer (≤ 2 rounds) ◄── fail      PR · merge
Spec Writer ── facts from the triage                           │
 │  per feature: spec.md · plan.md · contract.md               ▼ still failing
 └─ owner approves the bundle                  Spec Writer writes a new item ── owner decides

HARNESS (scripts at the project root, no model tokens)
init.sh · scripts/resolve-env · scripts/migrate-dev · scripts/run-gates · scripts/spawn-detached · scripts/stop
```

| # | Phase | Skill | Enters when | Leaves with |
| --- | --- | --- | --- | --- |
| 1 | **Search** | `workflow-search` | any request arrives | `.specs/triage/<date>-<slug>.md`: the request's slices on five axes, each with its facts and source, a verdict and a next step; and the request's route |
| 2 | **Plan** | `workflow-plan` | the triage sends slices to a PRD amendment, an ADR, a bundle or the fast lane; or the review produced a new item | `.specs/PRD.md` or a dated amendment, ADRs, and `.specs/features/<ID>-<slug>/` bundles, each `Approved` by the owner |
| 3 | **Implementation** | `workflow-implementation` | a feature's bundle is approved and its start conditions hold (§5.1), or the review sent it back as `fixing` | a branch with green gates; state `in-review` |
| 4 | **Review** | `workflow-review` | a feature's state is `in-review` with gates `pass` | a PR the owner merges; or `fixing`, back to implementation, at most twice; or a new item for plan |

Each phase is a skill the main session loads, one at a time; none is an agent, and none loads
another (`SDD-FLOW-04`). The only ways back belong to the review: a fix round to implementation,
or a new item, in its own folder, to plan. No failure goes back to search, and no phase reopens a
closed one: a wrong product decision is a PRD amendment; a spec that turned out short is a new
item. Both go forward, through the owner (`SDD-FLOW-02`).

---

## 3. Who runs each step

The tier follows the operation (`SDD-CORE-02`). Decisions stay on the high tier, inside named
agents; code and review run on the mid tier; anything whose result is an exit code runs as a
script.

| Phase | Point | Who executes | `modelo` · `esforco` | Reads | Why |
| --- | --- | --- | --- | --- | --- |
| search | split the request into slices and triage them | the main session, via `workflow-search` | the person's choice | the request, `.specs/` status lines, ADR titles, the project's docs and memory | splitting is routing; it costs little and decides nothing (`SDD-FLOW-05`) |
| search | answer one open slice in the code | `repo-explorer` | rapido · baixo | the code the slice touches | every fact carries the `file:line` that proves it |
| plan | write the PRD or an amendment | `product-manager`, via `doc-prd` | alto · alto | the triage, the request, evidence, the current PRD | the file is the product decision |
| plan | write the feature bundle | `spec-writer`, via `workflow-plan` | alto · alto | the PRD entry, the triage's facts, the providers' `spec.md` | decides interfaces, steps and proof once, for every round that follows |
| plan | a decision that outlives the feature | `software-architect`, via `doc-adr` | alto · alto | the decision in question | lasting boundary decisions get their own record |
| implementation | prepare env, migrate, spawn the worktree | `scripts/resolve-env`, `scripts/migrate-dev`, `scripts/spawn-detached` | — | — | mechanical; exit code only |
| implementation | implement, and fix rounds 1–2 | `frontend-developer` · `backend-developer`, resumed for each round | medio · medio | its feature folder, the files `plan.md` cites | most tokens; the gates and the reviewer catch its errors |
| implementation | run the gates the contract names | `scripts/run-gates` | — | — | the result is an exit code and a short summary |
| implementation | commit its own diff | the implementer | medio · medio | its own diff | already in its context |
| review | review against the contract | `code-reviewer`, with `workflow-review`'s `references/contract-review.md` | medio · alto | `contract.md`, the Surface from `plan.md`, the diff, the gate summary | it is the verification; nothing reviews it |
| review | security-class feature | `devops-security`, beside the reviewer | alto · alto | the sensitive path in the diff | a missed finding costs more than the tokens |
| review | push, open the PR | `repo-operator`, or the session when it is one known command | rapido · baixo | the PR template, the state file | template filled from the state file |
| any | orchestrate: state files, routing, talking to the owner | the main session, via the phase skill it loaded | the person's choice | state files only | a plugin does not pin the session's model |

Every delegated step goes to the named agent, called as a subagent, so it runs on its own tier
and carries its own body; a generic agent, or a session told to act "as" a role, inherits the
caller's model instead (`SDD-CORE-02`, `CC-PAR-05`).

**What the orchestrator never reads.** Code, diffs, gate logs and review reports stay in the
agent or script that produced them. The orchestrator holds one state file per running feature
(§5.4) and nothing else (`SDD-CORE-04`). Its context is reread on every turn until the run ends;
that is the cost this rule caps.

---

## 4. The artifacts

### 4.1 Where they live

```
.specs/
├── triage/
│   └── <date>-<slug>.md           workflow-search · slices, verdicts, the route
├── PRD.md                          product-manager · the product's single source of truth
├── adr/
│   └── NNNN-<slug>.md              software-architect · never edited, only superseded
└── features/
    └── F03-<slug>/
        ├── spec.md                 spec-writer · what the feature exposes and consumes
        ├── plan.md                 spec-writer · how to build it
        └── contract.md             spec-writer · how to prove it works

.sdd/                               runtime only, git-ignored
├── state/F03-<slug>.md             the state file for one feature; the only handoff between implementation and review
├── logs/                           full output of every script run
└── run/                            pid files of detached runs
```

Each fact lives in one file; the others link to it (`SDD-SPEC-02`). A feature folder is never
rewritten after its feature merges: a later change is a new item with its own folder
(`SDD-SPEC-08`).

### 4.2 The PRD

One file, `.specs/PRD.md`, for the product. Its sections, in this order (`SDD-PRD-01`):

| Section | Holds |
| --- | --- |
| **Summary** | the product in three sentences |
| **Problem and Opportunity** | numbered items (`PO-1`, `PO-2`…), each with its evidence and source |
| **Target Audience** | who has the problem, with the source that says so |
| **Objectives** | numbered (`OBJ-1`…), each with a metric and a target |
| **User Stories** | each with acceptance criteria numbered across the PRD (`AC-01`, `AC-02`…), in Given / When / Then |
| **Functionalities** | the features (`F01`, `F02`…): a sentence each, the `AC-*` it satisfies, what it **provides** and what it **consumes** |
| **Out of Scope** | what someone might expect and is deliberately left out, and why |
| **Dependency Graph** | Foundation Features, Execution Waves, Priority levels |
| **Traceability** | for each `PO-*` and `OBJ-*`, the features that address it and their role, provider or consumer |
| **Open gaps** | each question with who decides it; empty before `Approved` |

**Provides and consumes.** Each feature names the interfaces, data or capabilities it provides,
and the ones it consumes with the feature that provides each (`SDD-PRD-02`). Every consumed item
has exactly one provider. This is what lets a feature be a placeholder while it is built: its
consumers code against what it promised.

**The graph.** Foundation features consume nothing. Wave `W0` holds the foundation; wave `Wn`
holds the features whose providers all sit in earlier waves. A cycle is a design defect: break it
by extracting what both sides share into its own provider feature (`SDD-PRD-04`). Priority levels
(`P0` must ship for the product to work, `P1` should, `P2` could) order the features inside a
wave; they never move a feature ahead of its providers.

**Traceability.** Every `PO-*` and `OBJ-*` lists at least one feature, and every feature appears
under at least one of them (`SDD-PRD-05`). A feature traced to nothing is scope creep; a problem
traced to nothing is a promise nobody is building.

The PRD carries no technical design (`DOC-PRD-03`). An `Approved` PRD is frozen; a change enters
as a dated amendment, approved by the owner, and a new feature enters the same way
(`SDD-PRD-06`).

### 4.3 The feature bundle: one question per file

| File | The one question | Holds | Never holds |
| --- | --- | --- | --- |
| `spec.md` | what does this feature expose and consume? | interfaces, data shapes, invariants, boundary decisions; a UX section only when the feature has an interface that needs one | step order, checks |
| `plan.md` | how is it built? | ordered steps, Surface (files touched), Size, base branch, the commands to run; feature-local scripts when needed | acceptance criteria |
| `contract.md` | how do we prove it works? | what it traces (`AC-*`), consumes and provides; inputs, outputs, rules; one check per line, each citing its `AC-*` and the gate that runs it; the non-functional gates; the line that says when the contract is met | design rationale |

**The contract.** Each check names one `AC-*` (or `—` for a non-functional gate), what is
observed, and the gate type that proves it at the cheapest level that catches the defect —
static, unit, contract, integration, component, E2E, manual (`Teste de Software`
§4.1, `TS-CORE-02`). Every `AC-*` the feature traces in the PRD has at least one check
(`SDD-SPEC-05`). The non-functional gates are always there: static checks, the suite the plan
touches, and, for a feature on an authentication, authorization or sensitive-data path, the
security class (`SDD-SPEC-05`). The reviewer checks what the contract lists and nothing else, so
whatever is left out of it goes unverified.

The contract closes with a **Met when** line naming, per `AC-*`, the checks that prove it:

```
Met when: AC-04 proved by C1 and C2; AC-05 proved by C3; C4 and G1 green.
```

**Size.** A feature fits the review budget: † by default at most 300 changed lines, tests
included, at most two review families, one owner. A larger feature is split in the PRD, by
acceptance criterion, never by layer (`SDD-SPEC-04`). The opposite also costs: each feature pays
a fixed price — a bundle, a spawn, a review — so splitting below what one review handles raises
the bill instead of lowering it.

### 4.4 Triage, repo search and the edge sweep

**Triage.** Every request starts in `workflow-search`. A request usually touches several entities
and capabilities at once, and one long search over all of it returns little. So the session first
splits the request into **slices**, one sentence each, on five fixed axes, and notes the entities
and capabilities each slice touches (`SDD-FLOW-05`):

| Axis | What belongs there |
| --- | --- |
| product | promised behavior, rules, who uses it and what they see |
| frontend | screens, routes, guards, client state |
| backend | endpoints, data, sessions, server-side rules |
| tooling | tests, scripts, CI, environment variables, the harness |
| stack | libraries, providers, versions: the decisions that last |

An axis the request does not touch stays out. For each slice, the session reads the **record**
before the code, in this order: the PRD and its amendments, the ADRs, existing bundles, the
project's docs (`CLAUDE.md`, `docs/`, READMEs) and the agent memory the project keeps. A slice the
record answers never reaches the code. Each slice still open gets **one** bounded question to
`repo-explorer`, all side by side, in a single round; an unanswered question becomes a gap, never
a second round. The search is internal: no web page, no library documentation, no external source
(`SDD-FLOW-06`).

Each slice ends with a verdict, and the verdict names the next step:

| Verdict | Next step |
| --- | --- |
| already exists | nothing; the triage cites the source |
| missing product decision | plan: `product-manager`, a PRD amendment |
| missing lasting technical decision | plan: `software-architect`, an ADR |
| to build | plan: `spec-writer`, a bundle with the slice's facts |
| no behavior change | plan: the fast lane (§4.5) |
| traces to nothing | a question for the owner |

The triage file also gives the request one **route**: what plan writes, in which order — an
amendment before the bundles that depend on it, an ADR before the bundles that cite it. The
triage classifies and routes; it never decides scope or design. That is plan's job, and the
owner's.

**Repo search.** The triage's code facts are the repo search a bundle needs (`SDD-SPEC-01`): what
already exists for each interface the feature provides, every caller of what it changes, the
tests around it, and the conventions of the layer. They come back with `file:line`, and the Spec
Writer cites them in `spec.md`. A new item asks `repo-explorer` one question about the failing
branch itself, from plan; that is not a return to search (`SDD-FLOW-02`). The point is that the
code reveals nothing new during implementation: what exists was read before the spec was written.

Then the Spec Writer runs each `AC-*` and each rule of the feature through seven edge categories, once
(`SDD-SPEC-07`):

| Category | The question that tends to slip through |
| --- | --- |
| boundary | is the value exactly at the limit in or out? minimum, maximum, zero, negatives, rounding? |
| time | counted from when? expires when, in which time zone? events out of order? |
| empty | empty list, missing optional field, first use? |
| repetition | the same action twice, two people at once? |
| permission | which role, which owner, which tenant, a visitor with no session? |
| failure | a dependency down, an operation stopped halfway: what does the person see, what is undone? |
| what already exists | data stored before the change, a client on the previous version, behavior someone depends on? |

Each edge that applies ends as a check in `contract.md`, a line in the PRD's Out of Scope through
an amendment, or a gap for the owner. The sweep deepens the feature, never widens it.

### 4.5 The fast lane

A fix or refactor of something already built — no product behavior changes — gets a bundle with
no PRD amendment (`SDD-SPEC-09`): `plan.md` and `contract.md`, plus `spec.md` only when an
interface changes. Its contract traces the existing `AC-*` it protects, or names the defect and
the check that reproduces it. Repo search still runs first.

---

## 5. The run

Two phases run this section. `workflow-implementation` starts features and runs the implementer
and the gates: §5.1, steps 1–3 of §5.2, and the implementer's half of each fix round.
`workflow-review` runs the review, the verdict, delivery and the split: steps 4–5 of §5.2, and
§5.3. The state file (§5.4) is the only thing that passes between them, and the fix-round counter
lives in it (`SDD-FLOW-03`).

### 5.1 When a feature starts

A feature starts as soon as all five hold, without waiting for the rest of its wave (`SDD-RUN-01`):

1. its bundle is `Approved`;
2. every feature it consumes from has merged — the provider's contract landed first;
3. it depends on no open gap;
4. its Surface shares no file with a running feature's Surface;
5. a slot is free within the **wave width** — the number of features writing at once. † Default
   **4**, recorded by the project with its review budget.

Waves are how the PRD reads; execution is rolling.

### 5.2 One feature, end to end

1. `scripts/spawn-detached F03-<slug>` creates the worktree and branch from the base `plan.md`
   names, runs `scripts/resolve-env` and `scripts/migrate-dev` inside it, and starts the
   implementer there (`SDD-RUN-02`).
2. The implementer reads its feature folder and the files `plan.md` cites, writes the code and
   the checks the contract names, and commits its own diff.
3. `scripts/run-gates F03-<slug>` runs every gate `contract.md` names. A failing gate goes back to
   the implementer **before** any review (`SDD-RUN-03`) and does not count as a fix round: the
   reviewer never spends a turn on code that does not build.
4. With the gates green, a new `code-reviewer` instance, independent of the author, receives
   `contract.md`, the Surface line of `plan.md`, the diff against the base and the gate summary,
   and nothing else (`SDD-RUN-04`). It answers one question: is the contract met? It checks each `AC-*` against
   the checks that prove it, compares the diff's files with the Surface, and confirms the
   non-functional gates passed.
5. Contract met → push and PR, under the owner's authorization (`SDD-RUN-08`), then merge. The
   orchestrator marks the feature `merged`, and every feature that consumed from it re-checks
   §5.1.

### 5.3 When the review fails

| Round | Who runs it | What it receives |
| --- | --- | --- |
| fix 1 and fix 2 | the same implementer, resumed | only the failing checks and unmet `AC-*`, verbatim from the review |
| re-review after each fix | a new `code-reviewer` instance | the failing checks, the fix diff since the last reviewed commit, the new gate summary |
| after fix 2 still fails | nobody fixes again | the Spec Writer writes a **new item** from the failing checks; the owner decides |

The cap is two fix rounds (`SDD-RUN-05`). There is no third round and no move to a higher tier:
a feature two rounds could not close has a spec problem, not a model problem.

**The new item** (`SDD-RUN-06`) is a bundle in its own folder, `.specs/features/F03.1-<slug>/`,
that traces the same `AC-*`, starts from the failing branch, and holds only what the contract
could not get to. The owner reads it and answers: approve it (it runs like any feature), or drop
the feature. The failed feature's state becomes `split`, pointing at the new item.

**What the reviewer may not do.** Its findings are the contract's checks and `AC-*`, and the
files outside the Surface. Anything else it notices goes under **Notes**, which do not fail the
review. Two exceptions block the merge without counting as a fix round: a security defect, and a
regression of a contract that already merged. Both go to the owner as a new item before merge.

### 5.4 The state file

The orchestrator's whole view of a feature (`SDD-CORE-04`):

```yaml
feature: F03-invites
status: waiting | running | gates-failed | in-review | fixing | contract-met | merged | split | dropped
wave: W1
branch: feat/F03-invites
round: 0            # fix rounds used, at most 2
gates: pass | fail — <one-line summary from run-gates>
review: met | unmet — <the unmet AC-* and failing checks, IDs only>
gaps: []            # open questions returned by the implementer, one sentence each
next: <the item that replaces it, when status is split>
started: <ISO 8601>
finished: <ISO 8601>
```

`started` and `finished` exist so lead time per feature, and the time a ready feature waited for
a slot or for the owner, come from measured data, not impression.

### 5.5 Gaps during the run

A question the feature's files do not answer is returned as a gap, in one sentence, and the
feature waits (`SDD-RUN-07`). The Spec Writer answers it as a new item — or, when it changes what
the product promises, the owner answers it through a PRD amendment. The implementer never picks
an answer and keeps going: a question found in the middle of the code arrives with a guess
already written into it. The repo search exists so this is rare.

### 5.6 Owner touchpoints

The owner answers at exactly these points, each in one message:

| Point | Question |
| --- | --- |
| PRD or amendment | approve, change, or reject? |
| bundle (one or several features, as one message) | approve, change, or reject each? |
| push and PR | authorized for this run, once, or per wave? Merge is never covered |
| new item after two failed rounds, or a blocking note | approve the new item, or drop the feature? |
| gap that changes the product | the answer, or accept it as an assumption with what would invalidate it |

Silence approves nothing (`SDD-CORE-03`).

---

## 6. The harness scripts

Six scripts at the root of the consuming project, written once by the `scaffold-sdd-scripts`
command (`SDD-SCR-01`). Each one is idempotent, non-interactive, exits `0` on success and non-zero
on failure, prints at most a short summary, and writes its full output to `.sdd/logs/`
(`SDD-SCR-02`).

| Script | Does | Called by |
| --- | --- | --- |
| `init.sh` | first setup of a checkout or worktree: install, resolve the environment, migrate, run the baseline gates | a person, once; `spawn-detached` in each worktree |
| `scripts/resolve-env` | writes the worktree's environment: free ports, its own database name, the variables the app needs | `init.sh`, `spawn-detached` |
| `scripts/migrate-dev` | applies migrations to the worktree's own development database | `init.sh`, the implementer when `plan.md` says so |
| `scripts/run-gates` | runs the gates a contract names, by type, and reports pass or fail per gate | the orchestrator, after each implement or fix |
| `scripts/spawn-detached` | creates the worktree and branch, prepares it, starts the agent detached, records its pid | the orchestrator, once per feature |
| `scripts/stop` | stops one feature's detached run, or all of them | the orchestrator, a person |

Each worktree gets its own ports and its own database, so features running side by side do not
collide on shared state (`SDD-SCR-03`). The commands each script runs — the install, the
migration tool, the gate per type, the agent CLI — come from one file, `sdd.config.sh`, so the
scripts stay the same across stacks.

---

## 7. Normative rules

Convention: `MUST`/`NEVER` are normative. **†** marks a decision of this doc.

### `SDD-CORE-*` — what holds across every step

| ID | Rule |
| --- | --- |
| `SDD-CORE-01` | The PRD **MUST** be the product's single source of truth: every feature, acceptance criterion and dependency **MUST** trace to it; work that traces to nothing in the PRD **NEVER** enters a run. † |
| `SDD-CORE-02` | Product and specification decisions **MUST** be made once, before the run, by the high tier (`product-manager`, `spec-writer`); implementing, fixing and reviewing run on the mid tier, in fresh context, and **NEVER** decide product or specification. Every delegated step **MUST** go to a named agent called as a subagent, with its own model and effort; a generic agent, or a session told to act "as" a role, **NEVER** — both inherit the caller's model (Anthropic cookbook, plan big execute small; `CC-PAR-05`). |
| `SDD-CORE-03` | Every file in `.specs/` **MUST** be born `Draft` (an ADR `Proposed`) and change status only on the owner's explicit reply; one reply may approve a bundle of several features when it names them; the writer approving its own file, or silence counting as approval, **NEVER**. |
| `SDD-CORE-04` | The orchestrator **MUST** hold only one state file per running feature (§5.4); reading code, diffs, gate logs or review reports in the orchestrating session **NEVER** — that context is reread on every turn until the run ends. † |
| `SDD-CORE-05` | A mechanical operation — environment, migration, gates, spawning or stopping a run — **MUST** run through its harness script; an agent typing a gate's commands and reading their full output when a script exists **NEVER**. † |
| `SDD-CORE-06` | Registering work on a board **MUST** stay outside this flow; a step that writes to a tracker, or waits on one, **NEVER**. † |

### `SDD-PRD-*` — the PRD

| ID | Rule |
| --- | --- |
| `SDD-PRD-01` | The PRD **MUST** keep these sections, in order: Summary, Problem and Opportunity, Target Audience, Objectives, User Stories, Functionalities, Out of Scope, Dependency Graph (Foundation Features, Execution Waves, Priority levels), Traceability, Open gaps. † |
| `SDD-PRD-02` | Every feature **MUST** declare what it provides and what it consumes, and every consumed item **MUST** name exactly one provider feature; a consumer with no provider, or two providers of one item, **NEVER**. † |
| `SDD-PRD-03` | Every acceptance criterion **MUST** carry a PRD-wide ID (`AC-NN`) and an observable outcome in Given / When / Then; a criterion with nothing to observe **NEVER** — no contract can prove it (`DOC-PRD-02`). |
| `SDD-PRD-04` | The Dependency Graph **MUST** list the foundation features (no consumes) and the execution waves, wave `Wn` holding only features whose providers sit in earlier waves; a cycle **NEVER** — it **MUST** be broken by extracting the shared part into its own provider feature. † |
| `SDD-PRD-05` | Every Problem and Opportunity item and every Objective **MUST** list the features that address it, each as provider or consumer, and every feature **MUST** appear under at least one; a feature traced to nothing, or a problem no feature addresses, **NEVER**. † |
| `SDD-PRD-06` | The PRD **NEVER** carries technical design (`DOC-PRD-03`); once `Approved` it **MUST** be frozen, and a change, including a new feature, enters as a dated amendment approved by the owner (`DOC-PRD-04`). |

### `SDD-SPEC-*` — the feature bundle

| ID | Rule |
| --- | --- |
| `SDD-SPEC-01` | Before a bundle is written, a repo search **MUST** have run through `repo-explorer`, bounded to the feature — what exists for each interface it provides, every caller of what it changes, the tests and conventions around it — normally as the triage of `workflow-search` (§4.4), and the Spec Writer **MUST** cite the facts with `file:line`; a bundle written from the PRD alone **NEVER**. † |
| `SDD-SPEC-02` | Each feature **MUST** have one folder, `.specs/features/<ID>-<slug>/`, with `spec.md`, `plan.md` and `contract.md`, each answering only its question (§4.3); a fact **MUST** live in one file and the others link to it; copying content between files **NEVER** — the copy diverges. |
| `SDD-SPEC-03` | `spec.md` **MUST** hold what the feature exposes and consumes — interfaces, data shapes, invariants, boundary decisions — and a UX section only when the feature has an interface that needs one; step order or checks in `spec.md` **NEVER**. † |
| `SDD-SPEC-04` | `plan.md` **MUST** hold the ordered steps, the Surface, the Size, the base branch and the commands, plus any script only this feature needs, and **MUST** fit the review budget (default: 300 changed lines, two review families, one owner); a larger feature is split in the PRD by acceptance criterion, splitting by layer or file **NEVER**. † |
| `SDD-SPEC-05` | `contract.md` **MUST** list one check per line, each citing the `AC-*` it proves and the gate type that runs it at the cheapest level that catches the defect (`TS-CORE-02`); every `AC-*` the feature traces **MUST** have at least one check, and the non-functional gates — static checks, the touched suite, and the security class when the feature touches authentication, authorization or sensitive data — **MUST** be listed. † |
| `SDD-SPEC-06` | A contract is met **only** when it proves that every acceptance criterion it traces was met, as its **Met when** line states per `AC-*`; green checks that cover no `AC-*` **NEVER** close a contract, and an `AC-*` with no passing check **NEVER** does either. † |
| `SDD-SPEC-07` | The Spec Writer **MUST** run each `AC-*` and rule of the feature through the seven edge categories of §4.4 once, and each edge that applies **MUST** end as a check, an Out of Scope line through a PRD amendment, or a gap for the owner; the implementer re-deriving the sweep **NEVER** (Myers, boundary value analysis; Wynne, Example Mapping). |
| `SDD-SPEC-08` | The bundle of a merged feature is **NEVER** rewritten; a later change, a failed contract or a gap **MUST** become a new item in its own folder, written by the Spec Writer and approved by the owner. † |
| `SDD-SPEC-09` | A fix or refactor that changes no product behavior **MUST** take the fast lane: a bundle with no PRD amendment, `spec.md` only when an interface changes, its contract tracing the `AC-*` it protects or reproducing the defect; opening a PRD amendment for it **NEVER** (`DOC-CORE-02`). † |

### `SDD-RUN-*` — the run

| ID | Rule |
| --- | --- |
| `SDD-RUN-01` | A feature **MUST** start as soon as its bundle is approved, every provider it consumes from has merged, it depends on no open gap, its Surface shares no file with a running feature, and a slot is free within the wave width (default 4); running ready features one at a time with no stated reason **NEVER**, and starting a consumer before its provider's contract landed **NEVER**. † |
| `SDD-RUN-02` | Each feature **MUST** run in its own worktree and branch, created by `scripts/spawn-detached`, and its implementer **MUST** read only the feature folder and the files `plan.md` cites; reading the whole PRD or another feature's folder **NEVER**. † |
| `SDD-RUN-03` | `scripts/run-gates` **MUST** run before every review; a failing gate goes back to the implementer without a review and without counting as a fix round. † |
| `SDD-RUN-04` | The review **MUST** run in a new instance independent of the author, receiving only `contract.md`, the Surface from `plan.md`, the diff and the gate summary, and **MUST** decide one thing: whether the contract is met (`SDD-SPEC-06`); a finding outside the contract and the Surface is a non-blocking note, except a security defect or a regression of a merged contract, which block the merge and go to the owner as a new item (Google SWE practices; `CC-SES-07`, `CC-SES-10`). |
| `SDD-RUN-05` | A failed review **MUST** get at most two fix rounds, each run by the same implementer resumed with only the failing checks, each followed by a delta re-review in a new instance; a third round, or moving the fix to a higher tier, **NEVER**. † |
| `SDD-RUN-06` | A feature still failing after two fix rounds **MUST** stop: the Spec Writer writes a new item from the failing checks, tracing the same `AC-*` and starting from the failing branch, and the owner approves it or drops the feature; reopening the PRD or the feature's bundle instead **NEVER**. † |
| `SDD-RUN-07` | A question the feature's files do not answer **MUST** be returned as a gap in one sentence while the feature waits; it closes as a new item, or as a PRD amendment when it changes what the product promises; the implementer choosing an answer and continuing **NEVER** (Wynne, Example Mapping). |
| `SDD-RUN-08` | A feature **MUST** merge only with its contract met; push and PR need the owner's authorization, given once per run or once per wave and quoted in the state file, and that authorization **NEVER** covers merging on the owner's behalf unless the owner said so. † |

### `SDD-SCR-*` — the harness scripts

| ID | Rule |
| --- | --- |
| `SDD-SCR-01` | The six global scripts — `init.sh`, `scripts/resolve-env`, `scripts/migrate-dev`, `scripts/run-gates`, `scripts/spawn-detached`, `scripts/stop` — **MUST** live at the root of the consuming project, read their commands from `sdd.config.sh`, and a script only one feature needs **MUST** live in that feature's `plan.md`; a global script per feature **NEVER**. † |
| `SDD-SCR-02` | Every script **MUST** be idempotent and non-interactive, exit `0` on success and non-zero on failure, print at most a short summary and write its full output to `.sdd/logs/`; a script that prompts, or that dumps its full log into the caller's context, **NEVER**. † |
| `SDD-SCR-03` | Each worktree **MUST** get its own ports and its own development database from `scripts/resolve-env`; two running features sharing one database or port **NEVER**. † |

### `SDD-FLOW-*` — the phases

| ID | Rule |
| --- | --- |
| `SDD-FLOW-01` | The flow **MUST** run as four phases, in order — search, plan, implementation, review — each entering on its written condition and leaving with its named artifact (§2); a phase starting without its entry condition **NEVER**. † |
| `SDD-FLOW-02` | The flow **MUST** only move forward: the review may send a feature back to implementation for a fix round (`SDD-RUN-05`) or on to plan as a new item (`SDD-RUN-06`), and nothing else goes back; a failure re-entering search, or reopening a closed triage, PRD section or bundle, **NEVER**. † |
| `SDD-FLOW-03` | The state file **MUST** be the only handoff between implementation and review, and the fix-round counter **MUST** live in it; passing a diff, a log or a review report between the two phases **NEVER** (`SDD-CORE-04`). † |
| `SDD-FLOW-04` | The main session **MUST** load one phase skill at a time, and each phase **MUST** hand its work to named agents or scripts; a phase loading another phase as a sub-orchestrator **NEVER** — two orchestrators reread on every turn is the cost that retired the four-pillar flow. † |
| `SDD-FLOW-05` | Search **MUST** split the request into slices on five axes — product, frontend, backend, tooling, stack — and give each slice a verdict and a next step (§4.4); search deciding scope or design **NEVER**: it classifies and routes, and plan decides. † |
| `SDD-FLOW-06` | Search **MUST** stay internal and short: the record before the code, a slice the record answers never sent to the code, one question per open slice in a single round; a second search round, or an external source such as a web page or library documentation, **NEVER**. † |

### Count

**38 rules** in six families, a single file.

| Family | Rules |
| --- | --- |
| `SDD-CORE-*` | 6 |
| `SDD-PRD-*` | 6 |
| `SDD-SPEC-*` | 9 |
| `SDD-RUN-*` | 8 |
| `SDD-SCR-*` | 3 |
| `SDD-FLOW-*` | 6 |

---

## 8. Skill contract

### What to load

```
WHEN TRIAGING a request (workflow-search):             § 4.4 "Triage" + SDD-FLOW-05, SDD-FLOW-06
WHEN WRITING or AMENDING the PRD (workflow-plan):      § 4.2 + SDD-CORE-01, SDD-CORE-03, SDD-PRD-*
WHEN WRITING a bundle or a new item (workflow-plan):   § 4.3, § 4.4, § 4.5 + SDD-SPEC-*
WHEN RUNNING features (workflow-implementation):       § 3, § 5.1, § 5.2 + SDD-CORE-04, SDD-CORE-05, SDD-RUN-01–03, SDD-RUN-07
WHEN REVIEWING and DELIVERING (workflow-review):       § 4.3 "The contract", § 5.2, § 5.3 + SDD-SPEC-06, SDD-RUN-04–08
WHEN MOVING between phases:                            § 2 + SDD-FLOW-01–04
WHEN SCAFFOLDING the scripts:                          § 6 + SDD-SCR-*
NEVER:                                                 this whole doc inside an implementer or a reviewer;
                                                       each one gets its feature's files and the rule IDs its skill cites
```

### How to cite

> `SDD-SPEC-06` — the reviewer reports C1–C3 green, but `AC-05` ("an expired invite returns 410")
> has no check in the contract. The contract is not met: an `AC-*` with no passing check never
> closes it. The finding goes to the fix round as "AC-05 unproved".
> See [Delivery Flow — Spec Driven Development](delivery-flow.md) § 4.3.

### Invariants every skill of this flow enforces

1. Delegation names the agent and calls it as a subagent (`SDD-CORE-02`).
2. Every `.specs/` file it writes is born `Draft` and waits for the owner (`SDD-CORE-03`).
3. It returns a path and a status, never a file's content, to the orchestrating session
   (`SDD-CORE-04`).
4. It loads no other phase, and it ends by naming the next phase and what that phase reads
   (`SDD-FLOW-04`).

---

## 9. Bridges to the stack

| Decision | What **not** to do | The bridge |
| --- | --- | --- |
| What to build and why | decide it in the bundle or the code | `product-manager`, via `doc-prd` |
| A boundary decision that outlives the feature | bury it in one `spec.md` | `software-architect`, via `doc-adr` |
| Which test level proves a check | leave it for the implementer | the gate type in `contract.md`, chosen by `TS-CORE-02`; `test-design` when it is not obvious |
| The HTTP contract of a provided route | invent status and shape in the handler | `http-contract`, cited from `spec.md` |
| Code quality beyond the contract | turn every review into a full audit | the family review skills, run on request or as a gate the contract names |
| A security finding | fix it inside the round and move on | `devops-security`, and a new item before merge (`SDD-RUN-04`) |
| Board items | create them inside the flow | outside this flow (`SDD-CORE-06`) |

---

## Sources consulted

- Anthropic, *Claude Cookbooks* — `managed_agents/CMA_plan_big_execute_small.ipynb`: a frontier
  orchestrator plans and synthesizes and never reads raw material; cheaper workers execute in
  their own contexts and return distilled results; delegation has a floor cost, so more and
  narrower briefs raised the bill; and the verification standard only covers what is put in it.
  Basis for `SDD-CORE-02`, the review budget's lower bound (§4.3 "Size") and the non-functional
  gates in every contract (`SDD-SPEC-05`). Consulted on 2026-10-25.
- Glenford Myers, *The Art of Software Testing* — boundary value analysis; the "boundary"
  category of the edge sweep (`SDD-SPEC-07`). Consulted through chapter summaries.
- Matt Wynne, *Introducing Example Mapping* (Cucumber blog) — the question nobody can answer
  becomes a card instead of a guess; basis for `SDD-RUN-07`.
- Winters, Manshreck, Wright, *Software Engineering at Google* — review by a peer independent of
  the author (`SDD-RUN-04`).
- **Internal precedent, not external authority:** the owner's SDD draft and decisions of
  2026-10-25 — PRD as single source of truth with provides/consumes and waves; `spec.md`,
  `plan.md`, `contract.md` per feature; the implement → review → fixer → review loop; the six
  scripts; UX as a section of `spec.md`; repo search before writing; a failed contract becoming
  a new item; two fix rounds; ADRs kept; board registration out of the flow; and a contract met
  only when it proves its acceptance criteria met.

- **Internal precedent, not external authority:** the owner's decisions of 2026-10-26 — four
  phase skills in `skills/workflow/` (search, plan, implementation, review) absorbing
  `skills/sdd/`; search as an internal triage on five axes (product, frontend, backend, tooling,
  stack), with no external source and no long search; the main session splitting the request;
  this hub moved out of the knowledge base into the family's own docs.

**What could not be verified against a primary source in this version:** the cookbook was read
in full; the books were not reread on this date. Rules marked † are this project's decisions.

---

## Related

- `skills/workflow/` — `workflow-search`, `workflow-plan`, `workflow-implementation`,
  `workflow-review`: the four phases this doc is the foundation of
- `agents/README.md` — the roles this flow calls, and the tier each runs on
- `skills/design-docs/` — `doc-prd` and `doc-adr`, among the nine document writers
- `commands/spec.md` and `commands/scaffold-sdd-scripts.md` — search and plan, then stop; and the
  harness scripts

In the knowledge base, cited by name: `Decision Documents — PRD, RFC and ADR` (what the PRD and
the ADR are, and when each freezes); `Teste de Software` §4.1 (the cheapest level that catches the
defect, behind each check's gate type); `Claude Code - Paralelismo e Escala` (subagents,
worktrees, and why a session opened by another inherits its model); `Claude Code - Sessão e
Verificação` (`CC-SES-07`, `CC-SES-10`: review in fresh context, with a bounded criterion);
`Trunk-based development` (small batches, behind the review budget).
