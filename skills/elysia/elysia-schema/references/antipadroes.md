# Antipadrões, com ID

> Confira em `mapa-de-ids.md`. `ELYSIA-TYPE-11` é apelido de `ELYSIA-APP-04` **só** na cláusula de `strict` — pelo resto (paridade de versão de `elysia`) continua citável.

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| Tipo do payload reescrito à mão | `ELYSIA-TYPE-01` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| Upload validado por `content-type` declarado | `ELYSIA-TYPE-02` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| Nome de header capitalizado no schema | `ELYSIA-TYPE-03` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| `t.Number` no `body` contando com coerção | `ELYSIA-TYPE-04` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| `guard` sem `schema: 'standalone'` substituindo o da rota | `ELYSIA-TYPE-05` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| Rota multi-status sem `response` como mapa | `ELYSIA-TYPE-06` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| Zod/Valibot sem `mapJsonSchema` (some do OpenAPI) | `ELYSIA-TYPE-07` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| Usar `data` do Eden sem checar `error` | `ELYSIA-TYPE-08` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| `queryFn` que não lança em erro do Eden | `ELYSIA-TYPE-09` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| `parseDate: true` alimentando cache do Query | `ELYSIA-TYPE-10` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| Versões diferentes de `elysia` entre cliente e servidor | `ELYSIA-TYPE-11` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| `allowUnsafeValidationDetails` em produção | `ELYSIA-TYPE-12` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| Listagem devolvendo array cru | `ELYSIA-TYPE-13` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) |
| `strict: false` num dos lados do Eden | `ELYSIA-APP-04` | [Elysia](../../../../knowledge-base/docs/elysia.md) |
| `@elysiajs/swagger` para OpenAPI | `ELYSIA-APP-07` | [Elysia](../../../../knowledge-base/docs/elysia.md) |
| Instância exportada como valor | `ELYSIA-APP-05` | [Elysia](../../../../knowledge-base/docs/elysia.md) |

