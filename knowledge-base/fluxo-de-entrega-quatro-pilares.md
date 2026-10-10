---
titulo: Fluxo de Entrega — Quatro Pilares
tags:
  - workflow
  - delivery
  - agent-context
  - reference
source: "Barry Boehm, Software Engineering Economics (curva de custo de mudança, origem de verificação×validação); Marty Cagan, Inspired: How to Create Tech Products Customers Love; Teresa Torres, Continuous Discovery Habits; Ryan Singer/Basecamp, Shape Up: Stop Running in Circles; Kent Beck, Extreme Programming Explained; Winters/Manshreck/Wright, Software Engineering at Google (cultura de code review — já citado em TS-*); Forsgren/Humble/Kim, Accelerate (métricas DORA); Glenford Myers, The Art of Software Testing (partição de equivalência e análise de valor-limite); Matt Wynne, Introducing Example Mapping (Cucumber); precedente interno: lemind, ADR 114 — \"o workflow de agentes tem quatro pilares\" (implementação observada em produção, não autoridade acadêmica)"
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

Fontes consultadas em **2026-09-23**; Myers e Wynne, acrescentados com a varredura de bordas
(§4.1), em **2026-10-10**. Ver [Fontes consultadas](#fontes-consultadas).

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
executável), definidos em `workflow-spec/references/template-{epic,story,task}.md`. A
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
| 1 | **Pesquisa** | o problema, o comportamento esperado ou uma decisão duradoura não está claro | decisão mínima resolvida, com as bordas varridas (§4.1); evidência, riscos, fontes; lacunas com quem decide e onde fecham (§5) |
| 2 | **Planejamento** | a decisão foi aceita mas o trabalho ainda não é executável | unidade(s) de trabalho delimitadas, dependências, perfil, critério de aceite, plano de evidência com os tipos de teste |
| 3 | **Implementação** | a unidade está pronta e o comportamento já foi decidido | código ou nota alterada, teste focado, evidência de implementação |
| 4 | **Validação** | existe uma mudança ou entrega e ela precisa de prova | checks focados e de repositório, achados de revisão, resultado claro |

Nenhuma tarefa pula pilar (`WF-CORE-03`): pode **voltar** um pilar quando descobre uma lacuna,
mas nunca decide "vou resolver isso na implementação mesmo" quando a lacuna é de pesquisa.
Toda lacuna diz quem a decide e em que pilar fecha (§5, `WF-CORE-09`), e esse pilar nunca é a
Implementação.

---

## 3. Onde cada pilar roteia

| Pilar | Skill | Agente(s) que o exercem, hoje | Nível de board |
| --- | --- | --- | --- |
| Pesquisa | `workflow-research` | `product-manager` · `product-designer` · `software-architect`; levantamento de fatos no código: `repo-explorer` | — nenhum item ainda; sai com a decisão que autoriza um (§0.4) |
| Planejamento | `workflow-planning` | `project-manager` · `software-architect` | abre e decompõe Epic → Story → Task (`template-epic.md` · `template-story.md` · `template-task.md`) |
| Implementação | `workflow-implementation` | `frontend-developer` · `backend-developer` | executa um Task por vez — o único nível que quem implementa lê (`WF-IMPL-03`) |
| Validação | `workflow-validation` | `qa-engineer` · `code-reviewer` · `devops-security` (quando o achado é de segurança) | revisa o PR (`template-pr.md`), com link de mão única de volta ao Task/Story |

A coluna de agentes é também a lista fechada de quem pode receber um pilar delegado
(`WF-CORE-06`): cada um declara `modelo` e `esforco` no próprio frontmatter, e é isso que
impede o pilar de rodar no modelo da sessão — desde que o agente seja chamado como subagente.
Uma sessão nova não adota agente nenhum: herda o modelo de quem a abriu, e o papel só chega
nela se ela o chamar (§3.1). `repo-operator` não recebe pilar: recebe as operações mecânicas
de qualquer um deles (§3.1, `WF-CORE-08`).

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

### 3.1 Modelo por ponto do fluxo

O tier segue a operação, não o pilar. Dentro de um mesmo pilar há **decisão**, que fica no
tier do agente dono, e **operação mecânica**, cujo conteúdo um artefato já decidiu e que vai
para o tier mais barato (`WF-CORE-08`). `repo-operator` atravessa os quatro pilares fazendo a
segunda; o mapa de tier para modelo de cada provedor está em `agents/README.md`, "Model and
effort per role".

