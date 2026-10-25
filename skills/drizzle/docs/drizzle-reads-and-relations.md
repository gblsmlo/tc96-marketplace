---
titulo: Drizzle - Reads and Relations
Link: https://orm.drizzle.team/docs/select
tags:
  - typescript
  - backend
  - database
  - orm
  - postgresql
  - agent-context
source: "Official Drizzle ORM documentation — select, relations and RQB, cross-checked against the snapshot pinned to the stable version"
verificado-em: 2026-10-24
---

# Drizzle — Reads and Relations

> `select` · filters, joins, aggregation, subquery, CTE · pagination · `relations()` · Relational Queries (`db.query`) · prepared statements
>
> How to read data, how to declare that tables relate, and how to fetch all of it in a single query.

Entry: [Drizzle ORM](drizzle-orm.md) · **Confirm § 0 there before using this note** — the relations API here is the stable one (`relations()` + `one`/`many`), not v1-rc's `defineRelations()`.

> **Import convention in this note.** To avoid repeating the same line in every block, the examples assume, unless stated otherwise: `sql`, `eq`, `ne`, `lt`, `lte`, `gt`, `gte`, `and`, `or`, `not`, `inArray`, `asc`, `desc`, `count`, `sum`, `avg`, `max`, `min` and `relations` imported from `'drizzle-orm'`. Each block is an independent illustration — variable names do not persist from one block to the next.

---

## 0. Decision trees

### 0.1 Query builder or Relational Queries?

```
Does the read need data from MORE THAN ONE related table
(post + author + comments, for example)?
├── NO → plain query builder. select solves it alone;
│        RQB gains nothing here.
└── YES
    └── Do you need to control exactly the shape of the JOIN
        (semi-join, self-join, complex per-row aggregation)?
        ├── YES → query builder with explicit leftJoin/innerJoin
        └── NO → db.query.table.findMany({ with: {...} })
                 One query, the result already nested.
                 DRZ-RQB-01
```

### 0.2 One query or several?

```
Is the read about to run once per item of a list
(inside map, for, forEach, Promise.all)?
├── NO → one query, as decided in 0.1
└── YES — that is N+1: one query for the list, N for the items
    ├── the items are a relation of the list's rows
    │   → fold them into the parent read with `with`       DRZ-RQB-01
    └── the shape does not fit `with` (an aggregate per row,
        a table with no declared relation)
        → ONE second query with inArray(ids), grouped in a Map  § 4
```

*Verified:* five posts and a per-row author lookup inside `Promise.all` issue six statements; the same read with `with: { author: true }` issues one, even with `columns`, `extras` and a nested `limit`.

### 0.3 How is the list bounded?

```
Can the list grow with the data (feed, search, admin listing)?
├── NO (a fixed set: enum-like table, a user's handful of settings) → no limit needed
└── YES → it needs a limit, and a way to get the next page
    ├── the user jumps to page N, the data barely moves → limit + offset   § 5.1
    └── infinite scroll, a large or fast-moving table   → keyset (cursor)   § 5.2
```

---

## 1. Query builder: `select`

```ts
const result = await db.select().from(users)
```

**Even without arguments, `select()` lists explicit columns, never `SELECT *`** — the docs are explicit about this: the column order in the result is guaranteed by the declared order, which `SELECT *` does not guarantee across migrations.

### 1.1 Partial selection and SQL expressions

```ts
await db.select({
  id: users.id,
  name: users.name,
}).from(users)

// an arbitrary expression, with an explicit type
await db.select({
  id: users.id,
  lowerName: sql<string>`lower(${users.name})`,
}).from(users)
```

### 1.2 Filters

```ts
await db.select().from(users).where(eq(users.id, 42))
await db.select().from(users).where(and(eq(users.id, 42), eq(users.name, 'Dan')))
await db.select().from(users).where(or(eq(users.id, 1), eq(users.id, 2)))
await db.select().from(users).where(not(eq(users.id, 42)))
await db.select().from(users).where(inArray(users.id, [1, 2, 3]))
```

The operators are **imported functions**, not chained methods — `eq(column, value)`, not `column.eq(value)`. That is what makes `where` compose: `and(eq(...), or(eq(...), eq(...)))` is just functions inside functions.

`eq` covers equality; the rest of the comparison family has the identical shape — `lt`, `lte`, `gt`, `gte(column, value)`, `ne` (not equal), all imported from the same `'drizzle-orm'`. `and()`/`or()` skip `undefined` arguments, which is how an optional filter composes: `and(eq(posts.published, true), tag ? eq(tags.name, tag) : undefined)`.

### 1.3 Ordering and limit

