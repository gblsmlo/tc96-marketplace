# Template: Pull Request

Tool-neutral. The PR delivers one feature whose contract is met (`SDD-RUN-08`). Filled from the
feature's state file and its `contract.md`; nothing is guessed. It links back to the feature by a
one-way reference: the branch and the title carry the feature ID, and nothing copies review state
back into `.specs/`.

---

## Body (copy from here down)

<!-- PR title: <type>(<area>): <short description> [<feature ID>] -->

## Feature
- Feature: <!-- .specs/features/<ID>-<slug>/ -->
- PRD: <!-- F<NN>, and the AC-* it traces -->
- New item of: <!-- the split feature's ID, or delete this line -->

## Summary
- <!-- one sentence: what this PR delivers, from spec.md's Provides -->

## Contract
<!-- Copy the contract's "Met when" line, then each check with its result. A contract is met
only when it proves every AC-* it traces was met (SDD-SPEC-06). -->
Met when: <!-- verbatim -->

- [x] <!-- C1 (AC-NN) ... · gate -->
- [x] <!-- G1 (—) ... · static -->

## Gates
- <!-- the state file's `gates` line, verbatim: pass / fail per gate -->

## Review
- Verdict: <!-- met -->
- Fix rounds used: <!-- 0, 1 or 2 -->
- Notes (non-blocking): <!-- from the state file, or "none" -->

## How to test
1. <!-- from plan.md's Commands and the contract's checks -->

## Screenshot
<!-- attach if the change is visual, otherwise delete -->

---

## Related

- `workflow-plan/references/template-contract.md` — where the checks and the **Met when** line
  come from
- [Delivery Flow — Spec Driven Development](../../docs/delivery-flow.md) §5.2 — where delivery
  happens in the run