| Pilar | Ponto | Quem executa | `modelo` · `esforco` | Por quê |
| --- | --- | --- | --- | --- |
| Pesquisa | ler o código e levantar fatos | `repo-explorer` | rapido · baixo | todo fato traz o `arquivo:linha` que o prova |
| Pesquisa | classificar o escopo e decidir | `product-manager` · `software-architect` | alto · alto | ambíguo, poucos tokens, nada confere depois |
| Pesquisa | escrever `requirements.md` | `product-manager`, via `workflow-spec` | alto · alto | o arquivo é a própria decisão |
| Planejamento | `design.md` e ADRs | `software-architect` | alto · alto | a fronteira decide o custo de tudo que vem depois, inclusive dos testes (§4.2) |
| Planejamento | `user-experience.md` | `product-designer` | medio · alto | estruturado, mas aberto |
| Planejamento | portões, plano de `tasks/` e o texto dos itens de board | `project-manager` | medio · medio | guiado por template |
| Planejamento | publicar no board o texto que o plano já traz | `repo-operator` | rapido · baixo | cópia literal; pede a resposta do dono |
| Implementação | código e teste focado | `frontend-developer` · `backend-developer` | medio · medio | mais tokens; a Validação pega o erro |
| Implementação | commit do próprio diff | o mesmo implementador | medio · medio | o diff já está no contexto dele; reler em outro agente custa mais |
| Validação | rodar os checks do plano e reportar | `repo-operator` | rapido · baixo | saída longa; o resultado é o código de saída |
| Validação | revisar o diff | `code-reviewer` | medio · alto | é a verificação; ninguém a revisa |
| Validação | diagnosticar um check que falhou | `qa-engineer` | medio · medio | julgamento sobre a suíte |
| Validação | achado de segurança | `devops-security` | alto · alto | um achado perdido custa mais que os tokens |
| Validação | corpo do PR, push, abrir o PR | `repo-operator` | rapido · baixo | template preenchido do envelope; push e PR pedem a resposta do dono |
| qualquer | copiar, mover, renomear, organizar pasta | `repo-operator`, ou quem já está com o comando pronto | rapido · baixo | a lista ou o layout já foi decidido |
| qualquer | apagar, sobrescrever, build e release | `repo-operator` | rapido · baixo | apagar, sobrescrever e publicar pedem a resposta do dono |
| qualquer | orquestrar: envelopes, rotear, falar com o dono | a sessão principal | escolha da pessoa | um plugin não fixa o modelo da sessão; a recomendação está em `agents/README.md` |
| qualquer | abrir uma sessão nova para uma unidade | a sessão que orquestra | medio · medio, passados na abertura | a sessão nova herda o modelo de quem abre e não adota o dono; ela orquestra a unidade, e o dono roda dentro dela como subagente, no tier dele (`CC-PAR-05`) |

**Quando delegar uma operação mecânica.** Um subagente começa com prompt de sistema, ferramentas
e cache próprios, e a resposta dele volta para quem chamou. Para um comando só, isso custa mais
do que rodar o comando:

```
A operação exige decidir algo que nenhum artefato decidiu?
├── sim → não é mecânica: volta ao dono da decisão
└── não
    O conteúdo de que ela precisa já está no contexto de um agente medio ou rapido em trabalho?
    ├── sim → esse agente executa (o implementador faz o commit do próprio diff)
    └── não
        É um único comando já conhecido, sem nada a ler antes?
        ├── sim → roda onde está, inclusive na sessão que orquestra
        └── não → repo-operator (rapido · baixo)
```

**Quando o paralelismo é por sessão.** Abrir uma sessão por unidade (o `start_session` do app
desktop) troca o subagente por algo que a pessoa vê e com que conversa, mas o tier não vem
junto ([`CC-PAR-05`](claude-code-paralelismo-e-escala.md)). Quem abre:

1. passa `modelo` e `esforco` explícitos, no tier de orquestração (medio · medio; o valor por
   provedor está em `agents/README.md`), numa abertura `fresh` — um fork herda o modelo;
2. escreve o brief para a sessão **chamar** o dono como subagente e cuidar só do envelope, da
   Validação e do PR — "rode como `backend-developer`" faz a sessão escrever o código no
   modelo que herdou, sem o corpo do agente.

Uma sessão só abre outra no mesmo tier ou abaixo; quando o dono é `alto`, quem sobe é o
subagente, pelo frontmatter dele.

A sessão que orquestra é o maior gasto do fluxo: o contexto dela é relido em todo turno até o
fim (`WF-CORE-07`). Ler um diff, um template ou uma saída de teste ali, no tier mais caro, é
exatamente o que `WF-CORE-08` proíbe.

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

#### Varrer as bordas da decisão

Classificar o escopo diz **quem** decide; a varredura diz se a decisão está **completa**. A
pergunta que para uma unidade no meio do código raramente é a regra principal — é a borda
dela: o valor exatamente no limite, o prazo contado a partir de quando, a lista vazia, o
clique repetido. Antes do handoff, quem decide passa cada regra e cada cenário de aceite da
decisão pelas sete categorias (`WF-RES-06`):

| Categoria | A pergunta que costuma escapar |
| --- | --- |
| limite | o valor exatamente no limite entra ou não (`>` ou `>=`)? qual o mínimo, o máximo, o zero, o negativo, o arredondamento? |
| tempo | conta a partir de quando? expira quando, em que fuso? e se os eventos chegarem fora de ordem? |
| vazio | e a lista vazia, o campo opcional ausente, o primeiro uso, sem nada cadastrado ainda? |
| repetição | e a mesma ação duas vezes (duplo clique, retry)? e duas pessoas ao mesmo tempo? |
| permissão | quem pode — que papel, que dono do recurso, que tenant, que visitante sem sessão? |
| falha | e se uma dependência cair, ou a operação parar no meio? o que a pessoa vê, o que se desfaz? |
| o que já existe | e o dado gravado antes da mudança, o cliente na versão anterior, o comportamento atual de que alguém depende? |