```ts
await db.select().from(users).orderBy(users.name)      // asc is the default; the column alone is enough
await db.select().from(users).orderBy(desc(users.name))
await db.select().from(users).limit(10).offset(10)
```

### 1.4 Joins

```ts
await db
  .select()
  .from(countries)
  .leftJoin(cities, eq(cities.countryId, countries.id))
  .where(eq(countries.id, 10))
```

`leftJoin`, `innerJoin`, `rightJoin`, `fullJoin` follow the same shape: the join condition is the second argument, written with the same `eq` as `where`. The result is **flat** — one row per joined pair, `{ countries: ..., cities: ... }` — and a one-to-many join repeats the parent once per child. When the result must be nested, that is the case for RQB (§ 3).

### 1.5 Aggregation

```ts
await db.select({ value: count() }).from(users)
await db.select({ value: sum(users.age) }).from(users)

await db.select({
  age: users.age,
  total: sql<number>`cast(count(${users.id}) as int)`,
})
  .from(users)
  .groupBy(users.age)
```

`having()` filters after `groupBy`, with the same syntax as `where`. For a plain count with a filter, `db.$count(table, filter)` returns a number. *Verified:* `db.$count(posts, eq(posts.published, true))` returns `5` on five published rows.

### 1.6 Subquery and CTE

```ts
// subquery
const sq = db.select().from(users).where(eq(users.id, 42)).as('sq')
const result = await db.select().from(sq)

// CTE (WITH)
const cte = db.$with('sq').as(db.select().from(users).where(eq(users.id, 42)))
const result2 = await db.with(cte).select().from(cte)
```

### 1.7 `sql` for what the query builder does not express

```ts
await db.select().from(users).where(sql`lower(${users.name}) = 'aaron'`)
```

Every value interpolated inside `` sql`...` `` is **parameterized automatically** — the template literal does not concatenate strings, it builds the query with placeholders. The exception is `sql.raw(text)`, which inserts the text as SQL: a user value there is SQL injection. `sql` is an escape hatch, not a substitute for `where(eq(...))` in the common case.

### 1.8 Rules — `DRZ-QUERY-*` (reads)

| ID | Rule |
| --- | --- |
| `DRZ-QUERY-01` | Field selection **MUST** be explicit when the order or the subset of columns matters; `select()` with no argument is acceptable only when the whole object is consumed. |
| `DRZ-QUERY-02` | A filter **MUST** be composed with `eq`/`and`/`or`/`not` imported from `drizzle-orm`, **NEVER** string concatenation inside `sql`. |
| `DRZ-QUERY-03` | `` sql`...` `` **MUST** stay restricted to what the query builder does not express; it is not the default filtering route. |

---

## 2. Relations: declaring that tables relate

`relations()` is imported from `'drizzle-orm'` — **not** from `drizzle-orm/pg-core`. It does not change the SQL schema; it is metadata consumed only by RQB (§ 3).

### 2.1 One-to-many

```ts
export const usersRelations = relations(users, ({ many }) => ({
  posts: many(posts),
}))

export const postsRelations = relations(posts, ({ one }) => ({
  author: one(users, {
    fields: [posts.authorId],
    references: [users.id],
  }),
}))
```

**Both declarations are needed** — one per table. `fields`/`references` live on the side that **has** the foreign key (`posts.authorId`); the `many()` side only declares that the relation exists, without repeating the FK.

### 2.2 One-to-one

```ts
export const usersRelations = relations(users, ({ one }) => ({
  invitee: one(users, {
    fields: [users.invitedBy],
    references: [users.id],
  }),
}))
```

When the FK is in the related table instead of this one, `fields`/`references` disappear and the relation becomes optional:

```ts
export const usersRelations = relations(users, ({ one }) => ({
  profileInfo: one(profileInfo),   // no fields/references — the FK lives in profileInfo
}))
```

### 2.3 Many-to-many, through a junction table

Drizzle has **no** direct many-to-many primitive — it is always an explicit intermediate table, with two one-to-many relations.

```ts
export const usersToGroups = pgTable('users_to_groups', {
  userId: integer('user_id').notNull().references(() => users.id),
  groupId: integer('group_id').notNull().references(() => groups.id),
}, (t) => [
  primaryKey({ columns: [t.userId, t.groupId] }),
])

export const usersRelations = relations(users, ({ many }) => ({
  usersToGroups: many(usersToGroups),
}))
export const groupsRelations = relations(groups, ({ many }) => ({
  usersToGroups: many(usersToGroups),
}))
export const usersToGroupsRelations = relations(usersToGroups, ({ one }) => ({
  user: one(users, { fields: [usersToGroups.userId], references: [users.id] }),
  group: one(groups, { fields: [usersToGroups.groupId], references: [groups.id] }),
}))
```

