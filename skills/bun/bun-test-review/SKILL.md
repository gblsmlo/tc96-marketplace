---
nome: bun-test-review
descricao: Revisar uma suíte `bun test` existente e diagnosticar teste flaky, citando IDs `BUN-TEST-*`, com sete sondas executáveis para os defeitos que a leitura de código não encontra — use quando a tarefa for revisar os testes de um projeto, investigar "passa sozinho e falha na suíte", achar teste que nunca roda, conferir se o portão de cobertura e o de tipo realmente fecham, ou classificar severidade de achado em teste. Não use para escrever teste novo nem configurar suíte do zero, que é bun-test-build, nem para a forma da suíte entre níveis, que é test-review.
tipo: skill
familia: bun
fonte: "[Bun - Testes](../../../knowledge-base/docs/bun-testes.md)"
docs:
  - /oven-sh/bun
tags:
  - skill
  - bun
  - testing
  - code-review
---

# bun-test-review

> **Fonte desta skill:** [Bun - Testes](../../../knowledge-base/docs/bun-testes.md) — a § 6 normativa (`BUN-TEST-01` a `BUN-TEST-29`), a § 6.1 com as sete regras de violação silenciosa, e a § 5.1 com a árvore de flaky.
> Esta skill **não contém** o texto das regras — ela diz o que executar, em que ordem varrer, como classificar e como reportar.
> **Superfície de API:** resolva pelo Context7 — `/oven-sh/bun`. Assinatura, opção e comportamento por versão vêm de lá; a regra e o ID vêm da knowledge-base.

Contrato que esta skill implementa: [Bun - Testes](../../../knowledge-base/docs/bun-testes.md) § 7 ("Contrato de skill").

---

## Quando usar

Revisar suíte que **já existe** sob `bun test`, ou diagnosticar um teste que falha de forma intermitente.

| Situação | Vá para |
| --- | --- |
| escrever teste novo, configurar a suíte | `bun-test-build` |
| a **forma** da suíte entre níveis (E2E × unidade × componente) | `test-review` |
| a suíte como sistema: taxa de flakiness, credibilidade | `test-diagnose` |
| teste E2E que falha | `playwright-diagnose` |
| revisar o componente, não o teste dele | `react-review` |

---

## Carregamento mínimo

| Ordem | Carregar | Por quê |
| --- | --- | --- |
| 1 | [Bun - Testes](../../../knowledge-base/docs/bun-testes.md) § 2 | um `globalThis` compartilhado por todos os arquivos é o default |
| 2 | [Bun - Testes](../../../knowledge-base/docs/bun-testes.md) § 6 e § 6.1 | as regras, e as sete de violação silenciosa |
| 3 | `references/mapa-de-ids.md` | antes de citar — e para achar **em qual satélite** mora o corpo |
| 4 | [Bun - Testes](../../../knowledge-base/docs/bun-testes.md) § 5.1 | a árvore de flaky |
| 5 | o satélite do achado | só depois de ter a causa |

**Nunca carregue os seis satélites.** E **nunca invente ID** — a família vai de `BUN-TEST-01` a `BUN-TEST-29`.

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/sondas.md` | as sete sondas, as paradas, e o que elas não pegam |
| `references/ordem-da-varredura.md` | os nove passos, e a tabela sintoma → causa de flaky |
| `references/severidade-e-relatorio.md` | classificação, formato do achado, e o corte achado × opinião |
| `references/antipadroes.md` | a grade de antipadrões com ID e satélite |
| `references/mapa-de-ids.md` | os 29 `BUN-TEST-*`: declaração, **satélite do corpo** e seção |
| `references/exemplo-revisao.md` | revisão inteira, das sondas ao "não verificado" |
| `scripts/sondas.sh` | roda as mecânicas; com `--rodar`, também as que exigem a suíte de pé |
| `scripts/gerar-mapa-de-ids.sh` | regenera o mapa nas duas skills |

---

## Passo 1 — Sondar antes de ler

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/bun-test-review/scripts/sondas.sh --rodar
```

**Duas paradas obrigatórias:**

| Sonda | Se mostrar… | Por quê |
| --- | --- | --- |
| S1 | arquivo fora do padrão de descoberta | um arquivo que nunca rodou não tem defeito de asserção que importe |
| S5 | portão de cobertura que não reprova | qualquer discussão de cobertura vira decorativa |

E uma leitura que nomeia a causa sozinha: **S2 falha e S3 passa** → estado vazando pelo `globalThis` compartilhado. Com isso ligado, criticar asserção uma por uma é ruído.

---

## Passo 2 — Varrer na ordem que falha mais

`references/ordem-da-varredura.md`: asserção que pode não ter rodado → vazamento de mock e spy → isolamento e ordem → espera e tempo → marcas que apagam sinal → snapshot → DOM e componente → portões de CI → configuração.

Se um passo produz achado que invalida o seguinte (o preload não restaura mock; a suíte não passa com `--randomize`), **pare de revisar o interior**.

---

## Passo 3 — Diagnosticar flaky por sintoma

A tabela sintoma → causa está na mesma referência. Duas leituras que decidem sozinhas:

- **passa isolado, falha junto, e `--isolate` conserta** → estado no global compartilhado (`BUN-TEST-02`, `-03`, `-09`);
- **falha só com `--parallel`** → recurso externo compartilhado entre workers (`BUN-TEST-10`), ou preload que sobe algo (`BUN-TEST-24`).

**`test.serial` nunca resolve dependência entre arquivos** — ele sequencia dentro do arquivo. Proposta de correção com `serial` para dependência entre arquivos está errada (`BUN-TEST-09`).

---

## Passo 4 — Classificar e reportar

`references/severidade-e-relatorio.md`. O critério entre Bloqueante e Alta: **o defeito faz o CI mentir?** Teste que não roda e portão que não fecha produzem verde falso — outra categoria que "teste frágil".

Formato de quatro partes, com `arquivo:linha` sempre, e **evidência da sonda colada** quando o achado for de forma.

---

## Passo 5 — Fechar

1. **Transforme sonda em portão** — `--randomize` no CI, `tsc --noEmit` como passo próprio, limiar em `lines`.
2. **Ordene por severidade**, não por diretório.
3. **Declare o que não foi verificado** — sonda que rodou sobre suíte já quebrada não é conclusiva.
4. **Se a correção for escrever teste**, a fonte passa a ser `bun-test-build`.

---

## Exemplo

Monorepo com 180 testes e CI verde. As sondas encontram um arquivo que **nunca rodou**, `coverageThreshold` em `statements` (que não reprova), `-u` no CI, `.only` commitado, e `--randomize` falhando com `--isolate` passando — a assinatura de vazamento pelo global compartilhado. A correção do vazamento é **uma linha no preload**, não arquivo por arquivo.

Revisão completa: `references/exemplo-revisao.md`.

---

## Relacionados

- [Bun - Testes](../../../knowledge-base/docs/bun-testes.md) — fonte desta skill: § 2, § 5.1, § 6, § 6.1, § 7
- `bun-test-build` — a skill irmã
- `test-review` · `test-diagnose` — a camada de conceito
- `playwright-review` — a auditoria equivalente em E2E
- `react-review` · `drizzle-review` — de onde vem o formato de achado
