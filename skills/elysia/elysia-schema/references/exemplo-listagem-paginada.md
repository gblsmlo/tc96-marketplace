# Exemplo trabalhado — listagem paginada consumida pelo Query

Tarefa: *"listagem paginada de faturas, consumida pelo front com TanStack Query"*.

**Servidor:**

```ts
const FaturasQuery = t.Object({
 pagina: t.Number({ default: 1 }), // query COAGE string — ELYSIA-TYPE-04
 status: t.Optional(t.String),
});

const app = new Elysia
.get('/faturas', ({ query }) => listar(query), {
 query: FaturasQuery,
 response: { // mapa por status — ELYSIA-TYPE-06
 200: t.Object({ // envelope — ELYSIA-TYPE-13
 itens: t.Array(t.Object({ id: t.String, valor: t.Number })),
 total: t.Number,
 hasMore: t.Boolean,
 }),
 401: t.Object({ erro: t.String }),
 },
 });

export type App = typeof app;
export type FaturasQuery = typeof FaturasQuery.static; // ELYSIA-TYPE-01
```

**Cliente:**

```ts
import { treaty } from '@elysia/eden';
import type { App } from '@escopo/server';

export const api = treaty<App>('http://localhost:3333', {
 parseDate: false, // structural sharing — ELYSIA-TYPE-10
});

export const faturasQuery = (p: FaturasQuery) => ({
 queryKey: ['faturas', p],
 queryFn: async => {
 const { data, error } = await api.faturas.get({ query: p });
 if (error) throw error; // sem isso a query fica em success — ELYSIA-TYPE-09
 return data; // data é null em qualquer >= 300 — ELYSIA-TYPE-08
 },
});
```

**O que as decisões evitaram:**

| Decisão | Alternativa que dói | Regra |
| --- | --- | --- |
| envelope com `total`/`hasMore` | array cru, sem como paginar depois | `ELYSIA-TYPE-13` |
| `response` como mapa | `401` chegando ao Eden como `unknown` | `ELYSIA-TYPE-06` |
| `if (error) throw error` | query em `success`, retry morto, Error Boundary cego | `ELYSIA-TYPE-09` |
| `parseDate: false` | re-render de toda a lista a cada refetch | `ELYSIA-TYPE-10` |
| `typeof FaturasQuery.static` | tipo reescrito à mão, divergindo do schema | `ELYSIA-TYPE-01` |
| `pagina` em `query`, não em `body` | coerção que não aconteceria no body | `ELYSIA-TYPE-04` |
| `export type App` | valor exportado, e o Eden sem as rotas | `ELYSIA-APP-05` |

---

