# Finding format, and the cut

## Step 4 — Output format of a finding

Four parts, the same contract as `react-review`:

```
`RULE-ID` — file:line
<what is wrong, one sentence>
Fix: <concrete change>
See <the satellite and section>.
```

### Example

```
`DRZ-RQB-01` — apps/api/src/features/tasks/repository.ts:265
The listing calls the aggregate read once per row of the page, inside Promise.all.
Fix: fetch the page's IDs and load references and tags in one query with inArray, grouping by Map.
See Drizzle - Reads and Relations § 4.
```

Rules of the format:

- **Canonical ID required**, checked against `id-map.md` before writing.
- **file:line always.** For a probe, the evidence is the script's output — paste it.
- **Concrete fix.** If the repository already has the right pattern in another file, point at that file: extending the established pattern is worth more than introducing a new one. The build skills (`drizzle-query`, `drizzle-mutation`, `drizzle-zod`) carry executed patterns to point at.
- **One satellite reference.**

---

## Step 5 — The cut: finding × opinion

**A finding without a rule ID is an opinion**, with three ways out:

1. **There is an ID** → a finding; cite the canonical one.
2. **There is no ID, but a doc section covers it** (a listing without `limit`, offset × keyset, a redundant index, `extras` re-aliasing) → cite the doc and the section: "Drizzle - Reads and Relations § 5.1". Do not invent `DRZ-*`.
3. **Neither ID nor section** → a separate "Suggestions (no rule)" section, never mixed in with findings.

**Never invent an ID.** If the scan finds a recurring, real defect with no matching rule, the right product is a **rule proposal** for the family docs — with a suggested ID, the text, the case that motivated it and how it was verified — not a fake citation in the report.
