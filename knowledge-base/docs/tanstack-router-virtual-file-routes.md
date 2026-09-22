---
titulo: TanStack Router - Virtual File Routes
Link: https://tanstack.com/router/latest/docs/framework/react/routing/virtual-file-routes
tags:
 - tanstack-router
 - routing
 - build
 - agent-context
source: "Documentação oficial — https://tanstack.com/router/latest/docs/framework/react/"
verificado-em: 2026-08-14
---

# TanStack Router - Virtual File Routes

> O pacote `@tanstack/virtual-file-routes`: `rootRoute`, `route`, `index`, `layout`, `physical`, `defineVirtualSubtreeConfig`. Como declarar a árvore em código apontando para arquivos que estão onde você quiser, e como misturar isso com file-based em qualquer nível.
>
> **Não cobre:** o significado de cada tipo de rota ([TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)) · a convenção de nomes que o `physical` aplica ([TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md)) · code-based routing, que é outra coisa ([TanStack Router - Route Trees](tanstack-router-route-trees.md) § 4) · precedência de match, que é idêntica ([TanStack Router - Route Matching](tanstack-router-route-matching.md)).

Entrada: [TanStack Router](tanstack-router.md) · Base normativa: [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md)

---

## 1. Conceito: separar a árvore da pasta

File-based routing amarra duas decisões que não precisam estar juntas: **qual é a árvore de rotas** e **onde os arquivos moram**. Normalmente isso é uma vantagem — uma decisão a menos. Deixa de ser quando o projeto já tem uma organização por feature (`src/features/faturas/…`) que não se quer desmontar, ou quando a convenção do router colide com a convenção da casa.

Virtual file routes desamarram as duas: você declara a árvore em TypeScript e cada nó **aponta para um arquivo real**, em qualquer caminho.

A distinção que evita a confusão mais comum:

| | Onde a árvore é declarada | Componentes vêm de | Tipos gerados |
| --- | --- | --- | --- |
| **File-based** | nomes de arquivo | arquivos de rota | sim |
| **Virtual file routes** | um módulo TS | arquivos reais, referenciados | sim |
| **Code-based** | um módulo TS | imports diretos | não há geração |

Virtual **não** é code-based. O gerador continua rodando, continua produzindo `routeTree.gen.ts` e continua dando type safety — só troca a fonte da estrutura. É por isso que virtual é a resposta certa para "a convenção não serve", e code-based não é ([TanStack Router - Route Trees](tanstack-router-route-trees.md) § 4).

| ID | Regra |
| --- | --- |
| `TSR-VIRTUAL-01` | Virtual file routes **NEVER** são a escolha default. Só entram quando a convenção file-based não pode ser adotada — estrutura pré-existente, convenção interna conflitante, ou bundler sem plugin. |

---

## 2. A API

Pacote: `@tanstack/virtual-file-routes`.

| Função | Assinatura | Cria |
| --- | --- | --- |
| `rootRoute` | `rootRoute(file, children)` | a raiz virtual — equivalente a `__root.tsx` |
| `route` | `route(path, file?, children?)` | rota com path; `file` e `children` opcionais |
| `index` | `index(file)` | rota índice do pai |
| `layout` | `layout(file, children?)` ou `layout(id, file, children)` | pathless layout — não contribui segmento |
| `physical` | `physical(path, dir?)` ou `physical(dir)` | monta um diretório usando file-based |
| `defineVirtualSubtreeConfig` | `defineVirtualSubtreeConfig(children)` | subárvore virtual dentro de file-based (§ 4) |

```ts
// routes.ts
import {
 rootRoute,
 route,
 index,
 layout,
 physical,
} from '@tanstack/virtual-file-routes'

export const routes = rootRoute('root.tsx', [
 index('index.tsx'),

 layout('pathlessLayout.tsx', [
 route('/dashboard', 'app/dashboard.tsx', [
 index('app/dashboard-index.tsx'),
 route('/invoices', 'app/dashboard-invoices.tsx', [
 index('app/invoices-index.tsx'),
 route('$id', 'app/invoice-detail.tsx'),
 ]),
 ]),
 ]),

 // monta posts/ inteiro sob /posts, com convenção file-based
 physical('/posts', 'posts'),
])
```

Dois detalhes de assinatura que custam tempo quando passam despercebidos:

**`route` sem arquivo** — serve para criar um prefixo de path sem componente. Só faz sentido com children:

```ts
route('/hello', [
 route('/world', 'world.tsx'), // /hello/world
 route('/universe', 'universe.tsx'), // /hello/universe
])
```

**`layout` com id** — a sobrecarga de três argumentos nomeia o layout, útil quando há mais de um pathless layout irmão:

```ts
layout('auth', 'auth-layout.tsx', [
 route('/login', 'login.tsx'),
])
```

| ID | Regra |
| --- | --- |
| `TSR-VIRTUAL-02` | `route` sem `file` **MUST** ter `children` — sem arquivo e sem filhos, o nó não renderiza nem contém nada. |
| `TSR-VIRTUAL-03` | `layout` **NEVER** recebe path. Se o nó precisa contribuir um segmento à URL, é `route`, não `layout`. |

