# A sequência, e de onde a config do Vite é herdada

A doc oficial documenta cada peça isolada e **nunca a ordem**. Para um monorepo partindo do zero:

| # | Passo | Referência |
| --- | --- | --- |
| 1 | criar `apps/storybook` com `package.json` próprio, declarado no workspace | `Docs/Bun - Gerenciador de Pacotes.md` |
| 2 | instalar framework e addons, **todos na mesma versão** | `SB-CFG-04` |
| 3 | criar `apps/storybook/vite.config.ts` herdando a base compartilhada | Passo 4 |
| 4 | escrever `main.ts` com `framework`, `stories`, `addons` | `SB-CFG-01`, `SB-CFG-02` |
| 5 | escrever `preview.tsx` com CSS global, providers, parameters de projeto | `SB-CFG-03` |
| 6 | **subir e conferir a sidebar** | `SB-CFG-02` |
| 7 | só então ligar o runner | [Storybook - Testes e Interações](../../../../knowledge-base/docs/storybook-testes-e-interacoes.md) § 4 |

**O passo 6 antes do 7 é deliberado:** depurar glob e depurar runner ao mesmo tempo custa o dobro. E glob que não casa **não dá erro** — dá sidebar vazia, que é o sintoma mais confuso desta skill.

**Versões em lockstep:** todo pacote `@storybook/*` na mesma versão do pacote `storybook` (`SB-CFG-04`). Divergência é bug de instalação, não escolha — os pacotes publicam juntos.

**Globs de `stories` são relativos a `.storybook/`**, não à raiz do pacote (`SB-CFG-02`). É a causa nº 1 de sidebar vazia.

---

## Passo 4 — De onde a config do Vite é herdada

Num app único a resposta é óbvia: o `vite.config.ts` do próprio projeto.

**Num monorepo com `apps/storybook` separado, não existe "a config do projeto"** — as stories vêm de `packages/ui` e de `apps/web`, e o Storybook mora num quarto pacote sem Vite config nenhuma. Isso não é hipotético: o `vitest.config.ts` que o runner exige faz `import viteConfig from './vite.config'`, e esse arquivo precisa existir em `apps/storybook`.

A saída que mantém `SB-CFG-06` cumprível é **extrair a base para `packages/config`** — o pacote que já existe para `tsconfig` e Biome — e importá-la nos três lugares:

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
import { baseConfig } from '@escopo/config/vite.base';
export default defineConfig(baseConfig);
```

Alias, plugin e `define` declarados **uma vez**, herdados por `apps/web`, `apps/storybook` e pelo `vitest.config.ts` (`SB-CFG-06`).

> **Este arranjo é decisão do vault, não da fonte.** A revisão de 2026-08-19 encontrou que `SB-CFG-06` era **impossível de seguir** no layout que a própria doc prescreve. Ver [Storybook - Pendências de revisão](../../../../knowledge-base/docs/storybook-pendencias-de-revisao.md).

**`viteFinal` quase nunca é preciso.** Se você está alcançando por ele algo que a base já deveria dar, o problema é a herança do Passo 4 — não o hook.

**E `apps/storybook` permanece folha do grafo:** nenhum pacote depende dele (`SB-CFG-07`). Ele consome; não é consumido.

---

## Passo 5 — Estilo e tema

| Onde | O quê | Regra |
| --- | --- | --- |
| `preview.tsx` | CSS global que se pretende editar | `SB-CFG-03` |
| decorator global | tema, providers | `SB-CTX-03` |
| `staticDirs` | o diretório do service worker, se MSW estiver em uso | `SB-CFG-05` |

**`preview-head.html` não é para CSS** que se pretende editar (`SB-CFG-03`) — CSS importado em `preview.tsx` participa do HMR do Vite; injetado no head, não.

**Tema não se configura em `main.ts`.** É decorator global, e vale para as stories, não para a UI do Storybook.

---