Cada borda que se aplica sai da Pesquisa com um de três destinos, e toda lacuna leva quem a
decide e onde fecha (§5, `WF-CORE-09`). Categoria que não se aplica não deixa rastro.

| Destino | Escopo de produto | Arquitetura e detalhe |
| --- | --- | --- |
| **respondida**, com fonte | cenário de aceite na story do `requirements.md` | linha em `decisoes`, que o Planejamento leva ao critério de aceite da unidade |
| **fora** | não-objetivo no `requirements.md` | linha em `decisoes`: "fora deste incremento: …" |
| **lacuna** | "Open gaps" do `requirements.md`; no envelope, quando fecha no Planejamento | no envelope |

A varredura **aprofunda** a decisão, nunca a **alarga** (`WF-RES-03`): uma borda que pede
decisão nova, fora do que foi pedido, vira não-objetivo ou lacuna — não pesquisa extra. Ela
também testa a classificação acima: num escopo de detalhe, uma borda que se aplica e cuja
resposta não está escrita em lugar nenhum mostra que o escopo era de produto (`WF-RES-05`).

### 4.2 Planejamento — os portões

Uma unidade só está pronta para a Implementação depois de passar por todos:

1. **Portão de produto** — se a mudança altera `.specs/**` ou equivalente, existe
   comportamento aprovado por trás (`requirements.md` em `Approved`, `design.md` em
   `Accepted`, ou um ADR)? Sem isso, volta para `workflow-research`.
2. **Portão de decomposição** — só divide em mais de uma unidade se cada uma tiver critério
   de aceite, evidência e dependência próprios (`WF-PLAN-03`). Dividir por conveniência de
   quem escreve, não por essas fronteiras, é fragmentação de custo.
3. **Portão de fronteira** — qual perfil (`frontend-developer`, `backend-developer`,
   `devops-security`...) é dono de cada unidade? "Fullstack" nunca é resposta (`WF-PLAN-05`).
4. **Portão de apetite** — quanto vale gastar aqui, decidido **antes** de perguntar quanto vai
   levar (`WF-PLAN-01`, Shape Up). Uma unidade que estoura o apetite para e volta à mesa de
   decisão — não estica o prazo em silêncio (`WF-PLAN-02`, circuit breaker).
5. **Portão de aceite** — critério de aceite escrito, não implícito (`WF-PLAN-04`), com uma
   linha para cada borda que a Pesquisa respondeu para esta unidade (`WF-RES-06`). Uma lacuna
   aberta da qual a unidade dependa é uma linha que ninguém escreveu ainda: a unidade espera a
   resposta (`WF-CORE-09`).

#### Plano de evidência: que teste a Validação vai rodar, e quanto ele custa

Passados os portões, cada unidade nomeia os tipos de teste que vão prová-la, e a Validação
herda essa lista em vez de inventar outra (`WF-PLAN-06`). O nível segue
[Teste de Software](teste-de-software.md) §4.1: cada asserção na camada mais barata que ainda
pega o defeito (`TS-CORE-02`). Para um agente, o custo tem duas moedas, e as duas se repetem a
cada rodada de correção:

| Tipo | Pega | Tempo de execução | Tokens do agente (escrever, rodar, ler a saída, diagnosticar) | Precisa de pé |
| --- | --- | --- | --- | --- |
| estático (tipo, lint) | erro de tipo, import, regra de lint | baixo | baixo: nada a escrever, saída curta | nada |
| unidade | regra, cálculo, parse, invariante de domínio | baixo | baixo | nada |
| contrato | a forma do que atravessa uma fronteira | baixo | baixo a médio: um schema, ou um `curl` por rota | o servidor, no caso do `curl` |
| integração | peças minhas conversando com dependência real | médio | médio: preparo de dados, saída maior | banco ou serviço local |
| componente (story com `play`) | estado visual e interação de um componente | médio | médio: story, `play` e render | Storybook |
| E2E | a jornada crítica de ponta a ponta | alto | alto: app e navegador de pé, sessão, trace e DOM lidos a cada falha, reexecução por instabilidade | app, navegador e sessão |
| manual | o que nenhum check automatiza | — | — (é o tempo de uma pessoa) | pessoa, data e ambiente registrados |

Os valores são ordem relativa, não medição: cada projeto mede os seus. O que a tabela fixa é a
direção. Uma asserção que sobe de unidade para E2E troca segundos por minutos e uma saída curta
por um trace inteiro lido pelo agente, em toda rodada.

**Quem fixa esse custo é a fronteira, antes do teste.** Ao escolher onde uma regra mora, o
`software-architect` escolhe também o teste mais barato capaz de prová-la: uma regra no backend
se prova com um teste de unidade e um `curl`; a mesma regra espalhada pela interface só se
prova com E2E. Por isso cada invariante verificável de `design.md` e de um ADR nomeia o tipo de
teste que o prova, e um invariante que só um E2E prova diz por quê.

### 4.3 Implementação — quando parar e devolver

