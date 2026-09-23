# Self-check, and the type-augmentation trap

**`tanstack-react` path only.** Under `react-vite` this section is inert.

TanStack Router asks for `declare module '@tanstack/react-router'` to register the router's type. If that augmentation lives in the app's `main.tsx` — the file that mounts the DOM — it **does not reach Storybook's TS program**, because `main.tsx` cannot enter that program.

**The fix:** separate the augmentation into its own module (`router.ts`), export it, and import it **as a type** wherever needed.

**The symptom, which does not point at the cause:** the router's types fall back to the generic one inside the stories, and `params` stops being checked against the path — which makes `SB-TS-02` catch nothing. Verified by sabotage in [Monorepo com Bun - estrutura e tooling](../../../../knowledge-base/monorepo-com-bun-estrutura-e-tooling.md) § 5.7.

---

## Step 7 — Self-check before delivering

| # | Check | Rule |
| --- | --- | --- |
| 1 | `framework` declared in `main.ts`, and the choice recorded | `SB-CFG-01` |
| 2 | the chosen framework's version floors are met | Step 1 |
| 3 | Node ≥ 20.19 / 22.12 — and ≥ 22 if Playwright is present | `SB-CORE-04` |
| 4 | `main.ts` is valid ESM, with no `require` | `SB-CORE-03` |
| 5 | every `@storybook/*` on the same version as `storybook` | `SB-CFG-04` |
| 6 | `stories` globs relative to `.storybook/` | `SB-CFG-02` |
| 7 | **the sidebar has the expected stories** | `SB-CFG-02` |
| 8 | alias/plugin/`define` declared once and inherited | `SB-CFG-06` |
| 9 | `apps/storybook` is a leaf — no package depends on it | `SB-CFG-07` |
| 10 | editable CSS imported in `preview.tsx` | `SB-CFG-03` |
| 11 | `staticDirs` covers the service worker, if MSW is present | `SB-CFG-05` |
| 12 | type augmentation in its own module (TanStack only) | Step 6 |
| 13 | no `SB-TS-*` prescribed under `react-vite`, and vice versa | § 6.2 of the hub |

**Run it:** start Storybook, open one story from each covered package, and confirm the alias resolves and the CSS applies. Only then Step 3.7.
