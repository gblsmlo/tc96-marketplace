---
titulo: TanStack Router - File-Based Routing
Link: https://tanstack.com/router/latest/docs/framework/react/routing/file-based-routing
tags:
 - tanstack-router
 - routing
 - build
 - agent-context
source: "Documentação oficial — https://tanstack.com/router/latest/docs/framework/react/"
verificado-em: 2026-08-14
---

# TanStack Router - File-Based Routing

> A **mecânica da geração**: a tabela canônica de tokens de nome de arquivo, o plugin de bundler e a CLI, as opções de configuração com seus defaults, e o `routeTree.gen.ts` como artefato.
>
> **Não cobre:** o que cada tipo de rota significa e quando usar ([TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)) · flat × diretório × misto e code-based ([TanStack Router - Route Trees](tanstack-router-route-trees.md)) · precedência de match ([TanStack Router - Route Matching](tanstack-router-route-matching.md)) · substituir a convenção por código ([TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md)) · `autoCodeSplitting` na prática ([TanStack Router - Route Context e Code Splitting](tanstack-router-route-context-e-code-splitting.md)).

Entrada: [TanStack Router](tanstack-router.md) · Base normativa: [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)

---

## 1. Conceito: o nome do arquivo é o input de um compilador

File-based routing no TanStack Router não é "o router lê a pasta em runtime". É um **passo de build**: um plugin de bundler (ou a CLI) lê `routesDirectory`, interpreta os nomes de arquivo como uma gramática, e **escreve dois artefatos**:

1. `routeTree.gen.ts` — a árvore montada, com os tipos de todas as rotas;
2. o literal de path dentro de cada `createFileRoute('…')`, reescrito no seu arquivo.

> "our plugin will **automatically generate your route configuration through your bundler's dev and build processes**"

Isso explica os dois comportamentos que mais surpreendem:

- **o path que você escreve à mão é sobrescrito** — ele é saída, não entrada (`TSR-ROUTE-01`);
- **renomear um arquivo é uma refatoração de rota**, com type errors imediatos em todo lugar que a referenciava — é este o "type safety" que a fonte destaca:

> "File-based routing raises the ceiling on type-safety by generating and managing type linkages"

O router suporta Vite, Rspack/Rsbuild, Webpack e Esbuild. Para bundler não suportado, a saída documentada é [TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md).

---

## 2. A gramática dos nomes de arquivo

Tabela canônica de tokens, citada da fonte. Cada linha é uma regra do parser; o significado de cada tipo de rota está em [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md).

| Token | Significado (fonte) |
| --- | --- |
| `__root.tsx` | "The root route file must be named `__root.tsx` and must be placed in the root of the configured `routesDirectory`." |
| `.` | "Routes can use the `.` character to denote a nested route. For example, `blog.post` will be generated as a child of `blog`." |
| `$` | "Route segments with the `$` token are parameterized and will extract the value from the URL pathname as a route `param`." |
| `_` (prefixo) | "Route segments with the `_` prefix are considered to be pathless layout routes and will not be used when matching its child routes against the URL pathname." |
| `_` (sufixo) | "Route segments with the `_` suffix exclude the route from being nested under any parent routes." |
| `-` (prefixo) | "Files and folders with the `-` prefix are excluded from the route tree." |
| `(pasta)` | "A folder that matches this pattern is treated as a route group, preventing the folder from being included in the route's URL path." |
| `[x]` | Escapa caractere especial: `script[.]js.tsx` gera `/script.js`. |
| `index` | "Route segments ending with the `index` token will match the parent route when the URL pathname matches the parent route exactly." |
| `route` | "The `route` suffix can be used to create a route file at the directory's path" — `blog/post/route.tsx` para `/blog/post`. |

E o conteúdo mínimo de um arquivo de rota, presente em todos os exemplos oficiais:

```tsx
// src/routes/posts.$postId.tsx
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/posts/$postId')({
 component: PostComponent,
})
```

O gerador procura o export nomeado `Route`. Um arquivo dentro de `routesDirectory` que exporte outra coisa não vira rota utilizável.

| ID | Regra |
| --- | --- |
| `TSR-FILE-01` | Todo arquivo de rota **MUST** exportar `const Route` como export nomeado. |

> **Atenção:** `route` e `index` na tabela acima **não são palavras reservadas fixas** — são os defaults de `routeToken` e `indexToken`, configuráveis por projeto (§ 4). O mesmo vale para o `-` de `routeFileIgnorePrefix`.

