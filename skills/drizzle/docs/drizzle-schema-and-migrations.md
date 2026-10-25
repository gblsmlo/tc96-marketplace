---
titulo: Drizzle - Schema and Migrations
Link: https://orm.drizzle.team/docs/sql-schema-declaration
tags:
  - typescript
  - backend
  - database
  - orm
  - postgresql
  - agent-context
source: "Official Drizzle ORM documentation — schema declaration and drizzle-kit, cross-checked against the snapshot pinned to the stable version"
verificado-em: 2026-10-24
---

# Drizzle — Schema and Migrations

> `pgTable` · column types · indexes · enums · `drizzle-kit generate`/`migrate`/`push`/`pull`
>
> How the schema is declared in TypeScript, and how it becomes real SQL in the database.

Entry: [Drizzle ORM](drizzle-orm.md) · **Confirm § 0 there before using this note** — the API here is the stable one (0.45.x/0.31.x), not v1-rc.

> **Import convention in this note.** The blocks below assume `pgTable`, `integer`, `varchar`, `timestamp`, `index`, `uniqueIndex`, `primaryKey` already imported from `'drizzle-orm/pg-core'` (§ 1, form 1), except when the block exists precisely to introduce a new import (`pgEnum`, `AnyPgColumn`, `pgSchema`) — then only the new line appears. Each block is an independent illustration.

---

## 1. Declaring a table

`pgTable` accepts three ways of importing the column types. All three produce the same result — the choice is style.

```ts
// Form 1 — functions imported directly
import { pgTable, integer, varchar } from 'drizzle-orm/pg-core'

export const usersTable = pgTable('users', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  name: varchar().notNull(),
  age: integer().notNull(),
  email: varchar().notNull().unique(),
})
```

```ts
// Form 2 — a callback with the `t` namespace
import { pgTable } from 'drizzle-orm/pg-core'

export const usersTable = pgTable('users', (t) => ({
  id: t.integer().primaryKey().generatedAlwaysAsIdentity(),
  name: t.varchar().notNull(),
}))
```

```ts
// Form 3 — wildcard
import * as p from 'drizzle-orm/pg-core'

export const usersTable = p.pgTable('users', { id: p.integer().primaryKey() })
```

**The table must be exported.** `drizzle-kit` imports the schema module and reads what is exported — a table declared and not exported does not exist as far as migration is concerned. `DRZ-CORE-02`.

### 1.1 Column name: TS key × database name

By default, the object key is the column name in the database.

```ts
name: varchar()                    // column "name"
firstName: varchar('first_name')   // column "first_name" — explicit name as 1st arg
```

This matters when the project uses `snake_case` in the database and `camelCase` in TS — declaring every field with an explicit name is tedious, and the alternative is `casing: 'snake_case'` in the `drizzle-kit` configuration (see § 2.1), which converts automatically. The runtime client needs the same option (`drizzle({ client, casing: 'snake_case' })`), or the queries it builds name the camelCase columns.

### 1.2 Column types (PostgreSQL)

| Category | Types |
| --- | --- |
| Numeric | `serial()`, `integer()`, `bigint()`, `smallint()`, `numeric()` |
| Text | `varchar()`, `text()`, `char()` |
| Temporal | `timestamp()`, `date()`, `time()` |
| Boolean | `boolean()` |
| Other | `json()`, `jsonb()`, `uuid()` |

> **Why the examples use `integer().primaryKey().generatedAlwaysAsIdentity()` and not `serial()`.** Both produce an auto-incremented key, but `serial` is Postgres's legacy type (`SERIAL`, behind the scenes a loose sequence, with no consistent implicit `NOT NULL` across versions); `GENERATED ALWAYS AS IDENTITY` is the modern SQL standard (Postgres ≥ 10) and what the official docs recommend in every new example. `serial()` still exists for compatibility with an old schema or the introspection (`drizzle-kit pull`) of a database that already uses it.

All of them accept the column name as the first argument and configuration as an object:

