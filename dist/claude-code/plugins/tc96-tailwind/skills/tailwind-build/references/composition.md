# Composing classes

Source: [Tailwind CSS - Components and Composition](../../../docs/tailwind/tailwindcss-components-and-composition.md).

## Join × merge

| Classes come from… | Tool | ID |
| --- | --- | --- |
| inside the component only | `clsx` / `twJoin` — and structure the conditions so nothing conflicts | `TW-COMP-02`, `TW-UTIL-01` |
| inside + a `className` prop | `cn(…internal, className)` — **className last** | `TW-COMP-03` |

```tsx
// ✗ the merge hides the conflict
cn('p-4', compact && 'p-2')
// ✓ one class is emitted
cn(compact ? 'p-2' : 'p-4')
```

The project has **one** `cn`, imported from one place (`TW-COMP-05`). Custom tokens outside `--color-*` (`--text-display`, `--spacing-gutter`, `--radius-card`) are registered once in `extendTailwindMerge`, or `cn('text-lg', 'text-display')` keeps both (`TW-COMP-04`).

API surface for this file: Context7 `/dcastil/tailwind-merge` (topic `configuration`) and `/joe-bell/cva` (topic `variants`).

## Variants

```tsx
const badge = cva('inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium', {
  variants: {
    status: {
      paid: 'bg-success/15 text-success',
      pending: 'bg-warning/15 text-warning-foreground',
      failed: 'bg-destructive/15 text-destructive',
    },
  },
  defaultVariants: { status: 'pending' },
});

type BadgeProps = React.ComponentProps<'span'> & VariantProps<typeof badge>;

export function Badge({ className, status, ...props }: BadgeProps) {
  return <span className={cn(badge({ status }), className)} {...props} />;
}
```

- every variant value is a **complete** string — `TW-SRC-02` for free;
- cva does not merge — its output joins `className` through `cn` (`TW-COMP-07`);
- tailwind-variants merges by itself, has `slots` for multi-part components, and has **no** responsive variants on v4;
- `ref` is a prop (`REACT-REF-03`), native props are spread, `<button>` gets an explicit `type`;
- each variant is a story (`SB-CSF-04`).

## The `className` policy

`className` is for what the component cannot know — margin, width, grid placement. A design variation is a variant; relying on `className` to restyle focus, `disabled` or intent is `TW-COMP-08`.
