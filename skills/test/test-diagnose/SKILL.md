---
nome: test-diagnose
descricao: Diagnosticar uma suíte em que ninguém confia — medir a taxa de flakiness antes de opinar, achar a causa e separar conserto de anestésico, citando IDs `TS-*` — use quando a tarefa for investigar suíte instável como sistema, responder "por que passamos verde e o defeito chega em produção?", avaliar se as asserções detectam quebra, decidir se retry está mascarando defeito, ou quando o mesmo teste volta a flakear depois de corrigido. Não use para um teste concreto falhando, que é playwright-diagnose ou bun-test-review. Não use para auditar a forma da suíte, que é test-review, nem para decidir teste novo, que é test-design.
tipo: skill
familia: test
fonte: "[Teste de Software - Confiabilidade da Suíte](../../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md)"
tags:
  - skill
  - testing
  - software-quality
  - flaky-tests
---
# test-diagnose

> **Fonte desta skill:** [Teste de Software - Confiabilidade da Suíte](../../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md), com a § 4.5 do hub [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) como árvore de diagnóstico. As 64 regras da família `TS-*` moram na § 6 do hub.
> Esta skill **não contém** o texto das regras — ela diz o que medir, em que ordem eliminar hipóteses e como reportar.

Contrato que esta skill implementa: [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) § 7 ("Contrato de skill").

> **Nota de desenho.** Esta skill diagnostica a **suíte como sistema**: taxa de flakiness, confiança, capacidade de detectar quebra. `playwright-diagnose` e `bun-test-review` diagnosticam **um teste** que falha. A diferença prática: elas leem um trace; esta lê o histórico do CI. Chegar aqui com um único teste vermelho é usar a ferramenta errada — e chegar lá com "a suíte é flaky" produz um diagnóstico por vez, para sempre.

---

## Quando usar

A suíte, como conjunto, perdeu credibilidade: falhas intermitentes, gente reexecutando o job por reflexo, verde que não convence, ou defeito chegando em produção com tudo passando.

| Situação | Vá para |
| --- | --- |
| **um** teste falhando ou flakeando | `playwright-diagnose` (E2E) · `bun-test-review` (Bun) |
| auditar a forma e a cobertura de risco | `test-review` |
| decidir teste novo | `test-design` |
| a falha é defeito real do produto | então **a suíte funcionou** — pare e conserte o produto |
| defeito recorrente, causa organizacional | [Teste de Software - Processo e Artefatos](../../../knowledge-base/docs/teste-de-software-processo-e-artefatos.md) |

---

## Carregamento mínimo

| Ordem | Carregar | Por quê |
| --- | --- | --- |
| 1 | [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) § 2 (afirmação 5) | **a aritmética**: uma suíte não confiável é pior que nenhuma suíte |
| 2 | [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) § 4.5 | as seis perguntas de "não confio na suíte" |
| 3 | [Teste de Software - Confiabilidade da Suíte](../../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md) § 1 e § 2 | os números, e as dez causas em ordem de frequência |
| 4 | `references/mapa-de-ids.md` | antes de citar — três IDs são apelidos |

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/medicao.md` | o Passo 0, as métricas e os limiares |
| `references/causas-de-flake.md` | as seis perguntas, as dez causas, e os comandos que separam hipóteses |
| `references/deteccao.md` | o teste de trinta segundos e o corolário sobre cobertura |
| `references/conserto-x-anestesico.md` | os sete anestésicos e a grade de 21 antipadrões |
| `references/mapa-de-ids.md` | os 64 `TS-*` por satélite e seção |
| `references/exemplo-diagnostico.md` | diagnóstico inteiro, da medida ao relatório |
| `scripts/medir-flakiness.sh` | inventaria anestésicos e mede a taxa em N execuções |

---

## Passo 0 — A pergunta que vem antes

> **As falhas são defeitos reais do produto?**

Se sim, **a suíte fez o trabalho dela**. Falha **determinística** é defeito; falha **intermitente** é a suíte. Só o segundo caso é desta skill.

---

## Passo 1 — Medir antes de opinar

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/test-diagnose/scripts/medir-flakiness.sh "bun test" 20
```

O script inventaria os **anestésicos já instalados** (retry, `workers: 1`, `skip`, espera por tempo fixo, relógio real, prefixo numérico, `try/catch` no corpo) e **mede a taxa**.

