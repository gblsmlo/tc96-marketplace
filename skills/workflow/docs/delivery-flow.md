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
source: "Anthropic, Claude Cookbooks — managed_agents/CMA_plan_big_execute_small.ipynb (a frontier model plans and synthesizes, cheaper workers execute in their own contexts; delegation has a floor cost; verification only covers what you put in it); Glenford Myers, The Art of Software Testing (boundary value analysis, behind the edge sweep); Matt Wynne, Introducing Example Mapping (the unanswered question becomes a card, never a guess); Winters/Manshreck/Wright, Software Engineering at Google (review by an independent peer); internal precedent: the owner's SDD draft and decisions of 2026-10-25, 2026-10-26 (four phase skills) and 2026-10-27 (the delivery planned in layers, outside in, measured on the users-crud test round)"
verified-on: 2026-10-27
---

# Delivery Flow — Spec Driven Development

> **What this doc is.** The delivery flow of this house, and the foundation of the four phase
> skills in `skills/workflow/`: search, plan, implementation and review. The specification is the
> primary artifact and the contract the code must meet. Search triages every request into slices
> and routes each one. A PRD, the product's single source of truth, names the capabilities and
> their acceptance criteria. A Spec Writer plans the delivery once, from the outside in, as one
> index and one file per architectural layer — contracts, repository, backend, frontend, tests,
> gates — deciding only the seams between layers and the rules each must hold. Each layer then
> runs through a fixed loop — implement, gates, review against its checks, fix — on cheaper
> models, driven by scripts, into the delivery's feature branch; the delivery reaches the trunk
> once, validated.
>
> **What it is not.** It is not a role. It does not replace any agent in `agents/README.md`; it
> says which agent runs at each step and what it receives. It is not a project-management tool:
> no step of this flow writes to a board.
>
> **Why it exists.** A plan cut per capability, with step-by-step instructions, makes every
> capability carry a slice of every layer and re-decide the same seams, and its size is discovered
> one capability at a time and sent back to the PRD. On the users-crud test round (2026-10-27) a
> cut like that cost about $29 of planning and three amendments without finishing, where the
> layered plan covered all 33 acceptance criteria for $2.50–4.16 in one owner gate, with the same
> implementation accuracy on hidden oracles. A plan that dictates how also leaves the
> specialist skills nothing to decide. This flow plans the seams once, up front, on the expensive
> model, lets each layer's owner build the inside with its skills, gives the reviewer one fixed
> oracle per layer, and moves every mechanical step into a script.

