---
titulo: Drizzle ORM
Link: https://orm.drizzle.team/docs/overview
tags:
  - typescript
  - backend
  - database
  - orm
  - postgresql
  - reference
  - agent-context
source: "Official Drizzle ORM documentation — orm.drizzle.team, cross-checked against the docs-repository snapshot at the stable npm tag"
verificado-em: 2026-10-24
---
# Drizzle ORM — guided reference (fundamentals)

> **What this note is.** The single entry point for Drizzle ORM in this family: for a person looking something up, and for coding agents that generate or review database access. It is not a linear summary of the docs — it is a **router**, with the mental model that makes the rest make sense and rules citable by ID.
>
> **Scope: fundamentals.** Enough for a correct schema, query builder, relations, transactions, migrations and Zod boundary. It is not an exhaustive reference of every dialect and driver, nor of MySQL/SQLite/SingleStore/MSSQL — the focus is **PostgreSQL**.
>
> **What it is not.** It does not replace the source. When they diverge, [orm.drizzle.team/docs](https://orm.drizzle.team/docs/overview) wins — **with one important caveat, see § 0**.

See [Sources consulted](#sources-consulted) and, before anything else, [Verification notes](#verification-notes).

---

## 0. Read this first: which version these docs document

**The live public docs do not document the version that `npm install drizzle-orm` installs today.**

| | What `npm view <pkg> dist-tags` returns (2026-10-24) | What orm.drizzle.team/docs shows at the same URLs |
| --- | --- | --- |
| `drizzle-orm` | **0.45.4** (`latest`) | content of `1.0.0-rc.5` |
| `drizzle-kit` | **0.31.11** (`latest`) | same |
| `drizzle-zod` | **0.8.3** (`latest`) | same, with a deprecation notice |

The site does not version by path — `/docs/rqb` and `/docs/get-started-postgresql` were **rewritten in place** for the `v1.0.0-rc` line, which installs with `npm i drizzle-orm@rc`. An agent that reads the live URL today and writes code from it produces a project that **does not compile** against what `npm install drizzle-orm` actually brings.

**These docs document the stable API (0.45.x / 0.31.x / 0.8.x)** — the one that runs in any project created with `npm i drizzle-orm` without a tag. It was verified by cross-checking the published package (`npm view` and the `.d.ts` files) against the docs-repository snapshot at the tag matching the stable release, and the behaviour marked *verified* was executed against `drizzle-orm@0.45.4`, `drizzle-zod@0.8.3` and `zod@4.6.7` on PGlite (PostgreSQL compiled to WASM). See [Verification notes](#verification-notes).

> **Before following any link in these docs to orm.drizzle.team**: confirm the project is not on the `@rc`/`@beta` tag. If it is, the relations API in this note **does not apply** — see § 0.1.

### 0.1 What changes in v1, in short

The change that breaks code, not a cosmetic one: the **relations** API was rewritten.

| | Stable (these docs) | v1 (rc) |
| --- | --- | --- |
| Declaring a relation | `relations(table, ({ one, many }) => ({...}))`, one call per table | `defineRelations(schema, (r) => ({...}))`, in a single place |
| RQB filter | `where: (t, { eq }) => eq(t.col, v)` — a callback with operators | `where: { col: { eq: v } }` — an object |
| Zod schemas | the separate `drizzle-zod` package, current | **`drizzle-zod` deprecated** — generation is native, imported from `drizzle-orm/zod` |

If the project moves to `v1`, the relations and RQB sections of [Drizzle - Reads and Relations](drizzle-reads-and-relations.md) and the import line of [Drizzle - Zod](drizzle-zod.md) must be revised — the rest (schema declaration, insert/update/delete, transactions) diverges little.

### 0.2 How to check, in one command

```bash
grep -E '"drizzle-(orm|kit|zod)"' package.json
```

A version starting with `0.` is the stable line and these docs apply. `1.0.0-rc` or `1.0.0-beta` is v1: use these docs for everything except relations, RQB filters and the Zod import, and resolve those through Context7 (`/drizzle-team/drizzle-orm-docs`).

---

## 1. How to use these docs

### For a person

Read § 2 once. Use § 5 to find the satellite for the question at hand. § 4 is the index.

### For a coding agent

| Step | Load | When |
| --- | --- | --- |
| 1 | § 0.2 of this note — the one-line version check | always, before writing or judging code |
| 2 | the one satellite § 5 points to | the question decides it, not the file being edited |
| 3 | § 6 of this note | only to cite a `DRZ-CORE-*` ID or to see the full family table |

**Context economy rule:** never open two satellites by default. Each satellite carries its own decision tree, rules and antipatterns, so the task at hand needs exactly one of them.

---

## 2. Mental model

Four statements.

**1. Drizzle is not a data framework — it is a thin layer over SQL.** The docs say it literally: *"if you know SQL, you know Drizzle"*. It introduces no query language of its own (like Prisma's `where: { AND: [...] }`) — what you write is a composition of functions that generate SQL, and the result is predictable because it is **almost SQL with types**. That is the opposite of Prisma: there you learn Prisma's API on top of SQL; here, SQL knowledge transfers directly.

**2. There are two read APIs, and they solve different problems.** (From here on, **RQB** = Relational Queries — the acronym the `DRZ-RQB-*` IDs use.) The *query builder* (`db.select().from(...)`) is explicit SQL — full control, one `JOIN` at a time, visible in the generated query. *Relational Queries* (`db.query.table.findMany({ with: {...} })`) solve the common case of fetching an entity with its nested relations, **always in a single SQL query** — even when the result looks like N tables nested as JSON. The docs call this the central property for serverless databases, where every round trip costs network latency.

**3. The TypeScript schema is the source of truth — and migration files are a choice, not an obligation.** `drizzle-kit generate` compares the declared schema against the migration history and writes SQL; `drizzle-kit push` applies the difference directly, with no file. They are two legitimate flows for different moments of a project, not a right one and a wrong one. See [Drizzle - Schema and Migrations](drizzle-schema-and-migrations.md) § 2.

**4. Nothing happens that is not in the generated SQL.** No lazy loading, no hidden N+1, no query fired by reading a property. A relation is only fetched when it is in `with`; a `JOIN` only exists when it was written; a write only touches the rows its `where` names — and with no `where`, that is every row. The price of this predictability is that **you** decide the shape of the query — the tool does not decide for you.

---

## 3. Package boundaries

| Package | Contains | Note |
| --- | --- | --- |
| `drizzle-orm` | schema, query builder, RQB, `relations()`, transactions — the runtime | zero dependencies; imports per dialect (`drizzle-orm/pg-core`) and per driver (`drizzle-orm/node-postgres`, `drizzle-orm/postgres-js`, `drizzle-orm/bun-sql`, `drizzle-orm/pglite`) |
| `drizzle-kit` | migration CLI: `generate`, `migrate`, `push`, `pull`, `studio`, `check`, `up` | dev dependency; does not go into the production bundle |
| `drizzle-zod` | `createSelectSchema`/`createInsertSchema`/`createUpdateSchema`/`createSchemaFactory` from a table | **a separate package, deprecated for v1** — see § 0.1 and [Drizzle - Zod](drizzle-zod.md) |

```bash
npm i drizzle-orm pg
npm i -D drizzle-kit @types/pg
```

This command installs the stable line. **`@rc`/`@beta` install v1**, and the relations API in these docs does not apply to them.

---

## 4. API map

| Area | Covers | Satellite |
| --- | --- | --- |
| Connection | `drizzle(url)`, `drizzle({ connection })`, `drizzle({ client })` | this note, § 8 |
| Schema declaration | `pgTable`, column types, modifiers, indexes, enums, multi-schema | [Drizzle - Schema and Migrations](drizzle-schema-and-migrations.md) |
| Migration | `drizzle-kit generate`/`migrate`/`push`/`pull`, `drizzle.config.ts`, `migrate()` at runtime | [Drizzle - Schema and Migrations](drizzle-schema-and-migrations.md) |
| Reads | `select`, `where`, joins, aggregation, subquery, CTE, pagination | [Drizzle - Reads and Relations](drizzle-reads-and-relations.md) |
| Relations | `relations()`, `one`/`many`, many-to-many, `relationName`, wiring into the client | [Drizzle - Reads and Relations](drizzle-reads-and-relations.md) |
| Relational Queries | `db.query.table.findMany`/`findFirst`, `with`, `columns`, `where` callback, `extras`, prepared statements | [Drizzle - Reads and Relations](drizzle-reads-and-relations.md) |
| Writes | `insert`, `returning`, upsert, insert-from-select, `update`, `delete` | [Drizzle - Writes and Transactions](drizzle-writes-and-transactions.md) |
| Transactions | `db.transaction`, `tx.rollback()`, savepoints, isolation | [Drizzle - Writes and Transactions](drizzle-writes-and-transactions.md) |
| Boundary validation | `drizzle-zod`, request and response schemas, coercion | [Drizzle - Zod](drizzle-zod.md) |

---

## 5. Which satellite answers the question

Each decision tree lives in the satellite that owns its context, next to the rules it leads to.

| The question | Satellite and section |
| --- | --- |
| query builder or Relational Queries? one query or several? how do I paginate? | [Drizzle - Reads and Relations](drizzle-reads-and-relations.md) § 0 |
| plain insert or upsert? does this need a transaction? how do I clear a field? | [Drizzle - Writes and Transactions](drizzle-writes-and-transactions.md) § 0 |
| how do I migrate: generate + migrate, or push? | [Drizzle - Schema and Migrations](drizzle-schema-and-migrations.md) § 2.2 |
| I need to validate data entering or leaving the database — where, and with which schema? | [Drizzle - Zod](drizzle-zod.md) § 0 |
| how do I declare a table, a column, an index, a foreign key? | [Drizzle - Schema and Migrations](drizzle-schema-and-migrations.md) § 1 |

---

## 6. Normative rules

Rules citable by ID. `MUST`/`NEVER` are normative.

### `DRZ-CORE-*` — foundation

| ID | Rule |
| --- | --- |
| `DRZ-CORE-01` | Generated code **MUST** assume the stable line (`drizzle-orm` with no tag), **NEVER** the v1-rc API of `defineRelations`/object `where`, unless it is explicitly confirmed that the project is on `@rc`/`@beta`. |
| `DRZ-CORE-02` | Every table **MUST** be exported from the schema module — `drizzle-kit` only sees what is exported. |
| `DRZ-CORE-03` | A data-access function **MUST** take the database as its first positional parameter, typed `db: Database`, and its input as **one typed object** whenever it has two or more inputs, an optional input, or two inputs of the same type — **NEVER** several positional inputs after `db`. *Added 2026-10-25, house convention; § 10.* |

### `DRZ-RQB-*` — Relational Queries

| ID | Rule |
| --- | --- |
| `DRZ-RQB-01` | A read that nests more than one related table **MUST** use `db.query.table.findMany`/`findFirst` with `with`, **NEVER** N separate calls — RQB guarantees a single SQL query. |
| `DRZ-RQB-02` | `offset` **MUST** stay at the root level only — it does not exist in a nested `with`. |

### `DRZ-MIG-*` — migration

| ID | Rule |
| --- | --- |
| `DRZ-MIG-01` | `push` **MUST** stay restricted to a local/prototype environment with no auditable history required. |
| `DRZ-MIG-02` | Staging and production **MUST** use `generate` + `migrate`, **NEVER** `push`. |
| `DRZ-MIG-03` | In a serverless deploy, the migration **MUST** run through programmatic `migrate()` at boot. |
| `DRZ-MIG-04` | `push` and `generate`/`migrate` **NEVER** coexist in the same environment for the same schema. |

### `DRZ-ZOD-*` — validation boundary

| ID | Rule |
| --- | --- |
| `DRZ-ZOD-01` | Validation of a table row **MUST** derive from `createInsertSchema`/`createSelectSchema`/`createUpdateSchema`, **NEVER** a hand-written Zod schema duplicating the columns. |

### Full families in the satellites

| Family | Body in |
| --- | --- |
| `DRZ-SCHEMA-*` · `DRZ-MIG-*` (full body) | [Drizzle - Schema and Migrations](drizzle-schema-and-migrations.md) |
| `DRZ-QUERY-01`–`03` · `DRZ-REL-*` · `DRZ-RQB-*` (full body) | [Drizzle - Reads and Relations](drizzle-reads-and-relations.md) |
| `DRZ-QUERY-04`–`07` · `DRZ-TX-*` | [Drizzle - Writes and Transactions](drizzle-writes-and-transactions.md) |
| `DRZ-ZOD-*` (full body) | [Drizzle - Zod](drizzle-zod.md) |

---

## 7. Skill contract

```
ALWAYS:   Drizzle ORM.md § 0.2 (which version) — NOT OPTIONAL

drizzle-query     → Drizzle - Reads and Relations.md
drizzle-mutation  → Drizzle - Writes and Transactions.md
drizzle-zod       → Drizzle - Zod.md
drizzle-review    → the one satellite the finding touches, by the ID map

WHEN DECLARING A TABLE or RUNNING drizzle-kit:
          Drizzle - Schema and Migrations.md

NEVER:    follow a link to orm.drizzle.team without confirming
          first that the project is not on @rc/@beta
          load two satellites "just in case"
```

### Invariants the skills must enforce

1. **Check the version before generating code.** The project's `package.json` decides which relations API and which Zod import apply — not the live docs.
2. **The source wins, with the caveat of § 0.** A divergence between these docs and the **stable** docs is a bug in these docs. A divergence between these docs and the **live** docs may just be v1 announcing itself early.
3. **`push` never in production.** `DRZ-MIG-02` is the rule that saves the most incidents.
4. **A write without `where` is a write to every row.** `DRZ-QUERY-04`.
5. **Do not duplicate a table's shape in Zod by hand.** `DRZ-ZOD-01`.
6. **`db` first, then one input object.** `DRZ-CORE-03` — two ids of the same type cannot swap places silently.

---

## 8. Connecting to the database

Three forms, the same for `node-postgres` and `postgres-js` — only the import subpath changes.

```ts
// 1 — a connection string directly
import { drizzle } from 'drizzle-orm/node-postgres'
const db = drizzle(process.env.DATABASE_URL!)

// 2 — a configuration object, when an extra option is needed (ssl, for example)
const db = drizzle({
  connection: { connectionString: process.env.DATABASE_URL!, ssl: true },
})

// 3 — a driver instantiated outside (your own pool, reused across modules)
import { Pool } from 'pg'
const pool = new Pool({ connectionString: process.env.DATABASE_URL! })
const db = drizzle({ client: pool })
```

Export the client's type once, from the module that creates it, and use it in every data-access signature:

```ts
export const db = drizzle({ client: pool, schema })
export type Database = typeof db
```

Form 3 is the one to use when the project already manages the `Pool`/client somewhere else (a connection singleton, for example) and only wants Drizzle to draw on top of it — without it, `drizzle(url)` creates and manages the pool by itself.

**To use Relational Queries, pass the schema too** — `drizzle({ client, schema })`, with the tables **and** the `relations()` in that object. See [Drizzle - Reads and Relations](drizzle-reads-and-relations.md) § 2.5.

**A real difference between the two main drivers, which the docs record:** `postgres.js` uses **prepared statements by default**, which may need to be switched off behind a pooler in AWS/serverless environments; `node-postgres` accepts the optional `pg-native` addon for a performance gain.

**For tests, PGlite gives a real PostgreSQL in-process** (`drizzle-orm/pglite` with `@electric-sql/pglite`), with no server to start — a fresh database per test file, and a `logger` that counts the statements a function issues. *Verified* on `drizzle-orm@0.45.4` with `@electric-sql/pglite@0.3.16`.

---

## 9. Bridges to the stack

| Scenario | Use |
| --- | --- |
| Connection on the Bun runtime | `drizzle-orm/node-postgres`, `drizzle-orm/postgres-js` and the native `drizzle-orm/bun-sql` work under Bun — the runtime side is in `Bun - Dados e Persistência` |
| Hono/Elysia backend | `db` instantiated once and imported by the handlers — the singleton pattern |
| Route input validation | a schema narrowed from `createInsertSchema` feeding the route validator — [Drizzle - Zod](drizzle-zod.md) § 5; the route side is in `Elysia - Schema e Eden` and `Hono - Validação e RPC` |
| A heavier alternative | `Prisma` — a larger abstraction layer, more opinionated migration, without the "explicit SQL" philosophy |
| A thinner alternative | `Knex.js` — a query builder with no types generated from the schema and no RQB |

**Why Drizzle instead of Prisma in this stack:** `Bun - Dados e Persistência` records the criterion — "migration and type generation are what you buy with an ORM", and Drizzle delivers that "while still letting you write SQL", which matches the SQL-first philosophy of the house: less abstraction of its own, more explicit control.

---

## 10. The shape of a data-access function

```ts
export type PublishPostInput = { postId: number; authorId: number }

export async function publishPost(db: Database, { postId, authorId }: PublishPostInput) {
  // …
}

await publishPost(db, { postId: 10, authorId: 3 })
```

`DRZ-CORE-03`: the database comes first, positional, as `db: Database`; everything else arrives as one typed object, exported so the handler and the tests reuse it.

| Why the object | What it prevents |
| --- | --- |
| Inputs of the same type are named at the call site | `publishPost(db, authorId, postId)` compiles and acts on the wrong row; `transfer(db, key, toId, fromId, amount)` moves money the wrong way |
| Optional inputs need no placeholder | `feed(db, undefined, 20)`; defaults live in the destructuring: `{ cursor = null, pageSize = 20 }: FeedInput = {}` |
| A new input does not shift positions | every call site breaking, or worse, still compiling with a shifted meaning |
| The validated body or query is already an object | unpacking `z.infer<typeof schema>` into positions in the handler — `listPosts(db, parsed)` passes it whole |
| `ids.map(fn)` passes the index as the second argument | a positional function used as a callback reading the index as an id |

Why `db` stays outside the object: it is the execution context, not input. Keeping it separate keeps the function's data in one place and its dependency in another.

| Stays positional | Becomes an object |
| --- | --- |
| a single required input with one obvious meaning — `getPost(db, slug)`, `ensureTag(db, name)` | two or more inputs, any optional input, two inputs of the same type, a boolean flag |

The object's costs are small and known: an unknown key is rejected only in an object literal (a variable with extra keys passes), and a destructuring default applies to `undefined`, not to `null`. Allocation is irrelevant next to a database round trip.

---

## Related

- [Drizzle - Schema and Migrations](drizzle-schema-and-migrations.md) — declaring tables, `drizzle-kit`
- [Drizzle - Reads and Relations](drizzle-reads-and-relations.md) — select, relations, RQB
- [Drizzle - Writes and Transactions](drizzle-writes-and-transactions.md) — insert, upsert, update, delete, transactions
- [Drizzle - Zod](drizzle-zod.md) — schemas for the route boundary
- `PostgreSQL` · `Bun - Dados e Persistência` · `Prisma` · `Knex.js` — other tc96 notes, cited by name

## Sources consulted

Verified on **2026-08-16**, versions re-checked on **2026-10-24**:

- [Overview](https://orm.drizzle.team/docs/overview) · [Get Started PostgreSQL](https://orm.drizzle.team/docs/get-started-postgresql) — **live content already on the v1-rc line**, see § 0
- `npm view drizzle-orm dist-tags`, `npm view drizzle-kit dist-tags`, `npm view drizzle-zod dist-tags` — published stable versions (2026-10-24: 0.45.4 / 0.31.11 / 0.8.3; `rc` at 1.0.0-rc.5)
- `drizzle-orm@0.45.2/relations.d.ts` — confirms that the stable export is `relations()`, not `defineRelations`
- the `drizzle-orm@1.0.0-rc.5` tarball — ships `zod.js`/`zod.d.ts`, the native replacement for `drizzle-zod`
- Snapshot of the `drizzle-team/drizzle-orm-docs` repository, commit `3e7fe1b3` (2026-03-21, closest to the `0.45.2` tag of 2026-03-27): `overview.mdx`, `get-started-postgresql.mdx`, `sql-schema-declaration.mdx`, `relations.mdx`, `rqb.mdx`, `select.mdx`, `insert.mdx`, `update.mdx`, `delete.mdx`, `transactions.mdx`, `migrations.mdx`, `kit-overview.mdx`, `zod.mdx`, `relations-v1-v2.mdx`
- A playground project (`drizzle-orm@0.45.4`, `drizzle-kit@0.31.11`, `drizzle-zod@0.8.3`, `zod@4.6.7`, PGlite 0.3.16, Bun 1.4.3) where every claim marked *verified* was executed

## Verification notes

- **The live docs are not the stable docs.** `orm.drizzle.team/docs/rqb` and `/docs/get-started-postgresql`, accessed on 2026-08-16, show `defineRelations()` and `npm i drizzle-orm@rc` — content of the `1.0.0-rc` line. `npm view drizzle-orm dist-tags` on 2026-10-24 still shows `latest: 0.45.4`. The site rewrites URLs in place, with no versioning by path; the only reliable way to get the stable content was the docs-repository snapshot at a tag before the change.
- **`relations()` (lowercase, with `one`/`many` in the callback) is the API the published package exports**, confirmed by reading `relations.d.ts`. `defineRelations()` does not exist in that package.
- **`drizzle-zod` is marked deprecated from `1.0.0-beta.15`**, in favour of native schema generation inside `drizzle-orm` (`drizzle-orm/zod`). This **does not affect the stable package today** — `drizzle-zod@0.8.3` remains the right answer, and it declares `zod: ^3.25.0 || ^4.0.0` as a peer.
- **Two claims of the previous Portuguese notes were wrong, and are corrected in the satellites:** `tx.rollback()` does not end the transaction quietly — the awaited `db.transaction()` rejects with `TransactionRollbackError`; and an inner transaction (savepoint) only spares the outer one when its rejection is caught. See [Drizzle - Writes and Transactions](drizzle-writes-and-transactions.md) § 5.
- **Not verified in this round:** the MySQL, SQLite, SingleStore, MSSQL and CockroachDB dialects; managed drivers (Neon, Supabase, PlanetScale, Xata, Vercel Postgres); `drizzle-kit studio`/`check`/`up` in detail; `drizzle-seed`. Out of the agreed fundamentals scope.
