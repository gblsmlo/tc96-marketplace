# Skill — Índice

Skills são **procedimentos**: dizem o que carregar, em que ordem, qual passo seguir e como reportar. Elas **não** repetem o conteúdo da documentação — roteiam para ele e citam as regras por ID. Cada skill declara sua nota-fonte no frontmatter (`fonte:`), para que uma atualização da doc propague sem precisar reescrever a skill.

São **28 skills em 9 grupos**, e cada uma é um **pacote**: um diretório com `SKILL.md`, `references/` e, quase sempre, `scripts/`.

```
Skills/
├── README.md          este índice
├── instalar.sh        copia tudo para ~/.claude/skills, resolvendo wikilinks
└── <grupo>/
    ├── README.md      o índice da família e as decisões dela
    └── <skill>/
        ├── SKILL.md
        ├── references/   o material de apoio, um arquivo por decisão
        └── scripts/      as sondas, e o gerador do mapa de IDs
```

| Grupo | Skills | Índice da família |
| --- | --- | --- |
| **react** | [[react-developer]] · [[react-review]] · [[react-structure]] · [[react-hook-form]] | [[Skills/react/README\|Skills/react/]] |
| **teste** | [[teste-design]] · [[teste-review]] · [[teste-diagnose]] | [[Skills/teste/README\|Skills/teste/]] |
| **playwright** | [[playwright-build]] · [[playwright-review]] · [[playwright-diagnose]] | [[Skills/playwright/README\|Skills/playwright/]] |
| **bun** | [[bun-test-build]] · [[bun-test-review]] · [[bun-runtime]] · [[bun-workspace]] · [[bun-migrate]] | [[Skills/bun/README\|Skills/bun/]] |
| **elysia** | [[elysia-build]] · [[elysia-schema]] · [[elysia-diagnose]] | [[Skills/elysia/README\|Skills/elysia/]] |
| **http** | [[http-contract]] · [[http-cache]] · [[http-diagnose]] · [[http-review]] | [[Skills/http/README\|Skills/http/]] |
| **tanstack** | [[tanstack-query]] · [[tanstack-router]] | [[Skills/tanstack/README\|Skills/tanstack/]] |
| **storybook** | [[storybook-setup]] · [[storybook-story]] · [[storybook-test]] | [[Skills/storybook/README\|Skills/storybook/]] |
| **drizzle** | [[drizzle-review]] | [[Skills/drizzle/README\|Skills/drizzle/]] |

---

## O que cada uma faz

