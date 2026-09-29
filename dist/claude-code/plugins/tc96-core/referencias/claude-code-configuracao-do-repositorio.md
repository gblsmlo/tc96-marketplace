---
titulo: Claude Code - Configuração do Repositório
Link: https://code.claude.com/docs/pt/features-overview
tags:
  - claude-code
  - ia
  - configuracao
  - skills
  - hooks
  - mcp
  - monorepo
  - agent-context
source: "Documentação oficial do Claude Code — Extend Claude Code, How Claude remembers your project (memory), Extend Claude with skills, Automate actions with hooks + Hooks reference, Create custom subagents, Connect Claude Code to tools via MCP, Set up Claude Code in a monorepo or large codebase"
verificado-em: 2026-08-21
---

# Claude Code — Configuração do Repositório

> Satélite de [Claude Code](claude-code.md). Cobre o que se escreve **em disco** para render em toda sessão: CLAUDE.md, rules, auto memory, skills, hooks, subagentes customizados, MCP, plugins, e o kit de escopo para repositório grande.
>
> **A pergunta que organiza a nota** não é "que features existem", e sim **quando cada mecanismo é o certo**. Seis mecanismos podem guardar a mesma instrução, e escolher errado custa contexto em toda sessão ou faz a instrução não ser seguida.

---

## 1. O critério de escolha

Antes de qualquer sintaxe: o **gatilho** decide o mecanismo.

| O que aconteceu | O que adicionar | Por quê |
| --- | --- | --- |
| Claude errou uma convenção **duas vezes** | linha no **CLAUDE.md** | é regra sempre válida |
| Você digita o mesmo prompt para iniciar tarefa | **skill** invocável | é workflow, não convenção |
| Você colou o mesmo playbook pela terceira vez | **skill** | é referência ocasional |
| Você copia dado de aba que o Claude não vê | **MCP server** | é dado externo |
| Claude lê muitos arquivos para achar um símbolo | **plugin de code intelligence** | é navegação, não conhecimento |
| Tarefa lateral inunda a conversa | **subagente** | é isolamento de contexto |
| Você quer que aconteça **sempre**, sem pedir | **hook** | instrução é conselho; hook é determinístico |
| Segundo repositório precisa do mesmo setup | **plugin** | é empacotamento |

E o custo de contexto de cada um, que é a outra metade da decisão:

| Mecanismo | Quando carrega | O que carrega | Custo |
| --- | --- | --- | --- |
| **CLAUDE.md** | abertura | conteúdo **inteiro** | **em todo request** |
| **Skills** | abertura + quando usada | descrições na abertura, corpo quando usada | baixo (zero com `disable-model-invocation`) |
| **MCP** | abertura | nomes de ferramenta; schema on demand | baixo até usar |
| **Code intelligence** | após edit e on demand | diagnóstico e localização de símbolo | baixo — **reduz** leitura em outro lugar |
| **Subagentes** | quando invocado | janela própria | isolado do principal |
| **Hooks** | no disparo | nada (roda fora) | **zero**, salvo se devolver output |

**A assimetria a internalizar:** CLAUDE.md é a única coluna que diz "em todo request". Tudo que você põe lá é cobrado para sempre. Tudo o mais é sob demanda.

---

## 2. CLAUDE.md

Arquivo que o Claude lê no início de **toda** conversa. `/init` gera um inicial a partir da estrutura do projeto; a partir daí o trabalho é **podar**.

Não há formato obrigatório. Mantenha curto e legível por humano:

```markdown
# Code style
- Use ES modules (import/export), não CommonJS (require)
- Desestruture imports quando possível

# Workflow
- Rode typecheck ao terminar uma série de mudanças
- Prefira rodar teste único, não a suíte inteira, por performance
```

### 2.1 O que entra e o que não entra

