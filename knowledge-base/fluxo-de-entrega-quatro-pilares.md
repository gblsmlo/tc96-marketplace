---
titulo: Delivery Flow — Four Pillars
tags:
  - workflow
  - delivery
  - agent-context
  - reference
source: "Barry Boehm, Software Engineering Economics (cost-of-change curve, origin of verification×validation); Marty Cagan, Inspired: How to Create Tech Products Customers Love; Teresa Torres, Continuous Discovery Habits; Ryan Singer/Basecamp, Shape Up: Stop Running in Circles; Kent Beck, Extreme Programming Explained; Winters/Manshreck/Wright, Software Engineering at Google (code review culture — already cited in TS-*); Forsgren/Humble/Kim, Accelerate (DORA metrics); Glenford Myers, The Art of Software Testing (equivalence partitioning and boundary value analysis); Matt Wynne, Introducing Example Mapping (Cucumber); internal precedent: lemind, ADR 114 — \"the agent workflow has four pillars\" (implementation observed in production, not academic authority)"
verificado-em: 2026-09-23
---
# Delivery Flow — Four Pillars

> **What this note is.** The **procedure layer over the eleven agents**: the moment a task
> is in — research, planning, implementation or validation — kept separate from **who**
> carries it out. It is what decides which agent or skill a task goes to next, when that is
> not yet obvious from the request.
>
> **What it is not.** It does not replace any of the eleven agents nor redefine what each one
> does. It is not a fifth agent. It is the formalization, with citable rules, of the flowchart
> that already existed implicitly in `agents/README.md` ("How agents hand off") — which
> remains the source of the *who*; this note is the source of the *when*.
>
> **Why it exists.** The project had eleven roles and an informal mermaid diagram of how the
> baton passes from one to another, but no citable rule for deciding, in the middle of a task,
> whether what is missing is a decision (go back), execution (move on) or proof (evidence
> before closing). Without this layer, the tendency is to jump straight to "writing code" with
> a product decision still open — the equivalent, in this domain, of the anti-pattern that
> [Teste de Software](teste-de-software.md) describes for test levels: skipping the concept
> layer and going straight to the tool.

