# The five gates

`WF-PLAN-*`, hub §4.2. A unit is not ready for `workflow-implementation` until it has passed
all five — in order, because a later gate can invalidate an earlier answer (e.g. the boundary
gate can reveal that what looked like one unit is actually two).

## 1. Product gate

**Question:** if this touches `docs/specs/**` or an equivalent behavior contract, is there an
approved decision behind it?

**Check:** can you point to the spec, ADR, or `workflow-research` handoff that approved this
behavior? If the only answer is "it seemed obvious," this gate fails — return to
`workflow-research`.

## 2. Decomposition gate

**Question:** if this is being split into multiple units, does each one have its own
acceptance criterion, its own evidence, and its own dependencies?

**Check:** could each unit be implemented, validated, and shipped independently of the
others? If splitting only exists to divide typing work between two people, and both halves
share one acceptance criterion, it is not two units — it is one unit with two contributors
(`WF-PLAN-03`).

## 3. Boundary gate

**Question:** which perfil owns each unit?

**Check:** name one of the existing agents (`frontend-developer`, `backend-developer`,
`devops-security`, ...) per unit. "Fullstack" fails this gate — it means the boundary has not
actually been decided (`WF-PLAN-05`). If a unit genuinely needs two perfis working together
sequentially, that is a sign it is still two units, not one — back to gate 2.

## 4. Appetite gate

**Question:** how much is this worth spending, decided before any estimate of how long it
will take?

**Check:** see `apetite-e-corte.md`. The appetite is a cap, not a target — "small" or "one
cycle" is a legitimate appetite even for a task that could theoretically take longer if
scoped differently.

## 5. Acceptance gate

**Question:** is there a written, checkable criterion for "this unit is done"?

**Check:** the criterion must be specific enough that `workflow-validation` can check it
without asking the implementer what they meant. "Users can apply a discount" fails; "a
request with `discount > 0.5` and no `approvedBy` returns 422" passes.
