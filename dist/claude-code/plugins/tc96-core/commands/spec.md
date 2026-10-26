---
description: Plans big and stops — writes or amends .specs/PRD.md, then each feature's bundle (spec.md, plan.md, contract.md) in .specs/features/, every file a draft the owner approves, and stops before any code
tags:
  - sdd
  - spec
---
# Spec generation only

**Input:** the request the person typed with the command: a product, a feature, a change, or a
fix.
**Output:** the PRD or its amendment, and the bundle of every feature the request touches, each
reviewed by the owner. No code, no branch, no run.

This command runs the "plan big" half of the flow, in order, and stops. It decides nothing those
skills do not already decide; it fixes their order and the stop.
Rules: `SDD-PRD-*` and `SDD-SPEC-*` in [Delivery Flow — Spec Driven Development](../referencias/fluxo-de-entrega-sdd.md).

---

## Phase 0: Read where the request stands

Read only status lines: `.specs/PRD.md` and its last amendment, and the folders in
`.specs/features/`.

| Found | This run |
| --- | --- |
| no PRD | starts at Phase 1 |
| a `Draft` PRD or amendment | resumes at that review, in Phase 1 |
| an approved PRD, and the request changes what the product does or adds a feature | Phase 1 writes an amendment |
| an approved PRD, and the request is a fix or refactor that changes no product behavior | skips to Phase 2, fast lane (`SDD-SPEC-09`) |
| an approved PRD that already covers the request | starts at Phase 2 |

---

## Phase 1: PRD

Start `product-manager` on the request: it decides the product content — problem and evidence,
stories, each rule's edges, the feature cut — and has `doc-prd` (plugin `tc96-design-docs`) write
it into `.specs/PRD.md`, or into an amendment to it. `doc-prd` only writes: whatever the decisions
leave open comes back as gaps. Put the `Draft` in front of the owner: path, summary sentence,
waves, open gaps, "approve, change, or reject?".

**Gate:** the PRD, or the amendment this run wrote, is `Approved` before Phase 2, and only the
owner's answer sets it (`SDD-CORE-03`). No answer: the run ends here, with the path and its open
gaps.

---

## Phase 2: Feature bundles

Run `sdd-spec-writer` for the features this request touches — by default, every feature of the
approved PRD with no approved folder, in wave order; in the fast lane, the one fix. It runs the
repo search through `repo-explorer`, has `spec-writer` write each bundle, sends lasting decisions
to `software-architect` as ADRs, and puts every bundle and ADR in front of the owner in one
message.

| File | Agent | When |
| --- | --- | --- |
| `.specs/features/<ID>-<slug>/spec.md` | `spec-writer` | every feature; in the fast lane only when an interface changes |
| `.specs/features/<ID>-<slug>/plan.md` | `spec-writer` | always |
| `.specs/features/<ID>-<slug>/contract.md` | `spec-writer` | always; met only when it proves every acceptance criterion it traces |
| `.specs/adr/NNNN-<slug>.md` | `software-architect` | one per decision that outlives a feature |

A gap that changes what the product promises goes back to Phase 1 as an amendment, not into a
bundle.

---

## Phase 3: Stop

Report every `.specs/` path with its status, and every open gap with who decides it. Do not start
`sdd-orchestrator`. The run starts only on a new request from the owner, and each feature only
when its bundle is approved and its providers have merged (`SDD-RUN-01`).

---

## Checklist

- [ ] `doc-prd` and `sdd-spec-writer` passed their self-checks.
- [ ] A repo search ran before every bundle (`SDD-SPEC-01`).
- [ ] Phase 2 put its bundles in front of the owner as one message, not one per feature.
- [ ] Every contract has a check for each acceptance criterion it traces and a **Met when** line
      (`SDD-SPEC-06`).
- [ ] The run stopped with `sdd-orchestrator` not started; no code, branch, commit or PR was
      created.
