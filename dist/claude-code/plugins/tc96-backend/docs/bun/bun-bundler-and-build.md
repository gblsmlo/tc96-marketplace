---
titulo: Bun - Bundler and Build
Link: https://bun.com/docs/bundler
tags:
  - bun
  - bundler
  - build
  - agent-context
source: "Official documentation — https://bun.com/docs"
verificado-em: 2026-08-15
---

# Bun - Bundler and Build

> `Bun.build()` × `bun build` · `target` (`browser`/`bun`/`node`) and what changes in each · `external` × `packages` · splitting, `minify`, `sourcemap`, `define`, `loader` · plugins (`onResolve`/`onLoad`) · HTML/CSS imports and the dev server with HMR · `--compile` for a single executable · macros · where Vite still wins.
>
> **Does not cover:** module resolution at runtime and transpilation without a bundle ([Bun - Runtime and APIs](bun-runtime-and-apis.md)) · installing dependencies and the lockfile ([Bun - Package Manager](bun-package-manager.md)) · the server that consumes the artifact (`Bun - HTTP e Servidor`) · Docker image and deploy ([Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md)).

Entry: [Bun](bun.md) § 5 (decision trees) · § 6 (normative rules) · Normative base: [Bun](bun.md)

Version verified: **Bun 1.3.14** (`bun@latest` on the npm registry, 2026-08-15).

---

## 1. Concept: the bundler exists to produce an artifact — the real decision is `target` and what stays external

A bundler is not mandatory in Bun. The runtime transpiles TypeScript and JSX on import, so server code **runs without a build**. The docs are direct about it: for `target: "bun"`, *"in many cases, it isn't necessary to bundle server-side code"*.

What changes that conclusion are three concrete reasons, and only them:

1. **The code goes to the browser.** There is no choice there: TS/JSX need to become JS, and hundreds of files in `node_modules` need to become a few.
2. **You want to reduce boot time in production.** Bundling moves resolution, parsing and transpilation from runtime to build time.
3. **You want a single artifact.** `--compile` produces a binary; a Docker image without `node_modules` is a consequence of that — and it is a real Dockerfile option, not a bundler detail. If you arrived here coming from "how do I containerize this", § 8 of this note is the destination, and the conventional multi-stage Dockerfile (with `node_modules` and `bun install --production`) is in [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md) § 6. The two forms are alternatives for the same problem: `--compile` swaps `node_modules` in the image for a binary that already carries the runtime.

Once it is decided that there will be a build, **two options decide almost everything else**: `target` (which resolution conditions apply, which runtime is assumed) and what stays **external** (what does not enter the bundle and will be resolved at runtime). Far more mistakes are made in those two than in `minify` or `splitting`.

And an explicit boundary from the source, which avoids a wrong expectation: *"The Bun bundler is not intended to replace `tsc` for typechecking or generating type declarations."* The bundler does not typecheck. Typechecking is still `tsc --noEmit` in a separate step — see `TypeScript`.

---

## 2. `Bun.build()` × `bun build`: same engine, different ergonomics

**Concept.** The two forms cover the same set of options. The programmatic API wins when the build has logic (a matrix of targets, plugins built at runtime, reading the `metafile`); the CLI wins for the simple case of a script in `package.json`.

The difference that matters in CI is failure handling: **`Bun.build` rejects with an `AggregateError`**. A bare `await Bun.build(...)` without `try/catch` brings the script down with a non-zero exit code — which is usually what you want. Catching and ignoring is how a broken build passes green.

```ts
// build.ts — equivalent to: bun build ./src/index.tsx --outdir ./dist --target browser --minify
const resultado = await Bun.build({
  entrypoints: ["./src/index.tsx"],
  outdir: "./dist",
  target: "browser",   // default
  format: "esm",       // default
  splitting: true,     // default false
  minify: true,        // default false
  sourcemap: "linked", // default "none"; "linked" requires outdir
  define: {
    // key = identifier; value = JSON string that gets inlined
    "process.env.NODE_ENV": JSON.stringify("production"),
    __VERSAO__: JSON.stringify(Bun.env.GIT_SHA ?? "dev"),
  },
});

for (const artefato of resultado.outputs) {
  console.log(artefato.path, artefato.kind);
}
```

An easy detail to get wrong in `define`: **the value is a JSON string**, not the value. `define: { API_URL: "https://x" }` inlines the identifier `https://x` and breaks parsing. `JSON.stringify(...)` always.

