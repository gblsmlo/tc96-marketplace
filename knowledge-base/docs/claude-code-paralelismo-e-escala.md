---
titulo: Claude Code - Paralelismo e Escala
Link: https://code.claude.com/docs/pt/agents
tags:
 - claude-code
 - ia
 - subagentes
 - workflows
 - worktree
 - paralelismo
 - agent-context
source: "Documentação oficial do Claude Code — Run agents in parallel, Create custom subagents, Orchestrate subagents at scale with dynamic workflows, Run parallel sessions with worktrees, Message your other Claude Code sessions, Commands (/batch)"
verificado-em: 2026-08-21
---

# Claude Code — Paralelismo e Escala

> Satélite de [Claude Code](claude-code.md). Cobre o que fazer quando o trabalho passou do que cabe em uma conversa.
>
> **A distinção que a nota existe para fazer:** paralelismo não é uma coisa, são quatro, e a pergunta que as separa é **quem detém o plano**. Escolher errado não dá erro — dá desperdício silencioso de token, ou um resultado que ninguém conferiu.
>
> **Recorte:** agent view e agent teams estão fora, por serem *research preview* e *experimental desativado por default*. Ficam nomeados na § 7 do hub.

---

## 1. Quem detém o plano

| | **Subagentes** | **Skills** | **Dynamic workflows** |
| --- | --- | --- | --- |
| O que é | um worker que o Claude cria | instruções que o Claude segue | **um script que o runtime executa** |
| Quem decide o próximo passo | o Claude, turno a turno | o Claude, seguindo o prompt | **o script** |
| Onde vivem os resultados intermediários | na janela de contexto do Claude | na janela de contexto do Claude | **em variáveis do script** |
| O que é repetível | a definição do worker | as instruções | **a orquestração em si** |
| Escala | algumas tarefas delegadas por turno | igual a subagentes | **dezenas a centenas de agentes por run** |
| Interrupção | reinicia o turno | reinicia o turno | **resumível na mesma sessão** |

A linha que decide é a terceira. Com subagentes e skills, o Claude é o orquestrador e **todo resultado aterrissa numa janela de contexto**. Um workflow guarda o laço, a ramificação e os resultados intermediários **ele mesmo** — o contexto do Claude fica só com a resposta final.

Mover o plano para código também habilita algo que mais agentes por si não dão: **um padrão de qualidade repetível**. O workflow pode fazer agentes independentes revisarem adversarialmente os achados uns dos outros antes de reportar, ou rascunhar um plano por vários ângulos e pesá-los entre si.

E a árvore completa, incluindo o que **não** é forma de rodar agente:

```
Quem coordena?
├── Claude, dentro de uma conversa ──────────► subagentes
├── um script, com o plano em código ────────► dynamic workflows
└── você, em sessões separadas ─────────────► worktrees + cross-session messaging

As tarefas tocam os mesmos arquivos? ────────► isole em worktree
Mudança grande e divisível em unidades? ─────► /batch

NÃO é rodar agente:
 background bash — um comando de shell sem bloquear a conversa, sem agente
 /subtask — subagente forkado, herda o SEU contexto em vez de começar limpo
 /fork — copia a sessão inteira para uma nova sessão em background
```

> **Paralelismo troca token por tempo de parede, não por eficiência.** Rodar várias sessões ou subagentes ao mesmo tempo **multiplica** o consumo.

---

## 2. Subagentes

O mecanismo de maior retorno da estrutura inteira, pela razão da § 2 do hub: **as leituras de um subagente custam zero no seu contexto**. Uma investigação de dez arquivos custa ~18.000 tokens na sua janela, ou 420 (o resumo) se rodar delegada.

```text
Use subagentes para investigar como nosso sistema de autenticação trata refresh de
token, e se já temos utilitários de OAuth que eu deveria reusar.
```

### 2.1 Os embutidos

| Agente | Modelo | Ferramentas | Para |
| --- | --- | --- | --- |
| **Explore** | herda o da conversa principal, **limitado a Opus** na API da Anthropic | somente leitura — `Write` e `Edit` negados | descoberta de arquivo, busca, exploração de base |
| **Plan** | — | — | desenho de plano de implementação |

