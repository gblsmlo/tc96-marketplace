---
nome: tailwind-build
descricao: Write the Tailwind classes of a new component, screen or variant — deciding where each value comes from (token, arbitrary, runtime variable) and where each style lives (utility, `@utility`, component, cva variant) before the first class, then states, responsiveness, container queries and accessibility, with an executable self-check before delivering, citing `TW-*` IDs — use when the task is styling a React component or page with Tailwind, building a design-system component with variants, composing `className` with `cn`/`clsx`, wiring a value that only exists at runtime, making a layout responsive, or adding focus, hover, dark and reduced-motion states. Do not use to install or configure Tailwind, which is tailwind-setup, nor to audit markup that already exists, which is tailwind-review.
tipo: skill
familia: tailwind
idioma: en
fonte: "[Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md)"
docs:
  - /tailwindlabs/tailwindcss.com
  - /dcastil/tailwind-merge
  - /joe-bell/cva
  - /shadcn-ui/ui
tags:
  - skill
  - tailwindcss
  - frontend
  - design-system
---

# tailwind-build

> **Source of this skill:** [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) and [Tailwind CSS - Components and Composition](../docs/tailwindcss-components-and-composition.md), with the [Tailwind CSS](../docs/tailwindcss.md) hub as the router.
> This skill **does not contain** the text of the rules — it says what to decide, in what order, and what to check before delivering.
> **API surface:** resolve it through Context7 — `/tailwindlabs/tailwindcss.com`, `/dcastil/tailwind-merge`, `/joe-bell/cva`. Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

Contract this skill implements: [Tailwind CSS](../docs/tailwindcss.md) § 7.

---

## When to use

Writing classes that **will exist**: a new component, a screen, a variant, a responsive layout, a state.

| Situation | Go to |
| --- | --- |
| Tailwind is not installed, a token does not exist yet, dark mode is not wired | `tailwind-setup` |
| reviewing markup that already exists | `tailwind-review` |
| the component's React structure — state, Hooks, where the file lives | `react-developer` · `react-structure` |
| the story for each variant | `storybook-story` |

---

## API lookups — Context7 first

**Context7 first.** Any API fact this skill needs — whether a utility exists, a directive's options, what changed in a version — comes from a Context7 query, not from memory and not from a docs URL. The knowledge base gives the **rule and the ID**; Context7 gives the **signature for the installed version**. If they disagree, the source wins and the note is a bug to report.

| Question | Context7 library | Topic to query |
| --- | --- | --- |
| does this utility or variant exist, and what does it emit? | `/tailwindlabs/tailwindcss.com` | the utility's own name (`outline-style`, `container queries`, `hover focus and other states`) |
| arbitrary values, `@utility`, `--value()` | `/tailwindlabs/tailwindcss.com` | `adding custom styles` |
| `cva` — variants, `compoundVariants`, `VariantProps` | `/joe-bell/cva` | `variants` |
| `twMerge`, `twJoin`, `extendTailwindMerge` | `/dcastil/tailwind-merge` | `configuration` · `when and how to use it` |
| a shadcn/ui component's anatomy and tokens | `/shadcn-ui/ui` | the component's name · `theming` |
| line 3 | `/websites/v3_tailwindcss` | the utility's name |

---

