---
titulo: Claude Code - Sessão e Verificação
Link: https://code.claude.com/docs/pt/best-practices
tags:
  - claude-code
  - ia
  - verificacao
  - prompting
  - plan-mode
  - agent-context
source: "Documentação oficial do Claude Code — Best practices, Choose a permission mode, Keep Claude working toward a goal (/goal), Checkpointing, Manage sessions, Interactive mode, Skills (run and verify your app), Automate actions with hooks"
verificado-em: 2026-08-21
---

# Claude Code — Sessão e Verificação

> Satélite de [Claude Code](claude-code.md). Cobre a condução de uma sessão: como pedir, quando planejar, e — a parte que mais separa resultado bom de resultado plausível — **como o Claude sabe que terminou**.
>
> **A tese desta nota:** o Claude para quando o trabalho *parece* pronto. Sem uma verificação que ele mesmo possa rodar, "parece pronto" é o único sinal disponível, e **você** se torna o loop de verificação — cada erro espera você notar. Dar a ele algo que produz passa-ou-falha fecha o loop sozinho.

---

## 1. Os quatro níveis de gate

Esta é a estrutura mais importante da nota. Uma vez que a verificação existe, a decisão seguinte é **o quão forte ela prende a parada**:

| Nível | Mecanismo | Prende quanto | Custo de setup |
| --- | --- | --- | --- |
| **1. No prompt** | "escreva, rode os testes e itere até passar" | só naquele turno | zero — funciona hoje, em qualquer tarefa |
| **2. Na sessão** | condição de `/goal` | avaliador re-checa **a cada turno** até resolver | um comando |
| **3. Determinístico** | **Stop hook** que roda seu script | **bloqueia o fim do turno** até passar | escrever o script |
| **4. Segunda opinião** | subagente ou workflow de revisão | modelo fresco tenta **refutar** o resultado | escrever o prompt de revisão |

Cada passo troca setup por atenção sua. O nível 1 resolve o dia a dia. **Os níveis 2 e 3 são o que permite uma execução não supervisionada terminar correta sem você** (`CC-SES-12`).

O que serve como verificação: suíte de testes, exit code de build, linter, script que compara saída contra fixture, screenshot de browser comparado a um design. Qualquer coisa que devolva um sinal que o Claude consegue **ler na conversa**.

> **Limite do nível 3:** o Claude Code sobrepõe o Stop hook e encerra o turno depois de **8 bloqueios consecutivos**. O hook não é um laço infinito — é um gate com desistência.

### 1.1 Exigir evidência, não afirmação

Pedir que o Claude **mostre** a prova em vez de afirmar sucesso: a saída do teste, o comando que rodou e o que retornou, o screenshot do resultado. Revisar evidência é mais rápido que refazer a verificação — e é o único jeito que funciona para sessão que você não estava assistindo (`CC-SES-01`).

### 1.2 `/goal` — como funciona de verdade

`/goal` é um wrapper sobre um **Stop hook baseado em prompt**, escopado à sessão. A cada fim de turno, o Claude Code manda a condição e a conversa para o seu *small fast model* configurado (Haiku, por default, na API da Anthropic). O veredicto vem em três formas:

| Veredicto | O que acontece |
| --- | --- |
| **Not yet met** | o Claude continua, e toma o **motivo** como orientação para o turno seguinte |
| **Met** | o goal é limpo e uma entrada de conclusão vai para o transcript |
| **Impossible** | o avaliador julgou que a condição nunca pode ser satisfeita; o goal é limpo com o motivo registrado |

**Proteção contra laço:** se o Claude fica respondendo ao avaliador sem progredir (sem uso de ferramenta por vários turnos seguidos), o Claude Code para o laço, imprime um aviso, e devolve o controle **com o goal ainda ativo**.

**O que limpa o goal** (e portanto exige sua intervenção): falha de autenticação quando o Claude Code gerencia as próprias credenciais, saldo de crédito esgotado, overflow de contexto que a compactação automática não resolveu, e modelo indisponível. **Rate limit e servidor sobrecarregado não limpam** — o goal continua ativo.

