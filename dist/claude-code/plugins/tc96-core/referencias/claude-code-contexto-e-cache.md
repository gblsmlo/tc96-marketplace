---
titulo: Claude Code - Contexto e Cache
Link: https://code.claude.com/docs/pt/context-window
tags:
  - claude-code
  - ia
  - contexto
  - cache
  - performance
  - agent-context
source: "Documentação oficial do Claude Code — Explore the context window, How Claude Code uses prompt caching, Model configuration (effort, extended thinking, extended context, auto-compaction), Manage costs (reduce token usage)"
verificado-em: 2026-08-21
---

# Claude Code — Contexto e Cache

> Satélite de [Claude Code](claude-code.md). Cobre o recurso que a doc declara como **a** restrição: a janela de contexto. E o mecanismo que decide se cada turno é rápido ou lento: o prompt cache.
>
> **Por que os dois moram na mesma nota.** São o mesmo objeto visto de dois ângulos. A janela é *o que* o modelo enxerga; o cache é *o que não precisa ser reprocessado*. As duas otimizações se contradizem em um ponto exato — compactar libera janela e **destrói** cache — e é impossível decidir bem sobre uma sem a outra na mão.

---

## 1. A anatomia de um request

O modelo não lembra nada entre requests. Toda mensagem que você envia reenvia **tudo**: system prompt, contexto de projeto, cada mensagem anterior, cada resultado de ferramenta, e o seu texto novo. O conteúdo novo entra no fim.

O cache existe porque a maior parte de cada request é idêntica ao anterior. A API casa o **prefixo** — o início do request — contra o que processou recentemente. O casamento é **exato**: uma mudança em qualquer ponto recomputa tudo o que vem depois. **Não existe cache por arquivo nem por segmento.**

Por isso o Claude Code ordena o request colocando primeiro o que muda menos:

| Camada | Conteúdo | Muda quando |
| --- | --- | --- |
| **System prompt** | instruções centrais, definições de ferramenta, output style | o conjunto de ferramentas carregadas muda, ou o Claude Code é atualizado |
| **Contexto de projeto** | CLAUDE.md, auto memory, rules sem escopo | a sessão começa, ou depois de `/clear` e `/compact` |
| **Conversa** | suas mensagens, respostas do Claude, resultados de ferramenta | todo turno |

**A assimetria que governa tudo:** mudança na camada de conversa deixa as duas de cima cacheadas. Mudança no system prompt invalida **tudo**, porque todo o resto passou a ficar atrás de um prefixo diferente.

Duas configurações não são texto do prompt e ainda assim entram na chave do cache: **modelo** e **nível de effort**. Cada combinação tem seu próprio cache.

---

## 2. O que sobrevive à compactação

Quando a compactação roda, o histórico é substituído por um resumo. O que acontece com as suas instruções depende de **como elas foram carregadas** — e essa tabela é a informação menos intuitiva de toda a documentação:

| Mecanismo | Depois da compactação |
| --- | --- |
| System prompt e output style | inalterados; não fazem parte do histórico |
| CLAUDE.md da raiz do projeto, rules sem escopo | **reinjetados do disco** |
| Auto memory | **reinjetada do disco** |
| Rules com `paths:` frontmatter | **perdidas** até um arquivo que casa ser lido de novo |
| CLAUDE.md aninhado em subdiretório | **perdido** até um arquivo daquele subdiretório ser lido de novo |
| Corpo de skill invocada | reinjetado, com **cap de 5.000 tokens por skill e 25.000 no total**; o mais antigo cai primeiro |
| Hooks | não se aplica — rodam como código, não como contexto |

Três consequências operacionais:

1. **Rule com `paths:` é frágil por desenho.** Ela carrega quando o Claude lê um arquivo que casa o glob, ou seja, entra no **histórico** — e o histórico é justamente o que a compactação resume. Se uma regra precisa sobreviver, tire o `paths:` ou mova para o CLAUDE.md da raiz (`CC-CTX-04`).
2. **O truncamento de skill preserva o começo do arquivo.** Instrução que não pode se perder vai no **topo** do `SKILL.md`, não no fim (`CC-CTX-07`).
3. **Instrução dada só na conversa não sobrevive.** Se algo desapareceu depois de um `/compact`, foi dito só no chat, ou está num CLAUDE.md aninhado que ainda não recarregou, ou é rule com escopo que ainda não casou nenhum arquivo.

