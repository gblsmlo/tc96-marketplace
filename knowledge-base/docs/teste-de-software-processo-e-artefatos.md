---
titulo: Teste de Software - Processo e Artefatos
Link: https://www.guru99.com/software-testing-life-cycle.html
tags:
 - testing
 - process
 - qa
 - defect-management
 - agent-context
source: "guru99 (STLC, defect life cycle, severidade × prioridade, V-model), ISTQB CTFL v4.0 (atividades de teste)"
verificado-em: 2026-08-20
---

# Teste de Software — Processo e Artefatos

> Satélite de [Teste de Software](teste-de-software.md). Cobre o vocabulário de **processo**: as fases, os artefatos, o ciclo de vida do defeito e as métricas. É o satélite menos técnico e o mais necessário para conversar com quem não escreve código.
>
> **Como ler isto num contexto ágil.** O STLC descrito aqui vem do mundo de QA formal, com fases e documentos. Num time que entrega continuamente, as **fases não desaparecem — elas se comprimem** e mudam de dono: a análise de requisito virou a conversa de refinamento, o plano virou a política no `CONTRIBUTING.md`, e o ciclo de execução roda a cada PR. O que **não** se comprime é a pergunta de cada fase, e é por isso que o vocabulário continua útil. Onde a versão ágil difere, esta nota diz.

---

## 1. STLC — as seis fases

| Fase | Pergunta | Entregável clássico | Forma ágil |
| --- | --- | --- | --- |
| **1. análise de requisito** | o que é testável, e o que está ambíguo? | RTM, relatório de viabilidade | critério de aceite no ticket |
| **2. planejamento** | escopo, abordagem, recurso, risco | plano de teste, estimativa | política de teste do repositório |
| **3. desenho de caso** | quais casos, com que dados? | casos, scripts, massa de dado | os testes automatizados em si |
| **4. ambiente** | onde roda, com que dado? | checklist de ambiente, smoke | `webServer` + container + seed |
| **5. execução** | passou? o que falhou e por quê? | log, defeitos, RTM atualizada | o CI, e o relatório do runner |
| **6. encerramento** | o que aprendemos? | relatório de fechamento, métricas | retrospectiva, e o defeito virando teste |

**Cada fase tem critério de entrada e de saída**, e esse é o conceito que sobrevive melhor à compressão ágil: um portão declarado. "Critério de saída da execução: nenhum defeito crítico aberto" é a mesma ideia de "o merge é bloqueado se a suíte falha" — e o segundo é a versão executável do primeiro.

**A fase 1 é a mais subestimada.** A pergunta dela — *o que aqui está ambíguo?* — encontra defeito de requisito antes de existir código, e é o terceiro princípio (*early testing*) em ação. Uma tabela de decisão montada no refinamento acha o requisito faltando ([Teste de Software - Técnicas de Design de Caso](teste-de-software-tecnicas-de-design-de-caso.md) § 2.3) por um custo que nenhuma outra fase consegue.

### 1.1 V-model e shift-left

O **V-model** emparelha cada nível de especificação com um nível de teste: requisito ↔ aceitação, arquitetura ↔ sistema, desenho ↔ integração, código ↔ unidade. O valor dele não é o processo em cascata: é a **simetria** — cada artefato produzido tem um teste que o verifica, e planejar o teste junto com o artefato é o que evita descobrir na ponta que o requisito não era verificável.

**Shift-left** é essa simetria levada ao extremo: mover a verificação para o mais cedo possível. Concretamente, num stack como este:

| Deslocamento | Ferramenta |
| --- | --- |
| do runtime para o build | TypeScript, Biome |
| do CI para o editor | LSP, lint no salvamento |
| do CI para o pre-commit | hooks |
| da produção para o CI | suíte de regressão |
| do código para o requisito | critério de aceite, tabela de decisão |

A camada estática é a expressão mais literal do shift-left, e é por isso que ela conta como teste ([Teste de Software - Tipos e Atributos de Qualidade](teste-de-software-tipos-e-atributos-de-qualidade.md) § 4).

---

## 2. Estratégia × plano

