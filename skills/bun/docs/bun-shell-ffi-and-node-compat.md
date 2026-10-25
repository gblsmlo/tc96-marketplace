---
titulo: Bun - Shell, FFI and Node Compat
Link: https://bun.com/docs/runtime/nodejs-compat
tags:
  - bun
  - nodejs
  - infraestrutura
  - agent-context
source: "Official documentation — https://bun.com/docs"
verificado-em: 2026-08-15
---
# Bun - Shell, FFI and Node Compat

> `Bun.$` (Shell — safe interpolation, `.text()`/`.json()`/`.quiet()`/`.nothrow()`, `cwd`/`env`, redirection) · `bun:ffi` (`dlopen`, `cc`) and when **not** to use it · `Worker` and parallelism · **the Node compatibility matrix**: what is complete, partial and missing · `process` behavior · deploy (`oven/bun` image, `--smol`, signals, graceful shutdown, environment variables).
>
> **Does not cover:** `Bun.*` I/O and utility APIs ([Bun - Runtime and APIs](bun-runtime-and-apis.md)) · `Bun.serve` and the HTTP server lifecycle (`Bun - HTTP e Servidor`) · `--compile` and the single binary ([Bun - Bundler and Build](bun-bundler-and-build.md)) · database drivers (`Bun - Dados e Persistência`).

Entry point: [Bun](bun.md) § 5 (decision trees) · § 6 (normative rules) · Normative base: [Bun](bun.md)

Version verified: **Bun 1.3.14** (`bun@latest` on the npm registry, 2026-08-15). Compatibility matrix measured against **Node.js v26**, as declared on the page itself.

---

## 1. Concept: Node compatibility is good enough to fool you

The sentence in the doc is a promise of support, not a description of state: *"If a package works in Node.js but doesn't work in Bun, we consider it a bug in Bun."*

**The legend, before anything else.** The official page marks each module with one of three symbols, and they are used as normative vocabulary across this whole structure — including in `BUN-SYS-07` and in the hub. This is the canonical definition:

| Symbol | What the source means | What it means for you |
| --- | --- | --- |
| 🟢 | **complete.** The module is implemented; the page often cites the percentage of Node's test suite that passes | use without ceremony — but read the named caveat, because several 🟢 have one (§ 5) |
| 🟡 | **partial.** Implemented, with the page naming what is missing | **it imports, instantiates and runs the happy path.** The failure comes in the specific condition the matrix row names. It is the dangerous state |
| 🔴 | **missing.** Not implemented | fails immediately, with the replacement indicated on the page itself |

The real state, counted by the matrix itself: of all the `node:*` modules listed, **exactly one is marked 🔴** (`node:sea`). Everything else is 🟢 or 🟡. That is excellent — and it is precisely what makes migration dangerous.

A 🔴 module fails on the first line and you find out in two minutes. A 🟡 module imports, instantiates, runs the happy path, and fails **in the specific condition you did not test**: the EC curve the signing lib uses, TLS session resumption across processes, the `AsyncLocalStorage` that does not cross a `Worker`, the `eventLoopUtilization()` that returns zero and makes the dashboard lie.

**The value of this note is not saying that Bun is compatible. It is saying exactly where compatibility ends.** § 5 is the most important section of the satellite.

---

## 2. `Bun.$`: bash reimplemented in-process, safe by default

**Concept.** The statement that changes everything is at the end of the page: *"Bun Shell **does not invoke a system shell** like `/bin/sh`. It's a re-implementation of bash that runs in the same Bun process."*

There is no `/bin/sh -c`. So there is no string being re-parsed by a shell. When assembling the arguments, Bun treats **every interpolated variable as a single literal string**. This eliminates command injection by construction:

```ts
import { $ } from "bun";

const entrada = "relatorio.pdf; rm -rf /";
await $`ls ${entrada}`; // looks for a file named "relatorio.pdf; rm -rf /"
```

Compare with the `child_process` habit: `exec("ls " + entrada)` hands the string to `/bin/sh`, and the `;` separates commands. **That is why `Bun.$` replaces `child_process.exec` with a concatenated string**, not for convenience.

**The result API:**

| Call | Returns |
| --- | --- |
| `` await $`cmd` `` | `{ stdout, stderr }` as `Buffer`; the output also goes to the terminal |
| `.quiet()` | same thing, without writing to the terminal |
| `.text()` | `string` — **already calls `.quiet()` on its own** |
| `.json()` | parsed value |
| `.lines()` | async iterator, line by line |
| `.blob()` | `Blob` |

**Error.** A non-zero exit code **throws** by default, with a `ShellError` carrying `exitCode`, `stdout` and `stderr`. `.nothrow()` turns it off per command; `$.nothrow()` / `$.throws(false)` change the process-wide default — a global change that forces you to check `exitCode` on **every** command from then on.

**Context.** `.cwd(path)` and `.env(obj)` per command; `$.cwd(...)` and `$.env(...)` change the default. Without `.env()`, commands inherit `process.env`.

