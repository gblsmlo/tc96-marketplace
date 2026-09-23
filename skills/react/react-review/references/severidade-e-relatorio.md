# Severity, finding format and the finding × opinion cut

---

## Classification

Normative precedence, from [React.js](../../../../knowledge-base/react-js.md) § 7 (invariant 3) and [React - Rules of React](../../../../knowledge-base/react-rules-of-react.md) § 6.

| Severity | What goes in | Why |
| --- | --- | --- |
| **Blocking** | `REACT-PURE-*`, `REACT-CALL-*`, `REACT-HOOK-*` | it breaks React's contract; it is not negotiated for concision or style |
| **High** | the critical rules in [React.js](../../../../knowledge-base/react-js.md) § 6.1 — `REACT-EFFECT-06`, `REACT-PAT-03`, `REACT-ASYNC-08`, `REACT-RSC-06`, `REACT-DOM-01`… | a latent bug: a race condition, a white screen, an endpoint with no authorization |
| **Medium** | the other `REACT-*` from the satellite (structure, performance, forms, refs) | fixable in the same PR |
| **Low** | preference without an ID | **not a finding** — see the cut, below |

A `REACT-PURE-*` or `REACT-HOOK-*` violation takes precedence over any aesthetic
preference. Do not propose a cosmetic refactor on top of code that violates purity — report
the violation first.

---

## A finding's format

Four parts, always. The format comes from [React.js](../../../../knowledge-base/react-js.md) § 7 ("Como citar").

```
`RULE-ID` — file:line
<what is wrong, one sentence>
Fix: <concrete change, not generic advice>
See the corresponding satellite.
```

A real example:

```
`REACT-PAT-01` — src/features/cart/Cart.tsx:24
`total` is kept in useState and synchronized through a useEffect from `items`.
Fix: remove the state and the Effect; compute `const total = items.reduce(...)` in the render.
See React - Patterns.
```

Rules of the format:

- **Canonical ID required.** Check `mapa-de-ids.md` before writing the ID. The aliases
 (`REACT-STATE-03`, `REACT-EFFECT-04`, `REACT-PAT-07`, `REACT-FORM-03`, `REACT-PAT-08`,
 `REACT-PAT-09`, `REACT-FORM-08`, `REACT-STATE-02`) exist so the satellites can stand
 on their own and **must not appear in a review**.
- **`file:line` always.** A finding with no location is not actionable.
- **A concrete fix.** "Consider refactoring" is not a fix; "move the call into the `onSubmit`
 handler" is.
- **One satellite link**, so whoever fixes it can read the reasoning without the review paraphrasing it.

---

## The cut: finding × opinion

**A finding without a rule ID is an opinion, not a finding.**

Before reporting, check whether an ID exists in [React.js](../../../../knowledge-base/react-js.md) § 6, § 6.1, § 6.2, in `mapa-de-ids.md`
or in the satellite's family. Three ways out:

1. **There is an ID** → it is a finding. Cite the canonical one.
2. **There is no ID, but it is a documented antipattern** (`index` as a `key`, Context with frequent
 writes — both in [React - Patterns](../../../../knowledge-base/react-patterns.md) § 8) → report it citing the **section**, never an
 invented ID: "antipattern from [React - Patterns](../../../../knowledge-base/react-patterns.md) § 8".
3. **There is neither ID nor section** → it is your preference. Either it stays out of the report, or it goes in a
 separate section labeled **"Suggestions (no rule)"**, never mixed with the findings.

**Never invent an ID.** If an API does not appear in [React.js](../../../../knowledge-base/react-js.md) § 4, it has not been verified in this
doc: consult react.dev, **declare the limitation** and propose updating the note — do not assert
behavior ([React.js](../../../../knowledge-base/react-js.md) § 7, invariant 1).

---

## The report's structure

```markdown
## React review — <target>

**Environment** (probe 0): react <version> · React Compiler <active|absent> ·
lint net <ESLint|Biome+react domain|ABSENT> · StrictMode <ok|absent>

### Blocking (n)
<findings>

### High (n)
<findings>

### Medium (n)
<findings>

### Suggestions (no rule)
<preferences, kept separate>

### Not verified
<APIs outside React.js § 4, files not read, what the probe does not cover>
```

Four closing obligations:

1. **Automate what you can.** The net is `eslint-plugin-react-hooks` **or** Biome's `react`
 domain (`linter.domains.react`); `<StrictMode>` reveals purity breaks in development.
 If the project has neither, that is the **report's first finding** — and with
 Biome it is worth actually checking: `preset: recommended` does not enable the Hooks rules.
2. **Check whether the stack already solves it.** Before suggesting the raw primitive, check the bridges in
 [React.js](../../../../knowledge-base/react-js.md) § 8 — remote data is `tanstack-query`, URL state is `tanstack-router`.
3. **Order by severity**, not by file order.
4. **Declare what was not verified.** Silence about an unread file is read as approval.

---

## Related

- `sondas.md` — what to run first
- `grade-de-varredura.md` — the reading order
- `mapa-de-ids.md` — canonicals and aliases
- `exemplos/relatorio-de-pr.md` — a whole worked report