> A partir da v2.1.198 o request de sumarização herda a configuração de **extended thinking** da sessão. O thinking afeta só como o resumo é produzido; suas configurações não mudam depois.

---

## 3. O que invalida o cache

Cada item aqui produz **um** turno lento e caro, depois do qual o novo prefixo fica cacheado. Quase todos são evitáveis no meio de uma tarefa, uma vez que você sabe que têm custo.

| Ação | Por que invalida |
| --- | --- |
| **Trocar de modelo** (`/model`) | cada modelo tem cache próprio; o histórico é relido inteiro mesmo idêntico |
| **Trocar effort** (`/effort`) | o cache é chaveado por effort também |
| **Ligar fast mode** | adiciona header que entra na chave do cache |
| **Conectar/desconectar MCP** — *só se as tools estão no prefixo* | definição de ferramenta mora no system prompt |
| **Habilitar/desabilitar plugin que fornece MCP server** não deferido | idem |
| **Deny rule com nome de ferramenta puro** (`Bash`, `WebFetch`, `"*"`) | remove a ferramenta do contexto ⇒ muda o system prompt |
| **`/compact`** | por desenho: o novo histórico não compartilha prefixo com o antigo |
| **Atualizar o Claude Code** | nova versão normalmente muda system prompt ou definições de ferramenta |

**Detalhes que mordem:**

- **`opusplan` transforma cada toggle de plan mode numa troca de modelo.** A configuração resolve para Opus em plan mode e Sonnet na execução — então entrar e sair do plano começa um cache novo cada vez.
- **Retomar sessão depois de um upgrade reprocessa o histórico inteiro sem cache algum.** O custo escala com o tamanho da conversa: *o primeiro turno de volta numa sessão longa pode ser o request mais caro que você já mandou.* Para controlar quando o upgrade se aplica: `DISABLE_AUTOUPDATER=1`.
- **Tools de MCP deferidas (o default) não invalidam nada.** Servidor conectando, desconectando ou mudando a lista de tools só **acrescenta** conteúdo. Isso deixa de valer se o tool search estiver indisponível ou desligado, ou se o servidor/tool estiver marcado `alwaysLoad` — aí qualquer mudança invalida, e ela pode acontecer **sem ação sua**: um processo stdio que morre, uma sessão HTTP que expira, uma reconexão automática.
- **Deny rule só invalida se casar na posição do nome da ferramenta.** `Bash(rm *)` não invalida; `Bash` invalida. Toda regra de `allow` e `ask` preserva — são checadas quando o Claude tenta a chamada, não no prefixo.
- **Editar a config de MCP não muda o cache por si.** A config nova só vale depois de um restart, e é aí que servidor conecta ou desconecta.

---

## 4. O que preserva o cache

Estas ações ou acrescentam no fim da conversa ou não tocam o request. É também a razão pela qual **certas mudanças de configuração só valem depois de reiniciar**:

| Ação | Nota |
| --- | --- |
| Editar arquivos do repositório | o conteúdo entra no contexto só quando o Claude lê; editar não muda a leitura anterior. O Claude Code acrescenta um `<system-reminder>` avisando que o arquivo mudou |
| **Editar CLAUDE.md no meio da sessão** | preserva o cache — **e também não aplica**. O Claude segue com a versão carregada na abertura. O conteúdo novo entra no próximo `/clear`, `/compact` ou restart |
| **Trocar output style** | mesma coisa: preserva e **não aplica** até `/clear` ou restart |
| Trocar permission mode | não muda system prompt nem definição de ferramenta. Exceção: plan mode com `opusplan` |
| Invocar skill ou command | injetam instrução como mensagem de usuário, no ponto da invocação |
| **`/recap`** | acrescenta o resumo como saída de comando em vez de substituir o histórico — ao contrário de `/compact` |
| **`/rewind`** | trunca de volta a um prefixo que **já é** o que o cache foi construído em cima. Acerta a entrada anterior |
| **`/cd`** | muda o diretório de trabalho da sessão **preservando** o prompt cache |
| Spawn de subagente | roda em janela própria |
| Toggle do `/advisor` | a definição dele fica **depois** do breakpoint de cache |

