---
titulo: Tailwind CSS - Components and Composition
Link: https://tailwindcss.com/docs/styling-with-utility-classes#managing-duplication
tags:
  - tailwindcss
  - react
  - design-system
  - tooling
  - agent-context
source: "Official Tailwind CSS documentation — Styling with utility classes; tailwind-merge 3.7.0, clsx, cva, tailwind-variants, shadcn/ui, prettier-plugin-tailwindcss, Tailwind CSS IntelliSense, Biome"
verificado-em: 2026-10-02
---

# Tailwind CSS — Components and Composition

> Satellite of [Tailwind CSS](tailwindcss.md). Covers **how a React component carries classes**: reuse through components, conditional composition, declared variants, the `className` that comes from outside and the editor and formatter tools.
>
> **The distinction that organizes the note:** joining classes **that do not conflict** is concatenation; resolving classes **that conflict** is merge. They are two tools, with different costs, and using the second where the first was enough hides the defect that `TW-UTIL-01` forbids.

---

## 1. Reuse: the component is the unit

For style repeated in more than one file, the source recommends **creating a component** — and reserves your own CSS for the single element where a component "feels like overkill". The class string copied between files is the worst of the options: it changes in one, gets forgotten in the other.

The reusable component follows the contract of any React design system component — native props preserved, `ref` as a prop (`REACT-REF-03`), explicit `type` on `<button>`, focus and `disabled` intact — and lives in the generic layer (`components/ui`), with no feature vocabulary (`REACT-ARCH-06`, `Feature-Based Architecture`).

### 1.1 Rules — `TW-COMP-01`

| ID | Rule |
| --- | --- |
| `TW-COMP-01` | A set of classes repeated in more than one file **MUST** become a component. Copying the string between files **NEVER**. |

---

## 2. Concatenate × merge

### 2.1 The tools

| Tool | Does | Resolves conflict? | Size |
| --- | --- | --- | --- |
| `clsx` | joins strings, objects and arrays; drops falsy | **no** | 239 B |
| `twJoin` (tailwind-merge) | joins strings; drops falsy | **no** | — |
| `twMerge` | joins **and** removes the earlier conflicting class | **yes** | ~7 kB min+gz |
| `cn()` | `twMerge(clsx(…))` — the classic shadcn/ui helper | **yes** | — |
| `cn` package (shadcn-ui/cn 0.4) | replacement for clsx + tailwind-merge, same API, no dependencies | **yes** | — |

```ts
twMerge('px-2 py-1 bg-red hover:bg-dark-red', 'p-3 bg-[#B91C1C]');
// → 'hover:bg-dark-red p-3 bg-[#B91C1C]'   — the last conflicting one wins
```

The merge is **asymmetric**: `twMerge('pr-4 px-3')` gives `px-3`; `twMerge('px-3 pr-4')` keeps both, because `pr-4` refines `px-3` without cancelling it.

### 2.2 What the tailwind-merge doc itself says

> "Think of tailwind-merge as an **escape hatch** rather than the primary tool to handle style variants."

And the usage rule: classes **all defined inside the component** use `twJoin` (faster, easier to reason about); the main purpose of `twMerge` is **merging the `className` that comes from outside with the component's default classes** — and the `className` goes **last**.

```tsx
// ✓ internal condition: nothing conflicts, so concatenating is enough
const base = twJoin('inline-flex items-center rounded-md', disabled && 'opacity-50');

// ✓ boundary: the consumer can override
<button className={twMerge(base, className)} />
```

Using `cn` on every internal condition is accepting conflict inside the component and asking the library to hide it.

### 2.3 Configuring tailwind-merge on v4

tailwind-merge 3.x supports Tailwind v4.0 to v4.3 (for v3, 2.6). It knows the **default** theme; custom names in namespaces that are **not** color must be registered, or the merge gets it wrong silently:

```ts
import { extendTailwindMerge } from 'tailwind-merge';

export const twMerge = extendTailwindMerge({
  extend: { theme: { text: ['huge'], spacing: ['gutter'], radius: ['card'] } },
});
// without this: twMerge('text-lg text-huge') keeps both
```

Custom colors (`--color-*`) work without registration. Declared limitations: an arbitrary property does not merge with a utility (`p-4 [padding:1rem]` keeps both), an arbitrary variant does not merge with a default variant, and a class produced by `@apply` or your own CSS is invisible.

### 2.4 Rules — `TW-COMP-02` to `TW-COMP-05`

