# Worked example

Task: *"install Storybook in the monorepo — `packages/ui` and `apps/web`, which is on React 19 and Vite 7"*.

**Step 1 — the framework.** `apps/web` has pages importing `Link` from `@tanstack/react-router`, and a single Storybook covers both packages. React 19 ≥ 18 ✓, Vite 7 ≥ 7 ✓ → **`@storybook/tanstack-react`**, path A, family `SB-TS-*`. Recorded.

**Step 2 — platform.** Node 22.12 (required anyway by addon-vitest's Playwright). ESM confirmed.

**Steps 3 and 4 — the files:**

```ts
// apps/storybook/.storybook/main.ts
import type { StorybookConfig } from '@storybook/tanstack-react';

const config: StorybookConfig = {
 framework: { name: '@storybook/tanstack-react', options: {} },
 stories: [
 '../../../packages/ui/src/**/*.stories.@(ts|tsx)',
 '../../../apps/web/src/**/*.stories.@(ts|tsx)',
 ],
 addons: ['@storybook/addon-docs', '@storybook/addon-a11y'],
};
export default config;
```

```ts
// apps/storybook/vite.config.ts — the inheritance from Step 4
import { defineConfig } from 'vite';
import { baseConfig } from '@scope/config/vite.base';
export default defineConfig(baseConfig);
```

**What each decision prevented:**

| Decision | Alternative that hurts | Rule |
| --- | --- | --- |
| `tanstack-react` decided by the most demanding package | choosing by `packages/ui` and finding out later that `apps/web` needs routing | § 5.1 of the hub |
| globs with `../../../` from `.storybook/` | globs from the package root — an empty sidebar, with no error | `SB-CFG-02` |
| `vite.config.ts` inheriting from `packages/config` | duplicating the alias in three places, diverging on the first adjustment | `SB-CFG-06` |
| versions in lockstep in `package.json` | `addon-docs` on a different minor | `SB-CFG-04` |
| `staticDirs` declared | MSW without a served service worker, and a mock that fails silently | `SB-CFG-05` |
| the augmentation in `router.ts` | generic router types in the stories, and `SB-TS-02` inert | Step 6 |
| the runner **after** a green sidebar | debugging the glob and the runner together | Step 3.6 |

**The step nobody documents and that pays most:** start it and look at the sidebar before turning on the runner. An empty sidebar with the runner on produces "0 tests passed" — which is green, and means nothing.
