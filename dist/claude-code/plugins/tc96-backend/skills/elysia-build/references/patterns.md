# Patterns — routes, errors, cookies, SSE, tests, auth

Every block below passed `bun test` and `tsc --noEmit` on elysia 1.4.30 before it was written here. Copy the shape, rename the domain.

---

## 1. A feature module: an instance with a prefix

```ts
import { Elysia, t } from 'elysia'

class OutOfStock extends Error {
  status = 409                                              // the default status, even with no onError
  constructor(public sku: string) { super(`out of stock: ${sku}`) }
}

export const ordersModule = new Elysia({ prefix: '/orders' })
  .error({ OUT_OF_STOCK: OutOfStock })                      // own code, narrowing in onError — ELYSIA-CORE-08
  .onError(({ code, error, status }) => {                   // before the routes — ELYSIA-CORE-01
    if (code === 'OUT_OF_STOCK') return status(409, { error: 'out_of_stock', sku: error.sku })
  })
  .get('/:id', ({ params: { id }, status }) => {
    const order = orders.get(id)
    if (!order) return status(404, { error: 'not_found' })  // expected: return — ELYSIA-CORE-03
    return order
  }, {
    params: t.Object({ id: t.Number() }),                   // path params coerce: "7" -> 7
    response: {
      200: t.Object({ id: t.Number(), sku: t.String(), quantity: t.Number() }),
      404: t.Object({ error: t.String() })
    }
  })
  .post('/', ({ body, status }) => {
    if ((stock.get(body.sku) ?? 0) < body.quantity) throw new OutOfStock(body.sku)
    const order = { id: orders.size + 1, ...body }
    orders.set(order.id, order)
    return status(201, order)                               // a declared 201 must go out through status — ELYSIA-CORE-04
  }, {
    body: t.Object({ sku: t.String({ minLength: 3 }), quantity: t.Number({ minimum: 1 }) }),
    response: {
      201: t.Object({ id: t.Number(), sku: t.String(), quantity: t.Number() }),
      409: t.Object({ error: t.String(), sku: t.String() })
    }
  })
```

`return order` with only `201` declared would go out as **200**, unvalidated. Register a prefixed collection route as `''`, not `'/'`, and never mix the two in one module: with `.get('')` next to `.post('/')`, the POST answers 404 at both `/orders` and `/orders/` (verified). `t.Number` in a JSON body rejects `"2"` (422); `t.Integer` would coerce it.

## 2. The app: one onError for the unexpected, first in the chain

```ts
export const app = new Elysia()
  .onError(({ code, error, path, status }) => {
    // Registered first, so it runs first for every module below. Answer only what nobody else
    // owns: returning for every code would swallow OUT_OF_STOCK before the module sees it.
    if (code !== 'UNKNOWN' && code !== 'INTERNAL_SERVER_ERROR') return
    logger.error({ code, path, error })                     // log the detail…
    return status(500, { error: 'internal_error' })         // …answer generically — ELYSIA-CORE-07
  })
  .use(ordersModule)

export type App = typeof app                               // ELYSIA-APP-05
```

Without this handler, an unexpected `throw new Error('connect ECONNREFUSED 10.0.0.3:5432')` is sent to the client **as the 500 body**, also with `NODE_ENV=production`. A thrown `status(404, …)` reaches `onError` with `code === 404` (the number), not `'NOT_FOUND'`.

## 3. A signed, httpOnly session cookie

```ts
import { Elysia, env } from 'elysia'

const sessions = new Elysia({ cookie: { secrets: env.COOKIE_SECRET!, sign: ['session'] } })   // ELYSIA-APP-08/09
  .post('/sign-in', ({ cookie: { session } }) => {
    session.set({ value: { userId: 42 }, httpOnly: true, secure: true, sameSite: 'lax', maxAge: 7 * 86400, path: '/' })
    return 'ok'
  })
  .get('/me', ({ cookie: { session }, status }) => {
    if (!session.value) return status(401, { error: 'unauthenticated' })
    return session.value as { userId: number }
  })
```

Signed **and** `httpOnly` — `ELYSIA-CORE-05` is both halves. A tampered signature answers 400 (`INVALID_COOKIE_SIGNATURE`).