Sources consulted on **2026-10-25**; the phases on **2026-10-26**; the layered plan on
**2026-10-27**. See [Sources consulted](#sources-consulted).

---

## 0. Before anything else: five distinctions that settle the conversation

**1. Plan big × execute small.** Product and delivery decisions are made **once**, before any
code, by the high tier: the PRD by `product-manager`, the delivery plan by `spec-writer`.
Implementing, fixing and reviewing run on the mid tier, each in a fresh context, and never decide
product or plan (`SDD-CORE-02`). The cookbook pattern this follows puts the frontier model on
planning and synthesis and keeps it away from raw reading; the same split here keeps the
expensive model away from diffs, logs and test output.

**2. Seams × inside.** The plan decides what crosses from one layer to the next — names and
type-level shapes — and the rules each layer must hold, each with its source. How a layer is built
inside — files, helpers, queries, components, the order of the work — is the owner's, with the
specialist skills the layer names (`SDD-PLAN-04`). A plan line that says how is either an ADR, an
acceptance criterion with a check, or noise.

**3. Contract met × checks green.** A layer is done when its checks pass; the delivery is done
when its contract is met, and a contract is met only when it **proves that every acceptance
criterion it traces was met** (`SDD-PLAN-07`). A green check that covers no acceptance criterion
does not close it; an acceptance criterion with no check does not either. Green gates are
necessary, never sufficient.

**4. Global × local scripts.** The six harness scripts — environment, migrations, gates, spawning
and stopping a run — live once, at the root of the consuming project, and every layer uses them
(`SDD-SCR-01`).

**5. Spec × board.** The specification is the work list: the plan's index says what runs, in
what order, and how far it got. Registering work on a board is outside this flow
(`SDD-CORE-06`); a project that keeps one mirrors the index by hand or by its own tooling.

---

## 1. How to use this doc

### For a person

Start every request with `workflow-search`. It splits the request into slices, reads what is
already decided, and says where each slice goes next: a PRD amendment, an ADR, the delivery plan,
the fast lane, or a question for you. `workflow-plan` then writes what the triage asked for and
stops at your approval. An approved delivery runs layer by layer in `workflow-implementation`; a
layer whose gates are green goes to `workflow-review`, which opens its pull request into the
delivery's feature branch. When the last layer is merged there, the review validates the whole
delivery and opens the one pull request into the trunk that you approve. A fix or refactor of
something already built also starts at search; its triage sends it to the fast lane
(`SDD-PLAN-10`).

### For a coding agent

Read only the files your step names in §3. A layer's implementer reads the plan's index, its own
layer file, the **Provides** its layer links to and the ADR sections it cites — never the PRD
whole, never another layer's checks, and it never edits the index. A reviewer reads the layer
file, the diff and the gate result, never the conversation that produced the change. A question
your files do not answer is a gap you return (`SDD-RUN-07`), never a guess you write into the
code.

### Conventions

`MUST`/`NEVER` are normative, as in the rest of the knowledge base. **†** marks a decision of this
doc, with no direct parallel in a single external source.

---

## 2. Mental model

```
SEARCH (every request · main session + fast tier · decides nothing)
request ─► slices on five axes ─► record first ─► repo-explorer for open slices ─► triage file
                                                                                    │ verdict + next step per slice
PLAN BIG (once, high tier)                 EXECUTE SMALL (per layer, mid tier, fresh context)
──────────────────────────                 ─────────────────────────────────────────────────────
PRD  ── owner approves                     implementer ──► run-gates ──► reviewer (layer file)
 │  capabilities · AC-* · traceability        ▲ + skills      │ fail         │ checks met
 ▼                                            │               ▼              ▼
Spec Writer ── facts from the triage          └── fixer (≤ 2 rounds) ◄── fail     PR → feat/<delivery>
 │  plan.md (index, outside in, progress)                     │
 │  plans/<layer>.md (seams, rules, skills, checks)           ▼ still failing
 │  contract.md (AC-* → checks)               Spec Writer writes a new layer file ── owner decides
 └─ owner approves the delivery
                                           all layers merged ─► final review (contract.md) ─► PR → trunk, owner approves

HARNESS (scripts at the project root, no model tokens)
init.sh · scripts/resolve-env · scripts/migrate-dev · scripts/run-gates · scripts/spawn-detached · scripts/stop
```

| # | Phase | Skill | Enters when | Leaves with |
| --- | --- | --- | --- | --- |
| 1 | **Search** | `workflow-search` | any request arrives | `.specs/triage/<date>-<slug>.md`: the request's slices on five axes, each with its facts and source, a verdict and a next step; and the request's route |
| 2 | **Plan** | `workflow-plan` | the triage sends slices to a PRD amendment, an ADR, the delivery plan or the fast lane; or the review produced a new layer | `.specs/PRD.md` or a dated amendment, ADRs, and `.specs/delivery/<date>-<slug>/` — index, layer files and contract — each `Approved` by the owner |
| 3 | **Implementation** | `workflow-implementation` | a delivery is approved and a layer's start conditions hold (§5.1), or the review sent a layer back as `fixing` | a layer branch with green gates; state `in-review` |
| 4 | **Review** | `workflow-review` | a layer's state is `in-review` with gates `pass`; or every layer is merged into the feature branch | a layer PR into the feature branch; or `fixing`, at most twice; or a new layer for plan; at the end, the delivery PR into the trunk |

Each phase is a skill the main session loads, one at a time; none is an agent, and none loads
another (`SDD-FLOW-04`). The only ways back belong to the review: a fix round to implementation,
or a new layer file to plan. No failure goes back to search, and no phase reopens a closed one: a
wrong product decision is a PRD amendment; a layer that turned out short is a new layer file. Both
go forward, through the owner (`SDD-FLOW-02`).

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
| plan | write the delivery plan | `spec-writer`, via `workflow-plan` | alto · alto | the PRD, the triage's facts, the ADRs, the list of specialist skills | decides the seams and the proof once, for every layer and round that follows |
| plan | a decision that outlives the delivery | `software-architect`, via `doc-adr` | alto · alto | the decision in question | lasting boundary decisions get their own record |
| implementation | prepare env, migrate, spawn the worktree | `scripts/resolve-env`, `scripts/migrate-dev`, `scripts/spawn-detached` | — | — | mechanical; exit code only |
| implementation | implement a layer, and fix rounds 1–2 | the layer's owner — `backend-developer` · `frontend-developer` · `qa-engineer` — resumed for each round | medio · medio | the index, its layer file, the **Provides** it links to, the ADR sections it cites, and the skills it names | most tokens; the gates and the reviewer catch its errors |
| implementation | run the gates the layer names | `scripts/run-gates` | — | — | the result is an exit code and a short summary |
| implementation | update the index's Status | the main session, via `workflow-implementation` | the person's choice | the state file | one writer, so layers running side by side never conflict on the index |
| review | review a layer against its checks | `code-reviewer`, with `workflow-review`'s `references/contract-review.md` | medio · alto | the layer file, the diff against the feature branch, the gate summary | it is the verification; nothing reviews it |
| review | validate the delivery | a new `code-reviewer` | medio · alto | `contract.md`, the layer files its rows point to, the diff against the trunk, the gate summary on the feature branch | the only gate between the feature branch and the trunk |
| review | security-class layer | `devops-security`, beside the reviewer | alto · alto | the sensitive path in the diff | a missed finding costs more than the tokens |
| review | push, open the PR | `repo-operator`, or the session when it is one known command | rapido · baixo | the PR template, the state file | template filled from the state file |
| any | orchestrate: state files, routing, talking to the owner | the main session, via the phase skill it loaded | the person's choice | state files and the index | a plugin does not pin the session's model |

Every delegated step goes to the named agent, called as a subagent, so it runs on its own tier
and carries its own body; a generic agent, or a session told to act "as" a role, inherits the
caller's model instead (`SDD-CORE-02`, `CC-PAR-05`).

**What the orchestrator never reads.** Code, diffs, gate logs and review reports stay in the
agent or script that produced them. The orchestrator holds one state file per running layer
(§5.5) and the index's Status column, and nothing else (`SDD-CORE-04`).

---

## 4. The artifacts

### 4.1 Where they live

```
.specs/
├── triage/
│   └── <date>-<slug>.md           workflow-search · slices, verdicts, the route
├── PRD.md                          product-manager · capabilities and acceptance criteria
├── adr/
│   └── NNNN-<slug>.md              software-architect · never edited, only superseded
└── delivery/
    └── <date>-<slug>/
        ├── plan.md                 spec-writer · the index: outside in, layers, order, branches, progress
        ├── plans/
        │   ├── L1a-<slug>.md       spec-writer · one layer: seams, rules, skills, checks
        │   └── L2a-<slug>.md
        └── contract.md             spec-writer · which checks prove each acceptance criterion

.sdd/                               runtime only, git-ignored
├── state/<delivery>/L2a.md         the state file for one layer; the only handoff between implementation and review
├── logs/                           full output of every script run
└── run/                            pid files of detached runs
```

Each fact lives in one file; the others link to it (`SDD-PLAN-02`). A layer file is never
rewritten after its layer merges: a later change is a new layer file (`SDD-PLAN-09`).

### 4.2 The PRD

One file, `.specs/PRD.md`, for the product. Its sections, in this order (`SDD-PRD-01`):

| Section | Holds |
| --- | --- |
| **Summary** | the product in three sentences |
| **Problem and Opportunity** | numbered items (`PO-1`, `PO-2`…), each with its evidence and source |
| **Target Audience** | who has the problem, with the source that says so |
| **Objectives** | numbered (`OBJ-1`…), each with a metric and a target |
| **User Stories** | each with acceptance criteria numbered across the PRD (`AC-01`, `AC-02`…), in Given / When / Then |
| **Capabilities** | what the product can do (`CAP-1`, `CAP-2`…): a sentence each, the `AC-*` it satisfies, and its priority |
| **Out of Scope** | what someone might expect and is deliberately left out, and why |
| **Traceability** | for each `PO-*` and `OBJ-*`, the capabilities that address it |
| **Open gaps** | each question with who decides it; empty before `Approved` |

**Capabilities, not a delivery cut.** A capability is what a person can do with the product; it
names the acceptance criteria that prove it (`SDD-PRD-02`). It is not a unit of work: one
capability crosses every layer of the code. Layers, order, size, what one part provides another —
all of that is the delivery plan's (`SDD-PRD-04`). Priority levels (`P0` must ship for the
product to work, `P1` should, `P2` could) say what can be left out of a delivery, never how it is
built.

