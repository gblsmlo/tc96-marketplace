# Finding format, and the cut

Four parts, the same contract as `react-review`:

```
`RULE-ID` — file:line
<what is wrong, one sentence>
Fix: <concrete change>
See the corresponding satellite.
```

### Example

```
`DRZ-RQB-01` — apps/api/src/features/tasks/repository.ts:265
The listing calls the aggregate read once per row of the page, inside Promise.all.
Fix: fetch the page's IDs and load references and tags in one query with inArray, grouping by Map.
See Drizzle - Queries e Relations.
```

Rules of the format:

- **Canonical ID required**, checked against § 6 before writing.
- **file:line always.** For a probe, the evidence is the script's output — paste it.
- **Concrete fix.** If the repository already has the right pattern in another file, point at that file: extending the established pattern is worth more than introducing a new one.
- **One satellite link.**

---

## Step 6 — The cut: finding × opinion

**A finding without a rule ID is an opinion**, with two legitimate ways out:

1. **There is an ID** → a finding, cite the canonical one.
2. **There is no ID, but there is a normative note** (offset × cursor, log retention, destructive deploy order) → cite the note and the section: "". Do not invent `DRZ-*`.
3. **Neither ID nor note** → a separate "Suggestions (no rule)" section, never mixed in.

**Never invent an ID.** If the scan finds a recurring, real defect with no matching rule, the right product is a **rule proposal** for [Drizzle ORM](../../../../knowledge-base/docs/drizzle-orm.md) § 6 — with a suggested ID, text and the case that motivated it — not a fake citation in the report.
