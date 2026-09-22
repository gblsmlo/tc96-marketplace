# Fix × anesthetic, and the finding format

---

## The seven anesthetics

They make the red disappear without solving anything. If you are proposing one of them, go back to the tree.

| Anesthetic | What it hides | Rule |
| --- | --- | --- |
| `waitForTimeout` | the condition that should have been waited on | `PW-CORE-05` |
| higher `retries` | a diagnosable defect | `PW-RUN-03` |
| `force: true` | an overlay the user suffers too | `PW-ACT-01` |
| `workers: 1` | coupling between tests | § 5.2 of the hub |
| a larger global `expect.timeout` | a performance regression | `PW-EXP-04` |
| `test.skip` without an issue | the debt, now anonymous | `PW-STR-05` |
| removing the failing assertion | exactly what the test was verifying | `PW-AGT-05` |

The last one is the worst, and it is what an automatic healer does when it has no declared
intent — [Playwright - Agents, CLI e MCP](../../../../knowledge-base/docs/playwright-agents-cli-e-mcp.md) § 2.5.

---

## Finding format

Five parts — **the trace evidence** is what separates this skill from a guess:

```
`RULE-ID` — file:line
Symptom: <how the failure presents, and under what condition>
Evidence: <what the trace shows — the tab and the message>
Cause: <one sentence>
Fix: <concrete change>
See the corresponding satellite.
```

```
`PW-ACT-01` — e2e/checkout.spec.ts:52
Symptom: fails ~1 in 4 runs in CI, always on the click on "Confirm"; passes locally.
Evidence: trace, Log tab of the click action — "element intercepts pointer events";
 Snapshot Before shows the "item added" toast still on screen, over the button.
Cause: the toast lasts 3 s and covers the button; in CI the previous step finishes faster.
Fix: do NOT use force: true. Wait for the toast to leave before clicking —
 await expect(page.getByRole('status')).toBeHidden — or fix the toast's z-index/position,
 which is the real defect: the user cannot click either.
See Playwright - Ações e Auto-waiting.
```

Rules of the format:

- **ID checked in `mapa-de-ids.md`**, never an alias.
- **Trace evidence, with the tab.** "Looks like timing" is not evidence.
- **A fix that attacks the cause.** If the cause is a product defect, the fix is in the product —
 saying so explicitly is this skill's main value.

---

## Closing the diagnosis

1. **Confirm with `--repeat-each=20`.** Twenty greens; one proves nothing on a 1-in-4 flake.
2. **If the cause was a product defect**, the test does not change. Say so.
3. **If it was environment parity**, the fix is the pipeline (`PW-SNAP-02`).
4. **Turn the diagnosis into a gate:** trace on (`PW-CFG-02`), flaky not counting as green, `--repeat-each` in the nightly job.
5. **If the same test goes flaky again**, the root cause was not found (`TS-PROC-08`).
6. **Declare what was not verified.** "Not verified" is not "no findings".
