# Patterns — Eden clients that passed a test

## Contents

- [1. The server's side of the contract](#1-the-servers-side-of-the-contract)
- [2. The client module: configured once](#2-the-client-module-configured-once)
- [3. Narrowing by status, 422 included](#3-narrowing-by-status-422-included)
- [4. Query options: throw, retry only 5xx](#4-query-options-throw-retry-only-5xx)
- [5. A mutation whose error the form can read](#5-a-mutation-whose-error-the-form-can-read)
- [6. Pagination](#6-pagination)
- [7. Tests: two forms](#7-tests-two-forms)

Every block passed `bun test` and `tsc --noEmit` on elysia 1.4.30, @elysia/eden 1.4.10 and @tanstack/query-core 5.104.5.

---

## 1. The server's side of the contract

```ts
// server/src/app.ts — the chain ends in the exported type
const Order = t.Object({ id: t.Number(), sku: t.String(), quantity: t.Number(), createdAt: t.String() })

export const app = new Elysia()
  .model({
    Order,
    OrderPage: t.Object({ items: t.Array(Order), total: t.Number(), hasMore: t.Boolean() }),   // ELYSIA-TYPE-13
    ApiError: t.Object({ error: t.String() }),
    StockError: t.Object({ error: t.Literal('out_of_stock'), sku: t.String() })
  })
  .get('/orders/:id', ({ params: { id }, status }) => {
    const order = db.find((o) => o.id === id)
    if (!order) return status(404, { error: 'not_found' })      // returned: visible to the client
    return order
  }, { params: t.Object({ id: t.Number() }), response: { 200: 'Order', 401: 'ApiError', 404: 'ApiError' } })
  .post('/orders', ({ body, status }) => {
    if (body.sku === 'GONE') return status(409, { error: 'out_of_stock' as const, sku: body.sku })
    return status(201, { id: db.length + 1, ...body, createdAt: new Date().toISOString() })
  }, {
    body: t.Object({ sku: t.String({ minLength: 3 }), quantity: t.Number({ minimum: 1 }) }),
    response: { 201: 'Order', 401: 'ApiError', 409: 'StockError' }
  })

export type App = typeof app                                       // ELYSIA-APP-05
```

## 2. The client module: configured once

```ts
// web/src/api.ts
import { treaty } from '@elysia/eden'
import type { App } from '@acme/server'                          // type only — ELYSIA-TYPE-14

export const createApi = (baseUrl: string, getToken: () => string | undefined, fetcher?: typeof fetch) =>
  treaty<App>(baseUrl, {
    parseDate: false,                                            // ELYSIA-TYPE-10
    headers: () => {
      const token = getToken()
      return token ? { authorization: `Bearer ${token}` } : undefined
    },
    ...(fetcher ? { fetcher } : {})
  })

export const api = createApi(import.meta.env.VITE_API_URL, () => session.token())

// Unwrap once, at the boundary — ELYSIA-TYPE-08/09
export async function unwrap<R extends { data: unknown; error: unknown }>(call: Promise<R>) {
  const { data, error } = await call
  if (error) throw error
  return data as Exclude<R['data'], null>
}
```

## 3. Narrowing by status, 422 included

```ts
const { data, error } = await api.orders({ id }).get()
if (error) {
  switch (error.status) {
    case 401: return redirectToSignIn()
    case 404: return showNotFound(error.value.error)             // value typed by response[404]
    case 422: return showInvalid()                               // any route with a schema or a :param has it
    default:  throw error
  }
}
```

## 4. Query options: throw, retry only 5xx

```ts
export const orderOptions = (id: number) =>
  queryOptions({
    queryKey: ['orders', 'detail', id] as const,
    queryFn: ({ signal }) => unwrap(api.orders({ id }).get({ fetch: { signal } })),
    retry: (failures, error: { status?: number }) => (error.status ?? 500) >= 500 && failures < 3,   // ELYSIA-TYPE-16
    staleTime: 60_000
  })
```

Verified: with a 404, the observer ends in `status: 'error'`, `error.status === 404`, after **one** call.

## 5. A mutation whose error the form can read

```tsx
import type { Treaty } from '@elysia/eden'

const create = useMutation<Treaty.Data<typeof api.orders.post>, Treaty.Error<typeof api.orders.post>, OrderInput>({
  mutationFn: (input) => unwrap(api.orders.post(input)),
  onSuccess: () => queryClient.invalidateQueries({ queryKey: ['orders', 'list'] })
})
const stockError = create.error?.status === 409 ? create.error.value : undefined   // { error: 'out_of_stock', sku }
```

Without the generics, TanStack types `error` as `Error` and `status` does not exist.

## 6. Pagination

```ts
export const ordersOptions = (page: number) =>
  queryOptions({
    queryKey: ['orders', 'list', { page }] as const,
    queryFn: ({ signal }) => unwrap(api.orders.get({ query: { page, pageSize: 20 }, fetch: { signal } })),
    placeholderData: keepPreviousData
  })
// next disabled by: isPlaceholderData || !data?.hasMore
```

A query key with a server `default` is still required on the client; pass it, or make it `t.Optional(t.Number({ default: 20 }))` on the server.

## 7. Tests: two forms

```ts
// the production client config, routed in-process — no port
const api = createApi('http://localhost', () => 'test-token',
  ((input: RequestInfo | URL, init?: RequestInit) => app.handle(new Request(input, init))) as typeof fetch)

// a server-side test typed end to end
const local = treaty(app, { headers: { authorization: 'Bearer test-token' } })
expect((await local.orders({ id: 1 }).get()).status).toBe(200)
```

`http://localhost`, not `http://x`: a one-label origin answers 404. `treaty(app)` ignores `fetch.signal`.
