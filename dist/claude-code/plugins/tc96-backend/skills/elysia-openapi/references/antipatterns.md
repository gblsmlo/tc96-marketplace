# Antipatterns — OpenAPI

| Antipattern | What happens | ID | Doc section |
| --- | --- | --- | --- |
| `@elysiajs/swagger` | discontinued | `ELYSIA-APP-07` | [Elysia](../../../docs/elysia/elysia.md) § 3 |
| a route with no `response` | no `responses` in the spec | `ELYSIA-TYPE-06` | § 2 |
| statuses the route answers but does not declare (401 from a hook, 404, 422) | consumers and generators do not know them | `ELYSIA-TYPE-06` | § 2 |
| `response: { 201 }` with `return value` | documented 201, sent 200 | `ELYSIA-CORE-04` | § 2 |
| generated `operationId`s under a code generator | collisions break or drop methods | `ELYSIA-TYPE-18` | § 4 |
| `mapJsonSchema: { zod: z.toJSONSchema }` with Zod 4 | request bodies in the output view: defaults required | `ELYSIA-TYPE-07` | § 6 |
| Zod 3, Valibot or Effect routes without `mapJsonSchema` | empty schemas in the spec | `ELYSIA-TYPE-07` | § 6 |
| docs served everywhere by default | the API's shape is public; the plugin has no auth | `ELYSIA-TYPE-19` | § 8 |
| protected routes without `security`; public routes without `security: []` | the spec misdescribes access | `ELYSIA-TYPE-20` | § 5 |
| `detail` on a guard and on its routes | the guard overwrites the route's tags and summary | — | § 3 |
| `exclude.tags` with routes that lack `detail` | `/openapi/json` answers 500 (1.4.16) | — | § 8 |
| `fromTypes()` relied on under plain `bun test` | silently empty without `tsc` on `PATH` | — | § 7 |
| `withHeader` | does not exist; `withHeaders` documents only | — | § 7 |
| `.post('/')` in a prefixed module | documented as `/orders/` | — | § 9 |

Sections refer to [Elysia - OpenAPI](../../../docs/elysia/elysia-openapi.md) unless named.