```ts
varchar('first_name', { length: 256 })
varchar({ length: 256 })              // no explicit name: uses the key
```

`json()`/`jsonb()` accept `.$type<T>()` to type the value in TypeScript. **That type is compile-time only** — the database stores any JSON, and nothing checks the shape at runtime. Validate it at the boundary: [Drizzle - Zod](drizzle-zod.md) § 4.

### 1.3 Chainable modifiers

```ts
column: type()
  .primaryKey()
  .notNull()
  .unique()
  .default(value)
  .$default(() => computeAtRuntime())
  .$onUpdate(() => new Date())
  .references(() => otherTable.id)
  .generatedAlwaysAsIdentity()
```

**`.references()` between two normal tables** — the common case, outside the self-reference of § 1.6:

```ts
export const users = pgTable('users', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
})

export const posts = pgTable('posts', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  authorId: integer().notNull().references(() => users.id),
})
```

No type annotation — `AnyPgColumn` is only needed when the table references **itself** (§ 1.6), because then TypeScript's type inference has not finished resolving `users` at the moment `users` is used inside itself.

`.references()` creates the foreign key. `.$default()` runs in the client, at insert time — unlike `.default()`, which becomes `DEFAULT` in the SQL and runs in the database. `.$onUpdate()` also runs in the client, on every `update` that does not set the column itself — and, when the column has no default, on insert too. *Verified:* a `timestamp().$onUpdate(() => new Date())` column with no default is filled by the insert and bumped by the next update.

### 1.4 Indexes and composite keys

Declared in a second-argument function that receives the table and returns an array:

```ts
export const posts = pgTable('posts', {
  id: integer().primaryKey(),
  slug: varchar().notNull(),
  title: varchar({ length: 256 }),
}, (table) => [
  uniqueIndex('slug_idx').on(table.slug),
  index('title_idx').on(table.title),
])
```

A composite primary key goes in the same place:

```ts
export const composite = pgTable('composite', {
  col1: integer(),
  col2: varchar(),
}, (table) => [
  primaryKey({ columns: [table.col1, table.col2] }),
])
```

A `unique()`/`uniqueIndex` is also what an upsert needs: `ON CONFLICT` only observes a real constraint. See [Drizzle - Writes and Transactions](drizzle-writes-and-transactions.md) § 2.

### 1.5 Postgres enum

```ts
import { pgEnum } from 'drizzle-orm/pg-core'

export const rolesEnum = pgEnum('roles', ['guest', 'user', 'admin'])

export const users = pgTable('users', {
  role: rolesEnum().default('guest'),
})
```

The enum is a real database type (`CREATE TYPE roles AS ENUM (...)`), not a TypeScript-only check — `drizzle-kit generate` generates the type's migration.

### 1.6 Self-referencing foreign key

A table that references itself needs an explicit type annotation, because the reference happens before `users` has finished being inferred:

```ts
import type { AnyPgColumn } from 'drizzle-orm/pg-core'

export const users = pgTable('users', {
  id: integer().primaryKey().generatedAlwaysAsIdentity(),
  invitedBy: integer().references((): AnyPgColumn => users.id),
})
```

### 1.7 Reusable columns

A plain object of columns can be spread into several tables — the `timestamps` every table usually wants:

```ts
export const timestamps = {
  createdAt: timestamp().defaultNow().notNull(),
  updatedAt: timestamp().$onUpdate(() => new Date()),
  deletedAt: timestamp(),
}

export const users = pgTable('users', {
  id: integer().primaryKey(),
  ...timestamps,
})
```

### 1.8 Multiple Postgres schemas

When the database organizes tables into schemas (`public`, `auth`, `billing`...):

```ts
import { pgSchema } from 'drizzle-orm/pg-core'

export const authSchema = pgSchema('auth')

export const users = authSchema.table('users', {
  id: integer().primaryKey(),
})
```

### 1.9 File organization

`drizzle.config.ts` points at the schema in two ways:

