# Import scan — in the order that fails most

> Order from [Feature-Based Architecture](../../../../knowledge-base/feature-based-architecture.md) § 6 and § 4. Stop detailing a file when a
> finding invalidates the next one: if the **layer** is wrong, do not review its imports —
> report the layer change.

Script: `scripts/sondas-imports.sh [target]`, which runs the eight probes in the same order.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/react-structure/scripts/sondas-imports.sh src
```

---

## Probe 0 — enforcement (runs first)

`biome.json`, `noRestrictedImports`, `noImportCycles`, and the aliases in **all three** files.

| Probe 0 finding | Consequence |
| --- | --- |
| no `biome.json`, or none of the § 7 rules | the boundaries are convention: **the report's first finding**, because without it the report repeats in the next PR |
| an alias diverging between `tsconfig`, `vite.config`, `vitest.config` | "works in the build, breaks in the test" — § 2 and § 7 |
| a layer addressed through the barrel with no **wildcard-free** entry in `paths` | the bare import does not resolve |

---

## The order, and what each step catches

| # | What | ID | Probe |
| --- | --- | --- | --- |
| 1 | **Inverted direction** — generic importing `@features/`/`@routes/`; a feature importing `@routes/` | `REACT-ARCH-06`, `REACT-ARCH-07` | 1 |
| 2 | **Deep import** — `@features/x/...` with three segments or more | `REACT-ARCH-05` | 2 |
| 3 | **An own alias inside the feature** | `REACT-ARCH-04` | 3 |
| 4 | **Barrel** — a public surface that is too large, or logic in the `index.ts` | `REACT-ARCH-02`, `REACT-ARCH-03` | 4 |
| 5 | **Bloated route** — the bench test in § 4, not an impression | `REACT-ARCH-09` | 5 |
| 6 | **Placement** — a technical role where there should be a domain; premature extraction | `REACT-ARCH-01`, `REACT-ARCH-08` | — |
| 7 | **Convention** — `export type` in the barrel, kebab-case | `REACT-ARCH-11`, `REACT-ARCH-12` | 6, 7 |

**Do not report the same file twice with different IDs.** A domain inside `libs/`
already came out in step 1 as `REACT-ARCH-06`; it does not come back in step 6 as `REACT-ARCH-01`.

`REACT-ARCH-04` has **partial lint coverage** (§ 4): `noImportCycles` only catches it when the
import closes a cycle. The rest depends on this scan.

---

## What the probe does not catch

| Not detectable by regex | ID | How to find it |
| --- | --- | --- |
| a feature born from a **screen**, not from a capability | `REACT-ARCH-01` | read the folder's name and ask: is this product vocabulary? |
| extraction into the shared layer with fewer than three consumers | `REACT-ARCH-08` | count the module's importers in `features/core/` |
| a barrel exporting more than anyone consumes | `REACT-ARCH-02` | cross-reference the `index.ts` with whoever imports from it |
| a route that carries a journey instead of composing | `REACT-ARCH-09` | the bench test in § 4 |

---

## Finding format

The same format as the sibling skills, with this family's ID:

```
`RULE-ID` — file:line
<what is wrong, one sentence>
Fix: <concrete change>
See Feature-Based Architecture § <section>.
```

Severity comes from `mapa-de-ids.md` (the **Severity** column, normative in § 4) — **do not
reclassify**. Dependency direction beats aesthetics, always (§ 10, invariant 2).

**The cut:** an organizational preference with no ID is not a finding. There is an ID in § 4 → a finding.
It is an antipattern in § 6 with no ID → cite the **section**. Neither → "Suggestions (no
rule)", separately. Never invent a `REACT-ARCH-*`.

---

## Related

- [Feature-Based Architecture](../../../../knowledge-base/feature-based-architecture.md) § 4, § 6, § 7 — the source
- `arvore-de-colocacao.md` — deciding where to place, before auditing what is placed
- `mapa-de-ids.md` — severity and enforcement per ID