```ts
import { $ } from "bun";

// directory and environment per command, without touching the process
const versao = await $`git rev-parse --short HEAD`.cwd(repo).text();

// explicit check instead of an exception
const { exitCode, stderr } = await $`bun test`.cwd(repo).nothrow().quiet();
if (exitCode !== 0) {
  throw new Error(`testes falharam:\n${stderr.toString()}`);
}

// redirection to JavaScript objects
const resposta = await fetch("https://exemplo.com/dados.csv");
const linhas = await $`wc -l < ${resposta}`.text(); // Response as stdin
```

Redirection accepts the bash operators (`<`, `>`, `>>`, `2>`, `&>`, `2>&1`, `1>&2`) and also JavaScript objects in both directions: `Buffer`/TypedArray/`ArrayBuffer`, `Bun.file(path)`, and `Response` as input. Pipe (`|`) and substitution (`$(...)`) work.

**Cross-platform builtins** (work on Windows without `cross-env`/`rimraf`): `cd`, `ls`, `rm`, `echo`, `pwd`, `bun`, `cat`, `touch`, `mkdir`, `which`, `mv`, `exit`, `true`, `false`, `yes`, `seq`, `dirname`, `basename`. `mv` is partial — cross-device support is missing.

**Where the protection ends** — the doc names two cases, and both remain your responsibility:

1. **You open a shell yourself.** `` await $`bash -c "echo ${entrada}"` `` hands control to `bash`, and Bun's guarantees stop applying inside that string.
2. **Argument injection.** Bun passes the string as a single argument — but the target program interprets its own arguments. The doc's example: `branch = "--upload-pack=echo pwned"` in `` $`git ls-remote origin ${branch}` `` is passed safely and `git` obeys the flag.

The second case is what `BUN-SYS-03` covers, and "validate against the possibility of being read as a flag" is not reviewable. The criterion that is: **a runtime argument cannot start with `-`**, or it has to come after the `--` separator, which most command-line programs understand as "from here on nothing is a flag".

```ts
// ✅ reject: the simplest guard, and the one that works for branch name, path, id
if (branch.startsWith("-")) throw new Error("nome de branch inválido");
await $`git ls-remote origin ${branch}`;

// ✅ separator: when the value may legitimately start with "-"
await $`grep -e ${padrao} -- ${arquivo}`;

// ✅ the best of all, when the format is known: allowlist by regex
if (!/^[\w./-]+$/.test(branch) || branch.startsWith("-")) throw new Error("inválido");
```

Not every program respects `--`, so rejecting a leading `-` is the default guard. It is one line, it shows up in the diff and a reviewer can point out that it is missing.

`$.escape(str)` exposes the escaping logic; `{ raw: "..." }` turns escaping off deliberately.

| ID | Rule |
| --- | --- |
| `BUN-SYS-01` | An external command with a runtime value **MUST** use `Bun.$` interpolation; `child_process.exec` with a concatenated string **NEVER** in new code. |
| `BUN-SYS-02` | A value from external input **NEVER** is interpolated inside a `sh -c` / `bash -c` launched through `Bun.$` — the escaping guarantees do not hold there. |
| `BUN-SYS-03` | A runtime argument passed to an external program **MUST** be rejected when it starts with `-`, or be preceded by the `--` separator on the command line — without one of the two guards, the value is delivered safely and the target program obeys it as a flag. |
| `BUN-SYS-04` | `$.nothrow()` / `$.throws(false)` **NEVER** is called at application global scope — use `.nothrow()` on the specific command. |

---

## 3. `bun:ffi`: experimental, and the doc says not to use it in production

**Concept.** `bun:ffi` calls native libraries with a C ABI straight from JavaScript. The warning is the first thing on the page, and it is categorical:

> "`bun:ffi` is **experimental**, with known bugs and limitations. Do not rely on it in production."

And it points to the alternative: *"The most stable way to interact with native code from Bun is to write a Node-API module."*

With the warning recorded, the shape:

```ts
import { dlopen, FFIType, suffix } from "bun:ffi";

// suffix is "dylib" | "so" | "dll" depending on the platform
const { symbols } = dlopen(`libminhalib.${suffix}`, {
  somar: { args: [FFIType.i32, FFIType.i32], returns: FFIType.i32 },
});

symbols.somar(1, 2);
```

Verified performance: about **2 to 6x faster than Node.js FFI via Node-API**, because `dlopen`, `linkSymbols`, `CFunction` and `JSCallback` are implemented inside JavaScriptCore — argument conversion and return boxing happen in the engine, and hot call sites compile to a direct native call through the DFG/FTL tiers.

`cc()` compiles and runs C at runtime, embedding TinyCC; the C compiler page also declares **experimental** support. `JSCallback` has **experimental** support for thread-safe callbacks, needed when the callback crosses threads (`threadsafe: true`).

**The decision tree is short:**

```
Do I need to call native code?
├── It is an npm package that already ships a binding → use the package (Node-API works)
├── I need this in production → write a Node-API module
└── It is a prototype, script or benchmark → bun:ffi
```