Sources consulted on **2026-09-23**; Myers and Wynne, added with the edge sweep (§4.1), on
**2026-10-10**. See [Sources consulted](#sources-consulted).

---

## 0. Before anything else: four distinctions that settle the conversation

**1. Pillar × role.** A *pillar* is the moment of the work — research, planning,
implementation or validation. A *role* is who carries it out — one of the eleven agents in
`agents/README.md`. The two axes are **orthogonal**: the same `software-architect` appears in
the Research pillar (deciding whether a change is architectural) and in Planning (naming a
unit's boundary); the same `qa-engineer` appears in Implementation (the test's level) and in
Validation (running the suite). Reducing an agent to a single pillar is the most common
mistake when adopting this model (`WF-CORE-02`).

**2. Research × continuous discovery.** Research, here, is not a lengthy report commissioned
once a quarter — it is the smallest investigation that resolves the decision blocking the next
pillar, repeated as many times as a task needs (Torres, *Continuous Discovery Habits*). A
research effort that returns more questions than the decision it was asked for has not
finished.

**3. Verification × validation.** Already recorded in [Teste de Software](teste-de-software.md)
§0, and worth repeating at the level of the whole flow, not just of testing: verification asks
"did we build it right?" (contract, behavior, rule); validation asks "did we build the right
thing?" (business acceptance). This note's Validation pillar covers the **first** question —
it is technical verification. The second question is the responsibility of the
`product-manager` and happens **after** technical closure, never blocking it (`WF-VAL-03`).

**4. Pillar × board level.** A *board level* is the granularity at which a decision becomes
trackable work — Epic (permanent capability), Story (unit of acceptance) or Task (executable
slice), defined in `workflow-spec/references/template-{epic,story,task}.md`. Research (the
continuous discovery of item 2) **never** produces a board item directly: it produces the
minimum decision that authorizes Planning to open one. It is in Planning, through the
decomposition and boundary gates (§4.2, `WF-PLAN-03`, `WF-PLAN-05`), that the
Epic → Story → Task tree is born. Opening the Epic in the tracker as soon as someone has an
idea is the mirror mistake of `WF-CORE-03`: instead of skipping Research, it pretends Research
has already finished. Full table in §3. †

---

## 1. How to use this doc

### For a person

Before asking an agent to "implement X", ask: is something still undecided about **what** to
do (→ Research pillar), about **how to split it and when** (→ Planning), or is everything
already decided and it is time to **write** (→ Implementation)? If the code already exists and
the question is "is this right", go straight to `code-reviewer` — Validation is already its
pillar.

### For a coding agent

On receiving an ambiguous task, classify the pillar **before** choosing the next skill or
agent (§2). A task that arrives asking for implementation but carries an unresolved product
decision **is not** an implementation task yet — it is a Research task in disguise
(`WF-CORE-03`).

### Conventions

`MUST`/`NEVER` are normative, as in the rest of the knowledge-base. **†** marks a decision of
this doc — with no direct parallel in a single external source, but needed for the model to
work in this project.

---

## 2. Mental model

| # | Pillar | Enters when | Leaves with |
| --- | --- | --- | --- |
| 1 | **Research** | the problem, the expected behavior or a lasting decision is not clear | minimum decision resolved, with its edges swept (§4.1); evidence, risks, sources; gaps with who decides them and where they close (§5) |
| 2 | **Planning** | the decision was accepted but the work is not executable yet | bounded work unit(s), dependencies, perfil, acceptance criteria, evidence plan with the test types |
| 3 | **Implementation** | the unit is ready and the behavior has already been decided | changed code or note, focused test, implementation evidence |
| 4 | **Validation** | a change or delivery exists and needs proof | focused and repository checks, review findings, a clear result |

No task skips a pillar (`WF-CORE-03`): it can **go back** a pillar when it discovers a gap, but
it never decides "I'll just sort this out in implementation" when the gap belongs to research.
Every gap states who decides it and in which pillar it closes (§5, `WF-CORE-09`), and that
pillar is never Implementation.

---

## 3. Where each pillar routes

| Pillar | Skill | Agent(s) that carry it out, today | Board level |
| --- | --- | --- | --- |
| Research | `workflow-research` | `product-manager` · `product-designer` · `software-architect`; gathering facts from the code: `repo-explorer` | — no item yet; leaves with the decision that authorizes one (§0.4) |
| Planning | `workflow-planning` | `project-manager` · `software-architect` | opens and decomposes Epic → Story → Task (`template-epic.md` · `template-story.md` · `template-task.md`) |
| Implementation | `workflow-implementation` | `frontend-developer` · `backend-developer` | executes one Task at a time — the only level the implementer reads (`WF-IMPL-03`) |
| Validation | `workflow-validation` | `qa-engineer` · `code-reviewer` · `devops-security` (when the finding is about security) | reviews the PR (`template-pr.md`), with a one-way link back to the Task/Story |

The agents column is also the closed list of who can receive a delegated pillar
(`WF-CORE-06`): each one declares `modelo` and `esforco` in its own frontmatter, and that is
what keeps the pillar from running on the session's model — as long as the agent is called as
a subagent. A new session adopts no agent at all: it inherits the model of whoever opened it,
and the role only reaches it if it calls that role (§3.1). `repo-operator` does not receive a
pillar: it receives the mechanical operations of any of them (§3.1, `WF-CORE-08`).

This mapping is the same flowchart as in `agents/README.md`, section "How agents hand off" —
here only as a table, without repeating the mermaid. When a new agent is added there, this
table is what needs updating, not the other way around.

The board level column is the whole "discover → task" path, end to end: Research resolves the
decision (the `product-manager` calls this Discovery); Planning is where that decision first
becomes a board item, decomposes into Stories and is sliced into Tasks, always through the
five gates (§4.2); Implementation executes exactly one Task at a time; Validation reviews the
PR that references that Task. No pillar writes at two board levels at once, and no level is
born outside the pillar that produces it — opening a Task directly, with no Story and no Epic,
is decomposition without criteria (`WF-PLAN-03`), just as opening an Epic with no Research
decision behind it is moving forward without a resolved decision (`WF-CORE-03`).

### 3.1 Model per point of the flow

The tier follows the operation, not the pillar. Within a single pillar there is **decision**,
which stays on the owning agent's tier, and **mechanical operation**, whose content an
artifact has already decided and which goes to the cheapest tier (`WF-CORE-08`).
`repo-operator` crosses all four pillars doing the latter; the tier-to-model map for each
provider is in `agents/README.md`, "Model and effort per role".

| Pillar | Point | Who executes | `modelo` · `esforco` | Why |
| --- | --- | --- | --- | --- |
| Research | read the code and gather facts | `repo-explorer` | rapido · baixo | every fact carries the `file:line` that proves it |
| Research | classify the scope and decide | `product-manager` · `software-architect` | alto · alto | ambiguous, few tokens, nothing checks it afterwards |
| Research | write `requirements.md` | `product-manager`, via `workflow-spec` | alto · alto | the file is the decision itself |
| Planning | `design.md` and ADRs | `software-architect` | alto · alto | the boundary decides the cost of everything that follows, including the tests (§4.2) |
| Planning | `user-experience.md` | `product-designer` | medio · alto | structured, but open |
| Planning | gates, the `tasks/` plan and the text of the board items | `project-manager` | medio · medio | template-driven |
| Planning | publish to the board the text the plan already carries | `repo-operator` | rapido · baixo | literal copy; asks for the owner's reply |
| Implementation | code and focused test | `frontend-developer` · `backend-developer` | medio · medio | more tokens; Validation catches the error |
| Implementation | commit of its own diff | the same implementer | medio · medio | the diff is already in its context; rereading it in another agent costs more |
| Validation | run the plan's checks and report | `repo-operator` | rapido · baixo | long output; the result is the exit code |
| Validation | review the diff | `code-reviewer` | medio · alto | it is the verification; nobody reviews it |
| Validation | diagnose a check that failed | `qa-engineer` | medio · medio | judgment about the suite |
| Validation | security finding | `devops-security` | alto · alto | a missed finding costs more than the tokens |
| Validation | PR body, push, open the PR | `repo-operator` | rapido · baixo | template filled from the envelope; push and PR ask for the owner's reply |
| any | copy, move, rename, organize a folder | `repo-operator`, or whoever already has the command ready | rapido · baixo | the list or the layout has already been decided |
| any | delete, overwrite, build and release | `repo-operator` | rapido · baixo | deleting, overwriting and publishing ask for the owner's reply |
| any | orchestrate: envelopes, routing, talking to the owner | the main session | the person's choice | a plugin does not pin the session's model; the recommendation is in `agents/README.md` |
| any | open a new session for a unit | the orchestrating session | medio · medio, passed at opening | the new session inherits the model of whoever opens it and does not adopt the owner; it orchestrates the unit, and the owner runs inside it as a subagent, on its own tier (`CC-PAR-05`) |

**When to delegate a mechanical operation.** A subagent starts with its own system prompt,
tools and cache, and its answer goes back to whoever called it. For a single command, that
costs more than running the command:

```
Does the operation require deciding something no artifact has decided?
├── yes → it is not mechanical: back to the decision's owner
└── no
    Is the content it needs already in the context of a medio or rapido agent at work?
    ├── yes → that agent executes it (the implementer commits its own diff)
    └── no
        Is it a single, already-known command, with nothing to read first?
        ├── yes → run it where you are, including in the orchestrating session
        └── no → repo-operator (rapido · baixo)
```

**When parallelism is per session.** Opening one session per unit (the desktop app's
`start_session`) swaps the subagent for something the person sees and talks to, but the tier
does not come along ([`CC-PAR-05`](claude-code-paralelismo-e-escala.md)). Whoever opens it:

1. passes explicit `modelo` and `esforco`, at the orchestration tier (medio · medio; the value
   per provider is in `agents/README.md`), in a `fresh` opening — a fork inherits the model;
2. writes the brief so the session **calls** the owner as a subagent and takes care only of
   the envelope, Validation and the PR — "run as `backend-developer`" makes the session write
   the code on the model it inherited, without the agent's body.

A session only opens another at the same tier or below; when the owner is `alto`, what moves
up is the subagent, through its frontmatter.

The orchestrating session is the flow's largest expense: its context is reread on every turn
until the end (`WF-CORE-07`). Reading a diff, a template or a test output there, on the most
expensive tier, is exactly what `WF-CORE-08` forbids.

---

## 4. Decision trees

### 4.1 Research — classify the scope

```
1. Does the change alter what the product does or promises?
   └── yes → PRODUCT scope → product-manager decides, product-designer designs the flow
2. Does it move where a responsibility lives, or introduce a new service boundary?
   └── yes → ARCHITECTURE scope → software-architect decides
3. Is the expected behavior already decided and written down?
   (spec, ADR, test, contract, accepted ticket)
   ├── no  → PRODUCT scope: an undecided rule in disguise → product-manager decides
   └── yes → EXECUTION scope → go straight to workflow-planning, citing where the rule is written
```

Execution is defined by what it keeps, not by how small it is: the rule is already decided and
written down, and the change alters only how it is carried out.

| Subtype | When | Evidence planning requires |
| --- | --- | --- |
| **fix** | the code diverges from the written rule (a bug) | the rule, cited, and a case that fails today |
| **refactor** | same behavior, structure changes inside the same boundary | the existing tests still pass, unchanged |
| **technical adjustment** | performance, dependency, configuration — same promise, same boundaries | a before/after measurement, or a check of the adjustment |

`WF-RES-05`. The most expensive misclassification is treating a product change as execution —
it reaches Implementation ready-made without anyone having decided whether the product should
change at all. Question 3 is the guard: execution that cannot point at where its rule is
written is product.

#### Sweeping the decision's edges

Classifying the scope says **who** decides; the sweep says whether the decision is
**complete**. The question that stops a unit in the middle of the code is rarely the main
rule — it is the rule's edge: the value exactly at the limit, the deadline counted from when,
the empty list, the repeated click. Before the handoff, whoever decides runs each rule and
each acceptance scenario of the decision through the seven categories (`WF-RES-06`):

| Category | The question that tends to slip through |
| --- | --- |
| boundary | is the value exactly at the limit in or out (`>` or `>=`)? what are the minimum, the maximum, zero, negatives, rounding? |
| time | counted from when? expires when, in which time zone? and what if events arrive out of order? |
| empty | what about the empty list, the missing optional field, first use, nothing registered yet? |
| repetition | what about the same action twice (double click, retry)? and two people at the same time? |
| permission | who can — which role, which resource owner, which tenant, which visitor with no session? |
| failure | what if a dependency goes down, or the operation stops halfway? what does the person see, what is undone? |
| what already exists | what about data stored before the change, the client on the previous version, the current behavior someone depends on? |

Each edge that applies leaves Research with one of three destinations, and every gap carries
who decides it and where it closes (§5, `WF-CORE-09`). A category that does not apply leaves
no trace.

| Destination | Product scope | Architecture and execution |
| --- | --- | --- |
| **answered**, with a source | acceptance scenario in the `requirements.md` story | a line in `decisoes`, which Planning carries into the unit's acceptance criteria |
| **out** | non-goal in `requirements.md` | a line in `decisoes`: "out of this increment: …" |
| **gap** | "Open gaps" in `requirements.md`; in the envelope, when it closes in Planning | in the envelope |

The sweep **deepens** the decision, never **widens** it (`WF-RES-03`): an edge that calls for
a new decision, outside what was asked, becomes a non-goal or a gap — not extra research. It
also tests the classification above: in an execution scope, an edge that applies and whose
answer is written nowhere shows that the scope was product (`WF-RES-05`).

### 4.2 Planning — the gates

A unit is only ready for Implementation after passing all of them:

1. **Product gate** — if the change alters `.specs/**` or equivalent, is there approved
   behavior behind it (`requirements.md` in `Approved`, `design.md` in `Accepted`, or an ADR)?
   Without it, it goes back to `workflow-research`.
2. **Decomposition gate** — only split into more than one unit if each has its own acceptance
   criteria, evidence and dependency (`WF-PLAN-03`). Splitting for the writer's convenience,
   not along those boundaries, is cost fragmentation.
3. **Boundary gate** — which perfil (`frontend-developer`, `backend-developer`,
   `devops-security`...) owns each unit? "Fullstack" is never an answer (`WF-PLAN-05`).
4. **Appetite gate** — how much it is worth spending here, decided **before** asking how long
   it will take (`WF-PLAN-01`, Shape Up). A unit that blows its appetite stops and goes back to
   the decision table — it does not silently stretch the deadline (`WF-PLAN-02`, circuit
   breaker).
5. **Acceptance gate** — acceptance criteria written, not implicit (`WF-PLAN-04`), with one
   line for each edge Research answered for this unit (`WF-RES-06`). An open gap the unit
   depends on is a line nobody has written yet: the unit waits for the answer (`WF-CORE-09`).

#### Evidence plan: which test Validation will run, and what it costs

Once past the gates, each unit names the test types that will prove it, and Validation
inherits that list instead of inventing another (`WF-PLAN-06`). The level follows
[Teste de Software](teste-de-software.md) §4.1: each assertion at the cheapest layer that still
catches the defect (`TS-CORE-02`). For an agent, the cost comes in two currencies, and both
repeat on every fix round:

| Type | Catches | Execution time | Agent tokens (write, run, read the output, diagnose) | Needs running |
| --- | --- | --- | --- | --- |
| static (types, lint) | type error, import, lint rule | low | low: nothing to write, short output | nothing |
| unit | rule, calculation, parsing, domain invariant | low | low | nothing |
| contract | the shape of what crosses a boundary | low | low to medium: a schema, or one `curl` per route | the server, in the `curl` case |
| integration | my pieces talking to a real dependency | medium | medium: data setup, larger output | local database or service |
| component (story with `play`) | a component's visual state and interaction | medium | medium: story, `play` and render | Storybook |
| E2E | the critical journey end to end | high | high: app and browser up, session, trace and DOM read on every failure, reruns for flakiness | app, browser and session |
| manual | what no check automates | — | — (it is a person's time) | person, date and environment recorded |

The values are relative order, not measurement: each project measures its own. What the table
fixes is the direction. An assertion that moves up from unit to E2E trades seconds for minutes
and a short output for an entire trace read by the agent, on every round.

**What fixes this cost is the boundary, before the test.** When choosing where a rule lives,
the `software-architect` also chooses the cheapest test able to prove it: a rule in the backend
is proved with a unit test and a `curl`; the same rule spread across the interface can only be
proved with E2E. That is why each verifiable invariant in `design.md` and in an ADR names the
test type that proves it, and an invariant only an E2E can prove says why.

### 4.3 Implementation — when to stop and return

**Before the first line, the implementer's questions** (`WF-IMPL-06`). The agent that owns the
unit reads the Task and the code it touches and lists what it would need to know to write it,
running the unit through the seven edge categories of §4.1. Each question leaves in one of
three ways: answered by an accepted artifact, which it cites; decided right there, when the
answer stays within what the unit has already decided (a name, the local structure, a
library's API); or returned through the table below, before any code, as a gap with who
decides it and where it closes (§5, `WF-CORE-09`). The list stays in the implementer's context;
only the gaps reach the orchestrator (`WF-CORE-07`).

The table applies before and during the code. Before, the return costs only the return;
during, it also costs the code already written on top of an invented answer.

| Situation found before or during implementation | Goes back to |
| --- | --- |
| product behavior missing or contradictory | `workflow-research` (`fecha-em: pesquisa`) |
| insufficient scope, dependency or evidence in the unit | `workflow-planning` (`fecha-em: planejamento`) |
| local defect, within what this unit itself has already decided | fix it right here, record evidence (`WF-IMPL-05`) — not a return |

`WF-IMPL-01`: implementation never reopens a product decision on its own — even when the
fastest path would seem to be deciding it right there.

### 4.4 Validation — proportionality of evidence

Evidence is a **decision about risk**, not a synonym for "run everything" (`WF-VAL-02`):

```
Does the change alter a public contract (API, schema, route)?
├── yes → contract checks + independent review required
└── no
    Does the change touch an authentication, authorization or sensitive-data path?
    ├── yes → security checks + independent review required (route the finding to devops-security)
    └── no → focused checks on what changed are enough; state what was not covered, do not hide it
```

Validation starts from the test types the plan named (`WF-PLAN-06`). A more expensive type the
plan did not foresee only comes in with the sentence saying what it catches that the cheaper
ones do not; without that sentence, the gap belongs to the plan and goes back to Planning
(`WF-VAL-04`).

---

## 5. The handoff envelope

Every skill of this pillar returns the same format, so the next pillar (or person) does not
need to reconstruct what has already been decided:

```yaml
pilar: "pesquisa | planejamento | implementacao | validacao"
resultado: one sentence with the outcome
artefato: "<file in .specs/, board item, commit or PR where the full output lives>"
evidencia: [E1, E2]
decisoes: [D1]
lacunas:
  - pergunta: G1, in one sentence
    decide: "<agent from §3 | dono>"
    fecha-em: "pesquisa | planejamento"
proximo: "workflow-research | workflow-planning | workflow-implementation | workflow-validation | <agent>"
```

`proximo` is the transition field — it is what points to where the baton goes, and it is
always accompanied by an artifact (`WF-CORE-01`), never by a mere statement of intent.

`artefato` is the reference, not the content. The pillar's full output lives outside the
conversation; whoever orchestrates keeps only the envelope, which fits in 30 lines
(`WF-CORE-07`). A whole report returned to the main conversation is reread and charged on
every following turn, by every pillar that comes after.

### Gaps: who decides and where they close

A gap is the question whose answer belongs to another owner, not to whoever holds the baton;
what the implementer decides within their own unit is not a gap. Each item in `lacunas`
carries two fields besides the question (`WF-CORE-09`):

- `decide` — the §3 agent that owns that decision (`product-manager`, `product-designer`,
  `software-architect`, `project-manager`), or `dono`, when only the person can answer.
- `fecha-em` — the last pillar in which it can still be open:

| `fecha-em` | When | What it blocks |
| --- | --- | --- |
| `pesquisa` | the answer changes what the product does or promises, or what goes into the increment | all of Planning: it does not start |
| `planejamento` | the answer only changes how the unit is designed, split or proved — flow and screen states, boundary and contract, dependency and order | only the units that depend on it: none passes the acceptance gate (§4.2) |

`implementacao` and `validacao` are never values of `fecha-em`: a decision gap does not close
in the code (`WF-CORE-03`, `WF-IMPL-01`). The pillar that runs into a gap along the way —
Implementation through §4.3, Validation through `WF-VAL-04` — returns it with both fields
already filled in.

The `fecha-em` pillar does not hand on what depends on the gap before the answer: Research
hands on nothing with an open `pesquisa` gap; Planning does not hand on a unit that depends on
an open gap. Whoever answers is whoever `decide` names — a §3 agent, started on the spot
(`WF-CORE-06`), or the owner, asked in one sentence.

The file awaiting the owner's reply is the most common gap:
`pergunta: "awaiting owner approval: <path>"`, `decide: dono`, and `fecha-em` the pillar that
writes the file — `pesquisa` for `requirements.md`, `planejamento` for the others
(`WF-SPEC-04`).

**With no answer in time, the only way out is to become an assumption.** The gap only moves
forward if the owner explicitly accepts it in the conversation as an assumption, along with
what would invalidate it (`WF-SPEC-06`). It leaves `lacunas`, enters `decisoes` and is written
down in the artifact: under "Constraints and assumptions" in `requirements.md`, or in the plan
in `tasks/`. An assumption invalidated during Implementation is the first row of the §4.3
table: it goes back to Research.

### Where the artifact lives: `.specs/`

The output of Research and Planning is stored in the project, in `.specs/`, and the
envelope's `artefato` points to the path (`WF-SPEC-01`):

```
.specs/
├── adr/
│   └── NNNN-<slug>.md            software-architect · never edited, only superseded
└── <capability>/
    ├── requirements.md           Research · product-manager (the capability's PRD)
    ├── design.md                 Planning · software-architect (RFC or design doc)
    ├── user-experience.md        Planning · product-designer (UX, UI, usability, accessibility)
    └── tasks/
        └── NNNN-<slug>.md        Planning · project-manager (the plan of one increment)
```

**One folder per capability, not per delivery.** The capability is permanent, like the Epic
that represents it (§0.4): the second delivery in the same capability does not open another
folder. The folder's slug is the Epic's `capability` field, when the Epic exists; for a
capability with no Epic yet, Research proposes the slug — the `product-manager` when the scope
is product, the orchestrator in the others — the owner confirms it, and the Epic is born later
with that value. Two effects (`WF-SPEC-08`):

- `requirements.md`, `design.md` and `user-experience.md` belong to the capability and live as
  long as it lives. Approved text is not rewritten: the change goes back to Research and comes
  in as a **dated amendment** at the end of the file, which is born `Draft` and only takes
  effect after the owner's reply.
- The plan belongs to the increment: each one gets `tasks/NNNN-<slug>.md`, numbered in
  sequence like the ADRs. The implementer reads only the current plan, not the capability's
  history.

The scope classified in §4.1 decides which files are born or receive an amendment
(`WF-SPEC-03`):

| Scope | Files |
| --- | --- |
| execution | a plan in `tasks/` |
| architecture | `design.md` or an amendment to it; one ADR per decision that outlives the increment; a plan in `tasks/` |
| product | `requirements.md` or an amendment to it; `user-experience.md` when there is an interface; `design.md` when there is a boundary or contract; a plan in `tasks/` |

What each decision document is, and when it freezes, is in
[Decision Documents — PRD, RFC and ADR](documentos-de-decisao-prd-rfc-adr.md). Each file has
one owner and cites the others by link (`WF-SPEC-02`). A specification-only run stops after the
plan in `tasks/` (`WF-SPEC-05`).

**Who writes, in one line.** The pillar decides *when* a file is needed; the scope decides
*which*; the owning agent decides *what it says*; `workflow-spec` decides *form, place, status
and review*. Every file is born `Draft` (an ADR is born `Proposed`) and only changes status
through the owner's explicit reply in the conversation (`WF-SPEC-06`). Which documents the
project keeps is the owner's decision, recorded once in the `## Specs` section of the project's
`AGENTS.md`, with permission, or in `.specs/README.md`, and read before writing (`WF-SPEC-07`);
the plan in `tasks/` is never switched off, and a document that is switched off leaves its
decision in one line in the plan.

---

## 6. Normative rules

Convention: `MUST`/`NEVER` are normative. **†** marks a decision of this doc.

### `WF-CORE-*` — what survives any pillar

| ID | Rule |
| --- | --- |
| `WF-CORE-01` | Every pillar **MUST** return a citable artifact (decision, work unit, code with evidence, or findings report). "Done" without that artifact **NEVER**. † |
| `WF-CORE-02` | A pillar is the moment of the work; a role is who carries it out — the two axes **MUST** stay orthogonal. Reducing an agent to a single pillar ("`product-manager` only does research") **NEVER** — the same role crosses different pillars in different tasks. † |
| `WF-CORE-03` | A pillar **NEVER** moves forward with a decision still open: an explicit return to the previous pillar is cheaper than the wrong decision carrying on (Boehm, cost-of-change curve). |
| `WF-CORE-04` | Every Implementation pillar **MUST** end in Validation; it **NEVER** ends in "done" without proof. |
| `WF-CORE-05` | A decision without evidence **MUST** be treated as a hypothesis, not a fact; feigning certainty **NEVER** — it is packaged opinion. |
| `WF-CORE-06` | Every delegated pillar **MUST** go to a named agent from the §3 table, called as a subagent, which carries its own model and effort; if the pillar runs in a new session, that session **MUST** open with explicit `modelo` and `esforco` and call that agent as a subagent (§3.1, `CC-PAR-05`). Delegating to a generic agent (Claude Code's `general-purpose`, Codex's agentless spawn), or to a session that merely plays the role ("as `backend-developer`" in the brief), **NEVER** — both inherit the model of whoever opened them, not the owner's, and neither carries the agent's body. † |
| `WF-CORE-07` | Whoever orchestrates the pillars **MUST** keep only the §5 envelope, with the full output referenced in `artefato`; reading code, the whole hub or a pillar's full report in the main conversation **NEVER** — that context is reread on every turn until the end of the flow. † |
| `WF-CORE-08` | A mechanical operation — one whose content an artifact has already decided (diff, envelope, template, plan) — **MUST** run in the agent that already has that content in context or, if it must be read, in `repo-operator`, of tier `rapido` (§3.1); reading a diff, template or test output on the session's most expensive tier in order to execute it, or letting the executor decide the content, **NEVER**. † |
| `WF-CORE-09` | Every gap **MUST** leave in the envelope with who decides it (`decide`) and the last pillar in which it can be open (`fecha-em`: `pesquisa` or `planejamento`, §5); a gap without these fields, or left for Implementation or Validation, **NEVER** — with no answer in time, it only moves forward as an assumption the owner accepted, along with what would invalidate it (Wynne, Example Mapping's red cards). † |

### `WF-RES-*` — research

| ID | Rule |
| --- | --- |
| `WF-RES-01` | Research **MUST** separate fact, hypothesis, decision and gap before proposing a solution; mixing the four **NEVER** (Torres, opportunity solution tree). |
| `WF-RES-02` | Existing code **MUST** be treated as evidence of the present, **NEVER** as authority over intent — the current behavior may be the defect itself. |
| `WF-RES-03` | Research **MUST** resolve the smallest decision that unblocks Planning; a lengthy report with no decision attached **NEVER** counts as output of this pillar. |
| `WF-RES-04` | Every claim about user behavior **MUST** come with a source (data, interview, code, ticket); the team's opinion about the user, without that source, **NEVER** replaces research (Cagan, value risk). |
| `WF-RES-05` | A change **MUST** be classified as product, architecture or execution before moving on — and an execution scope **MUST** name its subtype and cite where its rule is written; the classification decides which agent this pillar routes to. |
| `WF-RES-06` | Before the handoff, each rule and each acceptance scenario of the decision **MUST** go through the seven edge categories of §4.1 — boundary, time, empty, repetition, permission, failure, what already exists — and each edge that applies leaves answered with a source, out as a non-goal, or as a gap (`WF-CORE-09`); a decision with an applicable edge that has no destination **NEVER** counts as resolved, and the sweep **NEVER** widens the decision (`WF-RES-03`) (Myers, boundary value analysis; Wynne, Example Mapping). |

### `WF-PLAN-*` — planning

| ID | Rule |
| --- | --- |
| `WF-PLAN-01` | Every work unit **MUST** have its appetite decided before any time estimate — "how much is it worth spending" comes before "how long will it take" (Shape Up). |
| `WF-PLAN-02` | A unit that blows its appetite **MUST** stop and go back to the decision table; silently extending the deadline **NEVER** (Shape Up, circuit breaker). |
| `WF-PLAN-03` | Decomposing into multiple units **MUST** follow a criterion — each unit with its own acceptance, evidence and dependency; decomposing without that criterion **NEVER**, it is cost fragmentation. |
| `WF-PLAN-04` | Every unit **MUST** enter Implementation with written acceptance criteria; "ready to start" without them is **NEVER** ready (Definition of Ready). |
| `WF-PLAN-05` | Each unit's layer/perfil boundary **MUST** be named in Planning; "fullstack" as a perfil **NEVER** — it hides the boundary instead of deciding it. |
| `WF-PLAN-06` | Each unit's evidence plan **MUST** name the test types Validation will run, each at the cheapest level that catches the defect (`TS-CORE-02`), and each invariant in `design.md` or an ADR **MUST** name the type that proves it; integration or E2E without the sentence saying what only they catch **NEVER** — the cost in time and tokens repeats on every round (§4.2). † |

### `WF-IMPL-*` — implementation

| ID | Rule |
| --- | --- |
| `WF-IMPL-01` | Implementation **NEVER** reopens a product decision already recorded in Planning; a divergence found here **MUST** go back to Research, not be decided ad hoc. |
| `WF-IMPL-02` | A focused test **MUST** accompany the change, not be a later step; implementing everything and "testing later" **NEVER** (XP, test-first). |
| `WF-IMPL-03` | The scope of the change **MUST** be the smallest that resolves the decided unit; solving an adjacent problem not decided in this unit **NEVER**, even if it seems efficient. |
| `WF-IMPL-04` | An explicit contract (type, schema, tenant/auth boundary) **MUST** be preserved during implementation; changing an implicit contract and "adjusting later" **NEVER**. |
| `WF-IMPL-05` | A local defect found during the implementation itself **MUST** be fixed there and recorded as evidence, without opening a separate Validation cycle just for it. |
| `WF-IMPL-06` | Before the first line of code, the implementer **MUST** list the questions the unit does not answer — the Task and the code it touches, through the edge categories of §4.1 — and each one leaves answered by an accepted artifact, decided within what the unit has already decided, or returned through §4.3 as a gap (`WF-CORE-09`); starting to write without that list **NEVER** — a question found in the middle of the code arrives with an invented answer already written into it. † |

### `WF-VAL-*` — validation

| ID | Rule |
| --- | --- |
| `WF-VAL-01` | The implementer **NEVER** approves their own change; Validation **MUST** inspect in a context independent of the author (Google SWE Practices; see `CC-SES-07`). |
| `WF-VAL-02` | The evidence required **MUST** be proportional to the change's risk; "run the whole suite" as the default answer **NEVER** — it is a lazy evidence decision, not a rigorous one. |
| `WF-VAL-03` | Technical verification ("did we build it right") and business validation ("is it the right thing") **MUST** be separate steps; the second **NEVER** blocks the technical closure of the first (see [Teste de Software](teste-de-software.md) §0). |
| `WF-VAL-04` | Every Validation failure **MUST** be routed to the pillar where the problem originated — Research if it is a decision gap, Planning if it is a scope/evidence gap, Implementation if it is a code defect; fixing it in the wrong pillar **NEVER**. |
| `WF-VAL-05` | A delivery metric (lead time, change failure rate) **MUST** come from measured data, **NEVER** from perception (Forsgren/Humble/Kim, *Accelerate* — DORA metrics). |

### `WF-SPEC-*` — the `.specs/` files

| ID | Rule |
| --- | --- |
| `WF-SPEC-01` | The output of Research and Planning **MUST** be stored in `.specs/`, and the envelope's `artefato` points to the path; output that exists only in the conversation **NEVER**. † |
| `WF-SPEC-02` | Each `.specs/` file **MUST** have a single owner and cite the others by link; copying content from one file to another **NEVER**, the copy diverges. † |
| `WF-SPEC-03` | The files generated **MUST** follow the scope classified in §4.1; generating the four files for an execution scope **NEVER** (see `DOC-CORE-02`). † |
| `WF-SPEC-04` | A Task of the plan in `tasks/` **MUST** start only when the files it cites are accepted; starting on a draft **NEVER** (`WF-CORE-03`). |
| `WF-SPEC-05` | A specification-only run **MUST** stop after the plan in `tasks/`, returning the Planning envelope; moving on to Implementation without a new request from the owner **NEVER**. † |
| `WF-SPEC-06` | Every `.specs/` file **MUST** be born `Draft` (ADR: `Proposed`) and change status only through the owner's explicit reply in the conversation; the agent that wrote it approving its own file, or silence counting as approval, **NEVER**. † |
| `WF-SPEC-07` | Which documents the project keeps **MUST** be recorded once (`## Specs` in `AGENTS.md`, with the owner's permission, or `.specs/README.md`) and read before writing; asking again on every run **NEVER**; switching off the plan in `tasks/` **NEVER**. † |
| `WF-SPEC-08` | `.specs/` **MUST** have one folder per capability: an already-approved capability document receives a change as a dated amendment, which is born `Draft`, and each increment gets its own plan in `tasks/NNNN-<slug>.md`; rewriting approved text, or piling increments into a single plan, **NEVER**. † |

### Count

**40 rules** in six families, a single file — no satellite in this version.

| Family | Rules |
| --- | --- |
| `WF-CORE-*` | 9 |
| `WF-RES-*` | 6 |
| `WF-PLAN-*` | 6 |
| `WF-IMPL-*` | 6 |
| `WF-VAL-*` | 5 |
| `WF-SPEC-*` | 8 |

---

## 7. Skill contract

### What to load

```
ALWAYS, when deciding which pillar an ambiguous task is in:
          Delivery Flow - Four Pillars.md § 0, § 2, § 3

WHEN CLASSIFYING the scope of a research effort and sweeping the decision's edges:
          § 4.1 + WF-RES-*

WHEN DECLARING a gap, or deciding whether a pillar moves forward with it:
          § 5 "Gaps" + WF-CORE-09

WHEN GOING through the planning gates:
          § 4.2 + WF-PLAN-*

WHEN LISTING the questions before the code, or deciding whether implementation stops and returns:
          § 4.3 + WF-IMPL-* (and the edge table in § 4.1)

WHEN DECIDING how much evidence validation requires:
          § 4.4 + WF-VAL-*

WHEN STORING the .specs/ files:
          § 5 + WF-SPEC-* (and the Decision Documents note, DOC-*, only for the document being written)

WHEN DECIDING who executes a mechanical operation (commit, PR, move, delete, publish, run checks):
          § 3.1 + WF-CORE-08

NEVER:    this whole structure for a task whose pillar is already obvious
          (e.g. "fix this typo" needs no pillar classification)
```

### How to cite

> `WF-CORE-03` — the task asks to implement a new discount limit, but nobody has decided yet
> whether anything above 50% needs manual approval. That is an open product decision arriving
> disguised as an implementation task; the correct response is to return it to
> `workflow-research`, not to pick a value and move on.
> See [Delivery Flow — Four Pillars](fluxo-de-entrega-quatro-pilares.md) § 4.1.

### Invariants the skill must enforce

1. **Pillar before agent.** Never choose `frontend-developer` or `backend-developer` before
   confirming the task has already gone through the earlier pillars.
2. **Going back is cheaper than moving forward wrongly.** Going back a pillar is not a failure
   of the process — it is the process working (`WF-CORE-03`).
3. **Do not reopen a product decision in implementation** (`WF-IMPL-01`) — flag it and return
   it, never decide ad hoc in the middle of the code.
4. **Proportional evidence, never "the whole suite" by default** (`WF-VAL-02`), and the test
   type decided in the plan, with its cost in plain sight (`WF-PLAN-06`).
5. **Technical verification does not wait for business validation, nor the reverse**
   (`WF-VAL-03`) — both are real, but they do not block each other.
6. **Follow the bridge.** When §8 indicates that the decision belongs to an existing skill or
   agent, follow it instead of reinventing the procedure here.
7. **Mechanical operation on the cheapest tier** (`WF-CORE-08`) — whoever orchestrates does not
   read a diff, template or test output to execute what an artifact has already decided.
8. **A gap never closes in the code.** Every gap has who decides it and where it closes
   (`WF-CORE-09`); Research sweeps the edges before handing off (`WF-RES-06`), and the
   implementer lists the questions before the first line (`WF-IMPL-06`).
9. **The role comes from the agent, not from the brief.** A delegated pillar runs in the named
   agent, called as a subagent; a session opened for a unit opens with explicit model and
   effort and calls that agent, instead of playing it (`WF-CORE-06`, `CC-PAR-05`).

### Slices for new skills

| Skill | Loads | Declared source |
| --- | --- | --- |
| "which pillar is this ambiguous task in" | § 0 + § 2 + § 3 | this hub |
| "classify the scope of a research effort" | § 4.1 + `WF-RES-*` | this hub |
| "go through the planning gates" | § 4.2 + `WF-PLAN-*` | this hub |
| "decide whether implementation stops and returns" | § 4.3 + `WF-IMPL-*` | this hub |
| "decide how much evidence validation requires" | § 4.4 + `WF-VAL-*` | this hub |
| "decide who executes a mechanical operation" | § 3.1 + `WF-CORE-08` | this hub |
| "write and record a `.specs/` file" | § 5 + `WF-SPEC-*` | this hub and [Decision Documents — PRD, RFC and ADR](documentos-de-decisao-prd-rfc-adr.md) |

---

## 8. Bridges to the stack

| Decision | What **not** to do | The bridge |
| --- | --- | --- |
| Decide whether a change is product, architecture or execution | assume and go on to the code | `product-manager` / `software-architect` — §4.1 |
| Answer a rule's edge — the limit, the deadline, the empty case, the repeated click | pick in the code whatever seems reasonable | the edge sweep of §4.1, in Research (`WF-RES-06`); in the code, the question list of §4.3 returns it (`WF-IMPL-06`) |
| Open an Epic/Story/Task in the tracker | create the item as soon as the idea shows up, before the decision | `workflow-research` decides the scope first (§4.1) — the Board only opens in Planning, with the decision already resolved (§0.4, §3) |
| Decide which level a unit's test goes in | leave it for when it is being written | `test-design`, existing — not reimplemented here |
| Review an already-implemented change | the author approving it themselves | `code-reviewer`, in fresh context (`WF-VAL-01`, `CC-SES-07`) |
| Decide the HTTP contract of a new route | invent status/shape in the handler | `http-contract`, existing |
| An authentication, cookie or secret finding during validation | fix it and move on without routing | `devops-security` (`WF-VAL-04`) |
| Schedule, risk or "does this fit the scope" during planning | the implementation team deciding alone | `project-manager` |
| Boundary between layers or services during planning | decide it inside the code, without recording it | `software-architect`, recorded decision |
| Write a PRD, RFC, ADR, UX or tasks in `.specs/` | invent the format, approve one's own file, or edit an accepted ADR | `workflow-spec`, with [Decision Documents — PRD, RFC and ADR](documentos-de-decisao-prd-rfc-adr.md) |

**The most important bridge in this note:** the pillar never replaces the skill or agent that
already resolves the question — it only decides **when** to call each one. A `workflow-*` that
answers the architecture question instead of routing to `software-architect` is duplicating a
rule that already exists elsewhere, and duplicated rules rot the next day, like any other layer
of this project.

---

## Sources consulted

- Barry Boehm, *Software Engineering Economics* — cost-of-change curve; basis of the historical
  origin of the verification × validation distinction.
- Marty Cagan, *Inspired: How to Create Tech Products Customers Love* — value, usability,
  viability and feasibility risks in product discovery.
- Teresa Torres, *Continuous Discovery Habits* — opportunity solution tree, continuous research
  instead of a one-off project.
- Ryan Singer / Basecamp, *Shape Up: Stop Running in Circles* — appetite, betting table,
  circuit breaker.
- Kent Beck, *Extreme Programming Explained* — test before implementation, small batches.
- Winters, Manshreck, Wright, *Software Engineering at Google* — culture of code review by an
  independent peer (already cited in `TS-*`).
- Forsgren, Humble, Kim, *Accelerate* — the four DORA delivery performance metrics.
- Glenford Myers, *The Art of Software Testing* — equivalence partitioning and boundary value
  analysis: defects concentrate at the boundary between input classes; basis of the "boundary"
  category of the edge sweep (§4.1, `WF-RES-06`). Consulted on 2026-10-10 through chapter
  summaries, not the book's text.
- Matt Wynne, *Introducing Example Mapping* (Cucumber blog) — rules, examples and questions:
  the question nobody in the room can answer becomes a red card and the conversation moves on,
  and a table covered in them says the story is not yet understood; basis for declaring the gap
  instead of guessing the answer (`WF-CORE-09`) and for sweeping the rule through examples
  (`WF-RES-06`). The `decide` and `fecha-em` fields are a decision of this doc, not of the
  post. Consulted on 2026-10-10.
- **Internal precedent, not academic authority:** lemind (`studio-risine`), ADR 114 — "the
  agent workflow has four pillars" (`docs/decisions/114-four-pillar-agent-workflow.md`) and
  `docs/engineering/agent-workflow.md` — the same four-pillar shape, implemented and in
  production in a real project; this note's pillar × perfil distinction comes directly from
  there.

**What could not be verified against a primary source in this version:** page or specific
edition citations for each book above — the `WF-*` rules are an original synthesis of each
work's central concepts, not a literal transcription. Marked with † on the rules where the
synthesis is this project's main contribution, with no direct parallel in a single source.

---

## Related

- `agents/README.md` — the eleven roles; "How agents hand off" is the flowchart this note
  formalizes
- [Teste de Software](teste-de-software.md) — §0, the verification × validation distinction
  that the Validation pillar reuses
- `skills/workflow/` — the four skills that implement this contract, and `workflow-spec`, which
  stores the `.specs/` files
- [Decision Documents — PRD, RFC and ADR](documentos-de-decisao-prd-rfc-adr.md) — what each
  decision document stored in `.specs/` is
- [Claude Code - Sessão e Verificação](claude-code-sessao-e-verificacao.md) — `CC-SES-07`,
  review in fresh context
- [Claude Code - Paralelismo e Escala](claude-code-paralelismo-e-escala.md) — subagents and how
  the baton passes in Claude Code specifically