Confusão frequente, e a distinção é útil (`TS-PROC-02`):

| | Estratégia de teste | Plano de teste |
| --- | --- | --- |
| Escopo | organização ou produto | um projeto ou release |
| Duração | duradoura | temporária |
| Conteúdo | política, padrões, níveis, ferramentas | escopo, cronograma, recurso, entregáveis |
| Pergunta | *como testamos, aqui?* | *como testamos isto, agora?* |

Num repositório, a **estratégia** é o que este vault chama de doc e regra normativa: os `TS-*`, a forma da suíte, as ferramentas por nível. O **plano** é o que cabe num ticket.

O sintoma de não ter estratégia: cada pessoa decide o nível por gosto, e a suíte vira a média de opiniões — o que na prática significa *ice-cream cone*, porque E2E é o default intuitivo (`TS-NIV-04`).

---

## 3. Cenário × caso × script

| Artefato | O que é | Exemplo |
| --- | --- | --- |
| **cenário** | o *quê*, em uma linha | "verificar login com senha inválida" |
| **caso** | passos, dado, esperado, obtido | os passos concretos, com valores |
| **script** | o caso executável | o arquivo de teste |

**RTM** (*Requirements Traceability Matrix*) liga requisito → caso → resultado. Serve para responder duas perguntas: *que requisito não tem teste?* e *que teste não corresponde a requisito nenhum?*

A segunda pergunta é a mais interessante e quase nunca é feita. Teste que não rastreia a requisito nenhum é candidato a ser: verificação de detalhe de implementação (`TS-CORE-07`), duplicata de outro nível (`TS-CORE-02`), ou resquício de uma feature removida.

**Num repositório, a RTM não precisa ser planilha.** Ela é: título de teste que descreve comportamento, tag ligando teste a ticket, e anotação de issue no teste. É a mesma função com custo de manutenção quase zero.

---

## 4. Ciclo de vida do defeito

Os estados, no vocabulário clássico:

```
 ┌─────────────────────────────────────────┐
 ▼ │
 New ──▶ Assigned ──▶ Open ──▶ Fixed ──▶ Pending Retest
 │ │ │
 │ │ ▼
 │ │ Retest
 │ │ │
 │ │ ┌────────┴────────┐
 │ │ ▼ ▼
 │ │ Verified Reopen ──┐
 │ │ │ │
 │ │ ▼ │
 │ │ Closed │
 │ │ │
 └───────────┴──▶ Rejected · Duplicate · │
 Deferred · Not a Bug │
 │
 (Reopen volta para Assigned/Open) ──────────┘
```

Os 13 estados: **New**, **Assigned**, **Open**, **Fixed**, **Pending Retest**, **Retest**, **Verified**, **Reopen**, **Closed**, **Duplicate**, **Rejected**, **Deferred**, **Not a Bug**.

**O que importa disso num time pequeno**, onde o quadro tem três colunas:

1. **`Fixed` não é `Verified`.** Quem corrige não é quem confirma. Colapsar os dois é como um defeito volta.
2. **`Reopen` existe e é informação.** Um defeito reaberto muitas vezes é sinal de causa raiz não encontrada —.
3. **`Deferred` é decisão explícita**, não esquecimento. A diferença é ter data ou release associada.
4. **`Rejected` e `Not a Bug` merecem justificativa escrita**, porque frequentemente são desacordo sobre requisito — que é achado de fase 1 chegando tarde.

### 4.1 O relatório de defeito

A fonte descreve os estados e **não** descreve o que um relatório deve conter. Esta doc prescreve, porque é o que decide se o defeito é acionável (`TS-PROC-06`):

| Campo | Por quê |
| --- | --- |
| **passos de reprodução** | sem eles, ninguém corrige — investiga |
| **resultado esperado** | separa defeito de desacordo sobre requisito |
| **resultado obtido** | o que se vê, não a interpretação |
| **ambiente** | versão, browser, SO, dado, usuário |
| **severidade** e **prioridade** | dois campos, § 5 |
| **evidência** | trace, log, screenshot, vídeo |