| Skill | O que faz | Fonte |
| --- | --- | --- |
| [[react-developer]] | Escreve componentes e Hooks novos: três perguntas de estrutura, árvores de decisão de API, tabela de hábitos que produzem violação, e autoverificação executável antes de entregar | [[React - Patterns]] |
| [[react-review]] | Revisa código React existente: 15 sondas antes de ler código, varredura em cinco níveis, severidade e achado com ID canônico, arquivo:linha e correção concreta | [[React - Rules of React]] |
| [[react-structure]] | Decide onde o código mora e quem importa quem: oito sondas de fronteira começando por enforcement, cinco perguntas antes de criar feature, migração por etapas | [[Feature-Based Architecture]] |
| [[react-hook-form]] | Formulários: tria se RHF é a ferramenta, conecta campos, valida com Zod, cuida de condicionais e listas, e diagnostica re-render — com 12 sondas | [[React Hook Form]] |
| [[teste-design]] | Decide **em que nível** um teste vai e deriva os casos: a frase "o que pode dar errado", a árvore de nível, a proporção por módulo, as técnicas de caso | [[Teste de Software - Níveis e Escopo]] |
| [[teste-review]] | Audita a **forma** da suíte — não os testes: nove sondas que medem distribuição, duração, portões e risco descoberto | [[Teste de Software]] |
| [[teste-diagnose]] | Diagnostica a **suíte como sistema**: mede a taxa de flakiness em script antes de opinar, aplica o teste de trinta segundos, separa conserto de anestésico | [[Teste de Software - Confiabilidade da Suíte]] |
| [[playwright-build]] | Escreve teste E2E novo: locator na ordem de prioridade, asserção web-first, e autoverificação executável de 12 itens | [[Playwright - Locators]] |
| [[playwright-review]] | Audita suíte Playwright: oito sondas em script, varredura em 11 níveis, checklist extra para teste gerado por agente | [[Playwright]] |
| [[playwright-diagnose]] | Diagnostica teste que falha ou flakeia: lê o trace **antes** de tocar no código, com bissecção em script | [[Playwright - Debug e Trace]] |
| [[bun-test-build]] | Escreve teste novo e configura a suíte sob `bun test`: roteia por tarefa e fecha com autoverificação executável | [[Bun - Testes]] |
| [[bun-test-review]] | Revisa suíte `bun test` e diagnostica flaky: sete sondas em script, com as que exigem a suíte de pé atrás de `--rodar` | [[Bun - Testes]] |
| [[bun-runtime]] | Código com as APIs do Bun: arquivo, `.env`, processo, shell, hash, `--watch` × `--hot` | [[Bun - Runtime e APIs]] |
| [[bun-workspace]] | Dependências e workspace: lockfile, `bun ci`, `trustedDependencies`, catalogs, `overrides`, linker, `bun patch` | [[Bun - Gerenciador de Pacotes]] |
| [[bun-migrate]] | Migra de Node e diagnostica o que não roda: enumera `node:*` das transitivas, lacunas de cripto, stubs, container | [[Bun - Shell, FFI e Compat Node]] |
| [[elysia-build]] | Escreve rota e handler: chaining, contexto desestruturado, `status`, cookie assinado, taxonomia de erro, teste por `app.handle` | [[Elysia - Roteamento e Handler]] |
| [[elysia-schema]] | Schema e Eden: coerção por fonte, `response` por status, `guard` standalone, OpenAPI, e as três armadilhas da ponte com Query | [[Elysia - Schema e Eden]] |
| [[elysia-diagnose]] | Plugin que não afeta a rota: ordem de registro, escopo `local`/`scoped`/`global`, `derive` × `resolve`, macro, tracing | [[Elysia - Lifecycle e Plugins]] |
| [[http-contract]] | Desenha o contrato de um endpoint: método, status, `Location`, idempotência, corpo de erro — e confere com `curl -i` | [[HTTP - Métodos e Semântica]] |
| [[http-cache]] | Política de frescor e condicional: `Cache-Control`, `ETag`, `304`, `If-Match` para escrita concorrente, `Vary` | [[HTTP - Cache e Requisições Condicionais]] |
| [[http-diagnose]] | Requisição bloqueada ou formato errado: percorre o modelo de falha de CORS e negociação com cinco sondas `curl` | [[HTTP - CORS]] |
| [[http-review]] | Audita o contrato HTTP de uma API existente: oito sondas antes de ler código, varredura por consequência | [[HTTP]] |
| [[tanstack-query]] | Estado do servidor: roteia por tarefa e diagnostica cache por sintoma — 12 sondas | [[TanStack Query]] |
| [[tanstack-router]] | Roteamento: rota, navegação, search params, loader e code splitting — 16 sondas | [[TanStack Router]] |
| [[storybook-setup]] | Configura Storybook: escolhe o framework pelos pisos de versão, a sequência de sete passos, e de onde a config do Vite é herdada | [[Storybook - Configuração e Builder]] |
| [[storybook-story]] | Escreve ou revisa story: estados nomeados, `satisfies`, `args` nos três níveis, `argTypes` como exceção, tags e docs | [[Storybook - Stories e Args]] |
| [[storybook-test]] | Transforma story em teste: **lê o `framework` antes de qualquer coisa**, `play`, `fn()`, mock, a11y | [[Storybook - Testes e Interações]] |
| [[drizzle-review]] | Revisa persistência Drizzle/PostgreSQL: 11 sondas antes de ler código, varredura por frequência de falha | [[Drizzle ORM]] |

---

## Anatomia comum

As 28 têm a mesma forma, e ela é conferível por script:

| Elemento | Regra |
| --- | --- |
| diretório | `Skills/<grupo>/<skill>/`, com `SKILL.md`, `references/` e `scripts/` |
| `name` | kebab-case, **igual** ao nome do diretório |
| `description` | **o quê** + **quando usar** + **quando não usar**, nomeando a skill vizinha |
| `fonte:` | **uma** nota normativa só |
| `## Quando usar` | com tabela de desvio para a skill certa (ou `Como usar` / `Triagem`, onde o desenho pede) |
| `## Carregamento mínimo` | ordem de leitura, o que **nunca** carregar, e a tabela de `references/` |
| `## Exemplo` | um caso trabalhado, com os IDs reais da família — em `references/exemplo*.md` |
| `## Relacionados` | as irmãs e as notas-fonte |
| `references/mapa-de-ids.md` | **gerado**, nunca escrito à mão |

**A `description` é o que decide se a skill certa é acionada.** O eixo que separa a maior parte dos pares é **novo × já existe**, e ele aparece nas primeiras palavras de cada uma.

**O que vai em `references/`, e o que não vai.** Vai o material que o `SKILL.md` afogaria: tabelas longas de antipadrão, árvores, grades de diagnóstico, exemplos trabalhados. **Não vai o texto da regra** — cópia de regra dentro de skill vira réplica desatualizada, e a fonte da verdade continua em `Docs/`.

---

## Desambiguação — a pergunta decide a skill

| A pergunta é… | Skill | Explicitamente **não** é |
| --- | --- | --- |
| escrever componente ou Hook React **novo** | [[react-developer]] | [[react-review]] · [react-component-performance](/Users/gabs/.claude/skills/react-component-performance/SKILL.md) |
| este código React **que já existe** está correto? | [[react-review]] | [[react-developer]] · [react-component-performance](/Users/gabs/.claude/skills/react-component-performance/SKILL.md) |
| onde este arquivo mora, quem pode importar quem | [[react-structure]] | as três acima — e num PR ela vem **antes** de [[react-review]] |
| componente ou lista já **confirmado lento**, precisa de fix medido | [react-component-performance](/Users/gabs/.claude/skills/react-component-performance/SKILL.md) | [[react-developer]] · [[react-review]] |
| o dado vem de servidor e outra pessoa pode alterá-lo | [[tanstack-query]] | [[react-developer]] |
| o estado pertence à **URL** (filtro, aba, página) | [[tanstack-router]] | [[tanstack-query]] |
| formulário com validação, campo condicional, submit | [[react-hook-form]] | [[react-developer]] |
| **que teste** eu escrevo, e em que nível? | [[teste-design]] | [[playwright-build]] · [[bun-test-build]] |
| escrever o teste, nível já decidido | [[playwright-build]] · [[bun-test-build]] | [[teste-design]] |
| esta **suíte** protege alguma coisa? | [[teste-review]] | [[playwright-review]] · [[bun-test-review]] |
| defeito **neste teste**, arquivo:linha | [[playwright-review]] · [[bun-test-review]] | [[teste-review]] |
| ninguém confia na suíte, como sistema | [[teste-diagnose]] | [[playwright-diagnose]] |
| **este teste** falha ou flakeia | [[playwright-diagnose]] · [[bun-test-review]] | [[teste-diagnose]] |
| arquivo, env, processo, shell, hash em Bun | [[bun-runtime]] | [[bun-workspace]] |
| dependência, lockfile, workspace, CI | [[bun-workspace]] | [[bun-runtime]] |
| vim do Node e não roda; container; Dockerfile | [[bun-migrate]] | [[bun-runtime]] |
| rota, handler, erro, cookie em Elysia | [[elysia-build]] | [[elysia-schema]] |
| schema, `response`, cliente Eden, OpenAPI | [[elysia-schema]] | [[elysia-build]] |
| hook ou plugin que não afeta a rota | [[elysia-diagnose]] | [[elysia-build]] |
| qual método, qual status, `Location`, idempotência | [[http-contract]] | [[http-cache]] |
| por quanto tempo cacheia, `ETag`, escrita concorrente | [[http-cache]] | [[http-contract]] |
| requisição bloqueada, CORS, acento quebrado | [[http-diagnose]] | [[http-review]] |
| esta API respeita o protocolo? | [[http-review]] | [[http-diagnose]] |
| instalar Storybook, escolher framework, sidebar vazia | [[storybook-setup]] | [[storybook-story]] |
| escrever story, `args`, controles, página de docs | [[storybook-story]] | [[storybook-test]] |
| teste de interação dentro de uma story | [[storybook-test]] | [[playwright-build]] · [[bun-test-build]] |
| persistência Drizzle/PostgreSQL existente | [[drizzle-review]] | — não há skill de construção ainda |

