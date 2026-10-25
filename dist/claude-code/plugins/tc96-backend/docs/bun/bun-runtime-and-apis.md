---
titulo: Bun - Runtime and APIs
Link: https://bun.com/docs/runtime
tags:
  - bun
  - runtime
  - agent-context
source: "Official documentation — https://bun.com/docs"
verificado-em: 2026-08-15
---

# Bun - Runtime and APIs

> Direct execution of TS/JSX · module resolution, `paths` and the JSX transform · ESM/CJS interop · `Bun.file` and `Bun.write` × `node:fs` · `.env` loading and precedence, and the caveat about Vite's `import.meta.env` · `Bun.spawn`/`spawnSync` · `Bun.password` and hashing · `--watch` × `--hot` · `bunfig.toml` and `--preload` · `using` and `Symbol.dispose` · global utilities that show up in real code.
>
> **Does not cover:** `Bun.serve` and HTTP (`Bun - HTTP e Servidor`) · `Bun.build`, bundler and browser HMR ([Bun - Bundler and Build](bun-bundler-and-build.md)) · `Bun.$` and the Node compatibility matrix ([Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md)) · `bun install` and lockfile ([Bun - Package Manager](bun-package-manager.md)) · `bun test` ([Bun - Tests](bun-tests.md)).

Entry: [Bun](bun.md) · Normative base: [Bun](bun.md) § 6

---

## 1. Concept: the runtime is not "faster Node" — it changes what needs a build and what needs an import

Two structural changes, and almost everything that distinguishes code written for Bun follows from them.

**The first: there is no build step to execute.** `bun index.tsx` runs. Bun transpiles each file in flight with the native transpiler before executing it, which is why `.ts`, `.tsx`, `.jsx` and `.mts` are legitimate entrypoints. What disappears from the project: `ts-node`, `tsx`, `swc-node`, the development `outDir` and the distinction between "source code" and "executable code". What does **not** disappear: type checking. Bun reads `tsconfig.json` to decide the JSX transform and resolve `paths` — it does not validate a single type. A Bun project without `tsc --noEmit` in CI has no type checking anywhere.

**The second: the native APIs are globals.** `Bun.file`, `Bun.write`, `Bun.spawn`, `Bun.password` live on `globalThis` with no import. That removes the import line and adds a coupling: the file now requires the `bun` process. It is not a matter of style — it is the difference between a module that runs on any runtime and one that does not. A library published on npm uses `node:*`; an application you control may couple, as long as the decision is deliberate.

The rest of this note is the consequence of those two choices: where Bun's API is better than Node's, where it does not cover the case, and where the difference produces a bug.

---

## 2. Execution, module resolution and ESM/CJS interop

### Running

`bun run <file>` and the short form `bun <file>` are identical. For `package.json` scripts, `bun run <script>`.

```bash
bun index.tsx              # runs TS + JSX, no build
bun run dev                # package.json script
bun run --bun vite         # forces the Bun runtime on a CLI with a node shebang
echo "console.log(1)" | bun run -   # reads from stdin, treated as TypeScript+JSX
```

Two command-line traps, both verified in the source:

- **Bun flags come right after `bun`.** `bun --watch run dev` works; `bun run dev --watch` passes `--watch` to the script.
- **A built-in command beats a script of the same name.** `bun <script>` only works if `<script>` does not collide with a `bun` command. In automation, always use the explicit form `bun run <script>`.

The resolution order of `bun run <x>` is: **`package.json` script → source file → project dependency binary → system command** (the last one only with an explicit `bun run`). Absolute paths and paths starting with `./` are always treated as a file.

### Resolving imports

Bun implements the Node.js resolution algorithm, with optional extensions. For `import { x } from "./hello"` in a local ESM import, the order tried is `.tsx`, `.jsx`, `.mts`, `.ts`, `.mjs`, `.js`, `.cts`, `.cjs`, `.json`, and then the same as `hello/index.*`. The order changes by context: `require()` tries the CommonJS extensions before the ESM ones, and imports inside `node_modules` try JavaScript before TypeScript.

One TypeScript compatibility rule is worth knowing because it looks like a bug: **`from "./x.js"` also resolves `./x.ts`**. It is the TypeScript compiler's *file extension substitution*, which lets source files refer to each other by the compiled path. Outside `node_modules`, `.mjs` also matches `.mts`. `.cjs` is **not** rewritten to `.cts`.

Path remapping comes from `compilerOptions.paths` in `tsconfig.json` (or `jsconfig.json`), and from `"imports"` in `package.json` with the `#` prefix. The two mechanisms work together. **`resolve.alias` from `vite.config.ts` is not read by Bun** — a project that declared the alias only there breaks as soon as it runs outside Vite (for example in `bun test`). The alias needs to exist in `compilerOptions.paths`.

### JSX: the transform comes from `tsconfig.json`, and `react-jsx` is the expected value

Bun transpiles JSX without a plugin, and reads the configuration from the same `tsconfig.json`/`jsconfig.json` that already provides `paths`. Four options, verified in the source:

| Option | Applies when | Effect |
| --- | --- | --- |
| `jsx` | always | chooses the transform (table below) |
| `jsxFactory` | only with `jsx: "react"` | name of the element function; default `"React.createElement"` (Preact: `"h"`) |
| `jsxFragmentFactory` | only with `jsx: "react"` | name of the `<>` fragment; default `"React.Fragment"` |
| `jsxImportSource` | only with `"react-jsx"`/`"react-jsxdev"` | where to import the runtime from; default `"react"` (Bun appends `/jsx-runtime` or `/jsx-dev-runtime`) |

| Value of `jsx` | What `<Box width={5}>Olá</Box>` transpiles to |
| --- | --- |
| `"react"` | `React.createElement(Box, { width: 5 }, "Olá")` — requires `React` in scope |
| `"react-jsx"` | `import { jsx } from "react/jsx-runtime"` — does **not** require importing `React` |
| `"react-jsxdev"` | `import { jsxDEV } from "react/jsx-dev-runtime"`, with extra debug arguments |
| `"preserve"` | **not supported** — the source literally says `"preserve"` is not currently supported by Bun |

The point that unblocks a React project coming from Vite: **`"jsx": "react-jsx"` — the value the Vite + React templates already ship — is exactly what Bun expects.** There is no configuration step; it is the same value the `tsconfig.json` recommended by Bun's own docs uses. Whoever had JSX working in Vite has JSX working in `bun test` without touching anything, as long as the `tsconfig.json` is the one that declares the transform. A project that declared `"jsx": "preserve"` (delegating the transform to the bundler) is the case that does **not** run.

The same four keys can be declared in `bunfig.toml` (§ 9), and there are per-file pragmas: `// @jsx h`, `// @jsxFrag MyFragment`, `// @jsxImportSource preact`.

### ESM and CJS in the same file

```ts
import { criarPedido } from "./pedidos.ts";
const { formatarMoeda } = require("./formatacao.cjs"); // in the same file, no ceremony
```

`require()` of an ESM module returns the *module namespace*; `require()` of a CJS module returns `module.exports`. The **only** break: `require()` of a module with **top-level `await`** fails, because `require` is synchronous by definition. Use a static `import` or a dynamic `import()`.

### `import.meta`

```ts
import.meta.dir;       // "/app/src"                — equivalent to __dirname
import.meta.path;      // "/app/src/pedidos.ts"     — equivalent to __filename
import.meta.file;      // "pedidos.ts"
import.meta.url;       // "file:///app/src/pedidos.ts"
import.meta.main;      // true if this file was the entrypoint of `bun run`
import.meta.env;       // alias of process.env
await import.meta.resolve("zod"); // URL of the resolved module
```

`import.meta.dirname` and `import.meta.filename` exist as aliases, for Node compatibility.

### Auto-install: the behavior that surprises in a container

If Bun **does not find `node_modules`** in the working directory or above it, it abandons Node-style resolution and starts **installing each imported package on the fly**, into the global cache. The version comes from `bun.lock`, otherwise from a `package.json` higher up the tree, otherwise from `latest`. For a loose script this is a real convenience; in a production image where `node_modules` was not copied, it is a silent install from the network at execution time — with `latest`.

Turn it off with `--no-install`, or make sure `node_modules` exists.

| ID | Rule |
| --- | --- |
| `BUN-RT-12` | Production execution **MUST** have `node_modules` present or run with `--no-install` — without that, auto-install resolves dependencies from the network at runtime. |

## 3. Files: `Bun.file`, `Bun.write` and where `node:fs` is still mandatory

The split is clean and the docs themselves declare it: **`Bun.file` and `Bun.write` deal with a file's content; everything about the file system stays in `node:fs`.**

> "For operations they don't cover, such as `mkdir` or `readdir`, use Bun's nearly complete implementation of the `node:fs` module."

### Reading

`Bun.file(path)` returns a `BunFile`, which is **lazy**: creating the reference reads nothing from disk. The interface is that of a `Blob`.

```ts
const contrato = Bun.file("contratos/2026-08.json");

contrato.size;              // bytes — 0 for a nonexistent file too
contrato.type;              // MIME type; default "text/plain;charset=utf-8"

await contrato.json();      // content as an object
await contrato.text();      // as a string
await contrato.bytes();     // Uint8Array
contrato.stream();          // ReadableStream, without loading everything into memory

await contrato.exists();    // ← the correct existence check
```

The existence check is where generated code gets it wrong. The `size` of a nonexistent file is `0`, and `type` comes back with the default — neither distinguishes "empty" from "does not exist". Only `await file.exists()` answers.

`Bun.stdin`, `Bun.stdout` and `Bun.stderr` are `BunFile` instances, which makes `await Bun.write(Bun.stdout, Bun.file(p))` a `cat`.

### Writing

`Bun.write(destination, data)` accepts a destination of `string | URL | BunFile | number` and data of `string | Blob | BunFile | ArrayBuffer | TypedArray | Response`, choosing the fastest syscall for each combination.

```ts
await Bun.write("saida.txt", "conteúdo");                    // string
await Bun.write(Bun.file("copia.pdf"), Bun.file("orig.pdf")); // file copy
await Bun.write("index.html", await fetch("https://exemplo.com")); // response body
```

That an HTTP response is a valid argument is the point: there is no `pipeline`, no `createWriteStream`, no manual conversion.

### Writing incrementally

