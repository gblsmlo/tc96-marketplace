# Worked example — an auth plugin that does not protect the app

Task: *"Our auth plugin passes its own tests, but `PATCH /profile/rename` on the server answers without a token."*

## The probe

```
$ bash scripts/probes.sh .
== lifecycle: 1 finding(s)
   [high] ELYSIA-LIFE-01 — packages/auth/src/plugin.ts:4
      plugin `auth`: .onBeforeHandle() has no scope — local by default, it does not reach the routes
      of the instance that .use()s it (this looks like auth: the consumer's routes are open)
```

No `ELYSIA-CORE-01` finding: the `.use(auth)` comes before the routes, so order is eliminated first. The hypothesis is scope. The probe does not prove it.

## The proof

The plugin's own test hits `/auth/me` and expects a rejection — it gets **500**, and passes, because it only asserted "not 200". A test on the consuming app:

```ts
const res = await app.handle(new Request('http://localhost/profile/rename', { method: 'PATCH' }))
expect(res.status).toBe(401)   // received 200
```

## The finding

```
`ELYSIA-LIFE-01` — packages/auth/src/plugin.ts:4
Symptom: the app's routes answer without a token; the plugin's own routes reject, as 500.
Evidence: the consumer test above returned 200, not 401.
Cause: the hook has the default `local` scope, so it stops at the plugin.
Fix: `.resolve({ as: 'scoped' }, function resolveUser({ headers, status }) { … return status(401, …) })`,
     and move the test to the consuming instance (ELYSIA-LIFE-08).
Also: the hook threw `new Error`, which Elysia answers as 500 — return status(401) instead (ELYSIA-LIFE-10).
If a second plugin sits between auth and the app, it needs `.as('scoped')` too: scoped climbs one level.
```

## What this example demonstrates

| Decision | Where the rule is |
| --- | --- |
| order was eliminated before scope | SKILL step 2 |
| the evidence is a test on the consumer, not a reading of the plugin | `probes-and-proof.md` |
| the existing test passed because it asserted "rejected", and a 500 is a rejection | `probes-and-proof.md`, table |
| the fix names `scoped` and says when it is not enough | `ELYSIA-LIFE-01`, `ELYSIA-LIFE-09` |
