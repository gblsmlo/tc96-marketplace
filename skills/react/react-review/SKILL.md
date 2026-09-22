---
nome: react-review
descricao: Revisar código React que já existe contra as regras normativas da doc do vault, citando IDs `REACT-*` — quinze sondas executáveis antes de ler código, varredura em cinco níveis na ordem que falha mais, classificação de severidade e formato fixo de achado — use quando a tarefa for revisar um PR, arquivo, componente ou Hook customizado já escrito, ou caçar violação de Rules of Hooks, fetch em Effect, estado derivado por Effect, dado remoto em useState, mutação de props, Suspense sem Error Boundary, Server Function sem validação e memoização sem medida. Não use para escrever código novo, que é react-developer, para decidir onde o arquivo mora, que é react-structure, para formulário com validação e campo condicional, que é react-hook-form, nem para diagnosticar componente já confirmado lento, que é react-component-performance.
tipo: skill
familia: react
fonte: "[React - Rules of React](../../../knowledge-base/docs/react-rules-of-react.md)"
tags:
  - skill
  - react
---

# react-review

> **Fonte desta skill:** [React - Rules of React](../../../knowledge-base/docs/react-rules-of-react.md), com o hub [React.js](../../../knowledge-base/docs/react-js.md) como roteador.
> Esta skill **não contém** o conteúdo das regras — ela diz o que rodar, o que carregar, em que ordem varrer e como reportar. Para o texto de uma regra, abra a nota-fonte: atualização da doc propaga sozinha para cá, e qualquer regra reescrita aqui viraria cópia desatualizada.

Contrato que esta skill implementa: [React.js](../../../knowledge-base/docs/react-js.md) § 7 ("Contrato de skill").

---

## Quando usar

Revisar código React que **já existe**: PR, arquivo, componente, Hook customizado.

| Se a pergunta for… | Vá para |
| --- | --- |
| escrever componente ou Hook **novo** | `react-developer` |
| onde este arquivo mora, quem importa quem | `react-structure` |
| formulário com validação, campo condicional, array de campos | `react-hook-form` |
| componente **já confirmado lento**, precisa de fix medido | *(rota vaga — ver `memory/STACK.md`)* |

---

## Carregamento mínimo

Nesta ordem, parando quando tiver o suficiente ([React.js](../../../knowledge-base/docs/react-js.md) § 1 e § 7):

| Ordem | Carregar | Por quê |
| --- | --- | --- |
| 1 | [React - Rules of React](../../../knowledge-base/docs/react-rules-of-react.md) (inteira, com foco na § 5) | base normativa e checklist de varredura |
| 2 | [React.js](../../../knowledge-base/docs/react-js.md) § 6 e § 6.1 | regras invioláveis e as críticas dos satélites |
| 3 | `references/mapa-de-ids.md` | canônicos e apelidos — obrigatório antes de citar |
| 4 | [React.js](../../../knowledge-base/docs/react-js.md) § 4 | descobrir **qual** satélite corresponde à API tocada |
| 5 | o satélite daquele domínio | só quando o achado exigir o texto completo da família |
| 6 | [React - Patterns](../../../knowledge-base/docs/react-patterns.md) | quando o achado for estrutural (posse de estado, composição, fronteiras) |

**Nunca carregue todos os satélites.** Regra de economia de contexto do hub.

Referências desta skill — abra só a que o passo pedir:

| Arquivo | Para quê |
| --- | --- |
| `references/sondas.md` | as quinze sondas, o que cada uma **não** pega, e os falsos positivos |
| `references/grade-de-varredura.md` | os cinco níveis, na ordem que falha mais, com ID por antipadrão |
| `references/severidade-e-relatorio.md` | classificação, formato de achado, o corte achado × opinião, estrutura do relatório |
| `references/mapa-de-ids.md` | onde cada `REACT-*` está declarado, e a lista de apelidos |
| `references/exemplo-relatorio-de-pr.md` | um relatório inteiro, das sondas ao fechamento |
| `scripts/sondas.sh` | roda as quinze sondas e imprime o ID a citar em cada bloco |
| `scripts/gerar-mapa-de-ids.sh` | regenera `mapa-de-ids.md` a partir de `Docs/React*` |

