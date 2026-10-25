---
titulo: Elysia
Link: https://elysiajs.com/
tags:
  - elysia
  - backend
  - agent-context
source: "Official documentation — https://elysiajs.com/"
verificado-em: 2026-10-25
---
# Elysia — guided reference

> **What this note is.** The single entry point for Elysia in this family: for a person looking something up, and for coding agents that generate or review Elysia servers. It is not a linear summary of the docs — it is a **router**. It decides what to load, offers the mental model that makes the rest make sense, and exposes citable rules that a skill or a code review can reference by ID.
>
> **What it is not.** It does not replace the source. When they diverge, [elysiajs.com](https://elysiajs.com/) wins, and this note must be corrected.

Inventory verified on elysiajs.com and in the published package on **2026-08-15**.
Verified version: **elysia 1.4.29** (`registry.npmjs.org/elysia/latest`), `@elysia/eden` 1.4.10, `@elysia/openapi` 1.4.15.
See [Sources consulted](#sources-consulted).

---

## 1. How to use these docs

### For a person

Read § 2 once — plugin scope (§ 2, statement 3) is the concept that costs the most when you do not know it. Then use § 4 as the index and § 5 to find the decision tree when you are torn between two neighbouring APIs. The satellites are on-demand reading.

### For a coding agent

Load in this order, stopping as soon as you have enough:

| Step | Load | When |
| ----- | -------- | ------ |
| 1 | This note (§ 2, § 6; § 5 to locate a decision tree) | Whenever the task involves Elysia |
| 2 | [Elysia - Routing and Handler](elysia-routing-and-handler.md) | Writing or changing routes, responses, errors, cookies, tests |
| 3 | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) | Writing a plugin, hook or auth, or when "the plugin does not work" |
| 4 | [Elysia - Schema and Validation](elysia-schema-and-validation.md) | Declaring a schema, coercion, guard, models, a `response` map, or customizing a validation error |
| 5 | [Elysia - OpenAPI](elysia-openapi.md) | Documenting the API with `@elysia/openapi` |
| 6 | [Elysia - Eden](elysia-eden.md) | Consuming the API from the frontend — Eden Treaty/Fetch, TanStack Query, pagination envelope |
| 7 | `Bun - HTTP e Servidor` | Detail of the server underneath — TLS, sockets, `Bun.serve` |

**Context economy rule:** never load every satellite.

### Conventions and vocabulary

**All examples are TypeScript.** Elysia without TypeScript loses most of its value: inference is the product.

Terms used without redefinition in the satellites:

| Term | Meaning in these docs |
| --- | --- |
| **instance** | a `new Elysia()` object. It is at once app, plugin, controller and scope unit |
| **accumulated type** | the type each chaining method returns, carrying everything registered up to that point |
| **scope** (`local`/`scoped`/`global`) | how far a hook registered on an instance reaches — see § 2, statement 3, and [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) § 5 |
| **context** | the single per-request object passed to the handler and to every hook |
| **local hook** | a hook passed in a route's 3rd argument; applies only to that route |
| **interceptor** | a hook registered with `.onX()`; applies to the routes registered **after** it |
| **guard** | a block that applies schema and hooks to several routes at once |
| **macro** | a reusable hook activated by a boolean or parameterized property in the local hook |
| **schema** | a `t.*` declaration (or Standard Schema) that produces validation, type, OpenAPI and the Eden contract |
| **Eden** | the typed client that consumes `typeof app` with no code generation |
| **Standard Schema** | the common interface that lets Zod/Valibot/ArkType/Effect be used in place of `t` |

---

## 2. Mental model

Five statements. Almost every mistake an agent makes in Elysia violates one of them.

**1. A schema is not validation — it is four things from a single declaration.** The docs are literal: *"A single Elysia/TypeBox schema can be used for: Runtime validation · Data coercion · TypeScript type · OpenAPI schema"*. And there is a fifth, which the docs cover on another page: it is the contract Eden consumes on the frontend. Practical consequence: any hand-written TypeScript `interface` describing an already-validated body is duplication, and it will drift. The type is extracted with `typeof MySchema.static`. One declaration as the single source of truth is a familiar principle; the difference here is that the tool enforces it.

**2. Method chaining is what holds the type. Breaking it loses inference silently.** Each method returns a **new** instance type. `const app = new Elysia(); app.state('build', 1); app.get(...)` compiles and runs — but `store.build` does not exist in the type, and the frontend's Eden does not see the route. The docs are emphatic: *"Elysia code should **ALWAYS** use method chaining"*. It is not style, it is the mechanism.

**3. Plugin scope is `local` by default, and it is the most common bug class.** An instance's hooks **do not leak** to whoever calls `.use()` on it. The docs compare it to `export` in JavaScript: you have to export. An authentication `onBeforeHandle` inside a plugin protects the routes *of that plugin* and nothing else — the `app` that consumes it stays open, with no error and no warning. The three levels (`local` / `scoped` / `global`) and `as()` are in [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) § 5.

**4. Code order is application order.** An event only applies to routes registered **after** it. An `onError` declared at the end of the file catches nothing that came before; a plugin registered before an `onBeforeHandle` does not inherit it. The only verified exception is `onRequest`, which is global because it does not yet know which route will serve the request.

**5. Elysia is Bun-first, not Bun-only — and the difference is feature by feature.** The default target runtime is Bun, and things like `context.server` are explicitly marked *"Bun only"* in the docs. Outside Bun there are real adapters (Node, Cloudflare Worker, Deno via `Deno.serve(app.fetch)`), with declared limitations — see § 3. Choosing Elysia without Bun is possible and documented; choosing it without knowing what you lose is not.

> **On the relationship with Zod.** The native schema is TypeBox (`t`), but Elysia 1.4 supports **Standard Schema**: Zod, Valibot, ArkType, Effect Schema, Yup and Joi work directly in place of `t`, and *"You can use any validator together in the same handler without any issue"* — verified. The choice is real and has concrete trade-offs (coercion, OpenAPI, file validation). Detail in [Elysia - Schema and Validation](elysia-schema-and-validation.md) § 2 and § 8 of this note.

---

## 3. Import boundaries and runtime

Knowing where something comes from avoids half of the import mistakes. List extracted from the `export`s of `elysia@1.4.29`.

### The `elysia` package

| Export | What it is for |
| --- | --- |
| `Elysia` | the class. Default export **and** named export |
| `t` | the schema builder (TypeBox + server types) |
| `status` | returns a response with a typed status — **it is the current name**, see the note below |
| `redirect` | redirects (also available on the context) |
| `file`, `ElysiaFile` | responds with a file |
| `form` | responds with `FormData` |
| `sse` | formats a chunk as a Server-Sent Event |
| `env` | runtime-independent access to environment variables |
| `validationDetail`, `fileType` | validation error detail; file type check by magic number |
| `NotFoundError`, `ParseError`, `ValidationError`, `InvalidCookieSignature`, `InvalidFileType`, `InternalServerError` | built-in error classes |
| `StatusMap`, `InvertedStatusMap`, `ERROR_CODE` | status maps and the error-code symbol |
| `Cookie`, `serializeCookie` | cookie utilities |
| types: `Context`, `PreContext`, `ErrorContext`, `Static`, `TSchema`, … | typing |

> **Confirmed rename:** `error` is **no longer exported** by `elysia`, and **no longer exists on the context**. The current name is `status`, both as an export (`import { status } from 'elysia'`) and as a context property (`({ status }) => status(418)`). Verified in the `.d.ts` files of 1.4.29 — `Context` lists `status`, not `error`. Some leftover examples in the official docs still use `error`; they are residue. `.error()` still exists, but it is an **instance method** for registering custom error classes, which is something else.

### npm scopes: `@elysia/*` and `@elysiajs/*` coexist

The official plugins are published **under both scopes**. The current documentation uses `@elysia/*`, and that is the scope ahead in version (e.g. `@elysia/eden` 1.4.10 × `@elysiajs/eden` 1.4.9; `@elysia/static` 1.4.11 × `@elysiajs/static` 1.4.10). Prefer `@elysia/*` in new code; `@elysiajs/*` is what you will find in tutorials and older projects.

| Package | Contains | Status |
| --- | --- | --- |
| `@elysia/openapi` | `openapi()`, `fromTypes()`, `withHeader` — documentation at `/openapi` (Scalar by default) | current |
| `@elysia/eden` | `treaty`, `edenFetch`, `edenTreaty` (legacy), `Treaty` (types) | current |
| `@elysia/cors` | CORS | current |
| `@elysia/jwt` | sign/verify JWT (on top of `jose`) | current |
| `@elysia/static` | serve a static folder | current |
| `@elysia/bearer` | extract a Bearer token | current |
| `@elysia/html` | HTML/JSX response, `isHtml` | current |
| `@elysia/cron` | cron jobs | current |
| `@elysia/opentelemetry` | tracing, `record`, `getCurrentSpan`, `setAttributes` | current |
| `@elysia/server-timing` | `Server-Timing` header | current |
| `@elysia/node` | Node.js adapter (`node()`) | current |
| `@elysiajs/swagger` | Swagger UI | **deprecated** — the docs say *"deprecated and is no longer maintained"* |

### Runtimes

| Runtime | How | Verified status |
| --- | --- | --- |
| **Bun** | default, `.listen(3000)` | primary target; `context.server`, `Bun.serve.static`, `Bun.serve.routes` only here |
| **Node.js** | `@elysia/node` + `new Elysia({ adapter: node() })` | supported and documented |
| **Deno** | `Deno.serve(app.fetch)` — no `.listen()` | supported, no dedicated adapter |
| **Cloudflare Worker** | `new Elysia({ adapter: CloudflareAdapter })` from `elysia/adapter/cloudflare-worker`, with `.compile()` before the export | **experimental**, marked as such in the docs |
| **Vercel / Netlify / Next.js / Astro / Expo / TanStack Start** | through an API route, calling `app.fetch(request)` | documented |

Declared limitations on Cloudflare Worker: `file()` and the static plugin do not work (no `fs`), OpenAPI Type Gen does not work, and **an inline value in a route (`.get('/', 'Hello')`) throws** because a `Response` cannot be created before start. Bindings come from `import { env } from 'cloudflare:workers'`, **not** from the `env` export of `elysia` — see § 6, `ELYSIA-APP-09`.

On `aot` in the Worker: up to 1.4.6 you had to pass `aot: false`, because the Worker did not allow function compilation at start. From **1.4.7** on that is no longer necessary, and the docs recommend leaving AoT on, *"for better performance and accurate plugin encapsulation"*. The default of `aot` is `true` in the published package, even though the Config page says otherwise — see [Sources consulted](#sources-consulted).

---

## 4. API map

Surface verified in the `.d.ts` files of 1.4.29 and on the corresponding pages. The **Satellite** column says what to load.

**Deliberately outside this map:** `mount` (interop with Hono/H3 and other Web Standard frameworks), `trace`, `wrap`, `Ref`, `affix`/`suffix`, `mapDerive`/`mapResolve`, `options`, `connect`, `headers`, the GraphQL plugins (Apollo and Yoga), the internal JIT compiler and the community plugin ecosystem. Absence here means **"not verified in these docs"**, not "does not exist" — check elysiajs.com.

`compile` and `prefix` **are** in the map: the first in the constructor and lifecycle table below (it is mandatory on Cloudflare Worker, § 3), the second among the verified constructor options.

### Constructor and server lifecycle

| API | What it is for | Satellite |
| --- | --- | --- |
| `new Elysia(config)` | creates an instance. Verified options: `name`, `seed`, `prefix`, `adapter`, `aot`, `precompile`, `normalize`, `strictPath`, `serve`, `websocket`, `cookie`, `detail`, `tags`, `sanitize`, `encodeSchema`, `nativeStaticResponse`, `systemRouter`, `allowUnsafeValidationDetails` | [Elysia - Routing and Handler](elysia-routing-and-handler.md) |
| `.listen(port)` | starts the server (Bun/Node) | [Elysia - Routing and Handler](elysia-routing-and-handler.md) |
| `.fetch(request)` / `.handle(request)` | processes a `Request` without a server — the basis of tests and of API-route integration | [Elysia - Routing and Handler](elysia-routing-and-handler.md) |
| `.compile()` | forces compilation of the chain without `listen` — **mandatory before exporting on Cloudflare Worker** (§ 3) | [Elysia - Routing and Handler](elysia-routing-and-handler.md) |
| `.onStart()`, `.onStop()` | lifecycle of the **server**, not of the request | — |
| `.modules` | promise of the loaded lazy/async modules | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) |

### Routes

| API | What it is for | Satellite |
| --- | --- | --- |
| `.get/.post/.put/.patch/.delete/.head` | route per verb | [Elysia - Routing and Handler](elysia-routing-and-handler.md) |
| `.all(path, handler)` | any method | [Elysia - Routing and Handler](elysia-routing-and-handler.md) |
| `.route(method, path, handler)` | custom verb (case-sensitive, use UPPERCASE) | [Elysia - Routing and Handler](elysia-routing-and-handler.md) |
| `.group(prefix, [guard], cb)` | common prefix, with an optional guard in the 2nd argument | [Elysia - Routing and Handler](elysia-routing-and-handler.md) |
| `.ws(path, handler)` | WebSocket with schema (`body`, `query`, `params`, `header`, `cookie`, `response`) | [Elysia - Eden](elysia-eden.md) |
| `.mount()` | mount another Web Standard app | — |

### The context object

What the handler receives. List from `context.d.ts`; the Satellite column points to where the behaviour is covered.

| Property | What it is for | Satellite |
| --- | --- | --- |
| `body`, `query`, `params`, `headers` | request input; exact type only with a schema | [Elysia - Schema and Validation](elysia-schema-and-validation.md) § 3 |
| `cookie` | reactive jar (Proxy): reads and writes `.value`, syncs the header | [Elysia - Routing and Handler](elysia-routing-and-handler.md) § 4 |
| `set` | the response's `{ headers, status }`. `set.status` is **not** checked against the `response` schema | [Elysia - Routing and Handler](elysia-routing-and-handler.md) § 4 |
| `set.headers` | outgoing headers, always lowercase — immutable after the first `yield` | [Elysia - Routing and Handler](elysia-routing-and-handler.md) § 4 |
| `status` | `status(code, value)` — response with a typed status; replaces the old `error` | [Elysia - Routing and Handler](elysia-routing-and-handler.md) § 4 and § 5 |
| `store` | the instance's global state, created by `.state()`; a primitive does not survive destructuring | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) § 3 |
| `redirect` | redirect function; `set.redirect` is deprecated | [Elysia - Routing and Handler](elysia-routing-and-handler.md) § 4 |
| `request` | the Web Standard `Request` — escape hatch | [Elysia - Routing and Handler](elysia-routing-and-handler.md) § 3 |
| `server` | the server instance — **Bun only**, `null` outside it | `Bun - HTTP e Servidor` |
| `path` × `route` | concrete URL (`/orders/9`) × registered path (`/orders/:id`) — use `route` as a metric label | [Elysia - Routing and Handler](elysia-routing-and-handler.md) § 3 |
| `responseValue` | the return value, visible in `onAfterHandle`/`mapResponse` (replaces `response`, deprecated) | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) § 2 |
| `PreContext` (only in `onRequest`) | subset: `request`, `set`, `store`, `status`, `redirect`, `server` and decorators | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) § 2 |