**A conclusão prática mais útil desta seção:** para abandonar um caminho que não deu certo, `/rewind` é estritamente melhor que `/compact`. Rewind volta a um prefixo já cacheado; compact constrói um novo (`CC-CTX-06`).

**E a pegadinha mais comum:** você edita o CLAUDE.md porque o Claude errou uma convenção, e o comportamento não muda. Não é o arquivo que está errado — é que ele foi lido na abertura da sessão e está em memória. Precisa de `/clear`, `/compact` ou restart (`CC-CTX-09`).

---

## 5. Vida e escopo do cache

**TTL.** O prefixo expira depois de um período de inatividade, e cada request que acerta o cache **reinicia** o contador — então o cache fica quente enquanto você trabalha.

| Como você autentica | TTL | Como mudar |
| --- | --- | --- |
| Assinatura Claude | **1 hora**, automático | — |
| API key, Bedrock, Google Cloud Agent Platform, Foundry, Claude Platform on AWS | **5 minutos** | `ENABLE_PROMPT_CACHING_1H=1` |
| Qualquer uma, forçando o curto | — | `FORCE_PROMPT_CACHING_5M=1` |

Se você passou do limite do plano e está consumindo *usage credits*, o Claude Code **cai sozinho para 5 minutos**, porque cache write de 1 hora custa mais. Para manter 1 hora nessa situação: `ENABLE_PROMPT_CACHING_1H=1`.

**Escopo.** No Claude Code o cache é efetivamente por **máquina + diretório**. O system prompt embute diretório de trabalho, plataforma, shell, versão do SO e caminhos de auto memory:

- Duas sessões em **diretórios diferentes** constroem prefixos diferentes e não se aproveitam.
- **Isso inclui worktrees do mesmo repositório** — cada worktree tem seu próprio diretório de trabalho. Paralelismo por worktree paga cache do zero em cada uma.
- Sessões **paralelas no mesmo diretório** constroem prefixos iguais e leem o cache uma da outra.
- Sessões **sequenciais** compartilham o prefixo só se o snapshot de git status da abertura casar — porque o system prompt também captura branch e commits recentes.

**Custo de `/compact` medido direito.** Para produzir o resumo, o Claude Code manda um request separado com o mesmo system prompt, ferramentas e histórico, mais a instrução de sumarizar no fim. **Com o cache quente, esse request lê o seu prefixo do cache** — então um `/compact` no meio da sessão custa uma fração do que o tamanho do contexto sugere, e gasta o tempo gerando o resumo. Depois de uma pausa maior que o TTL não há cache para ler, e o histórico inteiro é reprocessado como input não cacheado. **É por isso que `/compact` custa mais ao retomar uma sessão antiga.**

---

## 6. Effort, raciocínio e `ultrathink`

O nível de effort controla **raciocínio adaptativo**: o modelo decide se e quanto pensar em cada passo, conforme a complexidade.

| Modelo | Níveis |
| --- | --- |
| Fable 5, Opus 5, Sonnet 5, Opus 4.8, Opus 4.7 | `low`, `medium`, `high`, `xhigh`, `max` |
| Opus 4.6, Sonnet 4.6 | `low`, `medium`, `high`, `max` |

O default é **`high`** em todo modelo que suporta effort, exceto **Opus 4.7**, que é `xhigh`. Pedir um nível não suportado cai para o maior suportado abaixo (`xhigh` roda como `high` no Opus 4.6).

