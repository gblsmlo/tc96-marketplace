---
titulo: Bun
Link: https://bun.com/docs
tags:
  - bun
  - reference
  - agent-context
source: "Official documentation — https://bun.com/docs"
verificado-em: 2026-08-15
---

# Bun — guided reference

> **What this note is.** The single entry point for Bun in this vault: for me when consulting, and for coding agents when generating or reviewing code that runs on Bun. It is not a linear summary of the documentation — it is a **router**. It decides what to load, offers the mental model that makes the rest make sense, and exposes citable rules that a skill or a code review can reference by ID.
>
> **What it is not.** It does not replace the source. When they diverge, [bun.com/docs](https://bun.com/docs) wins, and this note must be corrected.
>
> **A self-contained family.** These notes live inside the `bun` skill family, not in the tc96 knowledge base, so the family can ship on its own. Names in code spans — `Bun - HTTP e Servidor`, `Bun - Dados e Persistência`, `Monorepo com Bun - estrutura e tooling`, `Storybook - Testes e Interações`, `Elysia`, `Hono` — and IDs from other families (`TS-*`, `SB-*`, `PW-*`, `DRZ-*`) belong to the tc96 knowledge base: useful context when it is installed, never required to apply a `BUN-*` rule.

Inventory verified directly on bun.com/docs on **2026-08-15**. Version verified: **Bun 1.3.14** (`latest` on the npm registry, published on 2026-05-13).
See [Sources consulted](#sources-consulted).

---

## 1. How to use this doc

### For a human

Read section 2 once — it is short and explains why Bun does not behave like "faster Node". Then use section 4 as an index, section 3 when an import fails, and section 5 when you are torn between two neighboring APIs. The satellites are for on-demand reading.

### For a coding agent

Load in this order, stopping as soon as you have enough:

| Step | Load | When |
| --- | --- | --- |
| 1 | This note (sections 2, 3, 5, 6) | Whenever the task involves Bun |
| 2 | The satellite of the specific domain | When the task touches a concrete API — use section 4 to find out which |
| 3 | [Bun - Runtime and APIs](bun-runtime-and-apis.md) | Execution, files, env, processes, module resolution |
| 4 | [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md) § 5 (compatibility matrix) | Whenever you are porting code from Node.js |
| 5 | [Bun - Package Manager](bun-package-manager.md) | Installation, lockfile, monorepo, CI |

**Context economy rule:** never load all the satellites.

### Conventions and vocabulary

**All examples are TypeScript.** Bun executes `.ts` and `.tsx` directly — the example code runs as is, with no build step.

Terms used without redefinition in the satellites:

| Term | Meaning in this doc |
| --- | --- |
| **Bun runtime** | the process started by `bun`, where the `Bun` global and the `bun:*` modules exist |
| **`Bun` global** | the `Bun` object, available without import; absent in Node.js and in the browser |
| **in-flight transpilation** | Bun converts TS/JSX to JS on every file load, before executing; there is no artifact on disk |
| **hoisted × isolated** | the two `node_modules` layout strategies (`--linker`); the second is pnpm's model |
| **phantom dependency** | a package that can be imported without being declared in `package.json`, a side effect of the hoisted layout |
| **lifecycle script** | `preinstall`/`postinstall`/etc. declared by a dependency, executed by the package manager |
| **soft reload** | the `--hot` reload: re-evaluates modules without restarting the process, preserving `globalThis` |
| **hard restart** | the `--watch` reload: kills and restarts the process with the same arguments |
| **preload** | a module loaded before any other (`--preload`, `[test] preload`) |

---

## 2. Mental model

Five statements. Almost every mistake an agent makes in Bun violates one of them.

**1. `bun` is four tools in the same binary, and that changes the workflow, not just the speed.** Runtime, package manager, test runner and bundler are the same executable. The practical consequence is not "fewer dependencies": it is that there is no `jest.config`, `ts-node`, `nodemon` or `dotenv` in the project, and writing one of them is a regression (`BUN-CORE-03`). Before adding a tool to `package.json`, check § 4 — the binary probably already does that. **The bundler is the honest exception:** Bun has one, but for a React SPA in production the plugin ecosystem still belongs to Vite, and Bun's dev server is declared *work in progress* by the source itself. The criterion is in [Bun - Bundler and Build](bun-bundler-and-build.md) § 10.

**2. The `Bun` global's APIs need no import, and for that reason they do not exist outside Bun.** `Bun.file`, `Bun.serve`, `Bun.spawn`, `Bun.password` are on `globalThis` without `import`. The price is that the same file, run with `node`, breaks with `ReferenceError`. Library code meant to run on both runtimes uses `node:*` or detects the environment; application code assumes Bun deliberately.

**3. TypeScript and JSX are executed, not compiled.** `bun index.tsx` runs. Bun reads `tsconfig.json` only to decide the JSX **transform** and the `paths` — it **does not type check**. No type error stops execution. Type checking remains a separate step (`tsc --noEmit`) and needs to be in CI, or wrong types reach production without warning.

**4. Node.js compatibility is a declared goal, not an achieved state — and knowing where it ends avoids the largest class of bug.** The source is explicit: *"This is an ongoing effort"*, and it keeps a [per-module status page](https://bun.com/docs/runtime/nodejs-compat) measured against Node.js v26. Most modules are 🟢, several are 🟡 with named gaps (`node:https` without `SNICallback`, `node:vm` partial, `node:worker_threads` ignoring `resourceLimits`), and `node:sea` is 🔴. "Works in Node" is not evidence that it works in Bun; the compatibility page is.

**5. ESM and CJS coexist in the same file, with one exception that matters.** `import` and `require` work side by side, and `require()` accepts `.ts`, `.tsx` and `.mjs`. The only break is `require()` of a module with **top-level `await`** — `require` is synchronous by definition. It is the only interop rule that needs to be remembered.

> **The corollary that saves time:** when something does not run in Bun, the first question is not "what is Bun's bug". It is *"is this using a Bun global in a `node` process, a `node:*` API marked 🟡, or `require()` on a module with top-level await?"*. The three cover most cases. See § 5.

---

## 3. Import and execution boundaries

Knowing where something comes from — and where it runs — avoids half the errors.

| Origin | How it is obtained | Contains | Exists outside Bun? |
| --- | --- | --- | --- |
| `Bun` global | nothing (already global) | `Bun.file`, `Bun.write`, `Bun.serve`, `Bun.spawn`, `Bun.password`, `Bun.build`, `Bun.env`, utilities | **No** |
| `import { … } from "bun"` | named import | the same APIs as the global, importable (`$`, `serve`, `file`, `randomUUIDv7`, …) | **No** |
| `bun:test` | `import { test, expect } from "bun:test"` | runner, `expect`, `mock`, `spyOn`, `jest`, `vi`, `expectTypeOf` | **No** |
| `bun:sqlite` | `import { Database } from "bun:sqlite"` | native SQLite driver | **No** |
| `bun:ffi` | `import { dlopen } from "bun:ffi"` | calling native libraries | **No** |
| `node:*` | `import { readdir } from "node:fs/promises"` | reimplemented Node.js surface | Yes |
| Web globals | nothing | `fetch`, `Request`, `Response`, `Headers`, `URL`, `Blob`, `ReadableStream`, `AbortController`, `crypto`, `WebSocket`, `structuredClone` | Yes (modern browser/Node) |
| Node globals | nothing | `process`, `Buffer`, `__dirname`, `__filename`, `require`, `module`, `global` | Yes |
| `import.meta` | language | `.dir`, `.file`, `.path`, `.url`, `.main`, `.env`, `.resolve()`, and the aliases `.dirname`/`.filename` | Partial (names differ) |

Three consequences that show up in generated code:

- **`bun:test` only exists inside `bun test`.** Importing it from an application file and running it with `bun run` fails.
- **`Bun.env`, `process.env` and `import.meta.env` are the same object.** The source literally says the last two are *aliases* of `process.env`. **Inside Bun**, choosing between them is style, not semantics. **Coming from Vite, it is not** — there `import.meta.env` is another object, filtered by the `VITE_` prefix and resolved by mode. Under Bun, `import.meta.env.VITE_FOO` works (Bun does not filter by prefix), but `import.meta.env.MODE`, `.DEV`, `.PROD` and `.BASE_URL` are **`undefined`**: they are constants that Vite injects at build time. Full table in [Bun - Runtime and APIs](bun-runtime-and-apis.md) § 4.
- **Types require `@types/bun`.** `bun add -d @types/bun`. On TypeScript 6.0+, `"types": ["bun"]` in `compilerOptions` is also needed — the auto-discovery of `@types` no longer exists.

---

## 4. API map

Surface verified on bun.com/docs. The **Satellite** column says what to load, **and in which section** — opening a 500-line satellite to find a signature is what this table exists to avoid.

**Granularity, and why.** One row per unit that a task asks for on its own. This rule is not aesthetic: while half of § 4 was per signature and the other half per area ("HTTP server | `Bun.serve`, `routes`, WebSockets, cookies, streaming"), a reader without context looking for the diagnosis of an SSE that kept dropping found nothing here — they reached the answer by reading the 34-rule table of § 6.1 linearly. A router whose routing table covers half the address space at the wrong granularity does not route; it gets it right by chance when the right satellite was already obvious. **When adding an API to a satellite, add the row here.**

**This table is a routing index, not an allow-list.** An API absent from here means "not verified in this doc" — consult bun.com/docs and update the note. See § 7.

**Container and Docker image** have two legitimate routes and the obvious path hides one: [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md) § 6 (`oven/bun` image with `node_modules`) and [Bun - Bundler and Build](bun-bundler-and-build.md) § 8 (`--compile`, single binary without `node_modules`).

**Deliberately outside this map:** TCP/UDP/DNS (`Bun.listen`, `Bun.connect`, `Bun.udpSocket`, `Bun.dns`), `HTMLRewriter`, `Bun.Image`, `Bun.WebView`, `Bun.Transpiler`, `Bun.FileSystemRouter`, `Bun.CSRF`, `Bun.Secrets`, `Bun.cron`, Node-API and the embedded C compiler, the `Bun.TOML`/`Bun.XML`/`Bun.markdown`/JSON5/JSONL parsers, `Bun.Glob`, `Bun.semver`, `Bun.color`, `Bun.archive` and `bun:jsc`. All of them exist and are documented in the source; absence here means **"not verified in this doc"**, not "does not exist".

### Execution and runtime

| API / command | What it is for | Satellite |
| --- | --- | --- |
| `bun run <file>` / `bun <file>` | Execute `.js`, `.ts`, `.jsx`, `.tsx` without a build | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `bun run <script>` | Run a `package.json` script | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `bun --watch` / `bun --hot` | Hard restart × soft reload | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `bun --bun` | Force the Bun runtime on a CLI with a `node` shebang | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `--preload` (`-r`, `--import`) | Load a module before everything else | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `import.meta.*` | Path, URL, entrypoint and resolution of the current module | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `bunfig.toml` | Runtime, install and test configuration | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |

### Files, env and processes

| API | What it is for | Satellite |
| --- | --- | --- |
| `Bun.file(path)` | Lazy reference to a file, with the `Blob` interface | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `Bun.write(dest, data)` | Multi-purpose write (string, Blob, `Response`, TypedArray, `BunFile`) | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `file.writer()` → `FileSink` | Incremental, buffered writing | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `Bun.stdin` / `stdout` / `stderr` | Standard streams as `BunFile` | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `node:fs` | Directories, permissions, everything `Bun.file` does not cover | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `.env` loading | Automatic, with precedence order and expansion | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `Bun.spawn` / `Bun.spawnSync` | Subprocesses, asynchronous × blocking | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `Bun.$` (Bun Shell) | Cross-platform shell commands with automatic escaping | [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md) |

### Hashing, passwords and utilities

| API | What it is for | Satellite |
| --- | --- | --- |
| `Bun.password.hash` / `.verify` | Argon2 (default) and bcrypt, with embedded salt | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `Bun.CryptoHasher` | Incremental cryptographic hash (sha256, blake2b, …) | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `Bun.hash.*` | **Non-cryptographic** hash (wyhash, xxHash, crc32, …) | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `Bun.version`, `Bun.revision`, `Bun.main` | Identity of the runtime and of the entrypoint | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `Bun.which`, `Bun.sleep`, `Bun.peek`, `Bun.deepEquals`, `Bun.escapeHTML` | Utilities that show up in real code | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `Bun.randomUUIDv7()` | Monotonic, sortable UUID v7 | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `Bun.gzipSync` / `deflateSync` / `zstdCompress` and inverses | Synchronous and asynchronous compression | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `Bun.readableStreamTo*` | Collect a `ReadableStream` into text, JSON, bytes, `Blob`, `FormData` | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |

### Package manager

| Command | What it is for | Satellite |
| --- | --- | --- |
| `bun install`, `bun add`, `bun remove`, `bun update` | Dependency cycle | [Bun - Package Manager](bun-package-manager.md) |
| `bun ci` / `--frozen-lockfile` | Reproducible installation in CI | [Bun - Package Manager](bun-package-manager.md) |
| `bun.lock` | Text lockfile (default since Bun 1.2) | [Bun - Package Manager](bun-package-manager.md) |
| `workspaces`, `catalog:`, `--filter` | Monorepo | [Bun - Package Manager](bun-package-manager.md) |
| `trustedDependencies`, `bun pm trust`/`untrusted` | Security model for lifecycle scripts | [Bun - Package Manager](bun-package-manager.md) |
| `overrides` / `resolutions`, `bun patch` | Control over transitive dependencies | [Bun - Package Manager](bun-package-manager.md) |
| `bun outdated`, `bun why`, `bun audit`, `bun pm` | Inspection and auditing | [Bun - Package Manager](bun-package-manager.md) |
| `bun x` / `bunx` | Run a package binary without installing | [Bun - Package Manager](bun-package-manager.md) |
| `--linker hoisted` / `isolated` | `node_modules` layout | [Bun - Package Manager](bun-package-manager.md) |

### Test runner

**The test runner has its own structure:** [Bun - Tests](bun-tests.md) is the hub, with six satellites and the whole `BUN-TEST-*` family (29 rules). The rows below route straight to the right satellite; the hub has the complete map and the decision trees.

| API / flag | What it is for | Satellite |
| --- | --- | --- |
| `bun test`, discovery, filters, `--changed` | What enters the suite and what runs in this invocation | [Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) |
| `bunfig.toml [test]`, `NODE_ENV`/`TZ`, exit code | Configuration and the environment the runner imposes | [Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) |
| `test`/`describe`/`expect`, matchers, `expect.assertions` | Test body and assertion | [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) |
| `test.each`/`.skip`/`.only`/`.todo`/`.failing`/`.if` | Modifiers | [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) |
| `toMatchSnapshot`, `toMatchInlineSnapshot`, `-u` | File and inline snapshots | [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) |
| `mock()`, `spyOn()`, `mock.module()`, the three cleanups | Function mocks, spies and module mocks | [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) |
| `setSystemTime`, `useFakeTimers`, `advanceTimersByTime` | Freeze the date and make time pass | [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) |
| `beforeAll`/`beforeEach`/`afterEach`/`afterAll`/`onTestFinished` | Lifecycle and scope | [Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) |
| `--parallel`, `--isolate`, `BUN_TEST_WORKER_ID`, `--shard` | Isolation, parallelism and splitting in CI | [Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) |
| `test.concurrent`/`.serial`, `--max-concurrency` | Concurrency inside the file | [Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) |
| `--preload` / `[test] preload` for DOM (happy-dom) | End-to-end component test | [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md) |
| `--coverage`, `coverageThreshold`, `--reporter=junit` | Coverage, threshold that fails the build, and reporters | [Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md) |

### HTTP server

| API | What it is for | Satellite |
| --- | --- | --- |
| `Bun.serve(options)` | Starts the server; returns the `server` object | `Bun - HTTP e Servidor` § 1 |
| `routes` | Native routing by path and method, with params typed from the key literal | `Bun - HTTP e Servidor` § 2 |
| Handler `(req, server)` | Route signature — the 2nd argument carries `timeout`, `upgrade`, `publish`, `requestIP` | `Bun - HTTP e Servidor` § 2 |
| `fetch(req, server)` | Fallback for what `routes` does not match | `Bun - HTTP e Servidor` § 2 |
| `new Response(Bun.file(p))` | Serve a file with `Range`, `ETag`, `304` and `sendfile(2)` | `Bun - HTTP e Servidor` § 3 |
| `server.timeout(req, s)` | Turns off the `idleTimeout` per request — mandatory in streaming and SSE | `Bun - HTTP e Servidor` § 3 |
| `idleTimeout` | Default 10 s, counts **during** the response; max. 255 | `Bun - HTTP e Servidor` § 3 |
| `req.cookies` (`CookieMap`) | Read and write cookies; applies `Set-Cookie` on its own, and **only** inside `routes` | `Bun - HTTP e Servidor` § 4 |
| `server.upgrade(req, { data })` | Upgrade to WebSocket; per-connection state goes in `ws.data` | `Bun - HTTP e Servidor` § 5 |
| `websocket: { message, open, close }` | Single handler per server | `Bun - HTTP e Servidor` § 5 |
| `ws.publish` / `server.publish` | Pub/sub by topic (`publishToSelf` is `false`) | `Bun - HTTP e Servidor` § 5 |
| `error(err)` | Server error handler | `Bun - HTTP e Servidor` § 6 |
| `development` | Accepts a boolean **and an object** — `NEVER` on in production | `Bun - HTTP e Servidor` § 6 |
| `server.reload()`, `.stop()`, `.requestIP()` | Lifecycle and binding | `Bun - HTTP e Servidor` § 6 |
| `tls`, `unix`, `reusePort`, `hostname`, `port` | Binding and transport options | `Bun - HTTP e Servidor` § 6 |
| **What does not exist natively** | middleware, typed validation, typed client, CORS | `Bun - HTTP e Servidor` § 7 · `Backend no runtime Bun` |

### Bundler and build

| API / flag | What it is for | Satellite |
| --- | --- | --- |
| `Bun.build(config)` / `bun build` | API × CLI of the same engine | [Bun - Bundler and Build](bun-bundler-and-build.md) § 2 |
| `target` (`browser`/`bun`/`node`) | Decides resolution, globals and polyfill | [Bun - Bundler and Build](bun-bundler-and-build.md) § 3 |
| `external`, `packages`, `splitting` | What leaves the bundle | [Bun - Bundler and Build](bun-bundler-and-build.md) § 4 |
| `minify`, `sourcemap`, `loader`, `define` | Output and build-time substitution | [Bun - Bundler and Build](bun-bundler-and-build.md) § 5 |
| `Bun.plugin`, `onResolve`, `onLoad` | Plugins, same API for runtime and bundler | [Bun - Bundler and Build](bun-bundler-and-build.md) § 6 |
| `.html` import · `import.meta.hot` | Dev server and HMR — declared *work in progress* | [Bun - Bundler and Build](bun-bundler-and-build.md) § 7 |
| `--compile`, `--target=bun-<os>-<arch>`, `bytecode` | Single executable | [Bun - Bundler and Build](bun-bundler-and-build.md) § 8 |
| `with { type: "macro" }` | Build-time execution, result inlined | [Bun - Bundler and Build](bun-bundler-and-build.md) § 9 |
| **Bun × Vite** | Tie-breaking criterion for a React SPA | [Bun - Bundler and Build](bun-bundler-and-build.md) § 10 |

### Data and persistence

| API | What it is for | Satellite |
| --- | --- | --- |
| `new Database(path, { strict, safeIntegers })` | Embedded, synchronous SQLite | `Bun - Dados e Persistência` § 2 |
| `db.query()` × `db.prepare()` | Cached (20 entries) × not cached | `Bun - Dados e Persistência` § 2 |
| `.get()`, `.all()`, `.run()`, `.iterate()`, `.values()` | Executors — `.get()` returns `null`, not `undefined` | `Bun - Dados e Persistência` § 2 |
| Parameter (`$name`, `?`, `${}` in the tag) | **The defense against SQL injection** | `Bun - Dados e Persistência` § 3 |
| `db.transaction(fn)` · `sql.begin(fn)` | Transaction — in `begin`, use the `tx` received | `Bun - Dados e Persistência` § 4 |
| `PRAGMA journal_mode = WAL` | Read concurrency in SQLite | `Bun - Dados e Persistência` § 4 |
| `Bun.sql` (tagged template) | **PostgreSQL, MySQL and SQLite** — the adapter comes from the URL format | `Bun - Dados e Persistência` § 5 |
| `sql.reserve()`, `sql.unsafe()`, `sql.file()`, `ssl` | Pool, escape hatch, script, TLS (default `"disable"`) | `Bun - Dados e Persistência` § 5 |
| `POSTGRES_URL` / `DATABASE_URL` / `PGSSLMODE` … | Connection variables, by name and precedence | `Bun - Dados e Persistência` § 5 |
| Redis client · `S3Client` / `Bun.s3` + presign | The other two embedded clients | `Bun - Dados e Persistência` § 6 |
| **Schema migration** | **Bun has none.** It is yours or an external tool's | `Bun - Dados e Persistência` § 8 · |

### Shell, native and compatibility

| API | What it is for | Satellite |
| --- | --- | --- |
| `Bun.$` | Cross-platform shell, interpolation escaped by default | [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md) § 2 |
| `.text()`, `.json()`, `.quiet()`, `.nothrow()`, `.cwd()`, `.env()` | Surface of `$` | [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md) § 2 |
| `bun:ffi` — `dlopen`, `cc`, `JSCallback` | Native libraries — **experimental** | [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md) § 3 |
| `Worker` | Real parallelism — **experimental** | [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md) § 4 |
| **`node:*` compatibility matrix** | Where compatibility ends; 🟢/🟡/🔴 legend | [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md) § 1 and § 5 |
| `oven/bun` image, `USER bun`, `--no-env-file` | Container deploy | [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md) § 6 |
| `SIGTERM` + `server.stop()` + `process.exit()` | Graceful shutdown — both halves | [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md) § 6 |
| `--smol` | Increases GC frequency; it is **not** "container mode" | [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md) § 6 |

---

## 5. Decision trees

They map **symptom → correct API**. It is where code generated for Bun errs the most, because almost every task has two plausible answers: Node's and Bun's.

### I need to read or write a file. Which API?

The deciding question is not "async or sync" — it is **whether the operation is about a file's content or about the file system**.

```
Is it about a file's CONTENT?
├── NO (mkdir, readdir, rm, stat, chmod, watch, symlink)
│   └── node:fs / node:fs/promises. There is no equivalent in Bun.*
│       → the File I/O doc itself says to use node:fs for this
│
└── YES
    ├── READ
    │   ├── whole, once → Bun.file(path).text() | .json() | .bytes() | .arrayBuffer()
    │   ├── in chunks → Bun.file(path).stream()  → ReadableStream
    │   └── only check existence → await Bun.file(path).exists()
    │       ⚠ do NOT use .size === 0: a nonexistent file also has size 0
    │
    └── WRITE
        ├── ready payload (string, Blob, TypedArray, Response, BunFile)
        │   → await Bun.write(dest, data)      ← copies a file, saves an
        │                                        HTTP response, writes
        │                                        to Bun.stdout — all the same
        ├── incremental / in a loop → Bun.file(p).writer() → FileSink
        │   └── .write() buffers · .flush() writes · .end() closes
        │       ⚠ the process does NOT exit until .end() (or .unref())
        └── append → node:fs (Bun.write overwrites)
```

On "when async matters": `Bun.file().text()` and `Bun.write()` are asynchronous and **do not block the event loop**. Inside a `Bun.serve` handler that is mandatory. In a short-lived CLI, synchronous `node:fs` is acceptable and sometimes simpler — but never in a server.

### I came from Node and my code does not run. What to check?

Walk through in order. The first three cover most cases.

```
1. ReferenceError: Bun is not defined
   → the process is `node`, not `bun`.
     ├── is it a CLI with shebang #!/usr/bin/env node? → bun run --bun <cli>
     │                                                  or bunx --bun <cli>
     └── is it your code? → run it with `bun`, or swap the Bun global for node:*

2. Cannot find name 'Bun' (a TYPE error, not a runtime one)
   → @types/bun is missing:  bun add -d @types/bun
     └── TypeScript 6.0+ still requires "types": ["bun"] in compilerOptions

3. Error inside a require()
   └── does the module have top-level await? → require() is synchronous; use import
                                               or dynamic import()

4. A node:* module behaves differently
   → consult the compatibility page BEFORE suspecting your code.
     Several modules are 🟡 with named gaps; node:sea is 🔴.
     → [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md)

5. A package did not work after installing
   ├── does it depend on postinstall? → Bun does NOT run lifecycle scripts by default.
   │   → bun pm untrusted  (lists what was blocked)
   │   → trustedDependencies / bun pm trust — see [Bun - Package Manager](bun-package-manager.md)
   └── does it import something it did not declare (phantom dependency)?
       → the isolated linker exposes this; hoisted hid it

6. It compiles but the type is wrong in production
   → Bun does NOT type check. `tsc --noEmit` needs to be in CI.
```

### I need to run a process or a command. Which API?

```
Is it a shell command with pipe, redirect, glob or variable?
├── YES
│   ├── and it needs to be cross-platform (Windows included)
│   │   → Bun.$  — implements ls/cd/rm natively, escapes
│   │             interpolation by default (no injection)
│   │             → [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md)
│   └── and the environment is POSIX-only and the command is trivial
│       → Bun.spawn(["sh", "-c", …]) still works, but escaping
│         becomes your responsibility
│
└── NO — it is running a binary with arguments
    ├── inside an HTTP server or code with a live event loop
    │   → Bun.spawn(cmd, { … })            ← NEVER spawnSync here
    │      ├── needs a deadline → { timeout, killSignal }
    │ ├── needs cancellation → { signal }
    │      ├── write to stdin → { stdin: "pipe" } → proc.stdin.write()
    │      └── read stdout → await proc.stdout.text()
    ├── in a short-lived CLI, small output
    │   → Bun.spawnSync(cmd)  → { success, stdout: Buffer, stderr: Buffer }
    │      └── guard against unbounded output: { maxBuffer }
    └── needs an API identical to Node's (shared lib)
        → node:child_process
```

### Which `bun` command for this task?

```
What do you want to run?
├── a project file                → bun <file>          (bun run <file>)
├── a package.json script         → bun run <script>
│   └── ⚠ if the name collides with a built-in bun command,
│         the built-in wins: ALWAYS use `bun run <script>` in automation
├── a binary of an already-installed dependency
│   ├── with the runtime the shebang asks for → bun run <bin>   (or bunx <bin>)
│   └── forcing the Bun runtime              → bun run --bun <bin>
├── an npm package you do NOT want to install → bunx <pkg>   (= bun x)
│   ├── pinned version            → bunx <pkg>@<version>
│   ├── binary named ≠ package    → bunx -p <pkg> <bin>
│   └── forcing Bun               → bunx --bun <pkg>
│       ⚠ --bun comes BEFORE the name; after the name it goes to the package
└── a system command              → bun run <cmd>  (last in the resolution order)

Resolution order of `bun run <x>`:
  1. package.json script → 2. source file → 3. dependency binary
  → 4. system command (only with an explicit `bun run`)

Bun flags come after `bun`, never at the end:
  bun --watch run dev   ✔     bun run dev --watch   ✘ (goes to the script)
```

---

## 6. Normative rules

Rules citable by ID. A skill, a review prompt or a PR comment can reference `BUN-CORE-03` without repeating the text. The full body of each family lives in the corresponding satellite; here are the inviolable ones.

**Convention:** `MUST` / `NEVER` are normative. A violation is a bug, not a matter of style.

### `BUN-CORE-*` — invariants of the single binary

| ID | Rule |
| --- | --- |
| `BUN-CORE-01` | Code that uses the `Bun` global **MUST** run under the `bun` process — not under `node`, nor under a CLI with a `node` shebang without `--bun`. |
| `BUN-CORE-02` | A Bun project **MUST** have explicit type checking in CI (`tsc --noEmit`) — the runtime transpiles without checking types. |
| `BUN-CORE-03` | A PR that adds `jest`, `ts-node`, `nodemon` or `dotenv` to `package.json` **MUST** state in its body why the built-in equivalent does not serve — the binary covers all four without caveat. **The bundler is not under this rule:** there is a real trade-off there, decided in [Bun - Bundler and Build](bun-bundler-and-build.md) § 10. |
| `BUN-CORE-04` | A module with top-level `await` is **NEVER** loaded with `require()`. |
| `BUN-CORE-05` | A claim about Node.js compatibility **MUST** be checked against the official compatibility page — "works in Node" is not evidence. |
| `BUN-CORE-06` | Automation (script, CI, Dockerfile) **MUST** use `bun run <script>` in its explicit form; the short form `bun <script>` loses to a built-in command of the same name. |
| `BUN-CORE-07` | A **runtime** flag (`--watch`, `--hot`, `--bun`, `--preload`/`-r`, `--no-env-file`) **MUST** come before the subcommand — `bun --preload ./setup.ts run ./index.ts`. A **subcommand** flag (`--filter`, `--frozen-lockfile`, `--production`, `--coverage`) comes after it — `bun install --filter './packages/api'`. A flag placed **after the script or package name** is **NEVER** Bun's: there it is passed through to the target. |

### 6.1 Critical rules from the satellites

The complete families live in the satellites, but **these need to travel with the minimum path** — they are the ones that show up most in generated code and cannot depend on the agent having opened the right satellite.

**Entry criterion for this table:** the violation is silent (no error in dev), or it is a security matter, or the behavior contradicts the habit brought from Node. A rule that the compiler or a test catches stays only in the satellite.

> **The satellite is canonical.** The rows below reproduce the satellite's text **verbatim**, not a paraphrase. In any divergence between this table and the satellite, the satellite wins and this table is the bug — § 7 says to cite by ID without paraphrasing, and two divergent copies of a normative rule make that impossible. This table has already had a regression of that kind: a trimmed version of `BUN-SYS-11` lost the `process.exit()` and prescribed a shutdown that leaves the container hanging until `SIGKILL`.

| ID | Rule | Satellite |
| --- | --- | --- |
| `BUN-RT-01` | A **directory** operation (`mkdir`, `readdir`, `rm`, `stat`) **MUST** use `node:fs` — `Bun.file`/`Bun.write` only handle file content. | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `BUN-RT-03` | File existence **MUST** be checked with `await file.exists()` — `size === 0` is also the value of a nonexistent file. | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `BUN-RT-05` | A production secret **NEVER** comes from a `.env` file loaded by the runtime. | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `BUN-RT-08` | An HTTP server handler **NEVER** calls `Bun.spawnSync` or a `*Sync` API of `node:fs` — it blocks the event loop of the whole process. | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `BUN-RT-09` | A subprocess of unguaranteed duration **MUST** receive `timeout` or `signal`. | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `BUN-RT-10` | A password **MUST** be handled with `Bun.password`; `Bun.hash` **NEVER** touches a password, token or secret — it is a non-cryptographic hash. | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `BUN-RT-12` | Production execution **MUST** have `node_modules` present or run with `--no-install` — without that, auto-install resolves dependencies from the network at runtime. | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `BUN-PKG-01` | `bun.lock` **MUST** be versioned in the repository. | [Bun - Package Manager](bun-package-manager.md) |
| `BUN-PKG-02` | Installation in CI **MUST** be `bun ci` or `bun install --frozen-lockfile` — plain `bun install` rewrites the lockfile and does not fail on divergence. | [Bun - Package Manager](bun-package-manager.md) |
| `BUN-PKG-03` | A PR that adds an entry to `trustedDependencies` **MUST** contain, in its body, the output of `bun pm untrusted` that shows the authorized command — without that artifact, the PR is rejected. | [Bun - Package Manager](bun-package-manager.md) |
| `BUN-PKG-04` | Declaring `trustedDependencies` **MUST** re-include the packages from the default list that are still needed — the declared list **replaces** the default one. | [Bun - Package Manager](bun-package-manager.md) |
| `BUN-PKG-08` | `overrides`/`resolutions` **MUST** be in the root `package.json` — Bun ignores those declared in a workspace. | [Bun - Package Manager](bun-package-manager.md) |
| `BUN-PKG-09` | Editing a package in `node_modules/` **MUST** be preceded by `bun patch <pkg>`; direct editing corrupts the global cache. | [Bun - Package Manager](bun-package-manager.md) |
| `BUN-TEST-02` | `spyOn` **MUST** have guaranteed restoration (`mock.restore()` in `afterEach` or in the preload) — without it the spy leaks into the following tests. | [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) |
| `BUN-TEST-03` | `mock.module()` is **NEVER** undone by `mock.restore()`; a module mock **MUST** be registered in `--preload` or treated as global state of the test process. | [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) |
| `BUN-TEST-05` | `--update-snapshots` (`-u`) **NEVER** appears in the CI test command, and the `__snapshots__/` directory **MUST** be versioned — a snapshot outside the repository is not an assertion. | [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) |
| `BUN-TEST-06` | A test whose assertion lives in a `catch`, a callback or a conditional branch **MUST** declare `expect.assertions(n)` or `expect.hasAssertions()`. | [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) |
| `BUN-TEST-09` | A test that depends on state left by **another file** **MUST** be fixed by moving the setup into the file itself — `test.serial` **NEVER** solves this (it sequences within the file) and no flag restores the shared global under `--isolate`; detection is `bun test --randomize`. | [Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) |
| `BUN-TEST-27` | `coverageThreshold` **MUST** be accompanied by the `text` reporter enabled in every run outside `--parallel` — with only `--coverage-reporter=lcov` the process exits `0` even below the threshold. | [Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md) |
| `BUN-TEST-28` | `coverageThreshold` **NEVER** depends on the `statements` key — it is accepted and **not** enforced; the real gate is `lines` and `functions`. | [Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md) |
| `BUN-HTTP-01` | A new server **MUST** declare its routes in `routes`, and `fetch` **NEVER** contains manual routing by `URL(req.url).pathname` — with a single named exception: the `fetch` that exists only to call `server.upgrade` (§ 5), because the doc documents the WebSocket upgrade only inside `fetch`. | `Bun - HTTP e Servidor` |
| `BUN-HTTP-04` | A streaming or SSE response **MUST** call `server.timeout(req, 0)` — the default `idleTimeout` of 10 s closes the connection mid-response, and the global set to `0` does not replace the call — and each SSE event **MUST** end in `\n\n`, because the blank line is what dispatches the event on the client. | `Bun - HTTP e Servidor` |
| `BUN-HTTP-07` | WebSocket authentication and authorization **MUST** happen before `server.upgrade` — after the `101` there is no HTTP response to refuse with. | `Bun - HTTP e Servidor` |
| `BUN-HTTP-10` | `development` is **NEVER** turned on in production in **either** of the two forms the option accepts — neither the boolean `true`, nor the object (`{ hmr, console }`, which also turns on development mode) — and the `error` handler **NEVER** includes `error.stack` in the response body. | `Bun - HTTP e Servidor` |
| `BUN-BUILD-02` | `define` values **MUST** be produced by `JSON.stringify` — the option inlines the text literally. | [Bun - Bundler and Build](bun-bundler-and-build.md) |
| `BUN-BUILD-03` | `target` **MUST** be declared explicitly in every production build — the default (`"browser"`, or `"bun"`/`"node"` by shebang/format) changes resolution silently. | [Bun - Bundler and Build](bun-bundler-and-build.md) |
| `BUN-BUILD-04` | Code that uses `Bun.*` or `bun:*` is **NEVER** bundled with `target: "node"` — there is no polyfill; the failure only appears at runtime. | [Bun - Bundler and Build](bun-bundler-and-build.md) |
| `BUN-DATA-01` | `new Database(...)` **MUST** be opened with `strict: true`, and with `safeIntegers: true` when any column may exceed 2^53 — the defaults do not throw on a missing parameter and truncate large integers silently. | `Bun - Dados e Persistência` |
| `BUN-DATA-03` | A runtime value **NEVER** enters SQL by concatenation or by a template string outside the `sql` tag — it **MUST** be a parameter (`$name`/`?` in `bun:sqlite`, `${}` inside the tagged template of `Bun.sql`). | `Bun - Dados e Persistência` |
| `BUN-DATA-07` | Inside `sql.begin`, every query **MUST** be issued through the `tx` received — the global `sql` uses another connection from the pool and stays outside the transaction. | `Bun - Dados e Persistência` |
| `BUN-DATA-09` | A connection to a remote database **MUST** declare `ssl` explicitly — the default of `Bun.sql` is `"disable"`. | `Bun - Dados e Persistência` |
| `BUN-DATA-12` | A query result that crosses the HTTP boundary **MUST** go through schema validation — the driver returns `any` typed by declaration, not by verification. | `Bun - Dados e Persistência` |
| `BUN-SYS-01` | An external command with a runtime value **MUST** use `Bun.$` interpolation; `child_process.exec` with a concatenated string **NEVER** in new code. | [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md) |
| `BUN-SYS-05` | `bun:ffi` and `cc()` **NEVER** enter a production path — the doc declares them experimental and recommends Node-API. | [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md) |
| `BUN-SYS-07` | A migration from Node **MUST** enumerate the `node:*` modules used by the code **and by the transitive dependencies** (grep in the source and in `node_modules`, `bun why` to find who brought each one) and check each one against the official matrix — 🟡 means "imports and runs the happy path", not "compatible". | [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md) |
| `BUN-SYS-11` | A service in a container **MUST** register a `SIGTERM` (and `SIGINT`) listener that drains the server — `await server.stop()` in `Bun.serve`, `server.close()` in `node:http` — and **MUST** finish by calling `process.exit()`: without the listener, `beforeExit`/`exit` are not emitted and in-flight connections are cut; with the listener and without the `process.exit()`, the signal's default exit is **suppressed** and the process only dies on the orchestrator's `SIGKILL`. | [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md) |

### Complete families in the satellites

| Family | Satellite |
| --- | --- |
| `BUN-CORE-*` | this note (§ 6) |
| `BUN-RT-*` | [Bun - Runtime and APIs](bun-runtime-and-apis.md) |
| `BUN-PKG-*` | [Bun - Package Manager](bun-package-manager.md) |
| `BUN-TEST-*` | [Bun - Tests](bun-tests.md) (the family's hub) and its six satellites |
| `BUN-HTTP-*` | `Bun - HTTP e Servidor` |
| `BUN-BUILD-*` | [Bun - Bundler and Build](bun-bundler-and-build.md) |
| `BUN-DATA-*` | `Bun - Dados e Persistência` |
| `BUN-SYS-*` | [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md) |

There are **107** rules in total (`BUN-CORE-*` 7 · `BUN-RT-*` 12 · `BUN-PKG-*` 12 · `BUN-TEST-*` 29 · `BUN-HTTP-*` 12 · `BUN-BUILD-*` 11 · `BUN-DATA-*` 12 · `BUN-SYS-*` 12); § 6.1 above selects 36. When citing in a review, use the ID — the full text is in the family's satellite.

> **`BUN-TEST-*` grew from 12 to 29 on 2026-08-20**, when the test runner gained its own structure ([Bun - Tests](bun-tests.md) + six satellites). IDs `01`–`12` keep their text and meaning: an old citation remains valid. § 6 of the tests hub says which satellite owns each ID.

---

## 7. Skill contract

How a Bun skill should consume this doc.

### What a Bun skill should load

```
ALWAYS:   Bun.md § 2 (mental model)
          Bun.md § 3 (import boundaries)
          Bun.md § 5 (decision trees)
          Bun.md § 6 + § 6.1 (normative and critical rules)

WHEN WRITING application code:
          Bun - Runtime and APIs.md

WHEN TOUCHING package.json, lockfile, CI or monorepo:
          Bun - Package Manager.md

WHEN WRITING or FIXING a test:
          Bun - Tests.md

ON DEMAND, via § 4 (API map):
          the satellite of the domain the task touches

NEVER:    all the satellites at once
          — except a Node→Bun MIGRATION, which legitimately touches 7 of the 8.
            Named path: § 2 + § 5 (the "I came from Node" tree) +
            [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md) § 5 (matrix) + the satellite
            of each surface the app uses.

          inventing a signature, flag or default. Whatever is not in the
          satellite MUST be checked on bun.com/docs before use —
          § 4 is a routing index, not an allow-list of APIs.
```

### How to cite

Review findings cite the rule's ID and the satellite, they do not paraphrase:

> `BUN-PKG-04` — `trustedDependencies` declared without re-including `sharp`, which was on the default list. Its install scripts stopped running.
> See [Bun - Package Manager](bun-package-manager.md).

### Invariants the skill must enforce

1. **Verify before asserting.** If an API is not in § 4, it was not verified in this doc. Consult bun.com/docs and update the note — do not invent a signature, flag or default.
2. **The source wins.** A divergence between this note and bun.com/docs is a bug in this note.
3. **Confirm the installed version.** Several features cited here are recent. `bun --version` before assuming a flag exists. See the [Verification notes](#sources-consulted).
4. **Portability is a decision, not a default.** Every time the skill writes `Bun.*`, it has decided that the file only runs on Bun. That needs to be intentional (`BUN-CORE-01`).
5. **Type checking is a separate step.** No delivery that "runs" is verified without `tsc --noEmit` (`BUN-CORE-02`).
6. **Install security is not convenience.** `trustedDependencies` and the linker are security decisions, reviewed as such (`BUN-PKG-03`, `BUN-PKG-04`).

### When creating a new Bun skill

Derive it from **one** satellite, not from this whole note. For tests, the source is the dedicated structure: a test-focused skill loads [Bun - Tests](bun-tests.md) § 2 + § 3 + § 6.1 and **one** of the six test satellites — the complete contract, with three ready-made cuts, is in [Bun - Tests](bun-tests.md) § 7. Record at the top of the skill which satellite is its source, so that a doc update propagates. It is the same contract as `React.js` § 7.

---

## 8. Bridges to the stack

Bun touches my frontend stack (`React.js`, `TanStack Query`, `TanStack Router`, `Tailwind CSS`, `TypeScript`) at the points below, and replaces `Node.js` as the runtime.

| Problem | Raw primitive | What to use in the stack |
| --- | --- | --- |
| Run the **server** in dev, with reload | `nodemon` + `ts-node` | `bun <file>` directly (TS/JSX without a build), `bun --hot` for the server. **`--hot` is not browser HMR** — see [Bun - Runtime and APIs](bun-runtime-and-apis.md) § 7 |
| Run the **frontend dev server** | Vite | still Vite in most cases — Bun's dev server and HMR API are declared *work in progress*. Tie-breaking criterion in [Bun - Bundler and Build](bun-bundler-and-build.md) § 10.1 |
| Serve frontend + API in the same process | two servers | `Bun.serve` with an `.html` import in `routes` and `development: true` **only in dev** (`BUN-HTTP-10`) — [Bun - Bundler and Build](bun-bundler-and-build.md) |
| Run Vite/Next/a frontend CLI | `npm run dev` | `bun run --bun vite` — forces the Bun runtime on a CLI with a `node` shebang. Not `bunx`: the package is a devDependency, and `bunx` without a pinned version in a versioned script violates `BUN-PKG-11` |
| Test a React component | Jest + jsdom + babel | `bun test` + `@happy-dom/global-registrator` in `[test] preload` — [Bun - Tests](bun-tests.md) |
| Install dependencies | `npm`/`pnpm` | `bun install`, `bun ci` in CI — [Bun - Package Manager](bun-package-manager.md) |
| Validate a payload at the boundary | manual checking | · |
| Server state on the client | `useEffect` + `fetch` | `TanStack Query` — |

**Bun as the dev runtime of a React app.** The source documents `bun init --react`, which generates a template with a React app and an API server in the same project, with `bun dev` (hot reloading), `bun start` (server + frontend in one process) and `bun run build` (static site in `dist/`). The mechanism behind it is the HTML import as a route in `Bun.serve` — the bundler runs on top of the HTML's `<script>` and `<link>` tags, transpiling TS/JSX and processing CSS. Details in [Bun - Bundler and Build](bun-bundler-and-build.md).

**Bun beside Vite, not in its place.** In an existing Vite project, Bun comes in as the package manager and as the CLI's runtime: `bun run --bun vite`. There is a verified detail that avoids a subtle configuration bug — **when Bun is invoked as `node` (via `bun --bun`, `bunx --bun` or a `node` symlink), it turns off the automatic loading of `.env`**, precisely so that tools with their own mode resolution (Vite's `loadEnv`) pick the right `.env.{mode}` instead of seeing the values preloaded by Bun as if they came from the shell. An explicit `--env-file` still applies.

**`bun test` for frontend code.** The runner brings no DOM: `document` and `window` do not exist by default. The verified recipe is `bun add -d @happy-dom/global-registrator`, a file that calls `GlobalRegistrator.register()`, and `[test] preload = ["./happydom.ts"]` in `bunfig.toml`. In TypeScript, the DOM types require `/// <reference lib="dom" />` at the top of the test file. **One extra step the official doc hides:** the `@testing-library/jest-dom` matchers (`toHaveTextContent`, `toBeInTheDocument`) are **not** registered by simply `import`ing the package — you need `expect.extend(matchers)` from `@testing-library/jest-dom/matchers`, in a preload (`BUN-TEST-12`). Two pages of the official doc diverge on this point; the guide's is the one that works. Complete recipe in [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md) § 2. What to test remains a strategy decision — and.

**The boundary with `Node.js`.** Bun presents itself as a *drop-in replacement*, and for most application code it is. The two things that do not transfer: (a) any file that uses the `Bun` global stops running on Node — that is a coupling choice, not a detail; (b) `node:*` compatibility is measured against Node.js v26 and has named gaps per module. A library published on npm that needs to run on both: use `node:*` and treat `Bun.*` as an optional optimization. An application you control: couple without guilt and record the decision. The complete matrix is in [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md).

---

### HTTP framework on top of Bun

`Bun.serve` covers routing with params, WebSocket, cookies, TLS and streaming, and does **not** cover composable middleware, typed input validation, an end-to-end typed client, CORS or mapping domain errors to statuses. That list of absences is what `Hono` and `Elysia` exist to fill — and both deliver the piece that matters most for this stack: the handler's type reaching the React component without a duplicated schema.

**The choice among the three has its own note: `Backend no runtime Bun`**, with a decision tree and the five axes that weigh. What that note decides does not belong here; what does is the warning that applies to both frameworks: neither `hc` (Hono) nor Eden Treaty (Elysia) **throws** on an error response, and a naive `queryFn` leaves the TanStack Query query in `success` with the error inside `data`.

---

## Related

- [Bun - Runtime and APIs](bun-runtime-and-apis.md) · [Bun - Package Manager](bun-package-manager.md) · [Bun - Tests](bun-tests.md) (hub of a dedicated structure, with six satellites)
- `Bun - HTTP e Servidor` · [Bun - Bundler and Build](bun-bundler-and-build.md) · `Bun - Dados e Persistência` · [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md)
- `Backend no runtime Bun` — choosing between raw `Bun.serve`, `Hono` and `Elysia`
- `Node.js` — the runtime Bun seeks to replace; the boundary is in § 8
- `TypeScript` ·
- `React.js` · `TanStack Query` · `TanStack Router` · `Tailwind CSS` · `Next.js`

## Sources consulted

Verified directly on **2026-08-15**:

- [Welcome to Bun](https://bun.com/docs) · [Bun Runtime](https://bun.com/docs/runtime) · [Bun APIs](https://bun.com/docs/runtime/bun-apis)
- [Globals](https://bun.com/docs/runtime/globals) · [Web APIs](https://bun.com/docs/runtime/web-apis) · [Node.js Compatibility](https://bun.com/docs/runtime/nodejs-compat)
- [Module Resolution](https://bun.com/docs/runtime/module-resolution) · [JSX](https://bun.com/docs/runtime/jsx) · [TypeScript](https://bun.com/docs/typescript)
- [File I/O](https://bun.com/docs/runtime/file-io) · [Environment Variables](https://bun.com/docs/runtime/environment-variables) · [Spawn](https://bun.com/docs/runtime/child-process) · [Shell](https://bun.com/docs/runtime/shell)
- [Watch Mode](https://bun.com/docs/runtime/watch-mode) · [Hashing](https://bun.com/docs/runtime/hashing) · [Utils](https://bun.com/docs/runtime/utils)
- [bun install](https://bun.com/docs/pm/cli/install) · [Lockfile](https://bun.com/docs/pm/lockfile) · [Lifecycle scripts](https://bun.com/docs/pm/lifecycle) · [Isolated installs](https://bun.com/docs/pm/isolated-installs) · [bunx](https://bun.com/docs/pm/bunx)
- [Test runner](https://bun.com/docs/test) · [Mocks](https://bun.com/docs/test/mocks) · [DOM testing](https://bun.com/docs/test/dom) · [Parallel & isolated test runs](https://bun.com/docs/test/parallel)
- [Fullstack dev server](https://bun.com/docs/bundler/fullstack) · [Build a React app with Bun](https://bun.com/docs/guides/ecosystem/react) · [Build a frontend using Vite and Bun](https://bun.com/docs/guides/ecosystem/vite)
- Version: `https://registry.npmjs.org/bun` — `dist-tags.latest = 1.3.14`, published on 2026-05-13.

**Verification notes** — points where the source contradicts what is assumed by habit:

- **The doc is ahead of the published version in at least one point.** The *Parallel & isolated test runs* page shows example output with `bun test v1.4.0`, while `latest` on npm on 2026-08-15 is **1.3.14**. Other pages show `1.3.3`. Treat `--parallel`, `--isolate`, `--shard` and `--timings` as features to confirm with `bun --version` before writing them into a CI.
- **The text lockfile `bun.lock` is the default since Bun 1.2**; the binary `bun.lockb` is the old format. The doc gives the exact migration command. Much third-party documentation still talks about `bun.lockb`.
- **`bun install` does not enable `--frozen-lockfile` automatically in CI.** The source says so explicitly and offers `bun ci` as a shortcut. It is the opposite of what `npm ci` trains you to expect.
- **`trustedDependencies` replaces the default list, it does not extend it.** Declaring a single package turns off the built-in allow-list for all the others — including `sharp` and `esbuild`.
- **The default linker depends on `configVersion` and on the presence of workspaces**: a new monorepo is born `isolated` (pnpm model), a single-package project is born `hoisted`, a project older than v1.3.2 stays `hoisted`.
- **`bun test --parallel` implies `--isolate`**: each file gets a fresh global. Without `--parallel`, the default is the opposite — all files share a single global in the same process.
- **`test.only` alone filters nothing**: you need to run `bun test --only`. A forgotten `.only` does not "make the other tests disappear" as in Jest — but it is not harmless either, because CI may pass the flag.
- **`mock.restore()` does not undo `mock.module()`.** The source is explicit. A module mock is a persistent effect of the test process.
- **Bun turns off automatic `.env` loading when invoked as `node`** (`bun --bun`, `bunx --bun`, `node` symlink), so as not to trample tools with their own `.env.{mode}` resolution such as Vite.
- **`bun run` honors the lifecycle hooks of your own `package.json`** (`preclean`/`postclean`), but does **not** run those of installed dependencies. They are two different mechanisms with the same name.