A `user → groups` read must go through the junction table in `with` — RQB does not "skip" the intermediate table by itself:

```ts
const rows = await db.query.users.findMany({
  with: { usersToGroups: { with: { group: true } } },
})
const withGroups = rows.map(({ usersToGroups, ...user }) => ({
  ...user,
  groups: usersToGroups.map((ug) => ug.group),
}))
```

Filtering the **parent** by a property of the far side ("posts that have tag X") is not a `with` filter — `where` inside `with` filters the children, not the parent. Use the query builder with an `innerJoin` through the junction, or an `exists`/`inArray` subquery in the root `where`.

### 2.4 Two relations between the same tables: `relationName`

When there is more than one path between the same two tables (author **and** reviewer of a post, both `users`), RQB does not know which FK to use without help:

```ts
export const usersRelations = relations(users, ({ many }) => ({
  postsAsAuthor: many(posts, { relationName: 'author' }),
  postsAsReviewer: many(posts, { relationName: 'reviewer' }),
}))

export const postsRelations = relations(posts, ({ one }) => ({
  author: one(users, { fields: [posts.authorId], references: [users.id], relationName: 'author' }),
  reviewer: one(users, { fields: [posts.reviewerId], references: [users.id], relationName: 'reviewer' }),
}))
```

### 2.5 Wiring: connecting `relations` to the client

```ts
import * as schema from './schema'
import { drizzle } from 'drizzle-orm/node-postgres'

const db = drizzle(process.env.DATABASE_URL!, { schema })
```

**`schema` here must include both the tables and the `relations()`** — usually an `export * from './tables'` and `export * from './relations'` in the same re-exported file, or an object that groups both. *Verified:* with no `schema` at all, `db.query.users` is `undefined`; with the tables but not the relations, `db.query.users.findMany({ with: { posts: true } })` throws `undefined is not an object (evaluating 'relation.referencedTable')` — a message that names neither the relation nor the fix.

### 2.6 Rules — `DRZ-REL-*`

| ID | Rule |
| --- | --- |
| `DRZ-REL-01` | Every relation **MUST** be declared on both sides — a `many()` on one table without the matching `one()` on the other leaves `with` incomplete. |
| `DRZ-REL-02` | `fields`/`references` **MUST** stay on the side that has the foreign key column; the opposite side uses `many()`/`one()` without them. |
| `DRZ-REL-03` | Many-to-many **MUST** go through an explicit junction table — there is no direct shortcut between the two domain tables. |
| `DRZ-REL-04` | Two relations between the same tables **MUST** use `relationName` on both sides, with the same name — otherwise RQB cannot tell which FK to use. |
| `DRZ-REL-05` | The `schema` passed to `drizzle(..., { schema })` **MUST** include the `relations()`, **NEVER** only the tables — without them `with` resolves nothing. |

---

## 3. Relational Queries (RQB)

`db.query.table.findMany()`/`findFirst()`. Requires `relations` in the connected schema (§ 2.5).

### 3.1 `with` — bringing nested relations

```ts
const posts = await db.query.posts.findMany({
  with: { comments: true },
})
```

It nests arbitrarily deep, and each level may bring `columns`, `where`, `orderBy`, `limit` and a new `with` — **except `offset`, which only exists at the root level** (§ 3.4).

```ts
const postsWithCommentAuthor = await db.query.posts.findMany({
  with: {
    comments: {
      with: { author: true },   // with inside with — the author of each comment
    },
  },
})
```

With `limit` at the nested level:

```ts
const posts2 = await db.query.posts.findMany({
  with: {
    comments: { limit: 3 },
  },
})
```

`findFirst` is the same API with `LIMIT 1` applied — the common case of "fetch a post by id, with its author":

```ts
const post = await db.query.posts.findFirst({
  where: (posts, { eq }) => eq(posts.id, postId),
  with: { author: true },
})
// post is the object or undefined — not a one-element array
```

### 3.2 `columns` — partial selection

```ts
await db.query.posts.findMany({
  columns: { id: true, content: true },
  with: { comments: true },
})
```

**When `true` and `false` coexist in the same `columns`, the `false` entries are ignored** — the docs are explicit: mixing the two modes makes no sense and the include wins.

### 3.3 `where` — callback syntax with operators

```ts
await db.query.users.findMany({
  where: (users, { eq }) => eq(users.id, 1),
})
```

**This is different from the `where` of the select query builder.** There the operators (`eq`, `and`...) come from `import { eq } from 'drizzle-orm'`. Here, the **callback receives the operators as its second argument** — nothing needs importing beyond what composes the logic around it. Confusing the two styles is the most common mistake when moving from select to RQB.