**Sem a taxa, não há diagnóstico** — há impressão. 0,05% e 3% têm o mesmo sintoma percebido e prognósticos opostos. Acima de **~1%** as pessoas param de acreditar no vermelho, e o vermelho verdadeiro passa junto com os falsos (`TS-CORE-04`).

Limiares e a leitura do zero: `references/medicao.md`.

---

## Passo 2 — As seis perguntas

`references/causas-de-flake.md`, **na ordem**. A pergunta 1 (há falha intermitente?) interrompe as outras cinco: flakiness contamina todo o resto.

A pergunta **3** é a mais reveladora e a menos feita — vá para o Passo 4.
A pergunta **6** é a que mais traz o time até aqui, e a resposta quase nunca é "falta cobertura": é **classe de risco** ausente.

---

## Passo 3 — Achar a causa

Dez causas em ordem de frequência, e os comandos que as separam — sozinho, um worker, ordem aleatória, 20×, container do CI. **A causa nº 1 é sempre a mesma:** esperar **tempo** em vez de esperar **condição** (`TS-SUI-07`).

> **Diagnosticar não é consertar.** Um worker faz a falha sumir e **mantém** o acoplamento.

---

## Passo 4 — O teste de trinta segundos

`references/deteccao.md`. **Quebre o código de propósito** em três lugares escolhidos por risco. Se a suíte fica verde em qualquer um, a asserção não existe (`TS-SUI-04`) — achado **bloqueante**, e explica sozinho a pergunta 6.

Cobertura não responde a essa pergunta: um teste que chama a função e não afirma nada dá cobertura total (`TS-CORE-05`).

---

## Passo 5 — Formato de saída

Cinco partes — **a medida** é o que distingue esta skill de um chute:

```
`ID-DA-REGRA` — <onde>
Sintoma: <como o problema se apresenta para o time>
Medida: <o número, e de onde veio>
Causa: <uma frase>
Correção: <mudança concreta, com ponto de partida>
Ver Satélite correspondente.
```

"A suíte é flaky" sem taxa não é achado. "Conserte as esperas" sem dizer por qual arquivo começar é inútil numa suíte com 17%.

---

## Passo 6 — Conserto × anestésico

`references/conserto-x-anestesico.md`: sete correções que fazem o vermelho sumir sem resolver nada. As duas mais graves — `try/catch` no corpo e remover a asserção — são **invisíveis em revisão**.

---

## Passo 7 — Fechar

1. **Reporte a taxa, antes e depois.** "Caiu de 17% para 0,4%" é o único fechamento verificável.
2. **Confirme com repetição.** 20 execuções verdes; uma não prova nada num flake de 1 em 6.
3. **Se a causa foi defeito de produto**, a suíte não muda. Diga isso.
4. **Se a causa foi a forma da suíte**, continue em `test-review` — é reestruturação, não conserto.
5. **Transforme o diagnóstico em portão:** ordem aleatória no pipeline, flaky não contando como verde, repetição no job noturno, o teste de trinta segundos como passo de revisão.
6. **Se o mesmo teste volta a flakear**, a causa raiz não foi encontrada (`TS-PROC-08`).
7. **Declare o que não foi medido.** "Não medido" não é "sem problema".

---

## Exemplo

Time reexecuta o job por reflexo. O script mede **25% em 20 execuções locais**, e o histórico do CI confirma 17% em 200. A pergunta 1 interrompe as demais; a causa são 9 arquivos com espera por tempo fixo e 3 compartilhando conta entre workers. Um segundo achado vem do teste de trinta segundos: invertida uma comparação, a suíte inteira continua verde — com 96% de cobertura no arquivo.

Diagnóstico completo, com os dois relatórios: `references/exemplo-diagnostico.md`.

---

## Relacionados

- [Teste de Software - Confiabilidade da Suíte](../../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md) — fonte desta skill: a aritmética, as dez causas, test smells
- [Teste de Software](../../../knowledge-base/docs/teste-de-software.md) — § 2 (afirmação 5), § 4.5 (a árvore), § 6, § 7
- `test-design` · `test-review` — as skills irmãs
- `playwright-diagnose` · `bun-test-review` — diagnosticam **um teste**; esta diagnostica a **suíte**
- `Docs/Playwright.md` § 5.2 · `Docs/Bun - Testes - Ciclo de Vida e Isolamento.md` — as formas concretas por ferramenta