**Trabalho em background adia a avaliação.** Se um subagente ou comando de shell ainda roda quando o turno termina, a avaliação daquele turno é pulada. A cada 30 minutos de espera, um check-in lista as tarefas rodando e pede ao Claude que leia a saída, siga esperando se estão progredindo, e conserte ou pare o que travou.

### 1.3 Verificar contra o app, não só contra os testes

Três skills embutidas trabalham juntas:

| Skill | Faz |
| --- | --- |
| `/run` | levanta e dirige seu app para você ver a mudança funcionando |
| `/verify` | constrói e roda o app para confirmar que a mudança faz o que deveria — **sem cair de volta para testes ou type check** |
| `/run-skill-generator` | ensina `/run` e `/verify` a construir e levantar **o seu** projeto |

`/run` e `/verify` funcionam sem setup: inferem o launch pelo tipo de projeto e pelo que há no README, `package.json` ou `Makefile`. A inferência fica pouco confiável em projeto que precisa de algo além do padrão — e aí `/run-skill-generator` grava a receita: parte de ambiente limpo, captura o que funcionou (comandos de install, variáveis de ambiente, script de launch) e commita como skill por projeto em `.claude/skills/run-<nome>/`.

Suíte verde é verificação; app rodando é validação. Não são substituíveis (`CC-SES-11`).

### 1.4 Revisão adversarial, e o seu preço

Quanto mais tempo o Claude trabalha sem supervisão, mais importa uma checagem independente antes de contar o trabalho como pronto. Um revisor em contexto **fresco** vê só o diff e o critério que você deu — **não o raciocínio que produziu a mudança** — então avalia o resultado nos próprios termos (`CC-SES-07`).

- Corretude: `/code-review` (revisa o diff atual em subagente e devolve os achados à sessão).
- Contra o plano: escreva o prompt. Nomeie o trabalho, o plano, e **o que conta como achado**.

```text
Use um subagente para revisar o diff do rate limiter contra o PLAN.md. Verifique que
todo requisito foi implementado, que os casos de borda listados têm teste, e que nada
fora do escopo mudou. Reporte lacunas, não preferências de estilo.
```

> **O preço, declarado na própria doc:** um revisor instruído a achar lacunas **normalmente acha algumas, mesmo quando o trabalho está correto** — porque foi isso que se pediu dele. Perseguir todo achado leva a over-engineering: camadas extras de abstração, código defensivo, e testes para casos que não podem acontecer. Instrua o revisor a sinalizar só o que afeta corretude ou requisito declarado, e trate o resto como opcional (`CC-SES-10`).

---

## 2. Como pedir

O Claude infere intenção, mas não lê mente. A tabela da doc, com o padrão antes/depois:

| Estratégia | Antes | Depois |
| --- | --- | --- |
| **Escopar a tarefa** | *"adicione testes para foo.py"* | *"escreva um teste para foo.py cobrindo o caso de borda em que o usuário está deslogado. evite mocks."* |
| **Apontar a fonte** | *"por que a api do ExecutionFactory é tão estranha?"* | *"olhe o histórico git do ExecutionFactory e resuma como a api dele chegou nesse estado"* |
| **Referenciar padrão existente** | *"adicione um widget de calendário"* | *"veja como os widgets existentes são implementados na home. HotDogWidget.php é um bom exemplo. siga o padrão... construa sem bibliotecas além das que já existem na base"* |
| **Descrever o sintoma** | *"corrija o bug de login"* | *"usuários relatam que o login falha após o timeout de sessão. veja o fluxo de auth em src/auth/, especialmente o refresh de token. escreva um teste que falha reproduzindo o problema, depois corrija"* |
| **Dar critério de verificação** | *"implemente uma função que valida emails"* | *"escreva validateEmail. casos de teste: user@example.com true, invalid false, user@.com false. rode os testes depois de implementar"* |
| **Atacar a causa** | *"o build está falhando"* | *"o build falha com este erro: [erro]. corrija e verifique que o build passa. ataque a causa raiz, não suprima o erro"* |