| ✅ Incluir | ❌ Excluir |
| --- | --- |
| comandos Bash que o Claude não consegue adivinhar | qualquer coisa que ele descubra lendo o código |
| regras de estilo que **divergem** do default | convenção padrão da linguagem, que ele já conhece |
| instrução de teste e runner preferido | documentação de API detalhada (linke em vez disso) |
| etiqueta do repositório (nome de branch, convenção de PR) | informação que muda com frequência |
| decisão de arquitetura específica do projeto | explicação longa ou tutorial |
| peculiaridade do ambiente (variável obrigatória) | descrição arquivo por arquivo da base |
| pegadinha ou comportamento não óbvio | prática autoevidente ("escreva código limpo") |

**O critério por linha:** *"remover isso faria o Claude errar?"* Se não, corte (`CC-CFG-01`).

### 2.2 Os diagnósticos

A doc dá três sintomas com causa diferente, e confundi-los custa tempo:

| Sintoma | Causa | Correção |
| --- | --- | --- |
| Claude **insiste** em fazer algo contra uma regra que existe | o arquivo está longo demais e a regra se perdeu no ruído | podar (`CC-CFG-04`) |
| Claude **pergunta** algo que o CLAUDE.md responde | a redação está ambígua | reescrever a linha |
| Claude ignora **uma** instrução específica | falta ênfase naquela linha | `IMPORTANT` **naquela linha só** |

> **Ênfase se anula.** Se você enfatiza muitas linhas, nenhuma se destaca (`CC-CFG-06`).

**CLAUDE.md inflado faz o Claude ignorar suas instruções reais.** Trate como código: revise quando algo der errado, pode regularmente, e teste mudanças observando se o comportamento realmente mudou. Para arquivo versionado, `/doctor` propõe cortes — remove o que é derivável da base (layout de diretórios, lista de dependências, visão de arquitetura) e mantém pegadinhas, racional, e convenções que divergem do default da ferramenta.

### 2.3 Limites concretos

| Limite | Valor |
| --- | --- |
| Recomendação de tamanho | **abaixo de 200 linhas** (`CC-CFG-02`) |
| Carrega inteiro até | 4 MiB |
| Acima de 4 MiB | **é ignorado** |

> **`@path` imports não economizam contexto.** Os arquivos importados carregam no launch do mesmo jeito. Dividir ajuda a **manter**, não a economizar. Quem reduz é rule com `paths:` ou skill.

Onde os arquivos podem morar: o Claude lê CLAUDE.md do diretório de trabalho até a raiz, e descobre os aninhados em subdiretórios conforme acessa arquivos deles. O Claude Code também reconhece `AGENTS.md`.

---

## 3. `.claude/rules/`

Para projeto maior, instruções em múltiplos arquivos — modular e mais fácil de manter em equipe:

```text
seu-projeto/
├── .claude/
│   ├── CLAUDE.md
│   └── rules/
│       ├── code-style.md
│       ├── testing.md
│       └── security.md
```

Todos os `.md` são descobertos recursivamente. **Rule sem `paths:` carrega no launch com a mesma prioridade do `.claude/CLAUDE.md`** — ou seja, não economiza nada em relação a estar no CLAUDE.md; a vantagem é organizacional.

**Rule com `paths:` é o mecanismo que economiza:**

```markdown
---
paths:
  - "src/api/**/*.ts"
---

# Regras de API
- Todo endpoint precisa de validação de entrada
- Use o formato padrão de resposta de erro
```

Ela dispara **quando o Claude lê arquivo que casa o padrão** — não em todo uso de ferramenta.

| Padrão | Casa |
| --- | --- |
| `**/*.ts` | todo TypeScript em qualquer diretório |
| `src/**/*` | tudo abaixo de `src/` |
| `*.md` | markdown na raiz do projeto |
| `src/components/*.tsx` | componentes num diretório específico |
| `src/**/*.{ts,tsx}` | expansão de chaves — **cada grupo multiplica** o número de padrões |

> **Orçamento de expansão:** a lista `paths:` de uma rule compartilha um orçamento de **1.000 padrões expandidos e 4 MiB**. Padrão que estouraria o orçamento é usado **sem expandir**, e as chaves literais não casam arquivo nenhum. Padrões sem chaves não contam.