**A única linha com skill de fora do vault.** `react-component-performance` não é uma destas 28 — não tem `fonte:` em `Docs/`, vem de um pack de comunidade (`Dimillian/Skills`) e por isso não leva `[[wikilink]]`, só o caminho absoluto do pacote instalado. Ela cobre o procedimento (Profiler, isolar estado que "ticka", estabilizar callback) que `react-developer`/`react-review` só citam como regra (`REACT-PERF-01`) sem passo a passo — não duplica, complementa.

---

## Editar e instalar

**A fonte de edição é o pacote**, não este arquivo: `Skills/<grupo>/<skill>/SKILL.md` e os arquivos de `references/`. Este índice descreve o conjunto; ele não é copiado para lugar nenhum.

```bash
bash Skills/instalar.sh          # instala as 28 em ~/.claude/skills/<nome>/
```

O instalador copia `SKILL.md`, `references/` e `scripts/`, resolvendo os wikilinks. **Skill e nota viram code span, não link markdown** — o `skill-validator` resolve qualquer href relativo ao diretório da skill, e marcaria caminho absoluto como `broken internal link`. Cada arquivo instalado leva um rodapé dizendo onde as notas moram.

Um único `[[...]]` sobrevive de propósito: `[[Satélite correspondente]]`, que é placeholder de prosa nos modelos de achado, não link.

**Depois de editar qualquer `Docs/`, regenere o mapa da família e reinstale.** Cada grupo tem seu gerador; o `README.md` do grupo traz o comando.

---

## O mapa de IDs — um índice que também é verificação

`references/mapa-de-ids.md` é **gerado** em todas as 28, por um gerador por família. Ele indexa cada ID por satélite e seção, e **nunca** carrega o texto da regra.

O efeito colateral é o que mais paga: **onde a doc declara a contagem, o gerado confere.**

| Família | IDs | Confere com |
| --- | --- | --- |
| `REACT-*` | 105 | — |
| `REACT-ARCH-*` | 12 | § 4 de [[Feature-Based Architecture]] |
| `RHF-*` | 81 | — |
| `TS-*` | 64 | "64 regras" da § 6.2 do hub |
| `PW-*` | 85 | "85 regras" declaradas |
| `BUN-TEST-*` | 29 | faixa contínua `01`–`29` |
| `BUN-CORE/RT/PKG/SYS-*` | 43 | — |
| `ELYSIA-*` | 44 | "44 regras" da § 6, com 9 de `APP` só no hub |
| `HTTP-*` | 74 | "74 regras", numeração contínua |
| `DRZ-*` | 32 | — |
| `SB-*` | 75 | — |
| `TSQ-*` | 55 | — |
| `TSR-*` | 102 | — |

Divergência entre o gerado e o declarado é bug de um dos dois, e aparece na hora — foi assim que se descobriu que o regex `[A-Z]+` perdia a família `RHF-A11Y-*`, que tem dígito no nome.

**Três colunas que só existem onde fazem falta.** Onde a família inteira é declarada no hub — `BUN-TEST-*`, `ELYSIA-*`, `DRZ-*` — a coluna "declarada em" seria uniforme e inútil, e o gerador acrescenta **"corpo no satélite"**: qual dos satélites carrega o raciocínio de cada ID. É o que permite carregar **um** satélite em vez de seis. Em `REACT-ARCH-*` a coluna extra é outra: **quem faz valer** — lint ou revisão humana —, que é o que decide se um achado volta no PR seguinte.

---

## Os três padrões de sonda

41 scripts, e o desenho deles convergiu para três regras.