---

## 3. `physical`: montar file-based dentro de virtual

`physical(path, dir)` monta um diretório inteiro sob um prefixo, aplicando ali a convenção file-based normal ([TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md) § 2).

```
/routes
├── root.tsx
├── posts/
│ ├── index.tsx
│ └── $postId.tsx
└── app/
 └── dashboard.tsx
```

```ts
rootRoute('root.tsx', [
 index('index.tsx'),
 physical('/posts', 'posts'),
 layout('app-layout.tsx', [
 physical('/dashboard', 'app'),
 ]),
])
```

Resultado: `/` → `index.tsx` · `/posts` → `posts/index.tsx` · `/posts/$postId` → `posts/$postId.tsx` · `/dashboard` → `app/dashboard.tsx`.

### Mesclar no nível atual

Sem prefixo de path, o diretório é mesclado onde está:

```ts
export const routes = rootRoute('__root.tsx', [
 route('/about', 'about.tsx'),
 physical('features'), // equivalente a physical('', 'features')
])
```

| URL | Arquivo |
| --- | --- |
| `/about` | `about.tsx` |
| `/` | `features/index.tsx` |
| `/contact` | `features/contact.tsx` |

E o aviso da fonte, que é a única armadilha real deste recurso:

> "When merging at the same level, ensure there are no conflicting route paths between your virtual routes and the physical directory routes."

| ID | Regra |
| --- | --- |
| `TSR-VIRTUAL-04` | Ao mesclar `physical` no nível atual, os paths do diretório físico e os das rotas virtuais irmãs **NEVER** podem colidir. |

---

## 4. `__virtual.ts`: virtual dentro de file-based

O caminho inverso. Um projeto file-based normal pode trocar para virtual em qualquer subárvore, colocando um `__virtual.ts` no diretório:

> um `__virtual.ts` faz o gerador "switch over to virtual file route configuration for this directory (and its child directories)."

```
/routes
├── __root.tsx
├── index.tsx
└── foo/
 ├── bar.tsx
 └── bar/
 ├── __virtual.ts ← daqui para baixo, virtual
 ├── home.tsx
 └── details.tsx
```

```ts
// routes/foo/bar/__virtual.ts
import {
 defineVirtualSubtreeConfig,
 index,
 route,
} from '@tanstack/virtual-file-routes'

export default defineVirtualSubtreeConfig([
 index('home.tsx'), // /foo/bar
 route('$id', 'details.tsx'), // /foo/bar/$id
])
```

`defineVirtualSubtreeConfig` aceita um array de config, uma função, ou uma função assíncrona — o mesmo contrato do `defineConfig` do Vite. E a alternância pode se repetir: um diretório dentro da subárvore virtual volta a ser file-based, e um `__virtual.ts` mais fundo volta a ser virtual.

```
/routes
├── __root.tsx
├── posts.tsx
└── posts/
 ├── __virtual.ts ← virtual
 ├── home.tsx
 ├── details.tsx
 └── lets-go/
 ├── index.tsx ← file-based de novo
 └── deeper/
 ├── __virtual.ts ← virtual de novo
 └── home.tsx
```

Esta é a propriedade que torna virtual file routes uma ferramenta de **migração**, e não uma decisão de tudo-ou-nada: dá para converter uma seção do app por vez.

| ID | Regra |
| --- | --- |
| `TSR-VIRTUAL-05` | `__virtual.ts` **MUST** exportar como `export default` o retorno de `defineVirtualSubtreeConfig`. |

---

## 5. Configuração

Uma única opção liga tudo: `virtualRouteConfig`.

```ts
// vite.config.ts
import { tanstackRouter } from '@tanstack/router-plugin/vite'

export default defineConfig({
 plugins: [
 tanstackRouter({
 target: 'react',
 virtualRouteConfig: './routes.ts',
 }),
 react,
 ],
})
```

Também aceita a árvore inline, sem arquivo separado:

```ts
import { rootRoute, index, route } from '@tanstack/virtual-file-routes'

const routes = rootRoute('root.tsx', [
 index('index.tsx'),
 route('/about', 'about.tsx'),
])

tanstackRouter({ target: 'react', virtualRouteConfig: routes })
```

E, pela CLI:

```json
// tsr.config.json
{ "virtualRouteConfig": "./routes.ts" }
```

A ordem do plugin em relação ao `@vitejs/plugin-react` continua valendo — `TSR-FILE-03`.

| ID | Regra |
| --- | --- |
| `TSR-VIRTUAL-06` | `virtualRouteConfig` **MUST** ser declarado em um único lugar — na opção do plugin **ou** em `tsr.config.json`, nunca nos dois com valores divergentes. |

