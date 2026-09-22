---
Link: https://www.guru99.com/software-testing.html
tags:
 - testing
 - software-quality
 - non-functional
 - agent-context
source: "guru99 (tipos de teste, performance), ISTQB CTFL v4.0 (tipos e change-related testing), Software Engineering at Google cap. 11"
verificado-em: 2026-08-20
---

# Teste de Software — Tipos e Atributos de Qualidade

> Satélite de [Teste de Software](teste-de-software.md). Cobre o eixo **ortogonal ao nível**: dado que o teste vai existir, *que propriedade* ele verifica.
>
> **O problema que esta nota resolve primeiro.** As listas de "tipos de teste" que circulam — 60 itens, às vezes mais — não são uma taxonomia: são cinco taxonomias sobrepostas. "Teste de unidade", "teste de regressão", "teste de carga", "teste caixa-preta" e "teste beta" não são cinco valores do mesmo campo. A § 1 separa os eixos, e é isso que torna a lista utilizável.

---

## 1. Os cinco eixos que a lista clássica mistura

| Eixo | Pergunta | Valores | Onde está |
| --- | --- | --- | --- |
| **nível** | quanto de código? | unidade, integração, sistema, aceitação | [Teste de Software - Níveis e Escopo](teste-de-software-niveis-e-escopo.md) |
| **objetivo** | por que agora? | smoke, sanity, regressão, reteste, exploratório | § 3 desta nota |
| **atributo** | qual propriedade? | funcional, performance, segurança, usabilidade, … | § 2 desta nota |
| **técnica** | como derivei os casos? | caixa-preta, caixa-branca, experiência | [Teste de Software - Técnicas de Design de Caso](teste-de-software-tecnicas-de-design-de-caso.md) |
| **quem/onde** | quem executa? | alpha, beta, UAT | [Teste de Software - Níveis e Escopo](teste-de-software-niveis-e-escopo.md) § 1 |

Um único teste tem um valor em **cada** eixo ao mesmo tempo. "Um teste de carga de integração, derivado por valor limite, rodando como regressão no CI" é uma frase coerente — e é impossível de expressar numa lista plana.

**Consequência para quem escreve ou revisa:** "que tipo de teste falta?" é uma pergunta ambígua. A pergunta útil é sempre por eixo: *falta cobrir qual atributo?*, *falta em qual nível?*

---

## 2. Funcional × não funcional

**Funcional** verifica *o que* o sistema faz — o comportamento contra o requisito. É o default, e é o que quase toda suíte cobre.

**Não funcional** verifica *quão bem* — as propriedades de qualidade. É o que quase nenhuma suíte cobre, e é onde os incidentes acontecem.

### 2.1 O mapa dos atributos não funcionais

| Atributo | Verifica | Como se mede |
| --- | --- | --- |
| **performance** | tempo de resposta e throughput sob condição definida | percentil (p50, p95, p99), não média |
| **carga** (*load*) | comportamento sob a carga esperada | usuários/requisições concorrentes × latência |
| **estresse** (*stress*) | comportamento **além** do esperado, até quebrar | onde degrada, e **como** degrada |
| **volume** | comportamento com massa grande de dados | tamanho de tabela, de payload, de arquivo |
| **escalabilidade** | se cresce com o recurso adicionado | latência × instâncias |
| **soak** / *endurance* | degradação ao longo de horas ou dias | vazamento de memória, conexão não devolvida |
| **spike** | reação a pico súbito | recuperação após o pico |
| **segurança** | resistência a uso malicioso | ver a ponte da § 2.3 |
| **usabilidade** | facilidade de uso real | teste com pessoa; não automatizável |
| **acessibilidade** | uso por tecnologia assistiva | varredura automática + teste manual |
| **compatibilidade** | funcionamento em browser/SO/device | matriz de ambiente |
| **confiabilidade** | comportamento em falha e recuperação | MTBF, taxa de erro |

**A distinção carga × estresse é a que mais se confunde:** carga responde *"aguenta o que esperamos?"*; estresse responde *"quando quebra, quebra bem?"*. A segunda é a mais informativa — degradar recusando requisição com `503` é aceitável, degradar corrompendo dado não é.

### 2.2 A regra que torna atributo não funcional testável

Atributo não funcional só é verificável se tiver **número**. "Deve ser rápido" não é requisito; "p95 do checkout abaixo de 2 s com 200 usuários concorrentes" é (`TS-TIPO-05`).

Isto já está registrado no vault, com o exemplo completo, em — e é o ponto em que teste e gestão de qualidade se encontram: o critério de aceite numérico é o que permite QC existir.

**E use percentil, não média.** Média esconde a cauda, e a cauda é a experiência de quem reclama. Um p50 de 200 ms com p99 de 8 s é um sistema que 1% das pessoas considera quebrado.

### 2.3 Onde cada atributo é decidido neste vault

