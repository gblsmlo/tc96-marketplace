# Zod boundary antipatterns, with IDs

> Each row names the fix and where the rule's body lives. Rows without a `DRZ-*` ID cite the doc section — never an invented ID.

| Antipattern | ID | Fix | Body |
| --- | --- | --- | --- |
| A hand-written `z.object` repeating a table's columns | `DRZ-ZOD-01` | `create*Schema(table)`, then narrow | [Zod](../../../docs/drizzle/drizzle-zod.md) § 0.2 |
| `.extend({ name: z.string().min(2) })` over a generated column | `DRZ-ZOD-02` | `createInsertSchema(t, { name: (s) => s.min(2) })` | [Zod](../../../docs/drizzle/drizzle-zod.md) § 4 |
| `createInsertSchema(users)` as the request body | `DRZ-ZOD-03` | `.pick()` the caller's fields, `.strict()` | [Zod](../../../docs/drizzle/drizzle-zod.md) § 2 |
| `authorId`/`ownerId`/`tenantId`/`role` read from the body | `DRZ-ZOD-03` | add it from the session after parsing | [Zod](../../../docs/drizzle/drizzle-zod.md) § 5 |
| `createSelectSchema(users)` returned with the password hash | `DRZ-ZOD-03` | `.omit({ passwordHash: true })` | [Zod](../../../docs/drizzle/drizzle-zod.md) § 2 |
| `new Date(body.publishedAt)` around `parse` | `DRZ-ZOD-04` | `createSchemaFactory({ coerce: { date: true } })` | [Zod](../../../docs/drizzle/drizzle-zod.md) § 3 |
| `Number(req.query.limit)` before `parse` | `DRZ-ZOD-04` | `coerce: { number: true }`, or `z.coerce.number()` in a plain schema | [Zod](../../../docs/drizzle/drizzle-zod.md) § 3 |
| `bio: z.string().max(280)` on a nullable column | `DRZ-ZOD-05` | `bio: (s) => s.max(280)`, or `.nullish()` | [Zod](../../../docs/drizzle/drizzle-zod.md) § 4.1 |
| An update schema that lets `{}` reach `set()` | `DRZ-ZOD-06` | `.refine((v) => Object.keys(v).length > 0)` | [Zod](../../../docs/drizzle/drizzle-zod.md) § 6 |
| A `jsonb().$type<T>()` written straight from the body | `DRZ-ZOD-07` | a Zod schema for `T` in the refinement | [Zod](../../../docs/drizzle/drizzle-zod.md) § 4.3 |
| `import { z } from 'zod'` on zod 3.25, next to drizzle-zod | no ID | `import { z } from 'zod/v4'` | [Zod](../../../docs/drizzle/drizzle-zod.md) § 1.2 |
| An email column trusted as validated | no ID | `(s) => s.pipe(z.email())` | [Zod](../../../docs/drizzle/drizzle-zod.md) § 1 |
| A typo in a refinement key, never type-checked | no ID | run `tsc --noEmit` | [Zod](../../../docs/drizzle/drizzle-zod.md) § 4.2 |
| `coerce: true` on a query string's booleans | no ID | coerce only what the transport cannot carry | [Zod](../../../docs/drizzle/drizzle-zod.md) § 3 |
| Several positional inputs after `db` (`posts(db, authorId, userId, page)`) | `DRZ-CORE-03` | `db: Database`, then one typed input object | [Hub](../../../docs/drizzle/drizzle-orm.md) § 10 |
