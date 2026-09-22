---
name: react-developer
description: Escrever componente, Hook customizado ou feature React nova — três perguntas de estrutura antes de qualquer código, escolha de API pelas árvores de decisão, tabela de hábitos que produzem violação, e autoverificação executável antes de entregar, citando IDs `REACT-*` — use quando a tarefa for criar componente ou Hook do zero, decidir quem é dono do estado, escolher entre Hooks próximos, extrair lógica para Hook customizado, desenhar fronteira de erro e espera, ou compor em vez de configurar. Não use para revisar código que já existe, que é react-review, para decidir onde o arquivo mora, que é react-structure, para formulário com validação e campo condicional, que é react-hook-form, nem para diagnosticar componente já confirmado lento, que é react-component-performance.
tags:
  - skill
  - react
fonte: "[[React - Patterns]]"
---

# react-developer

> **Fonte desta skill:** [[React - Patterns]] (decisão estrutural), com [[React - Rules of React]] como base normativa e [[React.js]] como roteador de API.
> Esta skill **não repete** as regras nem a superfície de API — ela define a ordem das decisões e aponta o que abrir em cada ponto. O texto das regras mora nas notas-fonte; atualização lá propaga para cá.
>
> Sucessora de `react-build`, com o mesmo procedimento e as referências internas que faltavam.

Contrato que esta skill implementa: [[React.js]] § 7 ("Contrato de skill").

---

## Quando usar

Escrever componente, Hook customizado ou feature React **nova** — ou reescrever um trecho a ponto de as decisões de estrutura voltarem à mesa.

| Se a pergunta for… | Vá para |
| --- | --- |
| este código que **já existe** está correto? | [[react-review]] |
| onde este arquivo mora, quem importa quem | [[react-structure]] |
| formulário com validação, campo condicional, array de campos | [[react-hook-form]] |
| componente **já confirmado lento**, precisa de fix medido | `react-component-performance` (instalada em `~/.claude/skills/`) |
| o dado vem do servidor e outra pessoa pode alterá-lo | [[tanstack-query]] |
| o estado pertence à URL (filtro, aba, página) | [[tanstack-router]] |

---

## Carregamento mínimo

Conforme [[React.js]] § 7:

```
SEMPRE:   [[React.js]] § 2 (modelo mental)
          [[React.js]] § 5 (árvores de decisão)
          [[React.js]] § 6 + § 6.1 (regras normativas e críticas)
          [[React - Rules of React]]   ← obrigatória ao escrever/editar componentes

ANTES DE ESCREVER:  [[React - Patterns]] § 1 a § 3

SOB DEMANDA:        o satélite do domínio tocado, descoberto por [[React.js]] § 4

NUNCA:              todos os satélites de uma vez
```

Referências desta skill — abra só a que o passo pedir:

| Arquivo | Para quê |
| --- | --- |
| `references/arvores-de-decisao.md` | qual árvore percorrer, os quatro erros de percurso, as saídas curtas |
| `references/habitos-de-ia.md` | o reflexo que produz cada violação, e o que fazer em vez disso |
| `references/autoverificacao.md` | as três passadas e as dez sondas `rg` antes de entregar |
| `references/mapa-de-ids.md` | onde cada `REACT-*` está declarado, e a lista de apelidos |
| `references/exemplo-painel-de-faturas.md` | caso trabalhado do caminho feliz |
| `references/exemplo-fronteira-de-servidor.md` | a variante robusta: Server Function, validação, boundaries |
| `references/exemplo-antipadrao-corrigido.md` | o mesmo componente antes e depois, defeito por ID |
| `scripts/autoverificar.sh` | roda as dez sondas do Passo 5 sobre o que você acabou de escrever |

---

## Passo 1 — As três perguntas de estrutura, antes de qualquer código

De [[React - Patterns]] § 1. A ordem importa: composição escolhida antes da posse do dado quase sempre gera prop drilling.