| ID | Rule |
| --- | --- |
| `BUN-SYS-05` | `bun:ffi` and `cc()` **NEVER** enter a production path — the doc declares them experimental and recommends Node-API. |

---

## 4. `Worker`: real parallelism, also marked experimental

**Concept.** `Worker` is global, runs a second JavaScript instance on another thread, shares I/O resources with the main thread, and accepts TypeScript/JSX without a build. It does not need `{ type: "module" }`.

And it also carries a warning: *"The `Worker` API is still experimental (particularly for terminating workers)."*

Verified points that change the code:

- **Messages are queued until the worker is ready** — there is no need to wait for the `"open"` event (which is a Bun extension, it does not exist in the browser) to call `postMessage`.
- **`preload`** (string or array) loads modules before the worker code; the doc cites OpenTelemetry, Sentry and DataDog as the use case.
- **`smol: true`** in the constructor reduces memory at the cost of performance (sets `JSC::HeapSize` to `Small`).
- Specifiers are resolved **relative to the project root**, like `bun ./caminho/arquivo.js`.
- Failure to resolve the script emits an `"error"` event on the `Worker` object.

```ts
const worker = new Worker("./workers/relatorio.ts", {
  preload: ["./instrumentacao.ts"], // runs before the worker code
  smol: true,
});

worker.postMessage({ pedidoId }); // queued if the worker has not come up yet
worker.onmessage = (e) => salvarRelatorio(e.data);
```

**The catch that only shows up in observability:** the compat matrix declares that **Bun does not propagate `AsyncLocalStorage` context to `MessagePort`, `BroadcastChannel` or `Worker` events.** A trace id that crosses the worker boundary disappears. Pass the context explicitly in the message.

| ID | Rule |
| --- | --- |
| `BUN-SYS-06` | Tracing context (trace id, request id) **MUST** be sent explicitly in the message to the `Worker` — `AsyncLocalStorage` does not cross the boundary. |

---

## 5. The compatibility matrix: where compatibility ends

**Concept.** The official page marks each module with 🟢, 🟡 or 🔴 (legend in § 1) and describes what is missing. Verification of 2026-08-15, against **Node.js v26**.

### How to enumerate what your app uses

`BUN-SYS-07` orders checking the matrix "for each `node:*` module used", and that instruction is worth nothing without a method to produce the list — which needs to include the **transitive dependencies**, because the `node:crypto` that is going to break is almost never yours. **There is no Bun command that enumerates the `node:*` usage of a dependency tree**; what exists is `bun why`, which answers the inverse question. The method is, then, assembled by hand, and it is three steps:

```bash
# 1. your code: explicit node:* specifiers
rg -o --no-filename 'node:[a-z_]+' src | sort -u

# 1b. the legacy names without prefix, which Node still accepts.
#     The dot in the pattern matches the quote, single or double.
rg -n -e 'from .(assert|async_hooks|buffer|child_process|cluster|crypto|dgram|dns|events|fs|http|http2|https|module|net|os|path|perf_hooks|readline|stream|timers|tls|tty|url|util|v8|vm|worker_threads|zlib).' src

# 2. the dependencies, including transitive ones — the step nobody does
rg -o --no-filename 'node:[a-z_]+' node_modules | sort -u

# 3. for each 🟡 module that shows up in step 2, find out who brought it in
bun why <pacote>
```

Two limitations to declare out loud, because a method that presents itself as complete is worse than none:

- **`rg` over `node_modules` is an approximation, in both directions.** It does not see `require(variable)`, dynamic import with an assembled string, nor what a native addon calls underneath — and, on the other side, it matches occurrences in comments, in dead code and in branches your app never executes. It serves to produce the list of **candidates**, not a proof.
- **`bun why` explains why a package is installed**, showing the dependency chain (`bun why react`, with `--top` and `--depth`, and accepting a glob like `@types/*`). It does **not** enumerate `node:*` modules. It is the tool for step 3, not step 1.

The practical result that is worth the effort: the list from step 2 crossed with the 🟡 rows of this section is a short list, and each item in it is a specific question ("does this lib sign with secp256k1?") instead of a diffuse worry.

### What is 🟢 complete

`node:assert` · `node:buffer` · `node:console` · `node:dgram` · `node:dns` · `node:events` · `node:fs` · `node:http` · `node:http2` · `node:net` · `node:os` · `node:path` · `node:punycode` (deprecated by Node itself) · `node:querystring` · `node:readline` · `node:sqlite` · `node:stream` · `node:string_decoder` · `node:timers` (+ `/promises`) · `node:trace_events` · `node:tty` · `node:url` · `node:zlib` · `node:quic`

Even among the 🟢 there are named caveats that break specific libraries:

| Module 🟢 | Verified caveat |
| --- | --- |
| `node:console` | Bun writes straight to the file descriptors. **Replacing `process.stdout.write` does not capture the output** — breaks log-capture libs in tests |
| `node:buffer` | a `Buffer` is limited to **4 GiB** |
| `node:http` | `http.Server` **does not extend** `net.Server`; `listen(handle)` and the `fd`, `ipv6Only`, `signal` options are ignored; `keepAlive` on the server is a no-op |
| `node:stream` | `isReadable`/`isWritable`/`isErrored`/`Readable.isDisturbed` only understand Node streams, not web streams |
| `node:path` | `matchesGlob()` uses `Bun.Glob` semantics, not minimatch (`*` matches dotfiles, no extglob) |
| `node:fs` | `Stats` does not have the `Temporal.Instant` getters (`atimeInstant` and the like) |

### What is 🟡 partial — and the missing part matters

| Module | What is missing, and the symptom |
| --- | --- |
| **`node:crypto`** | BoringSSL: the key types `ed448`, `x448`, `rsa-pss`, `dsa`, `dh` are missing; **EC curves beyond P-224/256/384/521 — there is no `secp256k1`**; the CCM, OCB, XTS and `chacha20-poly1305` ciphers. `argon2()` and `setEngine()` throw. → **breaks blockchain signing and Argon2 hashing** |
| **`node:async_hooks`** | `AsyncLocalStorage` and `AsyncResource` work. `createHook`, `executionAsyncId`, `triggerAsyncId`, `executionAsyncResource` are **stubs**; async ids are always `0`. Context does not propagate to `MessagePort`/`BroadcastChannel`/`Worker` → **hook-based APM instrumentation sees nothing** |
| **`node:tls`** | `pskCallback`, OCSP stapling (`requestOCSP`), the `newSession`/`resumeSession` server events and the session ticket keys (`ticketKeys` is ignored) are missing → **session resumption does not work across processes**. Because of BoringSSL, `tlsSocket.renegotiate()` always fails and `getEphemeralKeyInfo()`/`getSharedSigalgs()` return no information |
| **`node:https`** | `request`, `get`, `Agent` and `globalAgent` are implemented, including connection pooling. `https.Server` is an `http.Server` with TLS options, not a `tls.Server`. Request sockets are **not** `TLSSocket`: `encrypted`, `authorized` and `servername` work, but `getPeerCertificate()` and `getCipher()` are **missing**. `setSecureContext()`, `addContext()`, **`SNICallback`** and `handshakeTimeout` **are not supported** → breaks client-certificate authentication, and breaks multi-domain TLS by SNI callback |
| **`node:child_process`** | `serialization: "advanced"` **only works between Bun processes** — for Bun↔Node IPC use JSON. You cannot pass a child's `stdout`/`stderr` as another's `stdio` |
| **`node:cluster`** | `net` and `dgram` are shared by the primary as in Node. **`node:http`/`node:https` servers in workers bind on their own — HTTP balancing across processes only on Linux** (`SO_REUSEPORT`). The doc says "implemented, but not battle-tested" |
| **`node:perf_hooks`** | **`eventLoopUtilization()` always returns zeros**; there are no `gc`, `dns` or `resource` entries; `performance.nodeTiming` is a placeholder → **event loop lag dashboard lies** |
| **`node:v8`** | `serialize`/`deserialize` use the **JavaScriptCore wire format, not V8's** → a serialized payload does not cross between Node and Bun. No `Serializer`/`Deserializer`, `queryObjects`, `promiseHooks` |
| **`node:module`** | `module.register` is a **no-op** (the doc recommends `Bun.plugin`); `syncBuiltinESMExports`, `module._load`, `module._pathCache` too. `findSourceMap` always returns `undefined` → **instrumentation loaders/hooks via `module.register` do not run** |
| **`node:test`** | partially implemented; most `run()` options throw `ERR_NOT_IMPLEMENTED`, `test.only()` does not filter. The doc recommends **`bun:test`** ([Bun - Tests](bun-tests.md)) |
| **`node:worker_threads`** | `resourceLimits` and `trackUnmanagedFds` ignored; `execArgv` only sets `process.execArgv`; `eventLoopUtilization()` is a stub |
| **`node:util`** | `diff`, `transferableAbortSignal`, `transferableAbortController` are missing |
| **`node:vm`**, `node:wasi`, `node:inspector`, `node:repl`, `node:domain`, `node:diagnostics_channel` | partial, with caveats on the page |

### What is 🔴 missing

**Only `node:sea`** (Single Executable Applications). The doc points to `bun build --compile` instead ([Bun - Bundler and Build](bun-bundler-and-build.md)).

### `process` and globals

`process` is 🟡. Verified:

- **`process.title` is a no-op on macOS and Linux.**
- `getActiveResourcesInfo()`, `_getActiveHandles()`, `_getActiveRequests()` **always return an empty array**.
- `setSourceMapsEnabled()` is a no-op; `process.report.writeReport()` **writes nothing**.
- `process.binding` is partial: `buffer`, `config`, `constants`, `fs`, `natives`, `tty_wrap`, `util`, `uv` exist; the rest throws.

In the web globals, three details that produce a silent bug:

- **`structuredClone`**: only `ArrayBuffer` and `MessagePort` are transferable, and **a cloned `Error` loses its `cause`**.
- **`ReadableStream`, `WritableStream` and `TransformStream` cannot be transferred** via `postMessage`/`structuredClone`.
- **`Request`**: `keepalive` and `duplex` are missing; `credentials`, `integrity`, `referrer` and `referrerPolicy` are **accepted and ignored** — they do not throw.

| ID | Rule |
| --- | --- |
| `BUN-SYS-07` | A migration from Node **MUST** enumerate the `node:*` modules used by the code **and by the transitive dependencies** (grep in the source and in `node_modules`, `bun why` to find who brought each one in) and check each one against the official matrix — 🟡 means "imports and runs the happy path", not "compatible". |
| `BUN-SYS-08` | Code that depends on `secp256k1`, `argon2`, `ed448`/`x448` or the CCM/OCB/XTS/`chacha20-poly1305` ciphers **NEVER** assumes `node:crypto` on Bun — BoringSSL does not have them. |
| `BUN-SYS-09` | Observability **NEVER** relies on `createHook`, `executionAsyncId` or `eventLoopUtilization()` on Bun — they are stubs that return `0`. Use `AsyncLocalStorage`, which is implemented. |
| `BUN-SYS-10` | IPC between a Bun process and a Node process **MUST** use JSON serialization — `serialization: "advanced"` only works between Bun processes. |

---

## 6. Deploy: image, memory, signals and environment

**Official image.** `oven/bun`, with tags at `hub.docker.com/r/oven/bun/tags`. The doc's `Dockerfile` is multi-stage, and there are **four** stages — `base`, `install`, `prerelease` and `release`. All four matter: `prerelease` is the one that has the source code and the `devDependencies`, and it is from it that `release` copies the application files. Cutting `prerelease` and keeping the `COPY --from=prerelease` produces a Dockerfile that does not build.

```dockerfile
# official image; tags at https://hub.docker.com/r/oven/bun/tags
FROM oven/bun:1 AS base
WORKDIR /usr/src/app

# 1. dependencies in a separate stage: cached between builds
#    two installs, because test and build need the devDependencies
FROM base AS install
RUN mkdir -p /temp/dev
COPY package.json bun.lock /temp/dev/
# --frozen-lockfile: fails if the lockfile diverges, instead of "resolving"
RUN cd /temp/dev && bun install --frozen-lockfile

RUN mkdir -p /temp/prod
COPY package.json bun.lock /temp/prod/
# --production: no devDependencies in what goes to the final image
RUN cd /temp/prod && bun install --frozen-lockfile --production

# 2. stage with the full source: this is where test and build run
FROM base AS prerelease
COPY --from=install /temp/dev/node_modules node_modules
COPY . .
ENV NODE_ENV=production
RUN bun test
RUN bun run build

# 3. final image: production dependencies + what prerelease produced
FROM base AS release
COPY --from=install /temp/prod/node_modules node_modules
COPY --from=prerelease /usr/src/app/index.ts .
COPY --from=prerelease /usr/src/app/package.json .

# 4. the non-root user already exists in the image
USER bun
EXPOSE 3000/tcp
# --no-env-file: configuration comes from the orchestrator, never from a .env in the image
ENTRYPOINT [ "bun", "run", "--no-env-file", "index.ts" ]
```

The four decisions: **`--frozen-lockfile`** (reproducible build, and a noisy failure when the lockfile is out of date — see [Bun - Package Manager](bun-package-manager.md)), **`--production`** in the copy that goes to the final image, **`USER bun`** (the image already ships the user) and **`--no-env-file`** in the `ENTRYPOINT`, which is the third clause of `BUN-SYS-12` and the one most often forgotten: without it, a `.env` that escaped the `.dockerignore` is loaded silently and overrides what the orchestrator injected. The form `bun run --no-env-file <file>` is the documented one.

Pair it with a `.dockerignore` — the doc lists `.env` among the entries, alongside `node_modules`, `.git`, `Dockerfile*` and `.vscode`. For local composition. If the alternative is to distribute a binary instead of an image with `node_modules`, the path is `bun build --compile` in [Bun - Bundler and Build](bun-bundler-and-build.md) § 8.

**`--smol`.** The verified description is narrower than the name suggests: `--smol` makes the garbage collector **run more often**, which can slow execution down. Bun already adjusts the heap size according to the available memory (respecting cgroups and other limits) **with and without the flag** — so `--smol` is useful mainly when you want the heap to **grow more slowly**, not as a "container mode". In a `Worker`, the equivalent is `smol: true`.

**Signals and shutdown.** `process.on("SIGTERM" | "SIGINT", …)` works. The point that decides whether the shutdown is clean is in the signals doc, and it goes against habit:

> Neither `"beforeExit"` nor `"exit"` is emitted when the process is killed by a signal for which **there is no listener**. To run cleanup on a signal, register the listener for that signal and call `process.exit()` from it.

That is: without a `SIGTERM` listener, the container receives the orchestrator's signal and dies **without** going through `beforeExit`. In-flight connections are cut.