| ID | Rule |
| --- | --- |
| `BUN-BUILD-01` | A build script **MUST** let the `AggregateError` from `Bun.build` propagate (or exit with a non-zero code) — a broken build **NEVER** ends in success. |
| `BUN-BUILD-02` | `define` values **MUST** be produced by `JSON.stringify` — the option inlines the text literally. |

---

## 3. `target`: the option that decides resolution, globals and polyfill

**Concept.** `target` is not an output label. It changes **which export condition wins** in resolution and what the bundler assumes exists in the environment.

| `target` | Export condition | What it assumes | Mark in the output |
| --- | --- | --- | --- |
| `"browser"` | `"browser"` | **default.** `node:*` imports, but not everything works — the docs cite `fs.readFile` as an example of what does not run | — |
| `"bun"` | Bun's conditions | full Bun runtime; target of a fullstack app with HTML imported on the server | `// @bun` pragma (the runtime skips retranspilation) |
| `"node"` | `"node"` | Node.js. **Bun does not polyfill the `Bun` global nor the `bun:*` modules** | — |

Two implicit defaults that surprise:

- **A Bun shebang in the entrypoint (`#!/usr/bin/env bun`) changes the default `target` to `"bun"`.**
- **`format: "cjs"` changes the default `target` from `"browser"` to `"node"`.**

`format` accepts `"esm"` (default), `"cjs"` and `"iife"`; the docs mark **`cjs` and `iife` as experimental**. Combining `target: "bun"` with `format: "cjs"` generates the `// @bun @bun-cjs` pragma, and the docs warn that **this CommonJS wrapper is not compatible with Node.js** — a bundle marked that way does not run there.

| ID | Rule |
| --- | --- |
| `BUN-BUILD-03` | `target` **MUST** be declared explicitly in every production build — the default (`"browser"`, or `"bun"`/`"node"` by shebang/format) changes resolution silently. |
| `BUN-BUILD-04` | Code that uses `Bun.*` or `bun:*` **NEVER** is bundled with `target: "node"` — there is no polyfill; the failure appears only at runtime. |

---

## 4. `external` and `packages`: what leaves the bundle

**Concept.** Two options solve similar problems at different granularities.

- **`external: ["react", "lodash"]`** — explicit list. The import stays in the output as is, to be resolved at runtime.
- **`packages: "external"`** — turns off bundling of **all** dependencies at once. Bun treats as a package any import whose path does not start with `.`, `..` or `/`. Default is `"bundle"`.

The practical criterion:

| Situation | Choice |
| --- | --- |
| Browser bundle for your own app | everything internal (default) |
| Library published on npm | `packages: "external"` — dependencies resolved by the consumer |
| Server that keeps `node_modules` next to it | `packages: "external"` |
| Server in a lean image, without `node_modules` | default (`"bundle"`), or `--compile` |
| Native addon / `.node` that cannot be bundled | `external` just for it |

**`splitting`** (default `false`) only makes sense with multiple entrypoints or dynamic `import()`: the shared code becomes a chunk with a content hash in its name. Turning on splitting with a single entrypoint and no dynamic import produces no chunk at all — only noise in the output.

| ID | Rule |
| --- | --- |
| `BUN-BUILD-05` | A library published to a registry **MUST** be bundled with `packages: "external"` — a bundled dependency duplicates code and breaks deduplication in the consumer. |

---

## 5. `minify`, `sourcemap`, `loader`

**Concept.** The three compose the production artifact, and each has a catch.

**`minify`** (default `false`) accepts a boolean or granular: `{ whitespace, identifiers, syntax }`. On the CLI, `--minify-whitespace`, `--minify-identifiers`, `--minify-syntax`.

**`sourcemap`** (default `"none"`):

| Value | Produces | Note |
| --- | --- | --- |
| `"none"` | nothing | default |
| `"linked"` | separate `.js.map` + `//# sourceMappingURL` comment | **requires `outdir`** |
| `"external"` | separate `.js.map`, **without** the comment | inserts `//# debugId=…` to match bundle and map |
| `"inline"` | map in base64 at the end of the bundle | inflates the artifact served to the client |

For the browser, `"external"` is what gives a readable stack trace in the error collector without publishing the map together with the bundle — the `debugId` is what links the two. `"inline"` in a production bundle sends the whole source code to every visitor.

