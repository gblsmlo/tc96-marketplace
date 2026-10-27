---
nome: spec
descricao: Searches, plans big and stops — triages the request with workflow-search, then writes or amends .specs/PRD.md, the ADRs and the delivery plan (index, one file per layer, contract) with workflow-plan, every file a draft the owner approves, and stops before any code
tipo: comando
idioma: en
tags:
  - sdd
  - workflow
  - spec
---
# Spec generation only

**Input:** the request the person typed with the command: a product, a feature, a change, or a
fix.
**Output:** a triage file, then the PRD or its amendment, the ADRs and the delivery plan — its
index, one file per layer and its contract — each reviewed by the owner. No code, no branch, no
run.

This command runs the first two phases of the delivery flow, in order, and stops. It decides
nothing those phases do not already decide; it fixes their order and the stop.
Rules: `SDD-FLOW-*`, `SDD-PRD-*` and `SDD-PLAN-*` in [Delivery Flow — Spec Driven Development](../skills/workflow/docs/delivery-flow.md).

---

## Phase 1: Search

Run `workflow-search` on the request. It splits the request into slices on five axes, reads the
record before the code, sends only the open slices to `repo-explorer`, and writes
`.specs/triage/<date>-<slug>.md` with a verdict and a next step per slice and the request's
route.

| The route's first stop | This run |
| --- | --- |
| `amendment`, `adr` or `delivery` | Phase 2 |
| `fast-lane` | Phase 2, fast lane (`SDD-PLAN-10`) |
| `owner` | ask the owner the triage's gaps, then Phase 2 with the answers |
| every slice `exists` | stop: report the triage, nothing to plan |

---

## Phase 2: Plan

Run `workflow-plan` on the triage. It has `product-manager` decide the PRD or amendment and
`doc-prd` write it, and puts it in front of the owner. With the PRD approved, it writes the ADRs
the route asks for through `software-architect` and `doc-adr`, has `spec-writer` write one
delivery plan from the triage's facts, layered from the outside in, and puts the delivery and its
ADRs in front of the owner in one message.

| File | Agent | When |
| --- | --- | --- |
| `.specs/PRD.md` or a dated amendment | `product-manager`, through `doc-prd` | the route has an amendment, or there is no PRD |
| `.specs/adr/NNNN-<slug>.md` | `software-architect`, through `doc-adr` | one per decision that outlives the delivery |
| `.specs/delivery/<YYYY-MM-DD>-<slug>/plan.md` | `spec-writer` | always: the index — actors and doors, vocabulary, starting point, the layers with Status and PR, order, branches |
| `.specs/delivery/<YYYY-MM-DD>-<slug>/plans/<layer>-<slug>.md` | `spec-writer` | one per layer (L1 contracts and test environment … L6 gates); in the fast lane only the layers the fix touches |
| `.specs/delivery/<YYYY-MM-DD>-<slug>/contract.md` | `spec-writer` | always; met only when every `AC-*` it traces has all its checks green |

**Gate:** the PRD or amendment is `Approved` before the delivery plan, and only the owner's answer sets
it (`SDD-CORE-03`). No answer: the run ends there, with the path and its open gaps.

---

## Phase 3: Stop

Report the triage path, every `.specs/` path with its status, and every open gap with who decides
it. Do not start `workflow-implementation`. The run starts only on a new request from the owner,
and each layer only when the delivery is approved and the layers it depends on have merged into
the delivery's feature branch (`SDD-RUN-01`).

---

## Checklist

- [ ] `workflow-search` and `workflow-plan` passed their self-checks.
- [ ] The triage read the record before the code, and no slice got a second search round
      (`SDD-FLOW-06`).
- [ ] The delivery plan cites the triage's facts with `file:line` (`SDD-PLAN-01`).
- [ ] One delivery folder, read from the outside in; every index row has its layer file, and no
      layer file holds steps, file lists or code (`SDD-PLAN-02`–`SDD-PLAN-04`).
- [ ] Phase 2 put the delivery and its ADRs in front of the owner as one message.
- [ ] `contract.md` maps every acceptance criterion to the checks that prove it, and every check
      lives in one layer file (`SDD-PLAN-06`, `SDD-PLAN-07`).
- [ ] The run stopped with `workflow-implementation` not started; no code, branch, commit or PR
      was created.
