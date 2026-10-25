# Probes and proof

## What the scan's lifecycle findings mean

| Finding | Shape it saw | What usually follows |
| --- | --- | --- |
| `ELYSIA-CORE-01` high | a hook, guard or `onError` after a route in the same chain | move it above the routes; this explains the symptom before any scope finding does |
| `ELYSIA-CORE-01` candidate | `.use(x)` after a route | only matters if `x` carries hooks; a routes-only module is fine there |
| `ELYSIA-LIFE-01` high | a hook in a plugin (an instance that is `.use()`d or exported) with no `as` and no `.as()` | the consumer's routes do not pass through it — prove with the test below |
| `ELYSIA-LIFE-03` high | a plugin `.use()`d by two or more instances, no `name` | its global hooks run once per use (twice for two siblings, verified) |
| `ELYSIA-LIFE-02` high | `derive` reading credentials | runs before validation; move the access decision to `resolve` |
| `ELYSIA-LIFE-04` high | `onRequest` destructuring `body`/`query`/`params`/`cookie`/`headers` | none of them exist there; read `request` or move to `onBeforeHandle` |
| `ELYSIA-LIFE-06` high | `store: { x }` destructured in a handler parameter | a snapshot; stale against writes later in the same call |
| `ELYSIA-LIFE-10` high | `throw` inside a macro | a 500 instead of 401/403, and the status leaves the type |
| `ELYSIA-LIFE-11` high | an anonymous hook in an app that imports the OpenTelemetry plugin | the span is named `anonymous` |
| `ELYSIA-LIFE-12` high | `cors()` without `origin` | it echoes any origin with `allow-credentials: true` (verified) |

What the scan cannot see: a hook that depends on runtime data, scope crossing more than one `.use()` level in different files, an async plugin's timing. Those need the test.

## The scope proof — the test `ELYSIA-LIFE-08` requires

`local` and `scoped` produce the same code inside the plugin. The only assertion that separates them hits a route of the **consuming** instance:

```ts
import { test, expect } from 'bun:test'
import { Elysia } from 'elysia'
import { auth } from '../src/auth'

test('auth protects a route of the CONSUMING instance', async () => {
  const app = new Elysia().use(auth).patch('/profile/rename', () => 'renamed')
  await app.modules                                                   // ELYSIA-CORE-10, if anything is lazy
  const res = await app.handle(new Request('http://localhost/profile/rename', { method: 'PATCH' }))
  expect(res.status).toBe(401)                                        // 200 means the hook is local
})
```

Verified on 1.4.30 with both versions of the plugin:

| Where the request goes | `local` hook that throws | `scoped` resolve that returns 401 |
| --- | --- | --- |
| a route inside the plugin | **500** — rejected, but as a server error | 401 |
| a route of the consumer | **200** — open | 401 |

The test most projects have is the top row. It passes with the defect.

Use `http://localhost`: with a one-label host such as `http://x/profile/rename`, Elysia answers **404** for every route (it slices the path from index 11), which reads like "the route does not exist".

## Symptoms that are not lifecycle

| Symptom | It is | Skill |
| --- | --- | --- |
| the client sees an error as `unknown` | no `response` map for that status (`ELYSIA-TYPE-06`) | `elysia-schema` |
| Eden's `data` is `null` | any status >= 300, redirects included (`ELYSIA-TYPE-08`) | `elysia-eden` |
| the client type lost a route | the chain was split into statements (`ELYSIA-APP-01`) | `elysia-build` |
| a required header "is never sent" | a capitalised name in the schema (`ELYSIA-TYPE-03`) | `elysia-schema` |
| a numeric body field fails validation | a JSON body does not coerce `t.Number` (`ELYSIA-TYPE-04`) | `elysia-schema` |
| a route missing from `/openapi/json` | `hide`, `exclude`, or a vendor without Standard JSON Schema (`ELYSIA-TYPE-07`) | `elysia-openapi` |
| SSE drops after ~10 s of silence | `Bun.serve`'s `idleTimeout` | `Bun - HTTP e Servidor` |
| the browser blocks the request | CORS / preflight | `http-diagnose` |