| Nível | Quando |
| --- | --- |
| `low` | tarefa curta, escopada, sensível a latência e **não** sensível a inteligência |
| `medium` | reduzir consumo em trabalho sensível a custo, aceitando trocar alguma capacidade |
| `high` | equilíbrio. O default |
| `xhigh` | raciocínio mais fundo, mais gasto de token |
| `max` | pode melhorar em tarefa exigente, mas tem **retorno decrescente e tendência a pensar demais**. Teste antes de adotar em geral |
| `ultracode` | **não é nível de effort** — é uma configuração do Claude Code: manda `xhigh` ao modelo **e** faz o Claude orquestrar dynamic workflows em toda tarefa substantiva |

`max` vale só na sessão atual, a menos que você use `CLAUDE_CODE_EFFORT_LEVEL`. Os outros persistem entre sessões quando definidos em sessão interativa.

**Precedência:** variável de ambiente > nível configurado > default do modelo. Frontmatter `effort` de skill ou de subagente sobrepõe a sessão, mas **não** a variável de ambiente.

**`ultrathink`.** Escrever `ultrathink` em qualquer ponto do prompt pede raciocínio mais profundo **naquele turno**, sem mexer no effort da sessão — e portanto **sem invalidar o cache**. É palavra-chave reconhecida: o Claude Code adiciona uma instrução em contexto. O nível enviado à API não muda.

> `"think"`, `"think hard"` e `"think more"` **não** são palavras-chave. Passam como texto comum de prompt (`CC-CTX-08`).

**Thinking.** `Option+T` (macOS) ou `Alt+T` alterna na sessão; `/config` salva o default como `alwaysThinkingEnabled`. `MAX_THINKING_TOKENS=0` desliga na API da Anthropic — **exceto no Fable 5, onde thinking não pode ser desligado de forma alguma**. `Ctrl+O` mostra o raciocínio. **Você paga por todo token de thinking gerado, mesmo colapsado ou redigido.**

---

## 7. Janela grande e limite de compactação

**Contexto de 1 milhão de tokens** existe em Fable 5, Sonnet 5, Opus 4.6 e posteriores, e Sonnet 4.6. Disponibilidade por plano:

| Plano | Opus com 1M | Sonnet 4.6 com 1M |
| --- | --- | --- |
| Max, Team, Enterprise | incluído | exige usage credits |
| Pro | exige usage credits | exige usage credits |
| API e pay-as-you-go | acesso total | acesso total |

Na API da Anthropic, Fable 5, Sonnet 5 e Opus 4.7+ **sempre** rodam com a janela de 1M. Para desligar: `CLAUDE_CODE_DISABLE_1M_CONTEXT=1` — o que também faz modelos de janela nativa de 1M passarem a ser tratados como 200K.

**`/autocompact`** define o quão cheia a janela chega antes da compactação automática. Aceita de **100K a 1M**, como contagem (`200000`), com sufixo (`500k`, `1M`) ou número nu de 100 a 1000 (`200` = 200.000). Três lugares:

- `/autocompact 500k` — salva em settings e aplica na sessão atual
- `--autocompact` no launch — sobrepõe o salvo sem alterá-lo
- `CLAUDE_CODE_AUTO_COMPACT_WINDOW` — precede comando, flag e setting

Sem configuração, o default compacta **no limite de contexto do modelo**. Exceções: sessões na nuvem compactam ao se **aproximar** do limite; Sonnet 4.6 e Opus 4.6 sem contexto estendido compactam na fronteira de 200K, e o mesmo vale para Opus 4.8 e Opus 5 quando rodam com janela de 200K (Bedrock, Google Cloud Agent Platform, Foundry).

> Compactar mais cedo é a escolha certa quando você prefere um resumo bom a um contexto cheio. Compactar no limite é o default porque preserva o máximo de histórico — mas é também o cenário em que a compactação cai no meio de uma tarefa.

---

## 8. Reduzir consumo, na ordem do retorno

### 8.1 Não colocar no contexto