> **Quando o prompt vago é a escolha certa:** quando você está explorando e pode se permitir corrigir a rota. `"o que você melhoraria neste arquivo?"` levanta coisas que você não teria pensado em perguntar.

**Conteúdo rico.** `@` para referenciar arquivo (o Claude lê antes de responder) · colar ou arrastar imagem direto no prompt · dar URL de documentação (`/permissions` para allowlist de domínio frequente) · `cat error.log | claude` para mandar conteúdo por pipe · ou simplesmente instruir o Claude a buscar o contexto ele mesmo, por Bash, MCP ou leitura.

---

## 3. Explorar, planejar, implementar

O fluxo recomendado tem quatro fases:

| Fase | Como |
| --- | --- |
| **Explorar** | plan mode (`Shift+Tab` até aparecer `⏸ plan mode on`, ou `claude --permission-mode plan`). O Claude lê e responde **sem alterar nada**: *"leia /src/auth e entenda como tratamos sessão e login"* |
| **Planejar** | *"quero adicionar Google OAuth. Que arquivos mudam? Qual o fluxo de sessão? Crie um plano."* — **`Ctrl+G` abre o plano no seu editor** para você editar antes de o Claude prosseguir |
| **Implementar** | aprovar o plano ou `Shift+Tab`, verificando contra o plano: *"implemente o fluxo OAuth do seu plano. escreva testes para o handler de callback, rode a suíte e corrija falhas"* |
| **Commitar** | *"commit com mensagem descritiva e abra um PR"* |

**Quando não planejar.** Plan mode adiciona overhead. Para escopo claro e correção pequena — typo, linha de log, renomear variável — peça direto. **Se você descreve o diff em uma frase, pule o plano** (`CC-SES-03`).

### 3.1 Feature grande: deixe o Claude te entrevistar

Para feature grande, começar com prompt mínimo e pedir a entrevista rende mais que escrever a especificação sozinho. O Claude pergunta sobre o que você ainda não considerou: implementação técnica, UI/UX, casos de borda, trade-offs.

```text
Quero construir [descrição breve]. Me entreviste em detalhe usando a ferramenta AskUserQuestion.

Pergunte sobre implementação técnica, UI/UX, casos de borda, preocupações e trade-offs.
Não faça perguntas óbvias — cave nas partes difíceis que eu possa não ter considerado.

Continue entrevistando até cobrirmos tudo, então escreva uma spec completa em SPEC.md.
```

**Depois, abra uma sessão nova para executar.** A sessão nova tem contexto limpo, focado inteiramente na implementação, e você tem uma spec escrita para referenciar (`CC-SES-04`).

As specs mais úteis são **autocontidas**: nomeiam os arquivos e interfaces envolvidos, declaram o que está **fora** de escopo, e terminam com um passo de verificação ponta a ponta que prova que a feature funciona. *Tempo gasto deixando a spec precisa rende mais que tempo gasto assistindo a implementação.*

---

## 4. Corrigir rota e desfazer

Os melhores resultados vêm de laços de feedback curtos. Ainda que o Claude às vezes resolva perfeitamente na primeira, corrigir rápido geralmente produz solução melhor **mais rápido**.

| Ação | Faz |
| --- | --- |
| `Esc` | para o Claude no meio da ação. **O contexto é preservado** — você redireciona |
| `Esc` `Esc` ou `/rewind` | abre o menu de rewind: restaura conversa, código, ou os dois |
| *"desfaça isso"* | o Claude reverte as próprias mudanças |
| `/clear` | zera o contexto entre tarefas não relacionadas |
| `/branch` | ramifica a conversa neste ponto, para tentar outra direção sem perder a atual |

