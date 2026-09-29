# Closing the review


## Step 7 — Closing the review

1. **Turn a probe into a test.** Every finding from probes S1–S3 becomes a test that fails on regression: exports × registered schema, journal × snapshots, index × prefix. A finding that only exists in the report comes back in six months.
2. **Check whether the database already solves it.** Before proposing an invariant in the application, check `CHECK`, partial unique, exclusion constraint and RLS —.
3. **Separate what requires a product decision.** An ambiguous aggregation rule, a listing ceiling and a retention policy are not bugs until someone decides which behavior is right. Report them as a question with options, not as a fix.
4. **Order by severity**, not by file.
5. **Declare what was not verified.** If a probe did not run (database down, test flag not unlocked), say so — do not confuse "not verified" with "no findings".
