# Change-artifact template — Pull Request

Tool-neutral. The PR is the **change artifact**: what `workflow-validation` inspects in
independent context (`WF-VAL-01`). It links back to the work item (Epic/Story/Task, from
`workflow-planning`'s templates) by a one-way reference — the branch and the PR title carry
the work-item key; nothing copies review state back onto a second, mutable field (a real
lemind rule worth keeping generically: ADR 117 clause 2, "a referência ao GitHub é de mão
única").

---

## Body (copy from here down)

<!-- PR title: <type>(<area>): <short description> [<WORK-ITEM-ID>] -->

## Work item
- Item: <!-- the Task (or Story, if the Task level is not used) this PR delivers -->
- Research / source decision: <!-- link to the research or decision record, if applicable -->
- Capability, Milestone, cycle: <!-- if applicable -->

## Summary
- <!-- one-sentence summary of what this PR does and why -->

## Context
- <!-- problem, impact, and the relevant business or technical context -->

## Changes
- <!-- change 1 -->
- <!-- change 2 -->
- <!-- change 3 -->

## Acceptance criteria
- <!-- criterion 1, from the work item's "done when" -->
- <!-- criterion 2 -->

## Validation
<!-- WF-VAL-02: evidence proportional to risk, not a fixed default. Report pass / fail /
skipped / unavailable separately — never collapse "skipped" into "passed". -->
- [ ] <!-- automated checks run, and their result -->
- [ ] <!-- manual validation or acceptance scenario, when a check cannot cover it -->
- [ ] <!-- contract check, when this PR changes a public API/schema/route -->
- [ ] <!-- security-relevant check, when this PR touches auth, a cookie, or a secret — route the finding to whoever owns security if one is found -->

### How to test
1. <!-- step 1 -->
2. <!-- step 2 -->

## Product decisions
<!-- WF-VAL-03: a note here is verification context, not the business-acceptance step itself.
Delete this section when the PR does not touch a product decision. -->
- <!-- decision, canonical rule, or open follow-up -->

## Screenshot
<!-- attach if the change is visual, otherwise delete -->

---

## Related

- `template-epic.md`, `template-story.md`, `template-task.md` — the work items this PR links back to
- [Fluxo de Entrega — Quatro Pilares](../../../../knowledge-base/fluxo-de-entrega-quatro-pilares.md) §4.4 — the evidence-proportionality tree behind the Validation section
- Reference model: lemind `.github/pull_request_template.md`