**1. A sonda mais valiosa é a que ninguém roda.** Origem CORS **recusada**, `If-Match` **obsoleto**, `bun test --randomize`, ordem de registro do hook, `test.only` sem `forbidOnly`: todas medem o caso que o caminho feliz nunca exercita. As que só confirmam o que já se sabe ficam de fora.

**2. Sonda que não pode provar, não finge.** `elysia-diagnose` aponta o plugin sem escopo e manda o teste na instância **consumidora** provar — porque `local` e `scoped` produzem o mesmo código dentro do plugin. `drizzle-review` imprime as duas listas (o que é exportado × o que é registrado) e deixa a comparação com o revisor. `bun-test-build/autoverificar.sh` marca explicitamente os quatro itens **heurísticos**.

**3. Quando o grep não basta, o script muda de ferramenta.** `trustedDependencies` virou checagem **JSON**, porque um `package.json` de uma linha derrota qualquer `grep` — e a regra (`BUN-PKG-04`: a lista **substitui**, não estende) tem sintoma em runtime, longe da causa.

E um corolário operacional: **sonda que exige o serviço ou a suíte de pé fica atrás de flag ou de argumento** (`sondas.sh --rodar`, `sondas.sh <base-url>`). O que não rodou é declarado como "não verificado", nunca como "sem achado".

---

## As famílias, e por que cada decomposição

### React — quatro, em dois eixos

`react-developer` × `react-review` é **novo × já existe**. As outras duas cortam por outro eixo: `react-structure` cuida de **onde o código mora** (`REACT-ARCH-*`, e num PR vem **antes** da revisão de interior, porque mover um arquivo apaga o achado), e `react-hook-form` cobre uma capacidade inteira com família própria (`RHF-*`).

### Backend — Bun e Elysia

Nenhuma das duas é uma tríade: a decomposição seguiu o **satélite**, como a § 7 de cada hub pede.

| Família | Skills | Por quê assim |
| --- | --- | --- |
| **Bun** | [[bun-runtime]] · [[bun-workspace]] · [[bun-migrate]] · [[bun-test-build]] · [[bun-test-review]] | três por satélite, mais as duas de teste, que dividem **modo de trabalho** |
| **Elysia** | [[elysia-build]] · [[elysia-schema]] · [[elysia-diagnose]] | uma por satélite: rota, schema, lifecycle |

**O que ficou deliberadamente de fora de Bun:** `Bun.serve` cru, `bun:sqlite`/`Bun.sql`, e o bundler. Não é lacuna — neste stack a rota é de [[elysia-build]], a persistência é de [[drizzle-review]], e o bundle é do Vite.

**A peculiaridade de Elysia:** é a única família com **apelidos parciais** — `ELYSIA-TYPE-11` é apelido de `ELYSIA-APP-04` *só na cláusula de `strict`*, e continua citável pelo que é só dele. As três skills carregam a § 6.2 no carregamento mínimo por isso.

**A regra de maior consequência de cada uma:**

- Bun — **`trustedDependencies` substitui a lista padrão**, não estende. Declarar um pacote desliga os scripts de instalação de `sharp`, `esbuild` e todo o resto, e o sintoma aparece em runtime (`BUN-PKG-04`).
- Elysia — **o escopo default de hook de plugin é `local`**, então um plugin de autenticação sem escopo declarado protege as rotas dele e nenhuma do consumidor (`ELYSIA-LIFE-01`, `ELYSIA-LIFE-08`).

### HTTP — quatro, porque cache é domínio próprio

A § 7 do hub [[HTTP]] pede skills derivadas de satélite e cita "uma skill de cache" como exemplo. **Cache virou skill própria** porque tem 12 regras, árvore exclusiva, o caminho de escrita concorrente (`If-Match`/`412`) que nenhuma outra carrega, e uma fronteira que confunde de fato — a § 8.3 do hub existe só para separar o cache HTTP do cache do [[TanStack Query]].

**Três das quatro derivam de satélite; só [[http-review]] deriva do hub** — mesmo critério de [[playwright-review]] e [[teste-review]]: a § 6 normativa e a § 6.2 moram lá.

**A peculiaridade:** `Vary` tem **três** regras que **não são apelidos** — cada uma acrescenta uma obrigação concreta (cache, compressão, origem dinâmica).

