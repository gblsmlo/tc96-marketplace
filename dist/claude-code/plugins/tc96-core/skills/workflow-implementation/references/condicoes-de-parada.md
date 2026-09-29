# Stop-and-return conditions

Hub §4.3. Three situations can surface mid-implementation, and only one of them is fixed
without leaving this pillar.

## 1. Missing or contradicted product behavior → `workflow-research`

**Signal:** the code you need to write depends on a rule nobody decided, or the existing code
contradicts what the unit's acceptance criterion assumes.

**Example:** the unit says "approval expires after 24 hours," but implementing it raises a
question nobody answered — expires from when: from the request, or from the approval itself?
That is a product decision hiding inside what looked like a detail. Stop; do not pick one and
keep going (`WF-IMPL-01`).

## 2. Insufficient scope, dependency, or evidence plan → `workflow-planning`

**Signal:** the unit's boundary turns out to be wrong once you are inside the code — it
actually depends on a change in a different perfil's area, or the acceptance criterion cannot
be checked with the evidence plan that was named.

**Example:** the backend unit for the approval rule turns out to require a new field on a
shared type that the frontend unit also depends on, but the two units were planned as fully
independent. That dependency needs to go back through the decomposition gate.

## 3. A local defect inside what this unit already decided → fix here

**Signal:** something is wrong, but fixing it does not require any decision outside what this
unit already owns — it is a bug in executing an already-settled rule, found while implementing
a related one.

**Example:** implementing the approval-expiry check, the developer notices the existing
discount function also has an off-by-one at exactly 50% (`0.5` should require approval, but
the comparison uses `>` instead of `>=`). This is inside the same function, the same already-
decided rule, and safe to fix without a new decision. Fix it, record it as evidence
(`WF-IMPL-05`) — it is not grounds to stop.

## The distinguishing question

For any surprise found mid-implementation, ask: **does resolving this require a decision that
belongs to someone else's scope, or does it only require code that already agrees with a
decision already made?** The first stops; the second continues.
