---
nome: drizzle-zod
descricao: Build the Zod schemas that guard a Drizzle ORM table at the route boundary — `createInsertSchema`/`createUpdateSchema`/`createSelectSchema` and `createSchemaFactory` from drizzle-zod (or `drizzle-orm/zod` on v1), narrowing request bodies against mass assignment, response schemas without secrets, coercion of dates and query strings, refinements that keep nullability, typed `jsonb`, and PATCH bodies that reject `{}` — citing `DRZ-ZOD-*` IDs, with an AST self-check. Use when the task is validating a request body, query string or response for a Drizzle table, replacing a hand-written Zod schema that repeats the columns, "expected date, received string", a user setting their own `role` or `ownerId`, a password hash in a response, or zod 3 versus 4 errors with drizzle-zod. Do not use for the query itself (drizzle-query, drizzle-mutation), for a shape that is not a table (plain Zod), nor to audit existing code (drizzle-review).
tipo: skill
familia: drizzle
idioma: en
fonte: "[Drizzle - Zod](../docs/drizzle-zod.md)"
docs:
  - /drizzle-team/drizzle-orm-docs
  - /colinhacks/zod
tags:
  - skill
  - drizzle
  - zod
  - validation
---

# drizzle-zod

> **Source of this skill:** [Drizzle - Zod](../docs/drizzle-zod.md) — its § 0 holds the decision trees, § 1 the table of what each generator produces, and every rule this skill cites has its body there.
> **API surface:** resolve it through Context7 — `/drizzle-team/drizzle-orm-docs` (topic `zod`) for the generators, `/colinhacks/zod` for the Zod API (`pick`, `strict`, `refine`, `coerce`, `toJSONSchema`).

Generating a schema from the table removes the drift between the database and the validator — that is the whole point, and the reason a hand-written duplicate is a defect (`DRZ-ZOD-01`). But a generated schema describes **what a row can hold**, not **what a caller may send**, and it validates TypeScript types, not what travels over HTTP. Every rule in this skill is about that gap: narrowing, coercing, and refining without losing what the generator got right.

---

## When to use

| Situation | Go to |
| --- | --- |
| the insert or update that consumes the parsed body | `drizzle-mutation` |
| the read that produces the response | `drizzle-query` |
| a shape that is not a table — webhook, login form, filter DTO | plain Zod; `Zod - Validação de Ambiente` for env vars |
| the route's validator and error response | `elysia-schema` · `http-contract` |
| reviewing existing code | `drizzle-review` |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Drizzle - Zod](../docs/drizzle-zod.md) | the trees, the generated-schema table, the rules — the one doc this skill needs |
| 2 | [Drizzle - Writes and Transactions](../docs/drizzle-writes-and-transactions.md) § 4.1 | only when the schema feeds a PATCH — what `set()` does with `null`, absent keys and `{}` |
| 3 | [Drizzle ORM](../docs/drizzle-orm.md) § 0 | only when `package.json` shows `drizzle-orm` 1.x |

| File | What for |
| --- | --- |
| `references/recipes.md` | seven schemas for one feature, each executed: the coercing factory, create body, PATCH body, response, sign-up, `jsonb`, query string — and the handler that wires them |
| `references/antipatterns.md` | the grid with IDs and doc sections |
| `references/id-map.md` | the `DRZ-ZOD-*` IDs and where their bodies live |
| `scripts/self-check.sh` | versions (drizzle-zod, zod 3 × 4) and the zod-group AST scan |

---

## Step 0 — Which generator, which Zod

```bash
grep -E '"drizzle-(orm|zod)"|"zod"' package.json
```

- `drizzle-orm` 0.x → `import { createInsertSchema } from 'drizzle-zod'`. On 1.0.0-rc → `from 'drizzle-orm/zod'`; confirm the options through Context7.
- `zod` 4.x → `import { z } from 'zod'` works everywhere. **`zod` 3.25.x → import `z` from `'zod/v4'`** in every file that refines or extends a generated schema; the classic `'zod'` import fails with `expected a Zod schema` (doc § 1.2).

