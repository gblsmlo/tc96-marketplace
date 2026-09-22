# The sequence, and where the Vite config is inherited from

The official docs document each piece in isolation and **never the order**. For a monorepo starting from scratch:

| # | Step | Reference |
| --- | --- | --- |
| 1 | create `apps/storybook` with its own `package.json`, declared in the workspace | `Docs/Bun - Gerenciador de Pacotes.md` |
| 2 | install the framework and addons, **all on the same version** | `SB-CFG-04` |
| 3 | create `apps/storybook/vite.config.ts` inheriting the shared base | Step 4 |
| 4 | write `main.ts` with `framework`, `stories`, `addons` | `SB-CFG-01`, `SB-CFG-02` |
| 5 | write `preview.tsx` with global CSS, providers, project parameters | `SB-CFG-03` |
| 6 | **start it and check the sidebar** | `SB-CFG-02` |
| 7 | only then turn on the runner | [Storybook - Testes e Interações](../../../../knowledge-base/docs/storybook-testes-e-interacoes.md) § 4 |

**Step 6 before step 7 is deliberate:** debugging a glob and a runner at the same time costs double. And a glob that does not match **raises no error** — it gives an empty sidebar, which is this skill's most confusing symptom.

**Versions in lockstep:** every `@storybook/*` package on the same version as the `storybook` package (`SB-CFG-04`). Divergence is an install bug, not a choice — the packages publish together.

**`stories` globs are relative to `.storybook/`**, not to the package root (`SB-CFG-02`). It is the #1 cause of an empty sidebar.

---

## Step 4 — Where the Vite config is inherited from

In a single app the answer is obvious: the project's own `vite.config.ts`.

**In a monorepo with a separate `apps/storybook`, there is no "the project's config"** — the stories come from `packages/ui` and from `apps/web`, and Storybook lives in a fourth package with no Vite config at all. This is not hypothetical: the `vitest.config.ts` the runner requires does `import viteConfig from './vite.config'`, and that file has to exist in `apps/storybook`.

The way out that keeps `SB-CFG-06` satisfiable is to **extract the base into `packages/config`** — the package that already exists for `tsconfig` and Biome — and import it in all three places:

```ts
// packages/config/vite.base.ts
import type { UserConfig } from 'vite';
export const baseConfig: UserConfig = {
 resolve: { alias: { /* … */ } },
 plugins: [ /* … */ ],
};
```

```ts
// apps/storybook/vite.config.ts
import { defineConfig } from 'vite';
import { baseConfig } from '@scope/config/vite.base';
export default defineConfig(baseConfig);
```

Alias, plugin and `define` declared **once**, inherited by `apps/web`, `apps/storybook` and by the `vitest.config.ts` (`SB-CFG-06`).

> **This arrangement is the vault's decision, not the source's.** The 2026-08-19 review found that `SB-CFG-06` was **impossible to follow** in the layout the docs themselves prescribe. See [Storybook - Pendências de revisão](../../../../knowledge-base/docs/storybook-pendencias-de-revisao.md).

**`viteFinal` is almost never needed.** If you are reaching through it for something the base should already give, the problem is the inheritance in Step 4 — not the hook.

**And `apps/storybook` stays a leaf of the graph:** no package depends on it (`SB-CFG-07`). It consumes; it is not consumed.

---

## Step 5 — Styling and theming

| Where | What | Rule |
| --- | --- | --- |
| `preview.tsx` | global CSS you intend to edit | `SB-CFG-03` |
| a global decorator | theme, providers | `SB-CTX-03` |
| `staticDirs` | the service worker's directory, if MSW is in use | `SB-CFG-05` |

**`preview-head.html` is not for CSS** you intend to edit (`SB-CFG-03`) — CSS imported in `preview.tsx` takes part in Vite's HMR; injected into the head, it does not.

**A theme is not configured in `main.ts`.** It is a global decorator, and it applies to the stories, not to Storybook's own UI.