### Context and extension

| API | Phase | Satellite |
| --- | --- | --- |
| `.state(k, v)` | once, at boot → `store` (mutable, global) | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) |
| `.decorate(k, v)` | once, at boot → context property (do not mutate) | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) |
| `.derive(fn)` | per request, in `transform` — **before** validation | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) |
| `.resolve(fn)` | per request, in `beforeHandle` — **after** validation | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) |
| `.macro({...})` | reusable hook activated by a property | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) |
| `.model({...})` | registers named schemas, referenceable by string | [Elysia - Schema and Validation](elysia-schema-and-validation.md) |
| `.error({...})` | registers error classes with a code for narrowing | [Elysia - Routing and Handler](elysia-routing-and-handler.md) |
| `.parser(name, fn)` | custom body parser | [Elysia - Routing and Handler](elysia-routing-and-handler.md) |

### Lifecycle (execution order)

`onRequest` → `onParse` → `onTransform` (+`derive`) → **validation** → `onBeforeHandle` (+`resolve`) → **handler** → `onAfterHandle` → `mapResponse` → *response sent* → `onAfterResponse`. `onError` intercepts errors from any phase.

| API | What it can do | Satellite |
| --- | --- | --- |
| `.onRequest(fn)` | minimal context (`PreContext`), global; a return short-circuits | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) |
| `.onParse(fn)` | fill `body` for content types not covered | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) |
| `.onTransform(fn)` | mutate the context so it passes validation | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) |
| `.onBeforeHandle(fn)` | authorization; a return skips the handler | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) |
| `.onAfterHandle(fn)` | transform the return value; reads `responseValue` | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) |
| `.mapResponse(fn)` | map to a `Response` (compression etc.) | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) |
| `.onError(fn)` | handle errors; `code` narrows the type of `error` | [Elysia - Routing and Handler](elysia-routing-and-handler.md) |
| `.onAfterResponse(fn)` | logging/analytics after sending | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) |
| `.guard(obj, [cb])` | schema + hooks for several routes; accepts `as` and `schema: 'standalone'` | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) |
| `.as('scoped' \| 'global')` | raises the scope of everything the instance registered | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) |
| `.use(plugin)` | applies another instance, function, promise or `import()` | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) |