**`loader`** maps an extension to a built-in loader. The verified names: `js`, `jsx`, `ts`, `tsx`, `json`, `jsonc`, `toml`, `yaml`, `file`, `napi`, `wasm`, `text`, `css`, `html`.

```ts
await Bun.build({
  entrypoints: ["./src/index.tsx"],
  outdir: "./dist",
  loader: {
    ".png": "dataurl", // inlines as a data: URI
    ".sql": "text",    // imports as a string
  },
});
```

**`bytecode`** deserves a note because the restrictions are strict: it requires `target: "bun"` and a matching Bun version. In CommonJS it works with or without `compile`, generating `.jsc` next to the entrypoint; **in ESM it requires `compile: true`**. Without an explicit `format`, `bytecode` assumes CommonJS. It does not obfuscate the source code.

| ID | Rule |
| --- | --- |
| `BUN-BUILD-06` | A production browser bundle **NEVER** uses `sourcemap: "inline"` — use `"external"` and send the map to the error collector. |

---

## 6. Plugins: the same API for runtime and bundler

**Concept.** The plugin API is **universal**: the same object extends the bundler and the runtime. A plugin is `{ name, setup(build) }`.

Verified hooks: `onStart()` (bundle started; may return a Promise, and the bundler waits), `onResolve()` (before resolving a module), `onLoad()` (before loading), `onBeforeParse()` (zero-copy native addon on the parser thread), `onEnd()` (bundle finished, receives the `BuildOutput`).

`onResolve` and `onLoad` receive `{ filter: RegExp, namespace?: string }`. Namespace is the module prefix in the transpiled code; the default is `"file"`, and `"bun"` / `"node"` cover the built-in modules.

```ts
import type { BunPlugin } from "bun";

// loads .sql as a string exported by default
const sqlPlugin: BunPlugin = {
  name: "sql-loader",
  setup(build) {
    build.onLoad({ filter: /\.sql$/ }, async ({ path }) => ({
      loader: "js",
      contents: `export default ${JSON.stringify(await Bun.file(path).text())};`,
    }));
  },
};

await Bun.build({ entrypoints: ["./src/index.ts"], outdir: "./dist", plugins: [sqlPlugin] });
```

`filter` is a `RegExp` applied to the path. A filter that is too wide (`/.*/`) makes the callback run for every module in the graph, including everything in `node_modules` — it is the most common cause of a slow build with a custom plugin.

| ID | Rule |
| --- | --- |
| `BUN-BUILD-07` | The `filter` of `onLoad`/`onResolve` **MUST** be anchored on the intended extension or namespace — a wide filter runs the callback for every module in the graph. |

---

## 7. HTML, CSS and the dev server: useful, and declared *work in progress*

**Concept.** `bun ./index.html` brings up a dev server with no configuration: Bun scans the HTML with `HTMLRewriter`, finds `<script>` and `<link>`, runs bundler + transpiler + CSS parser, rewrites the paths with a hash and serves.

```bash
bun ./index.html                 # SPA: the HTML becomes the fallback for all routes
bun ./index.html ./about.html    # MPA: / and /about
bun ./**/*.html                  # glob; the common prefix becomes the base
```

The same HTML import works inside the server, linking this note to `Bun - HTTP e Servidor`:

```ts
import painel from "./painel.html";

Bun.serve({
  routes: {
    "/": painel,                                     // bundled and served
    "/api/pedidos": { GET: () => Response.json(listarPedidos()) },
  },
  development: { hmr: true, console: true },         // console: echoes browser logs in the terminal
});
```

What `development` turns on and off, verified:

| | `development: true` | `development: false` |
| --- | --- | --- |
| Sourcemap | `SourceMap` header present | off |
| Minification | **off** | on |
| HMR | on (unless `hmr: false`) | off |
| Bundling of the `.html` | **rebundle on every request** | lazy on the first request, cached in memory until restart |
| `Cache-Control` / `ETag` | — | sent |

For production there is the AOT path, available **since Bun v1.2.17**: `bun build --target=bun --production --outdir=dist ./src/index.ts` turns the HTML import into a pre-built manifest, and `Bun.serve` then serves without bundling anything at runtime.

**Stability status — do not assume.** The docs themselves mark two things:

> "The fullstack dev server is a work in progress. Features and APIs may change."

> "The HMR API is still a work in progress. Some features are missing."

