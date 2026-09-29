# Appetite and the circuit breaker

`WF-PLAN-01`, `WF-PLAN-02`. From Shape Up (Ryan Singer / Basecamp): appetite is how much time
a unit is worth spending, decided **before** anyone estimates how long it will actually take.
This inverts the usual order — most planning asks "how long will this take" first, then argues
about whether that is acceptable. Appetite asks "how much do we want to spend" first, which
turns the rest of planning into fitting the solution to the budget instead of fitting the
budget to whatever solution got proposed first.

## Setting an appetite

An appetite is a cap on time investment, stated before the work is scoped in detail:

- **Small batch** — hours to a couple of days. A single route, a single component, a bug fix.
- **Big batch** — up to a few weeks. A feature with several units, a new integration.

There is no appetite between "we'll spend whatever it takes." An unbounded appetite is not an
appetite — it means this gate has not actually been passed.

## The circuit breaker

`WF-PLAN-02`. When a unit's actual cost approaches its appetite and the work is not done, the
circuit breaker trips: the unit stops, and returns to the decision table — it does not
silently get more time.

At the circuit breaker, three outcomes are legitimate:

1. **Cut scope** — ship a smaller version that still satisfies the acceptance criterion, or a
   renegotiated one.
2. **Re-plan** — go back through the five gates with new information; the appetite may
   genuinely need to change, but that is a decision, not a drift.
3. **Drop it** — the unit was worth the original appetite and not more; abandoning it is a
   valid outcome, not a failure.

What is **not** legitimate: continuing past the appetite without anyone deciding to. That is
the failure mode the circuit breaker exists to catch — a budget that exists on paper but never
actually stops anything.

## Worked example

Appetite: small batch, one day, for "discounts above 50% require manager approval — backend
validation only." Two days in, the validation rule keeps growing (approval expiry, approval by
role, audit log of who approved). This is the circuit breaker: stop, and take "does the
approval need an audit trail on day one, or can that be its own later unit" back through the
gates — rather than quietly turning a one-day unit into a week-long one.