**Explore e Plan pulam os seus CLAUDE.md e o git status da sessão pai**, para manter a pesquisa rápida e barata. Todo outro subagente, embutido ou customizado, carrega os dois.

Ao invocar o Explore, o Claude especifica um nível de minúcia: **quick** para consulta pontual, **medium** para exploração equilibrada, **very thorough** para análise completa.

> Um subagente de usuário ou projeto chamado `Explore` **sobrepõe** o embutido e mantém o próprio campo `model` — então definir um com `model: haiku` é como manter exploração num modelo mais barato.

### 2.2 O que chega num subagente

| Chega | Não chega |
| --- | --- |
| o system prompt **dele**, não o do Claude Code inteiro | o histórico da sua conversa |
| o conteúdo **integral** das skills do campo `skills:` | a auto memory da conversa principal |
| CLAUDE.md e git status (**exceto** Explore e Plan) | |
| o que o agente líder passar no prompt | |

A exceção é o **fork**, que herda a conversa do pai, o system prompt e as ferramentas.

### 2.3 Limites

| Limite | Valor | Como mudar |
| --- | --- | --- |
| Subagentes **rodando ao mesmo tempo** | 20 | `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` |
| Total por sessão | **sem limite** | — |
| Profundidade de aninhamento | tem limite próprio | variável própria |

Ao estourar o limite de concorrência, o spawn falha com `Concurrent subagent limit reached`, e o erro **diz ao Claude para não tentar de novo**. Sessão com `ultracode` ativo é isenta. Um fork iniciado por `/subtask` ocupa um slot mas nunca é bloqueado pelo limite; retomar um subagente que já terminou pega slot novo **sem checar** o limite, e portanto pode empurrar a contagem além dele.

### 2.4 Fork: quando o subagente precisa do seu contexto

| Comando | Faz |
| --- | --- |
| `/subtask <tarefa>` | subagente em background que **herda a sua conversa** em vez de começar limpo |
| `/fork [prompt]` | **copia a sessão inteira** para uma nova sessão em background, que roda ao lado |
| `f` numa resposta de `/btw` | forka aquela pergunta para um subagente com ferramentas |

Fork é a resposta para "preciso delegar, mas o worker não entenderia a tarefa sem o histórico". Subagente normal é a resposta para "preciso delegar **justamente para** o histórico não vir".

### 2.5 Onde acompanhar

| Comando | Mostra |
| --- | --- |
| `/tasks` | tudo rodando em background na sessão atual, incluindo subagentes que já terminaram; permite conferir, anexar ou parar |
| `@`-mention typeahead | subagentes de background nomeados, com status |
| `/workflows` | runs de workflow: fase de cada um e quantos agentes terminaram |

> `/agents` **não** abre painel desde a v2.1.198 — imprime um aviso apontando onde os arquivos de subagente ficam. Para criar ou editar, peça ao Claude ou edite os arquivos.

---

## 3. Worktrees

Cada sessão ganha um checkout git separado, então sessões paralelas **nunca editam os mesmos arquivos** (`CC-PAR-02`). São para sessões que **você** roda, e subagentes que você cria podem ganhar uma cada.

O essencial da configuração:

| Preciso | Use |
| --- | --- |
| checkout só dos diretórios que a tarefa precisa | `worktree.sparsePaths` |
| escolher a branch base | configuração de base branch |
| ramificar de um pull request | criação a partir de PR |
| levar arquivos gitignorados (ex.: `.env`) para dentro | configuração de cópia de gitignorados |
| substituir a criação por lógica própria | **hook** de criação de worktree |

**A pegadinha de custo, que não está na página de worktrees:** o prompt cache é escopado por **máquina + diretório**, e cada worktree tem diretório próprio. **Worktrees do mesmo repositório não compartilham cache** — cada uma paga a construção do prefixo do zero. Sessões paralelas no **mesmo** diretório, ao contrário, leem o cache uma da outra. Ver § 5 de [Claude Code - Contexto e Cache](claude-code-contexto-e-cache.md).