**Precedência:** rules de usuário em `~/.claude/rules/` carregam **antes** das de projeto, dando prioridade maior às de projeto.

**Symlink funciona** — dá para manter um conjunto compartilhado e linkar em vários projetos:

```bash
ln -s ~/shared-claude-rules .claude/rules/shared
```

> **O trade-off que a § 2 de [Claude Code - Contexto e Cache](claude-code-contexto-e-cache.md) detalha:** rule com `paths:` economiza contexto e **não sobrevive à compactação** — ela entra no histórico, e o histórico é o que a compactação resume. Se a regra é crítica, tire o `paths:` ou mova para o CLAUDE.md da raiz (`CC-CTX-04`).

---

## 4. Auto memory

O Claude acumula conhecimento entre sessões sem você escrever nada, salvando quatro tipos de nota (registrados no campo `type` do frontmatter):

| Tipo | Guarda |
| --- | --- |
| `user` | seu papel, expertise, preferências de trabalho |
| `feedback` | correções que você deu, e abordagens que você confirmou |
| `project` | trabalho em andamento, prazos, decisões que ele não deriva do código nem do git |
| `reference` | onde achar informação fora do projeto (issue tracker, dashboard) |

Ele **pula** o que é derivável da base (arquitetura, caminhos, correções de debug) e o que os seus CLAUDE.md já dizem. E não salva algo toda sessão — decide pelo critério de ser útil numa conversa futura.

**Limites de carregamento:**

- Só as **primeiras 200 linhas de `MEMORY.md`, ou os primeiros 25 KB**, o que vier antes, carregam na abertura de toda conversa.
- Frontmatter YAML e comentários HTML de bloco são **removidos antes** da medição, então não contam.
- **Arquivos de tópico não carregam na abertura.** O Claude os lê sob demanda.
- A auto memory da conversa principal **não** vai para subagente — exceto num fork, que herda a conversa e o system prompt do pai.

Ligada por default. `/memory` alterna e abre os arquivos para leitura e edição — é markdown puro. Para desligar por projeto, `autoMemoryEnabled: false` nas settings do projeto.

---

## 5. Skills

Skill é capacidade extra no repertório do Claude. Pode ser **referência** (guia de estilo da API) ou **workflow invocável** (`/deploy`). Um diretório com um `SKILL.md` em `.claude/skills/`:

```markdown
---
name: api-conventions
description: Convenções de design de API REST para nossos serviços
---
# Convenções de API
- kebab-case em caminhos de URL
- camelCase em propriedades JSON
- Sempre paginar endpoints de listagem
- Versionar na URL (/v1/, /v2/)
```

### 5.1 Frontmatter

Todos os campos são opcionais; só `description` é recomendado, porque é por ela que o Claude decide quando aplicar.

| Campo | Faz |
| --- | --- |
| `name` | nome exibido. Default: nome do diretório |
| `description` | o que faz e quando usar. **É o que o Claude lê para decidir** |
| `when_to_use` | contexto adicional: frases-gatilho, exemplos de pedido |
| `argument-hint` | dica no autocomplete (`[issue-number]`) |
| `arguments` | argumentos posicionais nomeados, para substituição `$nome` |
| `disable-model-invocation` | `true` impede o Claude de carregar sozinho — só você invoca com `/nome` |
| `user-invocable` | `false` quando **só** o Claude deve invocar; some do menu `/` |
| `allowed-tools` | ferramentas liberadas sem pedir permissão **no turno** que invoca a skill. O grant expira na sua mensagem seguinte |
| `disallowed-tools` | ferramentas removidas do repertório enquanto a skill está ativa |
| `model` | modelo enquanto a skill está ativa. Vale pelo resto do turno, não é salvo |
| `effort` | nível de effort enquanto ativa. Sobrepõe a sessão |
| `context: fork` | roda em contexto de subagente forkado |

> Booleanos aceitam `yes`, `no`, `on`, `off`, `1`, `0` em qualquer caixa, além de `true`/`false`.

