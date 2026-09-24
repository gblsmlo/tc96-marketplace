---
titulo: Fluxo de Entrega — Quatro Pilares
tags:
  - workflow
  - delivery
  - agent-context
  - reference
source: "Barry Boehm, Software Engineering Economics (curva de custo de mudança, origem de verificação×validação); Marty Cagan, Inspired: How to Create Tech Products Customers Love; Teresa Torres, Continuous Discovery Habits; Ryan Singer/Basecamp, Shape Up: Stop Running in Circles; Kent Beck, Extreme Programming Explained; Winters/Manshreck/Wright, Software Engineering at Google (cultura de code review — já citado em TS-*); Forsgren/Humble/Kim, Accelerate (métricas DORA); precedente interno: lemind, ADR 114 — \"o workflow de agentes tem quatro pilares\" (implementação observada em produção, não autoridade acadêmica)"
verificado-em: 2026-09-23
---
# Fluxo de Entrega — Quatro Pilares

> **O que esta nota é.** A **camada de procedimento sobre os onze agentes**: o momento em
> que uma tarefa está — pesquisa, planejamento, implementação ou validação — separado de
> **quem** a exerce. É o que decide para qual agente ou skill uma tarefa vai a seguir, quando
> isso ainda não está óbvio pelo pedido.
>
> **O que não é.** Não substitui nenhum dos onze agentes nem redefine o que cada um faz.
> Não é um quinto agente. É a formalização, com regra citável, do fluxograma que já existia
> implicitamente em `agents/README.md` ("How agents hand off") — que
> continua sendo a fonte do *quem*; esta nota é a fonte do *quando*.
>
> **Por que ela existe.** O projeto tinha onze papéis e um diagrama mermaid informal de como
> um bastão passa de um para o outro, mas nenhuma regra citável para decidir, no meio de uma
> tarefa, se o que falta é decisão (volta para trás), execução (segue) ou prova (evidência
> antes de fechar). Sem essa camada, a tendência é pular direto para "escrever código" com uma
> decisão de produto ainda em aberto — o equivalente, neste domínio, ao antipadrão que
> [Teste de Software](teste-de-software.md) descreve para nível de teste: pular a camada de
> conceito e ir direto para a ferramenta.