In the `import.meta.hot` table, `invalidate()` and `send()` are marked as **not implemented**, and `prune()` as partial (*"callback is currently never called"*). `accept()`, `data`, `dispose()`, `on()`/`off()` work. And there is a syntactic restriction that breaks code silently: for dead code elimination to work, **the phrase `import.meta.hot.<API>` has to appear whole and direct**. `const hot = import.meta.hot; hot.accept()` does not work.

| ID | Rule |
| --- | --- |
| `BUN-BUILD-08` | `import.meta.hot` APIs **MUST** be called in the full form `import.meta.hot.x()`, without going through a variable or argument — otherwise elimination in production breaks. |
| `BUN-BUILD-09` | A fullstack app deploy **MUST** use an AOT build (`bun build --target=bun --production`) or `development: false`; the dev server **NEVER** serves production. |

---

## 8. `--compile`: one binary, with declared limits

**Concept.** `--compile` embeds the bundle **and a copy of the Bun runtime** in a single executable. All of Bun's and Node's built-in APIs keep working inside it.

```bash
# production, following the docs' recommendation
bun build ./src/servidor.ts --compile --minify --sourcemap --bytecode --outfile ./servidor

# cross-compile: target declared explicitly
bun build ./src/servidor.ts --compile --target=bun-linux-x64 --outfile ./servidor
```

What each flag does, verified: `--minify` shrinks the output; `--sourcemap` embeds a zstd-compressed map, and Bun resolves it by itself when an error happens; `--bytecode` moves JavaScriptCore's parsing from runtime to build time (the docs show `tsc` starting **2x faster**), without obfuscating the source.

**Declared limitations** — `--compile` does not accept:

- `--outdir` (use `--outfile`)
- `--public-path`
- `--target=node`
- `--target=browser` without an HTML entrypoint
- `--no-bundle` (compile always bundles everything)

`--compile` **supports** `--splitting` (chunks loaded at runtime by the binary itself) and plugins.

**In the Dockerfile, `--compile` is the alternative to the image with `node_modules`.** A binary produced here runs on a base image without Bun installed and without `node_modules` copied — the cost is an explicit cross-compile (`BUN-BUILD-10`) when the build machine differs from the destination, and a larger image per binary than the sum of the sources. The conventional path, with `oven/bun` + `bun install --frozen-lockfile --production`, is in [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md) § 6 with the full Dockerfile and the deploy rules (`BUN-SYS-11`, `BUN-SYS-12`). Choosing between the two is choosing between "smaller image, one more build step" and "image with the runtime installed, a deploy like any Node app's".

| ID | Rule |
| --- | --- |
| `BUN-BUILD-10` | A `--compile` binary for deploy **MUST** declare `--target=bun-<os>-<arch>` when the build machine differs from the destination — cross-compile is not inferred. |

---

## 9. Macros: bundle-time, and not marked as experimental

**Concept.** A macro is an ordinary JavaScript function that runs **during the bundle**; Bun inlines the return value in the output and the function's source does not go into the bundle. It is activated by the import attribute:

```ts
import { hashDoCommit } from "./git.ts" with { type: "macro" };

console.log(`build ${hashDoCommit()}`); // becomes a string literal in the bundle
```

Status in the source: **the Macros page carries no experimental or beta marking**. What it carries are hard restrictions, and that is where code breaks:

- **Only serializable values.** JSON works; functions and class instances do not. `Response` and `Blob` have special serialization guided by `Content-Type` — a macro can return the result of `fetch()` directly.
- **Arguments need to be statically known.** Passing a variable computed at runtime is a build error.
- **Macros run synchronously in the transpiler, in the visit phase — before plugins.**
- **Code in `node_modules` cannot invoke a macro** (security barrier). Your code can import a macro *from* a package.
- `--no-macros` turns everything off, with a build error.

Dead code elimination runs **after** the macro, so `if (macroQueRetornaFalse()) { … }` disappears from the bundle when `minify.syntax` is on. It is the mechanism to compile feature flags out.

| ID | Rule |
| --- | --- |
| `BUN-BUILD-11` | A macro **NEVER** receives an argument whose value depends on runtime, and **MUST** return only serializable values (JSON, `Response` or `Blob`). |

---

## 10. Where Vite still wins, and where Bun already covers

An honest comparison is what makes this note useful. Verified in Bun's official docs; the Vite column reflects what Bun's docs do **not** offer.