**Antes da primeira linha, as perguntas de quem implementa** (`WF-IMPL-06`). O agente dono da
unidade lê a Task e o código que ela toca e lista o que precisaria saber para escrevê-la,
passando a unidade pelas sete categorias de borda da §4.1. Cada pergunta sai de um de três
jeitos: respondida por um artefato aceito, que ela cita; decidida ali mesmo, quando a resposta
fica dentro do que a unidade já decidiu (um nome, a estrutura local, a API de uma biblioteca);
ou devolvida pela tabela abaixo, antes de qualquer código, como lacuna com quem decide e onde
fecha (§5, `WF-CORE-09`). A lista fica no contexto de quem implementa; ao orquestrador chegam
só as lacunas (`WF-CORE-07`).

A tabela vale antes e durante o código. Antes, o retorno custa só o retorno; durante, custa
também o código já escrito sobre uma resposta inventada.

| Situação encontrada antes ou durante a implementação | Volta para |
| --- | --- |
| comportamento de produto ausente ou contraditório | `workflow-research` (`fecha-em: pesquisa`) |
| escopo, dependência ou evidência insuficientes na unidade | `workflow-planning` (`fecha-em: planejamento`) |
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

A Validação parte dos tipos de teste que o plano nomeou (`WF-PLAN-06`). Um tipo mais caro que o
plano não previu só entra com a frase do que ele pega e os mais baratos não; sem essa frase, a
lacuna é do plano e volta ao Planejamento (`WF-VAL-04`).

---

## 5. O envelope de handoff

Toda skill deste pilar devolve o mesmo formato, para o próximo pilar (ou pessoa) não precisar
reconstruir o que já foi decidido:

```yaml
pilar: "pesquisa | planejamento | implementacao | validacao"
resultado: uma frase com o resultado
artefato: "<arquivo em .specs/, item de board, commit ou PR onde a saída completa está>"
evidencia: [E1, E2]
decisoes: [D1]
lacunas:
  - pergunta: G1, em uma frase
    decide: "<agente da §3 | dono>"
    fecha-em: "pesquisa | planejamento"
proximo: "workflow-research | workflow-planning | workflow-implementation | workflow-validation | <agente>"
```

`proximo` é o campo de transição — é ele que aponta para onde o bastão vai, e é sempre
acompanhado de um artefato (`WF-CORE-01`), nunca só de uma frase de intenção.

`artefato` é a referência, não o conteúdo. A saída completa do pilar mora fora da conversa;
quem orquestra guarda só o envelope, que cabe em 30 linhas (`WF-CORE-07`). Um relatório
inteiro devolvido à conversa principal é relido e cobrado em todo turno seguinte, de todos
os pilares que vierem depois.

### Lacunas: quem decide e onde fecham

Lacuna é a pergunta cuja resposta pertence a outro dono, não a quem está com o bastão; o que
quem implementa decide dentro da própria unidade não é lacuna. Cada item de `lacunas` leva
dois campos além da pergunta (`WF-CORE-09`):

- `decide` — o agente da §3 dono daquela decisão (`product-manager`, `product-designer`,
  `software-architect`, `project-manager`), ou `dono`, quando só a pessoa pode responder.
- `fecha-em` — o último pilar em que ela ainda pode estar aberta:

| `fecha-em` | Quando | O que ela bloqueia |
| --- | --- | --- |
| `pesquisa` | a resposta muda o que o produto faz ou promete, ou o que entra no incremento | o Planejamento inteiro: ele não começa |
| `planejamento` | a resposta só muda como a unidade é desenhada, dividida ou provada — fluxo e estados de tela, fronteira e contrato, dependência e ordem | só as unidades que dependem dela: nenhuma passa no portão de aceite (§4.2) |

`implementacao` e `validacao` nunca são valores de `fecha-em`: lacuna de decisão não fecha no
código (`WF-CORE-03`, `WF-IMPL-01`). O pilar que encontra uma lacuna pelo caminho — a
Implementação pela §4.3, a Validação pela `WF-VAL-04` — a devolve já com os dois campos.

O pilar de `fecha-em` não entrega adiante o que depende da lacuna antes da resposta: a
Pesquisa não entrega nada com uma lacuna `pesquisa` aberta; o Planejamento não entrega a
unidade que depende de uma lacuna aberta. Quem responde é quem `decide` nomeia — um agente da
§3, começado na hora (`WF-CORE-06`), ou o dono, perguntado numa frase.

O arquivo que espera a resposta do dono é a lacuna mais comum:
`pergunta: "awaiting owner approval: <caminho>"`, `decide: dono`, e `fecha-em` o pilar que
escreve o arquivo — `pesquisa` para o `requirements.md`, `planejamento` para os demais
(`WF-SPEC-04`).

**Sem resposta a tempo, a única saída é virar premissa.** A lacuna só avança se o dono a
aceitar explicitamente na conversa como premissa, com o que a invalidaria (`WF-SPEC-06`). Ela
sai de `lacunas`, entra em `decisoes` e fica escrita no artefato: em "Constraints and
assumptions" do `requirements.md`, ou no plano em `tasks/`. Uma premissa invalidada durante a
Implementação é a primeira linha da tabela da §4.3: volta para a Pesquisa.