1. **De quem é este dado?** → colocação de estado. Detalhe em [[React - Patterns]] § 2.
2. **Quem fornece o conteúdo variável?** → composição. Detalhe em [[React - Patterns]] § 3.
3. **Onde uma falha ou uma espera deve parar?** → fronteiras (Error Boundary, `<Suspense>`, `'use client'`, servidor). Detalhe em [[React - Patterns]] § 6.

Responda as três **por escrito**, em uma frase cada, antes da primeira linha de JSX. Se não conseguir responder a 1, o problema não é de código: falta definir a origem do dado.

---

## Passo 2 — Escolher a API pelas árvores de decisão

Não escolha o Hook por hábito. Percorra a árvore correspondente em [[React.js]] § 5 — o roteiro, os erros de percurso e as quatro saídas curtas estão em `references/arvores-de-decisao.md`.

| Sintoma da tarefa | Árvore a percorrer |
| --- | --- |
| "preciso guardar um valor" | *Preciso guardar um valor. Onde?* — primeiro **de onde vem o dado**, depois **em qual componente** |
| "preciso rodar um efeito colateral" | *Preciso rodar um efeito colateral. Onde?* — a primeira pergunta é se responde a uma interação |
| "a UI trava" | *A UI trava durante uma atualização* — a ordem é normativa e **não começa pela memoização** |
| "preciso lidar com algo assíncrono" | *Preciso lidar com algo assíncrono* |

Depois de escolher a API, confirme o pacote de origem em [[React.js]] § 3 e o satélite em [[React.js]] § 4. Abra **só esse** satélite.

**Antes de usar a primitiva crua, confira [[React.js]] § 8.** Dado remoto, cache, estado de URL, validação de fronteira e estado global de escrita frequente já têm resposta no stack — usar `useEffect` + `useState` onde o stack resolve é regressão, não simplicidade.

---

## Passo 3 — Escrever

Mantenha [[React - Rules of React]] carregada. Três âncoras do modelo mental ([[React.js]] § 2) decidem quase tudo:

- componente é função pura das entradas;
- estado é snapshot, não variável;
- Effect é sincronização com sistema externo, não "código que roda depois".

Convenção do vault: **todos os exemplos da doc são TypeScript**. Nenhuma regra depende de tipos, mas escreva TS por padrão.

---

## Passo 4 — Não cair nos hábitos automáticos

`references/habitos-de-ia.md` é a tabela completa, em sete seções: estado e dado, efeitos, composição e fronteiras, performance, refs e DOM, formulários e servidor, Hooks customizados. Não é lista de revisão — é decisão a tomar **antes** de escrever, porque cada linha nasce de um reflexo.

Os cinco que aparecem em quase todo código gerado:

| Hábito | Em vez disso | Regra |
| --- | --- | --- |
| `fetch` dentro de `useEffect` | biblioteca de data fetching ([[React.js]] § 8) | `REACT-EFFECT-06` |
| `useState` + `useEffect` para valor calculável | calcular no render, no dono do estado | `REACT-PAT-01` |
| `useState` para filtro, aba, paginação | search params do [[TanStack Router]] | `REACT-PAT-10` |
| memoização "por precaução" | medir antes; e checar se o React Compiler está ativo | `REACT-PERF-01`, `REACT-PERF-02` |
| Error Boundary só na raiz | boundary no nível da feature, ao lado de todo `<Suspense>` de dados | `REACT-PAT-06`, `REACT-ASYNC-08` |

Ao citar qualquer ID, use o canônico — `references/mapa-de-ids.md` tem a lista de apelidos que **não** devem sair da doc.

---

## Passo 5 — Autoverificar antes de entregar

`references/autoverificacao.md`, na íntegra: três passadas e dez sondas `rg`.

```bash
bash ~/.claude/skills/react-developer/scripts/autoverificar.sh src/features/faturas
```


1. **Checklist normativa** — a § 5 de [[React - Rules of React]], ordenada por frequência de falha.
2. **Tabela de hábitos** — para cada linha, o código evitou o hábito?
3. **Três perguntas de fechamento** — todo `useState` sobrevive à árvore de estado? todo `useEffect` sincroniza com sistema externo **nomeável**? toda memoização tem medida?

Se qualquer resposta for "não", corrija antes de entregar — não entregue com ressalva.

