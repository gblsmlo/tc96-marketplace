# Classifying scope: product, architecture, or execution

`WF-RES-05`. The decision tree from hub §4.1, expanded with the boundary cases that make it
hard in practice.

```
1. Does the change alter what the product does or promises?
   └── yes → PRODUCT scope → product-manager decides, product-designer designs the flow
2. Does it move where a responsibility lives, or introduce a new service boundary?
   └── yes → ARCHITECTURE scope → software-architect decides
3. Is the expected behavior already decided and written down?
   (spec, ADR, test, contract, accepted ticket)
   ├── no  → PRODUCT scope: an undecided rule in disguise → product-manager decides
   └── yes → EXECUTION scope → go straight to workflow-planning, citing where the rule is written
```

Execution is defined by what it keeps, not by how small it is: the rule is decided and written,
and the change alters only how it is carried out. A bug that corrupts data is execution; a
one-line threshold change nobody decided is product.

## The three scopes, with examples

| Scope | Example | Not this scope |
| --- | --- | --- |
| **Product** | "should a discount above 50% require manager approval" — changes what the system promises to the user or the business | "the approval check runs client-side instead of server-side" — same promise, different mechanism |
| **Architecture** | "move discount calculation from the checkout route into a shared pricing service" — moves a responsibility or introduces a boundary | "extract the discount function into a separate file in the same module" — no boundary crossed, no new service |
| **Execution** | "the discount function has an off-by-one in the boundary check, and the pricing policy says *above* 50%" — the rule is written, the code diverges from it | "we're not sure the 50% threshold is correct" — that is a product question hiding inside what looks like a bug report |

## The execution subtypes

Name the subtype in the envelope, because each one asks planning for different evidence.

| Subtype | When | Example | Evidence planning requires |
| --- | --- | --- | --- |
| **fix** | the code diverges from the written rule (a bug) | the off-by-one above | the rule, cited, and a case that fails today |
| **refactor** | same behavior, structure changes inside the same boundary | extract the discount function into its own file in the same module | the existing tests still pass, unchanged |
| **technical adjustment** | performance, dependency, configuration — same promise, same boundaries | cache the price list; upgrade the pricing library | a before/after measurement, or a check of the adjustment |

A refactor that needs a test changed is not a refactor: either the test pinned internal
structure (fix the test as a separate fix), or the behavior changed (back to
question 1).

## Why the classification is expensive to get wrong

Treating a **product** question as execution is the costliest miss: the fix ships, it is
technically correct against nobody's stated rule, and the next person to touch this code
inherits a decision that was never actually made — only guessed by whoever wrote the patch.

Treating **execution** as architecture is the opposite failure: a task that needed one line
changed gets escalated through a decision-recording process it did not need, which is its own
cost (`WF-PLAN-01`, appetite — the same economy applies one pillar earlier).

## The tell that "execution" is actually a product question

Question 3 is the tell. If answering "what should this do" requires knowing something about
the business rule that is not already written down anywhere — a threshold, a policy, an
exception case — it is not execution. Execution's answer only requires reading the code and
the already-written rule, and the envelope cites where that rule lives; it never requires
*inventing* the rule.