### Onde o artefato mora: `.specs/`

A saída de Pesquisa e de Planejamento é gravada no projeto, em `.specs/`, e o `artefato` do
envelope aponta o caminho (`WF-SPEC-01`):

```
.specs/
├── adr/
│   └── NNNN-<slug>.md            software-architect · nunca editado, só substituído
└── <capability>/
    ├── requirements.md           Pesquisa · product-manager (o PRD da capability)
    ├── design.md                 Planejamento · software-architect (RFC ou design doc)
    ├── user-experience.md        Planejamento · product-designer (UX, UI, usabilidade, acessibilidade)
    └── tasks/
        └── NNNN-<slug>.md        Planejamento · project-manager (o plano de um incremento)
```

**Uma pasta por capability, não por entrega.** A capability é permanente, como o Epic que a
representa (§0.4): a segunda entrega na mesma capability não abre outra pasta. O slug da pasta
é o campo `capability` do Epic, quando ele existe; numa capability ainda sem Epic, a Pesquisa
propõe o slug — o `product-manager`, quando o escopo é produto, quem orquestra nos demais — o
dono o confirma, e o Epic nasce depois com esse valor. Dois efeitos (`WF-SPEC-08`):

- `requirements.md`, `design.md` e `user-experience.md` são da capability e vivem enquanto ela
  vive. Texto aprovado não é reescrito: a mudança volta à Pesquisa e entra como **emenda
  datada** no fim do arquivo, que nasce `Draft` e só vale depois da resposta do dono.
- O plano é do incremento: cada um ganha `tasks/NNNN-<slug>.md`, numerado em sequência como os
  ADRs. Quem implementa lê só o plano atual, não o histórico da capability.

O escopo classificado na §4.1 decide quais arquivos nascem ou recebem emenda (`WF-SPEC-03`):

| Escopo | Arquivos |
| --- | --- |
| detalhe de implementação | um plano em `tasks/` |
| arquitetura | `design.md` ou emenda nele; um ADR por decisão que sobrevive ao incremento; um plano em `tasks/` |
| produto | `requirements.md` ou emenda nele; `user-experience.md` quando há interface; `design.md` quando há fronteira ou contrato; um plano em `tasks/` |

O que cada documento de decisão é, e quando congela, está em
[Documentos de Decisão — PRD, RFC e ADR](documentos-de-decisao-prd-rfc-adr.md). Cada arquivo tem
um dono e cita os outros por link (`WF-SPEC-02`). Uma execução só de especificação para depois
do plano em `tasks/` (`WF-SPEC-05`).

**Quem escreve, em uma linha.** O pilar decide *quando* um arquivo é necessário; o escopo
decide *qual*; o agente dono decide *o que ele diz*; `workflow-spec` decide *forma, lugar,
status e revisão*. Todo arquivo nasce `Draft` (ADR nasce `Proposed`) e só muda de status pela
resposta explícita do dono na conversa (`WF-SPEC-06`). Quais documentos o projeto mantém é
decisão do dono, registrada uma vez na seção `## Specs` do `AGENTS.md` do projeto, com
permissão, ou em `.specs/README.md`, e lida antes de escrever (`WF-SPEC-07`); o plano em
`tasks/` nunca é desligado, e documento desligado deixa sua decisão em uma linha no plano.

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
| `WF-CORE-06` | Todo pilar delegado **MUST** ir a um agente nomeado da tabela da §3, chamado como subagente, que carrega modelo e esforço próprios; se o pilar roda numa sessão nova, ela **MUST** abrir com `modelo` e `esforco` explícitos e chamar esse agente como subagente (§3.1, `CC-PAR-05`). Delegar a um agente genérico (o `general-purpose` do Claude Code, o spawn sem agente do Codex), ou a uma sessão que só interpreta o papel ("como `backend-developer`" no brief), **NEVER** — os dois herdam o modelo de quem os abriu, não o do dono, e nenhum carrega o corpo do agente. † |
| `WF-CORE-07` | Quem orquestra os pilares **MUST** guardar só o envelope da §5, com a saída completa referenciada em `artefato`; ler código, o hub inteiro ou o relatório completo de um pilar na conversa principal **NEVER** — esse contexto é relido em todo turno até o fim do fluxo. † |
| `WF-CORE-08` | Operação mecânica — cujo conteúdo um artefato já decidiu (diff, envelope, template, plano) — **MUST** rodar no agente que já tem esse conteúdo no contexto ou, se for preciso lê-lo, no `repo-operator`, de tier `rapido` (§3.1); ler diff, template ou saída de teste no tier mais caro da sessão para executá-la, ou deixar quem executa decidir o conteúdo, **NEVER**. † |
| `WF-CORE-09` | Toda lacuna **MUST** sair no envelope com quem a decide (`decide`) e o último pilar em que pode estar aberta (`fecha-em`: `pesquisa` ou `planejamento`, §5); lacuna sem esses campos, ou deixada para a Implementação ou a Validação, **NEVER** — sem resposta a tempo, ela só avança como premissa que o dono aceitou, com o que a invalidaria (Wynne, os cartões vermelhos do Example Mapping). † |