**`disable-model-invocation: true` para skill com efeito colateral** (`CC-CFG-07`). Duas razões: economiza contexto — nada carrega até você invocar — e garante que só você dispara. Para skill que você não escreveu, `skillOverrides` nas settings faz o mesmo sem editar o arquivo dela.

**Como o Claude escolhe:** ele casa a sua tarefa contra as **descrições**. Se as descrições são vagas ou se sobrepõem, ele carrega a errada ou perde a que ajudaria. Para forçar uma específica, invoque com `/nome`.

**Em subagente, skills funcionam diferente:** as listadas no campo `skills` do subagente são **pré-carregadas por inteiro** no launch dele, em vez de sob demanda.

**Instrução crítica vai no topo do arquivo** — o truncamento pós-compactação preserva o começo (`CC-CTX-07`).

### 5.2 Skill como workflow

```markdown
---
name: fix-issue
description: Corrige uma issue do GitHub
disable-model-invocation: true
---
Analise e corrija a issue do GitHub: $ARGUMENTS.

1. Use `gh issue view` para obter os detalhes
2. Entenda o problema descrito
3. Busque os arquivos relevantes
4. Implemente a correção
5. Escreva e rode testes que verifiquem
6. Garanta lint e type check
7. Mensagem de commit descritiva
8. Push e abra um PR
```

Invoca com `/fix-issue 1234`.

### 5.3 Skills embutidas

Vêm em toda sessão, e são prompt-based — dão instrução detalhada ao Claude e deixam ele orquestrar com as próprias ferramentas. As de maior alavancagem para performance:

| Skill | Faz |
| --- | --- |
| `/doctor` | checkup do setup; diagnostica e pode corrigir; propõe cortes no CLAUDE.md |
| `/code-review` | revisa o diff atual em subagente fresco. Aceita nível, `--fix`, `--comment`, e alvo (PR, branch, path) |
| `/verify` | constrói e roda o app para confirmar a mudança, sem cair para testes |
| `/run` | levanta e dirige o app |
| `/run-skill-generator` | grava a receita de build/launch do seu projeto como skill versionada |
| `/batch <instrução>` | decompõe uma mudança grande em 5 a 30 unidades, uma subagente por unidade em worktree isolada, cada uma abre PR |
| `/simplify` | revisa o código alterado buscando limpeza e aplica |
| `/security-review` | analisa o diff do branch buscando vulnerabilidade |
| `/loop [intervalo] <prompt>` | repete um prompt enquanto a sessão está aberta |
| `/fewer-permission-prompts` | varre transcripts e propõe allowlist priorizada |

Para desligar todas: `disableBundledSkills` (exceto `/doctor`).

---

## 6. Hooks

Hooks rodam automaticamente em pontos do ciclo do Claude Code. **A diferença que justifica existirem:** instrução de CLAUDE.md é *advisory*; hook é **determinístico** e garante que a ação aconteça (`CC-CFG-05`).

### 6.1 Eventos

| Evento | Dispara |
| --- | --- |
| `SessionStart` | sessão começa ou é retomada — matchers: `startup`, `resume`, `clear`, `compact`, `fork` |
| `UserPromptSubmit` | você submete um prompt, antes de o Claude processar. **Pode bloquear** |
| `PreToolUse` | antes de uma chamada de ferramenta. **Pode bloquear** |
| `PermissionRequest` | quando uma chamada precisa de decisão de permissão |
| `PostToolUse` | depois de uma chamada bem-sucedida |
| `PostToolUseFailure` | depois de uma chamada que falhou |
| `Notification` | quando o Claude Code notifica |
| `SubagentStop` | quando um subagente termina |
| `Stop` | quando o Claude termina de responder |
| `StopFailure` | quando o turno acaba por erro de API |
| `PreCompact` | **antes** da compactação |
| `SessionEnd` | sessão termina |

Tipos de hook: **command** (script), **prompt-based**, e **HTTP**. Existe também um tipo `agent`, mas é **experimental** — a própria doc recomenda `command` para produção, e por isso ele está fora do escopo desta estrutura.

### 6.2 As receitas que mais rendem