No stack, a evidência mais valiosa é o **trace** do Playwright: ele carrega DOM, rede, console e a linha de código de uma vez ([Playwright - Debug e Trace](playwright-debug-e-trace.md)). Anexar o trace ao ticket substitui meia página de descrição.

---

## 5. Severidade × prioridade

Dois campos independentes, e é a confusão mais comum do processo (`TS-PROC-04`):

| | Severidade | Prioridade |
| --- | --- | --- |
| Mede | impacto no funcionamento | ordem de correção |
| Base | aspecto técnico | valor de negócio |
| Quem define | quem testa | gestão / cliente |
| Natureza | objetiva, estável | subjetiva, muda com o tempo |

**As combinações cruzadas são as que provam que os campos são dois:**

| Caso | Severidade | Prioridade |
| --- | --- | --- |
| logo errado no site, em toda página | **baixa** — nada quebra | **alta** — cada minuto propaga a marca errada |
| defeito grave num fluxo usado por 3 clientes ao ano | **alta** — o fluxo não funciona | **baixa** — pode esperar o próximo release |
| checkout fora do ar | alta | alta |
| erro de digitação numa tela interna | baixa | baixa |

Colapsar em um campo força a escolher qual informação perder — e o que se perde na prática é a severidade, porque prioridade é o que aparece no planejamento. O resultado é uma base de defeitos onde não se sabe mais o que é tecnicamente grave.

---

## 6. Métricas

As que a fonte nomeia e que resistem a uso:

| Métrica | Mede | Cuidado |
| --- | --- | --- |
| **densidade de defeitos** | defeitos ÷ tamanho | tamanho é proxy ruim; útil para comparar módulos |
| **índice de severidade** | distribuição por severidade | melhor que contagem crua |
| **taxa de escape** | defeitos achados em produção ÷ total | **a mais honesta** — mede o que a suíte não pegou |
| **eficiência de remoção** | achados antes da entrega ÷ total | outra face da mesma coisa |
| **tendência de execução** | passou/falhou/pulou ao longo do tempo | onde flaky aparece |
| **taxa de flakiness** | intermitentes ÷ total | ~1% é o limiar de perda de valor |

> **A métrica que mais engana é cobertura**, e a que menos engana é **taxa de escape**. Cobertura mede o que a suíte executou; escape mede o que ela deixou passar até o usuário. Um time que acompanha escape descobre *que classe* de teste falta; um time que acompanha cobertura descobre que linha ninguém chamou (`TS-CORE-05`).

**Defect clustering** — quarto princípio — é o que torna essas métricas acionáveis: defeito se concentra em poucos módulos, tipicamente na proporção de Pareto. Densidade por módulo aponta onde apertar, e é a base do **teste baseado em risco**: onde a probabilidade de defeito e o impacto são maiores, mais esforço.

---

## 7. Regras — `TS-PROC-01` a `TS-PROC-10`

| ID | Regra |
| --- | --- |
| `TS-PROC-01` | Requisito **MUST** ter critério de aceite verificável antes de entrar em desenvolvimento. Requisito ambíguo **NEVER** é considerado pronto. † |
| `TS-PROC-02` | Estratégia de teste e plano de teste **NEVER** são o mesmo artefato: estratégia é política, duradoura e organizacional; plano é de um projeto ou release. |
| `TS-PROC-03` | Cada portão de qualidade **MUST** ter critério de saída declarado e verificável. † |
| `TS-PROC-04` | Severidade e prioridade **NEVER** são a mesma coisa: severidade é impacto técnico (do teste), prioridade é ordem de correção (do negócio). |
| `TS-PROC-05` | Defeito **MUST** ser verificado por quem não o corrigiu. `Fixed` **NEVER** é `Verified`. |
| `TS-PROC-06` | Relatório de defeito **MUST** conter passos de reprodução, resultado esperado, resultado obtido e ambiente. Sem isso, **NEVER** é relatório — é aviso. † |
| `TS-PROC-07` | `Deferred` **MUST** carregar data ou release. Adiamento sem prazo **NEVER** — é esquecimento com nome bonito. † |
| `TS-PROC-08` | Defeito reaberto repetidamente **MUST** disparar análise de causa raiz, **NEVER** outra correção pontual. † |
| `TS-PROC-09` | Esforço de teste **MUST** ser alocado por risco (probabilidade × impacto), **NEVER** distribuído uniformemente — defeito se concentra. |
| `TS-PROC-10` | Taxa de escape **MUST** ser a métrica de acompanhamento preferida sobre cobertura. † |

