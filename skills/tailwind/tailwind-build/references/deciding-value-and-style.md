# Deciding the value and the style

Source: [Tailwind CSS](../../docs/tailwindcss.md) § 5.2–5.3 · bodies in [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) § 2–3 and [Tailwind CSS - Theme and Tokens](../../docs/tailwindcss-theme-and-tokens.md).

## Per value

```
Is the value known only at runtime (DB, API, user)?
├── YES → CSS variable in style + utility: style={{ '--c': x }} className="bg-(--c)"   (TW-UTIL-05)
└── NO
    ├── does a token have it? → the token's utility                                    (TW-THEME-04)
    ├── is it a design decision, or will it repeat? → token first (tailwind-setup), then use it (TW-UTIL-03)
    └── a one-place pixel adjustment → arbitrary value, once: top-[117px]
```

| Smell | It is really |
| --- | --- |
| `text-[#0f766e]` in two files | a brand token nobody declared |
| `p-[16px]` | `p-4` |
| `style={{ padding: 12 }}` | `p-3` — a static value has no business in `style` |
| `[display:flex]`, `[&:hover]:underline` | `flex`, `hover:underline` (`TW-UTIL-04`) |
| `bg-zinc-900` in `components/ui` | `bg-primary` (`TW-THEME-11`) |
| `bg-primary text-foreground` | `bg-primary text-primary-foreground` — the pair (`TW-THEME-12`) |

## Per class name — the scanner reads text

```tsx
// ✗ never generated: the scanner sees "bg-" and "-100"
<span className={`bg-${tone}-100 text-${tone}-800`} />

// ✓ the value maps to the complete string
const tone = { success: 'bg-success/15 text-success', danger: 'bg-destructive/15 text-destructive' } as const;
<span className={tone[status]} />
```

`TW-SRC-01`, `TW-SRC-02`. The defect sometimes "works" because another file uses the same class literally — and breaks when that file changes.

## Per style

```
Is it markup the project writes?
├── NO (widget, CMS, library) → @apply on the third party's selector          (TW-UTIL-07)
└── YES
    ├── a CSS property Tailwind has no utility for → @utility (tailwind-setup) (TW-UTIL-06)
    ├── repeated in more than one file → a React component                     (TW-COMP-01)
    │   └── varies by design (intent, size, density)? → cva/tv variant         (TW-COMP-06)
    └── local → utilities in className
```

`@apply` in the project's own CSS rebuilds the semantic class the utility removed, and tailwind-merge cannot see it.