---

## Passo 1 — Sondar antes de ler

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/react-review/scripts/sondas.sh src
```

(no vault, `bash ${CLAUDE_PLUGIN_ROOT}/skills/react-review/scripts/sondas.sh src`; o alvo padrão é `src`, ou `.` se não houver.)

A **sonda 0 roda primeiro e muda o veredito das outras**: versão do React, React Compiler ativo, **rede de lint** (ESLint com o plugin, ou Biome com o domínio `react` ligado), `<StrictMode>` presente. Reportar "falta memoizar" num projeto com React Compiler ativo é achado inválido, e desmoraliza o relatório inteiro.

Sonda **não é achado**: ela diz onde olhar. Achado exige leitura do trecho e `arquivo:linha`. As quatro sondas de contexto (9, 11, 12, 13) precisam de leitura do arquivo pai, da topologia ou da config de SSR antes de virar achado. Detalhe e falsos positivos em `references/sondas.md`.

---

## Passo 2 — Varrer na ordem que falha mais

`references/grade-de-varredura.md`, cinco níveis:

1. **Contrato do React** — Hooks fora do topo, side effect no render, mutação, componente chamado como função. Bloqueante.
2. **Regras críticas** de [React.js](../../../knowledge-base/docs/react-js.md) § 6.1 — fetch em Effect, estado derivado, dado remoto em `useState`, Suspense sem boundary, memoização sem medida, `'use client'` alto, Server Function sem validação.
3. **Estrutura** — colocação de estado, composição, fronteiras, `key`, e as famílias dos satélites.
4. **Satélite do domínio** — só agora, e só o que o código toca (via [React.js](../../../knowledge-base/docs/react-js.md) § 4).
5. **Estilo** — por último, sempre subordinado aos anteriores.

Se um nível produz achado que invalida o código do seguinte — o Effect inteiro não deveria existir — **pare de revisar o interior dele** e reporte a remoção, não a correção de detalhe.

O que as sondas nunca pegam, e por isso exige leitura: `REACT-HOOK-01`, `REACT-CALL-01`, `REACT-CALL-02`, `REACT-PAT-02`, `REACT-PAT-03`, `REACT-PAT-10`, `REACT-ASYNC-09`.

---

## Passo 3 — Classificar e reportar

`references/severidade-e-relatorio.md`. Resumo:

| Severidade | O que entra |
| --- | --- |
| **Bloqueante** | `REACT-PURE-*`, `REACT-CALL-*`, `REACT-HOOK-*` |
| **Alta** | regras críticas de [React.js](../../../knowledge-base/docs/react-js.md) § 6.1 |
| **Média** | demais `REACT-*` do satélite |
| **Baixa** | preferência sem ID — **não é achado** |

Formato fixo, quatro partes:

```
`ID-DA-REGRA` — arquivo:linha
<o que está errado, uma frase>
Correção: <mudança concreta, não conselho genérico>
Ver Satélite correspondente.
```

**Achado sem ID de regra é opinião.** Existe ID → cite o canônico. Não existe ID mas é antipadrão documentado → cite a **seção** ([React - Patterns](../../../knowledge-base/docs/react-patterns.md) § 8). Não existe nem ID nem seção → vai para "Sugestões (sem regra)", separado, ou fica fora. **Nunca invente um ID.**

---

## Passo 4 — Fechar a revisão

1. **Automatize o que dá.** Sem rede de lint e sem `<StrictMode>`, metade do Nível 1 não tem proteção — e isso é o **primeiro achado do relatório**. Em projeto Biome, a rede só existe com `linter.domains.react` ligado: `preset: recommended` **não** ativa as regras de Hooks.
2. **Verifique se o stack já resolve** antes de sugerir a primitiva crua ([React.js](../../../knowledge-base/docs/react-js.md) § 8).
3. **Ordene por severidade**, não por ordem de arquivo.
4. **Declare o que não foi verificado.** API fora de [React.js](../../../knowledge-base/docs/react-js.md) § 4 não foi verificada nesta doc; silêncio sobre arquivo não lido é lido como aprovação.

Se `Docs/React*` mudou desde a última revisão, regenere o mapa antes de citar:

```bash
bash plugins/hermes-frontend/skills/react-review/scripts/gerar-mapa-de-ids.sh # reescreve o mapa das duas skills
bash scripts/instalar.sh # e reinstala o plugin
```

---

## Vizinhas — quando a revisão sai do React

Um PR de frontend quase nunca é só React. Quando o achado for de outra camada, ele pertence à skill daquela camada, com os IDs daquela família — não force um `REACT-*` em cima.

| A camada tocada é… | Skill | Doc-fonte |
| --- | --- | --- |
| dado remoto, cache, invalidação, update otimista | `tanstack-query` | [TanStack Query](../../../knowledge-base/docs/tanstack-query.md) |
| rota, navegação, search params, loader | `tanstack-router` | [TanStack Router](../../../knowledge-base/docs/tanstack-router.md) |
| formulário com validação, condicional, array de campos | `react-hook-form` | [React Hook Form](../../../knowledge-base/docs/react-hook-form.md) |
| story, controle, docs de componente | `storybook-story` · `storybook-setup` | [Storybook - Stories e Args](../../../knowledge-base/docs/storybook-stories-e-args.md) |
| teste de interação dentro da story, **runner Vitest** | `storybook-test` | [Storybook - Testes e Interações](../../../knowledge-base/docs/storybook-testes-e-interacoes.md) § 4 |
| **em que nível** este teste deve estar (unidade × integração × e2e) | `teste-design` | `Docs/Teste de Software - Níveis e Escopo.md` |
| a suíte protege alguma coisa? · ninguém confia nela | `teste-review` · `teste-diagnose` | `Docs/Teste de Software.md` |
| **teste de unidade e integração** sob `bun test` | `bun-test-build` · `bun-test-review` | `Docs/Bun - Testes.md` |
| **teste e2e** — escrever, auditar, diagnosticar | `playwright-build` · `playwright-review` · `playwright-diagnose` | `Docs/Playwright.md` |
| rota, handler, schema e lifecycle de API | `elysia-build` · `elysia-schema` · `elysia-diagnose` | `Docs/Elysia.md` |
| schema, migração, query, N+1 | `drizzle-review` | `Docs/Drizzle ORM.md` |
| método, status, cache, CORS, contrato da API | `http-contract` · `http-cache` · `http-diagnose` · `http-review` | `Docs/HTTP.md` |

Duas observações que evitam achado errado:

- **Vitest não tem skill própria neste vault.** Ele aparece como *runner* do `@storybook/addon-vitest`, rodando story em browser real via Playwright — [Storybook - Testes e Interações](../../../knowledge-base/docs/storybook-testes-e-interacoes.md) § 4, e o corte entre Vitest 3 e 4 está na § 4.2. Teste de unidade fora do Storybook é `bun test`, não Vitest.
- **A camada de conceito vem antes da de ferramenta.** "Este teste deveria existir, e neste nível?" é `teste-design`; "este teste está certo?" é a skill da ferramenta. Pular a primeira produz E2E por default, que é o antipadrão de maior custo do stack.

---

## Exemplo

PR de busca de clientes, três arquivos. As sondas apontam seis candidatos em cinco minutos; a **leitura** encontra o achado bloqueante que nenhuma sonda vê (`useState` depois de early return, `REACT-HOOK-01`), e ele reordena o relatório inteiro. Um `useMemo` apontado pela sonda 6 **não** vira achado, porque tinha medição documentada; o tamanho do arquivo vai para "Sugestões (sem regra)"; uma API de framework fora de [React.js](../../../knowledge-base/docs/react-js.md) § 4 vira declaração de limitação, não opinião.

Relatório completo, das sondas ao fechamento: `references/exemplo-relatorio-de-pr.md`.

---

## Relacionados

- `react-developer` — a skill irmã, para escrever código novo
- `react-structure` — onde o arquivo mora e quem importa quem
- [React - Rules of React](../../../knowledge-base/docs/react-rules-of-react.md) — fonte desta skill
- [React - Patterns](../../../knowledge-base/docs/react-patterns.md) — decisão estrutural e tabela de antipadrões
- [React.js](../../../knowledge-base/docs/react-js.md) — hub, mapa da API, árvores de decisão, contrato de skill