**Traceability.** Every `PO-*` and `OBJ-*` lists at least one capability, and every capability
appears under at least one of them (`SDD-PRD-05`). A capability traced to nothing is scope creep;
a problem traced to nothing is a promise nobody is building.

The PRD carries no technical design (`DOC-PRD-03`). An `Approved` PRD is frozen; a change enters
as a dated amendment, approved by the owner, and a new capability enters the same way
(`SDD-PRD-06`). A size problem never does: it is solved inside the plan.

### 4.3 The delivery plan: an index, one file per layer, and the contract

A PRD, or an amendment, is planned as **one delivery** in `.specs/delivery/<date>-<slug>/`
(`SDD-PLAN-02`). It reads from the outside in: who uses the system and through which door, the
vocabulary every layer shares, and then the layers, each giving the next a seam to code against
(`SDD-PLAN-03`).

| File | The one question | Read by |
| --- | --- | --- |
| `plan.md` | what does the system look like from the outside, which layers build it, in what order, and how far did they get? | everyone: the owner approving, every layer run, every reviewer |
| `plans/<layer>-<slug>.md` | what does this layer give the next, what must it hold, which skills build it, and how is it proved? | the layer's run and reviewer; consumers read only its **Provides** |
| `contract.md` | which checks prove each acceptance criterion? | the owner validating, the final review |

**The index.** Frontmatter with the delivery, the PRD and ADRs it builds on, the `trunk` and the
delivery's feature `branch` (`feat/<delivery>`). Then: from the outside (actors, doors, what sits
outside the code); the vocabulary (terms, roles, states, error codes, each with its source); the
starting point (at most ten `path:line` facts); the layers table — layer, goal, owner, depends
on, file, **Status**, **PR**; the order and the branches; the risks and open gaps. After
`Approved`, Status and PR are the only cells that change, and only the orchestrator writes them
(`SDD-PLAN-11`).

**The layers.** The defaults, outside in; a delivery drops a layer with nothing to do and never
adds a layer per capability:

| # | Layer | Typically holds |
| --- | --- | --- |
| L1 | Contracts and vocabulary | input/output schemas, table definitions, shared types, error codes, the API's shape, and the test environment every later layer's gates run in |
| L2 | Repository | data access over the tables, its unit and integration tests |
| L3 | Backend | routes, identity and access, errors, OpenAPI, commands, their integration tests |
| L4 | Frontend | API client, providers, queries and mutations, forms, screens, utils, their component tests |
| L5 | Tests | the journeys across layers (E2E) and the checks no single layer can prove |
| L6 | Gates | what only the whole delivery can check: security review, the ADRs' static invariants, the full suite and E2E together, CI |

**A layer file** holds, and nothing else (`SDD-PLAN-04`):

| Field | Holds |
| --- | --- |
| **Goal** | what the next layer can do once this one is merged |
| **Owner** · **Skills** | one role; the exact names of the specialist skills that build the inside, from the list the planner was given |
| **Consumes** | each seam it codes against, as a link to the **Provides** of the layer that defines it — never a copy |
| **Provides** | the seams the next layers code against, with a type-level shape: a signature, a schema's fields, a route with method, statuses and body |
| **Must hold** | the rules, each with its source (`AC-NN`, `ADR-NNNN §n`) |
| **Free to decide** | what the owner and its skills choose, said aloud so a review does not re-decide it |
| **Checks** | one per line: ID, the `AC-*` it proves, what is observed with the edge values, the level |
| **Surface** · **Size** · **Done when** | folders or globs; estimated changed lines and review family; its checks green plus G1 and G2 |

Never in a layer file: ordered steps, a file list, a regex, a function body, a query. Each one
takes a decision from the skill that knows it better and doubles what a person reads to approve.

**The checks.** Each check names one `AC-*` (or an ADR rule, for an invariant), what is observed,
and the level that proves it at the cheapest point that catches the defect — static, unit,
contract, integration, component, E2E, manual (`Teste de Software` §4.1, `TS-CORE-02`). A check
lives in the one layer that proves it; a journey across layers goes to L5 and says what a cheaper
level would miss (`SDD-PLAN-06`). Two gates hold on **every** layer's pull request, from L1 on:
G1, types and lint, formatting included; G2, the project's whole test command. L1 sets up what
they need, so no layer leaves them to the end. A layer on an authentication, authorization or
sensitive-data path adds G3, the security review.

