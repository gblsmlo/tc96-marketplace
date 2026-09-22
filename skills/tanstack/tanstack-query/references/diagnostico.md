# Diagnóstico: sintoma → causa provável → satélite

As duas perguntas mais frequentes sobre esta biblioteca são as duas caras do mesmo eixo. Comece pela tabela, abra **um** satélite.

### "A tela não atualiza"

| Sintoma | Causa provável | Onde |
| --- | --- | --- |
| Trocar filtro/param não refaz a busca | variável usada na `queryFn` fora da key (`TSQ-BASE-03`) — as variações disputam a mesma entrada de cache | [TanStack Query - O que um Dev Frontend Precisa Saber](../../../../knowledge-base/docs/tanstack-query-o-que-um-dev-frontend-precisa-saber.md) |
| Salvou e a lista continua antiga | a mutation não invalida nada, ou invalida prefixo que não cobre o efeito (`TSQ-MUT-07`) | [TanStack Query - Mutations e Invalidação](../../../../knowledge-base/docs/tanstack-query-mutations-e-invalidacao.md) |
| Invalidação roda, não dá erro e não surte efeito | `staleTime: 'static'` na query (`TSQ-CACHE-02`), ou query desabilitada guardando o dado (`TSQ-PATTERN-10`) | [TanStack Query - Cache e Frescor](../../../../knowledge-base/docs/tanstack-query-cache-e-frescor.md) · [TanStack Query - Padrões de Consulta](../../../../knowledge-base/docs/tanstack-query-padroes-de-consulta.md) |
| Cache está certo no devtools, tela não | mutação no lugar em vez de escrita imutável (`TSQ-MUT-08`) — sem nova referência, o React não vê mudança | [TanStack Query - Mutations e Invalidação](../../../../knowledge-base/docs/tanstack-query-mutations-e-invalidacao.md) |
| Botão volta a "Salvar" antes de a lista mudar | callback de invalidação sem `return` da Promise (`TSQ-MUT-02`) | [TanStack Query - Mutations e Invalidação](../../../../knowledge-base/docs/tanstack-query-mutations-e-invalidacao.md) |
| Update otimista pisca e volta | falta `cancelQueries` em `onMutate` (`TSQ-MUT-10`): refetch em voo chega depois e reverte | [TanStack Query - Mutations e Invalidação](../../../../knowledge-base/docs/tanstack-query-mutations-e-invalidacao.md) |
| Erro na escrita e a tela fica no estado otimista | rollback lendo o argumento errado — assinatura antiga de `onError` (`TSQ-MUT-11`) | [TanStack Query - Mutations e Invalidação](../../../../knowledge-base/docs/tanstack-query-mutations-e-invalidacao.md) § 2 |
| Rollback restaura valor errado | snapshot em `useRef`/módulo, sobrescrito por mutation concorrente (`TSQ-MUT-11`) | [TanStack Query - Mutations e Invalidação](../../../../knowledge-base/docs/tanstack-query-mutations-e-invalidacao.md) |
| Spinner que nunca sai | `isPending` em query com `enabled` (`TSQ-BASE-07`), ou `fetchStatus: 'paused'` sem rede (`TSQ-BASE-08`) | [TanStack Query - O que um Dev Frontend Precisa Saber](../../../../knowledge-base/docs/tanstack-query-o-que-um-dev-frontend-precisa-saber.md) § 5 |
| `isSuccess` com `data: undefined` | `select` validando ou lançando (`TSQ-PATTERN-13`) | [TanStack Query - Padrões de Consulta](../../../../knowledge-base/docs/tanstack-query-padroes-de-consulta.md) |
| Dado velho após mutação, com o Query aparentemente certo | router segurando o preload: falta `defaultPreloadStaleTime: 0` (`TSR-LOAD-14`) | [TanStack Router - Carregamento de Dados](../../../../knowledge-base/docs/tanstack-router-carregamento-de-dados.md) § 8 |

### "Requests demais"

| Sintoma | Causa provável | Onde |
| --- | --- | --- |
| Rede a cada montagem, foco de aba e reconexão | `staleTime` nunca declarado (`TSQ-CACHE-01`): todo dado nasce stale | [TanStack Query - Cache e Frescor](../../../../knowledge-base/docs/tanstack-query-cache-e-frescor.md) § 3 |
| Rajada de requisições a cada escrita | `invalidateQueries` sem filtro (`TSQ-MUT-07`), ou `refetchType: 'all'` em prefixo largo | [TanStack Query - Mutations e Invalidação](../../../../knowledge-base/docs/tanstack-query-mutations-e-invalidacao.md) § 3 |
| Voltar para a tela sempre recarrega do zero | `gcTime` baixo: o cache é descartado antes de você voltar | [TanStack Query - Cache e Frescor](../../../../knowledge-base/docs/tanstack-query-cache-e-frescor.md) § 2 |
| Refetch em cascata, dado que não mudou parecendo novo | `Date`/`Map`/`Set` na `queryFn` quebrando structural sharing (`TSQ-CACHE-04`) | [TanStack Query - Cache e Frescor](../../../../knowledge-base/docs/tanstack-query-cache-e-frescor.md) § 5 |
| Re-render a cada `isFetching` | `const { data,...rest }` desligando tracked properties (`TSQ-CACHE-05`) | [TanStack Query - Cache e Frescor](../../../../knowledge-base/docs/tanstack-query-cache-e-frescor.md) § 5 |
| Telas lentas, latências somadas em série | waterfall por `enabled` que a API podia resolver em uma chamada (`TSQ-PATTERN-01`), ou suspense queries lado a lado (`TSQ-PATTERN-03`, `TSQ-SSR-02`) | [TanStack Query - Padrões de Consulta](../../../../knowledge-base/docs/tanstack-query-padroes-de-consulta.md) · [TanStack Query - Suspense e SSR](../../../../knowledge-base/docs/tanstack-query-suspense-e-ssr.md) |
| Invalidar a lista infinita dispara N requisições | falta `maxPages` (`TSQ-PATTERN-08`): o refetch refaz todas as páginas em série | [TanStack Query - Padrões de Consulta](../../../../knowledge-base/docs/tanstack-query-padroes-de-consulta.md) § 4 |
| Busca por digitação deixa N requisições em voo | `queryFn` ignorando o `signal` (`TSQ-SSR-10`) | [TanStack Query - Suspense e SSR](../../../../knowledge-base/docs/tanstack-query-suspense-e-ssr.md) § 5 · |
| Cliente refaz na hidratação tudo que o servidor já buscou | `staleTime: 0` com SSR (`TSQ-SSR-05`) | [TanStack Query - Suspense e SSR](../../../../knowledge-base/docs/tanstack-query-suspense-e-ssr.md) § 3 |

**A correção quase nunca é desligar gatilho.** `refetchOnWindowFocus: false` apaga o sintoma e deixa `refetchOnMount` com a política oposta no mesmo cache — duas regras contraditórias sobre o mesmo dado. Calibre `staleTime` primeiro; desligar gatilho é ajuste fino depois, nunca remédio → `TSQ-CACHE-03`.

---

