---
Link: https://storybook.js.org/docs/api/main-config/main-config
tags:
 - storybook
 - vite
 - monorepo
 - configuracao
 - agent-context
source: "Documentação oficial do Storybook — main.ts config, Styling and CSS, Migration guide, frameworks"
verificado-em: 2026-08-19
---

# Storybook — Configuração e Builder

> Satélite de [Storybook](storybook.md). Cobre `.storybook/main.ts`, `.storybook/preview.tsx`, o builder Vite, carregamento de estilo e tema, e o recorte de `apps/storybook` dentro do monorepo.
>
> **Esta é a nota onde os dois caminhos de framework divergem de verdade.** A escolha é decidida na § 5.1 do hub e detalhada em [Storybook - TanStack React](storybook-tanstack-react.md) ou [Storybook - React Vite](storybook-react-vite.md). Aqui estão os efeitos dela sobre a configuração: valor de `framework`, piso de versão, e opções do framework. O resto da nota — estilo, `viteFinal`, monorepo — vale igual nos dois.

---

## 1. Os dois arquivos, e a divisão entre eles

| Arquivo | Roda onde | Decide |
| --- | --- | --- |
| `.storybook/main.ts` | no **build** (Node) | quais arquivos são stories, qual framework, quais addons, como o Vite se comporta |
| `.storybook/preview.tsx` | no **browser**, junto das stories | como toda story renderiza: CSS global, decorators, parameters, args e tags de projeto |

A divisão importa porque é a fronteira de o que pode ser importado. `main.ts` roda em Node e não pode importar componente React; `preview.tsx` roda no browser e não pode importar nada de Node. O erro mais comum é tentar configurar tema em `main.ts`.

### 1.1 `main.ts` mínimo, e o que cada campo faz

```ts
//.storybook/main.ts
import type { StorybookConfig } from '@storybook/tanstack-react';

const config: StorybookConfig = {
 framework: '@storybook/tanstack-react',
 stories: [
 '../../../packages/ui/src/**/*.stories.@(ts|tsx)',
 '../../../packages/ui/src/**/*.mdx',
 '../../web/src/**/*.stories.@(ts|tsx)',
 ],
 addons: ['@storybook/addon-docs', '@storybook/addon-a11y', '@storybook/addon-vitest'],
 staticDirs: ['../public'],
};

export default config;
```

- **`framework`** é obrigatório. Sem ele o Storybook não sobe (`SB-CFG-01`).
- **`stories`** são globs **relativos ao diretório `.storybook/`**, não à raiz do pacote. Num monorepo isso produz os `../../../` acima — feio, e correto. Glob que não casa não dá erro: dá sidebar vazia (`SB-CFG-02`).
- **`addons`** são pacotes. Em 10.x, `@storybook/addon-docs` é explícito — não existe mais um pacote guarda-chuva de "essentials" a puxar tudo.
- **`staticDirs`** serve arquivos como estáticos, e é relativo ao `.storybook/` como os globs de `stories`. É o campo que o MSW exige para achar o service worker (`SB-CFG-05`) — e o `npx msw init./public` que o gera roda a partir da raiz do pacote, não do `.storybook/`.

### 1.2 Restrições de plataforma da linha 10

Duas mudanças da versão 10 que quebram projeto vindo da 8 ou 9:

- **ESM-only.** `main.ts` e qualquer preset precisam ser ESM válido. `require` e `module.exports` não sobem (`SB-CORE-03`).
- **Node ≥ 20.19 ou ≥ 22.12** (`SB-CORE-04`).

E um piso de versão que não é do Storybook, mas do framework escolhido:

| | `@storybook/tanstack-react` | `@storybook/react-vite` |
| --- | --- | --- |
| React | ≥ **18** | ≥ 16.8 |
| Vite | ≥ **7** | ≥ 5 |

Adotar o framework do TanStack num app em Vite 5 ou 6 é, na prática, agendar uma migração de Vite primeiro — e é a razão pela qual [Storybook - React Vite](storybook-react-vite.md) existe como caminho de transição legítimo, não como segunda opção inferior.

### 1.2.1 `framework` como objeto — vale nos dois caminhos

O campo aceita string ou `{ name, options }`:

```ts
framework: {
 name: '@storybook/react-vite',
 options: {
 builder: { /* opções do builder Vite */ },
 },
},
```

`builder` é a opção **compartilhada** entre frameworks. Opções específicas de cada framework vivem na documentação do próprio pacote e **não foram verificadas nesta doc** — a referência de `main.ts` remete ao repositório. Use string simples enquanto não houver `options` a passar.

### 1.3 Versões em lockstep