**The contract** maps every `AC-*` the delivery traces to the IDs of the checks that prove it,
lists the ADR invariants, and the gates. It holds no check text: that lives in the layer files.
It is met only when every row has all its checks green on the feature branch (`SDD-PLAN-07`).

**Size.** A layer fits the review budget: † by default at most 300 changed lines, tests included,
one review family, one owner. A larger layer is split **inside the layer**, by capability (`L4a`
register screen, `L4b` list screen), as more rows and files in the same plan; it never goes back
to the PRD (`SDD-PLAN-05`). The opposite also costs: each layer pays a fixed price — a spawn, a
review — so splitting below what one review handles raises the bill.

**Order and branches.** Contracts come first, because every other layer codes against them; a
frontend layer runs beside the backend once the seams it consumes are merged. Every layer works
on `feat/<delivery>-<layer>`, cut from the delivery's feature branch `feat/<delivery>`, and its
pull request goes into that branch. Only the delivery's own pull request goes into the trunk,
after the delivery is validated (§5.4) and the owner approves. A half-built delivery never sits
on the trunk (`SDD-RUN-08`).

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
before the code, in this order: the PRD and its amendments, the ADRs, the delivery plans already
written, the project's docs (`CLAUDE.md`, `docs/`, READMEs) and the agent memory the project
keeps. A slice the record answers never reaches the code. Each slice still open gets **one**
bounded question to `repo-explorer`, all side by side, in a single round; an unanswered question
becomes a gap, never a second round. The search is internal: no web page, no library
documentation, no external source (`SDD-FLOW-06`).

Each slice ends with a verdict, and the verdict names the next step:

| Verdict | Next step |
| --- | --- |
| already exists | nothing; the triage cites the source |
| missing product decision | plan: `product-manager`, a PRD amendment |
| missing lasting technical decision | plan: `software-architect`, an ADR |
| to build | plan: `spec-writer`, the delivery plan, with the slice's facts |
| no behavior change | plan: the fast lane (§4.5) |
| traces to nothing | a question for the owner |

The triage file also gives the request one **route**: what plan writes, in which order — an
amendment before the delivery plan that depends on it, an ADR before the plan that cites it. The
triage classifies and routes; it never decides scope or design. That is plan's job, and the
owner's.

**Repo search.** The triage's code facts are the repo search the plan needs (`SDD-PLAN-01`): what
already exists for each seam a layer provides, every caller of what it changes, the tests around
it, and the conventions of each layer. They come back with `file:line`, and the Spec Writer cites
them in the index's starting point. A new layer from the review asks `repo-explorer` one question
about the failing branch itself, from plan; that is not a return to search (`SDD-FLOW-02`).

Then the Spec Writer runs each `AC-*` and each rule through seven edge categories, once
(`SDD-PLAN-08`):

| Category | The question that tends to slip through |
| --- | --- |
| boundary | is the value exactly at the limit in or out? minimum, maximum, zero, negatives, rounding? |
| time | counted from when? expires when, in which time zone? events out of order? |
| empty | empty list, missing optional field, first use? |
| repetition | the same action twice, two people at once? |
| permission | which role, which owner, which tenant, a visitor with no session? |
| failure | a dependency down, an operation stopped halfway: what does the person see, what is undone? |
| what already exists | data stored before the change, a client on the previous version, behavior someone depends on? |

Each edge that applies ends as a check in the layer that proves it, a line in the PRD's Out of
Scope through an amendment, or a gap for the owner. A guarantee the owner wants held — a database
that refuses a duplicate on its own, say — is written as a **Must hold** line, or the implementer
is free to meet it some other way. The sweep deepens the delivery, never widens it.

### 4.5 The fast lane

A fix or refactor of something already built — no product behavior changes — gets a delivery with
no PRD amendment (`SDD-PLAN-10`): the index and the layer files it touches, often one. Its checks
trace the existing `AC-*` they protect, or name the defect and the check that reproduces it. Repo
search still runs first.

---

## 5. The run

Two phases run this section. `workflow-implementation` starts layers and runs the implementer and
the gates: §5.1, steps 1–3 of §5.2, and the implementer's half of each fix round.
`workflow-review` runs the review, the verdict, the layer's delivery into the feature branch, the
validation of the whole delivery and the split: steps 4–5 of §5.2, §5.3 and §5.4. The state file
(§5.5) is the only thing that passes between them, and the fix-round counter lives in it
(`SDD-FLOW-03`).

### 5.1 When a layer starts

A layer starts as soon as all five hold, without waiting for any other layer (`SDD-RUN-01`):

1. the delivery is `Approved`;
2. every layer it depends on has merged into the feature branch;
3. it depends on no open gap;
4. its Surface shares no file with a running layer's Surface;
5. a slot is free within the **width** — the number of layers writing at once. † Default **4**,
   recorded by the project with its review budget.

### 5.2 One layer, end to end

1. `scripts/spawn-detached <delivery> <layer>` creates the feature branch from the trunk when it
   does not exist yet, then the layer's worktree and branch from the feature branch, runs
   `scripts/resolve-env` and `scripts/migrate-dev` inside it, and starts the implementer there
   (`SDD-RUN-02`). The orchestrator sets the layer's Status to `running`.
2. The implementer reads the index, its layer file, the **Provides** it links to and the ADR
   sections it cites; loads every skill its layer names before writing code; builds what the layer
   provides, holding to its rules; runs G1 and G2; and commits its own diff.
3. `scripts/run-gates <delivery> <layer>` runs G1, G2 and every level the layer's checks name. A
   failing gate goes back to the implementer **before** any review (`SDD-RUN-03`) and does not
   count as a fix round: the reviewer never spends a turn on code that does not build.