## 4. SSE: headers before the first yield

```ts
import { Elysia, sse } from 'elysia'

new Elysia().get('/progress', function* progress({ set }) {
  set.headers['x-job'] = 'import'                           // after the first yield it is ignored — ELYSIA-CORE-06
  for (const pct of [50, 100]) yield sse({ event: 'progress', data: { pct } })
})
```

`content-type` becomes `text/event-stream`. Check `Bun.serve`'s `idleTimeout` for long streams.

## 5. Tests through app.handle

```ts
import { test, expect } from 'bun:test'

const req = (path: string, init?: RequestInit) => app.handle(new Request(`http://localhost${path}`, init))
const json = (body: unknown) => ({ method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify(body) })

test('creates, finds, refuses', async () => {
  expect((await req('/orders', json({ sku: 'ABC', quantity: 2 }))).status).toBe(201)
  expect((await req('/orders/99')).status).toBe(404)
  expect((await req('/orders', json({ sku: 'ABC', quantity: '2' }))).status).toBe(422)   // validation default
})

test('a lazy module exists only after app.modules', async () => {
  const lazy = new Elysia().use(import('./lazy-module'))
  await lazy.modules                                        // ELYSIA-CORE-10
  expect((await lazy.handle(new Request('http://localhost/lazy'))).status).toBe(200)
})
```

- Use a real host (`http://localhost/...`). In 1.4.30 a one-label host such as `http://x/orders` answers **404** for every route.
- Keep state out of module scope, or build the app per test file (`createApp()`): a `Map` shared at module level makes one test file's orders consume the stock another file asserts on, and the suite fails under `bun test --randomize`.
- Await `app.modules` **before the first request**. A lazy `import()` recovers after the await; an async plugin *function* that was still pending when a request arrived keeps that route 404 for good.

## 6. An auth plugin with a declared scope (load the lifecycle doc)

```ts
import { Elysia, t } from 'elysia'

// Option A — every route after .use(auth) is protected; forgetting fails closed.
export const auth = new Elysia({ name: 'auth' })               // named: hooks run once however many modules use it — ELYSIA-LIFE-03
  .guard({ headers: t.Object({ authorization: t.Optional(t.String()) }) })
  .resolve({ as: 'scoped' }, function resolveUser({ headers: { authorization }, status }) {  // resolve, never derive — ELYSIA-LIFE-02
    const user = authorization?.startsWith('Bearer ') ? tokens.get(authorization.slice(7)) : undefined
    if (!user) return status(401, { error: 'unauthenticated' }) // return, never throw — ELYSIA-LIFE-10
    return { user }
  })

// Option B — a macro: routes opt in; open and closed routes share an instance; forgetting fails open.
export const roles = new Elysia({ name: 'roles' })
  .use(auth)
  .macro({
    role: (needed: 'admin' | 'member') => ({
      beforeHandle({ user, status }) {
        if (needed === 'admin' && user?.role !== 'admin') return status(403, { error: 'forbidden' })
      }
    })
  })
  .as('scoped')   // scoped climbs ONE level: without this, auth's resolve stops at `roles` and the app is open

const app = new Elysia()
  .get('/health', () => 'ok')                                  // before .use(): stays public
  .use(roles)
  .get('/me', ({ user }) => user)
  .delete('/orders/:id', ({ params: { id } }) => ({ deleted: id }), { role: 'admin', params: t.Object({ id: t.Number() }) })
```

Validation runs **before** `resolve`: an anonymous request with a bad body gets a 422 that describes the schema, not a 401 (verified). If unauthenticated callers must see 401 first, add a presence check in `onRequest` on the protected prefix — `if (!request.headers.get('authorization')) return status(401, …)` — and keep the real decision in `resolve`. Test "no token + bad body".

The test that proves the scope hits the **app's** routes, not the plugin's (`ELYSIA-LIFE-08`): `/health` 200, `/me` without a token 401, a member deleting 403, an admin deleting 200. Writing this pattern, the first version left out `.as('scoped')` on `roles` and `/me` answered **200** without a token — the test caught it; reading did not.