Os pacotes do monorepo do Storybook publicam juntos: `storybook`, `@storybook/tanstack-react`, `@storybook/addon-vitest`, `@storybook/addon-docs` e `@storybook/addon-a11y` compartilham o mesmo número. Um `package.json` com `storybook@10.5.9` e `@storybook/addon-docs@10.4.x` é erro de instalação, não escolha de versão (`SB-CFG-04`).

```bash
npm view storybook dist-tags
```

### 1.4 `preview.tsx` mínimo

```tsx
//.storybook/preview.tsx
import type { Preview } from '@storybook/tanstack-react';
import '../../../packages/ui/src/styles/global.css';

const preview = {
 parameters: {
 layout: 'centered',
 a11y: { test: 'error' },
 },
 tags: ['autodocs'],
} satisfies Preview;

export default preview;
```

A extensão é `.tsx`, não `.ts`, assim que houver um decorator com JSX — e num design system sempre haverá.

### 1.5 Regras — `SB-CFG-01`, `SB-CFG-02`, `SB-CFG-04`

| ID | Regra |
| --- | --- |
| `SB-CFG-01` | `framework` **MUST** estar declarado em `main.ts`. É ele que define o caminho da doc a seguir. |
| `SB-CFG-02` | Globs de `stories` **MUST** ser relativos ao diretório `.storybook/`. |
| `SB-CFG-04` | Todo pacote `@storybook/*` **MUST** estar na mesma versão do pacote `storybook`. |

---

## 2. Estilo

### 2.1 CSS global

O caminho prescrito é **importar no `preview.tsx`**:

```tsx
import '../../../packages/ui/src/styles/global.css';
```

Note que o import aponta para o **fonte** do pacote, não para o entrypoint publicado (`@escopo/ui/styles.css`). Os dois funcionam; só o primeiro dá HMR ao editar o CSS do design system, que é o arquivo que mais muda enquanto se trabalha (`SB-CFG-03`).

Existe ainda a alternativa de injetar CSS estático por `.storybook/preview-head.html`, e a fonte é explícita quanto ao custo: **sem HMR**. Editar o CSS não reflete sem recarregar. Para o CSS do próprio design system — o arquivo que você mais vai editar enquanto trabalha — isso é o oposto do que se quer (`SB-CFG-03`).

`preview-head.html` continua sendo o lugar certo para o que não muda: webfont, meta tag, script de terceiro.

### 2.2 O que o Vite já resolve

Sob o builder Vite, funcionam sem configuração:

| Recurso | Estado |
| --- | --- |
| CSS Modules | nativo |
| PostCSS | nativo |
| Sass / Less | nativo |
| CSS-in-JS | funciona sem configuração extra, salvo provider — ver § 2.3 |

A doc só exige configuração adicional para esses itens no builder **Webpack**, que está fora do escopo desta estrutura. Se o app já compila com Vite, o Storybook compila igual.

### 2.3 Tema

Provider de tema é ambiente, e ambiente é decorator global — o assunto é [Storybook - Decorators e Contexto](storybook-decorators-e-contexto.md) § 2. O que pertence a esta nota é onde ele mora: `preview.tsx`, uma vez, nunca repetido por arquivo de story.

Existe `@storybook/addon-themes` com decorators prontos; a página de estilo linka `withThemeFromJSXProvider` para o caso de provider JSX. **A API desse addon não foi verificada nesta doc** — o que está verificado é que decorator global + `globals` resolve o mesmo problema com primitivas da própria fonte, e é o que [Storybook - Decorators e Contexto](storybook-decorators-e-contexto.md) § 2.3 mostra.

### 2.4 Regras — `SB-CFG-03`, `SB-CFG-05`

| ID | Regra |
| --- | --- |
| `SB-CFG-03` | CSS que se pretende editar **MUST** ser importado em `preview.tsx`. `preview-head.html` **NEVER** para CSS sob desenvolvimento — não tem HMR. |
| `SB-CFG-05` | `staticDirs` **MUST** incluir o diretório do service worker quando MSW estiver em uso. |

---

## 3. `viteFinal`, e por que quase nunca é preciso

```ts
const config: StorybookConfig = {
 framework: '@storybook/tanstack-react',
 stories: [/* … */],
 viteFinal: async (config) => {
 // modificar e devolver a config do Vite
 return config;
 },
};
```

O hook existe, mas o uso mais comum dele é sintoma: alguém redeclarando alias, plugin ou `define` que o app já tem. **A herança é o caminho certo** — duplicar cria duas verdades que divergem na primeira mudança (`SB-CFG-06`).

### 3.1 "Herdar de qual config?" — a pergunta que o monorepo faz

