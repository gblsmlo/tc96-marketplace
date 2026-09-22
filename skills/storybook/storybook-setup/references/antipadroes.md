# Antipatterns, with IDs

> `SB-TS-*` and `SB-RV-*` are **mutually exclusive** — check the path before citing.

| Antipattern | ID | Satellite |
| --- | --- | --- |
| Choosing the framework by inertia, without checking the floors | § 5.1 of the hub | [Storybook](../../../../knowledge-base/docs/storybook.md) |
| Adopting `tanstack-react` on Vite 5 or 6 | Step 1 | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| Prescribing `SB-TS-*` under `react-vite`, or the reverse | § 6.2 of the hub | [Storybook](../../../../knowledge-base/docs/storybook.md) |
| `main.ts` with `require` | `SB-CORE-03` | [Storybook](../../../../knowledge-base/docs/storybook.md) |
| Node below 20.19 / 22.12 | `SB-CORE-04` | [Storybook](../../../../knowledge-base/docs/storybook.md) |
| `framework` absent or implicit | `SB-CFG-01` | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| A glob relative to the package root instead of `.storybook/` | `SB-CFG-02` | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| A glob pointing at `dist` | § 5.2 of the satellite | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| Misaligned versions across Storybook packages | `SB-CFG-04` | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| Configuring the theme in `main.ts` | § 5.1 of the satellite | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| Editable CSS in `preview-head.html` | `SB-CFG-03` | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| `staticDirs` without the service worker, with MSW in use | `SB-CFG-05` | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| Duplicating the Vite config in each package | `SB-CFG-06` | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| Reaching through `viteFinal` for what the base should give | § 3 of the satellite | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| Treating `apps/storybook` as a consumable package | `SB-CFG-07` | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| Type augmentation inside `main.tsx` | Step 6 | [Monorepo com Bun - estrutura e tooling](../../../../knowledge-base/pages/monorepo-com-bun-estrutura-e-tooling.md) |
| Turning on the runner before the sidebar shows stories | Step 3.6 | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| A provider repeated per file instead of a global decorator | `SB-CTX-03` | [Storybook - Decorators e Contexto](../../../../knowledge-base/docs/storybook-decorators-e-contexto.md) |

