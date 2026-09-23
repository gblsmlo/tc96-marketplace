# Self-check before delivering

> Three passes, in this order. None of them is optional, and the delivery does not go out with
> a caveat: if an item fails, fix it first.

---

## Pass 1 — the normative checklist

Ordered by failure frequency. It is the same one from § 5 of [React - Rules of React](../../../../knowledge-base/react-rules-of-react.md) —
open it when you need a rule's text.

- [ ] A Hook after an early return, inside an `if`, loop or callback? → `REACT-HOOK-01`
- [ ] `fetch`, `localStorage`, `Date.now`, `Math.random` or a log in the render body? → `REACT-PURE-01` / `REACT-PURE-02`
- [ ] Mutation of props or state (`push`, `sort`, `splice`, direct assignment)? → `REACT-PURE-03`
- [ ] A value mutated **after** it already went into the JSX? → `REACT-PURE-05`
- [ ] `setState(x + 1)` where the updater form was needed? → `REACT-STATE-01`
- [ ] A component called as a function (`Component(props)`)? → `REACT-CALL-01`
- [ ] A Hook passed as a value, or called from an ordinary function? → `REACT-CALL-02` / `REACT-HOOK-02`
- [ ] `ref.current` read or written in the render? → `REACT-REF-01`
- [ ] Any `eslint-disable` on `exhaustive-deps`? → `REACT-EFFECT-03` — it is almost always an Effect that should not exist

## Pass 2 — the habits table

Walk `habitos-de-ia.md` line by line and ask: **did the code avoid this habit?**
Sections 1 and 2 (state and effects) catch most of them; 6 and 7 only apply when the
code touches the server or extracts a Hook.

## Pass 3 — the three closing questions

1. Does every remaining `useState` answer "yes" to the state tree in [React.js](../../../../knowledge-base/react-js.md) § 5,
 or is one of them **derivable**, **remote** or **from the URL**?
2. Does every remaining `useEffect` synchronize with a **concrete, nameable** external system?
 Write the name. If no name comes out, the Effect should not exist.
3. Does every remaining memoization have a **measurement** behind it — or an active React Compiler making it
 redundant?

---

## Executable probes

They run against what you just wrote. They do not replace the passes above — they point
at where to look. `$ALVO` is the file or directory touched.

```bash
# 1. A fetch inside an Effect (REACT-EFFECT-06)
rg -nU --type-add 'rx:*.{ts,tsx}' -trx 'useEffect\((?s:.{0,400}?)\b(fetch|axios)\s*[\(\.]' "$ALVO"

# 2. State derived through an Effect: set* as the Effect's first thing (REACT-PAT-01)
rg -nU --type-add 'rx:*.{ts,tsx}' -trx 'useEffect\(\s*\(\)\s*=>\s*\{\s*set[A-Z]' "$ALVO"

# 3. An Effect with an async callback (REACT-EFFECT-12)
rg -n --type-add 'rx:*.{ts,tsx}' -trx 'useEffect\(\s*async' "$ALVO"

# 4. exhaustive-deps silenced (REACT-EFFECT-03)
rg -n 'eslint-disable.*exhaustive-deps' "$ALVO"

# 5. setState without the updater where the previous value matters (REACT-STATE-01)
rg -n --type-add 'rx:*.{ts,tsx}' -trx 'set[A-Z]\w*\(\s*\w+\s*[-+]\s*1\s*\)' "$ALVO"

# 6. index as a key (antipattern from Patterns § 8)
rg -n --type-add 'rx:*.{ts,tsx}' -trx 'key=\{\s*(i|idx|index)\s*\}' "$ALVO"

# 7. forwardRef in new code (REACT-REF-03)
rg -n --type-add 'rx:*.{ts,tsx}' -trx '\bforwardRef\b' "$ALVO"

# 8. Memoization — count before justifying (REACT-PERF-01)
rg -c --type-add 'rx:*.{ts,tsx}' -trx '\buseMemo\(|\buseCallback\(|\bmemo\(' "$ALVO"

# 9. 'use client' and how high it sits (REACT-RSC-03)
rg -l --sort path --type-add 'rx:*.{ts,tsx}' -trx "^['\"]use client['\"]" "$ALVO"

# 10. Suspense with no Error Boundary in the same file (REACT-ASYNC-08)
rg -l --type-add 'rx:*.{ts,tsx}' -trx '<Suspense' "$ALVO" | xargs -I{} sh -c 'rg -q "ErrorBoundary|errorElement" "{}" || echo "no boundary: {}"'
```

Probe 8 has no fixed threshold: **every** occurrence needs an answer to question 3
of Pass 3. Probe 9 is a reading, not a verdict — what matters is whether there is anything above
the boundary that could have stayed on the server.

---

## Before the first line, not after

Two environment checks that change the code you are about to write:

```bash
# React Compiler active? It changes the whole memoization decision (REACT-PERF-02)
rg -n 'babel-plugin-react-compiler|reactCompiler|react-compiler' package.json vite.config.* babel.config.* 2>/dev/null

# a lint net? ESLint with the plugin, OR Biome with the react domain switched on
rg -n 'react-hooks' package.json eslint.config.*.eslintrc* 2>/dev/null
rg -n 'domains|useHookAtTopLevel|useExhaustiveDependencies' biome.json* 2>/dev/null
```

A project with no lint net is not a reason to skip Pass 1 — it is a reason to **mention the
absence** in the delivery.

**In a Biome project, check the domain.** The Hooks rules (`useHookAtTopLevel`,
`useExhaustiveDependencies`) are recommended **within the `react` domain**: with `preset`/`recommended`
on and the domain off, they **do not run** — with no error and no warning. The fix is
`"linter": { "domains": { "react": "recommended" } }`.

---

## Related

- [React - Rules of React](../../../../knowledge-base/react-rules-of-react.md) § 5 — the normative checklist, with the rules' text
- `habitos-de-ia.md` — the second pass
- `mapa-de-ids.md` — where each ID is declared