Fontes consultadas em **2026-09-23**. Ver [Fontes consultadas](#fontes-consultadas).

---

## 0. Antes de tudo: quatro distinções que decidem a conversa

**1. Pilar × papel.** *Pilar* é o momento do trabalho — pesquisa, planejamento, implementação
ou validação. *Papel* é quem o exerce — um dos onze agentes de `agents/README.md`.
Os dois eixos são **ortogonais**: o mesmo `software-architect` aparece no pilar de Pesquisa
(decidindo se uma mudança é arquitetural) e no de Planejamento (nomeando a fronteira de uma
unidade); o mesmo `qa-engineer` aparece na Implementação (nível do teste) e na Validação
(rodar a suíte). Reduzir um agente a um único pilar é o erro mais comum ao adotar este modelo
(`WF-CORE-02`).

**2. Pesquisa × descoberta contínua.** Pesquisa, aqui, não é um relatório extenso encomendado
uma vez por trimestre — é a menor investigação que resolve a decisão que trava o próximo
pilar, repetida quantas vezes uma tarefa precisar (Torres, *Continuous Discovery Habits*).
Uma pesquisa que devolve mais perguntas do que a decisão pedida não terminou.

**3. Verificação × validação.** Já registrado em [Teste de Software](teste-de-software.md)
§0, e vale repetir no nível do fluxo inteiro, não só do teste: verificação pergunta
"construímos certo?" (contrato, comportamento, regra); validação pergunta "construímos a
coisa certa?" (aceite de negócio). O pilar de Validação desta nota cobre a **primeira**
pergunta — é verificação técnica. A segunda pergunta é responsabilidade do `product-manager`
e acontece **depois** do fechamento técnico, nunca o bloqueando (`WF-VAL-03`).

**4. Pilar × nível de board.** *Nível de board* é a granularidade em que uma decisão vira
trabalho rastreável — Epic (capacidade permanente), Story (unidade de aceite) ou Task (corte
executável), definidos em `workflow-planning/references/template-{epic,story,task}.md`. A
Pesquisa (a descoberta contínua do item 2) **nunca** produz um item de board diretamente: ela
produz a decisão mínima que autoriza o Planejamento a abrir um. É no Planejamento, pelos
portões de decomposição e de fronteira (§4.2, `WF-PLAN-03`, `WF-PLAN-05`), que a árvore
Epic → Story → Task nasce. Abrir o Epic no rastreador assim que alguém tem uma ideia é o erro
espelhado de `WF-CORE-03`: em vez de pular a Pesquisa, finge que ela já terminou. Tabela
completa em §3. †

---

## 1. Como usar esta doc

### Para uma pessoa

Antes de pedir a um agente para "implementar X", pergunte: falta decidir alguma coisa sobre
**o que** fazer (→ pilar de Pesquisa), sobre **como dividir e quando** (→ Planejamento), ou já
está tudo decidido e é hora de **escrever** (→ Implementação)? Se o código já existe e a
pergunta é "isso está certo", vá direto para `code-reviewer` — a Validação já é o pilar dele.

### Para um agente de código

Ao receber uma tarefa ambígua, classifique o pilar **antes** de escolher a skill ou o agente
seguinte (§2). Uma tarefa que chega pedindo implementação mas carrega uma decisão de produto
não resolvida **não é** uma tarefa de implementação ainda — é uma tarefa de Pesquisa disfarçada
(`WF-CORE-03`).

### Convenções

`MUST`/`NEVER` são normativos, como em todo o resto da knowledge-base. **†** marca decisão
desta doc — sem paralelo direto numa única fonte externa, mas necessária para o modelo
funcionar neste projeto.

---

## 2. Modelo mental

| # | Pilar | Entra quando | Sai com |
| --- | --- | --- | --- |
| 1 | **Pesquisa** | o problema, o comportamento esperado ou uma decisão duradoura não está claro | decisão mínima resolvida, evidência, riscos, fontes |
| 2 | **Planejamento** | a decisão foi aceita mas o trabalho ainda não é executável | unidade(s) de trabalho delimitadas, dependências, perfil, critério de aceite, plano de evidência |
| 3 | **Implementação** | a unidade está pronta e o comportamento já foi decidido | código ou nota alterada, teste focado, evidência de implementação |
| 4 | **Validação** | existe uma mudança ou entrega e ela precisa de prova | checks focados e de repositório, achados de revisão, resultado claro |

Nenhuma tarefa pula pilar (`WF-CORE-03`): pode **voltar** um pilar quando descobre uma lacuna,
mas nunca decide "vou resolver isso na implementação mesmo" quando a lacuna é de pesquisa.

---

## 3. Onde cada pilar roteia

| Pilar | Skill | Agente(s) que o exercem, hoje | Nível de board |
| --- | --- | --- | --- |
| Pesquisa | `workflow-research` | `product-manager` · `product-designer` · `software-architect` | — nenhum item ainda; sai com a decisão que autoriza um (§0.4) |
| Planejamento | `workflow-planning` | `project-manager` · `software-architect` | abre e decompõe Epic → Story → Task (`template-epic.md` · `template-story.md` · `template-task.md`) |
| Implementação | `workflow-implementation` | `frontend-developer` · `backend-developer` | executa um Task por vez — o único nível que quem implementa lê (`WF-IMPL-03`) |
| Validação | `workflow-validation` | `qa-engineer` · `code-reviewer` · `devops-security` (quando o achado é de segurança) | revisa o PR (`template-pr.md`), com link de mão única de volta ao Task/Story |

Este mapeamento é o mesmo fluxograma de `agents/README.md`, seção "Como os agentes passam o
bastão" — aqui só como tabela, sem repetir o mermaid. Quando um agente novo for adicionado lá, esta tabela é
quem precisa de atualização, não o inverso.

A coluna de nível de board é o percurso "descobrir → tarefa" por inteiro, de ponta a ponta:
Pesquisa resolve a decisão (o `product-manager` chama isso de Discovery); Planejamento é onde
essa decisão primeiro vira item de board, se decompõe em Story e corta em Task, sempre pelos
cinco portões (§4.2); Implementação executa exatamente um Task por vez; Validação revisa o PR
que referencia esse Task. Nenhum pilar escreve em dois níveis de board ao mesmo tempo, e
nenhum nível nasce fora do pilar que o produz — abrir uma Task direto, sem Story e sem Epic,
é decomposição sem critério (`WF-PLAN-03`), do mesmo jeito que abrir um Epic sem decisão de
Pesquisa por trás é avanço sem decisão resolvida (`WF-CORE-03`).

---

## 4. Árvores de decisão

### 4.1 Pesquisa — classificar o escopo

```
A mudança altera o que o produto faz ou promete?
├── sim → escopo de PRODUTO → product-manager decide, product-designer desenha o fluxo
└── não
    A mudança altera onde uma responsabilidade mora, ou introduz um novo limite de serviço?
    ├── sim → escopo de ARQUITETURA → software-architect decide
    └── não → escopo de DETALHE DE IMPLEMENTAÇÃO → segue direto para workflow-planning
```

`WF-RES-05`. A classificação errada mais cara é tratar mudança de produto como detalhe —
ela chega pronta na Implementação sem ninguém ter decidido se o produto deveria mesmo mudar.

### 4.2 Planejamento — os portões

Uma unidade só está pronta para a Implementação depois de passar por todos:

1. **Portão de produto** — se a mudança altera `docs/specs/**` ou equivalente, existe
   comportamento aprovado por trás? Sem isso, volta para `workflow-research`.
2. **Portão de decomposição** — só divide em mais de uma unidade se cada uma tiver critério
   de aceite, evidência e dependência próprios (`WF-PLAN-03`). Dividir por conveniência de
   quem escreve, não por essas fronteiras, é fragmentação de custo.
3. **Portão de fronteira** — qual perfil (`frontend-developer`, `backend-developer`,
   `devops-security`...) é dono de cada unidade? "Fullstack" nunca é resposta (`WF-PLAN-05`).
4. **Portão de apetite** — quanto vale gastar aqui, decidido **antes** de perguntar quanto vai
   levar (`WF-PLAN-01`, Shape Up). Uma unidade que estoura o apetite para e volta à mesa de
   decisão — não estica o prazo em silêncio (`WF-PLAN-02`, circuit breaker).
5. **Portão de aceite** — critério de aceite escrito, não implícito (`WF-PLAN-04`).

### 4.3 Implementação — quando parar e devolver

| Situação encontrada durante a implementação | Volta para |
| --- | --- |
| comportamento de produto ausente ou contraditório | `workflow-research` |
| escopo, dependência ou evidência insuficientes na unidade | `workflow-planning` |
| defeito local, dentro do que esta própria unidade já decidiu | corrige aqui mesmo, registra evidência (`WF-IMPL-05`) — não é retorno |

`WF-IMPL-01`: implementação nunca reabre decisão de produto sozinha — mesmo quando o caminho
mais rápido pareceria decidir ali.

### 4.4 Validação — proporcionalidade da evidência

Evidência é uma **decisão sobre risco**, não sinônimo de "rodar tudo" (`WF-VAL-02`):

```
A mudança altera contrato público (API, schema, rota)?
├── sim → checks de contrato + revisão independente obrigatórios
└── não
    A mudança toca caminho de autenticação, autorização ou dado sensível?
    ├── sim → checks de segurança + revisão independente obrigatórios (rotear achado para devops-security)
    └── não → checks focados no que mudou bastam; declarar o que não foi coberto, não escondê-lo
```

---

## 5. O envelope de handoff

Toda skill deste pilar devolve o mesmo formato, para o próximo pilar (ou pessoa) não precisar
reconstruir o que já foi decidido:

```yaml
pilar: "pesquisa | planejamento | implementacao | validacao"
resultado: uma frase com o resultado
evidencia: [E1, E2]
decisoes: [D1]
lacunas: [G1]
proximo: "workflow-research | workflow-planning | workflow-implementation | workflow-validation | <agente>"
```

`proximo` é o campo de transição — é ele que aponta para onde o bastão vai, e é sempre
acompanhado de um artefato (`WF-CORE-01`), nunca só de uma frase de intenção.

---

## 6. Regras normativas

Convenção: `MUST`/`NEVER` são normativos. **†** marca decisão desta doc.

### `WF-CORE-*` — o que sobrevive a qualquer pilar

| ID | Regra |
| --- | --- |
| `WF-CORE-01` | Todo pilar **MUST** devolver um artefato citável (decisão, unidade de trabalho, código com evidência, ou relatório de achados). "Concluído" sem esse artefato **NEVER**. † |
| `WF-CORE-02` | Pilar é o momento do trabalho; papel é quem o exerce — os dois eixos **MUST** ficar ortogonais. Reduzir um agente a um único pilar ("`product-manager` só faz pesquisa") **NEVER** — o mesmo papel atravessa pilares diferentes em tarefas diferentes. † |
| `WF-CORE-03` | Nenhum pilar **MUST** avançar com uma decisão em aberto: um retorno explícito ao pilar anterior é mais barato do que a decisão errada seguir adiante (Boehm, curva de custo de mudança). |
| `WF-CORE-04` | Todo pilar de Implementação **MUST** terminar em Validação; **NEVER** termina em "pronto" sem prova. |
| `WF-CORE-05` | Decisão sem evidência **MUST** ser tratada como hipótese, não fato; fingir certeza **NEVER** — é opinião empacotada. |

### `WF-RES-*` — pesquisa

| ID | Regra |
| --- | --- |
| `WF-RES-01` | A pesquisa **MUST** separar fato, hipótese, decisão e lacuna antes de propor solução; misturar os quatro **NEVER** (Torres, opportunity solution tree). |
| `WF-RES-02` | Código existente **MUST** ser tratado como evidência do presente, **NEVER** como autoridade sobre a intenção — o comportamento atual pode ser o próprio defeito. |
| `WF-RES-03` | A pesquisa **MUST** resolver a menor decisão que destrava o Planejamento; relatório extenso sem decisão anexada **NEVER** conta como saída deste pilar. |
| `WF-RES-04` | Toda alegação sobre comportamento do usuário **MUST** vir com uma fonte (dado, entrevista, código, ticket); opinião do time sobre o usuário, sem essa fonte, **NEVER** substitui pesquisa (Cagan, risco de valor). |
| `WF-RES-05` | Uma mudança de comportamento de produto, de arquitetura, ou só de detalhe de implementação **MUST** ser classificada antes de seguir — a classificação decide para qual agente este pilar roteia. |

### `WF-PLAN-*` — planejamento

| ID | Regra |
| --- | --- |
| `WF-PLAN-01` | Toda unidade de trabalho **MUST** ter apetite decidido antes de estimativa de prazo — "quanto vale gastar" vem antes de "quanto vai levar" (Shape Up). |
| `WF-PLAN-02` | Unidade que estoura o apetite **MUST** parar e voltar à mesa de decisão; estender o prazo em silêncio **NEVER** (Shape Up, circuit breaker). |
| `WF-PLAN-03` | Decompor em múltiplas unidades **MUST** ter critério — cada unidade com aceite, evidência e dependência próprios; decompor sem esse critério **NEVER**, é fragmentação de custo. |
| `WF-PLAN-04` | Toda unidade **MUST** entrar em Implementação com critério de aceite escrito; "pronta para começar" sem isso **NEVER** é pronta (Definition of Ready). |
| `WF-PLAN-05` | A fronteira de camada/perfil de cada unidade **MUST** ser nomeada no Planejamento; "fullstack" como perfil **NEVER** — esconde a fronteira em vez de decidi-la. |

### `WF-IMPL-*` — implementação

| ID | Regra |
| --- | --- |
| `WF-IMPL-01` | A Implementação **NEVER** reabre uma decisão de produto já registrada no Planejamento; divergência encontrada aqui **MUST** voltar para Pesquisa, não ser decidida ad-hoc. |
| `WF-IMPL-02` | Teste focado **MUST** acompanhar a mudança, não ser etapa posterior; implementar tudo e "testar depois" **NEVER** (XP, test-first). |
| `WF-IMPL-03` | O escopo da mudança **MUST** ser o menor que resolve a unidade decidida; resolver problema adjacente não decidido nesta unidade **NEVER**, mesmo que pareça eficiente. |
| `WF-IMPL-04` | Contrato explícito (tipo, schema, fronteira de tenant/auth) **MUST** ser preservado durante a implementação; mudar contrato implícito e "ajustar depois" **NEVER**. |
| `WF-IMPL-05` | Defeito local encontrado durante a própria implementação **MUST** ser corrigido ali e registrado como evidência, sem abrir um ciclo de Validação separado só para ele. |

### `WF-VAL-*` — validação

| ID | Regra |
| --- | --- |
| `WF-VAL-01` | Quem implementa **NEVER** aprova a própria mudança; a Validação **MUST** inspecionar em contexto independente do autor (Google SWE Practices; ver `CC-SES-07`). |
| `WF-VAL-02` | A evidência exigida **MUST** ser proporcional ao risco da mudança; "rodar a suíte inteira" como resposta padrão **NEVER** — é decisão de evidência preguiçosa, não rigorosa. |
| `WF-VAL-03` | Verificação técnica ("construímos certo") e validação de negócio ("é a coisa certa") **MUST** ser etapas separadas; a segunda **NEVER** bloqueia o fechamento técnico da primeira (ver [Teste de Software](teste-de-software.md) §0). |
| `WF-VAL-04` | Toda falha de Validação **MUST** ser roteada para o pilar de origem do problema — Pesquisa se é lacuna de decisão, Planejamento se é lacuna de escopo/evidência, Implementação se é defeito de código; corrigir no pilar errado **NEVER**. |
| `WF-VAL-05` | Métrica de entrega (lead time, taxa de falha de mudança) **MUST** vir de dado medido, **NEVER** de percepção (Forsgren/Humble/Kim, *Accelerate* — métricas DORA). |

### Contagem

**25 regras** em cinco famílias, um único arquivo — sem satélite nesta versão.

| Família | Regras |
| --- | --- |
| `WF-CORE-*` | 5 |
| `WF-RES-*` | 5 |
| `WF-PLAN-*` | 5 |
| `WF-IMPL-*` | 5 |
| `WF-VAL-*` | 5 |

---

## 7. Contrato de skill

### O que carregar

```
SEMPRE, ao decidir em que pilar uma tarefa ambígua está:
          Fluxo de Entrega - Quatro Pilares.md § 0, § 2, § 3

AO CLASSIFICAR o escopo de uma pesquisa:
          § 4.1 + WF-RES-*

AO PASSAR pelos portões de planejamento:
          § 4.2 + WF-PLAN-*

AO DECIDIR se a implementação para e devolve:
          § 4.3 + WF-IMPL-*

AO DECIDIR quanta evidência a validação exige:
          § 4.4 + WF-VAL-*

NUNCA:    esta estrutura inteira para uma tarefa cujo pilar já é óbvio
          (ex.: "corrija este typo" não precisa de classificação de pilar)
```

### Como citar

> `WF-CORE-03` — a tarefa pede para implementar um novo limite de desconto, mas ninguém
> decidiu ainda se acima de 50% precisa de aprovação manual. Isso é uma decisão de produto em
> aberto chegando disfarçada de tarefa de implementação; a resposta correta é devolver para
> `workflow-research`, não escolher um valor e seguir.
> Ver [Fluxo de Entrega — Quatro Pilares](fluxo-de-entrega-quatro-pilares.md) § 4.1.

### Invariantes que a skill deve fazer valer

1. **Pilar antes de agente.** Nunca escolher `frontend-developer` ou `backend-developer`
   antes de confirmar que a tarefa já passou pelos pilares anteriores.
2. **Retorno é mais barato que avanço errado.** Voltar um pilar não é falha do processo —
   é o processo funcionando (`WF-CORE-03`).
3. **Não reabrir decisão de produto na implementação** (`WF-IMPL-01`) — sinalizar e devolver,
   nunca decidir ad-hoc no meio do código.
4. **Evidência proporcional, nunca "a suíte inteira" por padrão** (`WF-VAL-02`).
5. **Verificação técnica não espera validação de negócio, nem o contrário** (`WF-VAL-03`) —
   as duas são reais, mas não se bloqueiam.
6. **Seguir a ponte.** Quando a §8 indicar que a decisão pertence a uma skill ou agente já
   existente, seguir em vez de reinventar o procedimento aqui.

### Recortes para skills novas

| Skill | Carrega | Fonte declarada |
| --- | --- | --- |
| "que pilar é esta tarefa ambígua" | § 0 + § 2 + § 3 | este hub |
| "classificar escopo de uma pesquisa" | § 4.1 + `WF-RES-*` | este hub |
| "passar pelos portões de planejamento" | § 4.2 + `WF-PLAN-*` | este hub |
| "decidir se a implementação para e devolve" | § 4.3 + `WF-IMPL-*` | este hub |
| "decidir quanta evidência a validação exige" | § 4.4 + `WF-VAL-*` | este hub |

---

## 8. Pontes com o stack

| Decisão | O que **não** fazer | A ponte |
| --- | --- | --- |
| Decidir se uma mudança é de produto, arquitetura ou detalhe | assumir e seguir para o código | `product-manager` / `software-architect` — §4.1 |
| Abrir Epic/Story/Task no rastreador | criar o item assim que a ideia aparece, antes da decisão | `workflow-research` decide o escopo primeiro (§4.1) — o Board só abre no Planejamento, com a decisão já resolvida (§0.4, §3) |
| Decidir em que nível um teste da unidade entra | deixar para a hora de escrever | `test-design`, existente — não é reimplementado aqui |
| Revisar uma mudança já implementada | o próprio autor aprovar | `code-reviewer`, em contexto fresco (`WF-VAL-01`, `CC-SES-07`) |
| Decidir o contrato HTTP de uma rota nova | inventar status/shape no handler | `http-contract`, existente |
| Achado de autenticação, cookie ou segredo durante a validação | corrigir e seguir sem rotear | `devops-security` (`WF-VAL-04`) |
| Cronograma, risco ou "isso cabe no escopo" durante o planejamento | o time de implementação decidir sozinho | `project-manager` |
| Fronteira entre camadas ou serviços durante o planejamento | decidir dentro do código, sem registrar | `software-architect`, decisão registrada |

**A ponte mais importante desta nota:** o pilar nunca substitui a skill ou o agente que já
resolve a pergunta — ele só decide **quando** chamar cada um. Um `workflow-*` que responde a
pergunta de arquitetura em vez de rotear para `software-architect` está duplicando regra que
já existe em outro lugar, e duplicação de regra apodrece no dia seguinte, igual a qualquer
outra camada deste projeto.

---

## Fontes consultadas

- Barry Boehm, *Software Engineering Economics* — curva de custo de mudança; base da origem
  histórica da distinção verificação × validação.
- Marty Cagan, *Inspired: How to Create Tech Products Customers Love* — riscos de valor,
  usabilidade, viabilidade e factibilidade na descoberta de produto.
- Teresa Torres, *Continuous Discovery Habits* — árvore de oportunidade-solução, pesquisa
  contínua em vez de projeto único.
- Ryan Singer / Basecamp, *Shape Up: Stop Running in Circles* — apetite, mesa de aposta,
  circuit breaker.
- Kent Beck, *Extreme Programming Explained* — teste antes da implementação, lotes pequenos.
- Winters, Manshreck, Wright, *Software Engineering at Google* — cultura de revisão de código
  por par independente (já citado em `TS-*`).
- Forsgren, Humble, Kim, *Accelerate* — as quatro métricas DORA de performance de entrega.
- **Precedente interno, não autoridade acadêmica:** lemind (`studio-risine`), ADR 114 — "o
  workflow de agentes tem quatro pilares" (`docs/decisions/114-four-pillar-agent-workflow.md`)
  e `docs/engineering/agent-workflow.md` — a mesma forma de quatro pilares, implementada e em
  produção num projeto real; a distinção pilar × perfil desta nota vem diretamente de lá.

**O que não foi possível verificar por fonte primária nesta versão:** citação de página ou
edição específica de cada livro acima — as regras `WF-*` são uma síntese própria dos conceitos
centrais de cada obra, não transcrição literal. Marcado com † nas regras onde a síntese é a
contribuição principal deste projeto, sem paralelo direto numa única fonte.

---

## Relacionados

- `agents/README.md` — os onze papéis; "How agents hand off" é o
  fluxograma que esta nota formaliza
- [Teste de Software](teste-de-software.md) — §0, a distinção verificação × validação que o
  pilar de Validação reaproveita
- `skills/workflow/` — as quatro skills que implementam este contrato
- [Claude Code - Sessão e Verificação](claude-code-sessao-e-verificacao.md) — `CC-SES-07`,
  revisão em contexto fresco
- [Claude Code - Paralelismo e Escala](claude-code-paralelismo-e-escala.md) — subagentes e
  como o bastão passa em Claude Code especificamente
