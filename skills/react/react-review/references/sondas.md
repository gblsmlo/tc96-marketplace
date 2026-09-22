# Probes — run before reading code

> A review that starts with linear reading finds what was on screen and misses what was
> in another file. The probes measure the whole repository in seconds and say
> **where to look**. They do not produce findings: a finding requires reading the passage and a `file:line`.

Ready-made script: `scripts/sondas.sh [target]` — runs all fifteen and prints the ID to cite in each block.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/react-review/scripts/sondas.sh src
```

Default target: `src`, or `.` when there is none. In the vault source the path is
`${CLAUDE_PLUGIN_ROOT}/skills/react-review/scripts/sondas.sh`.

---

## Probe 0 — environment (runs first, changes the verdict of the others)

```bash
rg -n '"react":|"react-dom":' package.json
rg -n 'babel-plugin-react-compiler|reactCompiler|react-compiler' package.json vite.config.* babel.config.* next.config.*
# the lint net: ESLint with the plugin, or Biome with the react domain switched on
rg -n 'react-hooks' package.json eslint.config.*.eslintrc*
rg -n 'domains|useHookAtTopLevel|useExhaustiveDependencies' biome.json*
rg -l 'StrictMode' src
```

Three direct consequences:

| Probe 0 finding | Consequence for the review |
| --- | --- |
| React Compiler **active** | manual memoization is redundant — `REACT-PERF-02` becomes a finding in itself |
| **lint net absent** | half of `REACT-HOOK-*` has no net: it is the **report's first finding** |
| `<StrictMode>` **absent** | purity breaks do not show up in dev — `REACT-DOM-06` in reverse |

Without probe 0, a review may report "a `useMemo` is missing here" in a project that compiles
memoization automatically. That is an invalid finding, and it discredits the rest of the report.

---

## The two forms of the net, and the one that fails silently

Probe 0 accepts **two** implementations of the same protection — and the second has a catch:

| Tool | What suffices | What misleads |
| --- | --- | --- |
| **ESLint** | `eslint-plugin-react-hooks` in the dependencies or in the config | — |
| **Biome** | `linter.domains.react` set to `"recommended"`/`"all"`, **or** `useHookAtTopLevel` and `useExhaustiveDependencies` declared | `recommended` switched on **is not enough**: the Hooks rules are recommended **within the react domain**, and without the domain they do not run |

The Biome case produces **neither error nor warning**: `biome lint` passes, the other recommended rules
fire normally, and the Hooks ones stay silent. The probe prints the fix alongside:

```jsonc
"linter": { "domains": { "react": "recommended" } }
```

How to confirm without trusting a read of the config — it is worth thirty seconds:

```bash
printf 'import {useState} from "react"\nexport function C({a}:{a:boolean}){\n if(a) return null\n const [x]=useState(0)\n return <div>{x}</div>\n}\n' > src/__probe.tsx
npx biome lint src/__probe.tsx # useHookAtTopLevel has to appear
rm src/__probe.tsx
```

---

## The fourteen code probes

| # | What it finds | Rule to cite | Typical false positive |
| --- | --- | --- | --- |
| 1 | `fetch`/`axios` inside a `useEffect` | `REACT-EFFECT-06`, `REACT-ASYNC-03` | legacy code explicitly marked; confirm whether it is new |
| 2 | a `useEffect` whose body starts with `set*` | `REACT-PAT-01` | an Effect that syncs with an external system and happens to start with `set` |
| 3 | `eslint-disable` on `exhaustive-deps` | `REACT-EFFECT-03` | — practically none |
| 4 | `useEffect(async …)` | `REACT-EFFECT-12` | — |
| 5 | `setX(x + 1)` without the updater form | `REACT-STATE-01` | a value that does not depend on the previous one (`setPage(1)` does not match) |
| 6 | an inventory of `useMemo`/`useCallback`/`memo` | `REACT-PERF-01` | none: **every** occurrence needs a measurement or the compiler |
| 7 | `key={i}` | [React - Patterns](../../../../knowledge-base/docs/react-patterns.md) § 8 | a static list, never reordered, with no state in the rows |
| 8 | `forwardRef` | `REACT-REF-03` | a third-party library re-exported |
| 9 | a `<Suspense>` with no Error Boundary in the same file | `REACT-ASYNC-08` | the boundary declared in the parent file — confirm by going up a level |
| 10 | `.push/.sort/.splice/.reverse` | `REACT-PURE-03`, `REACT-PURE-05` | a local array created in its own scope (`[...x].sort` is correct) |
| 11 | files with `'use client'` | `REACT-RSC-03` | none by itself — the finding is the **height** in the tree |
| 12 | `'use server'` with no apparent `parse`/`safeParse` | `REACT-RSC-06` | validation imported from another module; confirm by reading |
| 13 | `createRoot` × `hydrateRoot` | `REACT-DOM-01` | an app without SSR: `createRoot` is correct |
| 14 | `typeof window` | `REACT-DOM-03` | use outside the render (Effect, handler, module) |

**Probes 9, 11, 12 and 13 are about context, not pattern**: they list candidates whose
fix depends on looking at the parent file, the tree's topology or the SSR configuration.
Reporting straight from their output generates false positives.

---

## What the probes do **not** catch

Regex cannot see scope. These require reading, and they are precisely the highest-severity ones:

| Not detectable by a probe | Rule | How to find it |
| --- | --- | --- |
| a Hook after an early return, inside an `if`/loop/callback | `REACT-HOOK-01` | lint, or reading the top of each component |
| a component called as a function | `REACT-CALL-01` | reading; look for `Component(` with a capital letter |
| a Hook passed as a value | `REACT-CALL-02` | reading |
| state that should be in the URL | `REACT-PAT-10` | read the `useState` calls and ask: does it survive a refresh? |
| state lifted too high | `REACT-PAT-02` | read who consumes each piece of state |
| remote data in `useState` | `REACT-PAT-03` | cross-reference probe 1 with the `useState` calls in the same file |
| an expected error thrown to a boundary | `REACT-ASYNC-09` | read the `throw`s in actions and handlers |
| a boolean prop for a content variation | `REACT-PAT-04` | read the signatures of the larger components |

The practical order: probes first, to know **which files** to read; then
`grade-de-varredura.md` over those files, in the order that fails most.

---

## Related

- `grade-de-varredura.md` — the reading order after the probes
- `severidade-e-relatorio.md` — how to classify and write up what was found
- `mapa-de-ids.md` — where each ID is declared