---

## Step 1 — Four questions per schema

1. **Which direction?** Entering → `createInsertSchema` (create) or `createUpdateSchema` (change). Leaving → `createSelectSchema`. Is it a table at all? If not, plain Zod — reuse a column's rule through `.shape.<column>` when it must match exactly. Tree § 0.1–0.2.
2. **What may this caller set — or see?** Narrow with `.pick()` (an allow-list, best for bodies) or `.omit()` (best for responses), and add `.strict()` when an unknown key should be a 400 rather than silently dropped. The table's whole insert schema accepts `role: 'admin'`; its select schema carries the password hash (`DRZ-ZOD-03`). Owner, author and tenant are added from the authenticated context **after** parsing.
3. **How does the value travel?** JSON has no dates; a query string has only strings. Coerce in the schema — `createSchemaFactory({ coerce: { date: true } })` for bodies, `{ number: true }` for query strings — never with `new Date()` around `parse` (`DRZ-ZOD-04`). Tree § 0.3.
4. **What does the generator not know?** Formats (email, slug), trimming, cross-field rules, and the shape of a `jsonb` column — `$type<T>()` is invisible at runtime (`DRZ-ZOD-07`). Add them through the **second argument** of the generator (`DRZ-ZOD-02`).

---

## Step 2 — Write it

Start from `references/recipes.md`. The refinement argument has one trap worth knowing by heart:

- **A callback extends and keeps nullability** — `bio: (s) => s.max(280)` is still optional and still accepts `null`.
- **A plain schema replaces and drops it** — `bio: z.string().max(280)` becomes required and non-null. Restate it (`.nullish()`/`.nullable()`) or use the callback (`DRZ-ZOD-05`).

And the PATCH trap: `createUpdateSchema` accepts `{}`, which then makes `set()` throw `No values to set`. Add `.refine((v) => Object.keys(v).length > 0)` (`DRZ-ZOD-06`). `null` stays the explicit "clear this field".

The handler that parses the body follows the same shape as any data-access function: `createPost(db, { body, session })` — `db: Database` first, then one request object (`DRZ-CORE-03`, [Drizzle ORM](../docs/drizzle-orm.md) § 10).

Use `.extend()` only for fields that are **not columns** (a plaintext `password` the server hashes). Re-declaring a column there bypasses the generator — that is what `DRZ-ZOD-02` forbids.

---

## Step 3 — Prove it

Each rule above is one assertion. Test the schema directly, no database needed: the server-owned field rejected, `{}` rejected, `null` accepted where it clears, the date string coerced, the response without the secret, the bad `jsonb` shape rejected. Then:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/drizzle-zod/scripts/self-check.sh .
bunx tsc --noEmit
```

Run the type check: a refinement key that is not a column raises no runtime error — only the compiler catches it (doc § 4.2). The self-check flags hand-written duplicates, un-narrowed generators, select schemas that keep secrets, `.extend()` over a column, date columns without coercion, untyped `jsonb`, replacements that drop `null`, update schemas that accept `{}`, and zod 3.25 with the classic import.

---

## Step 4 — Report

Show the schemas, what each one accepts and rejects (with the test output), the IDs behind each choice, and what stays outside the schema — the route's error format, authorization beyond "who owns this row".

---

## Example

`POST /posts` parses a hand-written `z.object({ slug, title, authorId, published, publishedAt })` and spreads it into `insert`: any caller can post as someone else, publish without review, and every client that sends `publishedAt` as JSON gets a 400. Rewritten: `createSchemaFactory({ coerce: { date: true } }).createInsertSchema(posts, { slug: (s) => s.regex(…) }).pick({ slug, title, publishedAt }).strict()`, the author added from the session after parsing, and a `postResponse` from `createSelectSchema`. Tests cover the rejected `authorId`, the coerced date and the slug format. Cites `DRZ-ZOD-01`, `DRZ-ZOD-03`, `DRZ-ZOD-04`.