| Situation | Choice | Why |
| --- | --- | --- |
| React SPA in production, with a plugin ecosystem (Tailwind via the official plugin, SVGR, i18n, bundle analysis) | **Vite** | Bun has plugins, but the published ecosystem is Vite's; Bun's docs cite Tailwind support and little more |
| React app with sophisticated HMR and mature Fast Refresh | **Vite** | Bun's HMR API is declared *work in progress*, with `invalidate()` and `send()` not implemented |
| Meta-level framework (Next, Remix, SvelteKit, TanStack Start) | **the framework's bundler** | the build is part of the framework, not your choice |
| Landing page or small SPA, with no third-party plugin | **Bun** | `bun ./index.html` comes up with no configuration and no dependency |
| Fullstack app where server and client live in the same process | **Bun** | HTML imported on the server + AOT build produces a single artifact |
| CLI distributed as a binary | **Bun** | `--compile` has no direct equivalent in Vite |
| Server bundle to reduce boot and image | **Bun** | `target: "bun"` + `--compile`, with no `node_modules` at the destination |
| Library published on npm | **Bun**, with a caveat | `packages: "external"` covers the bundle; the `.d.ts` files are still `tsc`'s job |

Rule of thumb: **the more the build belongs to the frontend, the more Vite wins; the more the build belongs to the server artifact or the binary, the more Bun wins.** The two coexist — the official docs have a guide for Vite running under Bun.

### 10.1 The case both rows cover: a React SPA with a small backend

The rows "React SPA in production with plugins → **Vite**" and "fullstack app in the same process → **Bun**" describe the same app when someone has a React SPA and a backend of ten routes. It is the most common case, and the table alone does not break the tie. The tie-breaker:

| Question | If yes | Why |
| --- | --- | --- |
| Does the frontend depend on any Vite plugin other than Tailwind? (SVGR, i18n, bundle analysis, mdx, framework plugin) | **Vite** | it is the only criterion with no workaround: the plugin does not exist in Bun's format and porting it is your work |
| Would replacing Vite force someone to debug HMR during delivery week? | **Vite** | Bun's HMR API is declared *work in progress* by the docs themselves |
| Is today's deploy two artifacts (static + server) and does that already hurt — CORS, two pipelines, two domains? | **Bun** | the HTML import on the server collapses the two into one process; see `Bun - HTTP e Servidor` § 7.1 |
| Will the backend grow and do you want a single artifact? | **Bun** | AOT + `--compile` close the loop without a second bundler |
| None of the above | **stay with Vite** | it is the option with zero reversal cost: keeping Vite closes no door, and the decision can wait |

The pattern behind it: **the cost of leaving Vite is proportional to the number of plugins**, and the gain of entering Bun is proportional to how much the server matters. A SPA with a small backend and three plugins stays on Vite; a SPA with a growing backend and no plugin besides Tailwind is exactly the case where Bun's fullstack path pays off.

### 10.2 Fast Refresh and "hot reloading" are not the same promise

The decision above depends on a concrete question — *does hot reload preserve component state?* — and the verifiable answer is partial:

- **Bun has the Fast Refresh transform.** The CLI exposes the `--react-fast-refresh` flag, described in the source as *"Enable React Fast Refresh transform (for development testing)"*.
- **The HMR docs acknowledge Fast Refresh as a participant in the mechanism**, in the clause that describes the fallback: *"When no modules call `import.meta.hot.accept()` (and there isn't React Fast Refresh or a plugin calling it for you), the page reloads when the file updates."* That is, without Fast Refresh (or an explicit `accept()`) the behavior is **reloading the page** — and reloading the page loses state, always.
- **Not verified:** whether the `bun init --react` template turns on the transform, and whether component state is preserved across a hot update. The template docs say only *"starts the API server and the React app with hot reloading"*, without qualifying. The HMR page nowhere claims preservation of React state; what it documents for preserving state is `import.meta.hot.data`, which is manual and per module.

Practical consequence, and it is what matters to the decision: **do not assume Fast Refresh parity with `@vitejs/plugin-react`**. If preserving form state while editing the component is part of the team's workflow, that needs to be tested in your project before the switch, not deduced from the docs.

### 10.3 What running Vite under `--bun` gives, according to the source

The official Vite guide recommends `bunx --bun vite`, and it is fair to ask what is gained. **The source declares a mechanism, not a benefit** — it is worth recording exactly that, because the recommendation circulates as if it were a performance gain:

- What `--bun` does: *"The `--bun` flag tells Bun to run Vite's CLI using `bun` instead of `node`; by default Bun respects Vite's `#!/usr/bin/env node` shebang line."* Without the flag, Bun **spawns a `node` process** to execute Vite's binary.
- How it does it: `--bun` creates a symlink to the Bun executable named `"node"` in a temporary directory and puts it on the `PATH` during the script's execution — so child processes that call `node` also land on Bun.
- **The docs declare no gain in build time, dev server or capability.** No number, no comparison. Whoever wants to claim a gain needs to measure in their own project.

And the most cited consequence — `--bun` turning off automatic `.env` loading — **is not an accidental loss, it is deliberate parity behavior with Node**, and the source explains why: *"When Bun is invoked as `node` … automatic `.env` loading is disabled to match Node.js. This lets tools with their own mode-aware `.env` resolution, such as Vite's `loadEnv`, pick the correct `.env.{mode}` file instead of seeing Bun's pre-populated values as shell-set overrides."* For a Vite project this is the **correct** behavior: it is what makes `.env.production` and the `VITE_` prefix filter work as Vite expects, instead of Bun pre-populating everything. An explicit `--env-file` is still respected.

On publishing static files.

> The docs list `--app` and the React Server Components flag (Bun Bake) explicitly as **EXPERIMENTAL**. It is not a path to production today. The `--react-compiler` flag is also marked **Experimental**.

---

## Antipatterns

| Antipattern | Why it fails | What to do |
| --- | --- | --- |
| Counting on the bundler to catch type errors | the docs declare that the bundler does not replace `tsc`; it strips the types without checking | `tsc --noEmit` in a separate CI step |
| `define: { API_URL: "https://api.exemplo.com" }` | the value is inlined as literal text, producing an invalid identifier | `JSON.stringify(...)` — `BUN-BUILD-02` |
| Omitting `target` and assuming server is the default | the default is `"browser"`; shebang and `format: "cjs"` change that silently | always declare `target` — `BUN-BUILD-03` |
| `target: "node"` in code that uses `Bun.serve` or `bun:sqlite` | there is no polyfill of the `Bun` global nor of `bun:*`; it breaks only at runtime | `target: "bun"` — `BUN-BUILD-04` |
| `try { await Bun.build(...) } catch {}` in the build script | the `AggregateError` is swallowed and CI passes with a broken artifact | let it propagate — `BUN-BUILD-01` |
| `sourcemap: "inline"` in the browser bundle | the whole source code is downloaded by every visitor | `"external"` + map upload — `BUN-BUILD-06` |
| Publishing a library with bundled dependencies | duplicates React/lodash in the consumer and breaks deduplication | `packages: "external"` — `BUN-BUILD-05` |
| `const hot = import.meta.hot; hot.accept()` | dead code elimination requires the whole, direct phrase; in production it breaks | `import.meta.hot.accept()` — `BUN-BUILD-08` |
| Serving production with `development: true` | rebundle on every request, no minification, no `Cache-Control` nor `ETag` | AOT build or `development: false` — `BUN-BUILD-09` |
| `bun build --compile --outdir dist` | `--compile` does not accept `--outdir`; the build fails | `--outfile` — `BUN-BUILD-10` |
| A macro receiving a value computed at runtime | a macro argument needs to be statically known; it is a build error | pass a constant or the return of another macro — `BUN-BUILD-11` |
| `filter: /.*/` in `onLoad` | the callback runs for every module, including all of `node_modules` | anchor by extension or namespace — `BUN-BUILD-07` |

---

## Review checklist

- [ ] Is `target` declared explicitly? → `BUN-BUILD-03`
- [ ] No `Bun.*` / `bun:*` under `target: "node"`? → `BUN-BUILD-04`
- [ ] Does every `define` value go through `JSON.stringify`? → `BUN-BUILD-02`
- [ ] Does a `Bun.build` failure bring the process down? → `BUN-BUILD-01`
- [ ] Is the production `sourcemap` `"external"`, not `"inline"`? → `BUN-BUILD-06`
- [ ] Does the published library use `packages: "external"`? → `BUN-BUILD-05`
- [ ] `import.meta.hot.*` always in the full form? → `BUN-BUILD-08`
- [ ] Does production run AOT or `development: false`? → `BUN-BUILD-09`
- [ ] Does cross-compile declare `--target=bun-<os>-<arch>`? → `BUN-BUILD-10`
- [ ] Do macros receive only static values and return only serializable ones? → `BUN-BUILD-11`
- [ ] Is the plugin `filter` anchored? → `BUN-BUILD-07`
- [ ] Is there a `tsc --noEmit` in some CI step?