Num app único a resposta é óbvia: o Storybook parte do `vite.config.ts` do próprio projeto. **Num monorepo com `apps/storybook` separado, não existe "a config do projeto"** — as stories vêm de `packages/ui` e de `apps/web`, e o Storybook mora num quarto pacote que não tem Vite config nenhuma.

Isso não é detalhe: o `vitest.config.ts` prescrito em [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) § 4.2 faz `import viteConfig from './vite.config'`, e esse arquivo precisa existir em `apps/storybook`.

A saída que mantém `SB-CFG-06` cumprível é **extrair a config compartilhada para `packages/config`** — o pacote que o monorepo já tem para `tsconfig` e Biome — e importá-la nos três lugares:

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

Assim o alias é declarado uma vez e herdado por `apps/web`, `apps/storybook` e pelo `vitest.config.ts` — que é o que a regra quer dizer por "herança". **Este arranjo é decisão desta doc, não prescrição da fonte:** a doc do Storybook assume um app único e não trata o caso.

Casos legítimos de `viteFinal` são os que existem só no Storybook: excluir do bundle um módulo que a UI do Storybook não deve carregar, ou apontar um alias que só faz sentido sob story.

---

## 3.2 A sequência, uma vez

A doc oficial documenta cada peça isolada e nunca a ordem. Para um monorepo partindo do zero:

1. **Criar o pacote** `apps/storybook` com `package.json` próprio, e declará-lo no workspace — `Bun - Gerenciador de Pacotes`.
2. **Instalar** o framework e os addons (§ 1.3 sobre lockstep; § 4.1 sobre `npm` × `bun`).
3. **Criar `apps/storybook/vite.config.ts`** herdando a base compartilhada (§ 3.1).
4. **Escrever `main.ts`** com `framework`, `stories` e `addons` (§ 1.1).
5. **Escrever `preview.tsx`** com CSS global, providers e parameters de projeto (§ 1.4).
6. **Subir e conferir a sidebar.** Glob que não casa não dá erro — dá sidebar vazia (`SB-CFG-02`).
7. **Só então** ligar o runner: `npx storybook add @storybook/addon-vitest` — [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) § 4.

O passo 6 antes do 7 é deliberado: depurar glob e depurar runner ao mesmo tempo custa o dobro.

---

## 4. O recorte no monorepo

O desenho está em `Monorepo com Bun - estrutura e tooling`: `apps/storybook` é app deployável e **folha do grafo** — ele consome `apps/web` e `packages/ui`, e ninguém consome ele. É isso que permite tirá-lo do build de produção sem tocar em nenhum outro pacote (`SB-CFG-07`).

### 4.1 Scripts

```json
{
 "scripts": {
 "storybook": "storybook dev -p 6006",
 "build-storybook": "storybook build",
 "test-storybook": "vitest run --project=storybook"
 }
}
```

**Os nomes não são livres.** `storybookScript` do addon-vitest referencia este script pelo nome ([Storybook - Testes e Interações](storybook-testes-e-interacoes.md) § 4.2), e a doc oficial assume `storybook` / `build-storybook`. Renomear para `dev`/`build` obriga a lembrar disso em outro arquivo — e é exatamente o tipo de divergência que só aparece quando o watch mode do runner falha.

`storybook build` gera `storybook-static/`. É diretório estático — publica como qualquer SPA.

> **Num monorepo Bun, os comandos de instalação da doc oficial são `npm`/`npx`.** `npm create storybook@latest`, `npx storybook add …`, `npx msw init …`. Rodar `npm install` dentro de um workspace Bun gera `package-lock.json` e mexe no linker — ver `Bun - Gerenciador de Pacotes`. Use `bun add` / `bunx` para o equivalente. As formas `bunx` dos comandos de setup **não foram verificadas contra a fonte**; o que está verificado são as formas `npm`.

### 4.2 A armadilha de augmentation de tipo — **só caminho TanStack**

Esta é a que mais custa tempo, e já está documentada no vault por outro caminho. O TanStack Router pede `declare module '@tanstack/react-router'` para registrar o tipo do router. Se essa augmentation mora no `main.tsx` do app — o arquivo que monta o DOM — ela **não alcança o programa TS do Storybook**, porque `main.tsx` não pode entrar nesse programa.

O conserto é separar a augmentation num módulo próprio (`router.ts`), exportá-lo, e importar **de tipo** onde precisar. Ver `Monorepo com Bun - estrutura e tooling` § 5.7, onde isso foi verificado por sabotagem.

Sintoma no Storybook: tipos do router caem para o genérico dentro das stories, e `params` deixa de ser checado contra o path da rota — o que faz `SB-TS-02` passar a não pegar mais nada.