### `WF-RES-*` — pesquisa

| ID | Regra |
| --- | --- |
| `WF-RES-01` | A pesquisa **MUST** separar fato, hipótese, decisão e lacuna antes de propor solução; misturar os quatro **NEVER** (Torres, opportunity solution tree). |
| `WF-RES-02` | Código existente **MUST** ser tratado como evidência do presente, **NEVER** como autoridade sobre a intenção — o comportamento atual pode ser o próprio defeito. |
| `WF-RES-03` | A pesquisa **MUST** resolver a menor decisão que destrava o Planejamento; relatório extenso sem decisão anexada **NEVER** conta como saída deste pilar. |
| `WF-RES-04` | Toda alegação sobre comportamento do usuário **MUST** vir com uma fonte (dado, entrevista, código, ticket); opinião do time sobre o usuário, sem essa fonte, **NEVER** substitui pesquisa (Cagan, risco de valor). |
| `WF-RES-05` | Uma mudança de comportamento de produto, de arquitetura, ou só de detalhe de implementação **MUST** ser classificada antes de seguir — a classificação decide para qual agente este pilar roteia. |
| `WF-RES-06` | Antes do handoff, cada regra e cada cenário de aceite da decisão **MUST** passar pelas sete categorias de borda da §4.1 — limite, tempo, vazio, repetição, permissão, falha, o que já existe —, e cada borda que se aplica sai respondida com fonte, fora como não-objetivo, ou como lacuna (`WF-CORE-09`); decisão com borda aplicável sem destino **NEVER** conta como resolvida, e a varredura **NEVER** alarga a decisão (`WF-RES-03`) (Myers, análise de valor-limite; Wynne, Example Mapping). |

### `WF-PLAN-*` — planejamento

| ID | Regra |
| --- | --- |
| `WF-PLAN-01` | Toda unidade de trabalho **MUST** ter apetite decidido antes de estimativa de prazo — "quanto vale gastar" vem antes de "quanto vai levar" (Shape Up). |
| `WF-PLAN-02` | Unidade que estoura o apetite **MUST** parar e voltar à mesa de decisão; estender o prazo em silêncio **NEVER** (Shape Up, circuit breaker). |
| `WF-PLAN-03` | Decompor em múltiplas unidades **MUST** ter critério — cada unidade com aceite, evidência e dependência próprios; decompor sem esse critério **NEVER**, é fragmentação de custo. |
| `WF-PLAN-04` | Toda unidade **MUST** entrar em Implementação com critério de aceite escrito; "pronta para começar" sem isso **NEVER** é pronta (Definition of Ready). |
| `WF-PLAN-05` | A fronteira de camada/perfil de cada unidade **MUST** ser nomeada no Planejamento; "fullstack" como perfil **NEVER** — esconde a fronteira em vez de decidi-la. |
| `WF-PLAN-06` | O plano de evidência de cada unidade **MUST** nomear os tipos de teste que a Validação vai rodar, cada um no nível mais barato que pega o defeito (`TS-CORE-02`), e cada invariante de `design.md` ou ADR **MUST** nomear o tipo que o prova; integração ou E2E sem a frase do que só eles pegam **NEVER** — o custo em tempo e tokens se repete a cada rodada (§4.2). † |

### `WF-IMPL-*` — implementação

| ID | Regra |
| --- | --- |
| `WF-IMPL-01` | A Implementação **NEVER** reabre uma decisão de produto já registrada no Planejamento; divergência encontrada aqui **MUST** voltar para Pesquisa, não ser decidida ad-hoc. |
| `WF-IMPL-02` | Teste focado **MUST** acompanhar a mudança, não ser etapa posterior; implementar tudo e "testar depois" **NEVER** (XP, test-first). |
| `WF-IMPL-03` | O escopo da mudança **MUST** ser o menor que resolve a unidade decidida; resolver problema adjacente não decidido nesta unidade **NEVER**, mesmo que pareça eficiente. |
| `WF-IMPL-04` | Contrato explícito (tipo, schema, fronteira de tenant/auth) **MUST** ser preservado durante a implementação; mudar contrato implícito e "ajustar depois" **NEVER**. |
| `WF-IMPL-05` | Defeito local encontrado durante a própria implementação **MUST** ser corrigido ali e registrado como evidência, sem abrir um ciclo de Validação separado só para ele. |
| `WF-IMPL-06` | Antes da primeira linha de código, quem implementa **MUST** listar as perguntas que a unidade não responde — a Task e o código que ela toca, pelas categorias de borda da §4.1 — e cada uma sai respondida por um artefato aceito, decidida dentro do que a unidade já decidiu, ou devolvida pela §4.3 como lacuna (`WF-CORE-09`); começar a escrever sem essa lista **NEVER** — a pergunta achada no meio do código chega com uma resposta inventada já escrita nele. † |

### `WF-VAL-*` — validação