**Reinjetar contexto depois da compactação.** A compactação resume, e isso perde detalhe. Um `SessionStart` com matcher `compact` recoloca o que não pode se perder — o stdout do comando entra no contexto do Claude:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "compact",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Lembrete: use Bun, não npm. Rode bun test antes de commitar. Sprint atual: refactor de auth.'"
          }
        ]
      }
    ]
  }
}
```

Pode ser dinâmico — `git log --oneline -5` para lembrar os commits recentes. Para injetar em **toda** abertura, o lugar é o CLAUDE.md, não isto.

**Filtrar output antes do Claude ver.** É a receita de maior impacto em contexto: em vez de o Claude ler um log de 10.000 linhas, um hook faz `grep ERROR` e devolve só as linhas que casam — de dezenas de milhares de tokens para centenas.

**Outras que a doc documenta:** formatar código após cada edit · bloquear escrita em diretório protegido · auditar mudança de configuração · recarregar ambiente quando o diretório muda · auto-aprovar prompts de permissão específicos · notificar quando o Claude precisa de você.

**O Claude escreve hooks para você.** *"Escreva um hook que roda eslint depois de cada edição de arquivo"* ou *"escreva um hook que bloqueia escrita na pasta de migrations"*. `/hooks` lista o que está configurado.

---

## 7. Subagentes customizados

Rodam em contexto próprio, com o próprio conjunto de ferramentas permitidas. Em `.claude/agents/`:

```markdown
---
name: security-reviewer
description: Revisa código buscando vulnerabilidades
tools: Read, Grep, Glob, Bash
model: opus
---
Você é um engenheiro de segurança sênior. Revise o código buscando:
- Vulnerabilidades de injeção (SQL, XSS, comando)
- Falhas de autenticação e autorização
- Segredos ou credenciais no código
- Tratamento inseguro de dados

