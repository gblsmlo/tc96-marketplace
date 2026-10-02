# Worked example

Task: *"a status badge for orders — paid, pending, failed — reusable across the app"*.

**Step 0 — the line:** `LINE: 4`, entry stylesheet `src/styles.css`.

**Step 1 — the tokens:** `@theme inline` maps `primary`, `muted`, `destructive`, `success`, `warning` (each with `-foreground`), declared in `:root` and `.dark`. No new token needed.

**Step 2 — the first draft, and why it is wrong:**

```tsx
const color = { paid: 'green', pending: 'amber', failed: 'red' }[status];
<span className={`bg-${color}-100 text-${color}-800 rounded-full px-2`}>{label}</span>
```

- `bg-${color}-100` is never generated — it "worked" in development because the order list page writes `bg-green-100` literally (`TW-SRC-01`);
- `green`, `amber`, `red` are raw palette in a design-system component (`TW-THEME-11`) — and in dark mode a `-100` background with `-800` text is unreadable.

Rewritten as a cva variant over semantic tokens, every value a complete string (`TW-SRC-02`, `TW-COMP-06`) — see `composition.md`.

**Step 3 — states:** the color carried the meaning alone; the label is already text, so it stays visible. The pending variant gets `motion-safe:animate-pulse` on its dot, not a bare `animate-pulse` (`TW-A11Y-05`).

**Step 4 — compose:** `cn(badge({ status }), className)` — `className` last; inside, no conditional class at all.

**Step 5 — self-check:**

```
 1. ✓ no class name built by interpolation
 2. ✓ no two utilities on the same property
 ...
 9. ✓ animation respects motion-reduce / motion-safe
10. ✓ className passed LAST to the merge
11. ✓ design-system component uses semantic tokens
```

Rendered `Paid`, `Pending`, `Failed` stories in light and dark; `Failed` in dark had `text-destructive` on `bg-destructive/15` with enough contrast. Delivered with the three stories (`storybook-story`).
