# Closing the review

## Step 6 — Closing

1. **Turn a probe into a test.** Every P1–P2 finding becomes a test that fails on regression: exports × registered schema, `generate` on a clean tree proposes nothing. A read finding becomes a statement-count assertion (`drizzle-query`, pattern 7). A finding that only exists in the report comes back in six months.
2. **Check whether the database already solves it.** Before proposing an invariant in the application, check `UNIQUE`, `CHECK`, a foreign key, a partial unique index, an exclusion constraint and RLS. A constraint holds under concurrency; application code does not.
3. **Separate what requires a product decision.** An ambiguous aggregation rule, a listing ceiling, a retention policy and who may edit whose rows are not bugs until someone decides which behaviour is right. Report them as a question with options, not as a fix.
4. **Order by severity**, not by file.
5. **Declare what was not verified.** If a probe did not run (no `node`, no `typescript`, the database down, the integration flag not set), say so — "not verified" is never "no findings".