```ts
schema: './src/db/schema.ts'   // one file
schema: './src/db/schema'      // a folder — drizzle-kit reads every export in it recursively
```

For a small project, one file. For many tables, the folder avoids a file of thousands of lines — without requiring an `index.ts` that re-exports everything by hand, since `drizzle-kit` scans the folder. The runtime client is different: it only knows the object passed as `schema`, so the relational API still needs an aggregate import — see [Drizzle - Reads and Relations](drizzle-reads-and-relations.md) § 2.5.

### 1.10 Rules — `DRZ-SCHEMA-*`

| ID | Rule |
| --- | --- |
| `DRZ-SCHEMA-01` | Every table **MUST** be exported — `drizzle-kit` only sees exports. Alias of `DRZ-CORE-02`. |
| `DRZ-SCHEMA-02` | A self-referencing foreign key **MUST** annotate the return type as `AnyPgColumn`, or TypeScript does not resolve the circular reference. |
| `DRZ-SCHEMA-03` | A column repeated across several tables (timestamps, soft delete) **MUST** be extracted as a reusable object and spread, **NEVER** redeclared in each table. |
| `DRZ-SCHEMA-04` | `.default()` (SQL, runs in the database) and `.$default()` (TS, runs in the client) are **NEVER** confused — they change where the value is computed and what appears in the generated migration. |

---

## 2. `drizzle-kit`: what each command does

| Command | Does |
| --- | --- |
| `generate` | Compares the TS schema against the migration history and writes `migration.sql` + `snapshot.json` in a timestamped folder |
| `migrate` | Applies the migration files not yet applied, comparing against a history table in the database |
| `push` | Applies the difference **directly** to the database, with no file — introspects the current schema, compares, alters |
| `pull` | Introspects an existing database and writes the matching TypeScript schema |
| `studio` | Starts a local proxy that feeds Drizzle Studio (a data-browsing GUI) |
| `check` | Scans the generated migrations for collisions or race conditions between them |
| `up` | Upgrades the snapshot format of old migrations to the current `drizzle-kit` format |

### 2.1 `drizzle.config.ts`

```ts
import { defineConfig } from 'drizzle-kit'

export default defineConfig({
  dialect: 'postgresql',
  schema: './src/db/schema.ts',
  out: './drizzle',
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
  casing: 'snake_case',   // converts camelCase (TS) → snake_case (database) automatically
})
```

`dialect` and `schema` are the only mandatory options — the rest has a sensible default. `casing` is what avoids writing `varchar('first_name')` on every column when the database convention is `snake_case` and the TS one is `camelCase`.

### 2.2 How to migrate: two workflows, for two moments

This is the most misunderstood decision in the tool — both routes are legitimate, for different moments.

```
Does the schema change several times a day, alone, in a prototype/local?
├── YES → drizzle-kit push
│         Applies the difference directly to the database. No migration
│         file, no history. Fast, but no auditable trail.   DRZ-MIG-01
└── NO — it goes to staging/production, or there is more than one dev
    → drizzle-kit generate, then:
      ├── CI/CD runs `drizzle-kit migrate`                  DRZ-MIG-02
      └── Serverless/monolith deploy
          → migrate() called at application boot,
            programmatically, from the runtime.             DRZ-MIG-03

Never both in the same environment for the same schema — push
and generate disagree about what "the current state" is.    DRZ-MIG-04
```

**Workflow A — `push`, for prototyping.**

```bash
npx drizzle-kit push
```

No migration file, no auditable trail. Fast for when the schema changes several times a day and there is no second person or shared environment depending on the history.

**Workflow B — `generate` + `migrate`, for staging/production.**

```bash
npx drizzle-kit generate   # writes drizzle/0000_name/migration.sql
npx drizzle-kit migrate    # applies the pending files
```

It leaves a history reviewable in a PR — the generated `.sql` file can be read before it reaches production, which `push` does not offer.

**Workflow C — programmatic migration, for a serverless deploy.**