| ID | Regra |
| --- | --- |
| `WF-VAL-01` | Quem implementa **NEVER** aprova a própria mudança; a Validação **MUST** inspecionar em contexto independente do autor (Google SWE Practices; ver `CC-SES-07`). |
| `WF-VAL-02` | A evidência exigida **MUST** ser proporcional ao risco da mudança; "rodar a suíte inteira" como resposta padrão **NEVER** — é decisão de evidência preguiçosa, não rigorosa. |
| `WF-VAL-03` | Verificação técnica ("construímos certo") e validação de negócio ("é a coisa certa") **MUST** ser etapas separadas; a segunda **NEVER** bloqueia o fechamento técnico da primeira (ver [Teste de Software](teste-de-software.md) §0). |
| `WF-VAL-04` | Toda falha de Validação **MUST** ser roteada para o pilar de origem do problema — Pesquisa se é lacuna de decisão, Planejamento se é lacuna de escopo/evidência, Implementação se é defeito de código; corrigir no pilar errado **NEVER**. |
| `WF-VAL-05` | Métrica de entrega (lead time, taxa de falha de mudança) **MUST** vir de dado medido, **NEVER** de percepção (Forsgren/Humble/Kim, *Accelerate* — métricas DORA). |

### `WF-SPEC-*` — os arquivos de `.specs/`

| ID | Regra |
| --- | --- |
| `WF-SPEC-01` | A saída de Pesquisa e de Planejamento **MUST** ser gravada em `.specs/`, e o `artefato` do envelope aponta o caminho; saída que só existe na conversa **NEVER**. † |
| `WF-SPEC-02` | Cada arquivo de `.specs/` **MUST** ter um único dono e citar os outros por link; copiar conteúdo de um arquivo para outro **NEVER**, a cópia diverge. † |
| `WF-SPEC-03` | Os arquivos gerados **MUST** seguir o escopo classificado na §4.1; gerar os quatro arquivos para um detalhe de implementação **NEVER** (ver `DOC-CORE-02`). † |
| `WF-SPEC-04` | Um Task do plano em `tasks/` **MUST** começar só quando os arquivos que ele cita estão aceitos; começar sobre rascunho **NEVER** (`WF-CORE-03`). |
| `WF-SPEC-05` | Uma execução só de especificação **MUST** parar depois do plano em `tasks/`, devolvendo o envelope de Planejamento; seguir para a Implementação sem novo pedido do dono **NEVER**. † |
| `WF-SPEC-06` | Todo arquivo de `.specs/` **MUST** nascer `Draft` (ADR: `Proposed`) e mudar de status só pela resposta explícita do dono na conversa; o agente que escreveu aprovar o próprio arquivo, ou silêncio valer como aprovação, **NEVER**. † |
| `WF-SPEC-07` | Quais documentos o projeto mantém **MUST** ser registrado uma vez (`## Specs` no `AGENTS.md`, com permissão do dono, ou `.specs/README.md`) e lido antes de escrever; perguntar de novo a cada execução **NEVER**; desligar o plano em `tasks/` **NEVER**. † |
| `WF-SPEC-08` | `.specs/` **MUST** ter uma pasta por capability: documento da capability já aprovado recebe mudança como emenda datada, que nasce `Draft`, e cada incremento ganha seu plano em `tasks/NNNN-<slug>.md`; reescrever texto aprovado, ou acumular incrementos num plano só, **NEVER**. † |

### Contagem

**40 regras** em seis famílias, um único arquivo — sem satélite nesta versão.

| Família | Regras |
| --- | --- |
| `WF-CORE-*` | 9 |
| `WF-RES-*` | 6 |
| `WF-PLAN-*` | 6 |
| `WF-IMPL-*` | 6 |
| `WF-VAL-*` | 5 |
| `WF-SPEC-*` | 8 |

---

## 7. Contrato de skill

### O que carregar