**Sob `@storybook/react-vite` esta seção é inerte:** não há `parameters.tanstack.*` a tipar (`SB-RV-04`), e os params entram como string em `initialEntries`, sem checagem, por desenho — ver [Storybook - React Vite](storybook-react-vite.md) § 4.2.

### 4.3 Onde as stories vivem

Duas opções, e a escolha tem consequência:

| Opção | Efeito |
| --- | --- |
| story ao lado do componente, em `packages/ui/src/**` | o pacote carrega suas próprias stories; quem consome o pacote pode montar o próprio Storybook |
| story dentro de `apps/storybook/src/**` | `packages/ui` fica limpo, mas as stories deixam de viajar com o componente |

Esta doc assume a primeira, e é por isso que os globs da § 1.1 apontam para fora. O critério é o mesmo do monorepo: a story descreve o componente, então pertence ao pacote do componente. `apps/storybook` fica sendo só o *host* — config, deploy, e nada de conteúdo.

### 4.4 Regras — `SB-CFG-06`, `SB-CFG-07`

| ID | Regra |
| --- | --- |
| `SB-CFG-06` | Alias, plugin e `define` **MUST** ter uma única declaração, herdada por todos os consumidores. Redeclarar em `viteFinal` **NEVER**. Num monorepo, isso exige uma config base compartilhada — ver § 3.1. † |
| `SB-CFG-07` | `apps/storybook` **MUST** permanecer folha do grafo: nenhum pacote depende dele. † |

---

## 5. Antipadrões

### 5.1 Configurar tema em `main.ts`

`main.ts` roda em Node, no build. Não há componente, não há provider, não há CSS. Tudo que é visual pertence a `preview.tsx`.

### 5.2 Glob apontando para `dist`

```ts
stories: ['../../../packages/ui/dist/**/*.stories.js'], // ❌
```

Story compilada perde o docgen — a tabela de props fica vazia, porque os tipos e o JSDoc não sobrevivem ao build. Aponte para o fonte.

### 5.3 Duplicar a config do Vite

Ver § 3. O sintoma aparece semanas depois: um alias novo funciona no app e quebra no Storybook.

### 5.4 Versões desalinhadas entre pacotes do Storybook

Um `@storybook/addon-*` uma minor atrás produz erro em runtime difícil de ler, do tipo "cannot read property of undefined" dentro do manager. Antes de investigar, confira que todos estão no mesmo número (`SB-CFG-04`).

### 5.5 Tratar `apps/storybook` como pacote consumível

No momento em que outro pacote importa algo de `apps/storybook`, ele deixa de ser folha e passa a entrar no build de produção. O sintoma é bundle de produção crescendo sem motivo aparente.

---

## Relacionados

- [Storybook](storybook.md) — hub
- [Storybook - Decorators e Contexto](storybook-decorators-e-contexto.md) — o que colocar dentro do `preview.tsx`
- [Storybook - TanStack React](storybook-tanstack-react.md) — a escolha do framework e seus requisitos
- [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) — a config do Vitest, que é arquivo separado
- `Monorepo com Bun - estrutura e tooling` — o grafo de dependências e a armadilha de augmentation
- `Bun - Gerenciador de Pacotes` — workspaces e o linker

## Fontes consultadas

Verificadas diretamente em **2026-08-19**:

- [main.ts config](https://storybook.js.org/docs/api/main-config/main-config)
- [Styling and CSS](https://storybook.js.org/docs/configure/styling-and-css)
- [Storybook for TanStack React](https://storybook.js.org/docs/get-started/frameworks/tanstack-react)
- [Storybook for React & Vite](https://storybook.js.org/docs/get-started/frameworks/react-vite)
- [main.ts — framework](https://storybook.js.org/docs/api/main-config/main-config-framework)
- [Migration guide](https://storybook.js.org/docs/releases/migration-guide)

**Notas de verificação:**

- **A linha 10 é ESM-only:** `main.ts` e presets precisam ser ESM válido, e Node ≥ 20.19 / 22.12.
- **`preview-head.html` não tem HMR** — a fonte é explícita, e é o que decide contra ele para CSS de desenvolvimento.
- **CSS Modules, PostCSS e pré-processadores são nativos no Vite;** a configuração extra que a doc descreve é do builder Webpack.
- **`@storybook/tanstack-react` exige Vite ≥ 7**, contra Vite ≥ 5 do `@storybook/react-vite`. É o requisito mais alto de toda a estrutura.
- **A API de `@storybook/addon-themes` não foi verificada aqui.** A página de estilo linka `withThemeFromJSXProvider` para provider JSX; os demais decorators não foram conferidos.
- **`storybook build` sai em `storybook-static`**, e o diretório é configurável.
