---
nome: drizzle-review
descricao: Review an existing Drizzle and PostgreSQL persistence layer, citing `DRZ-*` IDs, with eleven executable probes for the defects that reading code does not find — use when the task is reviewing a schema, migrations, repositories or queries, checking whether the applied migration matches the schema, finding N+1, a write without `where` or interpolation in raw SQL, or confirming the package's version line before coding. Do not use to write a new schema or query — follow the decision trees in Drizzle ORM § 5 directly, because there is no build skill yet.
tipo: skill
familia: drizzle
idioma: en
fonte: "[Drizzle ORM](../../../knowledge-base/drizzle-orm.md)"
docs:
  - /drizzle-team/drizzle-orm-docs
tags:
  - skill
  - drizzle
  - database
---

# drizzle-review

> **Source of this skill:** [Drizzle ORM](../../../knowledge-base/drizzle-orm.md), which is both the hub and the normative note — `DRZ-CORE-*` lives in its § 6, and the bodies of the other families in the two satellites.
> This skill **does not contain** the text of the rules — it says what to run, in what order to scan and how to report.
> **API surface:** resolve it through Context7 — `/drizzle-team/drizzle-orm-docs`. Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

Contract this skill implements: [Drizzle ORM](../../../knowledge-base/drizzle-orm.md) § 7 ("Contrato de skill").

---

## When to use

Reviewing persistence that **already exists**: schema, migrations, repositories, queries.

| Situation | Go to |
| --- | --- |
| writing a new schema or query | [Drizzle ORM](../../../knowledge-base/drizzle-orm.md) § 5, directly — **there is no build skill yet** |
| modeling, indexes, constraints, RLS in the database | `PostgreSQL` |
| the route that calls the repository | `elysia-build` |
| the suite that should cover this | `bun-test-review` · `test-review` |
| the HTTP contract the route exposes | `http-review` |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Drizzle ORM](../../../knowledge-base/drizzle-orm.md) § 0 | **not optional** — the project's `package.json` decides which relations API applies, not the live docs |
| 2 | [Drizzle ORM](../../../knowledge-base/drizzle-orm.md) § 6 | the citable rules and the family table |
| 3 | [Drizzle ORM](../../../knowledge-base/drizzle-orm.md) § 2 and § 5 | mental model and trees, to tell "wrong" from "different" |
| 4 | [Drizzle - Schema e Migrations](../../../knowledge-base/drizzle-schema-e-migrations.md) | only when the finding touches a table, an index or `drizzle-kit` |
| 5 | [Drizzle - Queries e Relations](../../../knowledge-base/drizzle-queries-e-relations.md) | only when the finding touches a query, `relations`, RQB or a transaction |

**Never load both satellites by default.**

References in this skill:

| File | What for |
| --- | --- |
| `references/sondas.md` | the four probes from the docs, plus the seven the script adds |
| `references/varredura-e-severidade.md` | the order by failure frequency, and the classification |
| `references/relatorio-e-corte.md` | finding format, and what is **not** a finding |
| `references/antipadroes.md` | the grid with IDs — and the rows **without an ID**, which cite the note |
| `references/fechamento.md` | turning a probe into a test, and what requires a product decision |
| `references/mapa-de-ids.md` | the 32 `DRZ-*`: declaration, satellite of the body and section |
| `scripts/sondas.sh` | runs all eleven |
| `scripts/gerar-mapa-de-ids.sh` | regenerates the map from `knowledge-base/drizzle*` |

---

## Step 1 — Probe before reading

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drizzle-review/scripts/sondas.sh src
```

**S1 is the mandatory stop:** if the object passed to `drizzle({ schema })` does not contain the `relations`, `with` throws at runtime and `db.query.x` is `undefined` (`DRZ-REL-05`). With the relational API switched off, **every hand-built read is a consequence** — criticizing each one is noise.

The script prints both lists — what is exported and what is registered — and the comparison is yours.

**S0 comes before everything:** the version line in `package.json` decides which relations API applies.

---

## Step 2 — Scan in the order that fails most

`references/varredura-e-severidade.md`: client and schema boundary → migration → reads that multiply queries → reads without a ceiling → index × predicate → writes and transactions → projection and raw SQL → boundary validation.

**`DRZ-RQB-01` is the rule that pays most:** one read per item inside a `map`/`for` is the most common and most expensive finding.

---

## Step 3 — Classify and report

Blocking: loss of isolation between tenants, `update`/`delete` without `where` (`DRZ-QUERY-04`), `push` in production (`DRZ-MIG-02`), a destructive migration without a rollback.

**Measured cost beats assumed cost.** "This could get slow" with no number and no execution plan is Low, not Medium.

Four-part format, with `file:line`. For a probe, **paste the script's output**.

---

## Step 4 — Closing

1. **Turn a probe into a test.** S1, S2 and S3 become tests that fail on regression: exports × registered schema, journal × snapshots, index × prefix.
2. **Check whether the database already solves it** — `CHECK`, partial unique, exclusion constraint, RLS — before proposing an invariant in the application.
3. **Separate what requires a product decision.** A listing ceiling and a retention policy are not bugs until someone decides. Report them as a **question with options**.
4. **Order by severity**, not by file.
5. **Declare what was not verified.** A probe that did not run — database down, test flag not unlocked — is "not verified", never "no findings".

---

## Example

A tasks repository: probe S1 shows `usersRelations` exported and **absent** from `drizzle({ schema })` — a finding that invalidates the others. After it, S4 points at a listing that calls the aggregate read **once per row** inside `Promise.all` (`DRZ-RQB-01`), and S9 a `.default(crypto.randomUUID)` that freezes the value in the migration's SQL (`DRZ-SCHEMA-04`).

The format and the cut are in `references/relatorio-e-corte.md`.

---

## Related

- [Drizzle ORM](../../../knowledge-base/drizzle-orm.md) — source of this skill: § 0, § 5, § 6, § 7
- [Drizzle - Schema e Migrations](../../../knowledge-base/drizzle-schema-e-migrations.md) · [Drizzle - Queries e Relations](../../../knowledge-base/drizzle-queries-e-relations.md) — the satellites
- `PostgreSQL` — what the ORM does not dispense with
- · — when the finding is about strategy
- `react-review` — where the finding format comes from