### `t` — types Elysia adds to TypeBox

On top of the whole TypeBox surface (`t.Object`, `t.String`, `t.Number`, `t.Array`, `t.Union`, `t.Optional`, `t.Partial`, `t.Literal`, `t.Intersect`, `t.Tuple`, `t.Record`, `t.KeyOf`, …), these belong to Elysia — list extracted from `type-system/index.d.ts`:

| Type | What it does differently |
| --- | --- |
| `t.Numeric()` | accepts a numeric string and **transforms it into `number`** |
| `t.Integer()`, `t.Date()` | integer; date with coercion |
| `t.BooleanString()` | accepts `"true"`/`"false"` as a boolean |
| `t.ObjectString(props)` | a JSON string that becomes an object — for query, header, FormData |
| `t.ArrayString()`, `t.ArrayQuery()` | array from a string / from a repeated query |
| `t.File(opts)`, `t.Files(opts)` | upload, with `type`, `minSize`, `maxSize` (suffixes `k`/`m`) |
| `t.Form(props)` | validates the return of `form()` (FormData) |
| `t.Cookie(props, opts)` | object + cookie options: `secrets`, `sign`, `httpOnly`, `secure`, … |
| `t.Nullable(s)` | allows `null` (not `undefined`) |
| `t.MaybeEmpty(s)` | allows `null` **and** `undefined` |
| `t.UnionEnum([...])` | union of literals in a single schema |
| `t.NumericEnum(enum)` | numeric enum |
| `t.NoValidate(s)` | turns validation off while keeping the type |
| `t.Uint8Array()`, `t.ArrayBuffer()` | binary body |
| `t.String({ trusted: true })` | skips JSON escape validation in the accelerator |
| `t.Transform(s)` | custom encode/decode (see `encodeSchema` in the constructor) |

