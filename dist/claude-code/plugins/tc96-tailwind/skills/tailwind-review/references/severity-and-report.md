# Severity and the report

## Classification

| Severity | Criterion | Typical IDs |
| --- | --- | --- |
| **Blocking** | the CSS **lies**: a class that is never generated, a config or token nobody loads, a toggle that does nothing, a half-finished migration | `TW-SRC-01`, `TW-SRC-03/04`, `TW-CFG-08`, `TW-THEME-09`, `LINE: MIXED` |
| **High** | a user is hurt **today**: keyboard focus gone, a control with no name, dark mode unreadable, content only on hover, conflicting utilities whose winner is accidental | `TW-A11Y-01/03/04/08`, `TW-THEME-13`, `TW-UTIL-01` |
| **Medium** | debt that breaks on the next change: raw palette in the design system, merge hiding a conflict, `className` first, repeated arbitraries, `@apply` components, v3 names that still compile | `TW-THEME-04/11`, `TW-COMP-02/03/04/06`, `TW-UTIL-03/05/07`, `TW-MIG-*` |
| **Low** | consistency: arbitrary property where a utility exists, a `!` important, a group without a name that does not nest yet | `TW-UTIL-02/04`, `TW-VAR-05` |

A † rule (decision of the note, not of the source) is never Blocking on its own.

## The finding format

**Blocking and High** get the full block:

```
[Severity] `ID` — file:line
What: the code, quoted.
Why: one sentence, in the rule's terms — not the rule's text.
Fix: the smallest change. If it is a configuration fix, say "tailwind-setup".
Evidence: the probe's output, when a probe found it.
```

Example:

```
[Blocking] `TW-SRC-01` — src/components/ui/badge.tsx:4
What: className={`bg-${tone}-100 text-${tone}-800 …`}
Why: the scanner reads text; bg-green-100 exists in the CSS only because order-list.tsx writes it literally.
Fix: map tone to complete strings — or a cva variant over semantic tokens (TW-SRC-02, TW-COMP-06).
Evidence: S2 → src/components/ui/badge.tsx:4
```

**Medium and Low** get one line — severity, ID, location, what, fix:

```
[Medium] `TW-COMP-03` — button.tsx:14 — `cn(className, button(…))`: the consumer can never override → `cn(button(…), className)`.
[Low] `TW-UTIL-04` — order-card.tsx:14 — `[display:flex]` → `flex`.
```

Group configuration findings and markup findings under two headings — the first are fixed once (`tailwind-setup`), the second file by file. Do not repeat the rule's text in a finding; `rule.sh` is where the reader gets it.

## The cut

**Not findings:**

1. class **order** (`TW-TOOL-02`);
2. an arbitrary value used **once** for a pixel adjustment;
3. a line-4 rule against a project that **stays** on line 3 — it goes to a separate "if you migrate" list;
4. the absence of a story or a visual test — that is a gap for `qa-engineer`, not a Tailwind finding.

## Closing

1. **Configuration first, then markup** — the first is fixed once (`tailwind-setup`), the second file by file (`tailwind-build`).
2. **Order by severity**, not by file.
3. **Turn probes into gates** where possible — IntelliSense `cssConflict` and `suggestCanonicalClasses`; a CI grep for `-\$\{` inside `className`.
4. **Declare what was not verified** — always the rendered result, light and dark (`TW-CORE-04`), and contrast.