---

## 8. Antipadrões

### 8.1 Requisito sem critério de aceite

"Melhorar a performance do checkout" entra na sprint. Não há como verificar, então não se verifica (`TS-PROC-01`, e `TS-TIPO-05`).

### 8.2 Quem corrige é quem verifica

O mesmo modelo mental que produziu o defeito confirma a correção (`TS-PROC-05`).

### 8.3 Um campo só para severidade e prioridade

Perde-se a severidade, e a base de defeitos deixa de dizer o que é tecnicamente grave (`TS-PROC-04`).

### 8.4 "Não funciona" como relatório

Sem passos, sem esperado, sem ambiente. Vira investigação em vez de correção (`TS-PROC-06`).

### 8.5 `Deferred` como cemitério

Sem data, o backlog acumula defeitos que ninguém vai reavaliar (`TS-PROC-07`).

### 8.6 Corrigir o mesmo defeito três vezes

Três correções pontuais no mesmo lugar são um sintoma, não três defeitos (`TS-PROC-08`).

### 8.7 Esforço uniforme

Testar todo módulo igual ignora *defect clustering* e gasta no lugar errado (`TS-PROC-09`).

### 8.8 Meta de cobertura como indicador de qualidade

Ver § 6 e `TS-CORE-05`. O indicador honesto é escape (`TS-PROC-10`).

### 8.9 Tratar as fases do STLC como documentos obrigatórios

O outro extremo do erro. Num time que entrega continuamente, produzir plano de teste formal por release é custo sem informação — o que precisa sobreviver é a **pergunta** de cada fase, não o artefato. Ver § 1.

---

## Relacionados

- [Teste de Software](teste-de-software.md) — o hub
- [Teste de Software - Técnicas de Design de Caso](teste-de-software-tecnicas-de-design-de-caso.md) — a tabela de decisão como instrumento da fase 1
- [Teste de Software - Tipos e Atributos de Qualidade](teste-de-software-tipos-e-atributos-de-qualidade.md) — critério numérico, e a camada estática como shift-left
- [Teste de Software - Confiabilidade da Suíte](teste-de-software-confiabilidade-da-suite.md) — a taxa de flakiness da § 6
- · — a mesma matéria pelo lado da gestão
- — causa raiz do defeito reaberto
- [Playwright - Debug e Trace](playwright-debug-e-trace.md) — o trace como evidência anexável
- [Github Actions](github-actions.md) · — os portões executáveis
- [Pull Request](pull-request.md) · [Pull Request Template](pull-request-template.md) — onde o critério de saída vive num repositório
-
- — as fases comprimidas em prática de time

## Fontes consultadas

Verificadas em **2026-08-20**:

- [guru99 — Software Testing Life Cycle](https://www.guru99.com/software-testing-life-cycle.html) — as seis fases com atividades, critério de entrada/saída e entregáveis
- [guru99 — Defect Life Cycle](https://www.guru99.com/defect-life-cycle.html) — os 13 estados e as transições
- [guru99 — Severity vs Priority](https://www.guru99.com/defect-severity-in-software-testing.html) — a tabela comparativa e os exemplos cruzados
- [guru99 — Software Testing](https://www.guru99.com/software-testing.html) — V-model, métricas, estratégia × plano, RTM
- Vocabulário de atividades de teste: ISTQB CTFL v4.0, cap. 5 ("Managing the Test Activities") — **verificado por fonte terciária**, ver a ressalva em [Teste de Software](teste-de-software.md) § Fontes

**Decisões desta doc, não da fonte:** o conteúdo mínimo do relatório de defeito (§ 4.1 — a fonte descreve os estados e não o relatório); a coluna "forma ágil" da § 1; e a preferência por taxa de escape sobre cobertura (§ 6).
