---
nome: tanstack-router
descricao: Trabalhar com roteamento no TanStack Router — definir e aninhar rotas, navegar com `<Link>`, search params tipados e validados, loader e integração com cache, contexto de rota e code splitting — citando IDs `TSR-*`, com dezesseis sondas executáveis — use quando a tarefa for criar ou aninhar rota, montar navegação, validar e ler search params, decidir entre loader e Query, proteger rota por guarda, ou dividir bundle. Não use para o dado remoto em si, que é tanstack-query, nem para o interior dos componentes, que é react-developer e react-review.
tipo: skill
familia: tanstack
fonte: "[TanStack Router](../../../knowledge-base/docs/tanstack-router.md)"
tags:
  - skill
  - tanstack-router
  - react
---

# tanstack-router

> **Fonte desta skill:** [TanStack Router](../../../knowledge-base/docs/tanstack-router.md) e os dez satélites, carregados **um por tarefa**.
> Esta skill **não contém** procedimento técnico de API — ela roteia por tarefa, cita a regra e diz o que verificar.

> **O que mudou nesta versão.** A anterior trazia um "aviso de estado da doc" dizendo que os satélites estavam **em construção**, e por isso **não citava ID nenhum** — emprestava `REACT-*`. Os dez satélites hoje existem e somam **102 regras `TSR-*`**. O aviso saiu; cada tarefa passou a ter família citável, e o mapa é gerado da doc.

---

## Quando usar

A pergunta é sobre **rota, navegação, URL ou carregamento de rota**.

| Situação | Vá para |
| --- | --- |
| o dado remoto em si: frescor, invalidação, otimismo | `tanstack-query` |
| o interior do componente | `react-developer` · `react-review` |
| onde o arquivo mora na feature | `react-structure` |
| formulário multi-etapa (o **valor** é do form; a **etapa** é da URL) | `react-hook-form` |

---

## Carregamento mínimo

1. Identifique **a tarefa** em `references/por-tarefa.md`.
2. Carregue apenas os satélites da coluna "Carregar", na ordem indicada.
3. Percorra os itens de "Verificar" antes de dar a tarefa por concluída.

**Nunca carregue os dez satélites de uma vez.**

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/por-tarefa.md` | as sete tarefas: o que carregar e o que verificar |
| `references/regras-por-tarefa.md` | as famílias `TSR-*` por tarefa, e as regras que decidem a maior parte dos casos |
| `references/fronteira.md` | o que é de React e não do router |
| `references/mapa-de-ids.md` | os 102 `TSR-*` por satélite e seção |
| `references/exemplo.md` | caso trabalhado |
| `scripts/sondas.sh` | dezesseis sondas sobre rota, navegação, search e loader |
| `scripts/gerar-mapa-de-ids.sh` | regenera o mapa a partir de `Docs/TanStack Router*` |

---

## Passo 1 — Sondar

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/tanstack-router/scripts/sondas.sh src
```

**As duas que mais pagam:**

| Sonda | O que revela |
| --- | --- |
| **S5** — rota que lê search **sem `validateSearch`** | sem schema não há tipo, não há default e não há garantia de forma (`TSR-SEARCH-01`) |
| **S15** — loader usando Query **sem `defaultPreloadStaleTime: 0`** | dois caches decidindo frescor (`TSR-LOAD-14`) — o sintoma aparece como "dado velho com o Query aparentemente certo" |

E a mais frequente em código gerado: **S1**, `to` com string interpolada (`TSR-NAV-01`) — path param vai em `params`, query em `search`.

---

## Passo 2 — Rotear por tarefa

`references/por-tarefa.md`: definir rota · entender o match · navegar · search params · carregar dados · dividir bundle · árvore virtual.

As famílias e as regras decisivas de cada uma: `references/regras-por-tarefa.md`.

---

## Passo 3 — As fronteiras que decidem citação

- **`TSR-LOAD-01` é apelido de `REACT-EFFECT-06`** — buscar dado da primeira renderização em `useEffect` é o mesmo defeito, visto do router. Em revisão que cruza docs, cite o canônico do React.
- **`TSR-NAV-08` é apelido de `TSR-LOAD-14`** — cite o canônico.
- **A etapa do wizard é da URL** (`REACT-PAT-10`); o **valor** dos campos é do formulário (`react-hook-form`).

---

## Passo 4 — Fechar

1. **Se o loader usa Query**, o frescor é decidido em **um** cache — `defaultPreloadStaleTime: 0`.
2. **Se a guarda está num efeito**, ela está no lugar errado: é `throw redirect(...)` em `beforeLoad` (`TSR-LOAD-06`).
3. **Se a rota tem `loader`**, ela precisa de `errorComponent` (`TSR-LOAD-09`) — senão a falha sobe para a raiz.
4. **Declare o que não verificou.** Se a nota que a tarefa exige estiver incompleta, consulte a doc oficial, **declare a limitação** e registre o que foi verificado — não preencha lacuna de memória.

---

## Exemplo

Listagem com filtro, página e ordenação na URL: `validateSearch` com `.catch`/`.default` por chave, `loaderDeps` devolvendo **só** as chaves que o loader lê, `<Link>` com `params`/`search` em vez de string interpolada, e `defaultPreloadStaleTime: 0` porque o loader usa Query.

Caso completo: `references/exemplo.md`.

---

## Relacionados

- [TanStack Router](../../../knowledge-base/docs/tanstack-router.md) — o hub, e os dez satélites
- `tanstack-query` — o outro cache; `TSR-LOAD-14` é o que os concilia
- `react-developer` · `react-review` · `react-structure` — o que fica dentro da rota
- `react-hook-form` — o wizard cuja etapa mora na URL
