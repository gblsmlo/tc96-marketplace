# Separating fact, hypothesis, decision, and gap

`WF-RES-01`. The technique behind Step 2: every piece of information gathered during research
sorts into exactly one bucket. Mixing them is the single most common way a research pass
produces a confident-sounding answer that is actually a guess.

## The four buckets

| Bucket | Definition | Test |
| --- | --- | --- |
| **Fact** | observed directly — in code, a log, a passed test, a dated ticket | can you point to the artifact right now? |
| **Hypothesis** | a plausible explanation, not yet confirmed | would a different explanation also fit the same evidence? |
| **Decision** | already made and accepted by whoever owns that scope | is there a dated record — a spec, an ADR, a merged PR — or just someone's memory of a meeting? |
| **Gap** | genuinely unknown, and needs an answer before Planning can proceed | if you had to guess, would you be guessing? |

## Worked example

*Task: "the checkout discount is sometimes wrong."*

| Item | Bucket | Why |
| --- | --- | --- |
| the discount function returns `0.55` for a `0.5` input on line 42 | fact | reproducible in the code, right now |
| "this only happens for orders over $1000" | hypothesis | plausible, but no one has checked the actual failing orders yet — `WF-RES-02` applies here too: the current code's behavior on those orders is evidence of the present bug, not evidence of what the correct rule is |
| "discounts above 50% require manager approval" | decision, if there is a dated spec or ADR saying so; hypothesis, if it is only "I think that's how it should work" | check for the artifact before trusting the memory |
| "should a discount above 50% require approval at all" | gap | this is very likely the actual question `workflow-research` needs to resolve — see the Step 3 classification |

## Why code is evidence of the present, never authority over intent (`WF-RES-02`)

The function returning `0.55` for `0.5` is a **fact** about what the code does. It is not
evidence that the code is *supposed* to do that — the bug might be exactly this. Treating
"that's what the code does" as settling the question of "that's what it should do" is how a
defect survives a research pass unchanged.

## Common mixing failures

- Presenting a hypothesis with the confidence of a fact ("users hate this" instead of "we
  believe users find this confusing, based on three support tickets — not yet confirmed with
  data").
- Treating a decision someone remembers from a meeting as equivalent to a decision with a
  dated record — memory drifts, records don't.
- Calling a gap a decision because leaving it open feels unfinished. A declared gap
  (`WF-CORE-05`) is honest work; a fabricated decision is not.