| ID | Rule |
| --- | --- |
| `TW-COMP-02` | Conditional classes **internal** to the component **MUST** be joined without merge (`clsx`, `twJoin`) and structured so they do not conflict. Merge to resolve an internal conflict **NEVER**. |
| `TW-COMP-03` | A `className` received from outside **MUST** go through `twMerge`/`cn`, **last**. |
| `TW-COMP-04` | A custom token in a namespace that is not color (`--text-*`, `--spacing-*`, `--radius-*`, `--shadow-*`…) **MUST** be registered in `extendTailwindMerge`. |
| `TW-COMP-05` | The project **MUST** have a single composition helper (`cn`), imported from one place only. † |

---

## 3. Declared variants: cva and tailwind-variants

**Design** variation (intent, size, density) is component API, not `className`. It is declared as a map from variant to full string — which satisfies `TW-SRC-02` for free:

```ts
import { cva, type VariantProps } from 'class-variance-authority';

export const button = cva('inline-flex items-center justify-center rounded-md font-medium', {
  variants: {
    intent: {
      primary: 'bg-primary text-primary-foreground hover:bg-primary/90',
      ghost: 'hover:bg-accent hover:text-accent-foreground',
    },
    size: { sm: 'h-8 px-3 text-sm', md: 'h-10 px-4' },
  },
  compoundVariants: [{ intent: 'primary', size: 'sm', class: 'font-semibold' }],
  defaultVariants: { intent: 'primary', size: 'md' },
});

type ButtonProps = React.ComponentProps<'button'> & VariantProps<typeof button>;

export function Button({ className, intent, size, type = 'button', ...props }: ButtonProps) {
  return <button type={type} className={cn(button({ intent, size }), className)} {...props} />;
}
```

| | cva | tailwind-variants |
| --- | --- | --- |
| version | 0.7.1 stable (1.0 in beta) | 3.3.1 |
| resolves conflict | **no** — the doc says to wrap it in `twMerge` | **yes**, built in (`cx` and `/lite` do not) |
| slots (multi-part component) | no | yes — `slots`, `compoundSlots` |
| responsive variants | — | **removed in v4** — write `md:` by hand |

tailwind-variants' own recommendation: if slots and built-in merge are not needed, cva.

### 3.1 `className` is extension, not redesign

An open `className` lets the consumer override anything — including the focus ring and the `disabled` state. The predictable policy: **design variation is a variant**; `className` is for what the component cannot know — margin, width, position in the parent's grid.

### 3.2 Rules — `TW-COMP-06` to `TW-COMP-08`

| ID | Rule |
| --- | --- |
| `TW-COMP-06` | A component with design variation **MUST** declare it as a variant (cva or tailwind-variants), with the derived type (`VariantProps`). Design variation passed through `className` **NEVER**. † |
| `TW-COMP-07` | `cva` output that is joined with `className` **MUST** go through merge — cva does not resolve conflicts. |
| `TW-COMP-08` | A design system component's `className` **MUST** be treated as a layout extension. Relying on it to redo focus, `disabled` or intent **NEVER**. † |

---

## 4. Editor and formatter tools

### 4.1 Class sorting

| Tool | Status on v4 | Reading |
| --- | --- | --- |
| `prettier-plugin-tailwindcss` 0.8.1 | official reference | on v4 it **requires** `tailwindStylesheet` pointing to the entry stylesheet; `tailwindFunctions: ['cn', 'cva', 'tv', 'clsx']` to sort inside the helpers; **last** in the plugin list |
| Biome `useSortedClasses` | **nursery**, **unsafe** fix, "partially implemented" | does not know v4's `@theme`, does not sort screen variants, does not know prefixes |

**This house's bridge:** the formatter is Biome (`scaffold-02-biome`), not Prettier. With Biome alone, class order is applied **partially** — and a nursery rule is not a CI gate. Class order is **readability**, not correctness: it does not change the result (§ 1 of [Tailwind CSS - Utilities and Variants](tailwindcss-utilities-and-variants.md) — the generated stylesheet decides).

### 4.2 IntelliSense

| Setting | What for |
| --- | --- |
| `tailwindCSS.classFunctions: ["cn", "cva", "tv", "clsx"]` | completion, hover and lint **inside** the helpers |
| `tailwindCSS.experimental.configFile` | on v4 points to the entry **CSS stylesheet**; in a monorepo, a stylesheet → glob map |
| `"files.associations": { "*.css": "tailwindcss" }` | recognize `@theme`, `@utility`, `@source` |
| lints `cssConflict`, `suggestCanonicalClasses`, `invalidApply` | `TW-UTIL-01`, `TW-UTIL-04`, `TW-CFG-06` in the editor |

