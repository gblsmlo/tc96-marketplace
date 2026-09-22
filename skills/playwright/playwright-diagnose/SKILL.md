---
name: playwright-diagnose
description: Diagnosticar teste Playwright que falha ou falha de forma intermitente, lendo o trace antes de tocar no código, com bissecção executável e IDs `PW-*` — use quando a tarefa for investigar teste flaky, falha que só acontece em CI, falha que só acontece em paralelo, screenshot que difere sem motivo, ou timeout de 30 s sem causa aparente. Não use para escrever teste novo, que é playwright-build, para auditar uma suíte inteira sem falha concreta, que é playwright-review, nem para a suíte como sistema e taxa de flakiness, que é teste-diagnose.
tags:
  - skill
  - playwright
  - testing
  - flaky-tests
fonte: "[[Playwright - Debug e Trace]]"
---

# playwright-diagnose

> **Fonte desta skill:** [[Playwright - Debug e Trace]], com a § 5.2 do hub [[Playwright]] como árvore de diagnóstico. As 85 regras da família `PW-*` moram na § 6 do hub.
> Esta skill **não contém** o texto das regras — ela diz o que obter, em que ordem ler e como eliminar hipóteses.

Contrato que esta skill implementa: [[Playwright]] § 7 ("Contrato de skill").

> **Nota de desenho.** Esta skill diagnostica **um teste**. Para a **suíte como sistema** — taxa de flakiness, confiança, capacidade de detectar quebra — é [[teste-diagnose]]. A diferença prática: aqui se lê um trace; lá se lê o histórico do CI. Chegar lá com um teste vermelho, ou aqui com "a suíte é flaky", é usar a ferramenta errada.

---

## Quando usar

Um teste concreto falha, ou falha às vezes.

| Situação | Vá para |
| --- | --- |
| escrever ou reescrever teste | [[playwright-build]] |
| auditar suíte sem falha concreta | [[playwright-review]] |
| a **suíte** perdeu credibilidade; medir flakiness | [[teste-diagnose]] |
| teste sob `bun test` que falha | [[bun-test-review]] |
| a falha é defeito real do produto | então **o teste funcionou** — reporte o defeito e pare |

---

## Carregamento mínimo

| Ordem | Carregar | Por quê |
| --- | --- | --- |
| 1 | [[Playwright]] § 0 | a tabela de timeouts — quem estourou, e qual |
| 2 | [[Playwright]] § 5.2 | a árvore de diagnóstico |
| 3 | [[Playwright - Debug e Trace]] § 3 | a leitura do trace em quatro passos |
| 4 | `references/mapa-de-ids.md` | antes de citar — dois IDs são apelidos |
| 5 | o satélite da causa | só **depois** de ter a causa |

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/leitura-do-trace.md` | como obter o trace e as quatro abas, com a tabela de mensagens do Log |
| `references/arvore-de-hipoteses.md` | os oito itens da árvore e a bissecção |
| `references/falha-so-em-ci.md` | as quatro causas de CI, e as duas armadilhas que parecem flake |
| `references/conserto-x-anestesico.md` | os sete anestésicos, o formato do achado e o fechamento |
| `references/mapa-de-ids.md` | os 85 `PW-*` por satélite e seção |
| `references/exemplo-diagnostico.md` | diagnóstico inteiro, do trace ao achado |
| `scripts/isolar.sh` | roda a bateria de bissecção e imprime a hipótese que cada execução elimina |

---

## Passo 0 — A pergunta que vem antes de tudo

> **A falha é um defeito real do produto?**

Se sim, **o teste fez o trabalho dele**: reporte o defeito e pare. Confundir "teste vermelho" com "teste ruim" é como uma suíte perde a capacidade de dar sinal.

---

## Passo 1 — Obter o trace

Sem trace configurado, toda falha de CI é adivinhação — e se `trace` está `'off'`, **o primeiro achado é a configuração** (`PW-CFG-02`), não o teste.

> **Nunca** use `--debug` para decidir se é flake: ele força `timeout=0` e `workers=1`, então **sempre passa** (`PW-DBG-02`).

Comandos por situação: `references/leitura-do-trace.md`.

---

## Passo 2 — Ler o trace em quatro passos

**Errors** (qual ação falhou) → **Log** daquela ação (**em qual checagem** travou) → **Snapshot Before** (o que estava na tela) → **Network**.

O passo 2 é o que nenhum `console.log` dá, e é onde a causa aparece: `element intercepts pointer events` é overlay; `strict mode violation` é locator ambíguo; `waiting for element to be visible` é alvo que nunca apareceu. Tabela completa na referência.

---

## Passo 3 — Percorrer a árvore, na ordem

`references/arvore-de-hipoteses.md`, oito itens, **sem pular**. **O que nunca é a resposta:** subir `retries` (`PW-RUN-03`).

---

## Passo 4 — Isolar por bissecção

```bash
bash ~/.claude/skills/playwright-diagnose/scripts/isolar.sh e2e/checkout.spec.ts:52 20
```

`--repeat-each` confirma intermitência; `--workers=1` aponta estado compartilhado; só-o-caso aponta dependência de ordem; container do CI aponta paridade de ambiente.

> **`--workers=1` diagnostica; não conserta.**

---

## Passo 5 — Falha que só acontece em CI

`references/falha-so-em-ci.md`: CI mais lento, paridade de ambiente, estado de servidor, setup que não rodou. Mais duas armadilhas que aparecem como flake — Service Worker interceptando antes do `route` (`PW-NET-03`) e imagens bloqueadas numa suíte com screenshot (`PW-SNAP-06`).

---

## Passo 6 — Reportar

Cinco partes, com **evidência do trace e a aba**. "Parece timing" não é evidência. Se a causa é defeito de produto, a correção é no produto — dizer isso explicitamente é o valor principal desta skill. Formato e exemplo: `references/conserto-x-anestesico.md`.

---

## Passo 7 — Conserto × anestésico

Sete correções que fazem o vermelho sumir sem resolver nada: `waitForTimeout`, `retries`, `force: true`, `workers: 1`, `expect.timeout` global, `skip` sem issue, e **remover a asserção** — a mais grave, e a que um healer sem spec declarada faz sozinho (`PW-AGT-05`).

---

## Passo 8 — Fechar

1. **`--repeat-each=20`** confirma a correção. Uma execução verde não prova nada num flake de 1 em 4.
2. **Defeito de produto**: o teste não muda — diga isso.
3. **Paridade de ambiente**: o conserto é o pipeline.
4. **Transforme o diagnóstico em portão** — trace ligado, flaky não contando como verde.
5. **Se o mesmo teste volta a flakear**, a causa raiz não foi encontrada (`TS-PROC-08`).
6. **Declare o que não foi verificado.**

---

## Exemplo

Clique que falha ~25% no CI e passa local. A aba **Log** dá a causa em uma linha — `element intercepts pointer events` — e o Snapshot Before mostra o toast sobre o botão. `force: true` é explicitamente descartado: o defeito é do produto, porque o usuário também não consegue clicar.

Diagnóstico completo: `references/exemplo-diagnostico.md`.

---

## Relacionados

- [[Playwright - Debug e Trace]] — fonte desta skill
- [[Playwright]] § 5.2 — a árvore de diagnóstico
- [[playwright-build]] · [[playwright-review]] — as skills irmãs
- [[teste-diagnose]] — diagnostica a **suíte**; esta diagnostica **um teste**