4. With the gates green, a new `code-reviewer` instance, independent of the author, receives the
   layer file, the diff against the feature branch and the gate summary, and nothing else
   (`SDD-RUN-04`). It answers one question: are this layer's checks met? It checks each check
   against the code and the tests, each **Must hold** against the diff, compares the diff's files
   with the Surface, and confirms the gates passed.
5. Checks met → push and PR into the feature branch, under the owner's authorization
   (`SDD-RUN-08`), then merge. The orchestrator sets the layer's Status to `merged` with the PR
   link, and every layer that depends on it re-checks §5.1.

### 5.3 When the review fails

| Round | Who runs it | What it receives |
| --- | --- | --- |
| fix 1 and fix 2 | the same implementer, resumed | only the failing checks and broken rules, verbatim from the review |
| re-review after each fix | a new `code-reviewer` instance | the failing checks, the fix diff since the last reviewed commit, the new gate summary |
| after fix 2 still fails | nobody fixes again | the Spec Writer writes a **new layer file**; the owner decides |

The cap is two fix rounds (`SDD-RUN-05`). There is no third round and no move to a higher tier:
a layer two rounds could not close has a plan problem, not a model problem.

**The new layer** (`SDD-RUN-06`) is a file `plans/<layer>.<n>-<slug>.md` and a new row in the
index. It holds the same checks that failed, starts from the failing branch, and only what the
layer could not get to. The owner approves it (it runs like any layer), or drops the layer. The
failed layer's state becomes `split`, pointing at the new one.

**What the reviewer may not do.** Its findings are the layer's checks and rules, and the files
outside the Surface. Anything else it notices goes under **Notes**, which do not fail the review.
Two exceptions block the merge without counting as a fix round: a security defect, and a
regression of a layer that already merged. Both go to the owner as a new layer before merge.

### 5.4 The delivery reaches the trunk

When every layer of the index is `merged` into the feature branch, `workflow-review` validates the
delivery:

1. `scripts/run-gates <delivery> --all` runs every level any layer names, on the feature branch.
2. A new `code-reviewer` instance receives `contract.md`, the layer files its rows point to, the
   diff of the feature branch against the trunk and that gate summary. It answers whether the
   contract is met: every `AC-*` row with all its checks green (`SDD-PLAN-07`).
3. Met → the delivery's pull request, `feat/<delivery>` into the trunk, its body listing every
   `AC-*` with the checks that proved it. It merges only on the owner's approval of that pull
   request (`SDD-RUN-08`). Unmet → the failing rows become a new layer, as in §5.3.

### 5.5 The state file

The orchestrator's whole view of a layer (`SDD-CORE-04`), at `.sdd/state/<delivery>/<layer>.md`:

```yaml
delivery: 2026-10-27-people
layer: L4b
status: waiting | running | gates-failed | in-review | fixing | checks-met | merged | split | dropped
branch: feat/2026-10-27-people-L4b
round: 0            # fix rounds used, at most 2
gates: pass | fail — <one-line summary from run-gates>
review: met | unmet — <the failing checks and rules, IDs only>
gaps: []            # open questions returned by the implementer, one sentence each
next: <the layer that replaces it, when status is split>
pr: <link, once opened>
authorization: <the owner's words, quoted>
started: <ISO 8601>
finished: <ISO 8601>
```

The index's Status column mirrors `status`, written by the orchestrator on the feature branch;
the state file keeps the runtime detail. `started` and `finished` exist so lead time per layer,
and the time a ready layer waited for a slot or for the owner, come from measured data.

### 5.6 Gaps during the run

A question the layer's files and skills do not answer is returned as a gap, in one sentence, and
the layer waits (`SDD-RUN-07`). The Spec Writer answers it as a new layer file — or, when it
changes what the product promises, the owner answers it through a PRD amendment. The implementer
never picks an answer and keeps going. The repo search, and the **Free to decide** field, exist
so this is rare.

### 5.7 Owner touchpoints

The owner answers at exactly these points, each in one message:

| Point | Question |
| --- | --- |
| PRD or amendment | approve, change, or reject? |
| delivery plan (index, layer files, contract, and its ADRs, as one message) | approve, change, or reject? |
| push and layer PRs | authorized for this delivery, once? Merging into the feature branch is covered only if said |
| new layer after two failed rounds, or a blocking note | approve the new layer, or drop the layer? |
| gap that changes the product | the answer, or accept it as an assumption with what would invalidate it |
| the delivery's PR into the trunk | approve the merge? |

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
| `scripts/migrate-dev` | applies migrations to the worktree's own development database | `init.sh`, the implementer when its layer needs it |
| `scripts/run-gates` | runs G1, G2 and the levels a layer's checks name, or every level of the delivery with `--all`, and reports pass or fail per level | the orchestrator, after each implement or fix; the review, before validating the delivery |
| `scripts/spawn-detached` | creates the feature branch when missing, the layer's worktree and branch from it, prepares it, starts the agent detached, records its pid | the orchestrator, once per layer |
| `scripts/stop` | stops one layer's detached run, or all of them | the orchestrator, a person |

Each worktree gets its own ports and its own database, so layers running side by side do not
collide on shared state (`SDD-SCR-03`). The commands each script runs — the install, the
migration tool, the gate per level, the agent CLI — come from one file, `sdd.config.sh`, so the
scripts stay the same across stacks.

---

## 7. Normative rules

Convention: `MUST`/`NEVER` are normative. **†** marks a decision of this doc.

### `SDD-CORE-*` — what holds across every step