```ts
import { drizzle } from 'drizzle-orm/node-postgres'
import { migrate } from 'drizzle-orm/node-postgres/migrator'

const db = drizzle(process.env.DATABASE_URL!)
await migrate(db, { migrationsFolder: './drizzle' })
```

It runs from the code itself, at application boot — without depending on someone running a CLI by hand after the deploy. It is the common form where there is no separate CI step for migration.

### 2.3 Why not mix them

`push` and `generate`/`migrate` disagree about **what the current state is**: `push` compares against the live database; `generate` compares against the file history. Using both in the same environment for the same schema produces a generated migration that `push` already applied, or a `push` undoing a column that a pending migration was still going to create.

The same disagreement happens when someone **edits a migration by hand** without updating its snapshot: the next `generate` diffs from the stale snapshot and may propose SQL that recreates or drops what the hand edit already changed. A journal (`meta/_journal.json`) whose entry count differs from the number of `*_snapshot.json` files is the visible sign.

### 2.4 Rules — `DRZ-MIG-*`

| ID | Rule |
| --- | --- |
| `DRZ-MIG-01` | `push` **MUST** stay restricted to a local/prototype environment with no auditable history required. |
| `DRZ-MIG-02` | Staging and production **MUST** use `generate` + `migrate`, **NEVER** `push`. |
| `DRZ-MIG-03` | In a serverless deploy, the migration **MUST** run through programmatic `migrate()` at boot. |
| `DRZ-MIG-04` | `push` and `generate`/`migrate` **NEVER** coexist in the same environment for the same schema. |
| `DRZ-MIG-05` | Every `pgEnum` **MUST** be treated as a real schema change — changing the enum's values goes through the same `generate`/`migrate` discipline, it is not TypeScript only. |

---

## 3. Antipatterns

| Antipattern | Fix |
| --- | --- |
| Table declared without `export` | export it — `DRZ-SCHEMA-01` |
| `varchar('first_name')` repeated on every field because of the case convention | `casing: 'snake_case'` in the config |
| Timestamps redeclared in each table | a reusable object, spread · `DRZ-SCHEMA-03` |
| `.default()` when the intent was to compute in the client | `.$default()` · `DRZ-SCHEMA-04` |
| `push` in production | `generate` + `migrate` · `DRZ-MIG-02` |
| `push` and `generate` alternating in the same environment | choose one workflow · `DRZ-MIG-04` |
| A hand-edited migration whose snapshot was not updated | regenerate on a clean tree and compare · § 2.3 |
| A self-referencing foreign key without `AnyPgColumn` | annotate the type · `DRZ-SCHEMA-02` |
| A `jsonb().$type<T>()` trusted as a runtime check | validate at the boundary · [Drizzle - Zod](drizzle-zod.md) |

---

## Related

- [Drizzle ORM](drizzle-orm.md) — entry, § 0 on which version these docs document
- [Drizzle - Reads and Relations](drizzle-reads-and-relations.md) — what to do with the schema once declared
- [Drizzle - Writes and Transactions](drizzle-writes-and-transactions.md) — unique constraints and upserts
- `PostgreSQL` — another tc96 note, cited by name

## Sources consulted

Snapshot of the `drizzle-team/drizzle-orm-docs` repository, commit `3e7fe1b3` (2026-03-21, closest to the `drizzle-orm@0.45.2` tag, published on 2026-03-27), verified on 2026-08-16; versions re-checked and the *verified* behaviour executed on 2026-10-24 (`drizzle-orm@0.45.4`, `drizzle-kit@0.31.11`, PGlite):

- `sql-schema-declaration.mdx` — the three import forms, column types, modifiers, indexes, composite key, self-reference, `pgSchema`, reusable columns
- `migrations.mdx` — the workflows and the database-first × codebase-first distinction
- `kit-overview.mdx` — the command table and `drizzle.config.ts`

See [Drizzle ORM](drizzle-orm.md) § 0 for the caveat about the live docs being on the v1-rc line at these same URLs.
