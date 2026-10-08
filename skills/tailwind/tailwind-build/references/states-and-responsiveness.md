# States, responsiveness and the accessibility minimum

Source: [Tailwind CSS - Utilities and Variants](../../docs/tailwindcss-utilities-and-variants.md) § 4–6.

Whether a variant exists in the installed version is a Context7 question: `/tailwindlabs/tailwindcss.com`, topic `hover focus and other states` or `responsive design`.

## Responsive

| Write | Not |
| --- | --- |
| `text-center sm:text-left` — mobile unprefixed, override upward | `sm:text-center` "for mobile" (`TW-VAR-01`) |
| `md:max-lg:flex` for a range | two classes fighting at the same breakpoint |
| `@container` + `@md:flex-row` when the component lives at several widths | `md:` on a card that sits in a sidebar and in a grid (`TW-VAR-03`) |

## State

| Situation | Variant |
| --- | --- |
| state already in `aria-expanded`, `aria-selected`, `data-state` (Radix, shadcn/ui) | `aria-expanded:rotate-180`, `data-[state=open]:` — no parallel `is-open` class (`TW-VAR-06`) |
| style from a sibling | `peer` **before** it in the DOM; otherwise `has-*` on the parent (`TW-VAR-04`) |
| nested hover cards | `group/card` + `group-hover/card:` (`TW-VAR-05`) |
| error message on a field | `user-invalid:` — fires after interaction, not on load |
| stacked variants | read left to right: `dark:md:hover:bg-x`, `*:first:pt-0` (`TW-VAR-07`) |

## The accessibility minimum — every component

| Check | Write | ID |
| --- | --- | --- |
| an outline removed has a replacement | `outline-hidden focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-ring` | `TW-A11Y-01` |
| focus ring for keyboard, not click | `focus-visible:`, not `focus:` — **unless** the browser floor is below Safari 15.4 (a line-3 project): then `focus:` | `TW-A11Y-02` |
| icon-only control has a name | `<span className="sr-only">Close</span>` or `aria-label` | `TW-A11Y-03` |
| visually hidden but read | `sr-only`, never `hidden`/`invisible` | `TW-A11Y-04` |
| motion | `motion-safe:animate-spin` or `motion-reduce:animate-none` | `TW-A11Y-05` |
| custom control with `appearance-none` | `forced-colors:appearance-auto` | `TW-A11Y-06` |
| a real list styled without markers | `role="list"` | `TW-A11Y-07` |
| hover | an enhancement only — on v4 it does not fire on touch | `TW-A11Y-08` |

Color is never the only carrier of meaning: a status badge has text, not just a hue.