```ts
const relatorio = Bun.file("relatorio.ndjson");
const writer = relatorio.writer({ highWaterMark: 1024 * 1024 });

for (const pedido of pedidos) {
  writer.write(JSON.stringify(pedido) + "\n"); // buffers
}

await writer.flush();  // writes the buffer; returns the number of bytes
await writer.end();    // closes
```

The operational detail: **the `bun` process does not exit while the `FileSink` is open.** Whoever forgets `.end()` produces a script that "hangs at the end". `writer.unref()` removes that tie, and `writer.ref()` restores it.

### The selection criterion

| Operation | Use | Why |
| --- | --- | --- |
| Read a whole file | `Bun.file().text()/.json()/.bytes()` | asynchronous, no `readFile` + manual parse |
| Read large / streaming | `Bun.file().stream()` | standard `ReadableStream`, integrates with `Response` |
| Write a ready payload | `Bun.write()` | picks the syscall; accepts `Response` and `BunFile` |
| Write in a loop | `file.writer()` (`FileSink`) | buffer with a high water mark |
| Append | `node:fs` | `Bun.write` overwrites |
| `mkdir`, `readdir`, `rm`, `stat`, `chmod`, `watch` | `node:fs` / `node:fs/promises` | there is no `Bun.*` equivalent |
| API identical to Node's (shared lib) | `node:fs` | portability |

**On synchronous:** `node:fs` exposes `readFileSync` and friends, and they work in Bun. In a short-lived CLI, fine. Inside a `Bun.serve` handler, each synchronous call blocks the event loop of the whole process — and since Bun.serve serves many connections on the same loop, the cost is not local.

| ID | Rule |
| --- | --- |
| `BUN-RT-01` | A **directory** operation (`mkdir`, `readdir`, `rm`, `stat`) **MUST** use `node:fs` — `Bun.file`/`Bun.write` only deal with file content. |
| `BUN-RT-02` | `Bun.file(path)` is **NEVER** treated as a read — the reference is lazy; nothing is read until `.text()`/`.json()`/`.bytes()`/`.stream()`. |
| `BUN-RT-03` | File existence **MUST** be checked with `await file.exists()` — `size === 0` is also the value of a nonexistent file. |
| `BUN-RT-04` | A `FileSink` **MUST** be closed with `.end()` (or untied with `.unref()`) — without that the process does not exit. |

---

## 4. Environment: `.env`, precedence and why `Bun.env` is no different from `process.env`

Bun reads `.env` files automatically. `dotenv` and `dotenv-expand` are unnecessary — the source says so literally.

**The order, verified in the source, is of increasing precedence:**

1. `.env`
2. `.env.production` · `.env.development` · `.env.test` — according to `NODE_ENV`
3. `.env.local`

That is: `.env.local` beats `.env.production`, which beats `.env`. It is the inverse of what a top-down reading suggests, and it is the origin of "why did my production value not apply".

Explicit controls:

```bash
bun --env-file=.env.ci src/index.ts      # replaces which files are read
bun --env-file=.env.a --env-file=.env.b run build   # multiple
bun run --no-env-file index.ts            # turns off automatic loading
```

```toml
# bunfig.toml — turns it off per project
env = false
```

Files passed with `--env-file` are still read even with automatic loading turned off.

**Expansion is the default.** `BAR=hello$FOO` resolves `$FOO`. For a literal `$` — the real case is a generated password — escape with a backslash:

```ini
DB_PASSWORD=s3nh4\$com\$cifrao
DB_URL=postgres://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME  # useful expansion
```

**Reading.** `process.env`, `Bun.env` and `import.meta.env` are **the same object** — the source describes the last two as aliases. Inside Bun, choosing between them is style. In TypeScript, every property is `string | undefined`; to declare one as required, use interface merging:

```ts
declare module "bun" {
  interface Env {
    DATABASE_URL: string;
  }
}
```

That changes the **type**, not reality: the variable can still be absent at runtime. Validation at startup is still necessary — that is what argues, and the natural mechanism is a schema.

### The caveat that "it is the same object" hides: `import.meta.env` in Vite is something else

"They are aliases, choosing is style" holds **inside Bun**. In a project that also runs under Vite — the case of the React app that uses `import.meta.env.VITE_API_URL` in its components — the two `import.meta.env` are different objects, and the difference shows up exactly when the same component starts running in `bun test`:

| | Bun | Vite |
| --- | --- | --- |
| What it is | alias of `process.env`, read at runtime | constants **statically replaced** at build (and globals in dev) |
| Name filter | none — every environment variable appears | only those with the `VITE_` prefix reach client code (`envPrefix` adjusts) |
| Which `.env` is read | `.env` < `.env.{NODE_ENV}` < `.env.local` | by **mode**: `.env` < `.env.local` < `.env.[mode]` < `.env.[mode].local` |
| `MODE`, `DEV`, `PROD`, `BASE_URL` | **do not exist** — `process.env` has no such keys | injected by Vite |

The practical consequences, in the order they bite:

1. `import.meta.env.VITE_API_URL` **works** under `bun test`, as long as the variable is in the environment or in a `.env` that Bun loads — because Bun does not filter by prefix. The name does not change.
2. `import.meta.env.MODE` / `.DEV` / `.PROD` / `.BASE_URL` become `undefined` under Bun. A component that branches on `import.meta.env.DEV` falls into the production branch inside the test, with no error.
3. The file read changes: `bun test` runs with `NODE_ENV=test` (see [Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) § 6), so the mode layer Bun applies is `.env.test` — not the `.env.development` that `vite dev` would load.
4. A variable **without** the `VITE_` prefix is invisible in the browser and visible under `bun test`. A test can pass reading a value the app never sees in production.

If the component needs configuration, receiving it by prop or through an injectable config module is what removes the whole divergence. See [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md) § 4.

And the boundary the mechanism does not solve: **`.env` is a development convenience, not secret management**..

| ID | Rule |
| --- | --- |
| `BUN-RT-05` | A production secret **NEVER** comes from a `.env` file loaded by the runtime. |
| `BUN-RT-06` | An environment variable **MUST** be validated at startup; the type declared through interface merging is **NEVER** treated as a guarantee of presence. |
| `BUN-RT-07` | A literal `$` in a `.env` value **MUST** be escaped with `\` — Bun expands variables by default. |

---

## 5. Processes: `Bun.spawn` × `Bun.spawnSync`

The rule of thumb is in the source itself: *"the asynchronous `Bun.spawn` API is better for HTTP servers and apps, and `Bun.spawnSync` is better for building command-line tools."*

```ts
const proc = Bun.spawn(["git", "log", "--oneline", "-n", "20"], {
  cwd: "/srv/repo",
  env: { ...process.env, GIT_PAGER: "cat" },
  timeout: 10_000,         // ms; kills the process when it runs out
  killSignal: "SIGKILL",   // default is SIGTERM
  onExit(_proc, exitCode, signalCode, error) {
    // …
  },
});

const saida = await proc.stdout.text();  // stdout is a ReadableStream by default
await proc.exited;                       // Promise that resolves on exit
proc.exitCode;                           // null | number
```

Defaults that matter: `stdin` is `null` (no input), `stdout` is `"pipe"`, `stderr` is `"inherit"`. Whoever wants to capture `stderr` needs to ask for `stderr: "pipe"` explicitly.

Cooperative cancellation uses `AbortSignal` — the same mechanism as:

```ts
const controller = new AbortController();
const proc = Bun.spawn({ cmd: ["ffmpeg", "-i", entrada, saida], signal: controller.signal });
// …
controller.abort();   // sends killSignal (default SIGTERM)
```

Writing to stdin requires `stdin: "pipe"`, which returns a `FileSink`:

```ts
const proc = Bun.spawn(["wc", "-l"], { stdin: "pipe" });
proc.stdin.write(conteudo);
proc.stdin.end();
```

`Bun.spawnSync` blocks and returns a `SyncSubprocess`, with three declared differences: it has `success` (boolean of a zero exit code), `stdout`/`stderr` are `Buffer` instead of `ReadableStream`, and **it has no `stdin`**. For potentially unbounded output, `maxBuffer` limits how many bytes the process can emit before being killed.

```ts
const r = Bun.spawnSync({ cmd: ["yes"], maxBuffer: 100 });
```

The parent `bun` process does not exit while a child is alive; `proc.unref()` undoes that tie.

| ID | Rule |
| --- | --- |
| `BUN-RT-08` | An HTTP server handler **NEVER** calls `Bun.spawnSync` nor a `*Sync` API from `node:fs` — it blocks the event loop of the whole process. |
| `BUN-RT-09` | A subprocess of unguaranteed duration **MUST** receive a `timeout` or a `signal`. |

---

## 6. Hashing and passwords: three APIs that are not interchangeable

| API | Nature | For what |
| --- | --- | --- |
| `Bun.password` | cryptographic, with salt and cost | **user password** — argon2id (default) or bcrypt |
| `Bun.CryptoHasher` | cryptographic, incremental | integrity, signature, strong checksum (sha256, blake2b, sha3, …) |
| `Bun.hash.*` | **non-cryptographic** | hash table, dedupe, partitioning — wyhash (default), xxHash, crc32, murmur |

The source describes `Bun.hash` explicitly as *"utilities for non-cryptographic hashing"*, optimized for speed at the expense of collision resistance. Using it for a password, a token or anything that needs to resist an adversary is a vulnerability, not a performance choice.

```ts
// Sign-up
const hash = await Bun.password.hash(senhaEmClaro);
// => "$argon2id$v=19$m=65536,t=2,p=1$…"   salt already embedded