Isso não é argumento contra worktree — é argumento para não criar worktree quando o motivo não é conflito de arquivo.

---

## 4. Dynamic workflows

O script é escrito pelo Claude e executado pelo runtime, num ambiente **isolado da sua conversa**.

### 4.1 Como roda

Todo run escreve o script num arquivo sob o diretório da sua sessão em `~/.claude/projects/`, e o Claude recebe o caminho quando o run começa — então você pode **pedir o caminho**, abrir o arquivo para ler a orquestração que ele escreveu, comparar com o script de um run anterior, ou **editar e pedir para relançar da versão editada**.

O runtime acompanha o resultado de cada agente conforme o run avança, e é isso que torna um run **resumível** dentro da mesma sessão.

### 4.2 Limites do runtime

| Restrição | Motivo declarado |
| --- | --- |
| **Sem input do usuário no meio do run** | só prompts de permissão de agente pausam. Para aprovação entre etapas, rode **cada etapa como seu próprio workflow** |
| Sem acesso direto a filesystem ou shell **pelo script** | os agentes leem, escrevem e rodam comandos; o script coordena |
| Sem carregamento de módulo — script com `import` **falha antes de começar** | o corpo é JavaScript puro. Trabalho que precisa de biblioteca vai na tarefa de um agente |
| Até **16 agentes concorrentes**, menos com menos CPU disponível | limita uso de recurso local |
| **1.000 agentes no total** por run | evita laço desgovernado |
| Num fan-out, agentes que compartilham o prefixo de cache do primeiro começam até **5 segundos** depois dele | os demais leem o prefixo que o primeiro cacheou, em vez de cada um processar sem cache |

### 4.3 Cache em fan-out — o detalhe que economiza de verdade

Agentes do mesmo run **leem o cache uns dos outros**. Dois agentes com o mesmo modelo, nível de effort, tipo de agente, ferramentas, schema de saída e diretório de trabalho constroem o mesmo prefixo de ferramentas e system prompt.

Quando um fan-out dispara vários agentes iguais de uma vez, o Claude Code **segura todos menos o primeiro** até a resposta dele começar, e então libera os retidos juntos, para que a primeira requisição deles leia o prefixo compartilhado. O teto da espera é `CLAUDE_CODE_WORKFLOW_PREFIX_STAGGER_MS`, **5000 ms por default**; `0` desativa a espera.

> Consequência prática ao escrever um workflow: **estágios homogêneos são mais baratos que estágios heterogêneos.** Vinte agentes com a mesma configuração pagam o prefixo uma vez; vinte com configurações diferentes pagam vinte vezes.

### 4.4 Custo, e o aviso automático

Um run gasta bastante mais token que fazer a mesma tarefa na conversa, e conta contra os limites do seu plano como qualquer sessão.

**Para calibrar antes de comprometer:** rode o workflow numa fatia pequena primeiro — um diretório em vez do repositório todo, uma pergunta estreita em vez de ampla. A visão `/workflows` mostra o consumo de token **por agente** conforme o run avança, e você pode parar ali a qualquer momento, normalmente **sem perder trabalho já concluído**.

**O Claude Code sinaliza run grande.** Quando um workflow agenda mais de **25 agentes**, ou o total projetado de tokens passa de **1,5 milhão**, a linha de progresso mostra um aviso `Large workflow` apontando para `/workflows`, onde você pode parar. O aviso é **consultivo**: não pausa nem limita.

- Se você escolheu uma diretriz de tamanho, a contagem dela substitui o limiar de 25.
- Sessão com `ultracode` ligado **não** mostra o aviso — ligar ultracode já é optar por runs grandes.

**Modelo.** Todo agente usa o modelo da sua sessão, a menos que o script roteie um estágio para outro, ou que `CLAUDE_CODE_SUBAGENT_MODEL` esteja definido — essa variável sobrepõe os dois. Duas disciplinas: confira `/model` antes de um run grande, se você costuma trocar para modelo menor no trabalho rotineiro; e ao descrever a tarefa, peça modelo menor para os estágios que não precisam do mais forte.

