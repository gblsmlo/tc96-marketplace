# Coercion, response and guard

> Steps 0 to 5. The text of the rules lives in [Elysia - Schema e Eden](../../../../knowledge-base/elysia-schema-e-eden.md).

> **One schema declaration produces four effects:** runtime validation, a TypeScript type, an OpenAPI document, and the Eden client's type.

That changes the economics: a badly declared schema does not get one thing wrong — it gets four wrong. And that is why `ELYSIA-TYPE-01` forbids rewriting the type by hand: `typeof S.static` derives from the schema, and a manual copy will diverge.

---

## Step 1 — Coercion depends on the source

The most consequential rule in the family, and the least intuitive:

| Source | Does `t.Number` coerce a string? |
| --- | --- |
| `params` | **yes** |
| `query` | **yes** |
| `headers` | **yes** |
| `cookie` | **yes** |
| **`body`** | **no** |

`ELYSIA-TYPE-04`: a numeric `body` field **never** relies on coercion. A `t.Number` in the body receiving `"100"` from malformed JSON fails validation — and the developer concludes the schema is wrong.

And `ELYSIA-TYPE-03`: a `headers` schema declares names in **lowercase** — Elysia normalizes, and a capitalized name **never matches**. The symptom is a required header that "is never sent".

---

## Step 2 — `response` per status

```ts
// ✓ map by status — ELYSIA-TYPE-06
response: {
 200: t.Object({ id: t.String }),
 404: t.Object({ error: t.String }),
 422: t.Object({ error: t.String }),
}
```

Without the map, **the error reaches Eden as `unknown`** — and the client loses exactly the information that justified using a typed client.

And `ELYSIA-TYPE-13`: a paginated listing declares in `response` an envelope with `items`, `total` and `hasMore`. Returning the raw array closes the door to pagination without breaking the contract.

---

## Step 3 — `guard` and composition

`ELYSIA-TYPE-05`: a `guard` schema that has to **add to** the route's declares `schema: 'standalone'`. The default is **`override`** — the guard's schema **replaces** the route's.

```ts
// ✗ the route's schema is replaced
.guard({ headers: t.Object({ authorization: t.String }) })

// ✓ adds
.guard({ schema: 'standalone', headers: t.Object({ authorization: t.String }) })
```

Symptom of forgetting: the route's body validation disappears, silently, and the handler receives anything.

---

## Step 4 — Uploads

`ELYSIA-TYPE-02`: an upload validated through Standard Schema uses **`fileType`** — generic validators check the **declared** `content-type`, which the client controls. `fileType` inspects the content.

It is a security finding: an `.exe` renamed to `.png` passes `content-type` validation and does not pass `fileType`.

---

## Step 5 — OpenAPI

| Rule | What it requires |
| --- | --- |
| `ELYSIA-APP-07` | `@elysia/openapi`, **never** `@elysiajs/swagger` (discontinued) |
| `ELYSIA-TYPE-07` | a route declared with Zod/Valibot/Effect needs `mapJsonSchema` in the plugin — **or it disappears from the documentation** |
| `ELYSIA-TYPE-12` | `allowUnsafeValidationDetails: true` **never** in production |

**`ELYSIA-TYPE-07` fails silently:** the route works, validates, and simply does not appear in the OpenAPI document. In a project mixing `t` and Zod, half the documentation disappears without warning.

**`ELYSIA-TYPE-12` is global and leaks the internal contract:** the option makes the error response publish validation detail — field name, expected format, internal structure.