**And the inverse, which is the forgotten half:** registering the listener **suppresses the signal's default action**. The default for `SIGTERM` is to terminate the process; by registering a handler, you take on that responsibility. A listener that does the cleanup and does **not** call `process.exit()` leaves the process alive — the orchestrator waits out the whole `terminationGracePeriod` and sends `SIGKILL`. The symptom is a container that takes exactly 30 seconds to die on every deploy, and nobody connects that to a missing line. **`process.exit()` is not cosmetic cleanup; it is what makes the process exit.** This is the reason `BUN-SYS-11` names both things.

```ts
const server = Bun.serve({ /* … */ });

async function desligar(sinal: string) {
  console.log({ msg: "shutdown iniciado", sinal });

  // stops accepting; waits for in-flight requests to finish
  await server.stop();
  await sql.close({ timeout: 5 });

  process.exit(0); // without this, the listener blocks the signal's default exit
}

// without these listeners, beforeExit/exit do not run when the signal arrives
process.on("SIGTERM", () => desligar("SIGTERM")); // orchestrator
process.on("SIGINT", () => desligar("SIGINT"));   // Ctrl+C
```

`await server.stop()` is the correct pair: it closes idle keep-alive connections, waits for in-flight requests and resolves when every connection has closed (`Bun - HTTP e Servidor` § 6).

**If the server is not `Bun.serve`.** `server.stop()` is a `Bun.serve` API, and it is worth separating what in the rule belongs to it from what does not:

| Part of `BUN-SYS-11` | Depends on `Bun.serve`? |
| --- | --- |
| Registering a `SIGTERM`/`SIGINT` listener | **no** — it is `process`, it holds for any server running under Bun |
| Calling `process.exit()` at the end of the handler | **no** — it is the suppressed default action, the same thing in any app |
| `await server.stop()` as the way to drain | **yes** — it is the `Bun.serve` instance of the "stop accepting and wait for what is in flight" step |

In a `node:http` app (Express, Fastify and whatever else runs on top of it), the middle step is `server.close()`, which in Node semantics stops accepting new connections and calls the callback when the existing ones finish. The matrix marks `node:http` as 🟢 and does **not** list `close()` among the gaps — but it does list that `keepAlive` and `keepAliveInitialDelay` **on the server are no-ops**, and idle keep-alive is precisely what usually makes a `close()` hang in Node. **Not verified in this session:** the behavior of `server.closeIdleConnections()` and `server.closeAllConnections()` under Bun — the matrix does not mention them in either direction. If your shutdown depends on them, measure before trusting.

```ts
// equivalent in node:http — the structure is the same, the middle changes
import { createServer } from "node:http";
const server = createServer(app);

function desligar(sinal: string) {
  console.log({ msg: "shutdown iniciado", sinal });
  server.close(async () => {          // stops accepting; waits for in-flight ones
    await sql.close({ timeout: 5 });
    process.exit(0);                  // still mandatory, for the same reason
  });
}

process.on("SIGTERM", () => desligar("SIGTERM"));
process.on("SIGINT", () => desligar("SIGINT"));
```

What to do with a `node:http` server that already exists — keep, wrap or migrate to `Bun.serve` — is a decision, not an API, and it lives in `Backend no runtime Bun`. `Bun - HTTP e Servidor` § 7.2 declares the same limit on the HTTP side.

**Environment variables.** Bun reads `.env` automatically, in **ascending** order of precedence: `.env` → `.env.production` / `.env.development` / `.env.test` (according to `NODE_ENV`) → `.env.local`. `--env-file=...` (repeatable) replaces the list; **`--no-env-file` turns off automatic loading**, and the doc points to production and CI/CD as the use case — the container should receive variables from the orchestrator, not from a file that leaked into the image.

| ID | Rule |
| --- | --- |
| `BUN-SYS-11` | A containerized service **MUST** register a `SIGTERM` (and `SIGINT`) listener that drains the server — `await server.stop()` on `Bun.serve`, `server.close()` on `node:http` — and **MUST** finish by calling `process.exit()`: without the listener, `beforeExit`/`exit` are not emitted and in-flight connections are cut; with the listener and without the `process.exit()`, the signal's default exit is **suppressed** and the process only dies on the orchestrator's `SIGKILL`. |
| `BUN-SYS-12` | A production image **MUST** install with `bun install --frozen-lockfile --production`, **MUST** run as `USER bun` and **MUST** receive configuration from the orchestrator's environment, with `--no-env-file` in the `ENTRYPOINT` — a `.env` file **NEVER** goes into the image. |

---

## Antipatterns

