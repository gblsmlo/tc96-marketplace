# Template: Pull Request

Tool-neutral. Two bodies: a **layer** PR, into the delivery's feature branch, and the **delivery**
PR, from the feature branch into the trunk (`SDD-RUN-08`). Filled from the state files, the layer
file and `contract.md`; nothing is guessed. The branch and the title carry the delivery and layer
IDs; nothing copies review state back into `.specs/` except the index's Status and PR cells,
which the orchestrator writes (`SDD-PLAN-11`).

---

## Body: layer PR (copy from here down)

<!-- PR title: <type>(<area>): <short description> [<delivery> <layer>] -->
<!-- base: feat/<delivery> · head: feat/<delivery>-<layer> -->

## Layer
- Delivery: <!-- .specs/delivery/<id>/ -->
- Layer: <!-- plans/<layer>-<slug>.md — its goal, one sentence -->
- New layer of: <!-- the split layer's ID, or delete this line -->

## Provides
- <!-- the seams this layer provides, by name, from its file -->

## Checks
- [x] <!-- C6 (AC-29) ... · integration -->
- [x] <!-- G1 types and lint · static --> 
- [x] <!-- G2 test command · unit -->

## Review
- Verdict: <!-- met -->
- Fix rounds used: <!-- 0, 1 or 2 -->
- Skills the implementer loaded: <!-- from the layer's Skills line -->
- Notes (non-blocking): <!-- from the state file, or "none" -->

---

## Body: delivery PR (copy from here down)

<!-- PR title: feat(<area>): <the delivery in a few words> [<delivery>] -->
<!-- base: <trunk> · head: feat/<delivery> -->

## Delivery
- Plan: <!-- .specs/delivery/<id>/plan.md -->
- PRD: <!-- the capabilities, and the amendment if any -->

## Layers
<!-- one line per row of the index: layer, goal, its merged PR -->
- <!-- L1a — <goal> — #PR -->

## Contract
<!-- every AC-* row of contract.md, with the checks and layers that proved it on the feature
branch. The delivery is met only when every row is (SDD-PLAN-07). -->
- [x] <!-- AC-01 — C20 (L3c), C37 (L4b) -->

## Gates on the feature branch
- <!-- run-gates <delivery> --all, verbatim -->

## How to test
1. <!-- the journeys of L5, and the commands of L6 -->

## Screenshot
<!-- attach if the change is visual, otherwise delete -->

---

## Related

- `workflow-plan/references/template-layer.md` and `template-acceptance.md` — where the checks and
  the contract's rows come from
- [Delivery Flow — Spec Driven Development](../../../docs/workflow/delivery-flow.md) §5.2–§5.4 — where
  delivery happens in the run
