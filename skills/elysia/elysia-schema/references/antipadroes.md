# Antipatterns, with IDs

> Check `mapa-de-ids.md`. `ELYSIA-TYPE-11` is an alias of `ELYSIA-APP-04` **only** in the `strict` clause — for the rest (parity of the `elysia` version) it stays citable.

| Antipattern | ID | Satellite |
| --- | --- | --- |
| Payload type rewritten by hand | `ELYSIA-TYPE-01` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| Upload validated by the declared `content-type` | `ELYSIA-TYPE-02` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| Capitalized header name in the schema | `ELYSIA-TYPE-03` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| `t.Number` in the `body` relying on coercion | `ELYSIA-TYPE-04` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| `guard` without `schema: 'standalone'` replacing the route's | `ELYSIA-TYPE-05` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| Multi-status route without `response` as a map | `ELYSIA-TYPE-06` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| Zod/Valibot without `mapJsonSchema` (disappears from OpenAPI) | `ELYSIA-TYPE-07` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| Using Eden's `data` without checking `error` | `ELYSIA-TYPE-08` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| `queryFn` that does not throw on an Eden error | `ELYSIA-TYPE-09` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| `parseDate: true` feeding a Query cache | `ELYSIA-TYPE-10` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| Different `elysia` versions between client and server | `ELYSIA-TYPE-11` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| `allowUnsafeValidationDetails` in production | `ELYSIA-TYPE-12` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| Listing returning a raw array | `ELYSIA-TYPE-13` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| `strict: false` on either side of Eden | `ELYSIA-APP-04` | [Elysia](../../../../knowledge-base/docs/elysia.md) |
| `@elysiajs/swagger` for OpenAPI | `ELYSIA-APP-07` | [Elysia](../../../../knowledge-base/docs/elysia.md) |
| Instance exported as a value | `ELYSIA-APP-05` | [Elysia](../../../../knowledge-base/docs/elysia.md) |

