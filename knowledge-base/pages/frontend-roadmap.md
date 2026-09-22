---
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

Os Zettels acima carregam o raciocínio; a referência de API e as regras normativas ficam em `Docs/`, em três estruturas conduzidas de mesmo formato — hub que roteia, satélites com conceito → exemplo → regras citáveis → antipadrões.

| Hub | Cobre | Entradas diretas |
| --- | --- | --- |
| [React.js](../docs/react-js.md) | componentes, estado, efeitos, Suspense, RSC | [React - Hooks](../docs/react-hooks.md) · [React - Patterns](../docs/react-patterns.md) · [React - Rules of React](../docs/react-rules-of-react.md) |
| [TanStack Router](../docs/tanstack-router.md) | rotas, navegação, search params, loaders | [TanStack Router - Routing Concepts](../docs/tanstack-router-routing-concepts.md) · [TanStack Router - Search Params](../docs/tanstack-router-search-params.md) |
| [TanStack Query](../docs/tanstack-query.md) | estado do servidor, cache, mutations | [TanStack Query - O que um Dev Frontend Precisa Saber](../docs/tanstack-query-o-que-um-dev-frontend-precisa-saber.md) · [TanStack Query - Mutations e Invalidação](../docs/tanstack-query-mutations-e-invalidacao.md) |

As skills que consomem essas docs estão em `Skill/`: `react-review`, `react-build`, `tanstack-router` e `tanstack-query`.

Decisão de arquitetura — onde o código mora e quem pode importar quem — não está nos hubs acima. A entrada é [Architecture in React](architecture-in-react.md), que roteia os eixos de decisão para a nota que responde cada um; a estrutura adotada, com as regras `REACT-ARCH-*` e a verificação por Biome, está em [Feature-Based Architecture](feature-based-architecture.md).

## Revisão por tema

| Tema | Nota de entrada |
| --- | --- |
| Arquitetura e responsabilidades | [Architecture in React](architecture-in-react.md) |
| Estrutura de pastas e fronteiras | [Feature-Based Architecture](feature-based-architecture.md) |
| Coesão por capacidade | |
| Contratos full-stack | |
| Composition | |
| Clean Code | |
| Testes | |
| Data flow | |
| Zod | |
| React Hook Form | |
| Hooks | |
| Persistência | |
| Cache | |
| TanStack Query | |
| Optimistic update | |
| Server Actions | |
| Error handling | |

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