| Antipattern | Why it fails | What to do |
| --- | --- | --- |
| `child_process.exec("ls " + entrada)` | `/bin/sh` re-parses the string; `;` separates commands | `` $`ls ${entrada}` `` — `BUN-SYS-01` |
| `` $`bash -c "echo ${entrada}"` `` | you opened a shell explicitly; Bun's escaping does not hold in there | pass the value as an argument, without a nested shell — `BUN-SYS-02` |
| `` $`git ls-remote origin ${branch}` `` with a user-supplied `branch` | `--upload-pack=...` is passed safely and `git` obeys | reject a value starting with `-`, or use `--` — `BUN-SYS-03` |
| Container that only dies on `SIGKILL`, 30 s after every deploy | there is a `SIGTERM` listener, but it does not call `process.exit()`; the listener suppressed the signal's default exit | `process.exit()` at the end of the handler — `BUN-SYS-11` |
| Shell-form `CMD bun index.ts` (no JSON array) | `/bin/sh -c` is PID 1; Docker's reference says the executable does not receive Unix signals in this form, so the `SIGTERM` listener never runs and the process dies on `SIGKILL` | exec form, `ENTRYPOINT [ "bun", "run", "--no-env-file", "index.ts" ]` — the signal half of `BUN-SYS-11` |
| `ENTRYPOINT [ "bun", "run", "index.ts" ]` without `--no-env-file` | a `.env` that escaped the `.dockerignore` overrides what the orchestrator injected, silently | `bun run --no-env-file index.ts` — `BUN-SYS-12` |
| Copying the doc's Dockerfile without the `prerelease` stage | `COPY --from=prerelease` references a nonexistent stage; the build fails | keep the four stages — § 6 |
| "I checked the `node:*` that I import" | the `node:crypto` that breaks is almost always in a transitive dependency | enumerate `node_modules` too — `BUN-SYS-07` |
| `$.nothrow()` at application boot | every command from then on starts failing silently | targeted `.nothrow()` — `BUN-SYS-04` |
| `bun:ffi` for a production dependency | declared experimental, with known bugs, by the doc itself | Node-API module — `BUN-SYS-05` |
| Assuming `secp256k1` in `node:crypto` | BoringSSL does not implement the curve; it only fails when the signature is called | JS/WASM library, or verify first — `BUN-SYS-08` |
| Health dashboard reading `eventLoopUtilization()` | always returns zeros on Bun; the chart stays flat and nobody notices | your own metric — `BUN-SYS-09` |
| APM based on `createHook`/`executionAsyncId` | stubs; async ids always `0` | `AsyncLocalStorage`, which is implemented — `BUN-SYS-09` |
| `AsyncLocalStorage` expected to cross a `Worker` | context does not propagate through `MessagePort`/`Worker`; the trace id disappears | send it in the message — `BUN-SYS-06` |
| `serialization: "advanced"` in IPC with a Node process | only works between Bun processes; the message does not arrive | JSON — `BUN-SYS-10` |
| Replacing `process.stdout.write` to capture log output in a test | Bun writes straight to the file descriptor; nothing is captured | use the capture mechanism of `bun:test` |
| Container without a `SIGTERM` listener | `beforeExit`/`exit` are not emitted; in-flight connections die midway | listener + `server.stop()` + `process.exit()` — `BUN-SYS-11` |
| `.env` copied into the Docker image | secret versioned in the image layer, readable by whoever pulls it | orchestrator variables + `--no-env-file` — `BUN-SYS-12` |
| `--smol` expecting to reduce memory usage in a container | the flag increases GC frequency; Bun already sizes the heap per cgroup with and without it | adjust the container limit; use `--smol` only to contain heap growth |
| `node:cluster` to balance HTTP on macOS | HTTP servers in workers bind on their own; only Linux balances (`SO_REUSEPORT`) | `reusePort` on Linux — `Bun - HTTP e Servidor` |

---

## Review checklist

- [ ] No `child_process.exec` with a concatenated string? → `BUN-SYS-01`
- [ ] No interpolation inside `bash -c` / `sh -c`? → `BUN-SYS-02`
- [ ] Runtime arguments are rejected when they start with `-`, or come after `--`? → `BUN-SYS-03`
- [ ] No global `$.nothrow()`? → `BUN-SYS-04`
- [ ] No `bun:ffi` / `cc()` in a production path? → `BUN-SYS-05`
- [ ] Trace id sent explicitly to the `Worker`? → `BUN-SYS-06`
- [ ] The `node:*` list includes `node_modules`, not just `src`, and each one was checked against the matrix? → `BUN-SYS-07`
- [ ] No algorithm missing from BoringSSL in use? → `BUN-SYS-08`
- [ ] Observability without `createHook` / `eventLoopUtilization()`? → `BUN-SYS-09`
- [ ] Bun↔Node IPC in JSON? → `BUN-SYS-10`
- [ ] `SIGTERM` listener that drains (`server.stop()` / `server.close()`) **and** calls `process.exit()`? → `BUN-SYS-11`
- [ ] `--frozen-lockfile --production`, `USER bun`, `--no-env-file` in the `ENTRYPOINT` and no `.env` in the image? → `BUN-SYS-12`
- [ ] The Dockerfile has the four stages, and every `COPY --from=` points to one that exists? → § 6

---

## Related

