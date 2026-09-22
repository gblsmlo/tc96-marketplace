# Exemplo trabalhado

Tarefa: *"instalar Storybook no monorepo — `packages/ui` e `apps/web`, que está em React 19 e Vite 7"*.

**Passo 1 — o framework.** `apps/web` tem páginas que importam `Link` de `@tanstack/react-router`, e um Storybook único cobre os dois pacotes. React 19 ≥ 18 ✓, Vite 7 ≥ 7 ✓ → **`@storybook/tanstack-react`**, caminho A, família `SB-TS-*`. Registrado.

**Passo 2 — plataforma.** Node 22.12 (exigido de qualquer forma pelo Playwright do addon-vitest). ESM confirmado.

**Passos 3 e 4 — os arquivos:**

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
 staticDirs: ['../public'],
};
export default config;
```

```ts
// apps/storybook/vite.config.ts — a herança do Passo 4
import { defineConfig } from 'vite';
import { baseConfig } from '@escopo/config/vite.base';
export default defineConfig(baseConfig);
```

**O que cada decisão evitou:**

| Decisão | Alternativa que dói | Regra |
| --- | --- | --- |
| `tanstack-react` decidido pelo pacote mais exigente | escolher por `packages/ui` e descobrir depois que `apps/web` precisa de rota | § 5.1 do hub |
| globs com `../../../` a partir de `.storybook/` | globs a partir da raiz do pacote — sidebar vazia, sem erro | `SB-CFG-02` |
| `vite.config.ts` herdando `packages/config` | duplicar alias em três lugares, divergindo no primeiro ajuste | `SB-CFG-06` |
| versões em lockstep no `package.json` | `addon-docs` numa minor diferente | `SB-CFG-04` |
| `staticDirs` declarado | MSW sem service worker servido, e mock que falha em silêncio | `SB-CFG-05` |
| augmentation em `router.ts` | tipos do router genéricos nas stories, e `SB-TS-02` inerte | Passo 6 |
| runner **depois** da sidebar verde | depurar glob e runner juntos | Passo 3.6 |

**O passo que ninguém documenta e que mais rende:** subir e olhar a sidebar antes de ligar o runner. Sidebar vazia com runner ligado produz "0 testes passaram" — que é verde, e não significa nada.

---

