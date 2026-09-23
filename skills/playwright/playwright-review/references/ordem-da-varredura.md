# The scan order

> By **defect frequency** in E2E code, including agent-generated code. If a step
> produces a finding that invalidates the next one — the suite has no trace; the `.only` reduces
> everything to one test; the level is wrong — **stop auditing the interior** and report the change of shape.

| # | What | IDs |
| --- | --- | --- |
| 1 | **An assertion that does not assert** — produces a **green and useless** test, the worst category | `PW-CORE-04`, `PW-EXP-01` |
| 2 | **An invented wait** | `PW-CORE-05`, `PW-ACT-04`, `PW-ACT-03` |
| 3 | **A fragile locator** | `PW-LOC-01`, `PW-LOC-02`, `PW-LOC-03`, `PW-LOC-05`, `PW-LOC-06` |
| 4 | **An action that switches off verification** | `PW-ACT-01`, `PW-ACT-06`, `PW-ACT-05` |
| 5 | **Isolation and session** | `PW-AUTH-01`, `PW-AUTH-03`, `PW-AUTH-05`, `PW-CORE-06` |
| 6 | **Wrong level** — a business rule in E2E; the highest accumulated cost | `PW-STR-*` + `TS-CORE-02` |
| 7 | **Structure** | `PW-STR-01`, `PW-STR-02`, `PW-FIX-01`, `PW-FIX-03`, `PW-FIX-05`, `PW-STR-04`, `PW-STR-06`, `PW-STR-07` |
| 8 | **Network and data** | `PW-NET-02`, `PW-NET-04`, `PW-NET-06`, `PW-NET-03` |
| 9 | **Snapshots** | `PW-SNAP-01`, `PW-SNAP-02`, `PW-SNAP-04`, `PW-SNAP-06` |
| 10 | **Configuration and CI** | `PW-CORE-07`, `PW-CFG-04`, `PW-CFG-05`, `PW-CFG-06`, `PW-RUN-01`, `PW-RUN-02`, `PW-RUN-05`, `PW-RUN-06` |
| 11 | **Style** | last, always subordinate to the rest |

---

## Agent-produced tests — extra checklist

If the suite has planner/generator/healer tests, **also** apply:

| # | Check | Rule |
| --- | --- | --- |
| 1–6 | everything in the scan above | `PW-AGT-04` |
| 7 | **an assertion deleted by a previous healer** | `PW-AGT-05` |
| 8 | a new `test.skip` with no associated issue | `PW-STR-05` |
| 9 | the `.md` specs are committed alongside the tests | `PW-AGT-05` |
| 10 | the `init-agents` definitions were regenerated after updating Playwright | `PW-AGT-02` |

Item 7 is the central risk: **the easiest way to make a test pass is to remove what it
asserted.** A healer without the declared intent (the spec) "fixes" it by deleting. Compare the
test's diff with the corresponding spec.

Item 9 is what makes 7 **detectable** — without a committed spec, there is nothing to compare against.

And if the healer fixes the **same** test on every release, the finding is about the **application**:
an unstable locator means markup with no stable semantics, and the fix is giving the component a role and an
accessible name (`PW-LOC-01`).

---

## Related

- `sondas.md` — what to run first
- `antipadroes.md` — the full grid, with a satellite per ID
- [Playwright - Agents, CLI e MCP](../../../../knowledge-base/playwright-agents-cli-e-mcp.md) § 2.5 — committed specs