Full surface and coercion behaviour in [Elysia - Schema and Validation](elysia-schema-and-validation.md) § 3.

### Official plugins

Inventory and status of each package in the table in § 3. Where to load: `@elysia/openapi` → [Elysia - OpenAPI](elysia-openapi.md); `@elysia/eden` → [Elysia - Eden](elysia-eden.md); `@elysia/cors`, `@elysia/jwt`, `@elysia/bearer`, `@elysia/static` and `@elysia/opentelemetry` → [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) § 8.

---

## 5. Decision trees

These trees map **symptom → correct API**, which is where generated Elysia code most often goes wrong. Each one lives at the top of the satellite that owns the answer:

| Tree | Where it lives |
| --- | --- |
| I need a value available in the handler — which API? | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) § 0.1 |
| Where in the lifecycle does this logic go? | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) § 0.2 |
| Why does my plugin not affect this route? | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) § 0.3 |
| How do I return an error? | [Elysia - Routing and Handler](elysia-routing-and-handler.md) § 0 |

---

## 6. Normative rules

Rules citable by ID. The full body of each family lives in the corresponding satellite; the ones that apply to any Elysia code stay here.

**Convention:** `MUST` / `NEVER` are normative. A violation is a bug, not a matter of style.

### `ELYSIA-APP-*` — instance and project