### 3.4 `orderBy`, `limit`, `offset`

```ts
await db.query.posts.findMany({
  orderBy: (posts, { asc }) => [asc(posts.id)],
  limit: 5,
  offset: 2,
})
```

**`offset` only exists at the root level.** A `with.comments.offset` is not accepted — only `limit` goes down to nested relations. *Verified:* it is a type error, and when a cast forces it through, the runtime ignores it silently.

### 3.5 `extras` — a computed field

```ts
// an object of aliased SQL
await db.query.users.findMany({
  extras: { loweredName: sql<string>`lower(${users.name})`.as('lowered_name') },
})

// or one function that receives the (aliased) table and the sql helper
await db.query.users.findMany({
  extras: (table, { sql }) => ({
    loweredName: sql<string>`lower(${table.name})`.as('lowered_name'),
  }),
})
```

`.as()` is mandatory here — without it the computed field has no column name in the result. *Verified* on 0.45.4: an `extras` entry without `.as()` throws `undefined is not an object (evaluating 'query.queryChunks')`. A per-field callback (``extras: { loweredName: (table) => sql`...` }``) is the **v1** syntax and fails on the stable line, at compile time and at runtime.

**Every Drizzle column inside `extras` is re-aliased to the root table.** A correlated subquery written with another table's columns — `` sql`(select count(*) from ${comments} where ${comments.postId} = ${table.id})` `` — becomes `"posts"."postId"` and fails with `column posts.postId does not exist` (*verified*). Name the inner table in plain SQL and interpolate only the root's column:

```ts
extras: (p, { sql }) => ({
  commentCount: sql<number>`(select count(*)::int from comments c where c."postId" = ${p.id})`.as('comment_count'),
})
```

The plain identifiers are fixed text, not user input, so this is not the `DRZ-QUERY-02` case — but they are invisible to renames, so keep them next to a test that runs the query.

### 3.6 The performance guarantee

The docs state it, and it is the reason the API exists: **"Drizzle relational queries always generate exactly one SQL statement"**, with partial selection at the query level — no data beyond what was requested travels from the database to the application, even with `with` nested three levels deep. It is the opposite of the classic N+1 problem of ORMs with lazy loading. *Verified* with a three-level `with` and with `columns` + `extras` + a nested `limit`: one statement each.

### 3.7 Prepared statements

```ts
const prepared = db.query.users.findMany({
  where: (users, { eq }) => eq(users.id, sql.placeholder('id')),
}).prepare('find_user')

await prepared.execute({ id: 1 })
```

`where`, `limit` and `offset` accept `sql.placeholder(name)` — the query is compiled once and reused with different parameters.

### 3.8 Rules — `DRZ-RQB-*`

| ID | Rule |
| --- | --- |
| `DRZ-RQB-01` | A read that nests more than one related table **MUST** use `db.query.table.findMany`/`findFirst` with `with`, **NEVER** N separate calls — RQB guarantees a single SQL query. |
| `DRZ-RQB-02` | `offset` **MUST** stay at the root level only — it does not exist in a nested `with`. |
| `DRZ-RQB-03` | An RQB `where` **NEVER** imports `eq`/`and` from the `drizzle-orm` module — the operators arrive through the callback's own second argument. |
| `DRZ-RQB-04` | A computed field in `extras` **MUST** have `.as()` — with no column name, the result does not expose the field. |
| `DRZ-RQB-05` | A query repeated with varying parameters (a high-traffic endpoint) **MUST** consider `.prepare()` with `sql.placeholder`. |

---

## 4. Batching a read that does not fit `with`

When the per-item data is not a declared relation — an aggregate per row, a table owned by another module — the cure for N+1 is still **one** extra query, not N:

```ts
const page = await db.select().from(posts).orderBy(desc(posts.id)).limit(20)
const ids = page.map((p) => p.id)

const counts = await db
  .select({ postId: comments.postId, total: count() })
  .from(comments)
  .where(inArray(comments.postId, ids))
  .groupBy(comments.postId)

const byPost = new Map(counts.map((c) => [c.postId, c.total]))
const result = page.map((p) => ({ ...p, commentCount: byPost.get(p.id) ?? 0 }))
```

Two statements for any page size. The `?? 0` matters: a post with no comments has no row in the grouped result. *Verified:* `inArray(column, [])` on drizzle-orm 0.45.4 returns zero rows instead of throwing, so an empty page needs no special case — but older lines threw, so check the version (§ 0 of the hub) before relying on it.

---

## 5. Pagination