- [Bun](bun.md) — hub
- `Bun - HTTP e Servidor` · [Bun - Runtime and APIs](bun-runtime-and-apis.md) · [Bun - Bundler and Build](bun-bundler-and-build.md) · `Bun - Dados e Persistência` · [Bun - Package Manager](bun-package-manager.md) · [Bun - Tests](bun-tests.md)
- `Backend no runtime Bun` — what to do with a `node:http` server that already exists, and the `Bun.serve` × `Hono` × `Elysia` decision
- `Node.js`

## Sources consulted

Verified on **2026-08-15**:

- [Node.js Compatibility](https://bun.com/docs/runtime/nodejs-compat) — module-by-module matrix, globals, `process`
- [Shell](https://bun.com/docs/runtime/shell) — API, redirection, builtins, security section
- [FFI](https://bun.com/docs/runtime/ffi) · [C Compiler](https://bun.com/docs/runtime/c-compiler) · [Node-API](https://bun.com/docs/runtime/node-api)
- [Workers](https://bun.com/docs/runtime/workers) · [Bun Runtime](https://bun.com/docs/runtime) (`--smol`)
- [Environment Variables](https://bun.com/docs/runtime/environment-variables) (`--no-env-file`) · [Containerize with Docker](https://bun.com/docs/guides/ecosystem/docker) — four-stage Dockerfile and `.dockerignore` · [Listen to OS signals](https://bun.com/docs/guides/process/os-signals)
- [`bun why`](https://bun.com/docs/pm/cli/why) — what it answers, and what it does not · [Express and Bun](https://bun.com/docs/guides/ecosystem/express)
- Version: `https://registry.npmjs.org/bun/latest` → **1.3.14**

**Verification notes** — points where the source contradicts what is assumed by habit:

- **Only `node:sea` is marked 🔴 in the entire matrix.** Everything else is 🟢 or 🟡 — which makes the migration risk one of *partial behavior*, not of a missing module.
- **The matrix is measured against Node.js v26**, declared at the top of the page.
- **`node:crypto` does not have `secp256k1`** nor the other curves outside P-224/256/384/521, because Bun uses BoringSSL. `argon2()` throws.
- **`eventLoopUtilization()` always returns zeros**, and `createHook`/`executionAsyncId` are stubs with id `0` — instrumentation based on them observes nothing.
- **`AsyncLocalStorage` does not propagate to `MessagePort`, `BroadcastChannel` or `Worker` events.**
- **`node:v8` `serialize`/`deserialize` use the JavaScriptCore format, not V8's** — the payload is not interchangeable with Node.
- **Replacing `process.stdout.write` does not capture `console` output**: Bun writes straight to the file descriptor.
- **`process.title` is a no-op on macOS and Linux**, and `process.report.writeReport()` writes nothing.
- **TLS session resumption does not work across processes** (no `newSession`/`resumeSession`, `ticketKeys` ignored).
- **`module.register` is a no-op** — the doc recommends `Bun.plugin` instead.
- **`Request` accepts and ignores** `credentials`, `integrity`, `referrer` and `referrerPolicy` instead of throwing.
- **An `Error` passed through `structuredClone` loses its `cause`**; web streams are not transferable.
- **`--smol` is not a "container mode"**: it increases GC frequency. Bun already sizes the heap per cgroup with and without the flag.
- **Without an explicit listener for a signal, `beforeExit` and `exit` are not emitted** when the process is killed by it. And the inverse is equally counterintuitive: **registering the listener suppresses the signal's default action**, so a handler without `process.exit()` leaves the process alive until `SIGKILL`. Both halves are in `BUN-SYS-11`.
- **The official Dockerfile has four stages**, not three: `base`, `install`, `prerelease` and `release`. `install` runs **two** installs (with and without `--production`), and `prerelease` is the one that carries the source and runs `bun test` / `bun run build`.
- **The matrix names `SNICallback` under `node:https`, not under `node:tls`.** The full `node:https` row is 🟡 and says that `request`, `get`, `Agent` and `globalAgent` are implemented with pooling, that `https.Server` is an `http.Server` with TLS options, that request sockets are not `TLSSocket` (`encrypted`/`authorized`/`servername` work; `getPeerCertificate()`/`getCipher()` are missing) and that `setSecureContext()`, `addContext()`, `SNICallback` and `handshakeTimeout` are not supported.
- **`bun why` does not enumerate `node:*` modules.** It explains why a *package* is installed, showing the dependency chain. There is no Bun command that produces the `node:*` list of a dependency tree — `BUN-SYS-07` depends on grep.
- **Bun's `llms-full.txt` is out of date relative to the live compatibility page.** In the consolidated file, `node:crypto` appears as *"Missing `secureHeapUsed` `setEngine` `setFips`"* and `node:https` as 🟢; the live page carries the full BoringSSL text and marks `node:https` as 🟡. **The live page wins** — it is the one this satellite followed.
- **`bun:ffi`, `cc()`, `Worker` and the thread-safe callbacks of `JSCallback` are all marked experimental** on their respective pages.
- **`node:cluster` balances HTTP across processes only on Linux**; on other systems each worker binds its own socket.