| ID | Rule |
| --- | --- |
| `ELYSIA-APP-01` | Every instance construction **MUST** use continuous method chaining — assigning the instance and calling methods in separate statements loses type inference. |
| `ELYSIA-APP-02` | New code **NEVER** uses `error` from the context or from `elysia` — the current name is `status`, and `error` no longer exists in 1.4. |
| `ELYSIA-APP-03` | A handler that needs the context **MUST** be an inline function destructuring what it uses, and **NEVER** an external function annotated with `Context` — a literal value (`.get('/status', 'ok')`) and `file()` in place of the handler remain valid and are not handlers. |
| `ELYSIA-APP-04` | The server's `tsconfig.json` **and** that of every Eden client **MUST** have `strict: true` and TypeScript >= 5.0. |
| `ELYSIA-APP-05` | The instance exported to Eden **MUST** be exported as a type (`export type App = typeof app`) from the module where the chain ends. |
| `ELYSIA-APP-06` | Code that uses `context.server`, `Bun.*` or an inline value in a route **MUST** declare Bun as the target runtime — none of the three behaves the same outside it. |
| `ELYSIA-APP-07` | `@elysiajs/swagger` **NEVER** enters new code — it is deprecated at the source; use `@elysia/openapi`. |
| `ELYSIA-APP-08` | A secret (`jwt.secret`, `cookie.secrets`) is **NEVER** a literal in the code — load it at startup. |
| `ELYSIA-APP-09` | Application code **NEVER** reads `process.env` directly — it **MUST** use the `env` export of `elysia`, which resolves to `Bun.env` on Bun and `process.env` outside it. |

