---
name: workflow-validation
description: Decides how much evidence a change needs, proportional to its risk, and requires an independent reviewer rather than the change's own author — routes failures back to the pillar that actually owns the gap, citing `WF-VAL-*` and `WF-CORE-*` IDs. Use once a change or delivery artifact exists and needs proof before closing. Do not use to write the fix — that is `workflow-implementation`. Do not use for business acceptance ("is this the right thing") — that is a separate step owned by `product-manager`, after this pillar closes technically.
source: "[Delivery Flow — Four Pillars](../../referencias/fluxo-de-entrega-quatro-pilares.md)"
tags:
  - skill
  - workflow
  - validation
---

# workflow-validation

> **Source of this skill:** [Delivery Flow — Four Pillars](../../referencias/fluxo-de-entrega-quatro-pilares.md), §4.4 and the `WF-VAL-*` / `WF-CORE-*` rules in §6.
> This skill **does not contain** the text of the rules — it says what to decide, in what order, and to whom to hand it off.

Contract this skill implements: [Delivery Flow — Four Pillars](../../referencias/fluxo-de-entrega-quatro-pilares.md) §7.

> **Delegation, read first (`WF-CORE-06`, `WF-CORE-07`, `WF-CORE-08`).** The diff goes to
> `code-reviewer`; running the checks the plan named goes to `repo-operator`, on the cheapest
> tier; diagnosing a check that failed, or a test level in dispute, goes to `qa-engineer`; a
> security finding to `devops-security`; the PR body, push and PR, on the plan's **Delivery**
> authorization or the owner's answer, to `repo-operator`. Never delegate to a generic agent. Check output (test logs, lint) stays
> inside the agent that ran it; the orchestrating conversation receives the envelope with pass,
> fail, skipped and unavailable counts, and the findings.

> **Design note.** This is the **fourth pillar**, and it is a decision about evidence, not a
> synonym for running the broadest suite (`WF-VAL-02`). It also never lets the change's own
> author be the one who approves it (`WF-VAL-01`) — that is why `code-reviewer` runs this
> pillar in fresh context, never the implementer. Business acceptance is explicitly **not**
> part of this pillar (`WF-VAL-03`) — it happens later and does not block this one.

---

## When to use

| Situation | Go to |
| --- | --- |
| the change is not written yet | `workflow-implementation` |
| the failure found here is a product/decision gap | `workflow-research` |
| the failure found here is a scope/evidence-plan gap | `workflow-planning` |
| the failure found here is a code defect | `workflow-implementation` |
| the question is "is this the right thing for the business," after this pillar is clean | `product-manager` |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Delivery Flow — Four Pillars](../../referencias/fluxo-de-entrega-quatro-pilares.md) §4.4 | the evidence-proportionality tree — the core of this skill |
| 2 | Same hub, §6 `WF-CORE-*` and `WF-VAL-*` | the 16 rules this skill enforces |
| 3 | Same hub, §0.3 | the verification × validation distinction this pillar depends on |
| 4 | the Task's **Surface** and **Risk** lines, and the plan's **Delivery** (`template-task.md` and `template-plan.md` in the `spec-task` skill) | what the reviewer compares, which tree branch applies, and whether push and PR are authorized |

References in this skill:

| File | What for |
| --- | --- |
| `references/proporcionalidade-da-evidencia.md` | the risk → evidence tree, expanded with examples |
| `references/revisao-em-contexto-independente.md` | why the author never approves their own change, and how to hand off cleanly |
| `references/template-pr.md` | tool-neutral change-artifact template, one-way reference back to the work item |

---

## Step 1 — Start review, checks and security together

Hub §4.4, "Review and checks start together". Three readers start at once, in the Task's
directory, and none waits for another (`WF-CORE-10`): `code-reviewer` on the diff, `repo-operator`
on the plan's checks (Step 3) and, when the Task's **Risk** is `security`, `devops-security` on
the sensitive path.

`references/revisao-em-contexto-independente.md`. The implementer does not approve the
implementer's own change (`WF-VAL-01`) — `code-reviewer` runs in fresh context and receives the
input listed there, never the conversation that produced the change. Before reading code it
compares the diff's file list with the Task's **Surface**: a file outside it is a finding
(`WF-IMPL-03`). It reads the checks' envelope when Step 3 returns it, and does not run the
checks again.

---

## Step 2 — Decide the evidence, proportional to risk

`references/proporcionalidade-da-evidencia.md`, hub §4.4. Start from the Task's **Risk** line:
the tree already ran in planning (`WF-PLAN-06`). Run it again only when the diff leaves the
Surface (Step 1) or touches a contract the plan did not foresee, and report that departure.

```
Does the change alter a public contract (API, schema, route)?
├── yes → contract checks + independent review required
└── no
    Does it touch authentication, authorization, or sensitive data?
    ├── yes → security checks + independent review required (route finding to devops-security)
    └── no → focused checks on what changed are enough; declare what was not covered, don't hide it
```