```
SEMPRE, ao decidir em que pilar uma tarefa ambígua está:
          Fluxo de Entrega - Quatro Pilares.md § 0, § 2, § 3

AO CLASSIFICAR o escopo de uma pesquisa e varrer as bordas da decisão:
          § 4.1 + WF-RES-*

AO DECLARAR uma lacuna, ou decidir se um pilar avança com ela:
          § 5 "Lacunas" + WF-CORE-09

AO PASSAR pelos portões de planejamento:
          § 4.2 + WF-PLAN-*

AO LISTAR as perguntas antes do código, ou decidir se a implementação para e devolve:
          § 4.3 + WF-IMPL-* (e a tabela de bordas da § 4.1)

AO DECIDIR quanta evidência a validação exige:
          § 4.4 + WF-VAL-*

AO GRAVAR os arquivos de .specs/:
          § 5 + WF-SPEC-* (e a nota de Documentos de Decisão, DOC-*, só para o documento em escrita)

AO DECIDIR quem executa uma operação mecânica (commit, PR, mover, apagar, publicar, rodar checks):
          § 3.1 + WF-CORE-08

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
4. **Evidência proporcional, nunca "a suíte inteira" por padrão** (`WF-VAL-02`), e o tipo de
   teste decidido no plano, com o custo dele à vista (`WF-PLAN-06`).
5. **Verificação técnica não espera validação de negócio, nem o contrário** (`WF-VAL-03`) —
   as duas são reais, mas não se bloqueiam.
6. **Seguir a ponte.** Quando a §8 indicar que a decisão pertence a uma skill ou agente já
   existente, seguir em vez de reinventar o procedimento aqui.
7. **Operação mecânica no tier mais barato** (`WF-CORE-08`) — quem orquestra não lê diff,
   template ou saída de teste para executar o que um artefato já decidiu.
8. **Lacuna nunca fecha no código.** Toda lacuna tem quem decide e onde fecha (`WF-CORE-09`);
   a Pesquisa varre as bordas antes de entregar (`WF-RES-06`), e quem implementa lista as
   perguntas antes da primeira linha (`WF-IMPL-06`).
9. **O papel vem do agente, não do brief.** Pilar delegado roda no agente nomeado, chamado como
   subagente; uma sessão aberta para uma unidade abre com modelo e esforço explícitos e chama
   esse agente, em vez de interpretá-lo (`WF-CORE-06`, `CC-PAR-05`).

### Recortes para skills novas

| Skill | Carrega | Fonte declarada |
| --- | --- | --- |
| "que pilar é esta tarefa ambígua" | § 0 + § 2 + § 3 | este hub |
| "classificar escopo de uma pesquisa" | § 4.1 + `WF-RES-*` | este hub |
| "passar pelos portões de planejamento" | § 4.2 + `WF-PLAN-*` | este hub |
| "decidir se a implementação para e devolve" | § 4.3 + `WF-IMPL-*` | este hub |
| "decidir quanta evidência a validação exige" | § 4.4 + `WF-VAL-*` | este hub |
| "decidir quem executa uma operação mecânica" | § 3.1 + `WF-CORE-08` | este hub |
| "escrever e registrar um arquivo de `.specs/`" | § 5 + `WF-SPEC-*` | este hub e [Documentos de Decisão — PRD, RFC e ADR](documentos-de-decisao-prd-rfc-adr.md) |

---

## 8. Pontes com o stack

| Decisão | O que **não** fazer | A ponte |
| --- | --- | --- |
| Decidir se uma mudança é de produto, arquitetura ou detalhe | assumir e seguir para o código | `product-manager` / `software-architect` — §4.1 |
| Responder a borda de uma regra — o limite, o prazo, o vazio, o clique repetido | escolher no código o que parecer razoável | a varredura de bordas da §4.1, na Pesquisa (`WF-RES-06`); no código, a lista de perguntas da §4.3 devolve (`WF-IMPL-06`) |
| Abrir Epic/Story/Task no rastreador | criar o item assim que a ideia aparece, antes da decisão | `workflow-research` decide o escopo primeiro (§4.1) — o Board só abre no Planejamento, com a decisão já resolvida (§0.4, §3) |
| Decidir em que nível um teste da unidade entra | deixar para a hora de escrever | `test-design`, existente — não é reimplementado aqui |
| Revisar uma mudança já implementada | o próprio autor aprovar | `code-reviewer`, em contexto fresco (`WF-VAL-01`, `CC-SES-07`) |
| Decidir o contrato HTTP de uma rota nova | inventar status/shape no handler | `http-contract`, existente |
| Achado de autenticação, cookie ou segredo durante a validação | corrigir e seguir sem rotear | `devops-security` (`WF-VAL-04`) |
| Cronograma, risco ou "isso cabe no escopo" durante o planejamento | o time de implementação decidir sozinho | `project-manager` |
| Fronteira entre camadas ou serviços durante o planejamento | decidir dentro do código, sem registrar | `software-architect`, decisão registrada |
| Escrever PRD, RFC, ADR, UX ou tasks em `.specs/` | inventar o formato, aprovar o próprio arquivo, ou editar um ADR aceito | `workflow-spec`, com [Documentos de Decisão — PRD, RFC e ADR](documentos-de-decisao-prd-rfc-adr.md) |

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
- Glenford Myers, *The Art of Software Testing* — partição de equivalência e análise de
  valor-limite: o defeito se concentra na fronteira entre classes de entrada; base da
  categoria "limite" da varredura de bordas (§4.1, `WF-RES-06`). Consultado em 2026-10-10 por
  resumos do capítulo, não pelo texto do livro.
- Matt Wynne, *Introducing Example Mapping* (blog do Cucumber) — regras, exemplos e perguntas:
  a pergunta que ninguém na sala responde vira um cartão vermelho e a conversa segue, e uma
  mesa coberta deles diz que a story ainda não está entendida; base de declarar a lacuna em
  vez de adivinhar a resposta (`WF-CORE-09`) e de varrer a regra por exemplos (`WF-RES-06`).
  Os campos `decide` e `fecha-em` são decisão desta doc, não do post. Consultado em
  2026-10-10.
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
- `skills/workflow/` — as quatro skills que implementam este contrato, e `workflow-spec`, que grava os arquivos de `.specs/`
- [Documentos de Decisão — PRD, RFC e ADR](documentos-de-decisao-prd-rfc-adr.md) — o que é
  cada documento de decisão gravado em `.specs/`
- [Claude Code - Sessão e Verificação](claude-code-sessao-e-verificacao.md) — `CC-SES-07`,
  revisão em contexto fresco
- [Claude Code - Paralelismo e Escala](claude-code-paralelismo-e-escala.md) — subagentes e
  como o bastão passa em Claude Code especificamente
