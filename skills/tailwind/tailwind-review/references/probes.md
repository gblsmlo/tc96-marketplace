# The eleven probes

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/tailwind-review/scripts/probes.sh [src-dir] [project-root]
```

| Probe | Looks for | IDs | Reading the output |
| --- | --- | --- | --- |
| S1 | line, integration, entry stylesheet, ignored config, dark wiring, shadcn/ui — through `discover-line.sh` | `TW-CORE-01`, `TW-CFG-*`, `TW-THEME-05/09/13/14` | every `->` is a candidate finding; `LINE` decides which IDs are valid |
| S2 | a class name built by interpolation | `TW-SRC-01` | each hit is a finding — confirm it is a class, not a URL |
| S3 | line-3 names and syntax; bare scale names | `TW-MIG-*`, `TW-CORE-02` | removed names are findings; **bare** `shadow`/`rounded` are valid v4 — a finding only if the author meant the v3 value |
| S4 | two utilities on the same property, same variants | `TW-UTIL-01` (element), `TW-COMP-02` (inside `cn`) | heuristic over a fixed table — a custom `@utility` may be missed |
| S5 | arbitrary values, counted; arbitrary properties that duplicate a utility | `TW-THEME-04`, `TW-UTIL-03`, `TW-UTIL-04` | count ≥ 2 = an undeclared token; count 1 is usually not a finding |
| S6 | `style` with a static value | `TW-UTIL-05` | a runtime value in `style` is **correct** — only static ones are findings. A static value **no utility covers** (`animationDelay`) is Low at most: the Tailwind form is an arbitrary property, `[animation-delay:160ms]` |
| S7 | `@apply` outside `@utility` and `@layer base` | `TW-UTIL-07` | on a third party's selector it is correct; the probe already skips the two allowed blocks |
| S8 | raw palette in `components/ui`/`packages/ui`; `dark:` count; tokens in `:root` missing in `.dark` | `TW-THEME-11`, `TW-THEME-06`, `TW-THEME-13` | a missing dark token is a finding even with no visible bug yet |
| S9 | `className` first in the merge; helpers; non-color tokens without `extendTailwindMerge` | `TW-COMP-03`, `TW-COMP-04`, `TW-COMP-05` | two `cn` definitions = `TW-COMP-05` |
| S10 | outline removed with no `focus-visible:`; `focus:` rings; animation with no `motion-*` | `TW-A11Y-01`, `TW-A11Y-02`, `TW-A11Y-05` | the outline grep is per line — a replacement on another line of the same `cva` base is fine; read it. **`outline-none` on an inner field whose wrapper draws the focus with `focus-within:` is the documented pattern, not a finding.** A `focus:` ring is **correct** when the browser floor is below Safari 15.4 (no `:focus-visible`). `animate-spin` is skipped: a progress indicator is essential motion |
| S11 | a utility class in a Playwright locator | `PW-LOC-01` | hand it to `playwright-review`, citing the ID |

Before reporting a S3 hit as "removed" or "renamed", confirm it with Context7 `/tailwindlabs/tailwindcss.com`, topic `upgrade guide`. On line 3, use `/websites/v3_tailwindcss` instead.

## The three mandatory stops

| Probe | Shows | Then |
| --- | --- | --- |
| S1 | `LINE: 3` | only `TW-SRC-01/02`, `TW-UTIL-01`, `TW-A11Y-*`, `TW-COMP-*` are findings; everything else goes to a **separate** migration recommendation |
| S1 | `LINE: MIXED` | the half-finished migration is the first finding, and it explains several others — report it before the markup |
| S1 | a `tailwind.config` nothing loads | every class depending on its values is dead — Blocking, and it re-reads S5 (the "arbitrary" colors may have been an attempt to work around it) |

## What the probes do not catch

- an **icon-only control** without a name (`TW-A11Y-03`) — read every `<button>`/`<a>` whose only child is an icon;
- **`sm:` meaning "mobile"** (`TW-VAR-01`) — it is valid syntax;
- information reachable **only through `hover:`** (`TW-A11Y-08`);
- a design variation passed through **`className`** at the call sites (`TW-COMP-06`);
- **contrast** — no grep sees color pairs; that is a rendered check (the Storybook a11y scan, `SB-TEST-04`);
- a missing **`@source`** for a package — S1 warns in monorepos, but only rendering proves the classes are absent.