// Login
const ok = await Bun.password.verify(senhaEmClaro, usuario.senhaHash);
```

Verified points that avoid mistakes:

- **The salt is generated automatically and goes inside the hash.** There is no salt parameter, and storing a separate salt is redundancy.
- **`verify` detects the algorithm from the hash itself** (PHC for argon2, MCF for bcrypt). Changing the `hash` algorithm does not invalidate old hashes.
- **`hashSync`/`verifySync` exist**, and the docs warn that they are expensive: *"These functions are computationally expensive, so a blocking API can degrade application performance."* In a server, use the asynchronous versions.
- **With bcrypt, a password above 72 bytes goes through SHA-512 first**, instead of being silently truncated as in the classic implementation.
- `algorithm: "argon2id" | "argon2i" | "argon2d"` with `memoryCost` (KiB, minimum 8) and `timeCost`; `algorithm: "bcrypt"` with `cost` between 4 and 31. The values in the docs' examples are low on purpose — do not copy them into production without calibrating.

| ID | Rule |
| --- | --- |
| `BUN-RT-10` | A password **MUST** be handled with `Bun.password`; `Bun.hash` **NEVER** touches a password, token or secret — it is a non-cryptographic hash. |

---

## 7. `--watch` × `--hot`: the difference is the semantics of state

They are not two levels of aggressiveness of the same thing. They are two reload models.

| | `--watch` | `--hot` |
| --- | --- | --- |
| What it does | **hard restart**: kills and restarts the process | **soft reload**: re-evaluates the modules in the live process |
| `globalThis` | reset on every reload | **preserved** |
| Connections, timers, server | lost | kept |
| Arguments and env | the same as the initial run | — |
| Before restarting | runs the kill signal handlers (`SIGTERM` by default, adjustable with `--watch-kill-signal`) | — |
| If the process crashes | tries to restart | — |
| Reach | imported files, including `bun test` | imported files **outside `node_modules`** |
| Good for | tests, CLI, anything that requires clean state | HTTP server in development |

```ts
// With --hot, this counts reloads instead of restarting from zero:
declare global { var reloads: number }
globalThis.reloads ??= 0;
globalThis.reloads++;

Bun.serve({
  port: 3000,
  routes: {
    // `routes` and not a bare `fetch` — BUN-HTTP-01. See Bun - HTTP e Servidor.
    "/reloads": () => new Response(`reloads: ${globalThis.reloads}`),
  },
});
```

Where this becomes a bug: **preserved state hides an initialization error.** A cache populated on the first load stays populated after you break the code that populates it; a connection pool survives the change that should have recreated it. For a server in development, the benefit (not losing connections, instant refresh) pays off. For tests, almost never — the `bun test` docs themselves recommend `--watch`: *"For most tests, use `--watch`: it gives better isolation between runs."*

Two scope notes: `bun --hot` **is not** browser HMR. It is the server-side equivalent. Frontend HMR lives in [Bun - Bundler and Build](bun-bundler-and-build.md). And `--no-clear-screen` prevents clearing the terminal on every reload — useful when several instances run in parallel and one would wipe the other's errors.

| ID | Rule |
| --- | --- |
| `BUN-RT-11` | `--hot` is **NEVER** used where the result depends on clean state (tests, jobs, initialization checks) — in those cases, `--watch`. |

---

## 8. Global utilities that show up in real code

It is not the complete list (see [Bun](bun.md) § 4 for what was left off the map) — it is the subset that replaces an npm dependency.

```ts
Bun.version;                    // "1.3.x" — version of the running CLI
Bun.main;                       // absolute path of the entrypoint
import.meta.path === Bun.main;  // "was this file executed directly?"

Bun.which("psql");              // path of the executable, or null — replaces the `which` package
Bun.randomUUIDv7();             // monotonic, sortable UUID v7, good for a database key
await Bun.sleep(250);           // Promise; there is Bun.sleepSync for CLI
Bun.deepEquals(a, b);           // structural equality
Bun.escapeHTML(entradaDoUsuario);
Bun.fileURLToPath(import.meta.url);
Bun.pathToFileURL("/srv/app/index.ts");

Bun.gzipSync(bytes);  Bun.gunzipSync(bytes);
Bun.zstdCompressSync(bytes);  await Bun.zstdDecompress(bytes);

await Bun.readableStreamToText(stream);
await Bun.readableStreamToJSON(stream);
await Bun.readableStreamToFormData(stream);
```

On `Bun.randomUUIDv7()`: the docs detail the monotonicity guarantee — the counter is atomic and safe across Workers in the same process, and when it overflows within the same millisecond Bun advances the timestamp instead of wrapping around, keeping the UUIDs strictly increasing. It accepts `"hex"` (default), `"base64"`, `"base64url"` or `"buffer"` as the encoding. For a sortable primary key, it is the right choice over `crypto.randomUUID()` (v4).

On streams: Bun implements the Web types (`ReadableStream`, `WritableStream`, `TransformStream`) as globals, and also `node:stream`. The two coexist, but the compatibility docs record that `isReadable`/`isWritable`/`Readable.isDisturbed` from `node:stream` only understand Node streams, not Web streams. Conceptual context in and.

---

## 9. `bunfig.toml`: one file, four command scopes, and a global × project merge

`bunfig.toml` is the persistent configuration of the whole of Bun — runtime, `bun install`, `bun test` and `bun run` in the same tree. Everything it does also exists as a command-line flag; it is the place where the decision stops being typed on every run.

### Where the file lives

| Scope | Path | Name |
| --- | --- | --- |
| Project | project root, next to `package.json` | `bunfig.toml` |
| Global | `$HOME/.bunfig.toml` or `$XDG_CONFIG_HOME/.bunfig.toml` | `.bunfig.toml` — **with a dot** |

The name changes between the two: the project one has no dot, the global one does. Copying one to the other location without renaming produces a file that is never read, and Bun does not warn.

### Precedence

1. **Global and project are combined by `shallow merge`**, with the project one beating the global.
2. **A command-line flag beats `bunfig.toml`**, where the equivalent option exists.
3. **A verified exception, and it is the one that surprises:** for `bun run`, Bun automatically loads **only** the project's local `bunfig.toml` — it does not look for the global `.bunfig.toml`. Global `[run]` configuration does not apply to `bun run`.

That the merge is *shallow* matters in practice: declaring `[install]` in the project replaces the global's entire `[install]` table, not field by field.

**In a monorepo: not verified.** The source documents the global × project pair and nothing about workspaces — there is no statement that the root `bunfig.toml` is inherited by a member package, nor that the two are merged. Until that is confirmed, treat `bunfig.toml` as resolved from the directory where the command runs and do not count on inheritance.

### The sections this corpus uses

```toml
# bunfig.toml — project root