> **Não verificado:** a forma JSON literal da árvore em `tsr.config.json` (objetos com `"type": "root" | "index" | "route" | "layout"`, `"file"`, `"path"`, `"id"`, `"children"`), que a versão anterior desta nota documentava. A fonte consultada mostra `virtualRouteConfig` apontando para um **caminho de arquivo**; não confirmei a variante com a árvore embutida no JSON. Prefira o arquivo `routes.ts`.

---

## Antipadrões

**`layout` usado onde se queria segmento de URL**

```ts
// ERRADO — /dashboard e /settings ficam em /, sem o prefixo /app
layout('app-layout.tsx', [
 route('/dashboard', 'dashboard.tsx'),
 route('/settings', 'settings.tsx'),
])

// CERTO — route contribui o segmento; o layout continua envolvendo
route('/app', 'app-layout.tsx', [
 route('/dashboard', 'dashboard.tsx'), // /app/dashboard
 route('/settings', 'settings.tsx'), // /app/settings
])
```

| Antipadrão | Por que falha | Correção |
| --- | --- | --- |
| Adotar virtual routes por preferência estética | Troca uma convenção conhecida por um arquivo que ninguém mais lê | Só quando a convenção não pode ser adotada (`TSR-VIRTUAL-01`) |
| `route('/hello')` sem arquivo e sem filhos | Nó vazio: não renderiza nada e não contém nada | Dar `file` ou `children` (`TSR-VIRTUAL-02`) |
| `physical('features')` com rota virtual `/contact` irmã e `features/contact.tsx` | Colisão de path na mesclagem | Prefixar um dos lados (`TSR-VIRTUAL-04`) |
| `export const config = defineVirtualSubtreeConfig(...)` | O gerador lê o `default` | `export default` (`TSR-VIRTUAL-05`) |
| `virtualRouteConfig` no plugin **e** em `tsr.config.json` | Duas fontes de verdade divergindo entre dev e CI | Um lugar só (`TSR-VIRTUAL-06`) |
| Migrar o app inteiro de uma vez | Desnecessário — `__virtual.ts` permite converter por subárvore | Migração incremental (§ 4) |

---

## Checklist de revisão

- [ ] Há justificativa registrada para usar virtual em vez de file-based? → `TSR-VIRTUAL-01`
- [ ] Todo `route` sem arquivo tem filhos? → `TSR-VIRTUAL-02`
- [ ] Nenhum `layout` está sendo usado para adicionar segmento à URL? → `TSR-VIRTUAL-03`
- [ ] `physical` mesclado no nível atual não colide com rotas virtuais irmãs? → `TSR-VIRTUAL-04`
- [ ] Todo `__virtual.ts` usa `export default defineVirtualSubtreeConfig(...)`? → `TSR-VIRTUAL-05`
- [ ] `virtualRouteConfig` está declarado em um lugar só? → `TSR-VIRTUAL-06`
- [ ] O plugin ainda vem antes de `@vitejs/plugin-react`? → `TSR-FILE-03`

---

## Relacionados

- [TanStack Router](tanstack-router.md) — entrada
- [TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md) · [TanStack Router - Route Trees](tanstack-router-route-trees.md) · [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md) · [TanStack Router - Route Matching](tanstack-router-route-matching.md)
- [TanStack Router - Route Context e Code Splitting](tanstack-router-route-context-e-code-splitting.md) · `TypeScript`

## Fontes consultadas

Verificadas em 2026-08-14:

- [Virtual File Routes](https://tanstack.com/router/latest/docs/framework/react/routing/virtual-file-routes)
- [File-Based Routing API Reference](https://tanstack.com/router/v1/docs/api/file-based-routing) — opção `virtualRouteConfig`
- [Installation with Vite](https://tanstack.com/router/v1/docs/framework/react/installation/with-vite) — ordem do plugin

**Correções aplicadas nesta revisão** — esta era a nota mais correta das cinco; as mudanças são pontuais:

- **Corrigido caractere corrompido** na lista de casos de uso: `Montar 부분 específicas da árvore` → "montar partes específicas da árvore".
- **Explicitada a assinatura de `route`**: `route(path, file?, children?)`, com `path` obrigatório — a versão anterior mostrava os três usos sem dizer que `file` e `children` são opcionais e que um nó sem os dois é inútil.
- **Adicionado o aviso literal da fonte** sobre colisão de paths ao mesclar `physical` no nível atual; a versão anterior parafraseava como "o gerador lança erro", o que é mais forte do que a fonte afirma.
- **Adicionada a distinção virtual × code-based** (§ 1), que era a confusão que a nota anterior deixava em aberto — e que a versão anterior de [TanStack Router - Route Trees](tanstack-router-route-trees.md) efetivamente cometia, inventando um `createVirtualFileRoute`.
- **Marcada como não verificada** a forma JSON literal da árvore em `tsr.config.json`.
- **Removido o diagrama ASCII "Camada de Abstração — Processamento"** (parse → scan → merge → gerar tipos): descrevia etapas internas do plugin que não constam da fonte.
- **Cortado por redundância:** a tabela comparativa file-based × virtual foi reduzida à distinção que importa (§ 1), já que "vantagens do file-based" pertence a [TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md).
