---
generated-by: skills/elysia/elysia-diagnose/scripts/generate-id-map.sh
generated-at: 2026-10-25
---

# ID map `ELYSIA-*`

> An index, not a copy: it says **where** a rule's body lives, never what it says.
> Regenerate with `bash skills/elysia/elysia-diagnose/scripts/generate-id-map.sh` — the same file is written into every Elysia skill.

## Canonical IDs and partial aliases


Three principles appear in more than one family, because each satellite has to stand on its own. **To cite, always use the canonical ID** — the other one is an alias and should not appear in a review.

| Principle | Canonical | Alias |
| --- | --- | --- |
| `strict: true` and TypeScript >= 5.0 on both sides of the Eden boundary | `ELYSIA-APP-04` | `ELYSIA-TYPE-11`, **for this clause only** |
| An expected failure is signalled with `return status(...)`, not with `throw` | `ELYSIA-CORE-03` | `ELYSIA-LIFE-10` (the same principle applied inside a `macro`) |
| The handler destructures the context; an external function annotated with `Context` is not accepted | `ELYSIA-CORE-02` | `ELYSIA-APP-03`, **for this clause only** |

The two "for this clause only" are deliberate, because the two rules are not entirely redundant:

- **`ELYSIA-TYPE-11` remains citable on its own** for what belongs only to it: **`elysia` version parity between client and server**, which `ELYSIA-APP-04` does not cover and which is the most common reason Eden degrades to `any`. That is why it is in § 6.1 — version parity needs to travel with the minimum path. When citing the `strict: true` requirement alone, use `ELYSIA-APP-04`.
- **`ELYSIA-APP-09` is not an alias of anything.** It mirrors `HONO-APP-03` in the neighbouring family, but the motivation there is different; here there is an `env` export in the package itself.
- **`ELYSIA-APP-03` remains citable on its own** for what belongs only to it: the legitimacy of a literal value and `file()` in place of the handler. When citing context destructuring, use `ELYSIA-CORE-02`.


## Full index

