# Sources of the Elysia family docs

Provenance for maintainers re-verifying a doc against upstream. No doc links here, so the build
and the `.skill` packages leave this file out and no run loads it.

## Elysia - Eden

Doc: [elysia-eden.md](elysia-eden.md)

Verified on **2026-08-15** (docs) and **2026-10-25** (executed):

- [Eden Overview](https://elysiajs.com/eden/overview.html) · [Installation](https://elysiajs.com/eden/installation.html) · [Treaty Overview](https://elysiajs.com/eden/treaty/overview.html) · [Parameters](https://elysiajs.com/eden/treaty/parameters.html) · [Response](https://elysiajs.com/eden/treaty/response.html) · [Config](https://elysiajs.com/eden/treaty/config.html) · [WebSocket](https://elysiajs.com/eden/treaty/websocket.html) · [Unit Test](https://elysiajs.com/eden/treaty/unit-test.html) · [Legacy](https://elysiajs.com/eden/treaty/legacy.html) · [Eden Fetch](https://elysiajs.com/eden/fetch.html) · [TanStack Start](https://elysiajs.com/integrations/tanstack-start.html)
- `@elysia/eden@1.4.10` — `treaty2/types.d.ts` and the published code; `@tanstack/query-core@5.104.5` — `replaceEqualDeep` and retry behaviour

**What execution contradicted or added (2026-10-25):**

- **`error` is an `Error` at runtime** (`EdenFetchError`), contrary to the earlier note that it was not; only its *type* is the plain `{ status, value }` union.
- **Every status >= 300 is an error**, redirects included.
- **A 422 is in the error union of almost every route** (any schema or path param), while the OpenAPI document adds no 422 unless declared.
- **A thrown `status()` is invisible to the client type unless the `response` map declares it**; a returned one is there with its literal value either way.
- **`throwHttpError` as a function receives the `EdenFetchError`**, not the `Response`, and can be set per call.
- **`parseDate` makes the runtime disagree with the type** — `string` in the type, `Date` at runtime — for every date-looking string, declared or not.
- **Thrown 4xx are retried by TanStack Query**; limit `retry` to 5xx.
- **An abort resolves** (503, `AbortError`) unless `throwHttpError` is set; `treaty(app)` ignores the signal.
- **`onResponse` returning a value replaces `data`**; a throw there sets `error` to a 422.
- **`edenFetch` has a different shape** from Treaty (`retry`, no `response`, URL only).
- **A query key with a `default` is required on the client**; `t.Optional` makes it optional and widens the server type.
- **`app.handle` needs an origin of at least 11 characters**; `http://x/...` is 404.

## Elysia - Lifecycle and Plugins

Doc: [elysia-lifecycle-and-plugins.md](elysia-lifecycle-and-plugins.md)

Verified on **2026-08-15**:

- [Plugin](https://elysiajs.com/essential/plugin.html) — scope, dependency, deduplication, `as`
- [Lifecycle](https://elysiajs.com/essential/life-cycle.html) — order, hooks, queues
- [Key Concept](https://elysiajs.com/key-concept.html) — encapsulation, code order
- [Extend Context](https://elysiajs.com/patterns/extends-context.html) — `state`, `decorate`, `derive`, `resolve`
- [Macro](https://elysiajs.com/patterns/macro.html) · [Best Practice](https://elysiajs.com/essential/best-practice.html)
- [OpenTelemetry](https://elysiajs.com/patterns/opentelemetry.html) · [CORS](https://elysiajs.com/plugins/cors.html) · [JWT](https://elysiajs.com/plugins/jwt.html) · [Static](https://elysiajs.com/plugins/static.html) · [Plugins Overview](https://elysiajs.com/plugins/overview.html)
- `elysia@1.4.29` — `types.d.ts` (`LifeCycleType`, `GuardSchemaType`) and `index.d.ts` (`as` overloads)

**What verification contradicted:**

- **`.as()` has only two overloads: `'scoped'` and `'global'`.** There is no `as('local')` — `local` is the default and there is no way to "go down" to it.
- **`scoped` goes up exactly one level.** The intuitive reading ("scoped = applies across the whole scope") is wrong; crossing two levels requires `as` on each one, or `global`.
- **`guard` with `as` does not cover `derive` or `resolve`** — the docs state the limitation explicitly. To raise a `resolve`, use `as` inline on it or `.as()` on the instance.
- **`onTransform` and `derive` share the same queue**, as do `onBeforeHandle` and `resolve` — the order is registration order, not by hook type.
- **Returning from `onAfterHandle` does not stop the following `afterHandle`**, unlike `beforeHandle`, `parse` and `mapResponse`, which do stop. The asymmetry is stated in the source.
- **`onRequest` is global by nature** and does not obey the "only applies to routes registered after it" rule — because it does not yet know which route will serve the request.
- **The Lifecycle page enumerates the `PreContext` incompletely.** It lists `request`, `set`, `store` and decorators; the `PreContext` type in `context.d.ts` of 1.4.29 also has `status`, `redirect` and `server`. This note's enumeration (§ 2) comes from the `.d.ts` and is the canonical one for the three Elysia notes. The costliest omission is `status`: it is what allows an `onRequest` to short-circuit with a typed status instead of building a `Response` by hand.
- **`env` from `elysia` is not a Cloudflare Worker solution.** The export is `Bun.env` on Bun, `process.env` outside it, and `{}` where neither exists (`universal/env.js` of 1.4.29). On a Worker the bindings come from `import { env } from 'cloudflare:workers'`, as the integration page itself shows. The value of `env` from `elysia` is not tying the code to `process`, not covering the Worker.
- **A macro deduplicates the lifecycle on its own**, using the property's value as the seed, and Elysia caps recursion at 16 levels to avoid circular dependencies.
- **Re-executed on 1.4.30 (2026-10-25):** an unnamed plugin used by two siblings runs its global hooks twice per request; the callback form of `guard` always enforces both schemas; `onRequest` has no `headers` but does have `path`; `guard({ as: 'scoped' })` lifts its own `beforeHandle` and schema but not a `derive`/`resolve` declared after it (`derive({ as: 'scoped' })` is lifted); a destructured `store` primitive is stale only against writes later in the same call; an app-level `onError` registered before `.use(module)` runs before the module's own; `cors()` reflects any `Origin` with credentials.
- **`@elysia/cors` has `credentials: true` and `origin: true` as defaults** — more permissive than you would expect from a security plugin.

## Elysia - OpenAPI

Doc: [elysia-openapi.md](elysia-openapi.md)

Verified on **2026-08-15** (docs) and **2026-10-25** (executed):

- [OpenAPI (patterns)](https://elysiajs.com/patterns/openapi.html) · [OpenAPI (plugin)](https://elysiajs.com/plugins/openapi.html) · [Swagger (deprecated)](https://elysiajs.com/plugins/swagger.html)
- `@elysia/openapi@1.4.16` — types and published code (`index`, `openapi`, `gen` for `fromTypes`)

**What execution contradicted or added (2026-10-25):**

- **Zod 4 needs no `mapJsonSchema`**, contrary to the earlier rule; passing `z.toJSONSchema` makes request bodies use the output view.
- **No 422 is documented** unless declared, although Elysia sends it and Eden types it.
- **A route with no schema has no `responses`.**
- **`operationId` is generated but not unique.**
- **A guard's `detail` overrides the route's; a constructor's is only a default.**
- **The helper is `withHeaders`** (plural), documentation only.
- **`fromTypes()` silently does nothing without `tsc` on `PATH`.**
- **`exclude.tags` crashes the spec route** when a route has no `detail` (1.4.16).
- **There is no auth option**; `enabled: false` registers nothing.
- **A prefixed `.post('/')` is documented with a trailing slash**; use `''`.

## Elysia - Routing and Handler

Doc: [elysia-routing-and-handler.md](elysia-routing-and-handler.md)

Verified on **2026-08-15**:

- [Route](https://elysiajs.com/essential/route.html) · [Handler](https://elysiajs.com/essential/handler.html)
- [Lifecycle — On Error](https://elysiajs.com/essential/life-cycle.html) · [Error Handling](https://elysiajs.com/patterns/error-handling.html)
- [Reactive Cookie](https://elysiajs.com/patterns/cookie.html) · [Config](https://elysiajs.com/patterns/configuration.html)
- [Unit Test](https://elysiajs.com/patterns/unit-test.html) · [Best Practice](https://elysiajs.com/essential/best-practice.html)
- `elysia@1.4.29` — `context.d.ts` (exact shape of `Context` and `PreContext`) and `error.d.ts` (classes and `status`)

**What the verification contradicted:**

- **The context's `error` no longer exists**; it was renamed to `status`. Remaining examples in the official docs (Lifecycle § Local Error) still use the old name.
- **`context.route` exists** and carries the **registered** path (`/orders/:id`), separate from `context.path` (the concrete URL). It is the right value for metric and log labels.
- **`set.redirect` is deprecated** in the types, with its own JSDoc pointing to the migration to the inline `redirect`.
- **`return status()` does not go through `onError`** — only `throw` does. It is the source of the most common confusion about error handling in Elysia.
- **Validation error details are omitted in production by default**, deliberately, so as not to leak the shape of the schema.
- **`strictPath` defaults to `false`**: `/name` and `/name/` resolve to the same route unless you ask otherwise.
- **The body is ignored on GET and HEAD by default**, following RFC 2616 — a GET with a body does not reach `body`.
- **An inline value on a route does not work on Cloudflare Worker**, because it requires building the `Response` before the server starts.
- **The default status of a validation error is 422, not 400.** `ValidationError.status = 422` in `error.js` of 1.4.29 — no docs page states the number, and it goes out even without `onError`. `InvalidFileType` is also 422; `ParseError` and `InvalidCookieSignature` are 400; `NotFoundError`, 404.
- **Re-executed on elysia 1.4.30 (2026-10-25):** with no `onError`, a thrown `Error`'s message is the 500 body even in production; a thrown `status(404)` reaches `onError` as `code === 404`; a `status = 409` class property works without `.error()`, and `toResponse()`'s status wins; `response: { 201 }` with a plain `return` sends **200** and is not validated, while a body that breaks the 200 schema answers **422** with `on: 'response'`; a required `body` schema on a GET is silently not enforced; routes are case-sensitive; a repeated query key keeps the last value and brackets are not parsed; any non-`undefined` return from `onBeforeHandle` — `0` and `false` included — becomes the response; a handler that returns nothing sends 200 with an empty body; `app.handle` needs an origin of at least 11 characters; an async plugin function pending at the first request leaves its route 404 for good.
- **The `PreContext` of `onRequest` includes `status`**, even though the Lifecycle page lists only `request`, `set`, `store` and decorators. Verified in `context.d.ts`; canonical enumeration in [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) § 2.

## Elysia - Schema and Validation

Doc: [elysia-schema-and-validation.md](elysia-schema-and-validation.md)

Verified on **2026-08-15**:

- [Validation](https://elysiajs.com/essential/validation.html) — per-route schema, guard, reference model, error
- [TypeBox (Elysia.t)](https://elysiajs.com/patterns/typebox.html) — types and coercion behavior
- [Standalone Schema](https://elysiajs.com/tutorial/patterns/standalone-schema.html) · [Validation Error](https://elysiajs.com/tutorial/patterns/validation-error.html)
- `elysia@1.4.29` — `type-system/index.d.ts` (the exact list of Elysia's types)

**What verification contradicted:**

- **Elysia does not require TypeBox.** Standard Schema accepts Zod, Valibot, ArkType, Effect Schema, Yup and Joi, and schemas from different libraries coexist in the same handler and in the same standalone `guard`.
- **`t.Uint8Array` is the real spelling** (`type-system/index.d.ts`), while the docs write `t.UInt8Array`. There are also `t.NumericEnum`, `t.ArrayString`, `t.ArrayQuery`, `t.NoValidate` and `t.String({ trusted })`, which are missing from the TypeBox page.
- **`t.ObjectString` requires the properties as an argument** (`t.ObjectString({ state: t.String() })`), although the docs show `t.ObjectString()` with no argument.
- **Re-executed on 1.4.30 (2026-10-25):** `t.Integer()` in a body coerces `"2"` while `t.Number()` rejects it; a `t.Number` nested in a query object is not coerced; `normalize: false` answers 422 "Unexpected property" on input and response; `response: { 201 }` with a plain `return` sends 200 unvalidated; a body breaking the 200 schema answers 422 with `on: 'response'`; the callback form of `guard` always enforces both schemas; a required `body` on a GET is silently skipped; `fileType()` resolves `true` or **rejects** on a mismatch (map it to `false` in a Zod refine); a declared-MIME mismatch is `VALIDATION` 422 while `INVALID_FILE_TYPE` comes from the content check; the production 422 still echoes the raw input in `found`; Zod 4 reaches OpenAPI without `mapJsonSchema`.
- **Coercion does not apply to `body`** — only to `params`, `query`, `headers` and `cookie`, and never inside a nested `t.Object`.
- **`t.Optional` at the route level differs from plain TypeBox**: it makes the whole key optional instead of marking an object field.
- **`normalize` defaults to `true`**: properties outside the schema silently disappear from the input **and from the output**.
- **The default validation-error status is 422**, and no page of the docs states it. It is in `ValidationError.status = 422` in the published package's `error.js`. It is sent even without `onError`, which goes against the reflex of expecting 400.
- **`allowUnsafeValidationDetails` defaults to `false`** (Config page) and is **global**: there is no per-route granularity. Turning it on in production to debug one endpoint exposes the schema shape of every endpoint.

## Elysia

Doc: [elysia.md](elysia.md)

Verified on **2026-08-15**:

- [At a glance](https://elysiajs.com/at-glance.html) · [Key Concept](https://elysiajs.com/key-concept.html) · [Quick Start](https://elysiajs.com/quick-start.html)
- [Route](https://elysiajs.com/essential/route.html) · [Handler](https://elysiajs.com/essential/handler.html) · [Lifecycle](https://elysiajs.com/essential/life-cycle.html) · [Plugin](https://elysiajs.com/essential/plugin.html) · [Validation](https://elysiajs.com/essential/validation.html) · [Best Practice](https://elysiajs.com/essential/best-practice.html)
- [Config](https://elysiajs.com/patterns/configuration.html) · [Error Handling](https://elysiajs.com/patterns/error-handling.html) · [Extend Context](https://elysiajs.com/patterns/extends-context.html) · [Macro](https://elysiajs.com/patterns/macro.html) · [TypeBox](https://elysiajs.com/patterns/typebox.html) · [OpenAPI](https://elysiajs.com/patterns/openapi.html) · [Cookie](https://elysiajs.com/patterns/cookie.html) · [WebSocket](https://elysiajs.com/patterns/websocket.html) · [Unit Test](https://elysiajs.com/patterns/unit-test.html)
- [Eden Overview](https://elysiajs.com/eden/overview.html) · [Eden Treaty](https://elysiajs.com/eden/treaty/overview.html) · [Response](https://elysiajs.com/eden/treaty/response.html) · [Config](https://elysiajs.com/eden/treaty/config.html) · [Eden Fetch](https://elysiajs.com/eden/fetch.html) · [Legacy](https://elysiajs.com/eden/treaty/legacy.html)
- [Plugins Overview](https://elysiajs.com/plugins/overview.html) · [OpenAPI](https://elysiajs.com/plugins/openapi.html) · [Swagger](https://elysiajs.com/plugins/swagger.html) · [CORS](https://elysiajs.com/plugins/cors.html) · [JWT](https://elysiajs.com/plugins/jwt.html) · [Static](https://elysiajs.com/plugins/static.html) · [OpenTelemetry](https://elysiajs.com/plugins/opentelemetry.html)
- [Node.js](https://elysiajs.com/integrations/node.html) · [Deno](https://elysiajs.com/integrations/deno.html) · [Cloudflare Worker](https://elysiajs.com/integrations/cloudflare-worker.html) · [TanStack Start](https://elysiajs.com/integrations/tanstack-start.html)
- `elysia@1.4.29` and `@elysia/eden@1.4.10` — `.d.ts` declarations of the published package (`index.d.ts`, `context.d.ts`, `error.d.ts`, `types.d.ts`, `type-system/index.d.ts`, `treaty2/types.d.ts`)
- `elysia@1.4.29` — **published code**, not just the types: `index.js` (effective constructor defaults), `error.js` (default status of each error class), `universal/env.js` (what the `env` export resolves to per runtime). Where the code and the docs diverge, the notes below record both.

**Verification notes** — points where the source contradicts what people assume by habit:

- **Re-executed on elysia 1.4.30, @elysia/eden 1.4.10 and @elysia/openapi 1.4.16 (2026-10-25).** Every behaviour the satellites mark *verified* has a passing test in the authoring playground. What changed: Zod 4 reaches OpenAPI without `mapJsonSchema` (`ELYSIA-TYPE-07` reworded); Eden's `error` is an `Error` instance at runtime; a destructured `store` primitive is stale only within the same call (`ELYSIA-LIFE-06` reworded); with no `onError`, a thrown error's message is the 500 body even in production; `app.handle` needs an origin of at least 11 characters; `ELYSIA_AOT=false` (the literal string) is the only way to turn AOT off.

- **`error` was renamed to `status` and no longer exists.** It is not among the exports of `elysia@1.4.29` nor in the `Context` type. Examples with `error` still appear on pages of the official docs (Lifecycle § Local Error, JWT) — they are residue, not live API.
- **The plugins exist under two npm scopes at once.** `@elysia/*` (used by the current docs, newer versions) and `@elysiajs/*` (legacy, still published). `@elysia/openapi` and `@elysiajs/openapi` are both at 1.4.15; `@elysia/eden` is at 1.4.10 against 1.4.9 for `@elysiajs/eden`.
- **`@elysiajs/swagger` is deprecated**, with an explicit notice on its own page: *"Swagger plugin is deprecated and is no longer maintained"*. It is stuck at 1.3.1 while the rest of the ecosystem is on 1.4.x.
- **`context.response` in hooks is deprecated in favour of `context.responseValue`.** The `.d.ts` files mark `response` with `@deprecated use context.responseValue instead` in `AfterHandler`, `MapResponse` and `AfterResponseHandler`. The official docs use both names on different pages.
- **Elysia supports Zod, Valibot, ArkType, Effect Schema, Yup and Joi** through Standard Schema, and schemas from different libraries can coexist in the same handler. This contradicts the common assumption that Elysia forces TypeBox.
- **Eden Treaty does not throw on HTTP errors by default** (`throwHttpError: false`), and **converts date strings into `Date` by default** (`parseDate: true`). Both defaults have a direct consequence for the TanStack Query integration — see [Elysia - Eden](elysia-eden.md).
- **`.as()` only accepts `'scoped'` and `'global'`.** There is no `as('local')` — the `.d.ts` files have exactly two overloads. `local` is the default and you do not "step down" to it.
- **The Config page says `aot` defaults to `false`, and the published package says `true`.** The constructor of `elysia@1.4.29` (`index.js`) builds the config with `aot: env.ELYSIA_AOT !== 'false'` — that is, on by default, and switchable off with the environment variable `ELYSIA_AOT=false`. The Cloudflare Worker page corroborates the package: if the default were `false`, there would be no reason for the docs to say that "you used to have to pass `aot: false`". **Treat the default as `true`.** The `@default false` annotation on the Config page is what falls, and it is the only known divergence between docs and package in this family.
- **`normalize` defaults to `true`**: properties outside the schema are silently removed on input and output. With `normalize: false` they become an error. Confirmed in both places — the Config page and `index.js`.
- **The default status of a validation error is 422**, and no page of the docs states it. `ValidationError.status = 422` in `error.js`. An app **with no `onError`** already responds 422 to an invalid payload; the reflex of expecting 400 comes from other frameworks. Table per error class in [Elysia - Routing and Handler](elysia-routing-and-handler.md) § 5.
- **The `PreContext` of `onRequest` has `status`, `redirect` and `server`**, besides `request`, `set`, `store` and decorators. The Lifecycle page lists only the first four. The absence of `status` from a second-hand enumeration is what leads someone to build a `Response` by hand to block a request. Canonical enumeration in [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) § 2.
- **The `env` of `elysia` does not cover Cloudflare Worker.** It is `Bun.env` on Bun, `process.env` outside it, and `{}` where neither exists. Worker bindings come from `cloudflare:workers` — two exports called `env`, different things.
- **In `NODE_ENV=production`, validation error details are omitted by default** — deliberate behaviour so as not to leak the schema's shape. `allowUnsafeValidationDetails: true` reverts it.
- **`edenTreaty` (Treaty 1) is legacy**; `treaty` (Treaty 2) is the current API. Both live in the same package, which makes an old example compile without warning.
