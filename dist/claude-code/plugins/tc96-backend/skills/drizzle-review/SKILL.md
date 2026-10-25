---
name: drizzle-review
description: Review an existing Drizzle ORM and PostgreSQL persistence layer — schema, migrations, repositories, queries, transactions and the Zod schemas at the route boundary — citing `DRZ-*` IDs, with executable probes (version line, client registration, snapshot chain, push in a deploy path) and an AST scan for what reading misses — use when the task is reviewing or approving a PR that touches persistence, auditing a repository's data layer, checking whether the applied migrations match the schema, or hunting N+1, a write without `where`, a lost update, raw SQL with user input, or a body schema that lets a caller set their own role. Do not use to write new code — reads are drizzle-query, writes and transactions drizzle-mutation, request and response schemas drizzle-zod.
source: "[Drizzle ORM](../../docs/drizzle/drizzle-orm.md)"
docs:
  - /drizzle-team/drizzle-orm-docs
tags:
  - skill
  - drizzle
  - database
  - review
---

# drizzle-review

> **Source of this skill:** [Drizzle ORM](../../docs/drizzle/drizzle-orm.md), the family hub — `DRZ-CORE-*` lives in its § 6, and every other family's body lives in one of four satellites. `references/id-map.md` says which, for every ID.
> This skill **does not contain** the text of the rules — it says what to run, in what order to scan and how to report.
> **API surface:** resolve it through Context7 — `/drizzle-team/drizzle-orm-docs`. Signature, option and per-version behaviour come from there; the rule and the ID come from the family docs.

---

## When to use

Reviewing persistence that **already exists**: schema, migrations, repositories, queries, the Zod schemas that feed them.

| Situation | Go to |
| --- | --- |
| writing or fixing a read | `drizzle-query` |
| writing or fixing an insert, update, delete or transaction | `drizzle-mutation` |
| writing request or response schemas | `drizzle-zod` |
| modeling, indexes, constraints, RLS in the database | `PostgreSQL` |
| the suite that should cover this | `bun-test-review` · `test-review` |
| the HTTP contract the route exposes | `http-review` |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | `references/id-map.md` | every `DRZ-*` and the satellite section that holds its body — **not optional**, it decides what else to open |
| 2 | [Drizzle ORM](../../docs/drizzle/drizzle-orm.md) § 0 | only when the version line (P0) is not 0.x |
| 3 | the one satellite a finding touches | only when a finding needs its rule's body: [Schema](../../docs/drizzle/drizzle-schema-and-migrations.md), [Reads](../../docs/drizzle/drizzle-reads-and-relations.md), [Writes](../../docs/drizzle/drizzle-writes-and-transactions.md), [Zod](../../docs/drizzle/drizzle-zod.md) |

**Never load the satellites by default** — the probes and the ID map say which one a finding needs.

| File | What for |
| --- | --- |
| `references/probes.md` | P0–P8: how each runs, what it reveals, what the scan does not see |
| `references/scan-and-severity.md` | the scan order by failure frequency, and the severity table |
| `references/report-and-cut.md` | the finding format, and finding × opinion |
| `references/antipatterns.md` | the grid with IDs — and the rows **without an ID**, which cite a section |
| `references/closing.md` | turning a probe into a test, what requires a product decision |
| `references/id-map.md` | generated: the `DRZ-*` IDs, where each is declared, and the section of its body |
| `scripts/probes.sh` | runs P0–P7 |
| `scripts/drizzle-scan.mjs` | the AST scan behind P1 and P4–P7 — the build skills' self-checks call it too |

---

## Step 1 — Probe before reading

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drizzle-review/scripts/probes.sh .
```

**P0 comes first:** the version line decides which relations API and which Zod import apply.

**P1 is the mandatory stop:** if the object passed to `drizzle({ schema })` lacks the `relations`, `with` throws at runtime (`DRZ-REL-05`). With the relational API switched off, **every hand-built read is a consequence** — report P1 first and do not criticize each one.

**P2 needs one more command to conclude:** `drizzle-kit generate` on a clean tree must propose nothing.

The AST scan marks each finding `high` or `candidate`. A `candidate` is a pointer for reading, not a finding — it becomes one only when the code confirms it. If the scan printed `SKIPPED`, those probes are **not verified**.

---

## Step 2 — Scan in the order that fails most

`references/scan-and-severity.md`: client and schema boundary → migrations → reads that multiply queries → reads without a ceiling → index × predicate → writes and transactions → projection and raw SQL → boundary validation.

**`DRZ-RQB-01` is the rule that pays most:** one read per item inside a `map`/`for` is the most common and most expensive finding. **`DRZ-TX-05` is the one reading misses most:** a balance read, checked in JavaScript and then updated, passes every single-request test.

---

## Step 3 — Classify and report

Blocking: loss of isolation between tenants or owners, `update`/`delete` without `where` (`DRZ-QUERY-04`), a user value in `sql.raw` (`DRZ-QUERY-02`), `push` in production (`DRZ-MIG-02`), a destructive migration without a rollback, a body schema that lets the caller set `role` or an owner (`DRZ-ZOD-03`).

**Measured cost beats assumed cost.** "This could get slow" with no number and no execution plan is Low, not Medium.

Four-part format, with `file:line` (`references/report-and-cut.md`). For a probe, **paste the script's output**. **Never invent an ID** — a defect with no rule cites the doc section, or goes under "Suggestions (no rule)".

---

## Step 4 — Closing

1. **Turn a probe into a test** — registration, a clean `generate`, a statement count.
2. **Check whether the database already solves it** — `UNIQUE`, `CHECK`, a foreign key, a partial unique index, RLS — before proposing an invariant in the application.
3. **Separate what requires a product decision** — a listing ceiling, a retention policy, who may edit whose rows. Report them as a **question with options**.
4. **Order by severity**, not by file.
5. **Declare what was not verified** — a probe that did not run is "not verified", never "no findings".

---

## Example

A tasks repository: P1 shows `usersRelations` exported and **absent** from `drizzle({ schema })` — a finding that invalidates the others, reported first. After it, P5 points at a listing that calls the aggregate read once per row inside `Promise.all` (`DRZ-RQB-01`), P6 at a `tx.update` preceded by a read of the same balance with the check in JavaScript (`DRZ-TX-05`), and P7 at `createInsertSchema(tasks)` used whole as the body, so a caller can set `ownerId` (`DRZ-ZOD-03`, blocking). The format and the cut are in `references/report-and-cut.md`.