| ID | Body in | Section |
| --- | --- | --- |
| `ELYSIA-APP-01` | [Elysia](../../docs/elysia.md) | 6. Normative rules |
| `ELYSIA-APP-02` | [Elysia](../../docs/elysia.md) | 6. Normative rules |
| `ELYSIA-APP-03` | [Elysia](../../docs/elysia.md) | 6. Normative rules |
| `ELYSIA-APP-04` | [Elysia](../../docs/elysia.md) | 6. Normative rules |
| `ELYSIA-APP-05` | [Elysia](../../docs/elysia.md) | 6. Normative rules |
| `ELYSIA-APP-06` | [Elysia](../../docs/elysia.md) | 6. Normative rules |
| `ELYSIA-APP-07` | [Elysia](../../docs/elysia.md) | 6. Normative rules |
| `ELYSIA-APP-08` | [Elysia](../../docs/elysia.md) | 6. Normative rules |
| `ELYSIA-APP-09` | [Elysia](../../docs/elysia.md) | 6. Normative rules |
| `ELYSIA-CORE-01` | [Elysia - Routing and Handler](../../docs/elysia-routing-and-handler.md) | 2. Instance, routes and path precedence |
| `ELYSIA-CORE-02` | [Elysia - Routing and Handler](../../docs/elysia-routing-and-handler.md) | 1. Concept: the context is an accumulation of earlier decisions, not a fixed object |
| `ELYSIA-CORE-03` | [Elysia - Routing and Handler](../../docs/elysia-routing-and-handler.md) | 5. Errors: taxonomy, return × exception, and customization |
| `ELYSIA-CORE-04` | [Elysia - Routing and Handler](../../docs/elysia-routing-and-handler.md) | 4. Response shapes |
| `ELYSIA-CORE-05` | [Elysia - Routing and Handler](../../docs/elysia-routing-and-handler.md) | 4. Response shapes |
| `ELYSIA-CORE-06` | [Elysia - Routing and Handler](../../docs/elysia-routing-and-handler.md) | 4. Response shapes |
| `ELYSIA-CORE-07` | [Elysia - Routing and Handler](../../docs/elysia-routing-and-handler.md) | 5. Errors: taxonomy, return × exception, and customization |
| `ELYSIA-CORE-08` | [Elysia - Routing and Handler](../../docs/elysia-routing-and-handler.md) | 5. Errors: taxonomy, return × exception, and customization |
| `ELYSIA-CORE-09` | [Elysia - Routing and Handler](../../docs/elysia-routing-and-handler.md) | 6. Testing without starting a server |
| `ELYSIA-CORE-10` | [Elysia - Routing and Handler](../../docs/elysia-routing-and-handler.md) | 6. Testing without starting a server |
| `ELYSIA-LIFE-01` | [Elysia - Lifecycle and Plugins](../../docs/elysia-lifecycle-and-plugins.md) | 5. Scope: `local`, `scoped`, `global` and the `as()` method |
| `ELYSIA-LIFE-02` | [Elysia - Lifecycle and Plugins](../../docs/elysia-lifecycle-and-plugins.md) | 3. `state` × `decorate` × `derive` × `resolve` |
| `ELYSIA-LIFE-03` | [Elysia - Lifecycle and Plugins](../../docs/elysia-lifecycle-and-plugins.md) | 4. A plugin is an instance, and `use()` is the only way to compose |
| `ELYSIA-LIFE-04` | [Elysia - Lifecycle and Plugins](../../docs/elysia-lifecycle-and-plugins.md) | 2. The lifecycle order |
| `ELYSIA-LIFE-05` | [Elysia - Lifecycle and Plugins](../../docs/elysia-lifecycle-and-plugins.md) | 3. `state` × `decorate` × `derive` × `resolve` |
| `ELYSIA-LIFE-06` | [Elysia - Lifecycle and Plugins](../../docs/elysia-lifecycle-and-plugins.md) | 3. `state` × `decorate` × `derive` × `resolve` |
| `ELYSIA-LIFE-07` | [Elysia - Lifecycle and Plugins](../../docs/elysia-lifecycle-and-plugins.md) | 4. A plugin is an instance, and `use()` is the only way to compose |
| `ELYSIA-LIFE-08` | [Elysia - Lifecycle and Plugins](../../docs/elysia-lifecycle-and-plugins.md) | 5. Scope: `local`, `scoped`, `global` and the `as()` method |
| `ELYSIA-LIFE-09` | [Elysia - Lifecycle and Plugins](../../docs/elysia-lifecycle-and-plugins.md) | 5. Scope: `local`, `scoped`, `global` and the `as()` method |
| `ELYSIA-LIFE-10` | [Elysia - Lifecycle and Plugins](../../docs/elysia-lifecycle-and-plugins.md) | 6. `macro`: reusable hook, activated declaratively |
| `ELYSIA-LIFE-11` | [Elysia - Lifecycle and Plugins](../../docs/elysia-lifecycle-and-plugins.md) | 8. Official plugins in production |
| `ELYSIA-LIFE-12` | [Elysia - Lifecycle and Plugins](../../docs/elysia-lifecycle-and-plugins.md) | 8. Official plugins in production |
| `ELYSIA-TYPE-01` | [Elysia - Schema and Validation](../../docs/elysia-schema-and-validation.md) | 1. Concept: one declaration produces four artifacts — duplicating any of them is a regression |
| `ELYSIA-TYPE-02` | [Elysia - Schema and Validation](../../docs/elysia-schema-and-validation.md) | 2. `t` × Standard Schema: where Zod still makes sense |
| `ELYSIA-TYPE-03` | [Elysia - Schema and Validation](../../docs/elysia-schema-and-validation.md) | 3. Per-route schema and automatic coercion |
| `ELYSIA-TYPE-04` | [Elysia - Schema and Validation](../../docs/elysia-schema-and-validation.md) | 3. Per-route schema and automatic coercion |
| `ELYSIA-TYPE-05` | [Elysia - Schema and Validation](../../docs/elysia-schema-and-validation.md) | 4. `guard`, precedence and `standalone`; reference models |
| `ELYSIA-TYPE-06` | [Elysia - Schema and Validation](../../docs/elysia-schema-and-validation.md) | 5. `response` per status, and the validation error |
| `ELYSIA-TYPE-07` | [Elysia - OpenAPI](../../docs/elysia-openapi.md) | 6. Zod, Valibot and other Standard Schema libraries |
| `ELYSIA-TYPE-08` | [Elysia - Eden](../../docs/elysia-eden.md) | 3. The return value: a union you narrow by status |
| `ELYSIA-TYPE-09` | [Elysia - Eden](../../docs/elysia-eden.md) | 4. The TanStack Query bridge |
| `ELYSIA-TYPE-10` | [Elysia - Eden](../../docs/elysia-eden.md) | 4. The TanStack Query bridge |
| `ELYSIA-TYPE-11` | [Elysia - Eden](../../docs/elysia-eden.md) | 10. When Eden returns `any` (or loses a route) |
| `ELYSIA-TYPE-12` | [Elysia - Schema and Validation](../../docs/elysia-schema-and-validation.md) | 5. `response` per status, and the validation error |
| `ELYSIA-TYPE-13` | [Elysia - Eden](../../docs/elysia-eden.md) | 6. The paginated envelope |
| `ELYSIA-TYPE-14` | [Elysia - Eden](../../docs/elysia-eden.md) | 1. Concept: the type crosses, the code does not |
| `ELYSIA-TYPE-15` | [Elysia - Eden](../../docs/elysia-eden.md) | 3. The return value: a union you narrow by status |
| `ELYSIA-TYPE-16` | [Elysia - Eden](../../docs/elysia-eden.md) | 4. The TanStack Query bridge |
| `ELYSIA-TYPE-17` | [Elysia - Eden](../../docs/elysia-eden.md) | 4. The TanStack Query bridge |
| `ELYSIA-TYPE-18` | [Elysia - OpenAPI](../../docs/elysia-openapi.md) | 4. `operationId` for code generators |
| `ELYSIA-TYPE-19` | [Elysia - OpenAPI](../../docs/elysia-openapi.md) | 8. Exposing the docs |
| `ELYSIA-TYPE-20` | [Elysia - OpenAPI](../../docs/elysia-openapi.md) | 5. Security schemes |