| ID | Regra |
| --- | --- |
| `TSR-FILE-02` | A convenção de nomes de um projeto **MUST** ser lida da configuração antes de ser presumida — `routeToken`, `indexToken`, `routeFilePrefix` e `routeFileIgnorePrefix` alteram a gramática. |

---

## 3. Instalação e ordem do plugin

```bash
npm install @tanstack/router-plugin
```

```ts
// vite.config.ts
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { tanstackRouter } from '@tanstack/router-plugin/vite'

export default defineConfig({
 plugins: [
 tanstackRouter({
 target: 'react',
 autoCodeSplitting: true,
 }),
 react,
 ],
})
```

A ordem não é estética. A documentação é explícita:

> "Please make sure that '@tanstack/router-plugin' is passed before '@vitejs/plugin-react'"

Alternativa sem bundler: a CLI do TanStack Router, configurada por `tsr.config.json` com as mesmas opções.

| ID | Regra |
| --- | --- |
| `TSR-FILE-03` | `tanstackRouter` **MUST** vir antes de `@vitejs/plugin-react` no array de `plugins`. |

---

## 4. Configuração e defaults

Os defaults cobrem o projeto padrão inteiro:

```json
{
 "routesDirectory": "./src/routes",
 "generatedRouteTree": "./src/routeTree.gen.ts",
 "routeFileIgnorePrefix": "-",
 "quoteStyle": "single"
}
```

Opções completas:

| Opção | Default | O que faz |
| --- | --- | --- |
| `routesDirectory` | `./src/routes` | "The path to the directory where the route files are located, relative to the cwd" |
| `generatedRouteTree` | `./src/routeTree.gen.ts` | "The path to the file where the generated route tree will be saved, relative to the cwd" |
| `routeFilePrefix` | *(vazio)* | Só arquivos começando com este prefixo são considerados rotas |
| `routeFileIgnorePrefix` | `-` | "Used to ignore specific files and directories in the route directory" |
| `routeToken` | `route` | Identifica o arquivo de layout de um diretório; aceita regex |
| `indexToken` | `index` | Identifica o arquivo de rota índice; aceita regex |
| `virtualRouteConfig` | `undefined` | Ativa [TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md) |
| `quoteStyle` | `single` | Aspas nos arquivos gerados |
| `semicolons` | `false` | Ponto e vírgula nos arquivos gerados |
| `autoCodeSplitting` | `false` | Code splitting automático dos itens não críticos da rota |
| `disableTypes` | `false` | "Disables generating types for the route tree" — gera `.js` no lugar de `.ts` |

`disableTypes` desliga exatamente aquilo pelo qual se escolhe este router. Em projeto TypeScript não há caso de uso legítimo.

| ID | Regra |
| --- | --- |
| `TSR-FILE-04` | `disableTypes: true` **NEVER** em projeto TypeScript — remove a geração de tipos da árvore, que é o motivo de usar file-based routing. |

> **Não verificado:** a opção `target` (`'react'` / `'solid'`) aparece em todos os exemplos oficiais de `vite.config.ts`, mas não consta na referência de opções de file-based routing consultada. Mantenha `target` no exemplo — ele está na fonte — mas não presuma o conjunto de valores aceitos sem checar.

---

## 5. `routeTree.gen.ts`

É saída do gerador, regravada a cada dev e build. Duas consequências:

- **editar à mão é trabalho perdido** e mascara o problema real, que está no nome de algum arquivo;
- **um diff sujo nele em code review** significa que alguém mexeu na estrutura de rotas — é ali que se lê o impacto real de uma PR sobre a árvore.

| ID | Regra |
| --- | --- |
| `TSR-FILE-05` | `routeTree.gen.ts` **NEVER** é editado à mão. Para mudar a árvore, mude os nomes de arquivo em `routesDirectory`. |

---

## Antipadrões

**Plugin depois do React**

```ts
// ERRADO — a transformação do router não roda sobre o output do plugin React
plugins: [react, tanstackRouter({ target: 'react' })]

// CERTO
plugins: [tanstackRouter({ target: 'react' }), react]
```

**Componente auxiliar dentro de `routes/`**

```
// ERRADO — vira a rota /posts/PostsTable
src/routes/posts/PostsTable.tsx

// CERTO — o prefixo de routeFileIgnorePrefix exclui do route tree
src/routes/posts/-PostsTable.tsx
```