# --- top level: runtime ---
preload = ["./instrumentacao.ts"]     # runs before any entrypoint
jsx = "react-jsx"                     # same keys as tsconfig (§ 2)
env = false                           # turns off automatic .env loading (§ 4)
logLevel = "warn"                     # "debug" | "warn" | "error"

[install]
linker = "isolated"                   # "hoisted" | "isolated"  → [Bun - Package Manager](bun-package-manager.md) § 5
ignoreScripts = true                  # blocks lifecycle scripts  → § 4 of that note
minimumReleaseAge = 259200            # seconds
frozenLockfile = true                 # equivalent to --frozen-lockfile
production = false                    # no devDependencies; freezes the lockfile

[test]
preload = ["./happydom.ts", "./testing-library.ts"]   # → [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md) § 2
root = "."
coverageThreshold = { lines = 0.9 }
pathIgnorePatterns = ["**/fixtures/**"]

[run]
bun = true                            # aliases `node` to `bun` inside scripts
shell = "system"                      # "bun" | "system"
silent = false

[serve]
port = 3000                           # default port of Bun.serve()
```

The example shows what this corpus uses; the sections have more keys. What each one reaches, and where the note details it: **top level** = runtime (`preload`, `jsx*`, `env`, `define`, `loader`, `smol`, `logLevel`, `console.depth`) → § 2 and § 4 · **`[install]`** = `bun install`/`add`/`ci` (`linker`, `hoist`, `ignoreScripts`, `frozenLockfile`, `production`, `registry`, `scopes`, `minimumReleaseAge*`, `globalStore`, `saveTextLockfile`, `auto`, `security.scanner`, `cache.*`) → [Bun - Package Manager](bun-package-manager.md) · **`[test]`** = `bun test` (`preload`, `root`, `coverage*`, `pathIgnorePatterns`, `randomize`, `seed`, `retry`, `rerunEach`, `concurrentTestGlob`, `onlyFailures`, `reporter.*`) → [Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) § 5 · **`[run]`** = `bun run` (`bun`, `shell`, `silent`, `elide-lines`, `noOrphans`) → § 2 · **`[serve]`** = default `port` of `Bun.serve()` → `Bun - HTTP e Servidor`.

The `[test] preload` key is described by the source as *"the same as the top-level `preload` field, but only applies to `bun test`"*. It is not a separate mechanism — it is the same field with a narrower scope.

### `--preload` (and `-r`): running code before the entrypoint

The command-line equivalent of `preload`, and the analogue of `node --require`:

```bash
bun --preload ./setup.ts run ./index.ts    # runtime flag → before the subcommand
bun -r ./setup.ts index.ts                 # -r is an alias of --preload
bun test --preload ./happydom.ts           # ad-hoc; the persistent form is [test] preload
```

Three operational points:

- **The flag belongs to the runtime, so it comes before the subcommand.** `bun run ./index.ts --preload ./setup.ts` passes `--preload` on to the script — the preload never runs. It is the same trap as `bun run dev --watch` (§ 2).
- **What it is for:** registering a plugin, injecting a global, installing instrumentation — without polluting the entrypoint with an `import` that only exists for its side effect. In `bun test` it is the only place that runs *before* the test file's imports, which is why `mock.module()` and `GlobalRegistrator.register()` live there (`BUN-TEST-04`, `BUN-TEST-07`).
- **`--import` was not confirmed.** Node has `--import` as the ESM equivalent of `--require`; I found no statement in Bun's docs that the flag exists or is accepted. Use `--preload`/`-r`, which are documented.

---

## 10. `using`: the resource closes itself, and that is not a typo

`using db = new Database("app.sqlite")` and `await using reserved = await sql.reserve()` appear in the corpus as the recommended pattern, and read like a misspelled `const` to anyone who has not seen the feature. They are not: `using` is a **declaration** from the TC39 *Explicit Resource Management* proposal, and what it does is call the resource's disposal on leaving the scope, including through an exception or an early `return`.

```ts
{
  using arquivo = Bun.file("pedidos.ndjson").writer();
  arquivo.write(linha);
}   // ← here the writer's [Symbol.dispose] is called, even if the line above throws
```

What you need to know before using it:

| Point | Verified state |
| --- | --- |
| Standard | TC39, **stage 3** — not ratified JavaScript |
| Engine support | `using` and `await using` are natively supported in JavaScriptCore, Bun's engine |
| How it works | the object's prototype defines `[Symbol.dispose]`, or `[Symbol.asyncDispose]` for an asynchronous resource (`await using`) |
| Bun APIs | dozens, including `Bun.spawn()`, `Bun.serve()`, `Bun.connect()`, `Bun.listen()` and `bun:sqlite` |
| `DisposableStack` / `AsyncDisposableStack` | implemented in Bun 1.3 — to accumulate several resources in a single scope |
| TypeScript | **requires TS ≥ 5.2**, which introduced the syntax |
| `tsconfig.json` | `lib` needs to include `"esnext"` or `"esnext.disposable"`; the `lib: ["ESNext"]` of the tsconfig recommended by Bun already covers it |

The consequence of forgetting the `lib`: the code runs and `tsc --noEmit` fails, with an error about a missing `Symbol.dispose`. It is a type configuration failure, not a runtime one.

And the boundary: `using` is a **language** feature, not a Bun one. A file that uses it and is transpiled by another tool (or consumed by a runtime without `Symbol.dispose`) needs a polyfill. Inside an app that runs on Bun, it does not.

---

## Antipatterns

| Antipattern | Why it fails | What to do |
| --- | --- | --- |
| `if (Bun.file(p).size > 0)` to test existence | a nonexistent file also has `size === 0`; the condition confuses "empty" with "absent" | `await Bun.file(p).exists()` — `BUN-RT-03` |
| `const conteudo = Bun.file(p)` and using `conteudo` as a string | `Bun.file` returns a lazy `BunFile`, not the content; nothing has been read yet | `await Bun.file(p).text()` — `BUN-RT-02` |
| `writer.write(...)` in a loop without `.end()` | the `bun` process stays alive waiting for the `FileSink` to close; the script "hangs at the end" | `await writer.end()`, or `writer.unref()` — `BUN-RT-04` |
| `readFileSync`/`spawnSync` inside a `Bun.serve` handler | blocks the event loop; under load, degrades every connection, not only the current one | `Bun.file().text()` / `Bun.spawn` — `BUN-RT-08` |
| `Bun.spawn` of an external command without `timeout` or `signal` | a hung process keeps the parent alive and leaks into the next deploy | `{ timeout, killSignal }` or `{ signal }` — `BUN-RT-09` |
| `Bun.hash(senha)` or `new Bun.CryptoHasher("sha256")` for a password | `Bun.hash` is non-cryptographic; sha256 without salt or cost is brute-forceable | `Bun.password.hash` / `.verify` — `BUN-RT-10` |
| `.env.production` expected to beat `.env.local` | precedence is increasing and `.env.local` is the last in the list | do not version `.env.local` on a deploy machine; use an explicit `--env-file` |
| Password with a literal `$` in `.env` without escaping | Bun expands `$VAR` by default; the value arrives truncated or empty | escape with `\$` — `BUN-RT-07` |
| `bun --hot` to run the test suite | global state preserved between reloads masks a setup failure and leaks between runs | `bun test --watch` — `BUN-RT-11` |
| Container image without `node_modules`, counting on "Bun resolves it" | without `node_modules`, Bun installs from the network at runtime and may resolve `latest` | copy `node_modules` (or `bun ci` in the build) and run with `--no-install` — `BUN-RT-12` |
| `bun run dev --watch` | `bun` passes flags at the end of the command on to the script; watch is never enabled | `bun --watch run dev` |
| `bun run ./index.ts --preload ./setup.ts` | same trap: `--preload` becomes a script argument and the preload does not run | `bun --preload ./setup.ts run ./index.ts` — § 9 |
| Path alias declared only in `resolve.alias` of `vite.config.ts` | Bun does not read `vite.config`; the import breaks in `bun test` and in any run outside Vite | declare it in `compilerOptions.paths` — § 2 |
| `"jsx": "preserve"` in the `tsconfig.json` of a project that runs on Bun | the source declares `"preserve"` unsupported; there is no transform and the JSX does not execute | `"react-jsx"` — § 2 |
| Reading `import.meta.env.DEV`/`.MODE` in a component that also runs in `bun test` | they are constants injected by Vite; under Bun, `import.meta.env` is `process.env` and they are `undefined` | receive by prop/injectable config — § 4 |
| Copying the project's `bunfig.toml` to `$HOME/bunfig.toml` | the global file is called `.bunfig.toml`, with a dot; without the dot it is never read, and nothing warns | `$HOME/.bunfig.toml` — § 9 |
| `using` in a project with TS < 5.2 or without `esnext.disposable` in `lib` | it runs, but `tsc --noEmit` fails over a missing `Symbol.dispose` | TS ≥ 5.2 and `lib: ["ESNext"]` — § 10 |

---

## Review checklist

- [ ] Is there `tsc --noEmit` in CI? The runtime does not check types.
- [ ] Does every file existence check use `.exists()`? → `BUN-RT-03`
- [ ] Is every open `FileSink` closed or untied? → `BUN-RT-04`
- [ ] No `*Sync` call inside an HTTP handler? → `BUN-RT-08`
- [ ] Does every `Bun.spawn` of an external command have a `timeout` or `signal`? → `BUN-RT-09`
- [ ] Do passwords use `Bun.password`, and nothing else? → `BUN-RT-10`
- [ ] Are environment variables validated at startup? → `BUN-RT-06`
- [ ] Do production secrets come from a secret manager, not from `.env`? → `BUN-RT-05`
- [ ] Is the chosen reload mode the right one for the case (`--watch` for tests, `--hot` for a server)? → `BUN-RT-11`
- [ ] Does the production image have `node_modules` or run with `--no-install`? → `BUN-RT-12`
- [ ] Is `compilerOptions.jsx` `"react-jsx"` (or `"react"`/`"react-jsxdev"`), never `"preserve"`? → § 2
- [ ] Does every path alias exist in `compilerOptions.paths`, and not only in `vite.config.ts`? → § 2
- [ ] Does no shared component depend on `import.meta.env.MODE`/`.DEV`/`.PROD`? → § 4
- [ ] Does every runtime flag (`--watch`, `--hot`, `--preload`, `-r`) come **before** the subcommand? → § 9

---

## Related

- [Bun](bun.md) — hub, API map, decision trees
- [Bun - Package Manager](bun-package-manager.md) · [Bun - Tests](bun-tests.md) · `Bun - HTTP e Servidor` · [Bun - Bundler and Build](bun-bundler-and-build.md) · [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md)
- `Node.js` · · `TypeScript`
- · ·
- · ·

## Sources consulted

Verified on **2026-08-15**:

- [Bun Runtime](https://bun.com/docs/runtime) · [Watch Mode](https://bun.com/docs/runtime/watch-mode)
- [Module Resolution](https://bun.com/docs/runtime/module-resolution) · [JSX](https://bun.com/docs/runtime/jsx) · [Auto-install](https://bun.com/docs/runtime/auto-install)
- [File I/O](https://bun.com/docs/runtime/file-io) · [Streams](https://bun.com/docs/runtime/streams)
- [Environment Variables](https://bun.com/docs/runtime/environment-variables)
- [Spawn](https://bun.com/docs/runtime/child-process) · [Hashing](https://bun.com/docs/runtime/hashing) · [Utils](https://bun.com/docs/runtime/utils)
- [Globals](https://bun.com/docs/runtime/globals) · [TypeScript](https://bun.com/docs/typescript) · [Node.js Compatibility](https://bun.com/docs/runtime/nodejs-compat)
- [bunfig.toml](https://bun.com/docs/runtime/bunfig) · [Loaders](https://bun.com/docs/bundler/loaders)
- Outside Bun's official source, for the `import.meta.env` comparison: [Vite — Env Variables and Modes](https://vite.dev/guide/env-and-mode); for the `using` version requirement: [TypeScript 5.2 release notes](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-2.html)

**What the verification contradicted:**

- **`.env` precedence is increasing in the order listed**: `.env` < `.env.{NODE_ENV}` < `.env.local`. `.env.local` beats `.env.production`.
- **`Bun.env` and `import.meta.env` are aliases of `process.env`**, not distinct objects. There is no semantic difference between them.
- **Bun turns off automatic `.env` loading when invoked as `node`** (`bun --bun`, `bunx --bun`, a `node` symlink), so as not to trample the `.env.{mode}` resolution of tools like Vite.
- **`Bun.hash` is declaredly non-cryptographic.** The name suggests otherwise and its proximity to `Bun.password` on the same page increases the risk of mixing them up.
- **`bcrypt` in `Bun.password` does not truncate a password above 72 bytes** — it goes through SHA-512 first, unlike the classic implementation.
- **Without `node_modules`, the runtime installs packages from the network at execution time**, resolving `latest` when there is no lockfile nor a `package.json` above.
- **`from "./x.js"` resolves `./x.ts`**, for compatibility with the TypeScript compiler. `.cjs` is **not** rewritten to `.cts`.
- **`--watch` runs the kill signal handlers before restarting** (`SIGTERM` by default), which leaves room for a clean shutdown — behavior absent from most watchers.
- **The runtime transpiler has an on-disk cache** for files above 4 KB (`BUN_RUNTIME_TRANSPILER_CACHE_PATH`), turned off automatically in the official Docker images.
- **`"jsx": "preserve"` is not supported.** The other three values (`"react"`, `"react-jsx"`, `"react-jsxdev"`) are. The `tsconfig.json` that Bun's own docs recommend ships `"jsx": "react-jsx"` — the same value as the Vite + React templates, which makes the most common case require no configuration at all.
- **The global configuration file is called `.bunfig.toml`** (with a dot), and the project one `bunfig.toml` (without). The two are combined by *shallow merge*, with the project one winning.
- **`bun run` does not read the global `bunfig.toml`.** It is the only documented exception to the merge rule: for `bun run`, only the project's local file is loaded automatically.
- **`-r` is an alias of `--preload`**, and the behavior is declared as analogous to `node --require`. I did not confirm the existence of `--import` in Bun.
- **At runtime, `import logo from "./logo.svg"` resolves to the absolute path of the file on disk**, not to a URL — the `file` loader checks that the file exists and returns the path. It is something other than what Vite delivers for the same import.
- **`using` is a stage 3 language feature**, natively supported in JavaScriptCore and requiring TypeScript ≥ 5.2 with `esnext.disposable` in `lib`. It is not Bun sugar, and it is not `const`.