Start from the test types the plan named for the Task (`WF-PLAN-06`). A type more expensive
than the plan named comes in only with the sentence of what it catches and the cheaper ones
do not; without that sentence, the gap is the plan's and goes back to `workflow-planning`
(`WF-VAL-04`).

---

## Step 3 — Run the checks, report separately

Started in Step 1, not after the review. `repo-operator` runs exactly the commands the plan's
evidence names, in its order, and returns each one's outcome (`WF-CORE-08`); that envelope also
goes to the reviewer. Report pass / fail / skipped / unavailable as distinct
outcomes — never collapse "skipped" into "passed." A failure goes to `qa-engineer` for the
diagnosis only when its cause is not obvious from the first failing lines; the operator never
diagnoses.

---

## Step 4 — Route any failure to its pillar of origin

`WF-VAL-04`:

| Failure | Route to |
| --- | --- |
| missing or contradicted product decision | `workflow-research`, the gap with `fecha-em: pesquisa` |
| insufficient scope, dependency, or evidence plan | `workflow-planning`, the gap with `fecha-em: planejamento` |
| defect in the code itself | `workflow-implementation` |
| security-relevant finding (auth, cookie, secret) | `devops-security` |

Fixing the wrong pillar's problem inside this one is never the answer — a code fix for a
missing decision just produces a different wrong answer, faster. A gap routed back names who
decides it, in `decide` (`WF-CORE-09`, hub §5 "Gaps").

---

## Step 5 — Self-check before closing

| # | Check | Rule |
| --- | --- | --- |
| 1 | core self-check passed (hub §7) | `WF-CORE-01`, `WF-CORE-06`–`WF-CORE-10` |
| 2 | the review happened in a context independent from the implementer | `WF-VAL-01` |
| 3 | review, checks and, for a `security` Task, `devops-security` started together; the reviewer read the checks' envelope instead of running them | hub §4.4 |
| 4 | the diff's file list was compared with the Surface before reading code; each file outside it is a finding | `WF-IMPL-03` |
| 5 | the evidence matches the Task's `Risk`; the tree re-ran only on a departure from the Surface or the plan's contracts | `WF-VAL-02`, `WF-PLAN-06` |
| 6 | the checks were the types the plan named; any costlier type carries the sentence of what only it catches | `WF-PLAN-06`, `WF-VAL-04` |
| 7 | business acceptance was **not** required to close this pillar technically | `WF-VAL-03` |
| 8 | any failure was routed to its actual pillar of origin | `WF-VAL-04` |
| 9 | a re-review after a fix was the delta, in a new instance | `WF-VAL-06` |
| 10 | any delivery metric cited comes from measured data, not impression | `WF-VAL-05` |

---

## Step 6 — Hand off

Return the envelope from hub §5 (`pilar: validacao`):

| Result | Continue in |
| --- | --- |
| clean | closed technically — `product-manager` picks up business acceptance separately, if applicable |
| failure found | the pillar of origin from Step 4 |

**Advance without asking.** Routing a failure back to its pillar of origin is automatic: do not
ask whether to continue. Send only the findings, never this review's conversation. The fix
round number decides who runs it (resume, one tier up, or back to planning), per the table in
`workflow-implementation` Step 1
([`CC-CTX-01`, `CC-CTX-03`](../../referencias/claude-code-contexto-e-cache.md)).
After the fix, Step 1 runs again as a delta re-review (`WF-VAL-06`, hub §4.4), and Step 3 runs
in full.

A clean result ends the flow here. Push and PR follow the plan's **Delivery** (hub §5
"Delivery"): with the owner's authorization quoted there, `repo-operator` fills
`template-pr.md` from the envelope, pushes and opens the PR, quoting those words in its request
(`WF-CORE-08`); without it, ask once per wave, naming the Tasks that closed clean. Merging stays
with the owner.

---

## Example

Change: the backend unit for "discount above 50% requires approval." Its **Risk** line reads
`focused`: internal validation only, no public contract, no auth — so focused checks on the
changed function are enough; a full E2E run is not required (`WF-VAL-02`). `code-reviewer` and
`repo-operator` start together. The diff's files all sit inside the Surface, so the tree does
not run again; the reviewer reads the checks' envelope and confirms the boundary case (`>=` vs
`>`) is covered. Clean — closes technically, and the PR opens on the plan's quoted **Delivery**
authorization. Whether managers actually want
this approval flow at all is a separate, later question for `product-manager` (`WF-VAL-03`).

---

## Related

- [Delivery Flow — Four Pillars](../../referencias/fluxo-de-entrega-quatro-pilares.md) — source of this skill, §4.4, §6
- [Teste de Software](../../referencias/teste-de-software.md) — §0, verification × validation
- `code-reviewer` · `qa-engineer` · `devops-security` — who carries out this pillar
