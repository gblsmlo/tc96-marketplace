# Read patterns

> Seven shapes worth copying, each one executed against PostgreSQL (PGlite) on `drizzle-orm@0.45.4` with its statement count asserted. Pattern 7 is the harness that asserts it.
> Every function takes `db: Database` first and its input as one typed object (`DRZ-CORE-03`, hub § 10); a single obvious input stays positional.
> The schema they use: `users` 1—n `posts` 1—n `comments`, and `posts` n—n `tags` through `postsToTags`, with `relations()` declared on both sides and registered in the client.

```ts
import { and, count, desc, eq, getTableColumns, ilike, inArray, sql } from 'drizzle-orm'
import type { Database } from './db'
import { comments, posts, postsToTags, tags, users } from '../src/db/schema'
```

## 1. Detail: one post with its author and its latest comments — one statement

```ts
export function getPost(db: Database, slug: string) {
  return db.query.posts.findFirst({
    where: (p, { eq }) => eq(p.slug, slug),
    columns: { id: true, slug: true, title: true, publishedAt: true },
    with: {
      author: { columns: { id: true, name: true } },
      comments: { orderBy: (c, { desc }) => [desc(c.createdAt), desc(c.id)], limit: 5 },
    },
  })
}
```

One statement: `findFirst` returns the object or `undefined`, never a one-element array. `columns` keeps the payload to what the screen shows; nested `limit` and `orderBy` are allowed, nested `offset` is not (`DRZ-RQB-02`).

## 2. Feed with a keyset cursor: limit + 1 tells whether there is a next page

```ts
export type Cursor = { publishedAt: Date; id: number }
export type FeedInput = { cursor?: Cursor | null; pageSize?: number }

export async function feed(db: Database, { cursor = null, pageSize = 20 }: FeedInput = {}) {
  const rows = await db.query.posts.findMany({
    where: (p, { and, or, eq, lt, isNotNull }) => and(
      eq(p.published, true),
      isNotNull(p.publishedAt),
      cursor ? or(lt(p.publishedAt, cursor.publishedAt), and(eq(p.publishedAt, cursor.publishedAt), lt(p.id, cursor.id))) : undefined,
    ),
    orderBy: (p, { desc }) => [desc(p.publishedAt), desc(p.id)],
    limit: pageSize + 1,
    columns: { id: true, title: true, publishedAt: true },
    with: { author: { columns: { id: true, name: true } } },
    // inside extras every Drizzle column is re-aliased to the root table, so the inner table is plain SQL
    extras: (p, { sql }) => ({
      commentCount: sql<number>`(select count(*)::int from comments c where c."postId" = ${p.id})`.as('comment_count'),
    }),
  })
  const page = rows.slice(0, pageSize)
  const last = page.at(-1)
  return { page, next: rows.length > pageSize && last ? { publishedAt: last.publishedAt!, id: last.id } : null }
}
```

The `where` callback receives `and`, `or`, `lt`… as its second argument (`DRZ-RQB-03`), and `and()` drops the `undefined` cursor condition on the first page. The order is total — `publishedAt`, then `id` — so ties cannot swap between pages. Fetching `pageSize + 1` answers "is there a next page" without a `count`. The comment count is a correlated subquery in `extras`: inside `extras` every Drizzle column is re-aliased to the root table, so the inner table is written as plain SQL and only the root's `p.id` is interpolated (doc § 3.5).

## 3. Many-to-many through the junction, flattened

```ts
export async function postsWithTags(db: Database, authorId: number) {
  const rows = await db.query.posts.findMany({
    where: (p, { eq }) => eq(p.authorId, authorId),
    columns: { id: true, title: true },
    with: { postsToTags: { columns: {}, with: { tag: { columns: { name: true } } } } },
    limit: 50,
  })
  return rows.map(({ postsToTags, ...post }) => ({ ...post, tags: postsToTags.map((pt) => pt.tag.name) }))
}
```

RQB does not skip the junction table (`DRZ-REL-03`): go through it in `with`, select no columns from it (`columns: {}`), and flatten in JavaScript. Still one statement.