| Atributo | Ponte |
| --- | --- |
| segurança de sessão e autorização | `OWASP - Sessão e Autorização`, `RFC 8725 - JWT Best Current Practices`, `NIST RBAC - ANSI INCITS 359` |
| segurança de fronteira HTTP | [HTTP - CORS](http-cors.md), `RFC 6265 - Cookies HTTP` |
| acessibilidade (componente) | [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) |
| acessibilidade (página) | [Playwright - Snapshots e Visual](playwright-snapshots-e-visual.md) § 5 |
| compatibilidade de browser | projects — [Playwright - Configuração e Projects](playwright-configuracao-e-projects.md) § 3.1 |
| performance de query | [Drizzle - Queries e Relations](drizzle-queries-e-relations.md), `PostgreSQL` |
| cache e condicional HTTP | [HTTP - Cache e Requisições Condicionais](http-cache-e-requisicoes-condicionais.md) |

**A ressalva que vale para acessibilidade e vale para segurança:** varredura automática pega uma classe de problema e declara isso. Suíte verde no axe não é aplicação acessível, e nenhum SAST substitui revisão. É a `TS-CORE-08` aplicada a um atributo específico.

---

## 3. O eixo do objetivo

Por que este teste está rodando **agora**.

| Objetivo | O que é | Quando roda |
| --- | --- | --- |
| **smoke** | verificação rasa e ampla: "subiu?" | primeiro, após deploy ou build |
| **sanity** | verificação estreita e profunda de uma área que acabou de mudar | após correção pontual |
| **regressão** | o que já funcionava continua funcionando | sempre, em CI |
| **reteste** (*confirmation*) | **este** defeito corrigido está corrigido | após a correção |
| **exploratório** | busca ativa de defeito desconhecido, sem roteiro | manual, por pessoa |

### 3.1 Reteste × regressão

Os dois são "change-related testing" no vocabulário ISTQB, e **não são sinônimos** (`TS-TIPO-03`):

- **reteste** executa o caso que falhou, para confirmar que o defeito específico saiu;
- **regressão** executa o resto, para descobrir se a correção quebrou outra coisa.

Confundi-los produz o padrão mais comum de release ruim: corrigir, retestar só o ticket, entregar, e descobrir que a correção quebrou um fluxo vizinho. **A correção é uma mudança**, e mudança pede regressão.

### 3.2 Smoke × sanity

**Smoke** é largo e raso — cobre muitas áreas, sem profundidade, e responde "vale a pena testar isto?". **Sanity** é estreito e profundo — cobre uma área com detalhe.

Aplicado a este stack: um smoke de 5 E2E que abrem as telas principais e verificam que renderizam é o portão mais barato que existe, e roda antes da suíte completa. É o único caso em que E2E é a ferramenta certa para verificação rasa.

### 3.3 Exploratório é insubstituível, e não é automatizável

A suíte automatizada **detecta reintrodução**; ela quase nunca acha defeito novo. É o *pesticide paradox*: conjunto fixo de casos para de achar coisa nova.

Quem acha defeito novo é: teste exploratório, revisão de código, e produção observada. Uma organização que só tem suíte automatizada tem cobertura de regressão excelente e descoberta zero — e conclui erradamente que a qualidade está resolvida.

**O ganho barato:** depois de exploratório achar algo, o achado vira caso automatizado (`TS-CORE-06`). Exploratório descobre, suíte guarda.

---

## 4. Estático × dinâmico

**Teste estático** examina o artefato **sem executar**: revisão, inspeção, walkthrough, e análise estática automatizada. **Teste dinâmico** executa.

O que costuma passar: **estático pega defeito que dinâmico não pega** — inconsistência de requisito, código morto, tipo incompatível, padrão de risco. E pega mais cedo, o que é o terceiro princípio (*early testing*): defeito encontrado em requisito custa muito menos que em produção.

No stack deste vault a camada estática é substancial e frequentemente esquecida na conta:

| Ferramenta | Pega |
| --- | --- |
| TypeScript | tipo incompatível, propriedade inexistente, exaustividade de union |
| Biome / ESLint | padrão de risco, código morto, `no-floating-promises` |
| Zod / TypeBox | o que o tipo **não** pega: a fronteira em runtime |
| revisão de código | intenção, legibilidade, decisão de desenho |

É a base do Testing Trophy, e a razão de ela estar lá: é a camada mais barata de todas, e a única que roda no editor.

> **O par que precisa dos dois:** TypeScript não protege nada depois do build. Tipo é compile-time; a fronteira precisa de validação em runtime. É por isso que Zod na borda não é redundância com o tipo — é a outra metade. Ver `Zod - Validação de Ambiente` e.

---

## 5. Manual × automatizado

Não é um eixo de qualidade — é um eixo de **custo e adequação**.

| Automatize | Mantenha manual |
| --- | --- |
| regressão | exploratório |
| verificação determinística e repetitiva | usabilidade |
| carga e performance | validação com usuário (UAT) |
| o que roda em toda mudança | o que roda uma vez |

O critério: **automatize o que se repete e tem resultado esperado inequívoco.** Um caso que roda uma vez, ou cujo "certo" depende de julgamento, custa mais para automatizar do que para executar.

E o corolário incômodo: automatizar teste de usabilidade não é possível, e automatizar exploratório é contradição em termos — o valor dele está justamente em não seguir roteiro.

---