## Step 0 — The line

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/tailwind-setup/scripts/discover-line.sh | grep -e 'LINE' -e '->'
```

This skill writes for **line 4** (`TW-CORE-02`). On a project that stays on line 3 the class names and the config differ — use the v3 API surface and cite only the line-independent IDs (`TW-SRC-*`, `TW-UTIL-01`, `TW-A11Y-*`, `TW-COMP-*`). Note the entry stylesheet: it is where you check which tokens exist.

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Tailwind CSS](../docs/tailwindcss.md) § 2 and § 5.2–5.4 | the mental model, and the three trees: value, style, composition |
| 2 | [Tailwind CSS](../docs/tailwindcss.md) § 6 and § 6.1 | the invariants and the critical rules |
| 3 | [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) | no class exists without it |
| 4 | [Tailwind CSS - Components and Composition](../docs/tailwindcss-components-and-composition.md) | only for a **reusable** component, variants or `className` from outside |
| 5 | the **entry stylesheet** of the project | the tokens that exist — not the default palette |

**Never load Installation, Migration or Theme here** unless Step 1 sends you to `tailwind-setup`.
**To read a rule's text by ID** without opening its note: `bash ${CLAUDE_PLUGIN_ROOT}/skills/tailwind-review/scripts/rule.sh TW-THEME-05` (or a family, `TW-THEME`).


References in this skill:

| File | What for |
| --- | --- |
| `references/deciding-value-and-style.md` | the two questions per value and per style, with the trees |
| `references/states-and-responsiveness.md` | variants, mobile-first, container queries, the accessibility minimum |
| `references/composition.md` | `twJoin` × `cn`, cva, the `className` policy |
| `references/self-check.md` | the items and the three that are worth most |
| `references/antipatterns.md` | the grid, with IDs |
| `references/id-map.md` | the 77 `TW-*` by satellite and section |
| `references/example.md` | worked case, from the questions to the self-check |
| `scripts/self-check.sh` | runs the items over the file you just wrote |

---

## Step 1 — Read the tokens before the first class

Open the entry stylesheet and list what `@theme` declares: semantic colors, radius, spacing, fonts. **The component speaks in those names** — `bg-primary text-primary-foreground`, not `bg-zinc-900 text-white` (`TW-THEME-11`, `TW-THEME-12`).

If the design needs a value no token has and it is a **design decision** (it will repeat), the token is created first — that is `tailwind-setup`, Step 3 — and only then used (`TW-UTIL-03`).

---

## Step 2 — Two questions per value, one per style

`references/deciding-value-and-style.md`.

| Question | Answer → |
| --- | --- |
| does this value exist only at runtime? | CSS variable in `style` + `bg-(--x)` (`TW-UTIL-05`) |
| does it exist as a token? | the token's utility — **never** an arbitrary that duplicates it (`TW-THEME-04`) |
| does this style vary by design (intent, size)? | a cva/tv **variant** (`TW-COMP-06`), mapping to **complete** strings (`TW-SRC-01`, `TW-SRC-02`) |

**The rule that fails furthest from its cause:** a class name is never built by interpolation. `` `bg-${tone}-600` `` is never generated — and sometimes "works" because another file happens to use the class (`TW-SRC-01`).

---

## Step 3 — States, layout, accessibility

`references/states-and-responsiveness.md`: mobile is the **unprefixed** style (`TW-VAR-01`); a component reused at different widths answers to its **container** (`TW-VAR-03`); state already in `aria-*`/`data-*` is styled from the attribute (`TW-VAR-06`).

The accessibility minimum, every time: an outline removed has a `focus-visible:` replacement (`TW-A11Y-01`, `TW-A11Y-02`); an icon-only control has a name (`TW-A11Y-03`); motion respects `motion-reduce:` (`TW-A11Y-05`); nothing is reachable **only** through `hover:` (`TW-A11Y-08`).

---

## Step 4 — Compose

`references/composition.md`. Internal conditionals **join without merge** and are structured not to conflict (`TW-COMP-02`, `TW-UTIL-01`); `className` from outside goes through `cn`, **last** (`TW-COMP-03`); custom non-color tokens are registered in `extendTailwindMerge` (`TW-COMP-04`). `className` is for layout, not for redesigning the component (`TW-COMP-08`).

---

## Step 5 — Self-check, and render

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/tailwind-build/scripts/self-check.sh <file-or-dir>
```

`references/self-check.md`. Every ✗ compiles — that is why it is a script and not the build.

**Then render it, light and dark** — the story or the screen (`TW-CORE-04`). If there is no story for each variant, that is the next task (`storybook-story`).

---

## Example

A `StatusBadge` whose color comes from `status`: the first draft is `` `bg-${color}-100` ``. Step 2 turns it into a cva variant over semantic tokens; Step 3 adds `sr-only` text because the color alone carried the meaning; the self-check passes and the story shows both themes.

Full case: `references/example.md`.

---

## Related

- [Tailwind CSS - Utilities and Variants](../docs/tailwindcss-utilities-and-variants.md) — source of this skill
- [Tailwind CSS - Components and Composition](../docs/tailwindcss-components-and-composition.md)
- [Tailwind CSS](../docs/tailwindcss.md) § 2, § 5, § 6, § 7
- `tailwind-setup` · `tailwind-review` — the sibling skills
- `react-developer` — the component around the classes · `storybook-story` — one story per variant
