# Elysia skills — build, schema, eden, openapi, diagnose

Five skills, one directory each, with their own `references/`, `scripts/` and `evals/`. The family is
**self-contained**: its normative docs live in [`docs/`](docs/elysia.md), not in the tc96
`knowledge-base/` (the four Portuguese notes were removed on 2026-10-25).

| Skill | The question it answers | Source |
| --- | --- | --- |
| `elysia-build` | how do I write this route, module, error, session or auth plugin? | [Elysia - Routing and Handler](docs/elysia-routing-and-handler.md) |
| `elysia-schema` | how do I validate and type this request and response? | [Elysia - Schema and Validation](docs/elysia-schema-and-validation.md) |
| `elysia-eden` | how does a TypeScript client call this API — and TanStack Query on top of it? | [Elysia - Eden](docs/elysia-eden.md) |
| `elysia-openapi` | how do I document this API so the spec matches what it answers? | [Elysia - OpenAPI](docs/elysia-openapi.md) |
| `elysia-diagnose` | why does this hook or plugin not affect the route? | [Elysia - Lifecycle and Plugins](docs/elysia-lifecycle-and-plugins.md) |

## Why five, not three

The old `elysia-schema` answered three questions with three different audiences: declaring a schema on
the server, documenting the API, and consuming it from a React app. Its description triggered on all of
them and its minimum loading pulled the whole 11.7k-token Portuguese satellite for any one. Eden and
OpenAPI are now skills of their own, each loading one doc. `elysia-build` also took over writing
plugins and auth, which no skill owned before — `elysia-diagnose` only diagnosed.

## Docs

Hub [Elysia](docs/elysia.md) plus five satellites: routing and handler, lifecycle and plugins, schema and
validation, OpenAPI, Eden. Each satellite carries its own decision tree, rules and antipatterns, so a
skill loads one of them; the hub is loaded only for the import map, the runtime limits or an
`ELYSIA-APP-*` rule.

Behaviour marked *verified* was executed on elysia 1.4.30, @elysia/eden 1.4.10, @elysia/openapi 1.4.16,
zod 4.6.7 and @tanstack/query-core 5.104.5 (2026-10-25) — 216 passing tests in the authoring playground. Every
block in `references/patterns.md` passed `bun test` and `tsc --noEmit` before it was written down.

What execution changed:

- **New rules** `ELYSIA-TYPE-14` to `-20`: `import type` for the app type, narrowing Eden errors by
  status (422 included), retrying only 5xx, `onResponse` observers returning `undefined`, explicit
  `operationId`s, gating the docs per environment, declaring `security` on protected routes.
- **Reworded** `ELYSIA-TYPE-07` (Zod 4 reaches OpenAPI natively; `mapJsonSchema: { zod: z.toJSONSchema }`
  documents request bodies wrongly) and `ELYSIA-LIFE-06` (a destructured `store` primitive is stale
  within the same call, not frozen across requests).
- **Facts the old notes had wrong or missed:** Eden's `error` is an `Error` instance at runtime; an app
  with no `onError` sends a thrown error's message as the 500 body even in production; `app.handle`
  with a one-label origin (`http://x/`) answers 404 for every route — the old scope-proof test used it;
  an app-level catch-all `onError` swallows the codes modules register; `t.Integer` coerces strings in a
  body while `t.Number` does not; `cors()` reflects any origin with credentials.

## Scripts

- `elysia-diagnose/scripts/elysia-scan.mjs` — an AST scan (TypeScript compiler API) with groups `route`,
  `lifecycle`, `schema`, `openapi`, `eden`; findings are `high` or `candidate`. Every skill's
  `self-check.sh` calls it as a sibling; the packager copies it into each `.skill`. It replaced three
  grep scripts that, on a correct project, flagged `t.File` and a JSON `t.Number` as defects and, on a
  broken one, missed a `queryFn` that never throws and the default `parseDate`.
- `elysia-eden/scripts/self-check.sh` — `strict` in every tsconfig and one `elysia` version across the
  workspace, then the `eden` scan.
- `elysia-openapi/scripts/spec-lint.mjs` — reads a dumped `/openapi/json` and lists duplicate or missing
  `operationId`s, missing summaries, tags, responses and security, trailing slashes, empty body schemas.
- `elysia-diagnose/scripts/generate-id-map.sh` — writes each skill's `references/id-map.md` (authoring only).

## Evals

Two cases per skill under `evals/<case>/`, in the layout `claude plugin eval` reads, each with a runnable
Bun fixture in `files/` and one grader per verifiable statement. Run them with
`claude plugin eval skills/elysia/<skill> --scaffold`, or through the skill-creator loop.

Results on 2026-10-25, one run per configuration, against the old skills with their knowledge-base notes:

| Iteration | New skills | Old skills | Tokens per run | Time per run |
| --- | ---: | ---: | ---: | ---: |
| 1 | 72/73 | 71/73 | 104k vs 130k (−20%) | 184 s vs 276 s (−34%) |
| 2 (after the fixes iteration 1 surfaced) | 75/75 | 71/75 | 106k vs 130k (−19%) | 208 s vs 280 s (−26%) |

Most cases tie on pass rate; the old notes were long but mostly right. The new skills win on cost and on
the facts only execution revealed: a prefixed `.post('/')` documented with a trailing slash, an anonymous
request answered 422 before auth runs, test state shared across files.

<!-- tokens:inicio -->
## Context budget

Measured with tiktoken (`cl100k_base`) on 2026-10-25, after iteration 2. **`SKILL.md`** is what enters the context when
the skill triggers. **Before step 1** adds the one doc the skill marks as mandatory.

| Skill | description | `SKILL.md` | all references | before step 1 | loads |
| --- | ---: | ---: | ---: | ---: | --- |
| `elysia-build` | 209 | 2.327 | 6.136 | 10.448 | its satellite (8.121) |
| `elysia-schema` | 196 | 1.892 | 5.420 | 8.155 | its satellite (6.263) |
| `elysia-eden` | 241 | 1.962 | 5.176 | 8.459 | its satellite (6.497) |
| `elysia-openapi` | 223 | 1.901 | 4.655 | 6.645 | its satellite (4.744) |
| `elysia-diagnose` | 235 | 1.797 | 5.052 | 4.523 | `id-map.md` (2.726), then one satellite per finding |

The old skills told the model to load the 15.9k-token Portuguese hub plus a satellite before step 1:
**25.641** (`elysia-build`), **29.507** (`elysia-schema`, which Eden and OpenAPI tasks also hit) and
**27.228** (`elysia-diagnose`). The new ones need 4.5k–10.4k, a 60–85% cut.

The price is the always-loaded metadata: five descriptions cost **1.104** tokens against **496** for three,
because each now names its neighbours and its "do not use for". The six docs total 47.624 tokens (the four
Portuguese notes were 44.682); the growth is the executed Eden and OpenAPI material, and no skill loads
more than one doc before it starts.
<!-- tokens:fim -->

## Related

- [Skills index](../README.md) · `http-contract` · `drizzle-query` · `tanstack-query` · `bun-test-build`
