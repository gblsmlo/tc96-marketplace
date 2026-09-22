---
titulo: Claude Code - Automação Externa
Link: https://code.claude.com/docs/pt/headless
tags:
 - claude-code
 - ia
 - automacao
 - ci-cd
 - github-actions
 - code-review
 - agent-context
source: "Documentação oficial do Claude Code — Run Claude Code programmatically (headless), Best practices (automate and scale), Code Review (review a diff locally), Claude Code GitHub Actions, Claude Code in Slack, Remote Control, Use Claude Code with Chrome, Launch sessions from links"
verificado-em: 2026-08-21
---

# Claude Code — Automação Externa

> Satélite de [Claude Code](claude-code.md). Cobre tirar o trabalho do seu turno: script, pipeline, CI, revisão automática, e as superfícies que continuam a sessão fora do terminal.
>
> **O ponto que muda a forma de tudo aqui:** em execução não supervisionada você não pode corrigir a rota. As duas técnicas centrais desta nota — restringir ferramentas e validar numa fatia pequena — existem porque o laço de feedback que sustenta o uso interativo simplesmente não está disponível.
>
> **Recorte:** routines, channels e o Code Review do GitHub (bot de PR) estão fora — *research preview*. O `/code-review` **local** é estável e está aqui.

---

## 1. Modo não interativo

```bash
claude -p "Explique o que este projeto faz"
```

O run **ainda cria uma sessão resumível**, a menos que você passe `--no-session-persistence`.

### 1.1 `--bare`: o que você provavelmente deveria estar usando

`--bare` reduz o tempo de startup pulando a auto-descoberta de **hooks, skills, commands customizados, subagentes, plugins, MCP servers, auto memory e CLAUDE.md**.

> **A doc declara: `--bare` é o modo recomendado para chamada por script e por SDK, e vai se tornar o default do `-p` numa versão futura.**

Serve para CI e script onde você precisa do **mesmo resultado em toda máquina**. Um hook no `~/.claude` de um colega, ou um MCP server no `.mcp.json` do projeto, não roda — porque bare mode nunca os lê.

**E aqui está a razão de segurança, que é o argumento mais forte** (`CC-AUT-01`):

> Sem `--bare`, o Claude Code **roda os hooks do `.claude/settings.json` do projeto mesmo numa pasta que você nunca confiou**, porque uma sessão `-p` não mostra o diálogo de trust. Ele também **conecta os servidores do `.mcp.json` do projeto**, porque uma sessão `-p` também não consegue mostrar o prompt de aprovação por servidor.

Ou seja: `claude -p` num repositório de terceiro executa código de configuração dele sem te perguntar. `--bare` fecha isso.

**O que muda em bare mode:**

- **Não lê credencial OAuth nem o keychain.** Precisa de `ANTHROPIC_API_KEY`, ou um `apiKeyHelper` no `--settings`. Bedrock, Google Cloud Agent Platform e Foundry seguem lendo as credenciais próprias.
- O Claude tem acesso a Bash, leitura e edição de arquivo. O resto você passa por flag:

| Para carregar | Use |
| --- | --- |
| adição ao system prompt | `--append-system-prompt`, `--append-system-prompt-file` |
| settings | `--settings <arquivo-ou-json>` |
| MCP servers | `--mcp-config <arquivo-ou-json>` |
| subagentes | `--agents <json>` |
| plugin | `--plugin-dir <path>`, `--plugin-url <url>` |

- Exceção parcial: um diretório passado com `--add-dir` tem as skills do `.claude/skills/` dele carregadas, mas `.claude/commands/` e `.claude/agents/` continuam pulados.

```bash
claude --bare -p "Resuma o README.md" --allowedTools "Read"
```

---

## 2. Saída que um script consegue consumir

| `--output-format` | Devolve |
| --- | --- |
| `text` (default) | texto puro |
| `json` | um objeto JSON com o resultado no campo `result`, mais session ID e metadados |
| `stream-json` | um objeto JSON **por linha**, começando por um evento de init |

**Saída conformando a um schema** — o recurso que transforma o Claude num passo de pipeline confiável:

```bash
claude -p "Extraia os nomes das funções principais de auth.py" \
 --output-format json \
 --json-schema '{"type":"object","properties":{"functions":{"type":"array","items":{"type":"string"}}},"required":["functions"]}' \
 | jq '.structured_output'
```

Se o valor não é um JSON Schema válido, o `claude` sai com `Error: --json-schema is not a valid JSON Schema` seguido do diagnóstico do validador — falha cedo, não silenciosamente.

Encaixar num pipeline existente:

```bash
# Analisar log recente
tail -200 app.log | claude -p "Me avise no Slack se houver anomalias"

# Revisar só o que mudou
git diff main --name-only | claude -p "revise estes arquivos alterados buscando problemas de segurança"

# Alimentar outro comando
claude -p "<prompt>" --output-format json | seu_comando
```

`--verbose` durante o desenvolvimento; desligue em produção.

---

## 3. Fan-out por script

Quando você quer o laço na sua mão, em vez de no `/batch`. Três passos, e o terceiro é o que separa quem economiza de quem queima orçamento:

**1. Gerar a lista de tarefas em arquivo**, para o laço do passo seguinte poder ler:

```text
liste todos os arquivos Python que precisam de migração e salve a lista em files.txt
```

**2. Escrever o laço:**

```bash
for file in $(cat files.txt); do
 claude -p "Migre $file de React para Vue. Retorne OK ou FAIL." \
 --allowedTools "Edit,Bash(git commit *)"
done
```

**3. Testar em 2 ou 3 arquivos, refinar o prompt com o que deu errado, e só então rodar no conjunto inteiro** (`CC-AUT-03`).