### Storybook — três, um arquivo cada

As três dividem o **arquivo**, não o modo de trabalho: `.storybook/`, `*.stories.tsx`, e a `play` dentro da story. **Escrever e revisar estão juntas em cada uma**, porque no Storybook a story **é** o teste e a decisão é a mesma nas duas direções.

É também a única família cujo **Passo 0 é descobrir a configuração do projeto**, e por um motivo forte: **prescrever o caminho errado falha em silêncio**. `parameters.tanstack.*` não tem efeito sob `react-vite`; um `RouterProvider` manual sob `tanstack-react` cria um segundo router. `SB-TS-*` e `SB-RV-*` são mutuamente exclusivas, e citar uma contra um projeto do outro caminho é **achado inválido** — daí o `descobrir-caminho.sh`, que lê o campo **e** procura a contradição no código.

**A escolha de framework é praticamente irreversível:** a automigração é unidirecional, e o piso de Vite ≥ 7 do caminho TanStack pode exigir migração de build antes de qualquer story.

### TanStack — duas, e a fronteira é de quem é o dado

[[tanstack-query]] cuida do que **vem do servidor**; [[tanstack-router]], do que **pertence à URL**. As duas se encontram numa regra só: `TSR-LOAD-14` — loader que usa Query exige `defaultPreloadStaleTime: 0`, para que **um** cache decida o frescor.

### Drizzle — uma, e a ausência é deliberada

Só [[drizzle-review]]. Para escrever schema ou query nova, as árvores de [[Drizzle ORM]] § 5 são consultadas direto — não há skill de construção, e isso está declarado na `description`.

---

## Duas camadas de skill de teste

A distinção que evita as duas se canibalizarem:

| Camada | Skills | Decide |
| --- | --- | --- |
| **conceito** | [[teste-design]] · [[teste-review]] · [[teste-diagnose]] | *o quê*, *em que nível*, e se a suíte protege |
| **ferramenta** | [[playwright-build]] · [[playwright-review]] · [[playwright-diagnose]] · [[bun-test-build]] · [[bun-test-review]] · [[storybook-test]] | *como*, na ferramenta concreta |

A mesma tríade **build / review / diagnose** nas duas camadas, resolvendo problemas diferentes:

| Tríade | Camada de conceito | Camada de ferramenta |
| --- | --- | --- |
| **build** | decide o nível e deriva os casos | escreve o teste naquele nível |
| **review** | audita a **forma** da suíte (distribuição, portões, risco descoberto) | audita os **testes** (defeito por arquivo:linha) |
| **diagnose** | mede a **suíte** (taxa de flakiness, detecção de quebra) | investiga **um teste** (trace, hipóteses) |

**A ordem importa:** conceito primeiro, ferramenta depois. Pular a camada de conceito produz **E2E por default**, o antipadrão de maior custo do stack. Carregar as duas juntas para uma tarefa cujo nível já está decidido desperdiça contexto.

**Em Playwright, auditar e diagnosticar são skills separadas**; sob Bun, moram numa só. O motivo é que em Playwright o diagnóstico começa **fora do código** — no trace — e percorrer a § 5.2 do hub é procedimento longo demais para caber como seção de outra skill.

---

## Sobre a origem de cada `fonte:`

O critério geral é **uma nota normativa só, declarada no `fonte:`**. Três variações valem registro:

**Fonte no hub, não no satélite.** [[drizzle-review]], [[bun-test-build]], [[bun-test-review]], [[playwright-review]], [[teste-review]] e [[http-review]] declaram um **hub**. Não é exceção: em React as regras moram no satélite e o hub só roteia, enquanto em Drizzle, Bun e HTTP a § 6 normativa e a § 6.2 de IDs canônicos moram no próprio hub — e é isso que uma revisão precisa citar sem parafrasear.

**Escrever e diagnosticar derivam de satélite; revisar deriva do hub.** Vale em Playwright ([[Playwright - Locators]], [[Playwright - Debug e Trace]]) e em Teste de Software ([[Teste de Software - Níveis e Escopo]], [[Teste de Software - Confiabilidade da Suíte]]).

