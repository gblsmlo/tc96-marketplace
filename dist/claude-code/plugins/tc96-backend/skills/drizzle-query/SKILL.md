---
name: drizzle-query
description: Write and fix Drizzle ORM reads on PostgreSQL — query builder × Relational Queries, declaring and wiring `relations()`, folding a per-item lookup (N+1) into one query, many-to-many through a junction table, aggregation, and offset or keyset pagination — citing `DRZ-QUERY-*`, `DRZ-REL-*` and `DRZ-RQB-*` IDs, with an AST self-check and a statement-count proof. Use when the task is a new or slow listing, feed, search or detail endpoint, `db.query.x.findMany` with `with`, a `select` with joins or `groupBy`, paginating, or "with throws / db.query is undefined". Do not use for insert, update, delete, upsert or transactions (drizzle-mutation), for request or response validation with Zod (drizzle-zod), nor to audit existing persistence (drizzle-review).
fonte: "[Drizzle - Reads and Relations](../../docs/drizzle/drizzle-reads-and-relations.md)"
docs:
  - /drizzle-team/drizzle-orm-docs
tags:
  - skill
  - drizzle
  - database
---

# drizzle-query

> **Source of this skill:** [Drizzle - Reads and Relations](../../docs/drizzle/drizzle-reads-and-relations.md) — its § 0 holds the three decision trees, and every rule this skill cites has its body there.
> **API surface:** resolve it through Context7 — `/drizzle-team/drizzle-orm-docs`, topics `select`, `rqb`, `relations`, `joins`. Signatures come from there; the rule and the ID come from the family docs.

A read in Drizzle does exactly what its code says and nothing more: no lazy loading, no hidden join. That makes it predictable, and it also means the two expensive mistakes — a query per item, and a list with no ceiling — are written by hand, one line at a time. This skill exists to catch them before they ship.

---

## When to use

| Situation | Go to |
| --- | --- |
| insert, update, delete, upsert, transaction | `drizzle-mutation` |
| validating a request body, query string or response with Zod | `drizzle-zod` |
| reviewing a persistence layer that already exists | `drizzle-review` |
| declaring a table, index or foreign key; `drizzle-kit` | [Drizzle - Schema and Migrations](../../docs/drizzle/drizzle-schema-and-migrations.md) |
| the route that calls the read | `elysia-build` |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Drizzle - Reads and Relations](../../docs/drizzle/drizzle-reads-and-relations.md) | the trees (§ 0), the rules and the verified behaviour — the one doc this skill needs |
| 2 | [Drizzle ORM](../../docs/drizzle/drizzle-orm.md) § 0 | only when `package.json` shows `drizzle-orm` 1.x — relations and RQB filters differ there |
| 3 | [Drizzle - Schema and Migrations](../../docs/drizzle/drizzle-schema-and-migrations.md) | only when the read needs a new table, index or foreign key |

**Never load the writes or Zod satellites for a read.**

| File | What for |
| --- | --- |
| `references/patterns.md` | seven read shapes worth copying: detail, feed with keyset, many-to-many, parent filtered by child, per-row aggregate, optional filters, the statement-count test |
| `references/antipatterns.md` | the grid with IDs and doc sections |
| `references/id-map.md` | the `DRZ-QUERY-01`–`03`, `DRZ-REL-*`, `DRZ-RQB-*` IDs and where their bodies live |
| `scripts/self-check.sh` | the version line and the query-group AST scan |

---

## Step 0 — Which line is the project on

```bash
grep -E '"drizzle-(orm|kit)"' package.json
```

`0.x` is the stable line the docs describe. `1.0.0-rc`/`beta` means `defineRelations` and object `where` — do not write `relations()` or callback filters there (`DRZ-CORE-01`); resolve those two through Context7.

---

## Step 1 — Three questions before the first line

Answer them in order; each one changes the code you are about to write.

1. **How many tables does the result need?** One → `db.select()`. Several, nested → `db.query.<table>.findMany({ with })`, which issues **one** statement however deep the nesting (`DRZ-RQB-01`). A flat join only when you need control of the join itself. Tree § 0.1.
2. **Will this read run once per item?** A read inside `map`, `for` or `Promise.all` is N+1: fold it into `with`, or into **one** `inArray` query grouped in a `Map` when the data is not a relation (§ 4 of the doc). Tree § 0.2.
3. **Can the result grow with the data?** Then it needs a `limit` and a way to the next page — offset for "page N" over quiet data, keyset for feeds and large tables, always with the primary key as the last sort key. Tree § 0.3.

Relations must be declared on **both** sides (`DRZ-REL-01`) and **registered in the client** — `drizzle({ client, schema })` with the tables *and* the `relations()` (`DRZ-REL-05`). When `with` throws `undefined is not an object (evaluating 'relation.referencedTable')`, that is the cause; fix it before touching any query.

---

## Step 2 — Write it

Start from the closest shape in `references/patterns.md`. Four traps the patterns already avoid:

- **The function's shape:** `db: Database` first, then one typed input object whenever there are two or more inputs, an optional one, or two of the same type — `feed(db, { cursor, pageSize })`, never `feed(db, cursor, pageSize)` (`DRZ-CORE-03`, [Drizzle ORM](../../docs/drizzle/drizzle-orm.md) § 10).
- The RQB `where` is a callback — `(posts, { eq }) => eq(posts.id, id)` — and the operators come from its second argument (`DRZ-RQB-03`).
- `offset` exists only at the root of an RQB call; a nested `with` takes `limit` only (`DRZ-RQB-02`).
- A many-to-many read goes through the junction table in `with` and is flattened afterwards (`DRZ-REL-03`). Filtering the parent by the far side is a join or a subquery in the root `where`, not a `where` inside `with` — that one filters the children.

---

## Step 3 — Prove it

"One query" is a measurable claim, so measure it. Wrap the client's logger to count statements in a test (pattern 7 in `references/patterns.md`) and assert the count stays flat as the list grows — 1 for an RQB read, 2 for a page plus an `inArray` batch. Then:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drizzle-query/scripts/self-check.sh .
bunx tsc --noEmit
```

The self-check flags reads inside loops, a non-callback RQB `where`, a nested `offset`, `extras` without `.as()`, unregistered relations, `sql.raw` with a variable, and listings without a `limit`. Findings marked `candidate` need reading; `high` ones are the defect.

---

## Step 4 — Report

Say what the read does now, the statement count before and after (with the test output), the IDs behind each change, and what you did not verify — a real database's query plan, an index the read now depends on.

---

## Example

A feed loads 20 posts, then the author and the comment count of each one inside `Promise.all`: 41 statements per page. Rewritten as `db.query.posts.findMany({ with: { author: { columns: { id: true, name: true } } }, extras: { commentCount } , limit: 21 })` with a keyset cursor, the page is one statement, the 21st row says whether there is a next page, and a test asserts `statements.length === 1` for 5 posts and for 50. Cites `DRZ-RQB-01`, `DRZ-RQB-04`.