> **The reach of `ELYSIA-APP-09`, verified.** The `env` of `elysia` is `Bun.env` when the runtime is Bun, `process.env` when `process` exists, and `{}` when neither exists (`universal/env.js` of 1.4.29; on 1.4.30 under Bun, `env === process.env === Bun.env`, verified). The gain is not tying the code to `process`, which is what breaks when you switch runtimes. **It is not a Cloudflare Worker solution:** there the `env` of `elysia` returns `{}`, and the bindings come from `import { env } from 'cloudflare:workers'` — both names are `env` and they are not the same thing. In a Worker, import the one from `cloudflare:workers`; on any other target, the one from `elysia`.

### 6.1 Critical satellite rules

The full families live in the satellites, but **these need to travel with the minimum path** — they are the ones that show up most in generated code.

> **The satellite is canonical.** The rows below reproduce the satellite's text, not a paraphrase. In any divergence between this table and the satellite, the satellite wins and this table is the bug — § 7 says to cite by ID without paraphrasing, and two divergent copies of a normative rule make that impossible.

| ID | Rule | Satellite |
| --- | --- | --- |
| `ELYSIA-CORE-01` | Hooks, plugins and `onError` **MUST** be registered before the routes they should affect — an event only applies to routes registered after it. | [Elysia - Routing and Handler](elysia-routing-and-handler.md) |
| `ELYSIA-CORE-03` | An expected error **MUST** be `return status(...)`, not `throw`, when its type needs to reach Eden typed. | [Elysia - Routing and Handler](elysia-routing-and-handler.md) |
| `ELYSIA-CORE-06` | `set.headers` is **NEVER** changed after the first `yield` of a generator handler — the change is silently ignored. | [Elysia - Routing and Handler](elysia-routing-and-handler.md) |
| `ELYSIA-LIFE-01` | A plugin hook that must apply to whoever consumes the plugin **MUST** declare a scope (`{ as: 'scoped' }`, `guard({ as })` or `.as()`) — the default `local` does not propagate up, and the failure is silent. | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) |
| `ELYSIA-LIFE-02` | An authentication or authorization decision **NEVER** uses `derive` — it **MUST** use `resolve` or `macro.resolve`, which run after validation. | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) |
| `ELYSIA-LIFE-03` | A plugin applied by more than one instance **MUST** declare `name` — without it the lifecycle runs once per application. | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) |
| `ELYSIA-TYPE-01` | The TypeScript type of a validated payload **MUST** derive from the schema (`typeof S.static`) — and **NEVER** be rewritten by hand. | [Elysia - Schema and Validation](elysia-schema-and-validation.md) |
| `ELYSIA-TYPE-06` | A route that returns more than one status **MUST** declare `response` as a map by status — without it the error reaches Eden as `unknown`. | [Elysia - Schema and Validation](elysia-schema-and-validation.md) |
| `ELYSIA-TYPE-08` | An Eden result **MUST** have `error` checked before `data` is used — `data` is `null` on any status >= 300. | [Elysia - Eden](elysia-eden.md) |
| `ELYSIA-TYPE-09` | A `queryFn`/`mutationFn` that calls Eden **MUST** throw on error (or the client **MUST** use `throwHttpError: true`) — without that the query stays `success` with null data. | [Elysia - Eden](elysia-eden.md) |
| `ELYSIA-TYPE-11` | Client and server **MUST** resolve the same version of `elysia`, with `strict: true` and TypeScript >= 5.0 on both. | [Elysia - Eden](elysia-eden.md) |