| Antipadrão | Por que falha | Correção |
| --- | --- | --- |
| Corrigir o path dentro de `createFileRoute` | É artefato gerado; volta no próximo build | Renomear o arquivo (`TSR-ROUTE-01`) |
| Editar `routeTree.gen.ts` para "consertar" uma rota | Sobrescrito a cada build | Corrigir o nome do arquivo (`TSR-FILE-05`) |
| `export default` no arquivo de rota | O gerador espera o export nomeado `Route` | `export const Route = createFileRoute(…)` (`TSR-FILE-01`) |
| Presumir que `index.tsx` sempre é rota índice | `indexToken` é configurável | Ler a config do projeto (`TSR-FILE-02`) |
| `disableTypes: true` para acelerar o build | Elimina o type safety inteiro | Manter tipos (`TSR-FILE-04`) |

---

## Checklist de revisão

- [ ] Todo arquivo de rota exporta `const Route`? → `TSR-FILE-01`
- [ ] A convenção assumida bate com `routeToken`/`indexToken`/`routeFileIgnorePrefix` do projeto? → `TSR-FILE-02`
- [ ] `tanstackRouter` vem antes de `react` no `vite.config.ts`? → `TSR-FILE-03`
- [ ] `disableTypes` está `false`? → `TSR-FILE-04`
- [ ] `routeTree.gen.ts` só mudou por regeneração, nunca por edição manual? → `TSR-FILE-05`
- [ ] Arquivos auxiliares dentro de `routes/` usam o prefixo de exclusão? → `TSR-ROUTE-13`

---

## Relacionados

- [TanStack Router](tanstack-router.md) — entrada
- [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md) · [TanStack Router - Route Trees](tanstack-router-route-trees.md) · [TanStack Router - Route Matching](tanstack-router-route-matching.md) · [TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md)
- [TanStack Router - Route Context e Code Splitting](tanstack-router-route-context-e-code-splitting.md) — `autoCodeSplitting` na prática
- `TypeScript` · [React.js](react-js.md)

## Fontes consultadas

Verificadas em 2026-08-14:

- [File-Based Routing](https://tanstack.com/router/latest/docs/framework/react/routing/file-based-routing)
- [File Naming Conventions](https://tanstack.com/router/latest/docs/framework/react/routing/file-naming-conventions)
- [Installation with Vite](https://tanstack.com/router/v1/docs/framework/react/installation/with-vite)
- [File-Based Routing API Reference](https://tanstack.com/router/v1/docs/api/file-based-routing)

**Correções aplicadas nesta revisão** — a versão anterior desta nota tinha erros de convenção que produziriam código quebrado:

- **`.layout.tsx` não existe.** A versão anterior ensinava `posts.layout.tsx` como sufixo de layout route. O mecanismo real é o `route` token (`posts/route.tsx`) ou o irmão flat (`posts.tsx`); layout sem path é o prefixo `_` (`_pathlessLayout.tsx`).
- **`*.tsx` não é catch-all.** Catch-all é `$.tsx` (segmento `$` sozinho), lido em `params._splat`.
- **"`pathless/` ou prefixo `.`" está errado** nas duas metades. Pathless layout é prefixo `_`; route group é `(pasta)`; o `.` é separador de nível, não marcador de pathless.
- **`(.protected)/` com `__root.tsx` dentro** — errado duas vezes: a sintaxe de grupo é `(protected)` sem ponto, e `__root.tsx` só existe uma vez, na raiz de `routesDirectory`.
- **`createRoute({ getParentRoute, path })` em arquivo file-based** — em file-based o construtor é `createFileRoute('/path')({...})`; `createRoute` é a API de code-based ([TanStack Router - Route Trees](tanstack-router-route-trees.md) § 4).
- **Adicionada a ordem obrigatória do plugin** em relação a `@vitejs/plugin-react`, que a versão anterior não mencionava.
- **Adicionadas as opções de configuração e seus defaults**, ausentes na versão anterior — incluindo o fato de `routeToken`/`indexToken`/`routeFileIgnorePrefix` serem configuráveis.
- **Removidos os pseudocódigos** `parseRouteParams`, `renderOutlet`, `extractPathSegments` e a `interface OutletProps` — invenções que não correspondem a nada da fonte. O `extractPathSegments`, em particular, filtrava segmentos `$`, o que descreve o oposto do comportamento real.
- **Removido o formato inventado do tipo gerado** (`type PostIdRoute = { id, path, fullPath, params }`).
- **Cortado por redundância:** a explicação de cada tipo de rota com exemplos (agora só em [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)) e a nota de precedência index/splat (agora só em [TanStack Router - Route Matching](tanstack-router-route-matching.md)).
