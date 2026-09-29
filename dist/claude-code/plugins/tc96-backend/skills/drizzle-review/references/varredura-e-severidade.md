# The scan order, and severity

6. **Writes and transactions** — `DRZ-TX-01`, `DRZ-TX-03`, `DRZ-QUERY-04`, `DRZ-QUERY-06`.
7. **Projection and raw SQL** — `DRZ-QUERY-01`, `DRZ-QUERY-03`.
8. **Boundary validation** — `DRZ-ZOD-01`, `DRZ-ZOD-02`.

If a step produces a finding that invalidates the next one (the relational API is switched off; the whole listing should be paginated), **stop reviewing the interior** and report the change of shape, not the detail.

---

## Step 4 — Classify severity

| Severity | What goes in |
| --- | --- |
| **Blocking** | loss of isolation between tenants, `update`/`delete` without `where` (`DRZ-QUERY-04`), `push` in production (`DRZ-MIG-02`), a destructive migration without a rollback |
| **High** | `DRZ-REL-05`, `DRZ-RQB-01`, `DRZ-TX-01`, `DRZ-TX-03`, a desynchronized snapshot, an unbounded read on an open-volume screen |
| **Medium** | a missing index for a hot filter, a redundant index, `DRZ-QUERY-01`, `DRZ-QUERY-06`, `DRZ-ZOD-01` |
| **Low** | preference without an ID — **not a finding**, see Step 6 |

Measured cost beats assumed cost. "This could get slow" with no number and no execution plan is Low, not Medium.

---

## Step 5 — Output format of a finding

Four parts, the same contract as `react-review`:

```
`RULE-ID` — file:line
<what is wrong, one sentence>
Fix: <concrete change>
See the corresponding satellite.
```

### Example
