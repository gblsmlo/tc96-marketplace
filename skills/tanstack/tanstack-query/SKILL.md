---
nome: tanstack-query
descricao: Trabalhar com estado do servidor no TanStack Query — ler dado remoto, política de frescor, mutation e invalidação, update otimista com rollback, listas paginadas e infinitas, integração com o loader de rota — citando IDs `TSQ-*`, com doze sondas executáveis e uma tabela de diagnóstico por sintoma — use quando a tarefa for buscar dado que outra pessoa pode alterar, decidir `staleTime`, invalidar depois de escrever, montar update otimista, paginar, ou entender por que a tela não atualiza ou por que há requests demais. Não use para estado de UI efêmero, que é react-developer, para estado que pertence à URL, que é tanstack-router, nem para cache HTTP, que é http-cache.
tipo: skill
familia: tanstack
fonte: "[TanStack Query](../../../knowledge-base/docs/tanstack-query.md)"
docs:
  - /websites/tanstack_query
tags:
  - skill
  - tanstack-query
  - react
---

# tanstack-query

> **Fonte desta skill:** [TanStack Query](../../../knowledge-base/docs/tanstack-query.md), com os cinco satélites carregados **um por vez**.
> Esta skill **não contém** o texto das regras nem a superfície de API — ela roteia por tarefa e diagnostica por sintoma.
> **Superfície de API:** resolva pelo Context7 — `/websites/tanstack_query`. Assinatura, opção e comportamento por versão vêm de lá; a regra e o ID vêm da knowledge-base.

Contrato que esta skill implementa: [TanStack Query](../../../knowledge-base/docs/tanstack-query.md) § 7.

---

## Quando usar

O dado **vem de um servidor e outra pessoa pode alterá-lo**: ler, escrever, invalidar, paginar, decidir frescor, ou entender o cache.

Antes de tudo, passe pela primeira árvore de [TanStack Query](../../../knowledge-base/docs/tanstack-query.md) § 5 ("Este dado é da Query?"):

| O dado é… | Vá para |
| --- | --- |
| estado de UI efêmero, ou estrutura de componente | `react-developer` · `react-review` |
| estado que pertence à URL (filtro, aba, página, ordenação) | `tanstack-router` |
| dado de uma rota, carregado pelo loader | `tanstack-router`, **e** a tarefa 6 |
| estado global de cliente com escrita frequente | |
| frescor decidido pelo **servidor**, por header | `http-cache` — outra camada |

---

## Carregamento mínimo

```
SEMPRE: TanStack Query § 2 (modelo mental) e § 5 (árvores)
SOB DEMANDA, via § 4: o satélite da tarefa
SE envolve rota/loader: TanStack Router - Carregamento de Dados
NUNCA: todos os satélites de uma vez
```

Os cinco satélites somam mais de 100 KB. **Carregar todos é o erro de contexto mais caro desta doc.**

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/por-tarefa.md` | o mapa tarefa → satélite, e os sete recortes |
| `references/nao-assumir-de-memoria.md` | a assinatura dos callbacks na v5, e as duas camadas de otimismo |
| `references/diagnostico.md` | "a tela não atualiza" e "requests demais", sintoma a sintoma |
| `references/fronteira.md` | o que é de outra skill |
| `references/mapa-de-ids.md` | os 55 `TSQ-*` por satélite e seção |
| `references/exemplo.md` | caso trabalhado |
| `scripts/sondas.sh` | doze sondas sobre o código |
| `scripts/gerar-mapa-de-ids.sh` | regenera o mapa a partir de `Docs/TanStack Query*` |

---

## Passo 1 — Sondar

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/tanstack-query/scripts/sondas.sh src
```

**As duas que mais pagam:**

| Sonda | O que revela |
| --- | --- |
| **S1** — `staleTime` nunca declarado | **todo dado nasce stale** (`TSQ-CACHE-01`): rede a cada montagem, foco de aba e reconexão |
| **S6** — update otimista sem `cancelQueries`/`onError`/`onSettled` | ciclo incompleto (`TSQ-MUT-10`): pisca e volta, ou não faz rollback |

E a que mais engana: **S2**, gatilho desligado como remédio. `refetchOnWindowFocus: false` apaga o sintoma e deixa `refetchOnMount` com a política oposta no mesmo cache — duas regras contraditórias sobre o mesmo dado (`TSQ-CACHE-03`).

---

## Passo 2 — Rotear por tarefa

`references/por-tarefa.md`: ler dado · política de frescor · escrever e invalidar · update otimista · lista paginada · loader de rota · diagnosticar cache.

---

## Passo 3 — Não assumir de memória

`references/nao-assumir-de-memoria.md`:

1. **As assinaturas dos callbacks de mutation mudaram dentro da v5.** O retorno de `onMutate` chega como **terceiro argumento**. Código escrito contra a forma antiga lê o objeto errado, e o rollback **falha em silêncio** (`TSQ-MUT-11`). A forma antiga domina o material de treino — é o que sai por default de código gerado.
2. **Otimismo tem duas camadas.** `useOptimistic` e o update sobre o cache resolvem o mesmo problema em lugares diferentes; usar as duas cria dois estados provisórios com rollbacks independentes. Em qualquer delas, **o otimista nunca é fonte de verdade** (`REACT-FORM-07`).

---

## Passo 4 — Diagnosticar por sintoma

`references/diagnostico.md`, duas tabelas: **"a tela não atualiza"** e **"requests demais"**. Comece pela tabela, abra **um** satélite.

**A correção quase nunca é desligar gatilho** — calibre `staleTime` primeiro (`TSQ-CACHE-03`).

---

## Passo 5 — Fechar

1. **Se o dado é de rota**, o frescor é decidido em **um** cache só: `defaultPreloadStaleTime: 0` (`TSR-LOAD-14`) — `tanstack-router`.
2. **Se o cliente é Eden**, o `queryFn` precisa **lançar** (`ELYSIA-TYPE-09`), senão a query fica em `success` com o erro dentro de `data` — `elysia-schema`.
3. **Se o sintoma é re-render**, confira structural sharing (`TSQ-CACHE-04`) e tracked properties (`TSQ-CACHE-05`) antes de memoizar.
4. **Declare o que não verificou.**

---

## Exemplo

Listagem de faturas com filtro na URL, mutation de aprovação e update otimista: a key inclui o filtro; a mutation faz `cancelQueries` → snapshot → escrita imutável → rollback no `onError` → `invalidateQueries` retornando a Promise no `onSettled`. O que o hábito produziria: key sem o filtro, rollback lendo o argumento errado, e `refetchOnWindowFocus: false` para "resolver" o excesso de requests.

Caso completo: `references/exemplo.md`.

---

## Relacionados

- [TanStack Query](../../../knowledge-base/docs/tanstack-query.md) — fonte desta skill: § 2, § 4, § 5, § 7
- `tanstack-router` — o dado de rota, e o preload
- `react-developer` · `react-review` — o componente em volta
- `elysia-schema` — a ponte com o Eden
- `http-cache` — a camada de cache do servidor