## 4. Parent filtered by a property of the far side: posts that carry a tag

```ts
export type PostsTaggedInput = { tagName: string; pageSize?: number }

export function postsTagged(db: Database, { tagName, pageSize = 20 }: PostsTaggedInput) {
  return db.query.posts.findMany({
    where: (p, { and, eq, exists }) => and(
      eq(p.published, true),
      exists(db.select({ one: sql`1` }).from(postsToTags)
        .innerJoin(tags, eq(tags.id, postsToTags.tagId))
        .where(and(eq(postsToTags.postId, p.id), eq(tags.name, tagName)))),
    ),
    orderBy: (p, { desc }) => [desc(p.id)],
    limit: pageSize,
  })
}
```

A `where` inside `with` filters the **children**; filtering the **parent** by a property of the far side is an `exists` subquery in the root `where` (the callback receives `exists` too). One statement.

## 5. A per-row aggregate for a page, without N+1: one grouped query, merged through a Map

```ts
export async function authorsWithPostCounts(db: Database, { pageSize = 20 }: { pageSize?: number } = {}) {
  const page = await db.select({ id: users.id, name: users.name }).from(users).orderBy(users.id).limit(pageSize)
  const counts = await db.select({ authorId: posts.authorId, total: count() }).from(posts)
    .where(inArray(posts.authorId, page.map((u) => u.id))).groupBy(posts.authorId)
  const byAuthor = new Map(counts.map((c) => [c.authorId, c.total]))
  return page.map((u) => ({ ...u, postCount: byAuthor.get(u.id) ?? 0 }))
}
```

When the per-row data is not a declared relation, the cure for N+1 is one grouped `inArray` query merged through a `Map` — two statements for any page size. `?? 0` covers the rows with no match. On 0.45.x `inArray(col, [])` returns no rows instead of throwing (doc § 4).

## 6. Optional filters: and() drops undefined conditions

```ts
export type SearchPostsInput = { q?: string; authorId?: number; published?: boolean; pageSize?: number }

export function searchPosts(db: Database, { pageSize = 20, ...f }: SearchPostsInput = {}) {
  return db.select({ ...getTableColumns(posts) }).from(posts)
    .where(and(
      f.q ? ilike(posts.title, `%${f.q}%`) : undefined,
      f.authorId !== undefined ? eq(posts.authorId, f.authorId) : undefined,
      f.published !== undefined ? eq(posts.published, f.published) : undefined,
    ))
    .orderBy(desc(posts.id))
    .limit(pageSize)
}
```

`and()` drops `undefined` arguments, so each optional filter is a conditional. `ilike` takes the user value as a parameter — it is not concatenated into SQL. The listing still has a `limit`.

## 7. Prove the statement count in a test

```ts
// src/db/test-db.ts — a fresh in-memory PostgreSQL per test, every statement counted
import { PGlite } from '@electric-sql/pglite'
import { drizzle } from 'drizzle-orm/pglite'
import { pushSchema } from 'drizzle-kit/api'
import * as schema from './schema'

export async function createTestDb() {
  const statements: string[] = []
  const db = drizzle({ client: new PGlite(), schema, logger: { logQuery: (q) => statements.push(q) } })
  const { apply } = await pushSchema(schema, db as any)
  await apply()
  statements.length = 0
  return { db, statements }
}
```

```ts
// feed.test.ts
for (const n of [5, 50]) test(`the feed is one statement per page (n=${n})`, async () => {
  const { db, statements } = await createTestDb()
  await seedPosts(db, n)
  statements.length = 0
  await feed(db, { pageSize: 20 })
  expect(statements.length).toBe(1)
})
```

Asserting the same count for 5 rows and for 50 is what catches N+1: a loop makes the count grow with the data. PGlite needs `@electric-sql/pglite` as a dev dependency and no server; `pushSchema` from `drizzle-kit/api` applies the schema without migration files, which is fine for a throwaway test database (`DRZ-MIG-01` is about shared environments). Against a real server, the same `logger` works with any driver.
