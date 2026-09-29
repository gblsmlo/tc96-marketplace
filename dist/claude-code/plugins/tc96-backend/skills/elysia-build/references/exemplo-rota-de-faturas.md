# Worked example — invoices route

Task: *"an invoice approval route, with a limit error and a signed session"*.

```ts
import { Elysia, t } from 'elysia';
import { env } from 'elysia';

class LimitExceeded extends Error {}

const app = new Elysia({ cookie: { secrets: env.COOKIE_SECRET, sign: ['session'] } })
.error({ LIMIT_EXCEEDED: LimitExceeded }) // ELYSIA-CORE-08
.onError(({ code, error, status }) => { // registered BEFORE the routes
 if (code === 'LIMIT_EXCEEDED') return status(422, { error: 'limit' });
 console.error(error); // log the detail…
 return status(500, { error: 'internal' }); // …answer generically — ELYSIA-CORE-07
 })
.put('/invoices/:id/approval', async ({ params, cookie: { session }, status }) => {
 const user = session.value?.id;
 if (!user) return status(401, { error: 'no session' }); // ELYSIA-CORE-03

 const invoice = await find(params.id);
 if (!invoice) return status(404, { error: 'not found' });
 if (invoice.amount > limitOf(user)) throw new LimitExceeded;

 return approve(invoice);
 }, {
 params: t.Object({ id: t.String }),
 response: { // map by status — ELYSIA-TYPE-06
 200: t.Object({ id: t.String, status: t.String }),
 401: t.Object({ error: t.String }),
 404: t.Object({ error: t.String }),
 422: t.Object({ error: t.String }),
 },
 });

export type App = typeof app; // ELYSIA-APP-05
```

**What these decisions prevented:**

| Decision | Alternative that hurts | Rule |
| --- | --- | --- |
| `return status(401, …)` for no session | `throw`, and Eden does not know 401 exists | `ELYSIA-CORE-03` |
| `.error({ LIMIT_EXCEEDED })` | `if (e.message === 'limit')` in `onError`, without narrowing | `ELYSIA-CORE-08` |
| `console.error` + generic response | returning `error.message`, leaking the query and the path | `ELYSIA-CORE-07` |
| `onError` before the routes | registered afterwards, and affecting none of them | `ELYSIA-CORE-01` |
| `response` as a map by status | the error reaching Eden as `unknown` | `ELYSIA-TYPE-06` |
| continuous chaining up to the `export type` | the type stopping accumulating, and Eden losing routes | `ELYSIA-APP-01`, `ELYSIA-APP-05` |
| `env` from `elysia` | raw `process.env` | `ELYSIA-APP-09` |
| cookie signed in the constructor | a forgeable session cookie | `ELYSIA-CORE-05` |

Note that `throw` **is** used — for `LimitExceeded`, which is registered in `.error` and mapped in `onError` to `422`. The rule does not forbid `throw`; it requires that an **expected error that has to arrive typed** use `return status(...)`.
