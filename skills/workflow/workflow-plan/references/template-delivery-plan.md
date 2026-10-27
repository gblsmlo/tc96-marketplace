# Template: delivery plan

Saved as `.specs/delivery/<YYYY-MM-DD>-<slug>/plan.md`. It is the delivery's **index**: the system
seen from the outside, the vocabulary, the layers in one table with their status, the order and the
branches. Each layer's content lives in its own file, `plans/<layer-id>-<slug>.md`, from
`template-layer.md`, so a run reads the index and its own layer, not every layer. Written by
`spec-writer` once per PRD or amendment. The index stays under about 100 lines. Rules:
`SDD-PLAN-02`, `SDD-PLAN-03`, `SDD-PLAN-05`, `SDD-PLAN-11`, `SDD-RUN-08`.

| File | Read by |
| --- | --- |
| `plan.md` (this index) | everyone: the owner approving, every layer run, every reviewer |
| `plans/<layer-id>-<slug>.md` | the run of that layer, its reviewer, and the runs of the layers that consume it (its **Provides** only) |
| `contract.md` | the owner validating, the final review: which checks prove each `AC-*` |

## What this file decides, and what it leaves

| Decides | Leaves to the implementer and the specialist skill it loads |
| --- | --- |
| the seams: what crosses from one layer to the next, by name and type-level shape | how a layer is built inside: files, helpers, function bodies, step order |
| the vocabulary every layer uses (terms, roles, error codes) | regexes, queries, library calls, component structure |
| the rules a layer must hold, cited from the PRD (`AC-*`) or an ADR (`ADR-NNNN §n`) | how the rule is coded, as long as the contract's checks pass |
| the order of the layers and what can run in parallel | the tests inside a layer, beyond the checks the contract assigns it |
| which specialist skills own each layer | anything a skill already decides better (`drizzle-*`, `elysia-*`, `tanstack-*`, `react-*`, `bun-test-build`, `playwright-build`) |

A sentence that tells the implementer **how** ("write a regex…", "call `.returning()`…", "step 3:
create file X") does not belong here. If it is a lasting decision, it is an ADR; if it is a rule
the product needs, it is an `AC-*` with a check; otherwise the skill decides it.

## Fields

| Field | Meaning |
| --- | --- |
| `delivery` | `<YYYY-MM-DD>-<slug>` |
| `prd` | `.specs/PRD.md`, plus the amendment it plans, if any |
| `adr` | the ADRs it builds on |
| `trunk` | the branch the delivery finally merges into, normally `main` |
| `branch` | the delivery's feature branch, `feat/<delivery-id>`, cut from `trunk`; every layer branches from it and merges back into it |
| `status` | `Draft` · `Approved` |

## Body (copy from here down)

---

### 1. From the outside

Who uses the system and through which door, before any layer. A small table or diagram:
actors, the doors (screens, HTTP API, command line), the stores and services outside the code.
One line per door: who goes through it and which capabilities (`CAP-*`) it serves.

### 2. Vocabulary

The terms every layer uses, one line each: the term, what it means, where its rule comes from
(`AC-*`, `ADR-*`). Include the roles, the states, and the error codes a client sees. This is the
language of the contracts layer; the code takes its names from here.

### 3. Starting point

What exists today that the layers reuse or replace, from the triage's facts, `path:line`. At most
ten lines; anything more is the implementer's to read.

### 4. Layers

One row per layer or sub-layer, outside in. The content of each is in its file. The default layers
are below; drop one that has nothing to do, and never add a layer per capability: a capability
crosses the layers.

| # | Layer | Typically holds |
| --- | --- | --- |
| L1 | Contracts and vocabulary | input/output schemas, table definitions, shared types, error codes, the API's shape, **and the test environment every later layer's gates run in** (test command, test database, what `bun test` loads) |
| L2 | Repository | data access over the tables, its unit and integration tests |
| L3 | Backend | routes, identity and access, errors, OpenAPI, commands, their integration tests |
| L4 | Frontend | API client, providers, queries and mutations, forms, screens, utils, their component tests |
| L5 | Tests | the journeys across layers (E2E) and the acceptance checks no single layer can prove |
| L6 | Gates | what only the whole delivery can check: security review, the ADRs' static invariants, the full suite and E2E together, CI |

The index table:

| Layer | Goal | Owner | Depends on | File | Status | PR |
| --- | --- | --- | --- | --- | --- | --- |
| L1a | <one sentence> | backend-developer | — | `plans/L1a-<slug>.md` | planned | — |

**Status and PR are the only cells that change after `Approved`** (`SDD-PLAN-11`), and only the orchestrator writes
them, on the feature branch, when a layer's state changes: `planned` → `running` → `in-review` →
`merged` (with the PR link), or `fixing`, `waiting`. Layer runs and reviewers never edit
`plan.md`; two layers running at once would conflict on it. `.sdd/state/` keeps the runtime detail
(round, gates, pid); this table is what a person sees in the repository.

**G1 and G2 hold on every layer, from L1 on.** G1: types and lint clean on the layer's surface,
formatting included. G2: the project's test command green, every suite, not only the layer's.
A layer never leaves them to L6. L1 therefore sets up whatever they need to run.

A layer above the review budget is split **inside the layer** by capability (`L4a` register
screen, `L4b` list screen), never sent back to the PRD: size is a delivery concern, not a product
one.

### 5. Order

Which layers wait for which, and which run at the same time. Contracts come first, because every
other layer codes against them; a frontend layer can run beside the backend once the contracts
are merged. One pull request per layer (or sub-layer), so each review stays in one family.

**Branches.** Every layer pull request targets the delivery's feature branch, never the trunk:

| Pull request | From → into | Merged when |
| --- | --- | --- |
| one per layer or sub-layer | `feat/<delivery-id>-L<n>` → `feat/<delivery-id>` | the layer's checks green, G1 and G2 pass, and its review is `met` |
| one for the delivery | `feat/<delivery-id>` → `trunk` | the implementation is validated: every `AC-*` of **Met when** proved on the feature branch, L5 and L6 green there, and the owner approves |

Nothing reaches the trunk layer by layer: a half-built delivery never sits on `main`
(`SDD-RUN-08`).

### 6. Risks and open gaps

What could change the plan, and every question with who decides it. Empty before `Approved`.
