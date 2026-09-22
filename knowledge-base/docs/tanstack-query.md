---
titulo: TanStack Query
Link: https://tanstack.com/query/latest/docs/framework/react/overview
tags:
  - tanstack-query
  - data-fetching
  - server-state
  - reference
  - agent-context
source: "Documentação oficial — tanstack.com/query/latest/docs/framework/react"
verificado-em: 2026-08-14
---

# TanStack Query

> Ponto de entrada único para estado do servidor neste vault. Mesmo formato de [React.js](react-js.md) e [TanStack Router](tanstack-router.md): roteador de documentação, não resumo linear. Regras citáveis por ID (`TSQ-*`).
>
> Quando esta nota divergir de [tanstack.com/query](https://tanstack.com/query/latest/docs/framework/react/overview), a fonte vence.

---

## 1. Como usar esta doc

| Passo | Carregar | Quando |
| --- | --- | --- |
| 1 | Esta nota (§ 2, § 4, § 5) | Sempre que a tarefa envolver dado remoto |
| 2 | O satélite da tarefa — use § 4 | Quando toca uma API concreta |
| 3 | [React.js](react-js.md) | Se a tarefa também mexe em componente/estado |

**Regra de economia de contexto:** nunca carregue todos os satélites.

---

## 2. Modelo mental

**1. Estado do servidor não é estado de cliente.** É a distinção que sustenta a biblioteca inteira. Dado remoto é persistido em lugar que você não controla, exige API assíncrona, tem **propriedade compartilhada** — outra pessoa pode alterá-lo sem você saber — e por isso pode estar desatualizado a qualquer momento. `useState` não modela nada disso.

**2. Você não gerencia o dado. Você declara como obtê-lo e quando ele está velho.** Não existe "salvar a resposta no estado": existe uma query com uma chave, uma função e uma política de frescor. O cache é a fonte de verdade, e é compartilhado por todos os componentes que usam a mesma chave.

**3. A query key é a identidade do dado.** Tudo — cache, deduplicação, invalidação, refetch — gira em torno dela. Se a função de busca depende de uma variável, essa variável **pertence à chave**. Esquecer isso é a causa raiz da maioria dos bugs de dado velho.

**4. `stale` e `loading` são eixos independentes.** Um dado pode estar em cache (então há o que mostrar) e simultaneamente sendo revalidado em background. Confundir "não tenho dado" com "estou buscando" produz spinners que piscam sobre conteúdo que já estava na tela.

**5. Escrita não atualiza a tela — invalidação atualiza.** Depois de uma mutation, o trabalho não acabou: é preciso decidir o que ficou velho. Essa decisão é a parte que mais se erra, e é o assunto de [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md).

O raciocínio conceitual do vault está em e.

---

## 3. O que a biblioteca resolve de fábrica

Vale saber para não reimplementar à mão. Conforme a documentação oficial, ela cobre: cache, deduplicação de requisições redundantes, revalidação automática de dado velho, detecção de desatualização, atualização rápida da UI, paginação e lazy loading, gerenciamento de memória e coleta de lixo do cache, e memoização de resultado com *structural sharing*.

Se o código está resolvendo qualquer um desses manualmente, provavelmente está lutando contra a biblioteca.

---

## 4. Mapa por tarefa

| Preciso… | Satélite |
| --- | --- |
| Entender server state, setup, query keys, query functions, `status` × `fetchStatus` | [TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md) |
| Definir política de frescor: `staleTime`, `gcTime`, quando refetch acontece | [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) |
| Escrever: mutations, invalidação, update otimista, escrita direta no cache | [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) |
| Queries dependentes, paralelas, paginadas, infinitas, lazy, prefetch, `select` | [TanStack Query - Padrões de Consulta](tanstack-query-padroes-de-consulta.md) |
| `useSuspenseQuery`, SSR/hydration, cancelamento, network mode | [TanStack Query - Suspense e SSR](tanstack-query-suspense-e-ssr.md) |

---

## 5. Árvores de decisão

### Este dado é da Query?

```
O dado vem de um servidor e outra pessoa pode alterá-lo?
├── SIM → é estado do servidor. Query.
└── NÃO
    ├── É estado de UI efêmero → useState
    ├── Precisa sobreviver a refresh / ser link → search param da rota
    │   → [TanStack Router - Search Params](tanstack-router-search-params.md)
    └── É estado global de cliente com escrita frequente →
```

Guardar a resposta de uma query em `useState` cria uma segunda fonte de verdade que diverge na primeira revalidação. É `REACT-PAT-03` em [React - Patterns](react-patterns.md).

### Qual `staleTime`?

```
Com que frequência este dado muda, e o que custa mostrá-lo velho?
├── Praticamente imutável (país, moeda, enum de domínio)
│   → staleTime alto (minutos a horas). Refetch é desperdício.
├── Muda com o uso, mas ver velho por segundos é inofensivo
│   → staleTime médio. O caso mais comum.
└── Precisa estar sempre correto (saldo, estoque, permissão)
    → staleTime baixo ou zero, e revalide após ações que o afetam
```

`staleTime: 0` — o padrão — significa "sempre velho": revalida em cada montagem, foco de janela e reconexão. Isso é seguro, não gratuito..

### Escrevi no servidor. E agora?

```
O que a escrita tornou velho?
├── Uma ou poucas listas/detalhes conhecidos
│   → invalidateQueries nas chaves afetadas. É o padrão. Prefira isto.
├── O servidor já devolveu o recurso atualizado na resposta
│   → setQueryData para gravar direto, e considere invalidar mesmo assim
└── Preciso de feedback instantâneo antes da resposta chegar
    → update otimista com snapshot e rollback
      →
```

Invalidar de menos deixa tela velha; invalidar de mais transforma cada escrita numa cascata de requests. Detalhe em [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md).

### Feedback instantâneo: qual camada?

```
O dado que você quer mostrar otimisticamente vive no cache da Query?
├── SIM → mutation otimista: snapshot em onMutate, rollback em onError
│         → [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) § 5
└── NÃO (estado local, formulário sem cache remoto)
    → useOptimistic do React
      → [React - Formulários e Actions](react-formularios-e-actions.md) § 5
```

**Nunca as duas no mesmo dado** — viram duas fontes de verdade divergindo. É `REACT-FORM-07`.

---

## 5.1 Diagnóstico por sintoma

As duas perguntas mais comuns sobre esta biblioteca são "não atualiza" e "atualiza demais". As causas estão espalhadas por satélites diferentes, então esta tabela é o índice que falta — vá direto à causa candidata em vez de ler tudo.

### "Escrevi no servidor e a tela não atualiza"

Em ordem de probabilidade:

| # | Causa | Como confirmar | Onde |
| --- | --- | --- | --- |
| 1 | Não invalidou, ou invalidou key que não casa | a invalidação casa **por prefixo**; `exact: true` ou prefixo mais fundo que a key da lista não casa | `TSQ-MUT-07` · [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) |
| 2 | A key da lista não é a que você acha | ordem de itens soltos no array importa; dentro de objeto, não | `TSQ-BASE-02/03` · [TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md) |
| 3 | `refetchType` — a lista está em rota não montada | default é `'active'`: inativas são só marcadas, refazem ao montar | `TSQ-MUT-07` · [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) |
| 4 | A query está desabilitada (`enabled: false`) | query desabilitada **ignora** `invalidateQueries` e `refetchQueries` | `TSQ-PATTERN-10` · [TanStack Query - Padrões de Consulta](tanstack-query-padroes-de-consulta.md) |
| 5 | `staleTime: 'static'` na lista | `'static'` nunca refaz, nem sob invalidação manual. Use `Infinity` se quiser o extremo preservando invalidação | `TSQ-CACHE-02` · [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) |
| 6 | `setQueryData` mutando no lugar | o cache está certo e a tela não muda: quebrou structural sharing | `TSQ-MUT-08` · [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) |
| 7 | A lista foi copiada para `useState` | o cache atualiza, a cópia local fica para trás | `REACT-PAT-03` · [React - Patterns](react-patterns.md) |
| 8 | Não é "não atualiza", é "atualiza tarde" | sem `return` da Promise de invalidação, a mutation sai de `pending` antes do refetch terminar | `TSQ-MUT-02` · [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) |

As causas 4 e 5 são as que mais custam a achar, porque a invalidação roda, não dá erro, e não faz nada.

### "Requests demais — cada foco de aba dispara tudo"

| Causa | Correção | Onde |
| --- | --- | --- |
| `staleTime: 0`, o default | calibrar por volatilidade do dado, não por peso da tela | `TSQ-CACHE-01` · [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) |
| Tentaram corrigir com `refetchOnWindowFocus: false` | **antipadrão**: apaga o sintoma e deixa `refetchOnMount` com política oposta | `TSQ-CACHE-03` · idem |
| `staleTime` alto com `gcTime` default | não revalida enquanto ativa e perde tudo ao trocar de tela | [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) |

`staleTime` alto **não** isola a query das suas próprias escritas: `invalidateQueries` atravessa qualquer `staleTime` — exceto `'static'`.

**Instrumento de diagnóstico:** as Devtools mostram em runtime sob qual key cada dado está cacheado e em que estado. Para as causas 1, 2 e 4 acima, elas respondem em segundos o que a leitura de código demora a revelar.

---

## 6. Regras normativas

| Família | Assunto | Satélite |
| --- | --- | --- |
| `TSQ-BASE-*` | keys, query functions, estados | [TanStack Query - O que um Dev Frontend Precisa Saber](tanstack-query-o-que-um-dev-frontend-precisa-saber.md) |
| `TSQ-CACHE-*` | frescor, ciclo de vida, refetch | [TanStack Query - Cache e Frescor](tanstack-query-cache-e-frescor.md) |
| `TSQ-MUT-*` | escrita, invalidação, otimismo | [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) |
| `TSQ-PATTERN-*` | padrões de consulta | [TanStack Query - Padrões de Consulta](tanstack-query-padroes-de-consulta.md) |
| `TSQ-SSR-*` | Suspense, SSR, network mode | [TanStack Query - Suspense e SSR](tanstack-query-suspense-e-ssr.md) |

---

## 7. Contrato de skill

```
SEMPRE:   docs/TanStack Query.md § 2 (modelo mental)
                                 § 5 (árvores de decisão)

SOB DEMANDA, via § 4:
          o satélite da tarefa

SE a tarefa envolve rota/loader:
          docs/TanStack Router - Carregamento de Dados.md

NUNCA:    todos os satélites de uma vez
```

Invariantes:

1. **Dado remoto nunca vira `useState`** como fonte de verdade (`REACT-PAT-03`).
2. **Toda variável usada na query function pertence à query key.**
3. **Toda mutation declara o que invalida** — ou justifica por que nada precisa ser invalidado.
4. **`staleTime` é decisão deliberada**, não default aceito por omissão.
5. **A fronteira HTTP valida** — response não é confiável só por ter chegado..

---

## 8. Pontes

| Assunto | Onde |
| --- | --- |
| Rotas, loaders, search params | [TanStack Router](tanstack-router.md) |
| Por que não buscar dados em `useEffect` | `REACT-EFFECT-06` em [React - Efeitos e Sincronização](react-efeitos-e-sincronizacao.md) |
| `<Suspense>` e Error Boundaries | [React - Suspense e Assincronia](react-suspense-e-assincronia.md) |
| Update otimista: qual camada é dona | `REACT-FORM-07` em [React - Formulários e Actions](react-formularios-e-actions.md) |
| Validação de contrato na fronteira | · |
| Erro esperado × inesperado | |

---

## Relacionados

- [React.js](react-js.md) · [TanStack Router](tanstack-router.md) — estruturas irmãs, mesmo formato
- [Frontend roadmap](../pages/frontend-roadmap.md) — trilha de estudos
- Zettels: · · ·

## Fontes consultadas

- [Overview](https://tanstack.com/query/latest/docs/framework/react/overview), verificado em 2026-08-14

**Nota de verificação:** a página de overview **não declara número de versão maior**. Os satélites registram a versão que cada um verificou.
