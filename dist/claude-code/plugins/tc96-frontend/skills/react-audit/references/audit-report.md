# Audit report template

Fill every section. An empty tier is written as "none", never deleted, so the reader can tell "checked and clean" from "not checked".

```markdown
# React audit — <app or package> — <date>

## Coverage
- Target: `<path>` · <n> source files · <n> components · <n> tests · <n> stories
- Probe sets run: review · structure · forms (or "skipped: no useForm") · re-render
- Sampled: <k> of <n> rows with hits, up to 3 occurrences each · Hotspots read in full: <files>
- Not covered: runtime performance, behavior without tests, APIs outside React.js § 4

## Environment and enforcement
| Item | State | Effect on this audit |
| --- | --- | --- |
| React version | 19.x | |
| React Compiler | off | memoization rows count |
| Lint net for Hooks | none / ESLint / Biome react domain | |
| Boundary rules | none / noRestrictedImports / noImportCycles | |
| `<StrictMode>` | absent / present | |
| Aliases | consistent / diverge in <file> | |

## Backlog

### Tier 0 — enforcement
1. **<gap>** — <one-sentence effect>. Fix: <exact config change>. Owner: `react-structure` / `react-review`.

### Tier 1 — Blocking
1. `REACT-HOOK-01` — confirmed 1/1 · `src/x.tsx:12` — <what>. Fix: <change>. Owner: `react-developer`. Lint-enforceable: yes (`useHookAtTopLevel`).

### Tier 2 — Systemic High
1. `REACT-EFFECT-06` — 4 hit lines, confirmed 2/2 in 2 files · `src/a.tsx:14` — <what>. Fix: move to a query (`tanstack-query`). Lint-enforceable: no.

### Tier 3 — Isolated High and forms
### Tier 4 — Medium

## Dropped as false positives
- forms#7 in `src/list.tsx` — `key={index}` outside `useFieldArray`; counted under the index-key antipattern instead.

## Suggestions (no rule)
- <observation without an ID, kept apart>

## Next three actions
1. <tier 0 item, when tier 0 is not empty>
2. <highest systemic item>
3. <next>
```

## Writing rules

- One item per **pattern**, not per occurrence. List extra files on the same line.
- Every item has a canonical ID from `id-map.md` or a doc section; without either it goes to "Suggestions (no rule)".
- Counts are always "hit lines" from the probe, and "confirmed k/m" from sampling. Never present a hit count as the number of defects.
- The owner is the skill that will carry the fix, so the backlog can be handed out as is.