### 6.2 Canonical IDs

Three principles appear in more than one family, because each satellite has to stand on its own. **To cite, always use the canonical ID** — the other one is an alias and should not appear in a review.

| Principle | Canonical | Alias |
| --- | --- | --- |
| `strict: true` and TypeScript >= 5.0 on both sides of the Eden boundary | `ELYSIA-APP-04` | `ELYSIA-TYPE-11`, **for this clause only** |
| An expected failure is signalled with `return status(...)`, not with `throw` | `ELYSIA-CORE-03` | `ELYSIA-LIFE-10` (the same principle applied inside a `macro`) |
| The handler destructures the context; an external function annotated with `Context` is not accepted | `ELYSIA-CORE-02` | `ELYSIA-APP-03`, **for this clause only** |

The two "for this clause only" are deliberate, because the two rules are not entirely redundant:

- **`ELYSIA-TYPE-11` remains citable on its own** for what belongs only to it: **`elysia` version parity between client and server**, which `ELYSIA-APP-04` does not cover and which is the most common reason Eden degrades to `any`. That is why it is in § 6.1 — version parity needs to travel with the minimum path. When citing the `strict: true` requirement alone, use `ELYSIA-APP-04`.
- **`ELYSIA-APP-09` is not an alias of anything.** It mirrors `HONO-APP-03` in the neighbouring family, but the motivation there is different; here there is an `env` export in the package itself.
- **`ELYSIA-APP-03` remains citable on its own** for what belongs only to it: the legitimacy of a literal value and `file()` in place of the handler. When citing context destructuring, use `ELYSIA-CORE-02`.

### Full families in the satellites

| Family | Where it lives |
| --- | --- |
| `ELYSIA-APP-*` | this note (§ 6) |
| `ELYSIA-CORE-*` | [Elysia - Routing and Handler](elysia-routing-and-handler.md) |
| `ELYSIA-LIFE-*` | [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) |
| `ELYSIA-TYPE-01`–`06`, `ELYSIA-TYPE-12` | [Elysia - Schema and Validation](elysia-schema-and-validation.md) |
| `ELYSIA-TYPE-07`, `ELYSIA-TYPE-18`–`20` | [Elysia - OpenAPI](elysia-openapi.md) |
| `ELYSIA-TYPE-08`–`11`, `ELYSIA-TYPE-13`–`17` | [Elysia - Eden](elysia-eden.md) |

There are 51 rules in total (`ELYSIA-APP-*` 9 · `ELYSIA-CORE-*` 10 · `ELYSIA-LIFE-*` 12 · `ELYSIA-TYPE-*` 20); § 6.1 above selects 11. `ELYSIA-TYPE-14` to `-20` were added on 2026-10-25, when the Eden and OpenAPI patterns were executed against the published packages; `ELYSIA-TYPE-07` and `ELYSIA-LIFE-06` were reworded the same day after execution contradicted them. No existing ID changed number.

---

## 7. Skill contract

How an Elysia skill should consume these docs.

### What an Elysia skill should load

```
ALWAYS:   the skill's own satellite — one doc
          elysia.md § 3 and § 6 only when the task needs the import map,
          the runtime limits or an ELYSIA-APP-* rule's text

elysia-build — routes, handlers, errors, cookies, tests:
          elysia-routing-and-handler.md
          + elysia-lifecycle-and-plugins.md ONLY when the task
            writes a plugin, hook or auth

elysia-schema — schema, coercion, guard, models, response map,
validation error:
          elysia-schema-and-validation.md

elysia-openapi — documenting the API:
          elysia-openapi.md

elysia-eden — consuming the API from the frontend (Eden,
queryFn/mutationFn, pagination envelope):
          elysia-eden.md

elysia-diagnose — "the plugin is not being applied",
"the hook does not run":
          elysia-lifecycle-and-plugins.md

NEVER:    every satellite at once
```

### How to cite

Review findings cite the rule ID and the satellite; they do not paraphrase:

> `ELYSIA-LIFE-02` — `derive` used to resolve the user session. It runs before validation; use `resolve`.
> See [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md).

### Invariants the skill must enforce

1. **Verify before asserting.** If an API is not in § 4, it has not been verified in these docs. Check elysiajs.com and update the note — do not invent a signature.
2. **The source wins.** A divergence between this note and elysiajs.com is a bug in this note.
3. **Chaining before style.** No formatting preference justifies breaking the chain (`ELYSIA-APP-01`).
4. **Scope is the first hypothesis.** Faced with "the hook does not run", check scope and order before anything else ([Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) § 0.3).
5. **One schema declaration.** Any hand-written type for an already-validated payload is a regression (`ELYSIA-TYPE-01`).
6. **Prefer the bridge.** When § 8 indicates that the stack solves the problem, use the stack.

### When creating a new Elysia skill

Derive it from a satellite, not from this whole note: an authentication-focused skill loads [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) + § 2 + § 6; an API-contract skill loads [Elysia - Schema and Validation](elysia-schema-and-validation.md) or [Elysia - Eden](elysia-eden.md) + § 8. Record at the top of the skill which satellite is its source, so that doc updates propagate.

---

## 8. Bridges with the stack

The stack is `React.js` + `TanStack Router` + `TanStack Query` + TypeScript + Zod. Elysia comes in as the server, and the bridge has a name: **Eden**.

| Problem | Raw primitive | What to use in the stack |
| --- | --- | --- |
| Type the API response on the frontend | hand-written `interface` | `export type App = typeof app` + Eden Treaty — [Elysia - Eden](elysia-eden.md) |
| Validate the payload at the boundary | manual checks | `t` schema (or Zod via Standard Schema) — [Elysia - Schema and Validation](elysia-schema-and-validation.md) |
| Document the API | maintain a separate YAML | `@elysia/openapi` generates it from `t` — [Elysia - OpenAPI](elysia-openapi.md) |
| Fetch data in a component | `fetch` + `useEffect` | a `queryFn` calling Eden — [Elysia - Eden](elysia-eden.md) |
| Propagate a typed error by status | `any` in the `catch` | Eden's `{ error }` with `error.status` narrowing — [Elysia - Eden](elysia-eden.md) |
| Cancel an in-flight request | manual | Eden's `fetch: { signal }` — [Elysia - Eden](elysia-eden.md) |
| Paginate a listing | return the raw array | an `{ items, total, hasMore }` envelope in the `response` (`ELYSIA-TYPE-13`) — [Elysia - Eden](elysia-eden.md) |
| Show a domain error in a form | generic `catch` + toast | Eden's `error.status` in the `useMutation` — [Elysia - Eden](elysia-eden.md) |

The full Eden bridge — type export, the shape of Eden's return, the TanStack Query integration, `parseDate`, Treaty × Fetch and where responsibility changes owner — lives in [Elysia - Eden](elysia-eden.md); the documentation side lives in [Elysia - OpenAPI](elysia-openapi.md).

### And Zod?

Elysia 1.4 accepts Zod through Standard Schema, so the question is not "can I" — it is "where". A calibrated answer, with the verified trade-offs, is in [Elysia - Schema and Validation](elysia-schema-and-validation.md) § 2. The summary: `t` at the HTTP boundary (query/params coercion, file validation by magic number, OpenAPI with no extra configuration), Zod where the schema is already shared with the frontend or with code that already depends on it — knowing that with Zod, OpenAPI requires `mapJsonSchema: { zod: z.toJSONSchema }` and coercion becomes your job (`z.coerce.number()`).

---

## Related

- [Elysia - Routing and Handler](elysia-routing-and-handler.md) · [Elysia - Lifecycle and Plugins](elysia-lifecycle-and-plugins.md) · [Elysia - Schema and Validation](elysia-schema-and-validation.md) · [Elysia - OpenAPI](elysia-openapi.md) · [Elysia - Eden](elysia-eden.md)
- `Bun` · `Bun - HTTP e Servidor` · `Bun - Runtime e APIs` · `Bun - Testes`
- `React.js` · `TanStack Query - O que um Dev Frontend Precisa Saber` · `TanStack Query - Cache e Frescor` · `TanStack Router` · `TypeScript`
- `Node.js` · `Nest.js` — the alternatives Elysia replaces in this stack

## Sources consulted

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