### 5.1 Limit and offset

```ts
await db.select().from(posts)
  .orderBy(desc(posts.createdAt), desc(posts.id))
  .limit(pageSize)
  .offset((page - 1) * pageSize)
```

Simple, and right for "go to page N" over data that barely moves. Two costs: the database still reads and discards every skipped row, so deep pages get slower; and a row inserted while the user pages shifts the window, so a row repeats or is skipped. **The order must be total** — a unique column (`id`) as the last tiebreaker — or two rows with the same `createdAt` can swap between pages.

### 5.2 Keyset (cursor)

```ts
// cursor = the last row of the previous page: { createdAt, id }
await db.select().from(posts)
  .where(cursor
    ? or(
        lt(posts.createdAt, cursor.createdAt),
        and(eq(posts.createdAt, cursor.createdAt), lt(posts.id, cursor.id)),
      )
    : undefined)
  .orderBy(desc(posts.createdAt), desc(posts.id))
  .limit(pageSize)
```

The filter repeats the order: everything strictly "after" the cursor in `(createdAt desc, id desc)`. It reads only the rows it returns, an index on `(created_at, id)` serves it, and an insert does not shift the window. The price is no "jump to page N". *Verified:* five rows paged two at a time return disjoint pages in order, with ties on `createdAt` broken by `id`.

Fetching `pageSize + 1` rows and dropping the extra one tells the caller whether there is a next page, without a `count`.

---

## 6. Antipatterns

| Antipattern | Fix |
| --- | --- |
| A query per item inside `map`/`for`/`Promise.all` | `with`, or one `inArray` query grouped in a `Map` · `DRZ-RQB-01` · § 4 |
| Implicit `SELECT *` when the column order matters | explicit fields · `DRZ-QUERY-01` |
| A filter concatenated inside `sql`, or a user value in `sql.raw` | `eq`/`and`/`or` · `DRZ-QUERY-02` |
| `sql` as the default filter | the query builder operators · `DRZ-QUERY-03` |
| `many()` on one side without `one()`/`fields`/`references` on the other | declare both sides · `DRZ-REL-01`/`DRZ-REL-02` |
| Trying `with` directly between two tables linked only by a junction | go through the junction table · `DRZ-REL-03` |
| Two relations between the same tables without `relationName` | name both sides · `DRZ-REL-04` |
| `drizzle(client, { schema: tables })` without the relations | include the `relations()` in the schema · `DRZ-REL-05` |
| `offset` inside a nested `with` | `limit` only, offset at the root · `DRZ-RQB-02` |
| `import { eq } from 'drizzle-orm'` inside an RQB `where` | the callback's own operator · `DRZ-RQB-03` |
| An `extras` field without `.as()` | name it · `DRZ-RQB-04` |
| `extras` with a per-field callback (v1 syntax) on the stable line | an object of aliased SQL, or one function returning it · § 3.5 |
| Another table's Drizzle columns inside `extras` | plain SQL for the inner table · § 3.5 |
| A listing that grows with the data and has no `limit` | § 0.3 and § 5 — no `DRZ-*` ID; cite this section |
| Pagination ordered by a non-unique column | add the primary key as the last tiebreaker · § 5.1 |

---

## Related

- [Drizzle ORM](drizzle-orm.md) — entry, § 0 on which version these docs document
- [Drizzle - Schema and Migrations](drizzle-schema-and-migrations.md) — tables, indexes, foreign keys
- [Drizzle - Writes and Transactions](drizzle-writes-and-transactions.md) — insert, update, delete and transactions
- [Drizzle - Zod](drizzle-zod.md) — validating query parameters and response shapes

## Sources consulted

Snapshot of the `drizzle-team/drizzle-orm-docs` repository, commit `3e7fe1b3` (2026-03-21, closest to the `drizzle-orm@0.45.2` tag, published on 2026-03-27), verified on 2026-08-16; the *verified* behaviour executed on 2026-10-24 against `drizzle-orm@0.45.4` on PGlite:

- `select.mdx` — partial select, filters, joins, aggregation, subquery, CTE
- `relations.mdx` — `relations()` with `one`/`many`, many-to-many, `relationName` — **stable API, confirmed against `relations.d.ts` of `drizzle-orm@0.45.2`**
- `rqb.mdx` — `db.query`, `with`, `columns`, the `where` callback, `orderBy`, `extras`, prepared statements
- the `limit-offset-pagination` and `cursor-based-pagination` guides — the two pagination shapes of § 5

See [Drizzle ORM](drizzle-orm.md) § 0 for the caveat about the live docs being on the v1-rc line (`defineRelations()`, object `where`) at these same URLs.
