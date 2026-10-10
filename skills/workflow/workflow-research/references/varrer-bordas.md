# Sweeping the decision's edges

`WF-RES-06`. The technique behind Step 5, from hub §4.1 "Varrer as bordas da decisão",
expanded with the cases that make it hard in practice. Classifying the scope says **who**
decides; the sweep says whether the decision is **complete**.

## Why the edge, not the rule

The question that stops a unit mid-code is rarely the main rule — it is the rule's edge. Both
stop examples in `workflow-implementation`, `references/condicoes-de-parada.md`, are edges:
"expires from when — the request or the approval?" is the time edge of the approval rule, and
`>` versus `>=` at exactly 50% is its boundary edge. Asked here, each costs one row in a table;
found in the code, each costs a return plus the code already written on a guessed answer.

## The seven categories

Run every rule and every acceptance scenario of the decision through each one. The example
column uses a single rule: *a discount above 50% requires a manager's approval*.

| Category | The question that usually escapes | On the example rule | Usually decides |
| --- | --- | --- | --- |
| boundary | exactly at the limit, in or out (`>` or `>=`)? the minimum, the maximum, zero, a negative, rounding? | is a discount of exactly 50% above the threshold? | `product-manager` |
| time | counted from when? expires when, in which time zone? events out of order? | does an approval expire — and counted from the request or from the approval? | `product-manager` |
| empty | the empty list, the absent optional field, the first use with nothing registered yet? | a store with no manager registered yet: who approves? | `product-manager` |
| repetition | the same action twice (double click, retry)? two people at once? | the manager clicks approve twice; two managers approve the same order at once | `product-manager` for what the person sees; `software-architect` for how it is guaranteed |
| permission | who may — which role, which resource owner, which tenant, a visitor with no session? | may the requester approve their own discount? | `dono` when it is business policy; `product-manager` otherwise |
| failure | a dependency down, the operation stopped halfway? what the person sees, what is undone? | the approval is saved, but the notification to the requester fails | `product-manager` for what the person sees; `software-architect` for what is undone |
| what already exists | data saved before the change, a client on the previous version, current behavior someone relies on? | orders already discounted above 50% before the rule: re-approved, or kept? | `product-manager` |

A category that does not apply leaves no trace: the sweep is a pass, not a report.

## Where each edge goes

| The edge is | Product scope | Architecture and detail scopes |
| --- | --- | --- |
| **answered**, with a source | a Given/When/Then scenario in the story of `requirements.md` | a line under the envelope's `decisoes`; planning carries it into the unit's acceptance criterion |
| **out** | a non-goal in `requirements.md`, with why | a line under `decisoes`: "out of this increment: …" |
| **a gap** | "Open gaps" in `requirements.md` when it closes in research; the envelope when it closes in planning | the envelope |

Every gap names `decide` and `fecha-em` (`WF-CORE-09`, hub §5 "Lacunas"). The cut for
`fecha-em`: an answer that changes what the person sees or what the product promises closes in
`pesquisa`; one that only changes how the unit is designed, split or proved closes in
`planejamento`. Two managers approving at once shows both: *the requester sees one approval,
not two* is product (`pesquisa`); *a unique constraint or a lock* is architecture
(`planejamento`, `decide: software-architect`).

## Deepen, never widen (`WF-RES-03`)

The sweep goes deeper into the decision being made; it never opens a second one. "May a
manager from another store approve?" is the permission edge of this rule — answer it, or
declare it a gap. "Should refunds need approval too?" is a new decision — it becomes a
non-goal of this increment, not more research.

## Worked sweep

The rule above, as it leaves research:

| Category | Edge | Leaves as |
| --- | --- | --- |
| boundary | exactly 50% | scenario: given a discount of exactly 0.5, when it is submitted, then no approval is asked — source: the pricing policy says "above" |
| time | approval expiry | gap — nobody decided whether it expires at all: `decide: product-manager`, `fecha-em: pesquisa` |
| empty | a store with no manager | scenario: the discount is capped at 50% until a manager exists — source: the owner's answer in this conversation |
| repetition | approve clicked twice, or by two managers | scenario: the requester sees one approval; plus a gap for the mechanism: `decide: software-architect`, `fecha-em: planejamento` |
| permission | the requester approving their own discount | gap — business policy: `decide: dono`, `fecha-em: pesquisa` |
| failure | the notification fails after the approval is saved | out: notifications are a non-goal of this increment |
| what already exists | orders discounted above 50% before the rule | scenario: kept as they are, not re-approved — source: the owner's answer in this conversation |

Two gaps close in research before `requirements.md` can be `Approved`; one travels to
planning, where the unit that depends on it waits at the acceptance gate. The "expires from
when" question now surfaces here, at the cost of one row, instead of in the middle of the code.

## The tell that the scope was misclassified

In an implementation-detail scope the rule is already decided, so the sweep only checks that
the written rule answers each edge the change touches. An applicable edge whose answer is
written nowhere is the tell from `classificar-escopo.md`: answering it would mean inventing the
rule, so the scope is product — back to Step 3.
