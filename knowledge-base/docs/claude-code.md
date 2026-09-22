---
titulo: Claude Code
Link: https://code.claude.com/docs/pt/overview
tags:
 - claude-code
 - ia
 - agentes
 - produtividade
 - contexto
 - agent-context
source: "Documentação oficial do Claude Code — overview, best-practices, context-window, prompt-caching, memory, features-overview, model-config, agents, workflows, large-codebases, costs, headless, hooks-guide, goal, skills, commands"
verificado-em: 2026-08-21
---
# Claude Code — alta performance

> Hub. Esta estrutura responde a **uma** pergunta: o que fazer, em que ordem, para tirar o máximo do Claude Code. Não é um resumo linear da documentação — o `llms.txt` da doc indexa **189 páginas**, das quais 31 são do Agent SDK e 20 são notas semanais de release, e a maior parte do resto trata de instalação, deployment corporativo e gateways — nada disso muda a qualidade do seu resultado no dia a dia.
>
> O hub traz o modelo mental, o custo real de cada coisa em tokens, o checklist em cinco tempos, as árvores de decisão e a § 6 normativa com os IDs citáveis. Os satélites trazem o procedimento.
>
> **Recorte declarado:** só superfície **estável**. O que a doc marca como *research preview* ou *experimental* está listado na [§ 7](#7-fora-de-escopo-e-limitações), nomeado mas sem procedimento.

---

## 1. A restrição única

A documentação de best practices abre declarando de onde vem tudo o mais:

> A maior parte das boas práticas se baseia em uma restrição: a janela de contexto do Claude enche rápido, e a performance **degrada** conforme ela enche.

Isso é mais forte do que parece. Não é "quando encher, para de funcionar" — é **degradação contínua**: a doc descreve que, com a janela ficando cheia, o Claude pode começar a "esquecer" instruções anteriores e a errar mais. Ela não publica uma curva, então trate como direção, não como medida. A consequência prática inverte a intuição:

**Contexto é orçamento, não capacidade.** Você não deve encher a janela porque ela existe. Cada token gasto em algo que não contribui para a tarefa atual é um token cobrado de novo em **todo** request seguinte — e um pouco de degradação em todas as respostas seguintes.

Disso derivam as três alavancas, em ordem de retorno:

| Alavanca | Pergunta que ela responde | Satélite |
| --- | --- | --- |
| **Não colocar** no contexto | o que pode ficar de fora, ou ir para uma janela que não é a minha? | [Claude Code - Contexto e Cache](claude-code-contexto-e-cache.md) · [Claude Code - Paralelismo e Escala](claude-code-paralelismo-e-escala.md) |
| **Fechar o loop** de verificação | como o Claude sabe que terminou, sem eu ser o verificador? | [Claude Code - Sessão e Verificação](claude-code-sessao-e-verificacao.md) |
| **Configurar uma vez**, render sempre | o que eu digito repetidamente e deveria estar em disco? | [Claude Code - Configuração do Repositório](claude-code-configuracao-do-repositorio.md) |

A quarta — tirar o trabalho da sua máquina e do seu turno — é [Claude Code - Automação Externa](claude-code-automacao-externa.md).

---

## 2. O que já está no seu contexto antes de você digitar

A doc publica uma timeline com números representativos de uma sessão real. Esta é a parte de partida, **antes do seu primeiro prompt**:

| Carrega no startup | Tokens | Visível para você? |
| --- | --- | --- |
| System prompt | 4.200 | não |
| CLAUDE.md do projeto | 1.800 | não |
| Auto memory (`MEMORY.md`) | 680 | não |
| Skill descriptions | 450 | não |
| `~/.claude/CLAUDE.md` | 320 | não |
| Environment info | 280 | não |
| MCP tools (deferidas) | 120 | não |
| **Total** | **≈ 7.850** | |

E este é o custo de cada coisa que acontece depois:

| Operação | Tokens |
| --- | --- |
| leitura de um arquivo de código típico | 1.100 – 2.400 |
| saída de `npm test` | 1.200 |
| `grep` numa base | 600 |
| slash command | 620 |
| rule com `paths:` que casou | 290 – 380 |
| saída de hook | 100 – 120 |
| **subagente: as leituras dele** | **0** |
| resumo que o subagente devolve | 420 |
| resumo de `/compact` | ≈ 12% do acumulado |

Duas leituras dessa tabela valem o resto do documento:

1. **Uma investigação de dez arquivos custa ~18.000 tokens no seu contexto, ou zero se rodar em subagente.** É o maior fator isolado de diferença entre uma sessão que rende e uma que trava.
2. **O que você configura aparece na primeira tabela, não na segunda.** Um CLAUDE.md de 1.800 tokens é cobrado em todo request da sessão. Uma skill custa a descrição (dezenas de tokens) até ser usada. Não são a mesma decisão.

Para ver os seus números em vez dos representativos: `/context` (grid com sugestões de otimização) e `/skills` com `t` (ordena as skills por consumo de token).

---

## 3. Checklist em cinco tempos

### 3.1 Pré-voo — uma vez por repositório

- [ ] **`/init`** para gerar o CLAUDE.md inicial, e então **podar**. Critério por linha: *"remover isso faria o Claude errar?"* Se não, corte. `CC-CFG-01`
- [ ] Manter o CLAUDE.md **abaixo de 200 linhas**. O que passar disso vira skill ou `.claude/rules/`. `CC-CFG-02`
- [ ] Mover conhecimento **ocasional** para skill; instrução **sempre válida** fica no CLAUDE.md. `CC-CFG-03`
- [ ] Instalar o **CLI** dos serviços que você usa (`gh`, `aws`, `gcloud`). É a forma mais econômica de contexto para falar com serviço externo — mais que MCP. `CC-CFG-08`
- [ ] Instalar **plugin de code intelligence** se a linguagem é tipada. Reduz leitura de arquivo: uma ida à definição substitui grep + abrir vários candidatos. `CC-CFG-09`
- [ ] Escrever **hook** para o que precisa acontecer **sempre, sem exceção**. Instrução no CLAUDE.md é conselho; hook é determinístico. `CC-CFG-05`
- [ ] Configurar **allowlist de permissão** (`/permissions`) e **sandbox** (`/sandbox`) para parar de aprovar a mesma coisa. `/fewer-permission-prompts` varre seus transcripts e propõe a lista. `CC-SES-08`
- [ ] Repositório grande ou monorepo: aplicar o kit de escopo — CLAUDE.md por diretório, `claudeMdExcludes`, deny rules de `Read` em build output e vendored, `worktree.sparsePaths`. `CC-CFG-10`
- [ ] Rodar **`/doctor`**. Ele diagnostica o setup e propõe cortes no CLAUDE.md versionado.

### 3.2 Abertura de sessão

- [ ] **Escolher modelo e effort agora.** Trocar depois recomputa o request inteiro, sem cache. `CC-CTX-05`
- [ ] Uma sessão por linha de trabalho. **`/rename`** com nome descritivo (`oauth-migration`); trate como branch. `CC-SES-09`
- [ ] Tarefa com abordagem incerta, que toca vários arquivos, ou em código que você não conhece: **plan mode** (`Shift+Tab`, ou `claude --permission-mode plan`). `CC-SES-02`
- [ ] Tarefa cujo diff você descreve em **uma frase**: pule o plano. Plan mode tem overhead. `CC-SES-03`
- [ ] Feature grande: peça ao Claude para **te entrevistar** com o `AskUserQuestion` e escrever um `SPEC.md`. Depois **abra sessão nova** para executar. `CC-SES-04`

### 3.3 Durante a tarefa

- [ ] **Dar ao Claude uma verificação que ele mesmo roda** — teste, build, linter, screenshot comparado. Sem isso, "parece pronto" é o único sinal disponível e **você** é o loop de verificação. `CC-SES-01`
- [ ] Ser específico: nomear arquivo, cenário, restrição, e apontar o **padrão existente** a seguir. `CC-SES-05`
- [ ] Mandar investigação para **subagente**. As leituras dele não entram no seu contexto. `CC-PAR-01`
- [ ] **`Esc` cedo.** Corrigir rota assim que perceber o desvio rende mais que deixar terminar.
- [ ] **Após duas correções falhas na mesma coisa: `/clear`** e reescrever o prompt incorporando o que aprendeu. Contexto poluído por tentativas fracassadas não recupera. `CC-SES-06`
- [ ] **`/clear` entre tarefas não relacionadas.** `CC-CTX-01`
- [ ] Pergunta lateral que não precisa ficar no histórico: **`/btw`**. A resposta nunca entra na conversa. `CC-CTX-02`
- [ ] Abandonar um caminho: **`/rewind`**, não `/compact`. Rewind volta a um prefixo já cacheado; compact constrói um novo. `CC-CTX-06`
- [ ] Raciocínio mais fundo em **um** turno: a palavra **`ultrathink`** no prompt. (`"think hard"` e `"think more"` **não** são reconhecidas — passam como texto comum.) `CC-CTX-08`
- [ ] `/compact` em **pausa natural** entre tarefas, com instrução de foco (`/compact foque na correção de auth`), em vez de esperar a compactação automática cair no meio da tarefa. `CC-CTX-03`

### 3.4 Antes de considerar pronto

- [ ] Exigir **evidência**, não afirmação: a saída do teste, o comando e o retorno, o screenshot. Revisar evidência é mais rápido que refazer a verificação. `CC-SES-01`
- [ ] **Revisão adversarial em contexto fresco**: `/code-review`, ou um subagente que vê só o diff e o critério — não o raciocínio que produziu a mudança. `CC-SES-07`
- [ ] Ao instruir o revisor, mandar reportar **só o que afeta corretude ou requisito declarado**. Revisor instruído a achar lacuna acha mesmo quando não há; perseguir tudo produz over-engineering. `CC-SES-10`
- [ ] Confirmar contra o app rodando, não só contra os testes: **`/verify`**. `CC-SES-11`
- [ ] Trabalho longo sem supervisão: prender a saída a uma condição com **`/goal`**, ou a um **Stop hook**. `CC-SES-12`

### 3.5 Manutenção periódica

- [ ] Reler o CLAUDE.md quando algo der errado, e podar. **Se o Claude insiste em ignorar uma regra que existe, o arquivo provavelmente está longo demais e a regra se perdeu.** `CC-CFG-04`
- [ ] Se o Claude faz perguntas cuja resposta **está** no CLAUDE.md, o problema é redação ambígua, não ausência.
- [ ] Auditar o que a auto memory salvou: `/memory`. É markdown puro, editável e deletável.
- [ ] `/mcp` para desconectar servidor que você não está usando.
- [ ] Promover a hook o que virou regra estável — e deletar do CLAUDE.md o que o Claude já acerta sem a instrução. `CC-CFG-06`

---

## 4. Árvores de decisão

### 4.1 Onde colocar uma instrução

O gatilho decide o mecanismo. Esta é a tabela da doc, que evita a pergunta errada ("skill ou CLAUDE.md?") em favor da certa ("o que aconteceu?"):

| O que aconteceu | O que adicionar |
| --- | --- |
| Claude errou uma convenção **duas vezes** | linha no **CLAUDE.md** |
| Você digita o mesmo prompt para iniciar uma tarefa | **skill** invocável por você |
| Você colou o mesmo playbook pela **terceira** vez | **skill** |
| Você copia dado de uma aba que o Claude não vê | **MCP server** |
| Claude lê muitos arquivos para achar onde um símbolo é definido | **plugin de code intelligence** |
| Uma tarefa lateral inunda a conversa com output descartável | **subagente** |
| Você quer que algo aconteça **sempre**, sem pedir | **hook** |
| Um segundo repositório precisa do mesmo setup | **plugin** |

O mesmo gatilho diz quando **atualizar** o que já existe: erro repetido ou comentário recorrente de review é edição de CLAUDE.md, não correção no chat.

### 4.2 Planejar ou ir direto

```
O diff cabe em uma frase?
├── sim ──────────────────────────► vá direto (plan mode só adiciona overhead)
└── não
 ├── você conhece o código e a abordagem? ──► vá direto, com verificação no prompt
 └── incerteza de abordagem, vários arquivos,
 ou código desconhecido ────────────────► plan mode
 └── feature grande, escopo aberto ─────► entrevista → SPEC.md → sessão nova
```

### 4.3 Qual forma de paralelismo

A pergunta que separa as quatro é **quem detém o plano**:

```
Quem coordena?
├── Claude, dentro de uma conversa, turno a turno ──► subagentes
├── um SCRIPT, com o plano em código ───────────────► dynamic workflows
└── você, em sessões separadas ────────────────────► worktrees (+ cross-session messaging)

As tarefas tocam os mesmos arquivos? ──► isole em worktree
Uma mudança grande e divisível? ──► /batch (5 a 30 subagentes, cada um abre PR)
```

Detalhe decisivo: em subagente e skill, os resultados intermediários vivem **no contexto do Claude**. Em workflow, vivem em **variáveis do script** — o contexto guarda só a resposta final. É isso que faz workflow escalar para dezenas ou centenas de agentes, e o que o torna resumível. Procedimento em [Claude Code - Paralelismo e Escala](claude-code-paralelismo-e-escala.md).

> Rodar várias sessões ou subagentes ao mesmo tempo **multiplica** o consumo de token. Paralelismo troca token por tempo de parede, não por eficiência.

---

## 5. Mapa dos satélites

| Nota | Cobre | Leia quando |
| --- | --- | --- |
| [Claude Code - Contexto e Cache](claude-code-contexto-e-cache.md) | janela de contexto, o que sobrevive à compactação, prompt caching (o que invalida e o que preserva), effort e `ultrathink`, `/autocompact`, redução de tokens | a sessão está lenta, caindo em compactação, ou custando mais que devia |
| [Claude Code - Sessão e Verificação](claude-code-sessao-e-verificacao.md) | prompting específico, plan mode, os quatro níveis de gate de verificação, `/goal`, checkpoints, `/rewind`, antipadrões nomeados | o resultado vem plausível mas errado, ou você virou o verificador |
| [Claude Code - Configuração do Repositório](claude-code-configuracao-do-repositorio.md) | CLAUDE.md, `.claude/rules/`, auto memory, skills, hooks, subagentes customizados, MCP e tool search, plugins, monorepo | você digita a mesma coisa toda sessão, ou o repositório é grande |
| [Claude Code - Paralelismo e Escala](claude-code-paralelismo-e-escala.md) | subagentes, dynamic workflows, worktrees, `/batch`, `/subtask`, cross-session messaging | o trabalho passou do que cabe em uma conversa |
| [Claude Code - Automação Externa](claude-code-automacao-externa.md) | `claude -p`, `--bare`, formatos de saída, fan-out por script, CI, GitHub Actions, `/code-review` local | o trabalho deve rodar sem você, ou dentro do pipeline |

---

## 6. Regras normativas

IDs canônicos. Uma skill futura cita por ID sem parafrasear; uma revisão aponta "viola `CC-CTX-05`". Divergência entre satélite e esta tabela é bug do satélite.

### 6.1 Contexto e cache — `CC-CTX-*`

| ID | Regra |
| --- | --- |
| `CC-CTX-01` | `/clear` entre tarefas não relacionadas. Contexto obsoleto é cobrado em toda mensagem seguinte. |
| `CC-CTX-02` | Pergunta que não precisa persistir vai em `/btw`. A resposta não entra no histórico. |
| `CC-CTX-03` | `/compact` é ato deliberado em pausa natural, com instrução de foco — não evento que a automação dispara no meio da tarefa. |
| `CC-CTX-04` | Rule que precisa sobreviver à compactação **não** leva `paths:` frontmatter, ou mora no CLAUDE.md da raiz. |
| `CC-CTX-05` | Modelo e effort se escolhem na abertura da sessão. Trocar no meio recomputa o request inteiro. |
| `CC-CTX-06` | Para abandonar um caminho, `/rewind` — não `/compact`. Rewind volta a prefixo já cacheado. |
| `CC-CTX-07` | Instrução crítica vai no **topo** do `SKILL.md`: o truncamento pós-compactação preserva o início do arquivo. |
| `CC-CTX-08` | `ultrathink` é a única palavra-chave de raciocínio reconhecida no prompt. `"think hard"` não é. |
| `CC-CTX-09` | Editar CLAUDE.md ou output style no meio da sessão **não aplica**. Vale no próximo `/clear`, `/compact` ou restart. |

### 6.2 Sessão e verificação — `CC-SES-*`

| ID | Regra |
| --- | --- |
| `CC-SES-01` | Toda tarefa entregue tem uma verificação que o **Claude** roda, e a entrega mostra a evidência dela. Sem verificação, não faz merge. |
| `CC-SES-02` | Plan mode para incerteza de abordagem, mudança em vários arquivos, ou código desconhecido. |
| `CC-SES-03` | Se o diff cabe em uma frase, não planeje. |
| `CC-SES-04` | Feature grande: entrevista → `SPEC.md` → **sessão nova** para executar. |
| `CC-SES-05` | O prompt nomeia arquivo, cenário, restrição e o padrão existente a seguir. |
| `CC-SES-06` | Após **duas** correções falhas no mesmo ponto: `/clear` e novo prompt. Não uma terceira correção. |
| `CC-SES-07` | Revisão de resultado roda em **contexto fresco**, sem o raciocínio que produziu a mudança. |
| `CC-SES-08` | Aprovação repetida da mesma ação é bug de configuração: allowlist ou sandbox. |
| `CC-SES-09` | Uma sessão por linha de trabalho, nomeada com `/rename`. |
| `CC-SES-10` | O prompt do revisor delimita o que **conta** como achado. Sem isso, o revisor produz over-engineering. |
| `CC-SES-11` | Verificação contra o app rodando (`/verify`) não é substituível por suíte de testes verde. |
| `CC-SES-12` | Execução longa sem supervisão precisa de condição de parada externa ao julgamento do Claude: `/goal` ou Stop hook. |

### 6.3 Configuração — `CC-CFG-*`

| ID | Regra |
| --- | --- |
| `CC-CFG-01` | Critério de inclusão no CLAUDE.md: *"remover esta linha faria o Claude errar?"* Se não, corte. |
| `CC-CFG-02` | CLAUDE.md abaixo de 200 linhas. Acima disso a adesão cai. |
| `CC-CFG-03` | Instrução sempre válida → CLAUDE.md. Conhecimento ocasional → skill. |
| `CC-CFG-04` | Regra ignorada apesar de existir é sintoma de arquivo longo, não de falta de ênfase. |
| `CC-CFG-05` | O que precisa acontecer sempre, sem exceção, é hook — não linha de CLAUDE.md. |
| `CC-CFG-06` | Ênfase (`IMPORTANT`) só funciona em poucas linhas. Enfatizar muitas anula todas. |
| `CC-CFG-07` | Skill com efeito colateral leva `disable-model-invocation: true`. |
| `CC-CFG-08` | Para falar com serviço externo, CLI antes de MCP. |
| `CC-CFG-09` | Linguagem tipada: plugin de code intelligence. Troca leitura de arquivo por consulta de símbolo. |
| `CC-CFG-10` | Em repositório grande, o escopo é configurado — não confiado ao acaso da exploração. |

### 6.4 Paralelismo — `CC-PAR-*`

| ID | Regra |
| --- | --- |
| `CC-PAR-01` | Exploração que lê muitos arquivos roda em subagente. |
| `CC-PAR-02` | Tarefas paralelas que tocam os mesmos arquivos rodam em worktrees separadas. |
| `CC-PAR-03` | Quando o plano precisa de laço, ramificação ou verificação cruzada, ele vira **script** (workflow) — não julgamento turno a turno. |
| `CC-PAR-04` | Investigação sem escopo é antipadrão. Delimite ou delegue. |

### 6.5 Automação — `CC-AUT-*`

| ID | Regra |
| --- | --- |
| `CC-AUT-01` | Chamada em script ou CI usa `--bare`. Sem ele, `claude -p` roda hooks e conecta MCP do repositório mesmo em pasta não confiada. |
| `CC-AUT-02` | Execução não supervisionada restringe ferramentas com `--allowedTools`. |
| `CC-AUT-03` | Fan-out se valida em 2–3 itens antes de rodar no conjunto inteiro. |

---

## 7. Fora de escopo e limitações

### Superfície instável, deliberadamente sem procedimento

Por decisão de recorte, a estrutura cobre só o que a doc não marca como instável. Estas features existem, algumas são alavancas grandes, e **não** estão documentadas aqui — se você for depender de uma, vá à fonte, porque forma e disponibilidade podem mudar entre versões:

| Feature | Estágio declarado na doc |
| --- | --- |
| Agent view (`claude agents`, `/background`) | research preview |
| Agent teams | experimental, **desativado por default** |
| Ultrareview (`/code-review ultra`) | research preview |
| Code Review do GitHub (bot de PR) | research preview, só Team e Enterprise |
| Routines | research preview |
| Channels | research preview |
| Hooks do tipo `agent` | experimental — a própria doc recomenda hook de `command` em produção |

### O que esta estrutura não cobre por recorte

Instalação e troubleshooting de instalação, deployment corporativo (Bedrock, Google Cloud Agent Platform, Microsoft Foundry), gateways de LLM, managed settings e rollout organizacional, Agent SDK, acessibilidade, e customização de interface (statusline, keybindings, temas). É a maior parte das 189 páginas indexadas, e não muda a qualidade do resultado individual.

### Precisão dos números

Os valores da [§ 2](#2-o-que-já-está-no-seu-contexto-antes-de-você-digitar) são **representativos**, não medidos no seu ambiente: a própria doc declara que a visualização usa números de referência. Para os seus, `/context`. Os limites normativos (200 linhas de CLAUDE.md, 25 KB de `MEMORY.md`, caps de re-injeção de skill, 8 blocks de Stop hook) são valores declarados na doc e verificados em 2026-08-21.

### Sensibilidade a versão

A doc anota comportamento por versão de patch (`v2.1.198`, `v2.1.211`, `v2.1.237`…) com frequência incomum — vários comportamentos descritos aqui mudaram em patches de 2026. Antes de tratar um detalhe fino como estável, confira a versão: `/status`.

---

## Relacionados

- [Claude API Docs](claude-api-docs.md) — tool use na API da Anthropic; é a camada de baixo, não o Claude Code
- `Skill` — índice das skills do vault, que consomem as notas de `docs/` como fonte
-