---

## Related

- [Bun](bun.md) — hub
- `Bun - HTTP e Servidor` · [Bun - Runtime and APIs](bun-runtime-and-apis.md) · [Bun - Package Manager](bun-package-manager.md) · `Bun - Dados e Persistência` · [Bun - Shell, FFI and Node Compat](bun-shell-ffi-and-node-compat.md) · [Bun - Tests](bun-tests.md)
- · `TypeScript` · `React.js` · `Next.js` · `Tailwind CSS`
- · `Github Actions`

## Sources consulted

Verified on **2026-08-15**:

- [Bundler](https://bun.com/docs/bundler) — full API, `target`, `format`, `splitting`, `minify`, `sourcemap`, `external`, `packages`, `define`, `loader`, `bytecode`
- [Fullstack dev server](https://bun.com/docs/bundler/fullstack) · [Hot reloading](https://bun.com/docs/bundler/hot-reloading) · [HTML & static sites](https://bun.com/docs/bundler/html-static)
- [Single-file executable](https://bun.com/docs/bundler/executables) · [Plugins](https://bun.com/docs/bundler/plugins) · [Macros](https://bun.com/docs/bundler/macros)
- [`bun build` (CLI)](https://bun.com/docs/cli/build) — `--react-fast-refresh`, `--react-compiler`
- [Build a React app with Bun](https://bun.com/docs/guides/ecosystem/react) — `bun init --react` template · [Vite with Bun](https://bun.com/docs/guides/ecosystem/vite) · [`bunx`](https://bun.com/docs/pm/cli/bunx) and [`bun run`](https://bun.com/docs/cli/run) — what `--bun` does
- [Environment variables](https://bun.com/docs/runtime/environment-variables) — why `--bun` turns off automatic `.env` loading
- Version: `https://registry.npmjs.org/bun/latest` → **1.3.14**

**Verification notes** — points where the source contradicts what is assumed by habit:

- **The fullstack dev server and the HMR API are declared *work in progress* in the docs themselves.** `import.meta.hot.invalidate()` and `.send()` appear as **not implemented**, and `.prune()` as partial (*"callback is currently never called"*).
- **`format: "cjs"` and `"iife"` are experimental**, and `cjs` changes the default `target` from `"browser"` to `"node"`.
- **A `#!/usr/bin/env bun` shebang in the entrypoint changes the default `target` to `"bun"`** — with no flag at all.
- **`target: "bun"` + `format: "cjs"` generates a CommonJS wrapper that the docs declare incompatible with Node.js.**
- **Macros are not marked as experimental**, contrary to what the feature's rarity suggests. The real restrictions are serialization and static arguments.
- **Macros run before plugins** — synchronous, in the transpiler's visit phase.
- **`--compile` does not accept `--outdir`, `--public-path`, `--target=node` nor `--no-bundle`**, but **does accept** `--splitting` and plugins.
- **`bytecode` in ESM requires `compile: true`**; in CommonJS it works on its own. Without an explicit `format`, it assumes CommonJS.
- **`sourcemap: "linked"` requires `outdir`**, and `"external"` adds a `debugId` to match bundle and map.
- **`--app` and the React Server Components flag (Bun Bake) are marked EXPERIMENTAL** in the CLI help.
- The docs state explicitly that **the bundler does not replace `tsc`** for typechecking or `.d.ts` generation.
- **There is a `--react-fast-refresh` flag** in `bun build`, described as *"for development testing"*. But **it was not verified** whether the `bun init --react` template turns it on, nor whether component state survives a hot update — the template docs say only "hot reloading", and the HMR page never claims preservation of React state. The only preservation mechanism it documents is `import.meta.hot.data`, manual and per module.
- **The recommendation to run Vite under `--bun` comes with no declared benefit.** The source describes only the mechanism: running the CLI on Bun's runtime instead of spawning a `node` process, with a `node` → Bun symlink on the `PATH` during execution. No number, no time comparison.
- **`--bun` turning off automatic `.env` loading is deliberate, not a regression.** The docs explain that it is Node parity so that Vite's `loadEnv` resolves `.env.{mode}` correctly instead of seeing values already populated by Bun. An explicit `--env-file` still applies.