| ID | Rule |
| --- | --- |
| `SDD-CORE-01` | The PRD **MUST** be the product's single source of truth: every capability and acceptance criterion **MUST** trace to it, and every layer's checks **MUST** trace to its acceptance criteria or to an ADR; work that traces to nothing **NEVER** enters a run. † |
| `SDD-CORE-02` | Product and delivery-plan decisions **MUST** be made once, before the run, by the high tier (`product-manager`, `spec-writer`); implementing, fixing and reviewing run on the mid tier, in fresh context, and **NEVER** decide product or plan. Every delegated step **MUST** go to a named agent called as a subagent, with its own model and effort; a generic agent, or a session told to act "as" a role, **NEVER** — both inherit the caller's model (Anthropic cookbook, plan big execute small; `CC-PAR-05`). |
| `SDD-CORE-03` | Every file in `.specs/` **MUST** be born `Draft` (an ADR `Proposed`) and change status only on the owner's explicit reply; one reply approves a whole delivery plan when it names it; the writer approving its own file, or silence counting as approval, **NEVER**. |
| `SDD-CORE-04` | The orchestrator **MUST** hold only one state file per running layer (§5.5) and the index's Status column; reading code, diffs, gate logs or review reports in the orchestrating session **NEVER** — that context is reread on every turn until the run ends. † |
| `SDD-CORE-05` | A mechanical operation — environment, migration, gates, spawning or stopping a run — **MUST** run through its harness script; an agent typing a gate's commands and reading their full output when a script exists **NEVER**. † |
| `SDD-CORE-06` | Registering work on a board **MUST** stay outside this flow; a step that writes to a tracker, or waits on one, **NEVER**. † |

### `SDD-PRD-*` — the PRD

| ID | Rule |
| --- | --- |
| `SDD-PRD-01` | The PRD **MUST** keep these sections, in order: Summary, Problem and Opportunity, Target Audience, Objectives, User Stories, Capabilities, Out of Scope, Traceability, Open gaps. † |
| `SDD-PRD-02` | Every capability **MUST** name the acceptance criteria it satisfies, and every acceptance criterion **MUST** belong to at least one capability; a capability with no criterion, or a criterion no capability holds, **NEVER**. † |
| `SDD-PRD-03` | Every acceptance criterion **MUST** carry a PRD-wide ID (`AC-NN`) and an observable outcome in Given / When / Then; a criterion with nothing to observe **NEVER** — no check can prove it (`DOC-PRD-02`). |
| `SDD-PRD-04` | The PRD **NEVER** carries a delivery cut — layers, order, waves, size, what one part provides another: that is the delivery plan's; a size problem found while planning **NEVER** comes back as an amendment. † |
| `SDD-PRD-05` | Every Problem and Opportunity item and every Objective **MUST** list the capabilities that address it, and every capability **MUST** appear under at least one; a capability traced to nothing, or a problem no capability addresses, **NEVER**. † |
| `SDD-PRD-06` | The PRD **NEVER** carries technical design (`DOC-PRD-03`); once `Approved` it **MUST** be frozen, and a change, including a new capability, enters as a dated amendment approved by the owner (`DOC-PRD-04`). |

### `SDD-PLAN-*` — the delivery plan

| ID | Rule |
| --- | --- |
| `SDD-PLAN-01` | Before a delivery plan is written, a repo search **MUST** have run through `repo-explorer` — what exists for each seam the layers provide, every caller of what they change, the tests and conventions around them — normally as the triage of `workflow-search` (§4.4), and the Spec Writer **MUST** cite the facts with `file:line`; a plan written from the PRD alone **NEVER**. † |
| `SDD-PLAN-02` | A PRD or amendment **MUST** be planned as one delivery in `.specs/delivery/<date>-<slug>/`: `plan.md` (the index), one `plans/<layer>-<slug>.md` per layer, and `contract.md`; a fact **MUST** live in one file — a shape in the **Provides** of the layer that defines it, a check in the layer that proves it — and the others link to it; copying it **NEVER** — the copy diverges. † |
| `SDD-PLAN-03` | The plan **MUST** read from the outside in — actors and doors, the vocabulary, then the layers: contracts and the test environment, repository, backend, frontend, tests, gates; a capability crosses the layers; a layer per capability **NEVER**. † |
| `SDD-PLAN-04` | A layer file **MUST** hold its goal, one owner, the exact names of the specialist skills that build it, the seams it consumes (as links) and provides (with a type-level shape), the rules it must hold (each with its `AC-*` or ADR source), what is free to decide, its checks, Surface, Size and Done when; ordered steps, file lists, regexes, function bodies or queries in a plan **NEVER** — the skill decides the inside. † |
| `SDD-PLAN-05` | A layer **MUST** fit the review budget (default: 300 changed lines, one review family, one owner); a larger layer is split inside the layer by capability, as more rows of the same plan; sending a size problem back to the PRD **NEVER**. † |
| `SDD-PLAN-06` | Every check **MUST** cite the `AC-*` or ADR rule it proves and the level that runs it at the cheapest point that catches the defect (`TS-CORE-02`), and live in the one layer that proves it; G1 (types and lint) and G2 (the whole test command) **MUST** hold on every layer's pull request from L1 on, with L1 setting up what they need, and G3 (security review) on every layer that touches authentication, authorization or sensitive data. † |
| `SDD-PLAN-07` | A contract is met **only** when every `AC-*` it traces has all its checks green on the feature branch, as `contract.md` maps them; green checks that cover no `AC-*` **NEVER** meet it, and an `AC-*` with no passing check **NEVER** does either. † |
| `SDD-PLAN-08` | The Spec Writer **MUST** run each `AC-*` and rule through the seven edge categories of §4.4 once, and each edge that applies **MUST** end as a check, an Out of Scope line through a PRD amendment, or a gap for the owner; the implementer re-deriving the sweep **NEVER** (Myers, boundary value analysis; Wynne, Example Mapping). |
| `SDD-PLAN-09` | A merged layer's file is **NEVER** rewritten; a later change, a failed layer or a gap **MUST** become a new layer file with its own row in the index, written by the Spec Writer and approved by the owner. † |
| `SDD-PLAN-10` | A fix or refactor that changes no product behavior **MUST** take the fast lane: a delivery with no PRD amendment, holding only the layers it touches, its checks tracing the `AC-*` they protect or reproducing the defect; opening a PRD amendment for it **NEVER** (`DOC-CORE-02`). † |
| `SDD-PLAN-11` | After `Approved`, only the index's Status and PR cells **MUST** change, and only the orchestrator **MUST** write them, on the feature branch; a layer run or a reviewer editing the index **NEVER** — two layers running at once would conflict on it. † |

