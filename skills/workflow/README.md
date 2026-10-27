# workflow skills — the delivery flow in four phases

Four orchestrator skills that run this house's delivery flow, Spec Driven Development, as
phases: search, plan, implementation, review. Each one is a skill the main session loads, one at
a time. It routes to named agents and scripts, and holds only paths, statuses and state files.
The foundation they implement is [docs/delivery-flow.md](docs/delivery-flow.md) (`SDD-*`).

| # | Skill | The question it answers | Hands work to | Leaves with |
| --- | --- | --- | --- | --- |
| 1 | `workflow-search` | what does the request touch, what already exists, and where does each part go? | the main session splits; `repo-explorer` answers open slices | `.specs/triage/<date>-<slug>.md` |
| 2 | `workflow-plan` | what do we build, which layer gives what to the next, and how do we prove it? | `product-manager` (`doc-prd`) · `spec-writer` · `software-architect` (`doc-adr`) | PRD, ADRs and one delivery plan (index, layer files, contract), `Approved` by the owner |
| 3 | `workflow-implementation` | build each ready layer until its gates are green | the harness scripts · the layer's owner with the skills it names, detached | a layer branch with green gates; state `in-review` |
| 4 | `workflow-review` | are the layer's checks met, and then is the delivery's contract met? | `code-reviewer` · `devops-security` · `repo-operator` | a layer PR into the feature branch; `fixing`; a new layer; at the end, the delivery PR into the trunk |

**The order is search → plan → implementation → review, and it only moves forward**
(`SDD-FLOW-01`, `SDD-FLOW-02`). The review is the only phase with a way back: a fix round to
implementation, at most twice, or a new layer file to plan. No failure re-enters
search. Between implementation and review, only the state file passes (`SDD-FLOW-03`).

```
workflow/
├── README.md                          this file
├── docs/
│   └── delivery-flow.md               the foundation: phases, artifacts, run, harness, SDD-* rules
├── workflow-search/
│   ├── SKILL.md
│   └── references/
│       ├── template-triage.md         the triage file: slices, verdicts, the route
│       └── question.md                the one bounded question per open slice
├── workflow-plan/
│   ├── SKILL.md
│   └── references/
│       ├── template-delivery-plan.md  the index: outside in, vocabulary, layers table with progress, order, branches
│       ├── template-layer.md          one layer: seams, rules with sources, exact skills, checks
│       └── template-acceptance.md     the contract: which checks prove each AC-*
├── workflow-implementation/
│   ├── SKILL.md
│   └── references/
│       ├── template-brief.md          the prompt spawn-detached hands to the implementer
│       └── template-state.md          the one file per layer both run phases share
└── workflow-review/
    ├── SKILL.md
    └── references/
        ├── contract-review.md         the reviewer's procedure, read by a new code-reviewer
        └── template-pr.md             the layer PR into the feature branch, and the delivery PR into the trunk
```

## Files in `.specs/` and `.sdd/`

| File | Written by | In phase |
| --- | --- | --- |
| `.specs/triage/<date>-<slug>.md` | the main session | search |
| `.specs/PRD.md` | `product-manager`, through `doc-prd` | plan |
| `.specs/adr/NNNN-<slug>.md` | `software-architect`, through `doc-adr` | plan |
| `.specs/delivery/<date>-<slug>/plan.md`, `plans/<layer>-<slug>.md`, `contract.md` | `spec-writer` | plan |
| the index's Status and PR cells | the main session | implementation and review |
| `.sdd/state/<delivery>/<layer>.md` | the main session | implementation and review |
| `.sdd/logs/`, `.sdd/run/` | the harness scripts | implementation |

Every `.specs/` decision file is born `Draft` (an ADR `Proposed`) and moves only on the owner's
reply (`SDD-CORE-03`). The triage file is a record of facts and routes, not a decision: it has no
status to approve. `.sdd/` is runtime state, git-ignored.

## Which model runs each point

The phases run in the main session, on whatever model the person chose; a plugin cannot pin it.
Everything they hand out goes to a named agent on its own tier, or to a script
(`SDD-CORE-02`, `SDD-CORE-05`). The full table is in the foundation, §3.

## Decisions

1. **Four phases, one flow.** The four-pillar flow these names recall was retired on 2026-10-25
   (commit `2b66c5e`) for four costs: an orchestrator rereading every envelope each turn, at least
   four agents per unit, failed units going back to planning or research, and a reviewer
   auditing every family. These phases keep the SDD rules that fixed those and add
   `SDD-FLOW-*` for the boundaries: one phase loaded at a time, the state file as the only
   handoff, forward only, and a review that checks the contract and nothing else.
2. **Search is internal triage, not research.** A request usually touches several entities at
   once, and a long search over all of it returns little. Search splits the request on five axes
   (product, frontend, backend, tooling, stack), reads the record before the code, sends only open
   slices to `repo-explorer` in one round, and gives each slice a verdict and a next step. It uses
   no external source and decides nothing (`SDD-FLOW-05`, `SDD-FLOW-06`).
3. **The main session splits the request.** Splitting is routing: it costs little, and a
   dedicated triage agent would add a call to every request. Reading the record and the code
   stays with `repo-explorer`.
4. **Absorbs the former `sdd` family.** `sdd-spec-writer` became `workflow-plan`;
   `sdd-orchestrator` became `workflow-implementation` and `workflow-review`; `sdd-contract-review`
   became the reviewer's procedure under `workflow-review`. The hub moved from the knowledge base
   into `docs/`.
5. **One delivery, layered outside in (2026-10-27).** A PRD is planned as one delivery: an index
   that keeps progress, one file per layer — contracts, repository, backend, frontend, tests,
   gates — and a contract mapping each `AC-*` to its checks. The plan decides the seams and the
   rules; each layer's owner builds the inside with the skills the layer names. Each layer's PR
   goes into `feat/<delivery>`; only the validated delivery goes into the trunk. Measured on the
   users-crud test round: one owner gate instead of four, and a layer run reading 37% less
   (`SDD-PLAN-*`).

## What this family deliberately does not have

- **No board.** Registering work on a tracker is outside the flow (`SDD-CORE-06`).
- **No research phase.** Product decisions are the PRD; delivery decisions are the plan.
  Search reports facts and routes; it never decides.
- **No third fix round, no tier escalation.** Two rounds, then a new layer (`SDD-RUN-05`).
- **No step-by-step plan.** The plan decides seams and rules; the inside of a layer is its
  owner's, with its skills (`SDD-PLAN-04`).
- **No layer merged into the trunk.** Layers merge into the feature branch; the trunk receives
  the validated delivery only (`SDD-RUN-08`).
- **No phase inside a phase.** A phase never loads another as a sub-orchestrator
  (`SDD-FLOW-04`).

## Registered under

`tc96-core` in `build/claude-code.sh`, next to `test` and `http`. The `spec` command runs search
and plan, then stops; the `scaffold-sdd-scripts` command writes the harness.

## Related

- [Skills index](../README.md)
- [Delivery Flow — Spec Driven Development](docs/delivery-flow.md) — the foundation, §8 "Skill
  contract"
- `agents/README.md` — the roles these phases call
- `skills/design-docs/` — `doc-prd` and `doc-adr`