`experimental.classRegex` is still accepted, but left the README; `classFunctions` is the documented form.

### 4.3 Rules — `TW-TOOL-01` to `TW-TOOL-03`

| ID | Rule |
| --- | --- |
| `TW-TOOL-01` | A project that uses `prettier-plugin-tailwindcss` on v4 **MUST** declare `tailwindStylesheet` and the project's helpers in `tailwindFunctions`, and the plugin **MUST** be the last one. |
| `TW-TOOL-02` | Class order is **NEVER** a blocking finding in review — it is readability. An order finding only fits where a sorter is configured and it did not run. † |
| `TW-TOOL-03` | The editor configuration **MUST** register the class helpers (`classFunctions`) and, in a monorepo, each app's stylesheet (`experimental.configFile`). † |

---

## 5. Antipatterns

### 5.1 `cn` on everything

`cn('px-4', compact && 'px-2')` inside the component "works" — and it is exactly the conflict `TW-UTIL-01` forbids, resolved by 7 kB of heuristics. The right condition emits a single class (`TW-COMP-02`).

### 5.2 `className` before the default

`twMerge(className, base)` lets the default beat the consumer. The `className` goes last (`TW-COMP-03`).

### 5.3 Variant through `className`

`<Button className="bg-destructive text-white" />` scattered across the app is a `destructive` variant nobody declared — no type, no hover, no coherent focus (`TW-COMP-06`).

### 5.4 Custom font-size token not registered in the merge

`--text-display` in `@theme`, and `cn('text-lg', 'text-display')` keeps both. The text comes out with whatever size the stylesheet generated last (`TW-COMP-04`).

### 5.5 Two `cn` in the project

One in `lib/utils.ts` with `twMerge(clsx())` and another from the `cn` package, or one with `extendTailwindMerge` and another without: the same component merges differently depending on the import (`TW-COMP-05`).

---

## Related

- [Tailwind CSS](tailwindcss.md) — hub
- [Tailwind CSS - Utilities and Variants](tailwindcss-utilities-and-variants.md) — the conflict the merge resolves, and why it should not exist inside the component
- [Tailwind CSS - Theme and Tokens](tailwindcss-theme-and-tokens.md) — the semantic tokens the variants use
- `React - Refs e DOM` — `ref` as a prop (`REACT-REF-03`)
- `React - Patterns` — composition instead of configuration
- `Feature-Based Architecture` — where the generic component lives
- `Storybook - Stories e Args` — each declared variant is a story (`SB-CSF-04`)

## Sources consulted

Verified directly on **2026-10-02**:

- [Styling with utility classes — Managing duplication](https://tailwindcss.com/docs/styling-with-utility-classes#managing-duplication)
- [tailwind-merge 3.7.0 — docs](https://github.com/dcastil/tailwind-merge/tree/tailwind-merge@3.7.0/packages/tailwind-merge/docs) — *When and how to use it*, *Configuration*, *Limitations*, *Recipes*
- [clsx](https://github.com/lukeed/clsx) · [shadcn-ui/cn](https://github.com/shadcn-ui/cn) · [shadcn/ui — Manual installation](https://ui.shadcn.com/docs/installation/manual)
- [cva](https://cva.style/docs) · [tailwind-variants](https://www.tailwind-variants.org)
- [prettier-plugin-tailwindcss 0.8.1](https://github.com/tailwindlabs/prettier-plugin-tailwindcss)
- [Tailwind CSS IntelliSense 0.16.0](https://github.com/tailwindlabs/tailwindcss-intellisense/blob/main/packages/vscode-tailwindcss/README.md)
- [Biome — useSortedClasses](https://biomejs.dev/linter/rules/use-sorted-classes/)

**Verification notes:**

- **shadcn/ui switched the helper:** the current manual installation installs the `cn` package and `lib/utils.ts` is `export { cn } from "cn"`. Not verified whether the CLI still generates `twMerge(clsx())` for older styles. The `cn` package's performance claims are the vendor's.
- **The cva 1.0 (beta) API** was not extracted; this note describes 0.7.1.
- **`TW-TOOL-02` is a decision of this note** — consistent with the source (the order in the attribute does not change the result) and with the nursery status of the Biome rule.
