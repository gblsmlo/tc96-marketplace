---
name: bun-test-build
description: Escrever teste novo sob `bun test` e configurar a suíte de um projeto, seguindo as árvores de decisão e as regras `BUN-TEST-*` da doc do vault, com autoverificação executável — use quando a tarefa for escrever teste de unidade, substituir uma dependência por mock ou duplo, controlar data e tempo, testar componente React, configurar `bunfig.toml` e preloads, ou montar o comando de CI. Não use para revisar suíte existente nem diagnosticar flaky, que é bun-test-review, e não use para decidir *o que* testar e em que nível, que é test-design.
tags:
  - skill
  - bun
  - testing
fonte: "[[Bun - Testes]]"
---

# bun-test-build

> **Fonte desta skill:** [[Bun - Testes]] — a § 6 normativa (`BUN-TEST-01` a `BUN-TEST-29`), com o corpo de cada regra no satélite dono.
> Esta skill **não contém** o texto das regras nem a superfície de API — ela diz o que carregar, em que ordem decidir, e o que executar antes de entregar.

Contrato que esta skill implementa: [[Bun - Testes]] § 7 ("Contrato de skill").

---

## Quando usar

Escrever teste que **vai existir**, ou configurar a suíte de um projeto sob `bun test`.

| Situação | Vá para |
| --- | --- |
| revisar suíte existente, diagnosticar flaky | [[bun-test-review]] |
| decidir **o quê** testar e **em que nível** | [[test-design]] — vem antes desta |
| teste E2E | [[playwright-build]] |
| story e teste de interação em browser real | [[storybook-test]] |
| revisar o componente, não o teste dele | [[react-review]] · [[react-developer]] |

---

## Carregamento mínimo

A ordem vem do contrato ([[Bun - Testes]] § 7). Os dois primeiros **não são opcionais**:

| Ordem | Carregar | Por quê |
| --- | --- | --- |
| 1 | [[Bun - Testes]] § 2 | o default é **um global compartilhado por todos os arquivos** — quem escreve teste sem saber disso produz suíte que passa por acidente |
| 2 | [[Bun - Testes]] § 6.1 | as sete regras de violação silenciosa, que viajam com qualquer tarefa |
| 3 | [[Bun - Testes]] § 3 | fronteiras de import: o que vem de `bun:test`, e o que o Bun **não** lê (`vite.config.ts`, `jest.config.js`) |
| 4 | **um** satélite, pelo mapa em `references/por-tarefa.md` | a superfície que a tarefa toca |
| 5 | [[Bun - Testes]] § 5 | a árvore de decisão, quando houver dúvida entre duas APIs |

**Nunca carregue os seis satélites.** Escrever um teste de unidade precisa de 1 + 2 + [[Bun - Testes - Escrita e Asserções]] e nada mais.

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/por-tarefa.md` | o mapa tarefa → satélite, e os seis recortes (escrever, substituir, tempo, componente, suíte, CI) |
| `references/armadilhas-do-runner.md` | as três coisas que não se assumem de memória, vindas de Jest/Vitest |
| `references/autoverificacao.md` | a checklist e os três comandos que exigem execução |
| `references/mapa-de-ids.md` | os 29 `BUN-TEST-*`: onde declarados, e **em qual satélite mora o corpo** |
| `references/exemplo-sessao-expira.md` | caso trabalhado, com o que foi executado e o que não foi verificado |
| `scripts/autoverificar.sh` | roda a checklist sobre o arquivo recém-escrito |

**Nunca invente ID** — a família vai de `BUN-TEST-01` a `BUN-TEST-29`.

---

## Passo 1 — Escolher o recorte

`references/por-tarefa.md`: escrever teste novo · substituir uma dependência · controlar data e tempo · testar componente React · configurar a suíte · montar o comando de CI.

Cada recorte nomeia **o satélite que falta** — não o conteúdo dele.

---

## Passo 2 — Não confiar na memória de Jest/Vitest

`references/armadilhas-do-runner.md`. As três que produzem teste **verde e sem verificação**:

1. **Sem flag, todos os arquivos compartilham um `globalThis`.** "Vazou" não significa "afetou o próximo teste": significa "afetou o resto da suíte".
2. **`mock.restore()` não desfaz `mock.module()`** (`BUN-TEST-03`). As três limpezas fazem coisas diferentes.
3. **Concorrência dentro do arquivo não isola nada** — estado mutável exige `test.serial` (`BUN-TEST-23`), e `onTestFinished` não funciona em teste concorrente (`BUN-TEST-22`).

E a quarta, que é de tempo: **`useFakeTimers` não troca o construtor `Date`** — congelar data é `setSystemTime` (`BUN-TEST-20`).

---

## Passo 3 — Autoverificar antes de entregar

```bash
bash ~/.claude/skills/bun-test-build/scripts/autoverificar.sh test/sessao.test.ts
```

Depois, **as três que exigem execução**:

```bash
bun test ./caminho/do-novo.test.ts   # passa isolado
bun test --randomize                 # a suíte ainda passa em ordem aleatória
tsc --noEmit                         # o runner não checa tipo — BUN-TEST-18
```

**Rode as três de verdade.** Se `--randomize` quebrou depois do seu teste, você acabou de introduzir dependência de ordem (`BUN-TEST-09`) — e nenhuma flag substitui mover o setup para o próprio arquivo. O diagnóstico completo é [[bun-test-review]].

---

## Passo 4 — O que entregar

Três partes, e a terceira é a que costuma faltar:

1. **O código**, no padrão que a suíte já usa. Se o repositório tem o padrão certo em outro arquivo, **estenda esse padrão** em vez de introduzir um novo.
2. **O que foi executado**, com o resultado — cole a saída quando ela for o argumento.
3. **O que não foi verificado**, nomeado. **"Deve passar" não é resultado**: declarar a lacuna é o que separa entrega verificada de entrega plausível.

---

## Exemplo

*"A sessão expira 30 minutos após o último acesso."* A tarefa é sobre **tempo**, então a primeira decisão não é como escrever o teste — é qual API usar: `setSystemTime`, não `useFakeTimers` (`BUN-TEST-20`). Os instantes são 29/30/31 min (valor limite), o relógio é devolvido em `afterEach`, e o spy é restaurado explicitamente.

Caso completo, com o que foi executado e o que ficou por verificar: `references/exemplo-sessao-expira.md`.

---

## Fronteira com as outras skills

| Se a tarefa passar a ser… | Vá para |
| --- | --- |
| revisar a suíte inteira, diagnosticar flaky, classificar severidade | [[bun-test-review]] |
| a **forma** da suíte entre níveis | [[test-review]] |
| revisar a persistência que o teste exercita | [[drizzle-review]] |
| escrever ou revisar o componente, não o teste dele | [[react-developer]] · [[react-review]] |
| decidir cache e invalidação que o teste observa | [[tanstack-query]] |

Quando a fronteira for atravessada, **declare a troca** em vez de opinar fora da sua fonte.

---

## Relacionados

- [[Bun - Testes]] — fonte desta skill: § 2, § 5, § 6, § 7
- [[Bun - Testes - Escrita e Asserções]] · [[Bun - Testes - Mocks e Tempo]] · [[Bun - Testes - DOM e Componentes]] · [[Bun - Testes - Ciclo de Vida e Isolamento]] · [[Bun - Testes - Execução e Configuração]] · [[Bun - Testes - Cobertura e CI]]
- [[bun-test-review]] — a skill irmã
- [[test-design]] — decide o nível, antes desta skill começar
