# Worked example — a structural review in a PR

PR: *"extracts invoice formatting for reuse and adds the billing screen"*.

---

## Step 1 — probes before opening a file

```
$ bash scripts/sondas-imports.sh src

== 0. Enforcement
 -- biome.json: ABSENT ← already a finding, and the first one
 -- aliases: tsconfig.json 4 | vite.config.ts 4 | vitest.config.ts no alias
== 1. Inverted direction
 src/libs/format-invoice.ts:3 from '@features/invoices'
== 2. Deep import
 src/routes/billing.tsx:2 from '@features/invoices/components/invoice-row'
== 3. Own alias inside the feature
 src/features/billing/components/list.tsx:1 from '@features/billing'
== 4. Barrel with logic
 src/features/billing/index.ts
== 6. Naming convention
 src/features/billing/components/BillingList.tsx
```

Six minutes. None of them is a finding yet — they are candidates with a location.

## Step 2 — the reading, and what it changes

`libs/format-invoice.ts` imports `@features/invoices` to read the `Invoice` type and the tax
table. It confirms `REACT-ARCH-06`: the generic layer has stopped being generic.

`features/billing/` has **one** screen and no vocabulary of its own — "billing" here is
the button's name, not a capability's. The probe cannot see that: it is `REACT-ARCH-01`, and it **changes
the rest of the report**, because if the feature should not exist, findings 3, 4 and 6
inside it stop being fixable where they are.

## Step 3 — the report

```markdown
## Structural review — PR #91 (billing)

**Enforcement** (probe 0): biome.json **ABSENT** · alias missing in vitest.config.ts

### Critical (3)

`REACT-ARCH-01` — src/features/billing/
"Billing" is an invoices screen, not a capability with vocabulary of its own: there is no
entity, api/ or store that is not invoices'.
Fix: move the content into src/features/invoices/components/ and delete the feature;
the route composes what already exists.
See Feature-Based Architecture § 3.

`REACT-ARCH-06` — src/libs/format-invoice.ts:3
A domain rule inside the generic layer; libs/ stops being reusable.
Fix: move it to src/features/invoices/utils/format-invoice.ts and export it in the barrel
if some external consumer needs it.
See Feature-Based Architecture § 6.

`REACT-ARCH-05` — src/routes/billing.tsx:2
Deep import into @features/invoices/components/invoice-row.
Fix: import through the barrel — from '@features/invoices'.
See Feature-Based Architecture § 4.

### High (1)

`REACT-ARCH-08` — src/libs/format-invoice.ts:1
The extraction was done with **one** consumer. The third-consumer rule never fired.
Fix: the same as REACT-ARCH-06 — return it to the owning feature. Extract again only when
there are three real importers.
See Feature-Based Architecture § 4.

### Medium (1)

`REACT-ARCH-12` — src/features/billing/components/BillingList.tsx
A PascalCase name; the convention is kebab-case for files and directories.
Fix: rename it to billing-list.tsx in the same commit where the file moves.
See Feature-Based Architecture § 4.

### Not reported, and why

- `REACT-ARCH-04` (own alias) and `REACT-ARCH-03` (logic in the barrel) were inside
 `features/billing/`, which goes away entirely through REACT-ARCH-01. Fixing them where they
 are would be wasted work.
- The size of `invoice-row.tsx` (190 lines) has no ID — it goes to Suggestions, if at all.

### Closing

Without `biome.json`, `REACT-ARCH-04`, `-05`, `-06`, `-07` and `-10` depend on human review and
come back in the next PR. Turning on the § 7 rules is the highest-return item — more than
any individual finding above.
```

## What this example demonstrates

| Decision | Where the rule is |
| --- | --- |
| the reading reclassified the whole report (`REACT-ARCH-01`) | `varredura-de-imports.md` § *What the probe does not catch* |
| two findings inside the condemned feature were **not** reported | § 6 — stop when a finding invalidates the next |
| the same file came out with `-06` **and** `-08`, which are different defects | § 4 — import × duplicate × extract |
| the absence of lint became the closing, not a footnote | § 7 |
| the structural finding comes before the interior one | this skill, `## When to use` |