**A regra das duas correções.** Se você corrigiu o Claude mais de duas vezes no mesmo ponto em uma sessão, o contexto está entulhado de abordagens fracassadas. `/clear` e comece de novo com um prompt mais específico que **incorpore o que você aprendeu**. Uma sessão limpa com prompt melhor quase sempre bate uma sessão longa com correções acumuladas (`CC-SES-06`).

**Compactação parcial.** No menu de rewind, selecionando um checkpoint de mensagem: **Summarize from here** condensa dali para frente mantendo o contexto anterior intacto; **Summarize up to here** condensa o anterior mantendo o recente em texto integral.

### 4.1 Checkpoints — e o que eles não cobrem

Todo prompt que você manda cria um checkpoint, e o Claude tira um snapshot dos arquivos antes de cada mudança. Isso libera uma estratégia: em vez de planejar cada passo com cuidado, mandar o Claude **tentar algo arriscado** — se não der, rewind e outra abordagem. Checkpoints são salvos com a conversa, então você pode fechar o terminal, retomar depois, e ainda rebobinar.

> **O limite, e ele importa:** checkpoints rastreiam **só** as mudanças feitas pelas ferramentas de edição de arquivo do Claude. Mudança feita por comando Bash ou processo externo **não é capturada**. Isto não substitui git.

---

## 5. Sessões como linhas de trabalho

Conversas são persistentes e reversíveis. Trate cada sessão como um branch: uma linha de trabalho, com contexto próprio e nome próprio (`CC-SES-09`).

| Comando | Faz |
| --- | --- |
| `/rename <nome>` | nomeia a sessão e mostra o nome na barra de prompt |
| `claude --continue` | retoma de onde parou |
| `claude --resume` | escolhe de uma lista |
| `/resume <id ou nome>` | retoma por id ou nome |
| `/branch [nome]` | ramifica a conversa neste ponto |
| `/recap` | resumo de uma linha da sessão, **sem** substituir o histórico (ao contrário de `/compact`) |
| `/export [arquivo]` | exporta a conversa como texto |

Nome descritivo (`oauth-migration`) é o que torna `--resume` utilizável semanas depois.

---

## 6. Permissões: parar de aprovar a mesma coisa

Em **auto mode** — o modo inicial embutido nos planos Pro, Max e Team, para sessões interativas de terminal e VS Code — um modelo classificador separado revisa a maioria das ações em vez de você, e bloqueia só o que parece arriscado: escalada de escopo, infraestrutura desconhecida, ações dirigidas por conteúdo hostil.

Em **Manual mode** — o modo inicial nos outros planos — o Claude Code pergunta antes de qualquer ação que possa modificar seu sistema. É seguro e tedioso: *depois da décima aprovação você está clicando, não revisando*. Duas ferramentas cortam a interrupção, e valem nos dois modos:

- **Allowlist de permissão**: liberar ferramentas que você sabe seguras (`npm run lint`, `git commit`)
- **Sandbox**: isolamento no nível do SO, restringindo filesystem e rede, o que deixa o Claude trabalhar mais livre dentro de fronteiras definidas

`/fewer-permission-prompts` varre seus transcripts em busca de chamadas Bash e MCP somente-leitura recorrentes e propõe a allowlist priorizada. Aprovação repetida da mesma ação é bug de configuração, não disciplina de segurança (`CC-SES-08`).

Para execução não interativa: `claude --permission-mode auto -p "corrija todos os erros de lint"`.

---

## 7. Antipadrões nomeados

A doc nomeia cinco. Reconhecê-los cedo economiza tempo:

| Antipadrão | O que é | Correção |
| --- | --- | --- |
| **A sessão pia de cozinha** | você começa com uma tarefa, pergunta algo sem relação, volta à primeira. O contexto está cheio de informação irrelevante | `/clear` entre tarefas |
| **Corrigir e corrigir** | o Claude erra, você corrige, continua errado, corrige de novo. O contexto está poluído de abordagens fracassadas | após **duas** falhas, `/clear` e prompt melhor |
| **O CLAUDE.md super-especificado** | longo demais, e o Claude ignora metade porque as regras importantes se perdem no ruído | poda impiedosa. Se ele já acerta sem a instrução, delete — ou converta em hook |
| **O vão do confia-mas-verifica** | implementação de aparência plausível que não trata os casos de borda | sempre dar verificação. **Se você não pode verificar, não faça merge** |
| **A exploração infinita** | você pede para "investigar" algo sem escopo; o Claude lê centenas de arquivos e enche o contexto | escopar a investigação, ou usar subagente para a exploração não consumir seu contexto principal |

### 7.1 Duas sessões, um resultado melhor

Contexto fresco melhora revisão de código, porque o Claude não fica enviesado a favor do código que acabou de escrever. O padrão **Writer/Reviewer**:

| Sessão A (Writer) | Sessão B (Reviewer) |
| --- | --- |
| `Implemente um rate limiter para nossos endpoints` | |
| | `Revise a implementação em @src/middleware/rateLimiter.ts. Procure casos de borda, condições de corrida, e consistência com nossos padrões de middleware.` |
| `Aqui está o feedback da revisão: [saída da B]. Enderece esses pontos.` | |

O mesmo funciona com testes: uma sessão escreve os testes, outra escreve o código que os faz passar.

---

## 8. Desenvolver intuição

A doc fecha com uma ressalva que vale registrar, porque contraria o resto dela:

> Estes padrões não são fixos. **Às vezes você *deve* deixar o contexto acumular**, porque está fundo em um problema complexo e o histórico é valioso. Às vezes deve pular o planejamento porque a tarefa é exploratória. Às vezes um prompt vago é exatamente o certo, porque você quer ver como o Claude interpreta o problema antes de restringi-lo.

O que a doc pede: prestar atenção no que funciona. Quando a saída é boa, notar o que **você** fez — estrutura do prompt, contexto fornecido, modo em que estava. Quando o Claude tropeça, perguntar por quê: contexto ruidoso? prompt vago? tarefa grande demais para uma passada?

---

## 9. Regras normativas desta nota

Canônicas na § 6.2 de [Claude Code](claude-code.md). Aqui, o critério de aplicação:

| ID | Como reconhecer a violação |
| --- | --- |
| `CC-SES-01` | a entrega diz "implementado e funcionando" e não mostra saída de comando nenhuma |
| `CC-SES-02` | o Claude começou a editar arquivos antes de alguém entender o fluxo que ia mudar |
| `CC-SES-03` | houve fase de plano para uma mudança de uma linha |
| `CC-SES-04` | a spec de uma feature grande está espalhada na conversa, não em arquivo |
| `CC-SES-05` | o prompt não nomeia arquivo nem cenário, e a primeira resposta precisou de correção de escopo |
| `CC-SES-06` | terceira correção consecutiva sobre o mesmo ponto |
| `CC-SES-07` | quem revisou o diff é a mesma sessão que o escreveu |
| `CC-SES-08` | a mesma ação foi aprovada mais de três vezes na sessão |
| `CC-SES-09` | `--resume` mostra uma lista de sessões sem nome |
| `CC-SES-10` | o diff cresceu em abstração e código defensivo depois da revisão, sem requisito novo |
| `CC-SES-11` | "os testes passam" é a única evidência para uma mudança de comportamento visível |
| `CC-SES-12` | execução longa terminou porque o Claude julgou que estava pronto |

---

## Relacionados

- [Claude Code](claude-code.md) — hub: checklist em cinco tempos e tabela de IDs
- [Claude Code - Contexto e Cache](claude-code-contexto-e-cache.md) — por que `/clear` e `/rewind` são as ferramentas que são
- [Claude Code - Configuração do Repositório](claude-code-configuracao-do-repositorio.md) — Stop hook, skills de verificação, allowlist em disco
- [Teste de Software](teste-de-software.md) — o que verificar e em que nível; esta nota trata de **quem** verifica
