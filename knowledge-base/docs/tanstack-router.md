---
titulo: TanStack Router
Link: https://tanstack.com/router/latest/docs/framework/react/overview
tags:
 - tanstack-router
 - routing
 - frontend
 - reference
 - agent-context
source: "Documentação oficial — tanstack.com/router/latest/docs/framework/react"
verificado-em: 2026-08-14
---

# TanStack Router

> Ponto de entrada único para roteamento neste vault. Como [React.js](react-js.md), não é resumo linear — é **roteador de documentação**: decide o que carregar, dá o modelo mental, e expõe regras citáveis por ID (`TSR-*`).
>
> Quando esta nota divergir de [tanstack.com/router](https://tanstack.com/router/latest/docs/framework/react/overview), a fonte vence e esta nota é o bug.

---

## 1. Como usar esta doc

### Para um agente de código

| Passo | Carregar | Quando |
| --- | --- | --- |
| 1 | Esta nota (§ 2, § 4, § 5) | Sempre que a tarefa envolver rotas |
| 2 | O satélite da tarefa — use § 4 | Quando toca uma API concreta |
| 3 | [React.js](react-js.md) | Se a tarefa também mexe em componente/estado |

**Regra de economia de contexto:** nunca carregue todos os satélites. As cinco notas de definição de rota somam milhares de linhas — carregue só a que a tarefa exige.

**Todos os exemplos são TypeScript.** Em TanStack Router isso não é preferência: a biblioteca é construída em torno de inferência de tipos, e em JavaScript puro você perde a maior parte do valor dela.

---

## 2. Modelo mental

Cinco afirmações. A maior parte do código de roteamento mal escrito viola uma delas.

**1. Uma rota é um contrato tipado, não uma string.** `to="/posts/$postId"` é verificado em tempo de compilação: rota inexistente, param faltando ou search param inválido são **erro de tipo**, não bug de runtime. Escrever `href` cru ou montar caminho por concatenação joga fora a única garantia que a biblioteca oferece.

**2. Search params são estado da aplicação.** A documentação os descreve como *"like having `useState` right in the URL"*: parseados de JSON, validados por schema, tipados, com subscrição fina. Filtro, aba, ordenação e paginação pertencem ali — não a `useState`. É a mesma conclusão de `REACT-PAT-10` em [React - Patterns](react-patterns.md), vista do lado do roteador.

**3. Dados carregam antes do componente, não depois.** O `loader` da rota dispara durante a transição, em paralelo com o carregamento do código. Buscar dados dentro do componente cria o waterfall que `REACT-EFFECT-06` proíbe — ver [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md).

**4. A árvore de rotas é hierárquica em três coisas ao mesmo tempo:** layout (o que envolve o quê), contexto (o que desce como dependência tipada) e dados (o que já está carregado quando o filho renderiza). Desenhar a árvore é decidir as três de uma vez.

**5. A precedência de match é determinística.** Rotas não são testadas na ordem em que você as declarou: há uma ordem de especificidade. Saber qual é evita a categoria inteira de "minha rota nunca é atingida" — ver [TanStack Router - Route Matching](tanstack-router-route-matching.md).

---

## 3. As duas formas de declarar rotas

Decisão que vem antes de qualquer outra, porque muda a estrutura do projeto.

| | File-based | Code-based |
| --- | --- | --- |
| Onde a rota vive | no caminho do arquivo | em `createRoute` explícito |
| Geração de tipos | automática, por plugin de build | manual, via `getParentRoute` |
| Recomendação oficial | **preferida** | quando o file-based não expressa a estrutura |
| Satélite | [TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md) | [TanStack Router - Route Trees](tanstack-router-route-trees.md) |

As duas **coexistem** no mesmo projeto, e [TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md) é a ponte: mapeia estrutura física arbitrária para uma árvore lógica.

---

## 4. Mapa por tarefa

A coluna **Satélite** diz o que carregar. Se a tarefa não está aqui, ela não foi verificada nesta doc — consulte a fonte.

| Preciso… | Satélite |
| --- | --- |
| Entender anatomia de rota, rota raiz, index, dinâmica, splat, layout, pathless | [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md) |
| Nomear arquivos e pastas, entender convenções e o `routeTree.gen.ts` | [TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md) |
| Montar a árvore em código, tipar `getParentRoute`, comparar as abordagens | [TanStack Router - Route Trees](tanstack-router-route-trees.md) |
| Saber por que uma rota casa (ou não) e em que ordem | [TanStack Router - Route Matching](tanstack-router-route-matching.md) |
| Mapear estrutura de arquivos não convencional para rotas | [TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md) |
| Navegar: `<Link>`, `useNavigate`, `redirect`, preload, bloqueio de saída | [TanStack Router - Navegação](tanstack-router-navegacao.md) |
| Ler e escrever search params tipados e validados | [TanStack Router - Search Params](tanstack-router-search-params.md) |
| Carregar dados: `loader`, `beforeLoad`, pending/error, integração com Query | [TanStack Router - Carregamento de Dados](tanstack-router-carregamento-de-dados.md) |
| Proteger rota: autenticação (`beforeLoad` + `throw redirect`) e autorização por papel | [TanStack Router - Carregamento de Dados](tanstack-router-carregamento-de-dados.md) · § 5.1 abaixo |
| Injetar dependências por rota e dividir o bundle | [TanStack Router - Route Context e Code Splitting](tanstack-router-route-context-e-code-splitting.md) |
| `notFound`, `notFoundComponent`, `router.invalidate` | [TanStack Router - Carregamento de Dados](tanstack-router-carregamento-de-dados.md) |
| Search middlewares (`stripSearchParams`, `retainSearchParams`) e serialização customizada | [TanStack Router - Search Params](tanstack-router-search-params.md) |
| `useMatches`, `useRouterState`, breadcrumbs | [TanStack Router - Navegação](tanstack-router-navegacao.md) |
| Route masking e `linkOptions` | [TanStack Router - Navegação](tanstack-router-navegacao.md) |

---

## 5. Árvores de decisão

### Que tipo de rota eu preciso?

```
O caminho tem um segmento variável?
├── SIM
│ ├── Um segmento → rota dinâmica /posts/$postId
│ └── O resto todo do caminho → splat /files/$
└── NÃO
 └── Preciso envolver filhos em UI compartilhada?
 ├── SIM
 │ ├── e o wrapper deve aparecer na URL → layout route
 │ └── e NÃO deve aparecer na URL → pathless layout route
 └── NÃO
 ├── É o conteúdo do próprio caminho do pai → index route
 └── Caso geral → rota básica
```

Definições e exemplos de cada tipo em [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md).

### Como eu navego?

```
A navegação é iniciada por um clique do usuário num elemento?
├── SIM → <Link>. Sempre.
│ Dá href real (abre em nova aba, é indexável, acessível),
│ type safety e preload.
└── NÃO
 ├── Consequência de uma ação (submit, timeout, login)
 │ → useNavigate
 └── Dentro de beforeLoad/loader — guarda de rota, sessão inválida
 → redirect (lançado, não retornado)
```

`<Link>` não é "a versão bonita" de navigate: é a única forma que produz um elemento navegável de verdade. Detalhes em [TanStack Router - Navegação](tanstack-router-navegacao.md).

### Onde guardo este estado?

```
O estado precisa sobreviver a refresh, ser compartilhável por link,
ou responder ao botão voltar?
├── SIM → search param da rota, validado por schema
│ (filtro, aba, página, ordenação, faixa de datas)
│ → [TanStack Router - Search Params](tanstack-router-search-params.md)
└── NÃO → é estado efêmero de UI. useState no componente.
 (menu aberto, hover, foco, rascunho de campo)
 → [React - Patterns](react-patterns.md) § 2
```

### Como carrego os dados desta rota?

```
Os dados são necessários para a rota renderizar?
├── NÃO → carregue no componente, sob <Suspense> ou com estado próprio
└── SIM
 ├── O projeto usa TanStack Query?
 │ ├── SIM → loader chama ensureQueryData; o componente usa
 │ │ useSuspenseQuery. O cache é da Query, o loader
 │ │ só garante que já foi buscado.
 │ │ → [TanStack Query](tanstack-query.md)
 │ └── NÃO → loader nativo + useLoaderData, com staleTime da rota
 └── É uma checagem de acesso, não dados?
 → beforeLoad, que roda antes e pode redirect
```

Detalhe e o porquê da integração em [TanStack Router - Carregamento de Dados](tanstack-router-carregamento-de-dados.md).

---

## 5.1 Proteger uma rota

Autenticação e autorização são decisões diferentes e terminam em lugares diferentes.

```
O usuário está autenticado?
├── NÃO → throw redirect({ to: '/login', search: { redirect: location.href } })
│ em beforeLoad. Nunca em componente ou Effect: lá o loader
│ protegido já rodou e o dado já vazou.
└── SIM
 └── Tem o papel/permissão necessário?
 ├── NÃO → NÃO redirecione. É erro esperado (403): renderize
 │ a tela de acesso negado como ESTADO da rota.
 │ Jogar para um boundary transforma "sem permissão"
 │ em tela de erro genérica. → REACT-ASYNC-09
 └── SIM → siga
```

Três coisas que essa árvore assume e que precisam estar ditas:

**`redirect` precisa ser lançado.** `redirect({...})` como statement solto cria um objeto e o descarta — a guarda não acontece, sem erro. `TSR-NAV-10`.

**A guarda do router não é segurança.** Ela evita tela vazia e melhora UX; a autorização real é do backend. A tabela de camadas de enforcement está em `WorkOS - RBAC` § 4, que classifica o `beforeLoad` do TanStack Router exatamente como camada de UX. `TSR-NAV-12` e `TSR-CTX-07`.

**Voltar ao destino depois do login** guarda-se em search param (`search: { redirect: location.href }`) e consome-se no `/login`. O lado do consumo, com a validação anti-open-redirect obrigatória, está em [TanStack Router - Search Params](tanstack-router-search-params.md).

---

## 6. Regras normativas

Famílias por satélite. Cada satélite define as suas com numeração contígua.

| Família | Assunto | Satélite |
| --- | --- | --- |
| `TSR-ROUTE-*` | tipos de rota e anatomia | [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md) |
| `TSR-FILE-*` | convenções de arquivo | [TanStack Router - File-Based Routing](tanstack-router-file-based-routing.md) |
| `TSR-TREE-*` | montagem da árvore | [TanStack Router - Route Trees](tanstack-router-route-trees.md) |
| `TSR-MATCH-*` | precedência de match | [TanStack Router - Route Matching](tanstack-router-route-matching.md) |
| `TSR-VIRTUAL-*` | rotas virtuais | [TanStack Router - Virtual File Routes](tanstack-router-virtual-file-routes.md) |
| `TSR-NAV-*` | navegação | [TanStack Router - Navegação](tanstack-router-navegacao.md) |
| `TSR-SEARCH-*` | search params | [TanStack Router - Search Params](tanstack-router-search-params.md) |
| `TSR-LOAD-*` | carregamento de dados | [TanStack Router - Carregamento de Dados](tanstack-router-carregamento-de-dados.md) |
| `TSR-CTX-*` · `TSR-SPLIT-*` | contexto e code splitting | [TanStack Router - Route Context e Code Splitting](tanstack-router-route-context-e-code-splitting.md) |

### 6.1 IDs canônicos

Alguns princípios aparecem em mais de um satélite, porque cada um precisa se sustentar sozinho. **Cite sempre o canônico** — os apelidos não devem aparecer em revisão.

| Princípio | Canônico | Apelidos |
| --- | --- | --- |
| `defaultPreloadStaleTime: 0` com TanStack Query no loader | `TSR-LOAD-14` | `TSR-NAV-08` |
| Mesmo objeto `queryOptions` entre loader e componente | `TSR-LOAD-15` | `TSQ-BASE-09`, `TSQ-PATTERN-12` |
| Raiz com `createRootRouteWithContext<T>` | `TSR-CTX-02` | `TSR-ROUTE-03` |
| Guarda de rota não substitui autorização no backend | `TSR-CTX-07` | `TSR-NAV-12` |
| Ler dados fora do route file exige `getRouteApi` | `TSR-LOAD-07` | `TSR-ROUTE-05` |
| Fronteira crítico × lazy no code splitting | `TSR-SPLIT-01` | `TSR-SPLIT-02` (é o complemento da mesma regra) |

E dois princípios do React que o Router **não** redefine — cite o ID do React:

| Princípio | Canônico | Onde o Router o menciona |
| --- | --- | --- |
| Dado de rota nunca vem de `fetch` em `useEffect` | `REACT-EFFECT-06` | `TSR-LOAD-01` é apelido |
| Valor que vive no search nunca é copiado para `useState` | `REACT-PAT-01` + `REACT-PAT-03` | `TSR-SEARCH-09` é apelido |

---

## 7. Contrato de skill

```
SEMPRE: Docs/TanStack Router.md § 2 (modelo mental)
 § 5 (árvores de decisão)

SOB DEMANDA, via § 4:
 o satélite da tarefa

SE a tarefa também mexe em componente/estado:
 Docs/React.js.md

NUNCA: todos os satélites de uma vez
```

Invariantes que a skill faz valer:

1. **Type safety não é opcional.** Caminho montado por string, `any` em params ou search, e `@ts-expect-error` em rota são regressão — a biblioteca inteira existe para evitá-los.
2. **Verificar antes de afirmar.** Se uma API não está na § 4, não foi verificada aqui. Consulte a fonte e atualize a nota.
3. **A fonte vence.** Divergência entre esta nota e tanstack.com é bug desta nota.
4. **Search param antes de estado local**, sempre que o critério da § 5 se aplicar.
5. **Dados no loader antes do componente**, quando os dados são condição para renderizar.

Skill correspondente: `tanstack-router`.

---

## 8. Pontes

| Assunto | Onde |
| --- | --- |
| Estado do servidor, cache, invalidação | [TanStack Query](tanstack-query.md) |
| Estado de componente, efeitos, Suspense | [React.js](react-js.md) |
| Critério "isto pertence à URL?" pelo lado do React | `REACT-PAT-10` em [React - Patterns](react-patterns.md) |
| Por que não buscar dados em `useEffect` | `REACT-EFFECT-06` em [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md) |
| Validação de search params por schema | |
| Boundaries de erro e espera | [React - Suspense e Assincronia](react-suspense-e-assincronia.md) · |

---

## Relacionados

- [React.js](react-js.md) — estrutura irmã, mesmo formato
- [TanStack Query](tanstack-query.md) — estado do servidor
- [Frontend roadmap](../pages/frontend-roadmap.md) — trilha de estudos
- [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md) · [TanStack Router - Navegação](tanstack-router-navegacao.md) · [TanStack Router - Search Params](tanstack-router-search-params.md)

## Fontes consultadas

- [Overview](https://tanstack.com/router/latest/docs/framework/react/overview), verificado em 2026-08-14

**Nota de verificação:** a página de overview **não declara número de versão maior** nem menciona TanStack Start. Os três objetivos de projeto citados na § 2 — type safety, search params como estado, data loading integrado — são declarados literalmente ali.
