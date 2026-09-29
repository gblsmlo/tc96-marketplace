---
titulo: Frontend roadmap
aliases:
  - Estudos de Frontend
tags:
  - frontend
  - react
  - estudos
---
# Frontend roadmap

Este é o índice dos estudos de frontend. A trilha usa o projeto
`/Users/gabs/Workspaces/l/frontend-started` como laboratório prático e os Zettels como memória
conceitual reutilizável.

O avanço acontece por evidência: implementar uma pequena jornada, testar seu comportamento,
registrar o que ficou difícil e somente então introduzir o padrão do nível seguinte.

## Nível 1: Fundamentos explícitos

Objetivo: compreender React e o fluxo da interface antes de delegar coordenação a bibliotecas.

- [x]
- [x]
- [x]
- [x]
- [x]
- [x]
- [x]
- [x]
- [x]
- [x]

### Evidência prática

- Cadastrar e listar tópicos de estudo com props, callbacks e estado local.
- Validar o título e apresentar erros junto ao campo.
- Cobrir loading, vazio, sucesso e falha em testes.
- Explicar o data flow sem depender do nome de uma biblioteca.

## Nível 2: Features e estado remoto

Objetivo: separar responsabilidades e tratar dados da API como estado do servidor.

- [x]
- [x]
- [x]
- [x]
- [x]
- [x]
- [x]
- [x]

### Evidência prática

- Organizar tópicos como feature com componentes, hooks, queries, actions, schemas e testes.
- Validar requests e responses com `Zod` na fronteira HTTP.
- Substituir fetch em `useEffect` por queries e mutations.
- Definir query keys, `staleTime`, invalidação e retry de forma deliberada.

## Nível 3: Boundaries e resiliência

Objetivo: integrar ações, contratos, cache e recuperação de falhas sem acoplar UI ao transporte.

- [x]
- [x]
- [x]
- [x]
- [x]
- [x]

### Evidência prática

- Implementar mutation otimista com cancelamento, snapshot e rollback.
- Isolar uma falha de renderização no boundary da feature.
- Versionar e migrar dados persistidos no navegador.
- Comparar o adapter HTTP dos níveis Vite com Server Actions reais no nível Next.js.
- Cobrir a jornada principal e uma recuperação de falha com E2E.

## Referência do stack

Os Zettels acima carregam o raciocínio; a referência de API e as regras normativas ficam na knowledge-base, em três estruturas conduzidas de mesmo formato — hub que roteia, satélites com conceito → exemplo → regras citáveis → antipadrões.

| Hub | Cobre | Entradas diretas |
| --- | --- | --- |
| [React.js](react-js.md) | componentes, estado, efeitos, Suspense, RSC | [React - Hooks](react-hooks.md) · [React - Patterns](react-patterns.md) · [React - Rules of React](react-rules-of-react.md) |
| [TanStack Router](tanstack-router.md) | rotas, navegação, search params, loaders | [TanStack Router - Routing Concepts](tanstack-router-routing-concepts.md) · [TanStack Router - Search Params](tanstack-router-search-params.md) |
| [TanStack Query](tanstack-query.md) | estado do servidor, cache, mutations | [TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md) · [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) |

As skills que consomem essas docs estão em `Skill/`: `react-review`, `react-build`, `tanstack-router` e `tanstack-query`.

Decisão de arquitetura — onde o código mora e quem pode importar quem — não está nos hubs acima. A entrada é [Architecture in React](architecture-in-react.md), que roteia os eixos de decisão para a nota que responde cada um; a estrutura adotada, com as regras `REACT-ARCH-*` e a verificação por Biome, está em [Feature-Based Architecture](feature-based-architecture.md).

## Revisão por tema

| Tema | Nota de entrada |
| --- | --- |
| Arquitetura e responsabilidades | [Architecture in React](architecture-in-react.md) |
| Estrutura de pastas e fronteiras | [Feature-Based Architecture](feature-based-architecture.md) |
| Coesão por capacidade | [Feature-Based Architecture](feature-based-architecture.md) § 1 |
| Contratos full-stack | [Elysia - Schema e Eden](elysia-schema-e-eden.md) § 7 |
| Composition | [React - Patterns](react-patterns.md) § 3 |
| Clean Code | **gap** — ver observações |
| Testes | [Teste de Software](teste-de-software.md) |
| Data flow | [React - Patterns](react-patterns.md) § 7 |
| Zod | [Elysia - Schema e Eden](elysia-schema-e-eden.md) § 2 |
| React Hook Form | [React Hook Form](react-hook-form.md) |
| Hooks | [React - Hooks](react-hooks.md) |
| Persistência | **gap parcial** — ver observações |
| Cache | [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) · [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) |
| TanStack Query | [TanStack Query](tanstack-query.md) |
| Optimistic update | [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) |
| Server Actions | [React - Server Components e Diretivas](react-server-components-e-diretivas.md) |
| Error handling | [React - Patterns](react-patterns.md) § 6 · [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) |

### Observações da revisão (2026-09-23)

- **Clean Code** — `agents/code-reviewer.md` e `agents/frontend-developer.md` citam um hub
  `Clean Code - React e Node - Mapa de Fundamentos`, mas ele não existe em `knowledge-base/`. É um
  Zettel do vault privado (`_legado/snapshot-2026-09-08/agents/frontend-developer.md` ainda tem o
  wikilink `[[Clean Code - React e Node]]`) que nunca foi migrado nem virou skill. Referência
  pendurada: dois agentes ativos citam um recurso que não resolve.
- **Persistência** — cobre bem o lado servidor (`drizzle-review`, mas a própria skill registra que
  "não há skill de build ainda"). Do lado navegador, [React - Patterns](react-patterns.md) § 2
  tem só a linha "Persistido no browser · precisa versão e validação" sem ID `REACT-PAT-*`, sem
  exemplo e sem sonda em `react-developer`/`react-review` — é o único ponto da tabela de posse de
  estado sem regra citável, e é exatamente a lacuna que a evidência do Nível 3 ("versionar e migrar
  dados persistidos no navegador") pede para fechar.
- Vários eixos de [Architecture in React](architecture-in-react.md) § 2 (Posse de estado, Fluxo de
  dados e contratos, Fronteiras de falha, Verificação) têm "Nota de entrada" em branco mesmo quando o
  conteúdo já existe na knowledge-base — essa página-roteadora ficou para trás em relação ao conteúdo real e
  vale uma passada separada.

## Evidência concluída

Em 2026-08-08, os três clientes concluíram a mesma jornada de criar, concluir e excluir um tópico
contra uma API Bun e SQLite. O repositório contém contratos, testes unitários e de integração,
migração de persistência, Error Boundary e E2E isolado por nível.

## Fontes principais

- [Frontend Developer Roadmap](https://roadmap.sh/frontend)
- [React Developer Roadmap](https://roadmap.sh/react)
- [React — Learn](https://react.dev/learn)
- [TanStack Query](https://tanstack.com/query/latest/docs/framework/react/overview)
- [React Hook Form](https://react-hook-form.com/get-started)
- [Zod](https://zod.dev/)