**Fonte fora de `Docs/`.** [[react-structure]] deriva de [[Feature-Based Architecture]], que mora em `Pages/`. Aquela nota não resume documentação externa — registra uma decisão desta casa, com convenções que só existem neste vault, e por isso carrega IDs citáveis (`REACT-ARCH-*`) e contrato próprio. Onde ela contradisser um `Docs/` em fato verificável, o `Docs/` vence.

A **fonte da verdade sobre a regra em si é `Docs/`**. Divergência entre uma skill e a doc é **bug da skill**.

---

## Correções que o empacotamento produziu

Reescrever cada skill contra a doc encontrou três divergências reais:

1. **`react-hook-form` invertia canônico e apelido.** Dizia que `REACT-FORM-07` era o canônico e `RHF-BRIDGE-04` o apelido. A § 6.2 de [[React Hook Form]] diz o contrário: `RHF-BRIDGE-04` é canônico, sem equivalente no corpus de React, e `REACT-FORM-07` trata de outra coisa (`useOptimistic` não ser fonte de verdade).
2. **`tanstack-router` não citava ID nenhum.** Abria com um aviso de que os satélites estavam em construção, e emprestava `REACT-*`. Os dez existem e somam **102 regras `TSR-*`** — o aviso saiu, e cada tarefa ganhou família citável.
3. **`ELYSIA-APP-*` só existe no hub.** O gerador confirma: 9 das 44 regras não têm corpo em satélite, e o mapa marca isso em vez de apontar um satélite que não as carrega.

---

## Orçamento de contexto

O que a estrutura de pacote compra é **controle de quanto entra no contexto**. Cada
`README.md` de grupo traz a tabela por skill, medida por `skill-validator` (tiktoken):

```bash
bash Skills/tokens.sh            # atualiza a seção nos 9 READMEs de grupo
bash Skills/tokens.sh --mostrar  # só imprime
```

**O número que importa é o do `SKILL.md`** — é o que entra antes de a skill decidir o que
abrir. As referências carregam **uma por vez**, sob demanda.

| | tokens |
| --- | ---: |
| soma dos 28 `SKILL.md` | **45.529** |
| soma de tudo, com todas as referências | **239.053** |
| maior `SKILL.md` ([[react-developer]]) | 2.804 |
| menor `SKILL.md` ([[bun-workspace]]) | 973 |

Nenhum `SKILL.md` chega perto do limite de **5.000** do validador — e a diferença entre as
duas primeiras linhas é o argumento inteiro do desenho: **194 mil tokens de material de
apoio existem sem estar no caminho**. É por isso que cada skill declara, no
`## Carregamento mínimo`, o que **nunca** carregar.

O maior arquivo de referência é quase sempre o `mapa-de-ids.md` — e ele é justamente o que
raramente precisa ser lido inteiro: serve para localizar **um** ID.

## Validação

As 28 passam em [`skill-validator`](https://github.com/agent-ecosystem/skill-validator) (v1.6.1) com **0 erros**, na fonte e na cópia instalada.

```bash
for s in Skills/*/*/; do skill-validator check "$s"; done
```

Sobram **dois avisos por skill** — `unrecognized field: "tags"` e `"fonte"` — que são a anatomia comum deste vault e ficam **por decisão**, não por descuido.

Três classes de erro foram corrigidas no caminho, e valem como lembrete para o próximo script: `rg -E` é `--encoding`, não regex estendida (herdado de `grep -rnoE`); o motor de regex do `rg` **não tem lookaround**, então "arquivo tem A e não tem B" precisa de duas passadas; e nome de família com dígito (`RHF-A11Y-*`) não casa `[A-Z]+`.

---

## Relacionados

- [[React.js]] § 7 — o "Contrato de skill" que as demais famílias replicaram
- [[Teste de Software]] · [[Playwright]] · [[Bun - Testes]] · [[Elysia]] · [[HTTP]] · [[Drizzle ORM]] · [[Storybook]] · [[TanStack Query]] · [[TanStack Router]] — os hubs
- [[Como usar a base de conhecimento para dar contexto a agentes]]
