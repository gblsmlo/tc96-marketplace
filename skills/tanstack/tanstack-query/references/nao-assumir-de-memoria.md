# Dois pontos que não se assumem de memória

### As assinaturas dos callbacks de mutation mudaram dentro da v5

**Confira em [TanStack Query - Mutations e Invalidação](../../../../knowledge-base/docs/tanstack-query-mutations-e-invalidacao.md) § 2 ("As assinaturas dos callbacks") toda vez que tocar em mutation com `onMutate`, e sempre em update otimista.** Não escreva de cabeça e não copie de exemplo encontrado fora do vault.

O que muda o resultado: **o retorno de `onMutate` chega como o terceiro argumento**, e `context` passou a ser o último e a ser outra coisa. Código escrito contra a forma antiga lê o objeto errado — o rollback recebe `undefined` e **falha em silêncio**: a mutation "trata" o erro, a tela não volta ao estado anterior, e nada estoura.

Por que isto está aqui e não é detalhe de doc: a assinatura antiga domina o material de treino, então é exatamente o que código gerado por IA produz por default. TypeScript pega — desde que os tipos não estejam frouxos no ponto do callback.

Regras envolvidas: `TSQ-MUT-11` (o snapshot trafega pelo retorno de `onMutate`) e `TSQ-MUT-10` (ciclo completo). A checklist do satélite fecha com essa conferência como item próprio.

### Otimismo tem duas camadas — escolha uma, e declare qual

`useOptimistic` do React e o update otimista sobre o cache da Query resolvem o mesmo problema em camadas diferentes. Usar as duas no mesmo fluxo cria dois estados provisórios que convergem em momentos distintos, com rollbacks independentes.

| Critério | Camada |
| --- | --- |
| O dado otimista aparece em **um** lugar, dentro de um formulário/Action | `useOptimistic` — [React - Formulários e Actions](../../../../knowledge-base/docs/react-formularios-e-actions.md) § 5 |
| Aparece em mais de um lugar, ou precisa sobreviver à navegação | cache da Query, ciclo completo — `TSQ-MUT-10` |
| É um item só na lista e o cache não precisa ser tocado | renderizar as `variables` da mutation enquanto `pending` — a versão que não tem como dar rollback errado ([TanStack Query - Mutations e Invalidação](../../../../knowledge-base/docs/tanstack-query-mutations-e-invalidacao.md) § 5) |

Em qualquer das três, **o otimista nunca é fonte de verdade** — `REACT-FORM-07`. A verdade converge do servidor: no React, ao fim da Action; na Query, na invalidação de `onSettled`. Um rollback é automático (`useOptimistic`), o outro é explícito com snapshot (Query) — confundir os dois é como se escreve rollback que não roda.

---

