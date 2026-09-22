---
titulo: Bun
Link: https://bun.com/docs
tags:
  - bun
  - reference
  - agent-context
source: "Documentação oficial — https://bun.com/docs"
verificado-em: 2026-08-15
---

# Bun — referência conduzida

> **O que esta nota é.** O ponto de entrada único para Bun neste vault: para mim ao consultar, e para agentes de código ao gerar ou revisar código que roda em Bun. Não é um resumo linear da documentação — é um **roteador**. Ela decide o que carregar, oferece o modelo mental que faz o resto fazer sentido, e expõe regras citáveis que uma skill ou um code review pode referenciar por ID.
>
> **O que não é.** Não substitui a fonte. Quando houver divergência, [bun.com/docs](https://bun.com/docs) vence, e esta nota deve ser corrigida.

Inventário verificado diretamente em bun.com/docs em **2026-08-15**. Versão verificada: **Bun 1.3.14** (`latest` no registry npm, publicada em 2026-05-13).
Ver [Fontes consultadas](#fontes-consultadas).

---

## 1. Como usar esta doc

### Para um humano

Leia a seção 2 uma vez — ela é curta e explica por que Bun não se comporta como "Node mais rápido". Depois use a seção 4 como índice, a seção 3 quando um import falhar, e a seção 5 quando estiver na dúvida entre duas APIs próximas. Os satélites são para leitura sob demanda.

### Para um agente de código

Carregue nesta ordem, parando assim que tiver o suficiente:

| Passo | Carregar | Quando |
| --- | --- | --- |
| 1 | Esta nota (seções 2, 3, 5, 6) | Sempre que a tarefa envolver Bun |
| 2 | O satélite do domínio específico | Quando a tarefa toca uma API concreta — use a seção 4 para descobrir qual |
| 3 | [Bun - Runtime e APIs](bun-runtime-e-apis.md) | Execução, arquivos, env, processos, resolução de módulos |
| 4 | [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) § 5 (matriz de compatibilidade) | Sempre que estiver portando código de Node.js |
| 5 | [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) | Instalação, lockfile, monorepo, CI |

**Regra de economia de contexto:** nunca carregue todos os satélites.

### Convenções e vocabulário

**Todos os exemplos são TypeScript.** Bun executa `.ts` e `.tsx` diretamente — o código dos exemplos roda como está, sem passo de build.

Termos usados sem redefinição nos satélites:

| Termo | Significado nesta doc |
| --- | --- |
| **runtime do Bun** | o processo iniciado por `bun`, onde o global `Bun` e os módulos `bun:*` existem |
| **global `Bun`** | o objeto `Bun`, disponível sem import; ausente em Node.js e no browser |
| **transpilação em voo** | Bun converte TS/JSX para JS a cada carga de arquivo, antes de executar; não há artefato em disco |
| **hoisted × isolated** | as duas estratégias de layout de `node_modules` (`--linker`); a segunda é o modelo do pnpm |
| **phantom dependency** | pacote importável sem estar declarado em `package.json`, efeito colateral do layout hoisted |
| **lifecycle script** | `preinstall`/`postinstall`/etc. declarado por uma dependência, executado pelo package manager |
| **soft reload** | o reload de `--hot`: reavalia módulos sem reiniciar o processo, preservando `globalThis` |
| **hard restart** | o reload de `--watch`: mata e reinicia o processo com os mesmos argumentos |
| **preload** | módulo carregado antes de qualquer outro (`--preload`, `[test] preload`) |

---

## 2. Modelo mental

Cinco afirmações. Quase todo erro que um agente comete em Bun viola uma delas.

**1. `bun` é quatro ferramentas no mesmo binário, e isso muda o fluxo de trabalho, não só a velocidade.** Runtime, package manager, test runner e bundler são o mesmo executável. A consequência prática não é "menos dependências": é que não existe `jest.config`, `ts-node`, `nodemon` nem `dotenv` no projeto, e escrever um deles é regressão (`BUN-CORE-03`). Antes de adicionar uma ferramenta ao `package.json`, cheque a § 4 — o binário provavelmente já faz aquilo. **O bundler é a exceção honesta:** Bun tem um, mas para SPA React em produção o ecossistema de plugins ainda é do Vite, e o dev server do Bun é declarado *work in progress* na própria fonte. O critério está em [Bun - Bundler e Build](bun-bundler-e-build.md) § 10.

**2. As APIs do global `Bun` não precisam de import, e por isso não existem fora do Bun.** `Bun.file`, `Bun.serve`, `Bun.spawn`, `Bun.password` estão em `globalThis` sem `import`. O preço é que o mesmo arquivo, rodado com `node`, quebra com `ReferenceError`. Código de biblioteca destinado a rodar nos dois runtimes usa `node:*` ou detecta o ambiente; código de aplicação assume Bun deliberadamente.

**3. TypeScript e JSX são executados, não compilados.** `bun index.tsx` roda. Bun lê o `tsconfig.json` apenas para decidir o **transform** de JSX e o `paths` — ele **não faz type checking**. Nenhum erro de tipo impede a execução. Type checking continua sendo um passo separado (`tsc --noEmit`) e precisa estar no CI, ou tipos errados chegam à produção sem aviso.

**4. Compatibilidade com Node.js é objetivo declarado, não estado alcançado — e saber onde ela termina evita a maior classe de bug.** A fonte é explícita: *"This is an ongoing effort"*, e mantém uma [página de status por módulo](https://bun.com/docs/runtime/nodejs-compat) medida contra o Node.js v26. A maioria dos módulos está 🟢, vários estão 🟡 com lacunas nomeadas (`node:https` sem `SNICallback`, `node:vm` parcial, `node:worker_threads` ignorando `resourceLimits`), e `node:sea` está 🔴. "Funciona no Node" não é evidência de que funciona no Bun; a página de compatibilidade é.

**5. ESM e CJS coexistem no mesmo arquivo, com uma exceção que importa.** `import` e `require` funcionam lado a lado, e `require()` aceita `.ts`, `.tsx` e `.mjs`. A única quebra é `require()` de um módulo com **top-level `await`** — `require` é síncrono por definição. É a única regra de interop que precisa ser lembrada.

> **O corolário que economiza tempo:** quando algo não roda em Bun, a primeira pergunta não é "qual é o bug do Bun". É *"isto está usando um global do Bun em processo `node`, uma API `node:*` marcada 🟡, ou `require()` num módulo com top-level await?"*. Os três cobrem a maioria dos casos. Ver § 5.

---

## 3. Fronteiras de import e execução

Saber de onde algo vem — e onde roda — evita metade dos erros.

| Origem | Como se obtém | Contém | Existe fora do Bun? |
| --- | --- | --- | --- |
| Global `Bun` | nada (já é global) | `Bun.file`, `Bun.write`, `Bun.serve`, `Bun.spawn`, `Bun.password`, `Bun.build`, `Bun.env`, utilitários | **Não** |
| `import { … } from "bun"` | import nomeado | as mesmas APIs do global, importáveis (`$`, `serve`, `file`, `randomUUIDv7`, …) | **Não** |
| `bun:test` | `import { test, expect } from "bun:test"` | runner, `expect`, `mock`, `spyOn`, `jest`, `vi`, `expectTypeOf` | **Não** |
| `bun:sqlite` | `import { Database } from "bun:sqlite"` | driver SQLite nativo | **Não** |
| `bun:ffi` | `import { dlopen } from "bun:ffi"` | chamada de bibliotecas nativas | **Não** |
| `node:*` | `import { readdir } from "node:fs/promises"` | superfície Node.js reimplementada | Sim |
| Globais Web | nada | `fetch`, `Request`, `Response`, `Headers`, `URL`, `Blob`, `ReadableStream`, `AbortController`, `crypto`, `WebSocket`, `structuredClone` | Sim (browser/Node modernos) |
| Globais Node | nada | `process`, `Buffer`, `__dirname`, `__filename`, `require`, `module`, `global` | Sim |
| `import.meta` | linguagem | `.dir`, `.file`, `.path`, `.url`, `.main`, `.env`, `.resolve()`, e os aliases `.dirname`/`.filename` | Parcial (nomes diferem) |

Três consequências que aparecem em código gerado:

- **`bun:test` só existe dentro de `bun test`.** Importá-lo de um arquivo de aplicação e rodá-lo com `bun run` falha.
- **`Bun.env`, `process.env` e `import.meta.env` são o mesmo objeto.** A fonte diz literalmente que os dois últimos são *aliases* de `process.env`. **Dentro do Bun**, escolher entre eles é estilo, não semântica. **Vindo do Vite, não é** — lá `import.meta.env` é outro objeto, filtrado pelo prefixo `VITE_` e resolvido por modo. Sob Bun, `import.meta.env.VITE_FOO` funciona (Bun não filtra por prefixo), mas `import.meta.env.MODE`, `.DEV`, `.PROD` e `.BASE_URL` são **`undefined`**: são constantes que o Vite injeta em build. Tabela completa em [Bun - Runtime e APIs](bun-runtime-e-apis.md) § 4.
- **Tipos exigem `@types/bun`.** `bun add -d @types/bun`. Em TypeScript 6.0+, também é preciso `"types": ["bun"]` em `compilerOptions` — a auto-descoberta de `@types` deixou de existir.

---

## 4. Mapa da API

Superfície verificada em bun.com/docs. A coluna **Satélite** diz o que carregar, **e em que seção** — abrir um satélite de 500 linhas para achar uma assinatura é o que esta tabela existe para evitar.

**Granularidade, e por quê.** Uma linha por unidade que uma tarefa pede sozinha. Esta regra não é estética: enquanto metade da § 4 estava por assinatura e a outra metade por área ("Servidor HTTP | `Bun.serve`, `routes`, WebSockets, cookies, streaming"), um leitor sem contexto que procurava o diagnóstico de um SSE que caía não achava nada aqui — chegou à resposta por leitura linear da tabela de 34 regras da § 6.1. Um roteador cuja tabela de rotas cobre metade do endereçamento em granularidade errada não roteia; acerta por acaso quando o satélite certo já era óbvio. **Ao acrescentar API a um satélite, acrescente a linha aqui.**

**Esta tabela é índice de roteamento, não allow-list.** API ausente daqui significa "não verificada nesta doc" — consulte bun.com/docs e atualize a nota. Ver § 7.

**Container e imagem Docker** têm duas rotas legítimas e o caminho óbvio esconde uma: [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) § 6 (imagem `oven/bun` com `node_modules`) e [Bun - Bundler e Build](bun-bundler-e-build.md) § 8 (`--compile`, binário único sem `node_modules`).

**Deliberadamente fora deste mapa:** TCP/UDP/DNS (`Bun.listen`, `Bun.connect`, `Bun.udpSocket`, `Bun.dns`), `HTMLRewriter`, `Bun.Image`, `Bun.WebView`, `Bun.Transpiler`, `Bun.FileSystemRouter`, `Bun.CSRF`, `Bun.Secrets`, `Bun.cron`, Node-API e o compilador C embutido, os parsers `Bun.TOML`/`Bun.XML`/`Bun.markdown`/JSON5/JSONL, `Bun.Glob`, `Bun.semver`, `Bun.color`, `Bun.archive` e `bun:jsc`. Todos existem e estão documentados na fonte; a ausência aqui significa **"não verificado nesta doc"**, não "não existe".

### Execução e runtime

| API / comando | Para que serve | Satélite |
| --- | --- | --- |
| `bun run <arquivo>` / `bun <arquivo>` | Executar `.js`, `.ts`, `.jsx`, `.tsx` sem build | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `bun run <script>` | Rodar script de `package.json` | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `bun --watch` / `bun --hot` | Restart duro × reload suave | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `bun --bun` | Forçar o runtime do Bun em CLI com shebang `node` | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `--preload` (`-r`, `--import`) | Carregar módulo antes de tudo | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `import.meta.*` | Caminho, URL, entrypoint e resolução do módulo atual | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `bunfig.toml` | Configuração de runtime, install e test | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |

### Arquivos, env e processos

| API | Para que serve | Satélite |
| --- | --- | --- |
| `Bun.file(path)` | Referência preguiçosa a arquivo, com interface `Blob` | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `Bun.write(dest, data)` | Escrita multiuso (string, Blob, `Response`, TypedArray, `BunFile`) | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `file.writer()` → `FileSink` | Escrita incremental com buffer | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `Bun.stdin` / `stdout` / `stderr` | Streams padrão como `BunFile` | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `node:fs` | Diretórios, permissões, tudo que `Bun.file` não cobre | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| Carregamento de `.env` | Automático, com ordem de precedência e expansão | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `Bun.spawn` / `Bun.spawnSync` | Subprocessos assíncrono × bloqueante | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `Bun.$` (Bun Shell) | Comandos shell cross-platform com escape automático | [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) |

### Hashing, senha e utilitários

| API | Para que serve | Satélite |
| --- | --- | --- |
| `Bun.password.hash` / `.verify` | Argon2 (default) e bcrypt, com salt embutido | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `Bun.CryptoHasher` | Hash criptográfico incremental (sha256, blake2b, …) | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `Bun.hash.*` | Hash **não criptográfico** (wyhash, xxHash, crc32, …) | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `Bun.version`, `Bun.revision`, `Bun.main` | Identidade do runtime e do entrypoint | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `Bun.which`, `Bun.sleep`, `Bun.peek`, `Bun.deepEquals`, `Bun.escapeHTML` | Utilitários que aparecem em código real | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `Bun.randomUUIDv7()` | UUID v7 monotônico, ordenável | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `Bun.gzipSync` / `deflateSync` / `zstdCompress` e inversos | Compressão síncrona e assíncrona | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `Bun.readableStreamTo*` | Coletar `ReadableStream` em texto, JSON, bytes, `Blob`, `FormData` | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |

### Package manager

| Comando | Para que serve | Satélite |
| --- | --- | --- |
| `bun install`, `bun add`, `bun remove`, `bun update` | Ciclo de dependências | [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) |
| `bun ci` / `--frozen-lockfile` | Instalação reprodutível em CI | [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) |
| `bun.lock` | Lockfile textual (default desde Bun 1.2) | [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) |
| `workspaces`, `catalog:`, `--filter` | Monorepo | [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) |
| `trustedDependencies`, `bun pm trust`/`untrusted` | Modelo de segurança de lifecycle scripts | [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) |
| `overrides` / `resolutions`, `bun patch` | Controle de metadependências | [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) |
| `bun outdated`, `bun why`, `bun audit`, `bun pm` | Inspeção e auditoria | [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) |
| `bun x` / `bunx` | Executar binário de pacote sem instalar | [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) |
| `--linker hoisted` / `isolated` | Layout de `node_modules` | [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) |

### Test runner

**O test runner tem estrutura própria:** [Bun - Testes](bun-testes.md) é o hub, com seis satélites e a família `BUN-TEST-*` inteira (29 regras). As linhas abaixo roteiam direto para o satélite certo; o hub tem o mapa completo e as árvores de decisão.

| API / flag | Para que serve | Satélite |
| --- | --- | --- |
| `bun test`, descoberta, filtros, `--changed` | O que entra na suíte e o que roda nesta invocação | [Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) |
| `bunfig.toml [test]`, `NODE_ENV`/`TZ`, exit code | Configuração e o ambiente que o runner impõe | [Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) |
| `test`/`describe`/`expect`, matchers, `expect.assertions` | Corpo do teste e asserção | [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) |
| `test.each`/`.skip`/`.only`/`.todo`/`.failing`/`.if` | Modificadores | [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) |
| `toMatchSnapshot`, `toMatchInlineSnapshot`, `-u` | Snapshots em arquivo e inline | [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) |
| `mock()`, `spyOn()`, `mock.module()`, as três limpezas | Mocks de função, espiões e mocks de módulo | [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) |
| `setSystemTime`, `useFakeTimers`, `advanceTimersByTime` | Congelar data e fazer o tempo passar | [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) |
| `beforeAll`/`beforeEach`/`afterEach`/`afterAll`/`onTestFinished` | Ciclo de vida e escopo | [Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) |
| `--parallel`, `--isolate`, `BUN_TEST_WORKER_ID`, `--shard` | Isolamento, paralelismo e divisão em CI | [Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) |
| `test.concurrent`/`.serial`, `--max-concurrency` | Concorrência dentro do arquivo | [Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) |
| `--preload` / `[test] preload` para DOM (happy-dom) | Teste de componente ponta a ponta | [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md) |
| `--coverage`, `coverageThreshold`, `--reporter=junit` | Cobertura, limiar que falha o build e reporters | [Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md) |

### Servidor HTTP

| API | Para que serve | Satélite |
| --- | --- | --- |
| `Bun.serve(options)` | Sobe o servidor; devolve o objeto `server` | [Bun - HTTP e Servidor](bun-http-e-servidor.md) § 1 |
| `routes` | Roteamento nativo por path e método, com params tipados a partir do literal da chave | [Bun - HTTP e Servidor](bun-http-e-servidor.md) § 2 |
| Handler `(req, server)` | Assinatura de rota — o 2º argumento carrega `timeout`, `upgrade`, `publish`, `requestIP` | [Bun - HTTP e Servidor](bun-http-e-servidor.md) § 2 |
| `fetch(req, server)` | Fallback para o que `routes` não casa | [Bun - HTTP e Servidor](bun-http-e-servidor.md) § 2 |
| `new Response(Bun.file(p))` | Servir arquivo com `Range`, `ETag`, `304` e `sendfile(2)` | [Bun - HTTP e Servidor](bun-http-e-servidor.md) § 3 |
| `server.timeout(req, s)` | Desliga o `idleTimeout` por request — obrigatório em streaming e SSE | [Bun - HTTP e Servidor](bun-http-e-servidor.md) § 3 |
| `idleTimeout` | Default 10 s, conta **durante** a resposta; máx. 255 | [Bun - HTTP e Servidor](bun-http-e-servidor.md) § 3 |
| `req.cookies` (`CookieMap`) | Ler e escrever cookie; aplica `Set-Cookie` sozinho, e **só** dentro de `routes` | [Bun - HTTP e Servidor](bun-http-e-servidor.md) § 4 |
| `server.upgrade(req, { data })` | Upgrade para WebSocket; o estado por conexão vai em `ws.data` | [Bun - HTTP e Servidor](bun-http-e-servidor.md) § 5 |
| `websocket: { message, open, close }` | Handler único por servidor | [Bun - HTTP e Servidor](bun-http-e-servidor.md) § 5 |
| `ws.publish` / `server.publish` | Pub/sub por tópico (`publishToSelf` é `false`) | [Bun - HTTP e Servidor](bun-http-e-servidor.md) § 5 |
| `error(err)` | Handler de erro do servidor | [Bun - HTTP e Servidor](bun-http-e-servidor.md) § 6 |
| `development` | Aceita booleano **e objeto** — `NEVER` ligado em produção | [Bun - HTTP e Servidor](bun-http-e-servidor.md) § 6 |
| `server.reload()`, `.stop()`, `.requestIP()` | Ciclo de vida e binding | [Bun - HTTP e Servidor](bun-http-e-servidor.md) § 6 |
| `tls`, `unix`, `reusePort`, `hostname`, `port` | Opções de binding e transporte | [Bun - HTTP e Servidor](bun-http-e-servidor.md) § 6 |
| **O que não existe nativamente** | middleware, validação tipada, cliente tipado, CORS | [Bun - HTTP e Servidor](bun-http-e-servidor.md) § 7 · [Backend no runtime Bun](backend-no-runtime-bun.md) |

### Bundler e build

| API / flag | Para que serve | Satélite |
| --- | --- | --- |
| `Bun.build(config)` / `bun build` | API × CLI da mesma engine | [Bun - Bundler e Build](bun-bundler-e-build.md) § 2 |
| `target` (`browser`/`bun`/`node`) | Decide resolução, globais e polyfill | [Bun - Bundler e Build](bun-bundler-e-build.md) § 3 |
| `external`, `packages`, `splitting` | O que sai do bundle | [Bun - Bundler e Build](bun-bundler-e-build.md) § 4 |
| `minify`, `sourcemap`, `loader`, `define` | Saída e substituição em build time | [Bun - Bundler e Build](bun-bundler-e-build.md) § 5 |
| `Bun.plugin`, `onResolve`, `onLoad` | Plugins, mesma API para runtime e bundler | [Bun - Bundler e Build](bun-bundler-e-build.md) § 6 |
| Import de `.html` · `import.meta.hot` | Dev server e HMR — declarados *work in progress* | [Bun - Bundler e Build](bun-bundler-e-build.md) § 7 |
| `--compile`, `--target=bun-<os>-<arch>`, `bytecode` | Executável único | [Bun - Bundler e Build](bun-bundler-e-build.md) § 8 |
| `with { type: "macro" }` | Execução em build time, resultado inlinado | [Bun - Bundler e Build](bun-bundler-e-build.md) § 9 |
| **Bun × Vite** | Critério de desempate para SPA React | [Bun - Bundler e Build](bun-bundler-e-build.md) § 10 |

### Dados e persistência

| API | Para que serve | Satélite |
| --- | --- | --- |
| `new Database(path, { strict, safeIntegers })` | SQLite embutido, síncrono | [Bun - Dados e Persistência](bun-dados-e-persistencia.md) § 2 |
| `db.query()` × `db.prepare()` | Cacheado (20 entradas) × não cacheado | [Bun - Dados e Persistência](bun-dados-e-persistencia.md) § 2 |
| `.get()`, `.all()`, `.run()`, `.iterate()`, `.values()` | Executores — `.get()` devolve `null`, não `undefined` | [Bun - Dados e Persistência](bun-dados-e-persistencia.md) § 2 |
| Parâmetro (`$nome`, `?`, `${}` na tag) | **A defesa contra SQL injection** | [Bun - Dados e Persistência](bun-dados-e-persistencia.md) § 3 |
| `db.transaction(fn)` · `sql.begin(fn)` | Transação — no `begin`, use o `tx` recebido | [Bun - Dados e Persistência](bun-dados-e-persistencia.md) § 4 |
| `PRAGMA journal_mode = WAL` | Concorrência de leitura em SQLite | [Bun - Dados e Persistência](bun-dados-e-persistencia.md) § 4 |
| `Bun.sql` (tagged template) | **PostgreSQL, MySQL e SQLite** — o adapter vem do formato da URL | [Bun - Dados e Persistência](bun-dados-e-persistencia.md) § 5 |
| `sql.reserve()`, `sql.unsafe()`, `sql.file()`, `ssl` | Pool, escape hatch, script, TLS (default `"disable"`) | [Bun - Dados e Persistência](bun-dados-e-persistencia.md) § 5 |
| `POSTGRES_URL` / `DATABASE_URL` / `PGSSLMODE` … | Variáveis de conexão, por nome e precedência | [Bun - Dados e Persistência](bun-dados-e-persistencia.md) § 5 |
| Cliente Redis · `S3Client` / `Bun.s3` + presign | Os outros dois clientes embutidos | [Bun - Dados e Persistência](bun-dados-e-persistencia.md) § 6 |
| **Migração de schema** | **Bun não tem.** É de você ou de uma ferramenta externa | [Bun - Dados e Persistência](bun-dados-e-persistencia.md) § 8 · |

### Shell, nativo e compatibilidade

| API | Para que serve | Satélite |
| --- | --- | --- |
| `Bun.$` | Shell cross-platform, interpolação escapada por default | [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) § 2 |
| `.text()`, `.json()`, `.quiet()`, `.nothrow()`, `.cwd()`, `.env()` | Superfície do `$` | [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) § 2 |
| `bun:ffi` — `dlopen`, `cc`, `JSCallback` | Bibliotecas nativas — **experimental** | [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) § 3 |
| `Worker` | Paralelismo real — **experimental** | [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) § 4 |
| **Matriz de compatibilidade `node:*`** | Onde a compatibilidade termina; legenda 🟢/🟡/🔴 | [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) § 1 e § 5 |
| Imagem `oven/bun`, `USER bun`, `--no-env-file` | Deploy em container | [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) § 6 |
| `SIGTERM` + `server.stop()` + `process.exit()` | Graceful shutdown — as duas metades | [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) § 6 |
| `--smol` | Aumenta a frequência de GC; **não** é "modo container" | [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) § 6 |

---

## 5. Árvores de decisão

Mapeiam **sintoma → API correta**. É onde código gerado para Bun mais erra, porque quase toda tarefa tem duas respostas plausíveis: a do Node e a do Bun.

### Preciso ler ou escrever um arquivo. Qual API?

A pergunta que decide não é "async ou sync" — é **se a operação é sobre o conteúdo de um arquivo ou sobre o sistema de arquivos**.

```
É sobre o CONTEÚDO de um arquivo?
├── NÃO (mkdir, readdir, rm, stat, chmod, watch, symlink)
│   └── node:fs / node:fs/promises. Não existe equivalente em Bun.*
│       → a própria doc de File I/O manda usar node:fs para isso
│
└── SIM
    ├── LER
    │   ├── inteiro, uma vez → Bun.file(path).text() | .json() | .bytes() | .arrayBuffer()
    │   ├── em pedaços → Bun.file(path).stream()  → ReadableStream
    │   └── só checar existência → await Bun.file(path).exists()
    │       ⚠ NÃO use .size === 0: arquivo inexistente também tem size 0
    │
    └── ESCREVER
        ├── payload pronto (string, Blob, TypedArray, Response, BunFile)
        │   → await Bun.write(dest, data)      ← copia arquivo, salva
        │                                        resposta HTTP, escreve
        │                                        em Bun.stdout — tudo o mesmo
        ├── incremental / em loop → Bun.file(p).writer() → FileSink
        │   └── .write() bufferiza · .flush() grava · .end() fecha
        │       ⚠ o processo NÃO encerra até .end() (ou .unref())
        └── append → node:fs (Bun.write sobrescreve)
```

Sobre "quando o async importa": `Bun.file().text()` e `Bun.write()` são assíncronos e **não bloqueiam o event loop**. Dentro de um handler de `Bun.serve` isso é obrigatório. Em CLI de vida curta, `node:fs` síncrono é aceitável e às vezes mais simples — mas nunca em servidor.

### Vim do Node e meu código não roda. O que checar?

Percorra na ordem. As três primeiras cobrem a maioria dos casos.

```
1. ReferenceError: Bun is not defined
   → o processo é `node`, não `bun`.
     ├── é um CLI com shebang #!/usr/bin/env node? → bun run --bun <cli>
     │                                               ou bunx --bun <cli>
     └── é código seu? → rode com `bun`, ou troque o global Bun por node:*

2. Cannot find name 'Bun' (erro de TIPO, não de runtime)
   → falta @types/bun:  bun add -d @types/bun
     └── TypeScript 6.0+ ainda exige "types": ["bun"] em compilerOptions

3. Erro dentro de um require()
   └── o módulo tem top-level await? → require() é síncrono; use import
                                        ou import() dinâmico

4. Um módulo node:* se comporta diferente
   → consulte a página de compatibilidade ANTES de suspeitar do seu código.
     Vários módulos estão 🟡 com lacunas nomeadas; node:sea está 🔴.
     → [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md)

5. Um pacote não funcionou depois de instalar
   ├── depende de postinstall? → Bun NÃO roda lifecycle scripts por padrão.
   │   → bun pm untrusted  (lista o que foi bloqueado)
   │   → trustedDependencies / bun pm trust — ver [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md)
   └── importa algo que não declarou (phantom dependency)?
       → o linker isolated expõe isso; hoisted escondia

6. Compila mas o tipo está errado em produção
   → Bun NÃO faz type checking. `tsc --noEmit` precisa estar no CI.
```

### Preciso rodar um processo ou um comando. Qual API?

```
É um comando de shell com pipe, redirect, glob ou variável?
├── SIM
│   ├── e precisa ser cross-platform (Windows incluído)
│   │   → Bun.$  — implementa ls/cd/rm nativamente, escapa
│   │             interpolação por padrão (sem injeção)
│   │             → [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md)
│   └── e o ambiente é só POSIX e o comando é trivial
│       → Bun.spawn(["sh", "-c", …]) ainda funciona, mas o escape
│         passa a ser sua responsabilidade
│
└── NÃO — é executar um binário com argumentos
    ├── dentro de servidor HTTP ou código com event loop vivo
    │   → Bun.spawn(cmd, { … })            ← NUNCA spawnSync aqui
    │      ├── precisa de deadline → { timeout, killSignal }
    │ ├── precisa de cancelamento → { signal }
    │      ├── escrever no stdin → { stdin: "pipe" } → proc.stdin.write()
    │      └── ler o stdout → await proc.stdout.text()
    ├── em CLI de vida curta, saída pequena
    │   → Bun.spawnSync(cmd)  → { success, stdout: Buffer, stderr: Buffer }
    │      └── proteja contra saída ilimitada: { maxBuffer }
    └── precisa de API idêntica à do Node (lib compartilhada)
        → node:child_process
```

### Qual comando `bun` para esta tarefa?

```
O que você quer executar?
├── um arquivo do projeto        → bun <arquivo>        (bun run <arquivo>)
├── um script do package.json    → bun run <script>
│   └── ⚠ se o nome colide com um comando embutido do bun,
│         o embutido vence: use SEMPRE `bun run <script>` em automação
├── um binário de dependência já instalada
│   ├── com o runtime que o shebang pedir → bun run <bin>   (ou bunx <bin>)
│   └── forçando o runtime do Bun         → bun run --bun <bin>
├── um pacote npm que você NÃO quer instalar → bunx <pkg>   (= bun x)
│   ├── versão fixa            → bunx <pkg>@<versão>
│   ├── binário com nome ≠ pacote → bunx -p <pkg> <bin>
│   └── forçando o Bun         → bunx --bun <pkg>
│       ⚠ --bun vem ANTES do nome; depois do nome vai para o pacote
└── um comando do sistema        → bun run <cmd>  (último da ordem de resolução)

Ordem de resolução de `bun run <x>`:
  1. script do package.json → 2. arquivo-fonte → 3. binário de dependência
  → 4. comando do sistema (só com `bun run` explícito)

Flags do Bun vêm depois de `bun`, nunca no fim:
  bun --watch run dev   ✔     bun run dev --watch   ✘ (vai para o script)
```

---

## 6. Regras normativas

Regras citáveis por ID. Uma skill, um prompt de revisão ou um comentário de PR pode referenciar `BUN-CORE-03` sem repetir o texto. O corpo completo de cada família vive no satélite correspondente; aqui ficam as invioláveis.

**Convenção:** `MUST` / `NEVER` são normativos. Violação é bug, não questão de estilo.

### `BUN-CORE-*` — invariantes do binário único

| ID | Regra |
| --- | --- |
| `BUN-CORE-01` | Código que usa o global `Bun` **MUST** rodar sob o processo `bun` — não sob `node`, nem sob um CLI com shebang `node` sem `--bun`. |
| `BUN-CORE-02` | Projeto em Bun **MUST** ter type checking explícito no CI (`tsc --noEmit`) — o runtime transpila sem checar tipos. |
| `BUN-CORE-03` | PR que adiciona `jest`, `ts-node`, `nodemon` ou `dotenv` ao `package.json` **MUST** declarar no corpo por que o equivalente embutido não serve — o binário cobre os quatro sem ressalva. **Bundler não entra nesta regra:** ali existe trade-off real, decidido em [Bun - Bundler e Build](bun-bundler-e-build.md) § 10. |
| `BUN-CORE-04` | Módulo com top-level `await` **NEVER** é carregado com `require()`. |
| `BUN-CORE-05` | Afirmação sobre compatibilidade com Node.js **MUST** ser conferida na página de compatibilidade oficial — "funciona no Node" não é evidência. |
| `BUN-CORE-06` | Automação (script, CI, Dockerfile) **MUST** usar `bun run <script>` na forma explícita; a forma curta `bun <script>` perde para um comando embutido de mesmo nome. |
| `BUN-CORE-07` | Flag **do runtime** (`--watch`, `--hot`, `--bun`, `--preload`/`-r`, `--no-env-file`) **MUST** vir antes do subcomando — `bun --preload ./setup.ts run ./index.ts`. Flag **do subcomando** (`--filter`, `--frozen-lockfile`, `--production`, `--coverage`) vem depois dele — `bun install --filter './packages/api'`. Flag posta **depois do nome do script ou do pacote** **NEVER** é do Bun: ali ela é repassada ao alvo. |

### 6.1 Regras críticas dos satélites

As famílias completas vivem nos satélites, mas **estas precisam viajar com o caminho mínimo** — são as que mais aparecem em código gerado e não podem depender de o agente ter aberto o satélite certo.

**Critério de entrada nesta tabela:** a violação é silenciosa (não há erro em dev), ou é de segurança, ou o comportamento contraria o hábito trazido de Node. Regra que o compilador ou um teste pega fica só no satélite.

> **O satélite é canônico.** As linhas abaixo reproduzem o texto do satélite **verbatim**, e não uma paráfrase. Em qualquer divergência entre esta tabela e o satélite, o satélite vence e esta tabela é o bug — a § 7 manda citar por ID sem parafrasear, e duas cópias divergentes de uma regra normativa inviabilizam isso. Esta tabela já teve uma regressão desse tipo: uma versão enxugada de `BUN-SYS-11` perdeu o `process.exit()` e prescrevia um shutdown que deixa o container pendurado até o `SIGKILL`.

| ID | Regra | Satélite |
| --- | --- | --- |
| `BUN-RT-01` | Operação de **diretório** (`mkdir`, `readdir`, `rm`, `stat`) **MUST** usar `node:fs` — `Bun.file`/`Bun.write` só tratam conteúdo de arquivo. | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `BUN-RT-03` | Existência de arquivo **MUST** ser checada com `await file.exists()` — `size === 0` também é o valor de um arquivo inexistente. | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `BUN-RT-05` | Segredo de produção **NEVER** vem de arquivo `.env` carregado pelo runtime. | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `BUN-RT-08` | Handler de servidor HTTP **NEVER** chama `Bun.spawnSync` nem uma API `*Sync` de `node:fs` — bloqueia o event loop do processo inteiro. | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `BUN-RT-09` | Subprocesso de duração não garantida **MUST** receber `timeout` ou `signal`. | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `BUN-RT-10` | Senha **MUST** ser tratada com `Bun.password`; `Bun.hash` **NEVER** toca senha, token ou segredo — é hash não criptográfico. | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `BUN-RT-12` | Execução em produção **MUST** ter `node_modules` presente ou rodar com `--no-install` — sem isso, o auto-install resolve dependências da rede em runtime. | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `BUN-PKG-01` | `bun.lock` **MUST** estar versionado no repositório. | [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) |
| `BUN-PKG-02` | Instalação em CI **MUST** ser `bun ci` ou `bun install --frozen-lockfile` — `bun install` puro reescreve o lockfile e não falha em divergência. | [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) |
| `BUN-PKG-03` | PR que adiciona entrada em `trustedDependencies` **MUST** conter, no corpo, a saída de `bun pm untrusted` que mostra o comando autorizado — sem esse artefato, o PR é reprovado. | [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) |
| `BUN-PKG-04` | Declarar `trustedDependencies` **MUST** reincluir os pacotes da lista padrão ainda necessários — a lista declarada **substitui** a padrão. | [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) |
| `BUN-PKG-08` | `overrides`/`resolutions` **MUST** estar no `package.json` raiz — Bun ignora os declarados em workspace. | [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) |
| `BUN-PKG-09` | Editar um pacote em `node_modules/` **MUST** ser precedido de `bun patch <pkg>`; edição direta corrompe o cache global. | [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) |
| `BUN-TEST-02` | `spyOn` **MUST** ter restauração garantida (`mock.restore()` em `afterEach` ou no preload) — sem isso o spy vaza para os testes seguintes. | [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) |
| `BUN-TEST-03` | `mock.module()` **NEVER** é desfeito por `mock.restore()`; mock de módulo **MUST** ser registrado em `--preload` ou tratado como estado global do processo de teste. | [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) |
| `BUN-TEST-05` | `--update-snapshots` (`-u`) **NEVER** aparece no comando de teste do CI, e o diretório `__snapshots__/` **MUST** estar versionado — snapshot fora do repositório não é asserção. | [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) |
| `BUN-TEST-06` | Teste cuja asserção vive em `catch`, callback ou branch condicional **MUST** declarar `expect.assertions(n)` ou `expect.hasAssertions()`. | [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) |
| `BUN-TEST-09` | Teste que depende de estado deixado por **outro arquivo** **MUST** ser corrigido movendo o setup para dentro do próprio arquivo — `test.serial` **NEVER** resolve isso (ele sequencia dentro do arquivo) e nenhuma flag restaura o global compartilhado sob `--isolate`; a detecção é `bun test --randomize`. | [Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) |
| `BUN-TEST-27` | `coverageThreshold` **MUST** vir acompanhado do reporter `text` habilitado em toda execução fora de `--parallel` — com apenas `--coverage-reporter=lcov` o processo sai `0` mesmo abaixo do limiar. | [Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md) |
| `BUN-TEST-28` | `coverageThreshold` **NEVER** depende da chave `statements` — ela é aceita e **não** é aplicada; o portão real é `lines` e `functions`. | [Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md) |
| `BUN-HTTP-01` | Servidor novo **MUST** declarar suas rotas em `routes`, e `fetch` **NEVER** contém roteamento manual por `URL(req.url).pathname` — com uma única exceção nomeada: o `fetch` que existe apenas para chamar `server.upgrade` (§ 5), porque a doc documenta o upgrade de WebSocket somente dentro de `fetch`. | [Bun - HTTP e Servidor](bun-http-e-servidor.md) |
| `BUN-HTTP-04` | Resposta em streaming ou SSE **MUST** chamar `server.timeout(req, 0)` — o `idleTimeout` padrão de 10 s fecha a conexão no meio da resposta, e o global em `0` não substitui a chamada — e cada evento SSE **MUST** terminar em `\n\n`, porque é a linha em branco que despacha o evento no cliente. | [Bun - HTTP e Servidor](bun-http-e-servidor.md) |
| `BUN-HTTP-07` | Autenticação e autorização do WebSocket **MUST** ocorrer antes de `server.upgrade` — após o `101` não há resposta HTTP para recusar. | [Bun - HTTP e Servidor](bun-http-e-servidor.md) |
| `BUN-HTTP-10` | `development` **NEVER** é ligado em produção em **nenhuma** das duas formas que a opção aceita — nem o booleano `true`, nem o objeto (`{ hmr, console }`, que também liga o modo de desenvolvimento) — e o `error` handler **NEVER** inclui `error.stack` no corpo da resposta. | [Bun - HTTP e Servidor](bun-http-e-servidor.md) |
| `BUN-BUILD-02` | Valores de `define` **MUST** ser produzidos por `JSON.stringify` — a opção inlina o texto literalmente. | [Bun - Bundler e Build](bun-bundler-e-build.md) |
| `BUN-BUILD-03` | `target` **MUST** ser declarado explicitamente em todo build de produção — o default (`"browser"`, ou `"bun"`/`"node"` por shebang/format) muda a resolução em silêncio. | [Bun - Bundler e Build](bun-bundler-e-build.md) |
| `BUN-BUILD-04` | Código que usa `Bun.*` ou `bun:*` **NEVER** é bundleado com `target: "node"` — não há polyfill; a falha aparece só em runtime. | [Bun - Bundler e Build](bun-bundler-e-build.md) |
| `BUN-DATA-01` | `new Database(...)` **MUST** ser aberta com `strict: true`, e com `safeIntegers: true` quando alguma coluna puder exceder 2^53 — os defaults não lançam em parâmetro ausente e truncam inteiros grandes em silêncio. | [Bun - Dados e Persistência](bun-dados-e-persistencia.md) |
| `BUN-DATA-03` | Valor de runtime **NEVER** entra em SQL por concatenação ou por template string fora da tag `sql` — **MUST** ser parâmetro (`$nome`/`?` em `bun:sqlite`, `${}` dentro da tagged template de `Bun.sql`). | [Bun - Dados e Persistência](bun-dados-e-persistencia.md) |
| `BUN-DATA-07` | Dentro de `sql.begin`, toda query **MUST** ser emitida pelo `tx` recebido — o `sql` global usa outra conexão do pool e fica fora da transação. | [Bun - Dados e Persistência](bun-dados-e-persistencia.md) |
| `BUN-DATA-09` | Conexão a banco remoto **MUST** declarar `ssl` explicitamente — o default de `Bun.sql` é `"disable"`. | [Bun - Dados e Persistência](bun-dados-e-persistencia.md) |
| `BUN-DATA-12` | Resultado de query que cruza a fronteira HTTP **MUST** passar por validação de schema — o driver devolve `any` tipado por declaração, não por verificação. | [Bun - Dados e Persistência](bun-dados-e-persistencia.md) |
| `BUN-SYS-01` | Comando externo com valor de runtime **MUST** usar interpolação de `Bun.$`; `child_process.exec` com string concatenada **NEVER** em código novo. | [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) |
| `BUN-SYS-05` | `bun:ffi` e `cc()` **NEVER** entram em caminho de produção — a doc os declara experimentais e recomenda Node-API. | [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) |
| `BUN-SYS-07` | Migração de Node **MUST** enumerar os módulos `node:*` usados pelo código **e pelas dependências transitivas** (grep no fonte e em `node_modules`, `bun why` para achar quem trouxe cada um) e conferir cada um na matriz oficial — 🟡 significa "importa e roda o happy path", não "compatível". | [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) |
| `BUN-SYS-11` | Serviço em container **MUST** registrar listener de `SIGTERM` (e `SIGINT`) que drene o servidor — `await server.stop()` em `Bun.serve`, `server.close()` em `node:http` — e **MUST** terminar chamando `process.exit()`: sem o listener, `beforeExit`/`exit` não são emitidos e as conexões em voo são cortadas; com o listener e sem o `process.exit()`, a saída padrão do sinal fica **suprimida** e o processo só morre no `SIGKILL` do orquestrador. | [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) |

### Famílias completas nos satélites

| Família | Satélite |
| --- | --- |
| `BUN-CORE-*` | esta nota (§ 6) |
| `BUN-RT-*` | [Bun - Runtime e APIs](bun-runtime-e-apis.md) |
| `BUN-PKG-*` | [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) |
| `BUN-TEST-*` | [Bun - Testes](bun-testes.md) (hub da família) e seus seis satélites |
| `BUN-HTTP-*` | [Bun - HTTP e Servidor](bun-http-e-servidor.md) |
| `BUN-BUILD-*` | [Bun - Bundler e Build](bun-bundler-e-build.md) |
| `BUN-DATA-*` | [Bun - Dados e Persistência](bun-dados-e-persistencia.md) |
| `BUN-SYS-*` | [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) |

São **107** regras no total (`BUN-CORE-*` 7 · `BUN-RT-*` 12 · `BUN-PKG-*` 12 · `BUN-TEST-*` 29 · `BUN-HTTP-*` 12 · `BUN-BUILD-*` 11 · `BUN-DATA-*` 12 · `BUN-SYS-*` 12); a § 6.1 acima seleciona 36. Ao citar em revisão, use o ID — o texto completo está no satélite da família.

> **`BUN-TEST-*` cresceu de 12 para 29 em 2026-08-20**, quando o test runner ganhou estrutura própria ([Bun - Testes](bun-testes.md) + seis satélites). Os IDs `01`–`12` mantêm texto e significado: citação antiga continua válida. A § 6 do hub de testes diz qual satélite é dono de cada ID.

---

## 7. Contrato de skill

Como uma skill de Bun deve consumir esta doc.

### O que uma skill de Bun deve carregar

```
SEMPRE:   docs/Bun.md § 2 (modelo mental)
          docs/Bun.md § 3 (fronteiras de import)
          docs/Bun.md § 5 (árvores de decisão)
          docs/Bun.md § 6 + § 6.1 (regras normativas e críticas)

AO ESCREVER código de aplicação:
          docs/Bun - Runtime e APIs.md

AO TOCAR package.json, lockfile, CI ou monorepo:
          docs/Bun - Gerenciador de Pacotes.md

AO ESCREVER ou CORRIGIR teste:
          docs/Bun - Testes.md

SOB DEMANDA, via § 4 (mapa da API):
          o satélite do domínio tocado pela tarefa

NUNCA:    todos os satélites de uma vez
          — exceto MIGRAÇÃO Node→Bun, que legitimamente toca 7 dos 8.
            Caminho nomeado: § 2 + § 5 (árvore "vim do Node") +
            [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) § 5 (matriz) + o satélite
            de cada superfície que a app usa.

          inventar assinatura, flag ou default. O que não estiver no
          satélite MUST ser conferido em bun.com/docs antes de usar —
          a § 4 é um índice de roteamento, não uma allow-list de APIs.
```

### Como citar

Achados de revisão citam o ID da regra e o satélite, não parafraseiam:

> `BUN-PKG-04` — `trustedDependencies` declarado sem reincluir `sharp`, que estava na lista padrão. Os scripts de instalação dele deixaram de rodar.
> Ver [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md).

### Invariantes que a skill deve fazer valer

1. **Verificar antes de afirmar.** Se uma API não está na § 4, ela não foi verificada nesta doc. Consulte bun.com/docs e atualize a nota — não invente assinatura, flag ou default.
2. **A fonte vence.** Divergência entre esta nota e bun.com/docs é bug desta nota.
3. **Confirmar a versão instalada.** Vários recursos citados aqui são recentes. `bun --version` antes de assumir que uma flag existe. Ver as [Notas de verificação](#fontes-consultadas).
4. **Portabilidade é decisão, não default.** Toda vez que a skill escrever `Bun.*`, ela decidiu que o arquivo só roda em Bun. Isso precisa ser intencional (`BUN-CORE-01`).
5. **Type checking é passo separado.** Nenhuma entrega que "roda" está verificada sem `tsc --noEmit` (`BUN-CORE-02`).
6. **Segurança de instalação não é conveniência.** `trustedDependencies` e o linker são decisões de segurança, revisadas como tais (`BUN-PKG-03`, `BUN-PKG-04`).

### Ao criar uma nova skill de Bun

Derive-a de **um** satélite, não desta nota inteira. Para teste, a fonte é a estrutura própria: uma skill focada em testes carrega [Bun - Testes](bun-testes.md) § 2 + § 3 + § 6.1 e **um** dos seis satélites de teste — o contrato completo, com três recortes prontos, está em [Bun - Testes](bun-testes.md) § 7. Registre no início da skill qual satélite é sua fonte, para que a atualização da doc propague. É o mesmo contrato de [React.js](react-js.md) § 7.

---

## 8. Pontes com o stack

Bun toca o meu stack de frontend ([React.js](react-js.md), [TanStack Query](tanstack-query-o-que-um-dev-frontend-precisa-saber.md), [TanStack Router](tanstack-router.md), `Tailwindcss`, `TypeScript`) nos pontos abaixo, e substitui `Node.js` como runtime.

| Problema | Primitiva crua | O que usar no stack |
| --- | --- | --- |
| Rodar **servidor** em dev, com reload | `nodemon` + `ts-node` | `bun <arquivo>` direto (TS/JSX sem build), `bun --hot` para o servidor. **`--hot` não é HMR de browser** — ver [Bun - Runtime e APIs](bun-runtime-e-apis.md) § 7 |
| Rodar o **dev server do frontend** | Vite | continua Vite na maioria dos casos — o dev server e a API de HMR do Bun são declarados *work in progress*. Critério de desempate em [Bun - Bundler e Build](bun-bundler-e-build.md) § 10.1 |
| Servir frontend + API no mesmo processo | dois servidores | `Bun.serve` com import de `.html` em `routes` e `development: true` **só em dev** (`BUN-HTTP-10`) — [Bun - Bundler e Build](bun-bundler-e-build.md) |
| Rodar Vite/Next/CLI de frontend | `npm run dev` | `bun run --bun vite` — força o runtime do Bun num CLI com shebang `node`. Não `bunx`: o pacote é devDependency, e `bunx` sem versão fixa em script versionado viola `BUN-PKG-11` |
| Testar componente React | Jest + jsdom + babel | `bun test` + `@happy-dom/global-registrator` em `[test] preload` — [Bun - Testes](bun-testes.md) |
| Instalar dependências | `npm`/`pnpm` | `bun install`, `bun ci` em CI — [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) |
| Validar payload na fronteira | checagem manual | · |
| Estado de servidor no cliente | `useEffect` + `fetch` | [TanStack Query](tanstack-query-o-que-um-dev-frontend-precisa-saber.md) — |

**Bun como runtime de dev de app React.** A fonte documenta `bun init --react`, que gera um template com app React e servidor de API no mesmo projeto, com `bun dev` (hot reloading), `bun start` (servidor + frontend em um processo) e `bun run build` (site estático em `dist/`). O mecanismo por trás é o import de HTML como rota em `Bun.serve` — o bundler roda em cima das tags `<script>` e `<link>` do HTML, transpilando TS/JSX e processando CSS. Detalhe em [Bun - Bundler e Build](bun-bundler-e-build.md).

**Bun ao lado do Vite, e não no lugar dele.** Em projeto Vite existente, Bun entra como package manager e como runtime do CLI: `bun run --bun vite`. Há um detalhe verificado que evita um bug sutil de configuração — **quando Bun é invocado como `node` (via `bun --bun`, `bunx --bun` ou um symlink `node`), ele desliga o carregamento automático de `.env`**, justamente para que ferramentas com resolução própria de modo (o `loadEnv` do Vite) escolham o `.env.{mode}` correto em vez de enxergar os valores pré-carregados pelo Bun como se fossem do shell. `--env-file` explícito continua valendo.

**`bun test` para código de frontend.** O runner não traz DOM: `document` e `window` não existem por padrão. A receita verificada é `bun add -d @happy-dom/global-registrator`, um arquivo que chama `GlobalRegistrator.register()`, e `[test] preload = ["./happydom.ts"]` no `bunfig.toml`. Em TypeScript, os tipos de DOM exigem `/// <reference lib="dom" />` no topo do arquivo de teste. **Um passo a mais que a doc oficial esconde:** os matchers de `@testing-library/jest-dom` (`toHaveTextContent`, `toBeInTheDocument`) **não** são registrados pelo simples `import` do pacote — é preciso `expect.extend(matchers)` a partir de `@testing-library/jest-dom/matchers`, num preload (`BUN-TEST-12`). Duas páginas da doc oficial divergem nesse ponto; a do guia é a que funciona. Receita completa em [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md) § 2. O que testar continua sendo decisão de estratégia — e.

**A fronteira com `Node.js`.** Bun se apresenta como *drop-in replacement*, e para a maior parte do código de aplicação é. As duas coisas que não transferem: (a) qualquer arquivo que use o global `Bun` deixa de rodar em Node — isso é uma escolha de acoplamento, não um detalhe; (b) a compatibilidade `node:*` é medida contra o Node.js v26 e tem lacunas nomeadas por módulo. Biblioteca publicada em npm que precisa rodar nos dois: use `node:*` e trate `Bun.*` como otimização opcional. Aplicação que você controla: acople sem culpa e registre a decisão. A matriz completa está em [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md).

---

### Framework HTTP em cima do Bun

`Bun.serve` cobre roteamento com params, WebSocket, cookies, TLS e streaming, e **não** cobre middleware componível, validação tipada de entrada, cliente tipado end-to-end, CORS nem mapeamento de erro de domínio para status. Essa lista de ausências é o que [Hono](hono.md) e [Elysia](elysia.md) existem para preencher — e os dois entregam a peça que mais importa para este stack: o tipo do handler chegando ao componente React sem schema duplicado.

**A escolha entre os três tem nota própria: [Backend no runtime Bun](backend-no-runtime-bun.md)**, com árvore de decisão e os cinco eixos que pesam. O que essa nota decide não cabe aqui; o que cabe é o alerta que vale para os dois frameworks: nem `hc` (Hono) nem Eden Treaty (Elysia) **lançam** em resposta de erro, e uma `queryFn` ingênua deixa a query do TanStack Query em `success` com o erro dentro de `data`.

---

## Relacionados

- [Bun - Runtime e APIs](bun-runtime-e-apis.md) · [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) · [Bun - Testes](bun-testes.md) (hub de uma estrutura própria, com seis satélites)
- [Bun - HTTP e Servidor](bun-http-e-servidor.md) · [Bun - Bundler e Build](bun-bundler-e-build.md) · [Bun - Dados e Persistência](bun-dados-e-persistencia.md) · [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md)
- [Backend no runtime Bun](backend-no-runtime-bun.md) — escolher entre `Bun.serve` cru, [Hono](hono.md) e [Elysia](elysia.md)
- `Node.js` — o runtime que Bun busca substituir; a fronteira está na § 8
- `TypeScript` ·
- [React.js](react-js.md) · [TanStack Query](tanstack-query-o-que-um-dev-frontend-precisa-saber.md) · [TanStack Router](tanstack-router.md) · `Tailwindcss` · `Next.js`

## Fontes consultadas

Verificadas diretamente em **2026-08-15**:

- [Welcome to Bun](https://bun.com/docs) · [Bun Runtime](https://bun.com/docs/runtime) · [Bun APIs](https://bun.com/docs/runtime/bun-apis)
- [Globals](https://bun.com/docs/runtime/globals) · [Web APIs](https://bun.com/docs/runtime/web-apis) · [Node.js Compatibility](https://bun.com/docs/runtime/nodejs-compat)
- [Module Resolution](https://bun.com/docs/runtime/module-resolution) · [JSX](https://bun.com/docs/runtime/jsx) · [TypeScript](https://bun.com/docs/typescript)
- [File I/O](https://bun.com/docs/runtime/file-io) · [Environment Variables](https://bun.com/docs/runtime/environment-variables) · [Spawn](https://bun.com/docs/runtime/child-process) · [Shell](https://bun.com/docs/runtime/shell)
- [Watch Mode](https://bun.com/docs/runtime/watch-mode) · [Hashing](https://bun.com/docs/runtime/hashing) · [Utils](https://bun.com/docs/runtime/utils)
- [bun install](https://bun.com/docs/pm/cli/install) · [Lockfile](https://bun.com/docs/pm/lockfile) · [Lifecycle scripts](https://bun.com/docs/pm/lifecycle) · [Isolated installs](https://bun.com/docs/pm/isolated-installs) · [bunx](https://bun.com/docs/pm/bunx)
- [Test runner](https://bun.com/docs/test) · [Mocks](https://bun.com/docs/test/mocks) · [DOM testing](https://bun.com/docs/test/dom) · [Parallel & isolated test runs](https://bun.com/docs/test/parallel)
- [Fullstack dev server](https://bun.com/docs/bundler/fullstack) · [Build a React app with Bun](https://bun.com/docs/guides/ecosystem/react) · [Build a frontend using Vite and Bun](https://bun.com/docs/guides/ecosystem/vite)
- Versão: `https://registry.npmjs.org/bun` — `dist-tags.latest = 1.3.14`, publicada em 2026-05-13.

**Notas de verificação** — pontos em que a fonte contraria o que se assume por hábito:

- **A doc está à frente da versão publicada em pelo menos um ponto.** A página de *Parallel & isolated test runs* mostra saída de exemplo com `bun test v1.4.0`, enquanto `latest` no npm em 2026-08-15 é **1.3.14**. Outras páginas mostram `1.3.3`. Trate `--parallel`, `--isolate`, `--shard` e `--timings` como recursos a confirmar com `bun --version` antes de escrever num CI.
- **O lockfile textual `bun.lock` é o default desde Bun 1.2**; o binário `bun.lockb` é o formato antigo. A doc dá o comando exato de migração. Muita documentação de terceiros ainda fala em `bun.lockb`.
- **`bun install` não ativa `--frozen-lockfile` automaticamente em CI.** A fonte diz isso explicitamente e oferece `bun ci` como atalho. É o oposto do que `npm ci` treina a esperar.
- **`trustedDependencies` substitui a lista padrão, não a estende.** Declarar um único pacote desliga o allow-list embutido para todos os outros — inclusive `sharp` e `esbuild`.
- **O linker default depende de `configVersion` e da presença de workspaces**: monorepo novo nasce `isolated` (modelo pnpm), projeto de pacote único nasce `hoisted`, projeto anterior à v1.3.2 permanece `hoisted`.
- **`bun test --parallel` implica `--isolate`**: cada arquivo ganha um global novo. Sem `--parallel`, o default é o oposto — todos os arquivos compartilham um único global no mesmo processo.
- **`test.only` sozinho não filtra nada**: é preciso rodar `bun test --only`. Um `.only` esquecido não "some com os outros testes" como no Jest — mas também não é inofensivo, porque o CI pode passar a flag.
- **`mock.restore()` não desfaz `mock.module()`.** A fonte é explícita. Mock de módulo é efeito persistente do processo de teste.
- **Bun desliga o carregamento automático de `.env` quando invocado como `node`** (`bun --bun`, `bunx --bun`, symlink `node`), para não atropelar ferramentas com resolução própria de `.env.{mode}` como o Vite.
- **`bun run` respeita lifecycle hooks do seu próprio `package.json`** (`preclean`/`postclean`), mas **não** roda os das dependências instaladas. São dois mecanismos diferentes com o mesmo nome.
