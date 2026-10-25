# Antipatterns — Eden

| Antipattern | What happens | ID | Doc section |
| --- | --- | --- | --- |
| `import { App } from '@acme/server'` | the server lands in the client bundle | `ELYSIA-TYPE-14` | § 1 |
| `data!` or `data.x` before checking `error` | `data` is `null` on any status >= 300, redirects too | `ELYSIA-TYPE-08` | § 3 |
| `if (error instanceof Error) toast(error.message)` | always true; the message is `"[object Object]"` | `ELYSIA-TYPE-15` | § 3 |
| a `switch (error.status)` without `case 422` | validation failures fall into the default | `ELYSIA-TYPE-15` | § 3 |
| `queryFn: () => api.orders.get()` | a 404 is a `success` with null data | `ELYSIA-TYPE-09` | § 4 |
| a throwing `queryFn` with the default retry | 4xx retried three times; the error screen comes late | `ELYSIA-TYPE-16` | § 4 |
| default `parseDate` feeding the Query cache | a `Date` per refetch; every consumer re-renders; the type lies | `ELYSIA-TYPE-10` | § 4 |
| `onResponse: (r) => { log(r); return r }` | the response becomes `data`; errors go undetected | `ELYSIA-TYPE-17` | § 2 |
| `useMutation` without the Eden error type | `error.status` does not exist for TypeScript | — | § 5 |
| mixing `throwHttpError: true` and checked results | inconsistent error handling across call sites | `ELYSIA-TYPE-09` | § 4 |
| two `elysia` versions; `strict` off on one side | the client degrades to `any` silently | `ELYSIA-TYPE-11`, `ELYSIA-APP-04` | § 10 |
| a paginated list returning a bare array | the UI cannot know whether a next page exists | `ELYSIA-TYPE-13` | § 6 |
| `http://x` as the test origin; asserting abort on `treaty(app)` | 404 everywhere; the instance form ignores the signal | — | § 7 |
| `edenTreaty(...)` | Treaty 1, legacy | — | § 9 |

Sections refer to [Elysia - Eden](../../docs/elysia-eden.md).
