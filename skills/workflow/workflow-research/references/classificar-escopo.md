# Classifying scope: product, architecture, or implementation detail

`WF-RES-05`. The decision tree from hub §4.1, expanded with the boundary cases that make it
hard in practice.

```
Does the change alter what the product does or promises?
├── yes → PRODUCT scope → product-manager decides, product-designer designs the flow
└── no
    Does it move where a responsibility lives, or introduce a new service boundary?
    ├── yes → ARCHITECTURE scope → software-architect decides
    └── no → IMPLEMENTATION DETAIL → go straight to workflow-planning
```

## The three scopes, with examples

| Scope | Example | Not this scope |
| --- | --- | --- |
| **Product** | "should a discount above 50% require manager approval" — changes what the system promises to the user or the business | "the approval check runs client-side instead of server-side" — same promise, different mechanism |
| **Architecture** | "move discount calculation from the checkout route into a shared pricing service" — moves a responsibility or introduces a boundary | "extract the discount function into a separate file in the same module" — no boundary crossed, no new service |
| **Implementation detail** | "the discount function has an off-by-one in the boundary check" — the rule was already decided, this is a bug in executing it | "we're not sure the 50% threshold is correct" — that is a product question hiding inside what looks like a bug report |

## Why the classification is expensive to get wrong

Treating a **product** question as a detail is the costliest miss: the fix ships, it is
technically correct against nobody's stated rule, and the next person to touch this code
inherits a decision that was never actually made — only guessed by whoever wrote the patch.

Treating a **detail** as architecture is the opposite failure: a task that needed one line
changed gets escalated through a decision-recording process it did not need, which is its own
cost (`WF-PLAN-01`, appetite — the same economy applies one pillar earlier).

## The tell that a "detail" is actually a product question

If answering "what should this do" requires knowing something about the business rule that
is not already written down anywhere — a threshold, a policy, an exception case — it is not a
detail. A detail's answer only requires reading the code and the already-decided rule; it
never requires *inventing* the rule.
