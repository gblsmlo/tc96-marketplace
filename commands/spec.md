---
nome: spec
descricao: Searches, plans big and stops — triages the request with workflow-search, then writes or amends .specs/PRD.md, the ADRs and each feature's bundle (spec.md, plan.md, contract.md) with workflow-plan, every file a draft the owner approves, and stops before any code
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
**Output:** a triage file, then the PRD or its amendment, the ADRs and the bundle of every feature
the request touches, each reviewed by the owner. No code, no branch, no run.

This command runs the first two phases of the delivery flow, in order, and stops. It decides
nothing those phases do not already decide; it fixes their order and the stop.
Rules: `SDD-FLOW-*`, `SDD-PRD-*` and `SDD-SPEC-*` in [Delivery Flow — Spec Driven Development](../skills/workflow/docs/delivery-flow.md).

---

## Phase 1: Search

Run `workflow-search` on the request. It splits the request into slices on five axes, reads the
record before the code, sends only the open slices to `repo-explorer`, and writes
`.specs/triage/<date>-<slug>.md` with a verdict and a next step per slice and the request's
route.

| The route's first stop | This run |
| --- | --- |
| `amendment`, `adr` or `bundles` | Phase 2 |
| `fast-lane` | Phase 2, fast lane (`SDD-SPEC-09`) |
| `owner` | ask the owner the triage's gaps, then Phase 2 with the answers |
| every slice `exists` | stop: report the triage, nothing to plan |

---

## Phase 2: Plan

Run `workflow-plan` on the triage. It has `product-manager` decide the PRD or amendment and
`doc-prd` write it, and puts it in front of the owner. With the PRD approved, it writes the ADRs
the route asks for through `software-architect` and `doc-adr`, has `spec-writer` write each
bundle from the triage's facts, and puts every bundle and ADR in front of the owner in one
message.

| File | Agent | When |
| --- | --- | --- |
| `.specs/PRD.md` or a dated amendment | `product-manager`, through `doc-prd` | the route has an amendment, or there is no PRD |
| `.specs/adr/NNNN-<slug>.md` | `software-architect`, through `doc-adr` | one per decision that outlives a feature |
| `.specs/features/<ID>-<slug>/spec.md` | `spec-writer` | every feature; in the fast lane only when an interface changes |
| `.specs/features/<ID>-<slug>/plan.md` | `spec-writer` | always |
| `.specs/features/<ID>-<slug>/contract.md` | `spec-writer` | always; met only when it proves every acceptance criterion it traces |

**Gate:** the PRD or amendment is `Approved` before any bundle, and only the owner's answer sets
it (`SDD-CORE-03`). No answer: the run ends there, with the path and its open gaps.

---

## Phase 3: Stop

Report the triage path, every `.specs/` path with its status, and every open gap with who decides
it. Do not start `workflow-implementation`. The run starts only on a new request from the owner,
and each feature only when its bundle is approved and its providers have merged (`SDD-RUN-01`).

---

## Checklist

- [ ] `workflow-search` and `workflow-plan` passed their self-checks.
- [ ] The triage read the record before the code, and no slice got a second search round
      (`SDD-FLOW-06`).
- [ ] Every bundle cites the triage's facts with `file:line` (`SDD-SPEC-01`).
- [ ] Phase 2 put its bundles in front of the owner as one message, not one per feature.
- [ ] Every contract has a check for each acceptance criterion it traces and a **Met when** line
      (`SDD-SPEC-06`).
- [ ] The run stopped with `workflow-implementation` not started; no code, branch, commit or PR
      was created.
