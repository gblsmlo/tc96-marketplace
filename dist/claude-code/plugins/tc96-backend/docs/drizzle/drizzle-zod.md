---
titulo: Drizzle - Zod
Link: https://orm.drizzle.team/docs/zod
tags:
  - typescript
  - backend
  - database
  - orm
  - zod
  - validation
  - agent-context
source: "Official Drizzle ORM documentation (zod.mdx) cross-checked against drizzle-zod@0.8.3's type declarations and executed with zod 4.6.7 and 3.25.76"
verificado-em: 2026-10-24
---

# Drizzle — Zod

> `createSelectSchema` · `createInsertSchema` · `createUpdateSchema` · `createSchemaFactory` · request and response schemas · coercion · refinement · PATCH bodies
>
> How to turn a table into the schemas that guard the route boundary, without writing the shape twice and without letting the table's shape become the API's.

Entry: [Drizzle ORM](drizzle-orm.md) · **Confirm § 0 there before using this note** — on the stable line the functions come from the `drizzle-zod` package; on v1 they come from `drizzle-orm/zod` (§ 7).

> **Import convention in this note.** The examples assume `createSelectSchema`, `createInsertSchema`, `createUpdateSchema` and `createSchemaFactory` imported from `'drizzle-zod'`, and `z` from `'zod'` (zod 4). On zod 3.25, see § 1.2. The examples use this table:
>
> ```ts
> export const users = pgTable('users', {
>   id: integer().primaryKey().generatedAlwaysAsIdentity(),
>   email: varchar({ length: 120 }).notNull().unique(),
>   name: varchar({ length: 80 }).notNull(),
>   role: roleEnum().notNull().default('member'),
>   passwordHash: text().notNull(),
>   bio: text(),
>   settings: jsonb().$type<{ theme: 'light' | 'dark' }>(),
>   createdAt: timestamp().defaultNow().notNull(),
> })
> ```

---

## 0. Decision trees

### 0.1 Which schema, for which direction?

```
Is the data ENTERING the system (a request body, a form, a message)
or LEAVING it (a response, an export)?
├── ENTERING
│   ├── creates a row  → createInsertSchema(table, refine)
│   ├── changes a row  → createUpdateSchema(table, refine)          + § 6 (empty PATCH)
│   └── then NARROW it to what the caller may set: .pick()/.omit()  DRZ-ZOD-03
│       and .strict() when an unknown key should be a 400, not dropped
└── LEAVING
    └── createSelectSchema(table) .omit() the columns the caller
        must never see (password hash, tokens, internal flags)        DRZ-ZOD-03
```

### 0.2 Is the shape a table at all?

```
Does the shape to validate ALREADY EXIST as a Drizzle table?
├── YES → derive it from the table. Do not duplicate the shape.       DRZ-ZOD-01
│         Need an extra rule on a column (min, regex, email)?
│         → the second argument of create*Schema                      DRZ-ZOD-02
└── NO — a shape that is not a table (a query-string filter, a
    webhook payload, a login form, a DTO that joins three tables)
    → plain Zod. Reuse single fields from a generated schema with
      .shape.<column> when they must match the column exactly.
```

### 0.3 Does the value arrive as a string?

```
Where does the value come from?
├── a parsed JSON body, typed values (numbers, booleans, null)
│   └── a Date column? JSON has no dates — it arrives as a string    DRZ-ZOD-04
└── a query string, a path parameter, form data — everything is a string
    → coerce: createSchemaFactory({ coerce: { number: true, date: true, boolean: true } })
```

---

## 1. The three functions, and what they generate

```ts
const userSelectSchema = createSelectSchema(users)
const userInsertSchema = createInsertSchema(users)
const userUpdateSchema = createUpdateSchema(users)
```

Each one derives a Zod object from the table's columns — name, type, nullability and default already right. *Verified* on drizzle-zod 0.8.3 with zod 4.6.7, for the table above:

| Column | select | insert | update |
| --- | --- | --- | --- |
| `id` — identity (`generatedAlwaysAsIdentity`) | `number`, required | **absent** | **absent** |
| `email` — `varchar({ length: 120 }).notNull()` | `string` max 120, required | required | optional |
| `role` — enum with a default | `z.enum([...])`, required | **optional** | optional |
| `bio` — nullable `text()` | `string \| null`, **required key** | optional, accepts `null` | optional, accepts `null` |
| `settings` — `jsonb().$type<T>()` | **any JSON** | any JSON | any JSON |
| `createdAt` — `timestamp().defaultNow()` | `Date` | optional `Date` | optional `Date` |

Five things that table says, each one a bug when missed:

- **A varchar length becomes `.max(length)`, but nothing else is inferred.** `email` is a plain string — no format check. *Verified:* `'nope'` passes as an email. The format rule is yours to add (§ 4).
- **The insert schema includes every insertable column**, `role` and `passwordHash` included. *Verified:* `{ email, name, role: 'admin' }` parses, and the parsed object carries `role: 'admin'` — § 2.
- **Unknown keys are dropped, not rejected.** *Verified:* `id: 7` and `extra: 1` vanish from the parsed object without an error. That protects the identity column, and hides a client bug. `.strict()` turns it into a 400.
- **`$type<T>()` is invisible at runtime.** *Verified:* `settings: { theme: 42 }` passes. The JSON shape needs a Zod schema of its own (§ 4.3).
- **A `timestamp` column is a `z.date()`**, which a JSON string does not satisfy (§ 3).

`createSelectSchema` also accepts a `pgEnum` and returns its `z.enum` — `createSelectSchema(roleEnum).options` is `['member', 'admin']` (*verified*).

### 1.1 Types: infer from the schema that parsed

```ts
type CreateUserBody = z.infer<typeof createUserBody>   // what the route accepted
type NewUser = typeof users.$inferInsert                 // what the table accepts
```

They differ on purpose once the request schema is narrowed: the body has no `passwordHash`, the row needs one. The handler builds the row from the body plus what the server decides (§ 5).

### 1.2 Zod 4, Zod 3.25 and the `zod/v4` import

`drizzle-zod@0.8.x` declares `zod: ^3.25.0 || ^4.0.0` and builds its schemas with `zod/v4`. With **zod 4.x** installed, `'zod'` and `'zod/v4'` are the same module and any import works. With **zod 3.25.x**, `'zod'` is still the classic v3 API: a v3 schema passed as a refinement, or to `.extend()`, fails at runtime. *Verified* on zod 3.25.76: `Invalid element at key "bio": expected a Zod schema` — and `tsc` rejects it too. On 3.25, import `z` from `'zod/v4'` in every file that touches a generated schema.

---

## 2. Narrowing: the table's shape is not the API's

A table's insert schema answers "what can a row hold". A route answers "what may **this caller** set". They are different questions, and using the first for the second is mass assignment: whoever sends `role: 'admin'`, `ownerId: <someone else>` or `published: true` gets it.

```ts
// what a sign-up may send
export const signUpBody = createInsertSchema(users, {
  email: (s) => s.pipe(z.email()),
  name: (s) => s.min(2),
})
  .pick({ email: true, name: true, bio: true })
  .extend({ password: z.string().min(12) })   // not a column: the server hashes it
  .strict()

// what a response may show
export const userResponse = createSelectSchema(users).omit({ passwordHash: true })
```

*Verified:* the picked, strict schema rejects `role: 'admin'` and rejects a malformed email. `.pick()`/`.omit()` keep the derivation — the fields still come from the table, so a column change still reaches the API — which is why narrowing does not conflict with `DRZ-ZOD-01`.

`.extend()` here adds a field that **is not a column** (`password`). That is legitimate; what `DRZ-ZOD-02` forbids is using `.extend()` to re-declare a rule on a field the table already generated.

Prefer `.pick()` (an allow-list) for request bodies: a column added to the table later stays out of the API until someone decides it belongs. `.omit()` (a deny-list) is the natural fit for responses, where the default is "show the row".

---

## 3. Transport and coercion

JSON has strings, numbers, booleans, null, arrays and objects. A query string has only strings. The generated schema validates **TypeScript** types, so:

- a `timestamp` column expects a `Date` — a JSON body's `"2026-01-01T00:00:00Z"` fails (*verified*);
- an `integer` column expects a number — a query string's `"3"` fails (*verified*).

`createSchemaFactory` returns the same three functions, configured:

```ts
const { createInsertSchema: createInsertSchemaCoerced } = createSchemaFactory({
  coerce: { date: true },   // or { number: true, boolean: true, bigint: true, string: true }, or `true` for all
})

export const createPostBody = createInsertSchemaCoerced(posts).pick({ title: true, slug: true, publishedAt: true })
```

*Verified:* with `coerce: { date: true }`, `"2026-01-01T00:00:00Z"` parses into a `Date`. Coerce only the types the transport cannot carry; `coerce: true` also turns `"false"` into `true` for booleans (JavaScript truthiness), which is rarely what a query string means.

`createSchemaFactory({ zodInstance })` is the hook for a project that extends Zod or must pin a specific instance.

---

## 4. Refining a generated field

The second argument of `create*Schema` takes one entry per column:

```ts
const userInsertSchema = createInsertSchema(users, {
  name: (schema) => schema.min(2),                                // a callback EXTENDS the generated schema
  bio: (schema) => schema.max(280),
  settings: z.object({ theme: z.enum(['light', 'dark']) }),       // a schema REPLACES it entirely
})
```

### 4.1 A callback keeps nullability; a replacement drops it

*Verified:* with `bio: (s) => s.max(280)`, `bio` is still optional and still accepts `null` — the callback receives the base string schema and drizzle-zod re-applies the column's nullability. With `bio: z.string().max(280)`, `bio` becomes **required and non-null**: omitting it fails, `null` fails. A replacement is taken literally. When the column is nullable and you replace it, restate it: `z.string().max(280).nullish()` on insert, `.nullable()` on select.

Prefer the callback. Replace only when the generated base is wrong for the field — a `jsonb` that needs a real shape, a string that must become an enum.

### 4.2 The refinement keys are only checked by the compiler

*Verified:* a refinement for a column that does not exist (`{ nope: ... }`) raises no runtime error. TypeScript catches it (`NoUnknownKeys` in the signature) — so run the type check; a typo in a refinement key silently refines nothing.

### 4.3 `jsonb` and `json` need a schema

`$type<T>()` types the column for TypeScript only. The generated schema accepts any JSON value (*verified*), so the shape the code relies on must be given as a replacement:

```ts
const settingsSchema = z.object({ theme: z.enum(['light', 'dark']) })

const userUpdateSchema = createUpdateSchema(users, {
  settings: settingsSchema.nullish(),
})
```

Declaring `settingsSchema` once and deriving the column's `$type` from it (`jsonb().$type<z.infer<typeof settingsSchema>>()`) keeps the two from drifting.

---

## 5. Wiring it to the route

```ts
export async function createPost(db: Database, { body, session }: { body: unknown; session: { userId: number } }) {
  const input = createPostBody.parse(body)          // the narrowed schema of § 2/§ 3
  const [post] = await db.insert(posts)
    .values({ ...input, authorId: session.userId }) // the server decides the owner
    .returning()
  return postResponse.parse(post)                   // the response schema of § 2
}
```

The fields the server decides — owner, author, tenant, role, timestamps — are **added after** parsing, from the authenticated context, never read from the body. Parsing the response is optional for correctness and useful at the boundary: it is what guarantees the password hash never leaves, even when someone later changes the query to `select()`.

`.parse()` throws a `ZodError`; `.safeParse()` returns `{ success, error }`. The route layer turns that into a 400/422 with the issue list — the framework side (Elysia's and Hono's validators accept Zod schemas) lives in `Elysia - Schema e Eden` and `Hono - Validação e RPC`. `z.toJSONSchema(schema)` produces the JSON Schema for an OpenAPI document (*verified* on zod 4.6.7).

---

## 6. PATCH: the update schema accepts `{}`

`createUpdateSchema` makes every column optional, so an empty object is valid (*verified*). Passed on to `db.update(table).set({})`, it fails with `No values to set` — a 500 for what is a client error. Reject it at the boundary:

```ts
export const patchProfileBody = createUpdateSchema(users, { name: (s) => s.min(2) })
  .pick({ name: true, bio: true })
  .strict()
  .refine((value) => Object.keys(value).length > 0, { message: 'Send at least one field' })
```

*Verified:* `{}` fails, `{ bio: null }` passes — and `null` is the explicit "clear this field" that `set()` honours, while an absent key leaves the column untouched (see [Drizzle - Writes and Transactions](drizzle-writes-and-transactions.md) § 4.1).

---

## 7. v1: the same functions, from `drizzle-orm/zod`

On the `1.0.0-rc` line, `drizzle-zod` is deprecated and the generators ship inside `drizzle-orm` (`import { createInsertSchema } from 'drizzle-orm/zod'`; the `1.0.0-rc.5` tarball contains `zod.js` and `zod.d.ts`). The concepts of this note carry over; the import line changes, and the signature should be confirmed through Context7 (`/drizzle-team/drizzle-orm-docs`, topic `zod`) before relying on an option.

---

## 8. Rules — `DRZ-ZOD-*`