## 6. Regras — `TS-TIPO-01` a `TS-TIPO-09`

| ID | Regra |
| --- | --- |
| `TS-TIPO-01` | "Que tipo de teste falta?" **MUST** ser respondida por eixo (nível, objetivo, atributo, técnica). A pergunta sem eixo **NEVER** é acionável. † |
| `TS-TIPO-02` | Todo estado observável de um fluxo — carregando, vazio, sucesso, erro, recuperação — **MUST** ter cobertura proporcional ao risco. Cobrir só o caminho feliz **NEVER**. † |
| `TS-TIPO-03` | Teste de regressão e reteste **NEVER** são sinônimos: reteste confirma **um** defeito corrigido; regressão verifica que o resto continua funcionando. |
| `TS-TIPO-04` | Correção de defeito **MUST** disparar regressão, não apenas reteste do ticket. † |
| `TS-TIPO-05` | Atributo não funcional que é requisito **MUST** ter critério numérico e um teste que o meça. "Deve ser rápido" **NEVER** é requisito. † |
| `TS-TIPO-06` | Requisito de performance **MUST** ser expresso em percentil. Média **NEVER** — ela esconde a cauda, que é a experiência de quem reclama. † |
| `TS-TIPO-07` | Varredura automática de acessibilidade ou de segurança **NEVER** é declarada como cobertura do atributo: ela pega uma classe de problema, e isso **MUST** estar dito. |
| `TS-TIPO-08` | A camada estática (tipo, lint) **MUST** ser contada como teste na estratégia — é a mais barata e a que roda mais cedo. † |
| `TS-TIPO-09` | Exploratório **NEVER** é substituível por suíte automatizada: suíte detecta reintrodução, exploratório descobre. Todo achado de exploratório **MUST** virar caso automatizado. |

---

## 7. Antipadrões

### 7.1 Só o caminho feliz

Fluxo com teste de sucesso e nada de erro, vazio ou carregando. Os estados não-felizes são onde o usuário sofre, e são baratos de cobrir no nível de componente (`TS-TIPO-02`).

### 7.2 Reteste sem regressão

Corrigir, verificar o ticket, entregar. A correção é uma mudança (`TS-TIPO-04`).

### 7.3 "Deve ser rápido" como requisito

Não é verificável, então ninguém verifica, então degrada sem ninguém notar (`TS-TIPO-05`).

### 7.4 Média de tempo de resposta

Um p50 de 200 ms com p99 de 8 s reportado como "média de 300 ms" descreve um sistema saudável que 1% das pessoas considera quebrado (`TS-TIPO-06`).

### 7.5 Axe verde reportado como "acessível"

Ver § 2.3 e `TS-CORE-08` (`TS-TIPO-07`).

### 7.6 Suíte automatizada como toda a estratégia

Regressão excelente, descoberta zero — e a conclusão errada de que qualidade está resolvida (`TS-TIPO-09`).

### 7.7 Automatizar exploratório

Converter uma sessão exploratória em roteiro automatizado e chamar isso de exploratório. O que sobrou é regressão; o valor era não ter roteiro.

### 7.8 Carga chamada de estresse

Rodar a carga esperada e concluir que o sistema "aguenta estresse". Estresse é além do esperado, e a informação que ele dá é **como** degrada (§ 2.1).

---

## Relacionados

- [Teste de Software](teste-de-software.md) — o hub
- [Teste de Software - Níveis e Escopo](teste-de-software-niveis-e-escopo.md) — o eixo do nível
- [Teste de Software - Técnicas de Design de Caso](teste-de-software-tecnicas-de-design-de-caso.md) — o eixo da técnica
- [Teste de Software - Processo e Artefatos](teste-de-software-processo-e-artefatos.md) — critério de aceite e de saída
- — o critério numérico, com exemplo completo
- `OWASP - Sessão e Autorização` · [HTTP - CORS](http-cors.md) · `RFC 6265 - Cookies HTTP` — o atributo segurança
- [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) · [Playwright - Snapshots e Visual](playwright-snapshots-e-visual.md) — o atributo acessibilidade
- `TypeScript` · `Zod - Validação de Ambiente` · — a camada estática e a fronteira
- `PostgreSQL` · [Drizzle - Queries e Relations](drizzle-queries-e-relations.md) — performance de dado
- — os cinco estados de um fluxo

## Fontes consultadas

Verificadas em **2026-08-20**:

- [guru99 — Software Testing](https://www.guru99.com/software-testing.html) — a lista de tipos, os eixos de comparação do FAQ, e as 13 variantes de performance
- [Software Engineering at Google, cap. 11](https://abseil.io/resources/swe-book/html/ch11.html) — a Beyoncé Rule: testar tudo que não se quer que quebre, inclusive performance, acessibilidade e segurança
- [The Testing Trophy](https://kentcdodds.com/blog/the-testing-trophy-and-testing-classifications) — o estático como camada de teste
- Vocabulário de *confirmation testing* × *regression testing* e de teste estático: ISTQB CTFL v4.0 — **verificado por fonte terciária**, ver a ressalva em [Teste de Software](teste-de-software.md) § Fontes