Forneça referências de linha específicas e correções sugeridas.
```

Campos úteis além desses: `skills` (pré-carrega skills no launch), `memory` (auto memory própria, em diretório separado), `effort`.

**O que carrega no startup de um subagente:** o system prompt **dele**, não o do Claude Code inteiro · o conteúdo integral das skills do campo `skills:` · CLAUDE.md e git status — **exceto** nos agentes embutidos Explore e Plan, que omitem os dois · e o que o agente líder passar no prompt.

**Para tarefa simples, `model: haiku`.** É a economia mais direta disponível em subagente.

Invocar explicitamente: *"use um subagente para revisar isso buscando problemas de segurança"*.

---

## 8. MCP

Conecta serviços externos: ler documento de design no Drive, atualizar ticket no Jira, consultar banco, integrar design do Figma.

```bash
claude mcp add --transport http notion https://mcp.notion.com/mcp
```

**Tool search está ligado por default**, e é o que torna MCP barato: só nomes de ferramenta e instruções de servidor entram no contexto; os schemas JSON completos ficam **deferidos** até o Claude precisar de uma ferramenta específica. Consequência de cache: com tools deferidas, servidor conectando ou desconectando **não invalida** o prefixo (ver § 3 de [Claude Code - Contexto e Cache](claude-code-contexto-e-cache.md)).

**Mesmo assim, CLI vem antes de MCP** (`CC-CFG-08`). `gh`, `aws`, `gcloud`, `sentry-cli` não adicionam listagem por ferramenta nenhuma. Sem o `gh`, o Claude ainda usa a API do GitHub, mas requisição não autenticada bate em rate limit. E o Claude aprende CLI que não conhece: *"use `foo-cli --help` para aprender a ferramenta, então resolva A, B, C"*.

`/mcp` mostra status de conexão e desabilita servidor que você não está usando. `/context all` mostra quantos tokens cada ferramenta carregada consome.

---

## 9. Plugins

Camada de **empacotamento**: um plugin agrupa skills, hooks, subagentes e MCP servers numa unidade instalável. Skills de plugin são namespaced (`/meu-plugin:review`), então vários coexistem. Use quando o mesmo setup deve valer em vários repositórios, ou para distribuir via marketplace.

`/plugin` abre o menu. **Se você trabalha com linguagem tipada, instale um plugin de code intelligence** (`CC-CFG-09`) — o Claude ganha a ferramenta LSP, navegação precisa de símbolo, e detecção automática de erro de tipo depois de cada edit, sem rodar compilador.

`/reload-plugins` aplica mudança sem restart. Se o reload fosse causar releitura completa do contexto, o Claude Code avisa e **não aplica** — `--force` aplica de todo modo.

---

## 10. Repositório grande e monorepo

Os defaults são afinados para projeto pequeno. Numa base grande eles enchem a janela de instrução e leitura **sem relação com a tarefa** (`CC-CFG-10`). O kit, e cada item é independente e acumulável:

| Eu quero | Use |
| --- | --- |
| carregar só as convenções do código que eu toco | **CLAUDE.md por diretório** |
| excluir CLAUDE.md de pacotes que eu nunca toco | `claudeMdExcludes` |
| impedir o Claude de abrir build output, código gerado e vendored | **deny rules de `Read`** em `permissions.deny` |
| achar definição e chamadores pelo language server em vez de varrer arquivo | **plugin de code intelligence** |
| fazer checkout só dos diretórios que a tarefa precisa | `worktree.sparsePaths` |
| ler e editar pacote irmão ou outro repositório na mesma sessão | `--add-dir` ou `additionalDirectories` |
| dar procedimento de uma área que carrega só quando relevante | **skills por diretório** |
| trocar muitos CLAUDE.md por um conjunto que todos instalam | **plugin em marketplace interno** |

> **Leia isto primeiro:** **onde você inicia o `claude`** determina quais arquivos ele lê e edita sem grant adicional, quais CLAUDE.md carregam na abertura, e quais settings de projeto valem. É a decisão que posiciona todas as outras.

### 10.1 CLAUDE.md por diretório ou rule com `paths:`?

As duas resolvem "carregar só o relevante". A diferença operacional está na compactação: **CLAUDE.md aninhado e rule com `paths:` são igualmente perdidos** e recarregam quando o Claude lê arquivo da área. A escolha é de organização — arquivo por pacote (segue a estrutura do repositório) ou arquivo por tema com glob (atravessa pacotes).

---

## 11. Regras normativas desta nota

Canônicas na § 6.3 de [Claude Code](claude-code.md). Aqui, o critério de revisão:

| ID | Como auditar |
| --- | --- |
| `CC-CFG-01` | percorra o CLAUDE.md linha a linha perguntando se remover causaria erro |
| `CC-CFG-02` | `wc -l CLAUDE.md` — acima de 200, há trabalho a fazer |
| `CC-CFG-03` | procure no CLAUDE.md conhecimento que só vale em algumas tarefas: é skill |
| `CC-CFG-04` | se há regra sendo violada e ela **existe** no arquivo, o problema é tamanho |
| `CC-CFG-05` | procure no CLAUDE.md instrução com "sempre" ou "nunca" que dá para verificar por script: é hook |
| `CC-CFG-06` | conte os `IMPORTANT`. Mais de dois ou três, nenhum funciona |
| `CC-CFG-07` | toda skill com efeito colateral tem `disable-model-invocation: true` |
| `CC-CFG-08` | há MCP server fazendo o que um CLI instalado faria |
| `CC-CFG-09` | projeto tipado sem plugin de code intelligence |
| `CC-CFG-10` | `/context` numa sessão típica mostra CLAUDE.md de pacotes que a tarefa não toca |

---

## Relacionados

- [Claude Code](claude-code.md) — hub: checklist e árvore de decisão de mecanismo
- [Claude Code - Contexto e Cache](claude-code-contexto-e-cache.md) — o que sobrevive à compactação, e por que isso muda onde escrever a regra
- [Claude Code - Paralelismo e Escala](claude-code-paralelismo-e-escala.md) — subagentes em operação
- [Claude Code - Automação Externa](claude-code-automacao-externa.md) — o que acontece com esta configuração sob `claude -p`