| ID | Rule |
| --- | --- |
| `DRZ-ZOD-01` | Validation of a table row **MUST** derive from `createInsertSchema`/`createSelectSchema`/`createUpdateSchema`, **NEVER** a hand-written Zod schema duplicating the columns. |
| `DRZ-ZOD-02` | An additional rule on a generated field **MUST** use the second argument of `create*Schema`, **NEVER** a manual `.extend()`/`.merge()` on the outside. |
| `DRZ-ZOD-03` | A request schema **MUST** be narrowed from the generated schema to the fields the caller may set (`.pick()`, or `.omit()` of server-owned columns), and a response schema **MUST** omit the columns the caller must not see — **NEVER** the table's whole insert or select schema at the boundary. *Added 2026-10-24, verified on drizzle-zod 0.8.3.* |
| `DRZ-ZOD-04` | A value that the transport carries as a string (a date in JSON; anything in a query string or path) **MUST** be coerced by the schema — `createSchemaFactory({ coerce })` — **NEVER** converted by hand before or after parsing. *Added 2026-10-24, verified.* |
| `DRZ-ZOD-05` | A refinement that replaces a nullable or optional column with a plain Zod schema **MUST** restate `.nullable()`/`.optional()`/`.nullish()` — a replacement drops them; prefer the callback form, which keeps them. *Added 2026-10-24, verified.* |
| `DRZ-ZOD-06` | A PATCH body derived from `createUpdateSchema` **MUST** reject the empty object before it reaches `set()`. *Added 2026-10-24, verified.* |
| `DRZ-ZOD-07` | A `json`/`jsonb` column typed with `$type<T>()` **MUST** be given a Zod schema for `T` through the refinement argument wherever it is written — the generated schema accepts any JSON. *Added 2026-10-24, verified.* |

---

## 9. Antipatterns

| Antipattern | Fix |
| --- | --- |
| A hand-written `z.object` repeating the table's columns | `create*Schema` · `DRZ-ZOD-01` |
| `.extend({ name: z.string().min(2) })` on a generated schema | `createInsertSchema(t, { name: (s) => s.min(2) })` · `DRZ-ZOD-02` |
| `createInsertSchema(users)` used as the request body | `.pick()` the caller's fields, `.strict()` · `DRZ-ZOD-03` |
| `ownerId`/`authorId`/`tenantId` read from the body | add it from the authenticated context after parsing · `DRZ-ZOD-03` · § 5 |
| `createSelectSchema(users)` returned as-is, with the password hash | `.omit({ passwordHash: true })` · `DRZ-ZOD-03` |
| `new Date(body.publishedAt)` before or after `parse` | `createSchemaFactory({ coerce: { date: true } })` · `DRZ-ZOD-04` |
| `bio: z.string().max(280)` on a nullable column | `bio: (s) => s.max(280)`, or `.nullish()` · `DRZ-ZOD-05` |
| An update schema that lets `{}` through to `set()` | `.refine(v => Object.keys(v).length > 0)` · `DRZ-ZOD-06` |
| A `jsonb().$type<T>()` written straight from the body | a Zod schema for `T` in the refinement · `DRZ-ZOD-07` |
| `import { z } from 'zod'` on zod 3.25 next to drizzle-zod | `import { z } from 'zod/v4'` · § 1.2 |
| An email column trusted as validated | `(s) => s.pipe(z.email())` · § 1 |

---

## Related

- [Drizzle ORM](drizzle-orm.md) — entry, § 0 on which version these docs document
- [Drizzle - Writes and Transactions](drizzle-writes-and-transactions.md) — what `values()` and `set()` do with what the schema let through
- [Drizzle - Schema and Migrations](drizzle-schema-and-migrations.md) — the columns the schemas are generated from
- `Zod - Validação de Ambiente` · `Elysia - Schema e Eden` · `Hono - Validação e RPC` · `React Hook Form - Validação e Resolvers` — other tc96 notes, cited by name

## Sources consulted

- Snapshot of the `drizzle-team/drizzle-orm-docs` repository, commit `3e7fe1b3` (2026-03-21): `zod.mdx` — `createSelectSchema`/`createInsertSchema`/`createUpdateSchema`, refinement, `createSchemaFactory`, and the deprecation notice from `1.0.0-beta.15`
- `drizzle-zod@0.8.3` type declarations (`schema.types.d.ts`): the refine signature with `NoUnknownKeys`, `CreateSchemaFactoryOptions` (`zodInstance`, `coerce`), the `zod/v4` import, the `zod: ^3.25.0 || ^4.0.0` peer range
- A playground project on 2026-10-24 (`drizzle-orm@0.45.4`, `drizzle-zod@0.8.3`, `zod@4.6.7`; and a second one on `zod@3.25.76`), where every claim marked *verified* was executed
- the `drizzle-orm@1.0.0-rc.5` tarball — `zod.js`/`zod.d.ts`

See [Drizzle ORM](drizzle-orm.md) § 0 for the caveat about the live docs being on the v1-rc line at these same URLs.