### `SDD-RUN-*` — the run

| ID | Rule |
| --- | --- |
| `SDD-RUN-01` | A layer **MUST** start as soon as the delivery is approved, every layer it depends on has merged into the feature branch, it depends on no open gap, its Surface shares no file with a running layer, and a slot is free within the width (default 4); running ready layers one at a time with no stated reason **NEVER**, and starting a layer before the seams it consumes have merged **NEVER**. † |
| `SDD-RUN-02` | Each layer **MUST** run in its own worktree on `feat/<delivery>-<layer>`, cut from the feature branch by `scripts/spawn-detached`; its implementer **MUST** read only the index, its layer file, the **Provides** it links to and the ADR sections it cites, and **MUST** load every skill its layer names before writing code; reading the whole PRD or another layer's checks **NEVER**. † |
| `SDD-RUN-03` | `scripts/run-gates` **MUST** run before every review; a failing gate goes back to the implementer without a review and without counting as a fix round. † |
| `SDD-RUN-04` | A layer's review **MUST** run in a new instance independent of the author, receiving only the layer file, the diff against the feature branch and the gate summary, and **MUST** decide one thing: whether the layer's checks and rules are met; a finding outside them and the Surface is a non-blocking note, except a security defect or a regression of a merged layer, which block the merge and go to the owner as a new layer (Google SWE practices; `CC-SES-07`, `CC-SES-10`). |
| `SDD-RUN-05` | A failed review **MUST** get at most two fix rounds, each run by the same implementer resumed with only the failing checks, each followed by a delta re-review in a new instance; a third round, or moving the fix to a higher tier, **NEVER**. † |
| `SDD-RUN-06` | A layer still failing after two fix rounds **MUST** stop: the Spec Writer writes a new layer file from the failing checks, starting from the failing branch, and the owner approves it or drops the layer; reopening the PRD or the merged files instead **NEVER**. † |
| `SDD-RUN-07` | A question the layer's files and skills do not answer **MUST** be returned as a gap in one sentence while the layer waits; it closes as a new layer file, or as a PRD amendment when it changes what the product promises; the implementer choosing an answer and continuing **NEVER** (Wynne, Example Mapping). |
| `SDD-RUN-08` | A layer **MUST** merge only into the delivery's feature branch, with its checks met; the delivery **MUST** reach the trunk only through one pull request from the feature branch, after every layer merged, the gates passed there and a final review found the contract met, and only on the owner's approval; a layer merged into the trunk directly, or authorization to push covering a merge the owner did not name, **NEVER**. † |

### `SDD-SCR-*` — the harness scripts

| ID | Rule |
| --- | --- |
| `SDD-SCR-01` | The six global scripts — `init.sh`, `scripts/resolve-env`, `scripts/migrate-dev`, `scripts/run-gates`, `scripts/spawn-detached`, `scripts/stop` — **MUST** live at the root of the consuming project and read their commands from `sdd.config.sh`; a global script per layer or per delivery **NEVER**. † |
| `SDD-SCR-02` | Every script **MUST** be idempotent and non-interactive, exit `0` on success and non-zero on failure, print at most a short summary and write its full output to `.sdd/logs/`; a script that prompts, or that dumps its full log into the caller's context, **NEVER**. † |
| `SDD-SCR-03` | Each worktree **MUST** get its own ports and its own development database from `scripts/resolve-env`; two running layers sharing one database or port **NEVER**. † |

### `SDD-FLOW-*` — the phases

| ID | Rule |
| --- | --- |
| `SDD-FLOW-01` | The flow **MUST** run as four phases, in order — search, plan, implementation, review — each entering on its written condition and leaving with its named artifact (§2); a phase starting without its entry condition **NEVER**. † |
| `SDD-FLOW-02` | The flow **MUST** only move forward: the review may send a layer back to implementation for a fix round (`SDD-RUN-05`) or on to plan as a new layer (`SDD-RUN-06`), and nothing else goes back; a failure re-entering search, or reopening a closed triage, PRD section or merged layer file, **NEVER**. † |
| `SDD-FLOW-03` | The state file **MUST** be the only handoff between implementation and review, and the fix-round counter **MUST** live in it; passing a diff, a log or a review report between the two phases **NEVER** (`SDD-CORE-04`). † |
| `SDD-FLOW-04` | The main session **MUST** load one phase skill at a time, and each phase **MUST** hand its work to named agents or scripts; a phase loading another phase as a sub-orchestrator **NEVER** — two orchestrators reread on every turn. † |
| `SDD-FLOW-05` | Search **MUST** split the request into slices on five axes — product, frontend, backend, tooling, stack — and give each slice a verdict and a next step (§4.4); search deciding scope or design **NEVER**: it classifies and routes, and plan decides. † |
| `SDD-FLOW-06` | Search **MUST** stay internal and short: the record before the code, a slice the record answers never sent to the code, one question per open slice in a single round; a second search round, or an external source such as a web page or library documentation, **NEVER**. † |

### Count

**40 rules** in six families, a single file.

| Family | Rules |
| --- | --- |
| `SDD-CORE-*` | 6 |
| `SDD-PRD-*` | 6 |
| `SDD-PLAN-*` | 11 |
| `SDD-RUN-*` | 8 |
| `SDD-SCR-*` | 3 |
| `SDD-FLOW-*` | 6 |

---

## 8. Skill contract

### What to load