Duas verificações que mudam o código e por isso rodam **antes** da primeira linha: React Compiler ativo (`REACT-PERF-02`) e `eslint-plugin-react-hooks` configurado. Ambas em `references/autoverificacao.md` § *Antes da primeira linha*.

---

## Vizinhas — quando a feature sai do React

Antes de escrever a primitiva crua, confirme de quem é a camada. [[React.js]] § 8 lista o que o stack já resolve; a tabela abaixo diz **qual skill** carrega o procedimento.

| A camada é… | Skill | Doc-fonte |
| --- | --- | --- |
| dado remoto, cache, invalidação, update otimista | [[tanstack-query]] | [[TanStack Query]] |
| rota, navegação, search params, loader, code splitting | [[tanstack-router]] | [[TanStack Router]] |
| formulário com validação, campo condicional, array de campos | [[react-hook-form]] | [[React Hook Form]] |
| onde o arquivo mora e quem importa quem | [[react-structure]] | [[Feature-Based Architecture]] |
| story, args, controle, página de docs | [[storybook-story]] · [[storybook-setup]] | [[Storybook - Stories e Args]] |
| teste de interação na story, **runner Vitest** | [[storybook-test]] | [[Storybook - Testes e Interações]] § 4 |
| **em que nível** este teste vai (unidade × integração × e2e) | [[teste-design]] | [[Teste de Software - Níveis e Escopo]] |
| **unidade e integração** sob `bun test` | [[bun-test-build]] · [[bun-test-review]] | [[Bun - Testes]] |
| **e2e** — escrever, auditar, diagnosticar | [[playwright-build]] · [[playwright-review]] · [[playwright-diagnose]] | [[Playwright]] |
| rota, handler, schema e lifecycle de API | [[elysia-build]] · [[elysia-schema]] · [[elysia-diagnose]] | [[Elysia]] |
| schema, migração, query, N+1 | [[drizzle-review]] | [[Drizzle ORM]] |
| método, status, cache, CORS, contrato da API | [[http-contract]] · [[http-cache]] · [[http-diagnose]] · [[http-review]] | [[HTTP]] |

Três fronteiras que costumam ser cruzadas na direção errada:

- **Teste: conceito antes de ferramenta.** Decidir *o nível* é [[teste-design]]; escrever é a skill da ferramenta. Pular a primeira produz E2E por default — o antipadrão de maior custo do stack.
- **Vitest não tem skill própria neste vault.** Ele é o *runner* do `@storybook/addon-vitest`, executando story em browser real via Playwright ([[Storybook - Testes e Interações]] § 4; o corte entre Vitest 3 e 4 está na § 4.2). Unidade fora do Storybook é `bun test`.
- **Otimismo tem dois donos.** Se o dado vive no cache da Query, o otimismo é da mutation, com snapshot e rollback; `useOptimistic` é para o que não vive em cache. Empilhar os dois viola `REACT-FORM-07`.

---

## Exemplo

Tarefa: *"um painel de faturas com filtro por status e o total do que está selecionado"*.

O Passo 1 identifica **três donos** — faturas (servidor), filtro (URL), seleção (painel) — e o total como **derivável**. O Passo 2 percorre a árvore de estado uma vez por dono, e três das quatro saídas terminam sem Hook nenhum. Sobra um `useState` e nenhum `useEffect`; a versão intuitiva da mesma tela tem quatro e dois.

Caso completo, com código e placar: `references/exemplo-painel-de-faturas.md`.
A variante com escrita e fronteira de confiança: `references/exemplo-fronteira-de-servidor.md`.
O mesmo componente feito errado e corrigido, defeito por ID: `references/exemplo-antipadrao-corrigido.md`.

---

## Relacionados

- [[react-review]] — a skill irmã, para revisar código existente
- [[react-structure]] — onde o arquivo mora e quem importa quem
- [[React - Patterns]] — fonte desta skill
- [[React - Rules of React]] — base normativa, obrigatória ao escrever
- [[React.js]] — hub, mapa da API, árvores de decisão, pontes com o stack