- **Delegar leitura grande a subagente.** As leituras ficam na janela dele; só o resumo volta. Procedimento em [Claude Code - Paralelismo e Escala](claude-code-paralelismo-e-escala.md).
- **Hook que pré-processa.** Em vez do Claude ler um log de 10.000 linhas, um hook faz `grep ERROR` e devolve só as linhas que casam: de dezenas de milhares de tokens para centenas.
- **CLI antes de MCP.** `gh`, `aws`, `gcloud`, `sentry-cli` não adicionam listagem por ferramenta nenhuma. É a forma mais econômica de falar com serviço externo.
- **Plugin de code intelligence** em linguagem tipada. Uma ida à definição substitui um grep mais a leitura de vários candidatos — o consumo líquido **cai**.
- **Skill de visão geral do repositório.** Descrever arquitetura e diretórios numa skill evita o Claude gastar tokens explorando para descobrir a mesma coisa.
- **`claudeMdExcludes`** e **deny rules de `Read`** em build output, código gerado e vendored.

### 8.2 Tirar do contexto

- `/clear` entre tarefas não relacionadas — com `/rename` antes, para achar a sessão depois (`CC-CTX-01`).
- `/compact` com instrução de foco, em pausa natural (`CC-CTX-03`).
- Instrução de compactação fixa no CLAUDE.md, para o que não pode se perder no resumo:

```markdown
# Compact instructions

Ao compactar, preserve a lista completa de arquivos modificados e os comandos de teste.
```

- `/btw` para pergunta lateral: responde do que **já** está no contexto, sem entrar no histórico. Sem acesso a ferramenta, e funciona **enquanto o Claude trabalha**. `x` limpa o thread; `f` forka a pergunta para um subagente em background, aí com ferramentas (`CC-CTX-02`).

### 8.3 Medir

| Comando | Mostra |
| --- | --- |
| `/context` | grid de uso por categoria, com sugestões de otimização e quais CLAUDE.md e auto memory carregaram |
| `/context all` | quantos tokens cada ferramenta de MCP carregada consome |
| `/skills` + tecla `t` | skills **ordenadas por contagem de token** |
| `/usage` (alias `/cost`, `/stats`) | custo da sessão, limites do plano, atividade |
| statusline customizada | uso de contexto e taxa de acerto de cache, continuamente |

> **Armadilha de organização:** dividir o CLAUDE.md em `@path` imports **não reduz contexto** — os arquivos importados carregam no launch do mesmo jeito. Ajuda a manter, não a economizar. Quem reduz é rule com `paths:` ou skill.

---

## 9. Regras normativas desta nota

As regras `CC-CTX-*` são canônicas na § 6.1 de [Claude Code](claude-code.md). Aqui ficam as consequências que justificam cada uma:

| ID | Consequência de violar |
| --- | --- |
| `CC-CTX-01` | contexto obsoleto é reprocessado e cobrado em toda mensagem seguinte, e degrada as respostas |
| `CC-CTX-02` | pergunta de curiosidade fica no histórico para sempre, custando em cada turno |
| `CC-CTX-03` | a compactação cai no meio da tarefa e o resumo guarda o que a automação **supôs** ser importante |
| `CC-CTX-04` | a regra desaparece silenciosamente na compactação e o Claude passa a violá-la sem aviso |
| `CC-CTX-05` | um turno com zero acerto de cache, relendo o histórico inteiro |
| `CC-CTX-06` | `/compact` constrói prefixo novo onde `/rewind` acertaria um já quente |
| `CC-CTX-07` | a instrução mais importante da skill é o que o truncamento corta |
| `CC-CTX-08` | você acha que pediu raciocínio profundo e mandou texto decorativo |
| `CC-CTX-09` | você edita, testa, não muda nada, e conclui que a instrução não funciona |

---

## Relacionados

- [Claude Code](claude-code.md) — hub: checklist, árvores de decisão e a tabela de IDs
- [Claude Code - Configuração do Repositório](claude-code-configuracao-do-repositorio.md) — onde CLAUDE.md, rules e skills são escritos
- [Claude Code - Paralelismo e Escala](claude-code-paralelismo-e-escala.md) — a janela que não é a sua