```
WHEN TRIAGING a request (workflow-search):              § 4.4 "Triage" + SDD-FLOW-05, SDD-FLOW-06
WHEN WRITING or AMENDING the PRD (workflow-plan):       § 4.2 + SDD-CORE-01, SDD-CORE-03, SDD-PRD-*
WHEN WRITING a delivery or a new layer (workflow-plan): § 4.3, § 4.4, § 4.5 + SDD-PLAN-*
WHEN RUNNING layers (workflow-implementation):          § 3, § 5.1, § 5.2 + SDD-CORE-04, SDD-CORE-05, SDD-PLAN-11, SDD-RUN-01–03, SDD-RUN-07
WHEN REVIEWING and DELIVERING (workflow-review):        § 4.3 "The checks", § 5.2–§ 5.4 + SDD-PLAN-07, SDD-RUN-04–08
WHEN MOVING between phases:                             § 2 + SDD-FLOW-01–04
WHEN SCAFFOLDING the scripts:                           § 6 + SDD-SCR-*
NEVER:                                                  this whole doc inside an implementer or a reviewer;
                                                        each one gets its layer's files and the rule IDs its skill cites
```

### How to cite

> `SDD-PLAN-07` — the final review finds every layer merged and green, but `AC-05` ("an expired
> invite returns 410") maps to C12 in L3c, and C12 has no test. The contract is not met: an
> `AC-*` with no passing check never meets it. The row becomes a new layer, `L3c.1`.
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
| What to build and why | decide it in the plan or the code | `product-manager`, via `doc-prd` |
| A boundary decision that outlives the delivery | bury it in one layer file | `software-architect`, via `doc-adr` |
| How a layer is built inside | write it as steps in the plan | the specialist skills the layer names (`drizzle-*`, `elysia-*`, `tanstack-*`, `react-*`, `bun-test-build`, `playwright-build`) |
| Which test level proves a check | leave it for the implementer | the level on the check, chosen by `TS-CORE-02`; `test-design` when it is not obvious |
| The HTTP contract of a provided route | invent status and shape in the handler | `http-contract`, cited from the layer's **Provides** |
| Code quality beyond the checks | turn every review into a full audit | the family review skills, run on request or as a gate a layer names |
| A security finding | fix it inside the round and move on | `devops-security`, and a new layer before merge (`SDD-RUN-04`) |
| Board items | create them inside the flow | outside this flow (`SDD-CORE-06`) |

---

## Sources consulted

- Anthropic, *Claude Cookbooks* — `managed_agents/CMA_plan_big_execute_small.ipynb`: a frontier
  orchestrator plans and synthesizes and never reads raw material; cheaper workers execute in
  their own contexts and return distilled results; delegation has a floor cost, so more and
  narrower briefs raised the bill; and the verification standard only covers what is put in it.
  Basis for `SDD-CORE-02`, the review budget's lower bound (§4.3 "Size") and the gates on every
  layer (`SDD-PLAN-06`). Consulted on 2026-10-25.
- Glenford Myers, *The Art of Software Testing* — boundary value analysis; the "boundary"
  category of the edge sweep (`SDD-PLAN-08`). Consulted through chapter summaries.
- Matt Wynne, *Introducing Example Mapping* (Cucumber blog) — the question nobody can answer
  becomes a card instead of a guess; basis for `SDD-RUN-07`.
- Winters, Manshreck, Wright, *Software Engineering at Google* — review by a peer independent of
  the author (`SDD-RUN-04`).
- **Internal precedent, not external authority:** the owner's SDD draft and decisions of
  2026-10-25 — PRD as single source of truth; the implement → review → fixer → review loop; the
  six scripts; repo search before writing; a failed contract becoming a new item; two fix rounds;
  ADRs kept; board registration out of the flow; and a contract met only when it proves its
  acceptance criteria met.
- **Internal precedent, not external authority:** the owner's decisions of 2026-10-26 — four
  phase skills in `skills/workflow/` (search, plan, implementation, review); search as an internal
  triage on five axes, with no external source and no long search.
- **Internal precedent, not external authority:** the owner's decisions of 2026-10-27, from the
  users-crud test round — the delivery planned once, in layers, from the outside in, deciding the
  seams and leaving the inside to the specialist skills; gates on every layer; the planner given
  the real skill list and the implementer told to load it; the plan split into an index that
  keeps progress and one file per layer; each layer's pull request into the delivery's feature
  branch, and only the validated delivery into the trunk. Measured there: planning the same PRD
  cost ≈ $29 and three amendments without finishing when cut per capability, and $2.50 (one file)
  or $4.16 (index and layer files) when layered, with every hidden oracle passed in both
  implementations; reading only the index and the layer file cut a layer run's input by 37% and
  its cost by 26%.

**What could not be verified against a primary source in this version:** the cookbook was read
in full; the books were not reread on this date. The 2026-10-27 measurements come from two to
three runs per scenario. Rules marked † are this project's decisions.

---

## Related

- `skills/workflow/` — `workflow-search`, `workflow-plan`, `workflow-implementation`,
  `workflow-review`: the four phases this doc is the foundation of
- `agents/README.md` — the roles this flow calls, and the tier each runs on
- `skills/design-docs/` — `doc-prd` and `doc-adr`, among the document writers
- `commands/spec.md` and `commands/scaffold-sdd-scripts.md` — search and plan, then stop; and the
  harness scripts

In the knowledge base, cited by name: `Decision Documents — PRD, RFC and ADR` (what the PRD and
the ADR are, and when each freezes); `Teste de Software` §4.1 (the cheapest level that catches the
defect, behind each check's level); `Claude Code - Paralelismo e Escala` (subagents, worktrees,
and why a session opened by another inherits its model); `Claude Code - Sessão e Verificação`
(`CC-SES-07`, `CC-SES-10`: review in fresh context, with a bounded criterion); `Trunk-based
development` (small batches, behind the review budget).