### 4.5 Onde workflow é a escolha certa

Os padrões que a doc dá como exemplo, e que são o teste de "isso é workflow ou é subagente?":

- auditar muitos arquivos buscando a mesma questão
- **continuar corrigindo até um check passar**
- migrar muitos arquivos em paralelo
- revisar cada arquivo alterado e escrever **um** resumo
- pesquisar um tema em muitas fontes
- **achar problemas até a lista parar de crescer**

Os dois em negrito são os que subagente não faz: são **laços com condição de parada**, e laço é exatamente o que se ganha ao mover o plano para código (`CC-PAR-03`).

O embutido é `/deep-research`: fan-out de buscas web por vários ângulos, busca e cruza as fontes, e sintetiza um relatório com citações.

---

## 5. `/batch`

Mudança grande e divisível numa passada. Pesquisa a base, decompõe em **5 a 30 unidades independentes**, e apresenta um plano. Aprovado, cria **uma subagente por unidade em worktree git isolada**; cada uma implementa, roda testes e **abre um pull request**. Exige repositório git.

```text
/batch migre src/ de Solid para React
```

É um uso empacotado de subagentes e worktrees, não um estilo de coordenação separado. E é a resposta certa quando a decomposição é óbvia e a revisão deve acontecer por PR.

Alternativa por script, quando você quer o laço na sua mão: ver § 3 de [Claude Code - Automação Externa](claude-code-automacao-externa.md).

---

## 6. Cross-session messaging

O Claude lista e manda mensagem para as suas outras sessões do Claude Code — nesta máquina, em outra, ou na web. Serve para sessões que **você** roda passarem achado e status entre si.

O caso de uso que a doc nomeia é específico e vale registrar: **uma sessão avisa outra que uma mudança que ela fez quebra aquilo em que a outra está construindo.** É o problema que worktree cria — isolamento de arquivo não é isolamento de consequência.

`/list-agents` mostra os subagentes e as sessões que o Claude pode mensagear, com o nome a usar para cada.

---

## 7. Disciplina de custo

O paralelismo é a única parte desta estrutura em que a otimização de contexto e a de custo **divergem**. Subagente melhora seu contexto e aumenta o gasto total. As três disciplinas que a doc sustenta:

1. **Calibrar numa fatia.** Um diretório, não o repositório. Uma pergunta estreita, não ampla.
2. **Rotear modelo por estágio.** `model: haiku` em subagente de tarefa simples; modelo forte só onde o julgamento é difícil.
3. **Observar durante.** `/workflows` e `/tasks` mostram consumo enquanto roda, e permitem parar sem perder o concluído. Parar cedo é a alavanca de custo mais eficaz que existe aqui.

---

## 8. Regras normativas desta nota

Canônicas na § 6.4 de [Claude Code](claude-code.md).

| ID | Como reconhecer a violação |
| --- | --- |
| `CC-PAR-01` | `/context` mostra dezenas de leituras de arquivo que a tarefa atual não referencia mais |
| `CC-PAR-02` | duas sessões paralelas editaram o mesmo arquivo e uma sobrescreveu a outra |
| `CC-PAR-03` | o Claude está reiniciando o mesmo padrão de delegação a cada turno, em vez de um laço rodar sozinho |
| `CC-PAR-04` | um pedido de "investigue X" sem arquivo, diretório ou pergunta delimitados |

---

## Relacionados

- [Claude Code](claude-code.md) — hub: árvore de decisão de paralelismo
- [Claude Code - Contexto e Cache](claude-code-contexto-e-cache.md) — por que subagente é barato, e por que worktree não compartilha cache
- [Claude Code - Configuração do Repositório](claude-code-configuracao-do-repositorio.md) — definir subagente customizado em `.claude/agents/`
- [Claude Code - Automação Externa](claude-code-automacao-externa.md) — fan-out por script, fora da sessão interativa