`--allowedTools` restringe o que o Claude pode fazer — **e isso importa justamente porque a execução é não supervisionada** (`CC-AUT-02`). Em execução interativa, uma ação errada você interrompe; num laço de 2.000 iterações, não.

**Modo auto em `-p`.** Para execução ininterrupta com checagem de segurança em background:

```bash
claude --permission-mode auto -p "corrija todos os erros de lint"
```

Um modelo classificador revisa os comandos antes de rodarem, bloqueando escalada de escopo, infraestrutura desconhecida e ações dirigidas por conteúdo hostil, e deixando o trabalho rotineiro passar sem prompt. **Quando o classificador bloqueia repetidamente num run com `-p`, o Claude Code não encerra o run** — há um comportamento de fallback documentado na página de permission modes.

---

## 4. `/code-review` local

Revisa o diff atual, ou o alvo que você passar: número de PR, branch, ou path.

```text
/code-review
/code-review high --fix
/code-review --comment 1234
```

| Argumento | Faz |
| --- | --- |
| nível (`low` … `max`) | troca cobertura por confiança. Em `low` e `medium`, só os achados de maior confiança |
| `--fix` | aplica os achados na working tree depois da revisão |
| `--comment` | posta os achados como comentários inline no PR |
| alvo | PR, branch ou path |

**Detalhe de ergonomia:** sem nível digitado, a revisão **reusa o último nível que você digitou, mesmo de uma sessão anterior**, e o Claude Code avisa qual está reusando.

**Onde roda:** em background, por default. Roda em foreground quando você dispara outra revisão com uma em andamento, quando está em modo não interativo (`-p` ou Agent SDK — aí o Claude Code espera e inclui os achados na resposta), ou quando `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1`.

---

## 5. GitHub Actions

`/install-github-app` instala o app e pode configurar o workflow. Dois modos: **interativo** (responde a menção de `@claude` em issue e PR) e **automação** (roda em evento ou agendamento, incluindo rodar uma skill).

### 5.1 Práticas, na ordem em que importam

**Credenciais.** Nunca comitar API key ou token OAuth. Sempre GitHub Secrets: `anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}`. Dar ao workflow **só** as permissões que ele precisa, e revisar as mudanças do Claude antes do merge.

**Custo.** Cada run consome dois recursos: **minutos de GitHub Actions** (roda em runner hospedado) e **tokens**. As duas alavancas se reduzem dando contexto mais claro e limitando quanto trabalho cabe num run:

- pedidos `@claude` específicos, para o Claude precisar de menos turnos
- templates de issue, para o contexto vir de antemão
- **CLAUDE.md conciso — ele é lido em todo run**
- `--max-turns` em `claude_args`, para limitar iteração
- timeout no nível do workflow, contra job desgovernado
- controles de concorrência do GitHub, para limitar runs paralelos

**Padrões do projeto.** O CLAUDE.md da raiz vale aqui: o Claude segue as diretrizes dele ao criar PR e revisar. É o mesmo arquivo, com o mesmo custo por run — o que torna a poda da § 2 de [Claude Code - Configuração do Repositório](claude-code-configuracao-do-repositorio.md) uma questão de custo de CI, não só de qualidade local.

> **Nota de diagnóstico da doc:** CI não roda nos commits do Claude por default — é comportamento conhecido, com solução documentada na própria página.

---

## 6. Superfícies que continuam a sessão fora do terminal

Todas estáveis, e todas resolvem o mesmo problema: a sessão não estar presa a um lugar.

| Superfície | Serve para |
| --- | --- |
| **Remote Control** | continuar uma sessão **local** do celular ou de qualquer navegador. `/remote-control` |
| **Claude Code on the web** | rodar na nuvem, sem setup local; tarefa longa que você busca depois. `claude --teleport` traz para o terminal |
| **Desktop** | `/desktop` entrega a sessão do terminal para o app, para revisão visual de diff |
| **Slack** | mencionar `@Claude` com um relatório de bug e receber um pull request de volta. `/install-slack-app` |
| **Chrome** | depurar aplicação web ao vivo; screenshot como critério de verificação |
| **Deep links** | iniciar sessão a partir de um link |

**Chrome merece nota específica no contexto de performance:** ele fecha o laço de verificação para mudança visual. Screenshot comparado a um design é um critério que o Claude consegue ler e iterar contra — é o nível 1 de gate da § 1 de [Claude Code - Sessão e Verificação](claude-code-sessao-e-verificacao.md) aplicado a UI, onde teste não alcança.

---

## 7. Regras normativas desta nota

Canônicas na § 6.5 de [Claude Code](claude-code.md).

| ID | Como reconhecer a violação |
| --- | --- |
| `CC-AUT-01` | há `claude -p` em script ou CI sem `--bare` — e portanto rodando hooks e MCP do repositório sem trust |
| `CC-AUT-02` | laço não supervisionado sem `--allowedTools` |
| `CC-AUT-03` | o fan-out rodou no conjunto inteiro na primeira tentativa |

---

## Relacionados

- [Claude Code](claude-code.md) — hub: checklist e tabela de IDs
- [Claude Code - Paralelismo e Escala](claude-code-paralelismo-e-escala.md) — `/batch` e dynamic workflows, o paralelismo **dentro** da sessão
- [Claude Code - Sessão e Verificação](claude-code-sessao-e-verificacao.md) — os quatro níveis de gate, que é o que uma automação precisa ter antes de rodar sozinha
- [Claude Code - Configuração do Repositório](claude-code-configuracao-do-repositorio.md) — o CLAUDE.md que o CI lê em todo run
- [Github Actions](github-actions.md) — workflows e CI/CD em geral
