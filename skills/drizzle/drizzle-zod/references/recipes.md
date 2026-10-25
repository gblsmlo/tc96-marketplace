# Recipes: the schemas of one feature

> Seven schemas for a `posts`/`users` feature, each one executed with `drizzle-zod@0.8.3` and `zod@4.6.7`, with a test per accepted and rejected case. The handler that wires them closes the file.

```ts
import { createInsertSchema, createSchemaFactory, createSelectSchema, createUpdateSchema } from 'drizzle-zod'
import { z } from 'zod'
import { posts, userSettingsSchema, users } from './db/schema'
```

## 1. One factory per transport: JSON bodies carry dates as strings

```ts
const json = createSchemaFactory({ coerce: { date: true } })
```

A JSON body carries `publishedAt` as a string; the generated `z.date()` rejects it. The factory returns the same three generators with coercion switched on for the types the transport cannot carry (`DRZ-ZOD-04`). Coerce booleans only with care: `'false'` coerces to `true`.

## 2. Create: refine through the second argument, then narrow to what the caller may send

```ts
export const createPostBody = json.createInsertSchema(posts, {
  slug: (s) => s.regex(/^[a-z0-9-]+$/, 'lowercase letters, digits and hyphens'),
  title: (s) => s.trim().min(3),
})
  .pick({ slug: true, title: true, publishedAt: true })
  .strict()
export type CreatePostBody = z.infer<typeof createPostBody>
```

The rules live in the refinement argument (`DRZ-ZOD-02`); callbacks keep each column's nullability. `.pick()` is the allow-list: `authorId` and `published` are columns the table accepts and the caller may not send (`DRZ-ZOD-03`). The allow-list must still cover every **required** column the server does not fill — here the table's `slug` and `title`; a table with a required `body` picks it too, or the insert fails. `.strict()` turns an unexpected key into a 400 instead of dropping it, which surfaces client bugs.

## 3. PATCH: the update schema accepts {}, so reject it; null is the explicit "clear"

```ts
export const patchPostBody = json.createUpdateSchema(posts, { title: (s) => s.trim().min(3) })
  .pick({ title: true, publishedAt: true })
  .strict()
  .refine((v) => Object.keys(v).length > 0, { message: 'Send at least one field' })
```

`createUpdateSchema` makes every column optional, so `{}` is valid — and `set({})` would throw `No values to set` (`DRZ-ZOD-06`). `publishedAt: null` passes: it is the explicit "unpublish", and `set()` writes `NULL`. An absent key leaves the column untouched.

## 4. Response: the row minus what must never leave

```ts
export const userResponse = createSelectSchema(users).omit({ passwordHash: true })
export const postResponse = createSelectSchema(posts)
```

A response schema is a guarantee at the edge: even if someone later changes the query to `select()`, `userResponse.parse(row)` will not let the hash out (`DRZ-ZOD-03`). `.omit()` fits responses — the default is "show the row".

## 5. Sign-up: a field that is not a column joins with .extend(); a column's rule goes in the refinement

```ts
export const signUpBody = createInsertSchema(users, {
  email: (s) => s.trim().toLowerCase().pipe(z.email()),
  name: (s) => s.trim().min(2),
})
  .pick({ email: true, name: true, bio: true })
  .extend({ password: z.string().min(12) })
  .strict()
```

`password` is not a column: the server hashes it into `passwordHash`, so it joins through `.extend()`. The column rules — trimmed, lower-cased, a real email — go in the refinement; `pipe(z.email())` checks the format after the transforms.

## 6. A jsonb column: the shape declared once, used by the column's $type and by the boundary

```ts
export const patchSettingsBody = createUpdateSchema(users, { settings: userSettingsSchema.nullable() }) // null resets to defaults
  .pick({ settings: true })
  .required()
  .strict()
```

`$type<T>()` types the column for TypeScript and checks nothing at runtime; the generated schema accepts any JSON (`DRZ-ZOD-07`). Declaring `userSettingsSchema` once and using it for both the column (`jsonb().$type<UserSettings>()`) and the boundary keeps them from drifting. The replacement restates `.nullable()` because the column is nullable (`DRZ-ZOD-05`) — here `null` means "reset to defaults" — and `.required()` makes the key itself mandatory for this endpoint.

## 7. A query string is not a table: plain Zod, coerced, reusing a column's own rule where it must match

```ts
const queryString = createSchemaFactory({ coerce: { number: true } })
export const listPostsQuery = z.object({
  authorId: queryString.createSelectSchema(posts).shape.authorId.optional(),
  q: z.string().trim().min(1).optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
}).strict()
```

A filter is not a row, so it is plain Zod (§ 0.2 of the doc). `authorId` reuses the column's own schema from a coercing factory, so `'3'` becomes `3` and stays in sync with the column type; `limit` has a ceiling.

## Wiring them in a handler

The handler follows `DRZ-CORE-03`: `db: Database` first, then one typed request object — the raw body and the session travel together, and nothing positional can be swapped.

```ts
export type Session = { userId: number }
export type CreatePostRequest = { body: unknown; session: Session }
export type PatchPostRequest = { postId: number; body: unknown; session: Session }

export async function createPost(db: Database, { body, session }: CreatePostRequest) {
  const input = createPostBody.parse(body)                       // throws ZodError on a bad body
  const [post] = await db.insert(posts)
    .values({ ...input, authorId: session.userId })              // the server decides the author
    .returning()
  return postResponse.parse(post)
}

export async function patchPost(db: Database, { postId, body, session }: PatchPostRequest) {
  const patch = patchPostBody.parse(body)                        // {} is rejected here, never reaches set()
  const [post] = await db.update(posts).set(patch)
    .where(and(eq(posts.id, postId), eq(posts.authorId, session.userId)))
    .returning()
  return post ? postResponse.parse(post) : undefined
}
```

```ts
// at the route boundary
try {
  return json(201, await createPost(db, { body: await request.json(), session }))
} catch (error) {
  if (error instanceof ZodError) return json(422, { issues: error.issues })
  throw error
}
```

*Executed:* a body carrying `authorId` is rejected by `.strict()`, the author comes from the session, the ISO date is coerced, `{}` never reaches `set()`, `publishedAt: null` clears, and another user's PATCH matches no row.

Frameworks that accept a Zod schema as the route validator (Elysia, Hono) do the `parse` and the 4xx themselves — the schema is the same object. `z.toJSONSchema(createPostBody)` gives the JSON Schema for the OpenAPI document.

## The tests that pin them

```ts
expect(createPostBody.safeParse({ slug: 'x', title: 'Hey', authorId: 9 }).success).toBe(false)   // server-owned
expect(createPostBody.parse({ slug: 'a-b', title: 'Hey', publishedAt: '2026-01-01T00:00:00Z' }).publishedAt).toBeInstanceOf(Date)
expect(patchPostBody.safeParse({}).success).toBe(false)                                          // empty PATCH
expect(patchPostBody.parse({ publishedAt: null }).publishedAt).toBeNull()                        // null clears
expect('passwordHash' in userResponse.parse(row)).toBe(false)                                    // no secret out
expect(patchSettingsBody.safeParse({ settings: { theme: 42 } }).success).toBe(false)             // jsonb shape
expect(listPostsQuery.parse({ authorId: '3', limit: '5' })).toEqual({ authorId: 3, limit: 5 })    // query string
```
