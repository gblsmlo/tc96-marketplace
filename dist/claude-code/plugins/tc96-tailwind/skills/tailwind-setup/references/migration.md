# Migrating from line 3

Source: [Tailwind CSS - Migration v3 to v4](../../../docs/tailwind/tailwindcss-migration-v3-to-v4.md).

**The risk is not the build breaking — it is the build passing.** `shadow-sm` still compiles, smaller; `border` still compiles, another color.

## The sequence

1. Browser floor accepted (`TW-CFG-11`). If not — stay on 3.4 and stop here.
2. Clean branch, Node ≥ 20, `npx @tailwindcss/upgrade` (`TW-MIG-01`). With Bun: `bunx @tailwindcss/upgrade`.
3. **Read the whole diff.** The tool does not reach classes built by interpolation (`TW-SRC-01`) nor files it does not scan.
4. Grep the leftovers — `bash ${CLAUDE_PLUGIN_ROOT}/skills/tailwind-review/scripts/probes.sh`, probe S3.
5. **Decide each changed default** — table below (`TW-MIG-05`).
6. Integration: PostCSS → `@tailwindcss/vite` (`TW-CFG-01`); drop `autoprefixer`, `postcss-import` (`TW-CFG-02`).
7. Whatever is still in `tailwind.config` behind `@config` is the work list, not the end state (`TW-CFG-08`).
8. **Compare visually** — Storybook, `toHaveScreenshot`, or side by side. It is the only step that catches 5.

## The changed defaults — record a decision for each

| Default | v3 → v4 | Decision to record |
| --- | --- | --- |
| `border` color | gray-200 → `currentColor` | add explicit color where it mattered (`TW-MIG-06`), or restore in `@layer base` |
| `ring` | 3px blue-500 → 1px `currentColor` | `ring-3` + color where intended; restoring the color is "not idiomatic" per the source |
| placeholder | gray-400 → text at 50% | adopt, or restore in `@layer base` |
| `<button>` cursor | pointer → default | adopt (shadcn/ui did), or restore |
| `<dialog>` margin | auto → 0 | restore if dialogs were centered by it |
| `hover:` | always → only `@media (hover: hover)` | adopt — and fix anything reachable only by hover (`TW-A11Y-08`) |
| `space-*`/`divide-*` selector | top margin → bottom margin | prefer `flex flex-col gap-*` |

Each row is version-dependent: confirm it with Context7 `/tailwindlabs/tailwindcss.com`, topic `upgrade guide`, before restoring anything.

## The renames that move one step

`shadow-sm`→`shadow-xs` **before** `shadow`→`shadow-sm`; the same for `drop-shadow`, `blur`, `backdrop-blur`, `rounded` (`TW-MIG-02`). `outline-none` → `outline-hidden` (`TW-MIG-03`). `*-opacity-*` → `/NN` (`TW-MIG-04`). `@layer utilities` → `@utility` (`TW-MIG-07`). `bg-[--x]` → `bg-(--x)` (`TW-MIG-08`). Variants read left to right (`TW-VAR-07`).
