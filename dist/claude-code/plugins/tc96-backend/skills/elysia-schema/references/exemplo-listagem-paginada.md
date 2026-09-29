# Worked example — a paginated listing consumed by Query

Task: *"a paginated invoice listing, consumed by the front end with TanStack Query"*.

**Server:**

```ts
const InvoicesQuery = t.Object({
 page: t.Number({ default: 1 }), // query DOES coerce strings — ELYSIA-TYPE-04
 status: t.Optional(t.String),
});

const app = new Elysia
.get('/invoices', ({ query }) => list(query), {
 query: InvoicesQuery,
 response: { // map by status — ELYSIA-TYPE-06
 200: t.Object({ // envelope — ELYSIA-TYPE-13
 items: t.Array(t.Object({ id: t.String, amount: t.Number })),
 total: t.Number,
 hasMore: t.Boolean,
 }),
 401: t.Object({ error: t.String }),
 },
 });

export type App = typeof app;
export type InvoicesQuery = typeof InvoicesQuery.static; // ELYSIA-TYPE-01
```

**Client:**

```ts
import { treaty } from '@elysia/eden';
import type { App } from '@scope/server';

export const api = treaty<App>('http://localhost:3333', {
 parseDate: false, // structural sharing — ELYSIA-TYPE-10
});

export const invoicesQuery = (p: InvoicesQuery) => ({
 queryKey: ['invoices', p],
 queryFn: async => {
 const { data, error } = await api.invoices.get({ query: p });
 if (error) throw error; // without this the query stays in success — ELYSIA-TYPE-09
 return data; // data is null on any >= 300 — ELYSIA-TYPE-08
 },
});
```

**What these decisions prevented:**

| Decision | Alternative that hurts | Rule |
| --- | --- | --- |
| envelope with `total`/`hasMore` | a raw array, with no way to paginate later | `ELYSIA-TYPE-13` |
| `response` as a map | `401` reaching Eden as `unknown` | `ELYSIA-TYPE-06` |
| `if (error) throw error` | query in `success`, retry dead, Error Boundary blind | `ELYSIA-TYPE-09` |
| `parseDate: false` | the whole list re-rendering on every refetch | `ELYSIA-TYPE-10` |
| `typeof InvoicesQuery.static` | a type rewritten by hand, diverging from the schema | `ELYSIA-TYPE-01` |
| `page` in `query`, not in `body` | coercion that would not happen in the body | `ELYSIA-TYPE-04` |
| `export type App` | an exported value, and Eden without the routes | `ELYSIA-APP-05` |
