---
name: storybook-test
description: Transformar story em teste de componente no Storybook — `play`, `storybook/test`, mock de módulo e rede, acessibilidade — citando IDs `SB-TEST-*` e `SB-MOCK-*`, sempre depois de descobrir o caminho de framework do projeto, com autoverificação executável — use quando a tarefa for escrever ou revisar teste de interação numa story, asseverar callback com `fn()`, esperar dado assíncrono, mockar módulo ou rede para uma story, ou ligar a varredura de a11y. Não use para configurar Storybook do zero, que é storybook-setup, para interpretar cobertura e montar CI, que é o satélite Cobertura e CI, nem para teste de jornada, que é playwright-build.
tags:
  - skill
  - storybook
  - testing
fonte: "[[Storybook - Testes e Interações]]"
---

# storybook-test

> **Fonte desta skill:** [[Storybook - Testes e Interações]], com o hub [[Storybook]] como roteador.
> Esta skill **não contém** o texto das regras — ela diz o que descobrir, o que escrever e o que conferir.

Contrato que esta skill implementa: [[Storybook]] § 7.

---

## Passo 0 — Descobrir o caminho do framework

**Antes de qualquer outra coisa.**

```bash
bash ~/.claude/skills/storybook-setup/scripts/descobrir-caminho.sh
```

| `framework` | Caminho | Família | Nota |
| --- | --- | --- | --- |
| `@storybook/tanstack-react` | **A** | `SB-TS-*` | [[Storybook - TanStack React]] |
| `@storybook/react-vite` | **B** | `SB-RV-*` | [[Storybook - React Vite]] |

Isto **não é formalidade**. É a única estrutura deste vault em que prescrever o caminho errado **falha em silêncio**: sob `react-vite`, `parameters.tanstack.*` não tem efeito nenhum (`SB-RV-04`); sob `tanstack-react`, um decorator com `RouterProvider` cria um **segundo** router (`SB-TS-03`).

As duas famílias são **mutuamente exclusivas** — citar uma contra um projeto do outro caminho é **achado inválido**. Detalhe: `references/caminho-do-framework.md`.

---

## Quando usar

Escrever ou revisar teste de interação dentro de uma story.

| Situação | Vá para |
| --- | --- |
| configurar Storybook, sidebar vazia, versões | [[storybook-setup]] |
| a story em si: `args`, controles, docs | [[storybook-story]] |
| cobertura e job de CI | [[Storybook - Cobertura e CI]] |
| jornada com rota, sessão e rede | [[playwright-build]] |
| unidade e integração fora do browser | [[bun-test-build]] |
| **em que nível** este teste deveria estar | [[teste-design]] |

---

## Carregamento mínimo

| Ordem | Carregar |
| --- | --- |
| 1 | o campo `framework` (Passo 0) |
| 2 | [[Storybook]] § 6 e § 6.2 |
| 3 | [[Storybook - Testes e Interações]] |
| 4 | a nota do **caminho descoberto** |
| 5 | [[Storybook - Mocking]] quando houver módulo ou rede a substituir |

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/caminho-do-framework.md` | o Passo 0, e por que ele é diferente de todos os outros do vault |
| `references/play.md` | a story antes do teste, e como escrever a `play` |
| `references/ambiente-e-a11y.md` | mock de módulo e rede, e a varredura de acessibilidade |
| `references/autoverificacao.md` | os 14 itens, e a que vale mais que eles |
| `references/antipadroes.md` | a grade com ID |
| `references/mapa-de-ids.md` | os 75 `SB-*` por satélite e seção |
| `references/exemplo.md` | caso trabalhado |
| `scripts/autoverificar.sh` | roda o Passo 0 **e** os itens mecânicos |

---

## Passo 1 — A story, antes do teste

A `play` verifica o que a story **já** estabelece. Se a story não é um estado nomeado por `args` (`SB-CSF-04`), o teste vai carregar setup que era da story — e é [[storybook-story]] que resolve.

---

## Passo 2 — Escrever a `play`

Todo `expect` **aguardado** (`SB-TEST-01`); a primeira query de story assíncrona é **`findBy…`** (`SB-TEST-10`); callback é **`fn()` em `args`** (`SB-TEST-03`), não função no `render`; query por **papel/rótulo** (`SB-TEST-06`); nenhuma asserção sobre implementação interna (`SB-TEST-09`).

---

## Passo 3 — Substituir o ambiente

`sb.mock()` só no **preview**; o comportamento vai em `beforeEach` (`SB-MOCK-01`, `SB-MOCK-04`). `beforeEach` que altera ambiente **retorna a limpeza** (`SB-CTX-08`).

---

## Passo 4 — Acessibilidade

`a11y.test` é `'error'` onde se espera que o **CI reprove** (`SB-TEST-04`) — em `'todo'` a varredura existe e não protege.

---

## Passo 5 — Autoverificar

```bash
bash ~/.claude/skills/storybook-test/scripts/autoverificar.sh src
vitest run --project=storybook       # sem `run` entra em watch mode
```

**A verificação que vale mais que as catorze:** quebre o componente de propósito e confirme que a story fica **vermelha**. Se nada quebrar, a `play` não afirma nada (`TS-TEC-08`).

---

## Passo 6 — Fechar

1. **Confirme o caminho** antes de citar qualquer `SB-TS-*` ou `SB-RV-*`.
2. **Se o teste precisou de rota, sessão e rede reais**, ele não é de componente — é [[playwright-build]].
3. **Se o teste é de lógica pura**, ele é mais barato em [[bun-test-build]].
4. **Declare o que não cobriu.**

---

## Exemplo

Story de formulário com envio: `fn()` em `args` para o callback, `findBy…` para o campo que aparece depois do carregamento, mock do módulo de API no preview com comportamento em `beforeEach`, e `a11y.test: 'error'`. O que o hábito produziria: `expect` sem `await` — que passa sempre — e `getBy` na primeira query, que falha por timing.

Caso completo: `references/exemplo.md`.

---

## Relacionados

- [[Storybook - Testes e Interações]] — fonte desta skill
- [[Storybook - Mocking]] — módulo e rede
- [[storybook-setup]] · [[storybook-story]] — as skills irmãs
- [[teste-design]] — decide o nível, antes desta
- [[playwright-build]] · [[bun-test-build]] — os outros níveis
