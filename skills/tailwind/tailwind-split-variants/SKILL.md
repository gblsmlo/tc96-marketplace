---
name: tailwind-split-variants
description: Split cva/tv variants out of a component into a sibling .variants.ts file
type: skill
family: tailwind
language: en
source: "`Tailwind CSS - Components and Composition` § 3 (tailwind-build)"
docs:
  - /joe-bell/cva
  - /tailwindlabs/tailwindcss.com
tags:
  - skill
  - tailwindcss
  - frontend
  - design-system
---

# tailwind-split-variants

Keeps a component's styles in their own file: `button.tsx` renders, `button.variants.ts` holds the `cva`/`tv` declarations, the class constants they use and the `VariantProps` type. Writing a new component's classes is `tailwind-build`; auditing them is `tailwind-review`.

Use it when the project already keeps variants apart, or when the user asks for it. A project whose convention is inline variants stays inline unless the user says otherwise.

## 1. Detect the convention

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/skills/tailwind-split-variants/scripts/split-variants.py detect <src-dir>
```

Prints `CONVENTION: variants|styles`, whether it was found or is the default, and every component that still declares `cva`/`tv` inline. Follow what exists: `*.styles.ts` → `--suffix styles`; variants inside a component folder (`button/button.variants.ts`) → the sibling rule already lands there. With nothing found, the default is a sibling `<name>.variants.ts`.

## 2. Split: dry run, then write

```bash
python3 ${CLAUDE_PLUGIN_ROOT}/skills/tailwind-split-variants/scripts/split-variants.py split <file-or-dir> [--suffix styles]
python3 ${CLAUDE_PLUGIN_ROOT}/skills/tailwind-split-variants/scripts/split-variants.py split <file-or-dir> --write
```

The script does the mechanical part, so do not move code by hand:

- moves every top-level `const x = cva(…)`/`tv(…)` and its `type … = VariantProps<typeof x>`, exported;
- moves the top-level constants those calls use, and every top-level class-string constant; the ones the component still uses are imported back;
- creates `XVariants = VariantProps<typeof x>` (`XStyles` under `--suffix styles`) when none existed and replaces `VariantProps<typeof x>` in the component with it;
- moves the `cva`/`tv`/`VariantProps` imports, drops the ones the component no longer uses, and adds one `import { x, type XVariants } from './name.variants'`;
- keeps every name the component exported available from the component (`export { buttonVariants } from './button.variants'`), so `@/components/ui/button` importers and the shadcn/ui layout keep working;
- refuses to overwrite an existing variants file.

It reports, and leaves to you: a `cva`/`tv` declared **inside a function** (hoist it to top level, named the way the convention names it, e.g. `alertVariants`, then rerun) and anything it could not classify. A hand-typed prop that duplicates a variant (`intent?: 'info' | 'warning'`) can then come from the generated type.

## 3. Rules the split must keep

- The variants file holds only `cva`/`tv` calls, their types and class constants: no React import, no JSX, no import from its own component (cycle).
- Every class is a complete literal (`TW-SRC-01`, `TW-SRC-02`). Composing complete constants, `` `${base} ${focus}` ``, is fine; gluing a fragment to a name, `` `bg-${tone}` ``, is not.
- The component composes `cn(xVariants({ … }), className)`, `className` last (`TW-COMP-03`); `cva` does not merge on its own (`TW-COMP-07`).
- This is a pure move: no class changes. Fixing a class you notice is a separate step, with its ID, after the split.

Two project settings can make the new `.ts` files second-class (rule text: `grep -h 'TW-SRC-04\|TW-TOOL-03' references/rules.md`):

- variants in a package outside the app (`packages/ui`) need `@source` in the app's stylesheet (`TW-SRC-04`);
- IntelliSense completes classes in a `.ts` file only through `tailwindCSS.classFunctions: ["cva", "tv", "cn"]` (`TW-TOOL-03`).

## 4. Verify and close

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/tailwind-split-variants/scripts/self-check.sh <file-or-dir>
```

Then `tsc --noEmit` (or the project's `typecheck` script) when dependencies are installed; if they are not, say so. Report: files created, names re-exported, anything moved by hand, and what was not verified.
