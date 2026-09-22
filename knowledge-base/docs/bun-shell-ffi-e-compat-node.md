---
titulo: Bun - Shell, FFI e Compat Node
Link: https://bun.com/docs/runtime/nodejs-compat
tags:
 - bun
 - nodejs
 - infraestrutura
 - agent-context
source: "Documentação oficial — https://bun.com/docs"
verificado-em: 2026-08-15
---
# Bun - Shell, FFI e Compat Node

> `Bun.$` (Shell — interpolação segura, `.text`/`.json`/`.quiet`/`.nothrow`, `cwd`/`env`, redirecionamento) · `bun:ffi` (`dlopen`, `cc`) e quando **não** usar · `Worker` e paralelismo · **a matriz de compatibilidade com Node**: o que é completo, parcial e ausente · comportamento de `process` · deploy (imagem `oven/bun`, `--smol`, sinais, graceful shutdown, variáveis de ambiente).
>
> **Não cobre:** APIs `Bun.*` de I/O e utilidade ([Bun - Runtime e APIs](bun-runtime-e-apis.md)) · `Bun.serve` e o ciclo de vida do servidor HTTP ([Bun - HTTP e Servidor](bun-http-e-servidor.md)) · `--compile` e o binário único ([Bun - Bundler e Build](bun-bundler-e-build.md)) · drivers de banco ([Bun - Dados e Persistência](bun-dados-e-persistencia.md)).

Entrada: [Bun](bun.md) § 5 (árvores de decisão) · § 6 (regras normativas) · Base normativa: [Bun](bun.md)

Versão verificada: **Bun 1.3.14** (`bun@latest` no registry npm, 2026-08-15). Matriz de compatibilidade aferida contra **Node.js v26**, conforme declarado na própria página.

---

## 1. Conceito: a compatibilidade com Node é boa o bastante para enganar

A frase da doc é uma promessa de suporte, não uma descrição de estado: *"If a package works in Node.js but doesn't work in Bun, we consider it a bug in Bun."*

**A legenda, antes de qualquer coisa.** A página oficial marca cada módulo com um de três símbolos, e eles são usados como vocabulário normativo em toda esta estrutura — inclusive em `BUN-SYS-07` e no hub. Esta é a definição canônica:

| Símbolo | O que a fonte quer dizer | O que significa para você |
| --- | --- | --- |
| 🟢 | **completo.** O módulo é implementado; a página frequentemente cita o percentual da suíte de testes do Node que passa | usar sem cerimônia — mas leia a ressalva nominal, porque vários 🟢 têm uma (§ 5) |
| 🟡 | **parcial.** Implementado, com a página nomeando o que falta | **importa, instancia e roda o happy path.** A falha vem na condição específica que a linha da matriz nomeia. É o estado perigoso |
| 🔴 | **ausente.** Não implementado | falha imediatamente, com a substituição indicada na própria página |

O estado real, contado pela própria matriz: de todos os módulos `node:*` listados, **exatamente um está marcado 🔴** (`node:sea`). Todo o resto é 🟢 ou 🟡. Isso é excelente — e é precisamente o que torna a migração perigosa.

Um módulo 🔴 falha na primeira linha e você descobre em dois minutos. Um módulo 🟡 importa, instancia, roda o happy path, e falha **na condição específica que você não testou**: a curva EC que a lib de assinatura usa, a resumption de sessão TLS entre processos, o `AsyncLocalStorage` que não atravessa um `Worker`, o `eventLoopUtilization` que devolve zero e faz o painel mentir.

**O valor desta nota não é dizer que Bun é compatível. É dizer exatamente onde a compatibilidade termina.** A § 5 é a seção mais importante do satélite.

---

## 2. `Bun.$`: bash reimplementado em processo, seguro por default

**Conceito.** A afirmação que muda tudo está no fim da página: *"Bun Shell **does not invoke a system shell** like `/bin/sh`. It's a re-implementation of bash that runs in the same Bun process."*

Não há `/bin/sh -c`. Logo não há uma string sendo reparseada por um shell. Ao montar os argumentos, Bun trata **toda variável interpolada como uma única string literal**. Isso elimina command injection por construção:

```ts
import { $ } from "bun";

const entrada = "relatorio.pdf; rm -rf /";
await $`ls ${entrada}`; // procura um arquivo chamado "relatorio.pdf; rm -rf /"
```

Compare com o hábito de `child_process`: `exec("ls " + entrada)` entrega a string ao `/bin/sh`, e o `;` separa comandos. **É por isso que `Bun.$` substitui `child_process.exec` com string concatenada**, não por conveniência.

**A API do resultado:**

| Chamada | Devolve |
| --- | --- |
| `` await $`cmd` `` | `{ stdout, stderr }` como `Buffer`; a saída também vai para o terminal |
| `.quiet` | mesma coisa, sem escrever no terminal |
| `.text` | `string` — **já chama `.quiet` sozinho** |
| `.json` | valor parseado |
| `.lines` | async iterator, linha a linha |
| `.blob` | `Blob` |

**Erro.** Exit code diferente de zero **lança** por default, com um `ShellError` que carrega `exitCode`, `stdout` e `stderr`. `.nothrow` desliga por comando; `$.nothrow` / `$.throws(false)` mudam o default global do processo — mudança global que obriga a checar `exitCode` em **todo** comando dali em diante.

**Contexto.** `.cwd(caminho)` e `.env(obj)` por comando; `$.cwd(...)` e `$.env(...)` mudam o default. Sem `.env`, os comandos herdam `process.env`.

```ts
import { $ } from "bun";

// diretório e ambiente por comando, sem tocar no processo
const versao = await $`git rev-parse --short HEAD`.cwd(repo).text;

// checagem explícita em vez de exceção
const { exitCode, stderr } = await $`bun test`.cwd(repo).nothrow.quiet;
if (exitCode !== 0) {
 throw new Error(`testes falharam:\n${stderr.toString}`);
}

// redirecionamento para objetos JavaScript
const resposta = await fetch("https://exemplo.com/dados.csv");
const linhas = await $`wc -l < ${resposta}`.text; // Response como stdin
```

Redirecionamento aceita os operadores de bash (`<`, `>`, `>>`, `2>`, `&>`, `2>&1`, `1>&2`) e também objetos JavaScript nos dois sentidos: `Buffer`/TypedArray/`ArrayBuffer`, `Bun.file(path)`, e `Response` como entrada. Pipe (`|`) e substituição (`$(...)`) funcionam.

**Builtins cross-platform** (funcionam no Windows sem `cross-env`/`rimraf`): `cd`, `ls`, `rm`, `echo`, `pwd`, `bun`, `cat`, `touch`, `mkdir`, `which`, `mv`, `exit`, `true`, `false`, `yes`, `seq`, `dirname`, `basename`. `mv` é parcial — falta suporte cross-device.

**Onde a proteção acaba** — a doc nomeia dois casos, e ambos continuam sendo sua responsabilidade:

1. **Você mesmo abrir um shell.** `` await $`bash -c "echo ${entrada}"` `` entrega o controle ao `bash`, e as garantias de Bun deixam de valer dentro daquela string.
2. **Argument injection.** Bun passa a string como um argumento único — mas o programa alvo interpreta seus próprios argumentos. O exemplo da doc: `branch = "--upload-pack=echo pwned"` em `` $`git ls-remote origin ${branch}` `` é passado com segurança e o `git` obedece a flag.

O segundo caso é o que `BUN-SYS-03` cobre, e "validar contra a possibilidade de ser lido como flag" não é revisável. O critério que é: **um argumento de runtime não pode começar com `-`**, ou tem que vir depois do separador `--`, que a maioria dos programas de linha de comando entende como "daqui em diante nada é flag".

```ts
// ✅ rejeitar: a guarda mais simples, e a que serve para nome de branch, path, id
if (branch.startsWith("-")) throw new Error("nome de branch inválido");
await $`git ls-remote origin ${branch}`;

// ✅ separador: quando o valor pode legitimamente começar com "-"
await $`grep -e ${padrao} -- ${arquivo}`;

// ✅ o melhor de todos, quando o formato é conhecido: allowlist por regex
if (!/^[\w./-]+$/.test(branch) || branch.startsWith("-")) throw new Error("inválido");
```

Nem todo programa respeita `--`, então a rejeição por `-` inicial é a guarda de default. Ela é uma linha, aparece no diff e um revisor consegue apontar que falta.

`$.escape(str)` expõe a lógica de escaping; `{ raw: "..." }` desliga o escaping deliberadamente.

| ID | Regra |
| --- | --- |
| `BUN-SYS-01` | Comando externo com valor de runtime **MUST** usar interpolação de `Bun.$`; `child_process.exec` com string concatenada **NEVER** em código novo. |
| `BUN-SYS-02` | Valor de entrada externa **NEVER** é interpolado dentro de um `sh -c` / `bash -c` disparado por `Bun.$` — ali as garantias de escaping não valem. |
| `BUN-SYS-03` | Argumento de runtime passado a um programa externo **MUST** ser rejeitado quando começa com `-`, ou ser precedido do separador `--` na linha de comando — sem uma das duas guardas, o valor é entregue com segurança e o programa alvo o obedece como flag. |
| `BUN-SYS-04` | `$.nothrow` / `$.throws(false)` **NEVER** é chamado em escopo global de aplicação — use `.nothrow` no comando específico. |

---

## 3. `bun:ffi`: experimental, e a doc diz para não usar em produção

**Conceito.** `bun:ffi` chama bibliotecas nativas com ABI C direto do JavaScript. O aviso é a primeira coisa na página, e é categórico:

> "`bun:ffi` is **experimental**, with known bugs and limitations. Do not rely on it in production."

E ela indica a alternativa: *"The most stable way to interact with native code from Bun is to write a Node-API module."*

Registrado o aviso, a forma:

```ts
import { dlopen, FFIType, suffix } from "bun:ffi";

// suffix é "dylib" | "so" | "dll" conforme a plataforma
const { symbols } = dlopen(`libminhalib.${suffix}`, {
 somar: { args: [FFIType.i32, FFIType.i32], returns: FFIType.i32 },
});

symbols.somar(1, 2);
```

Performance verificada: cerca de **2 a 6x mais rápido que FFI de Node.js via Node-API**, porque `dlopen`, `linkSymbols`, `CFunction` e `JSCallback` são implementados dentro do JavaScriptCore — conversão de argumento e boxing do retorno acontecem na engine, e sites de chamada quentes compilam para chamada nativa direta pelos tiers DFG/FTL.

`cc` compila e roda C em runtime, embutindo o TinyCC; a página do compilador C também declara suporte **experimental**. `JSCallback` tem suporte **experimental** a callbacks thread-safe, necessário quando o callback cruza threads (`threadsafe: true`).

**A árvore de decisão é curta:**

```
Preciso chamar código nativo?
├── É um pacote npm que já traz binding → use o pacote (Node-API funciona)
├── Preciso disso em produção → escreva um módulo Node-API
└── É protótipo, script ou benchmark → bun:ffi
```

| ID | Regra |
| --- | --- |
| `BUN-SYS-05` | `bun:ffi` e `cc` **NEVER** entram em caminho de produção — a doc os declara experimentais e recomenda Node-API. |

---

## 4. `Worker`: paralelismo real, também marcado experimental

**Conceito.** `Worker` é global, roda uma segunda instância de JavaScript em outra thread, compartilha recursos de I/O com a main thread, e aceita TypeScript/JSX sem build. Não precisa de `{ type: "module" }`.

E também traz aviso: *"The `Worker` API is still experimental (particularly for terminating workers)."*

Pontos verificados que mudam o código:

- **Mensagens são enfileiradas até o worker estar pronto** — não é preciso esperar o evento `"open"` (que é extensão do Bun, não existe no browser) para chamar `postMessage`.
- **`preload`** (string ou array) carrega módulos antes do código do worker; a doc cita OpenTelemetry, Sentry e DataDog como o caso de uso.
- **`smol: true`** no construtor reduz memória à custa de performance (define `JSC::HeapSize` como `Small`).
- Especificadores são resolvidos **relativos à raiz do projeto**, como `bun./caminho/arquivo.js`.
- Falha ao resolver o script emite evento `"error"` no objeto `Worker`.

```ts
const worker = new Worker("./workers/relatorio.ts", {
 preload: ["./instrumentacao.ts"], // roda antes do código do worker
 smol: true,
});

worker.postMessage({ pedidoId }); // enfileirado se o worker ainda não subiu
worker.onmessage = (e) => salvarRelatorio(e.data);
```

**A pegadinha que só aparece em observabilidade:** a matriz de compat declara que **Bun não propaga contexto de `AsyncLocalStorage` para eventos de `MessagePort`, `BroadcastChannel` nem `Worker`.** Trace id que atravessa a fronteira do worker some. Passe o contexto explicitamente na mensagem.

| ID | Regra |
| --- | --- |
| `BUN-SYS-06` | Contexto de rastreamento (trace id, request id) **MUST** ser enviado explicitamente na mensagem ao `Worker` — `AsyncLocalStorage` não atravessa a fronteira. |

---

## 5. A matriz de compatibilidade: onde a compatibilidade termina

**Conceito.** A página oficial marca cada módulo com 🟢, 🟡 ou 🔴 (legenda na § 1) e descreve o que falta. Verificação de 2026-08-15, contra **Node.js v26**.

### Como enumerar o que a sua app usa

`BUN-SYS-07` manda conferir a matriz "para cada módulo `node:*` usado", e essa instrução não vale nada sem um método para produzir a lista — que precisa incluir as **dependências transitivas**, porque o `node:crypto` que vai quebrar quase nunca é o seu. **Não existe comando de Bun que enumere o uso de `node:*` de uma árvore de dependências**; o que existe é `bun why`, que responde à pergunta inversa. O método é, então, montado à mão, e são três passos:

```bash
# 1. o seu código: especificadores node:* explícitos
rg -o --no-filename 'node:[a-z_]+' src | sort -u

# 1b. os nomes legados sem prefixo, que o Node ainda aceita.
# O ponto no padrão casa a aspa, simples ou dupla.
rg -n -e 'from.(assert|async_hooks|buffer|child_process|cluster|crypto|dgram|dns|events|fs|http|http2|https|module|net|os|path|perf_hooks|readline|stream|timers|tls|tty|url|util|v8|vm|worker_threads|zlib).' src

# 2. as dependências, incluindo transitivas — o passo que ninguém faz
rg -o --no-filename 'node:[a-z_]+' node_modules | sort -u

# 3. para cada módulo 🟡 que aparecer no passo 2, descubra quem o trouxe
bun why <pacote>
```

Duas limitações a declarar em voz alta, porque um método que se apresenta como completo é pior que nenhum:

- **`rg` sobre `node_modules` é uma aproximação, nos dois sentidos.** Não vê `require(variável)`, import dinâmico com string montada, nem o que um addon nativo chama por baixo — e, do outro lado, casa ocorrências em comentários, em código morto e em ramos que a sua app nunca executa. Serve para produzir a lista de **candidatos**, não uma prova.
- **`bun why` explica por que um pacote está instalado**, mostrando a cadeia de dependências (`bun why react`, com `--top` e `--depth`, e aceitando glob como `@types/*`). Ele **não** enumera módulos `node:*`. É a ferramenta do passo 3, não do passo 1.

O resultado prático que vale o esforço: a lista do passo 2 cruzada com as linhas 🟡 desta seção é uma lista curta, e cada item dela é uma pergunta específica ("essa lib assina com secp256k1?") em vez de uma preocupação difusa.

### O que é 🟢 completo

`node:assert` · `node:buffer` · `node:console` · `node:dgram` · `node:dns` · `node:events` · `node:fs` · `node:http` · `node:http2` · `node:net` · `node:os` · `node:path` · `node:punycode` (deprecado pelo próprio Node) · `node:querystring` · `node:readline` · `node:sqlite` · `node:stream` · `node:string_decoder` · `node:timers` (+ `/promises`) · `node:trace_events` · `node:tty` · `node:url` · `node:zlib` · `node:quic`

Mesmo entre os 🟢 há ressalvas nominais que quebram bibliotecas específicas:

| Módulo 🟢 | Ressalva verificada |
| --- | --- |
| `node:console` | Bun escreve direto nos file descriptors. **Substituir `process.stdout.write` não captura a saída** — quebra libs de captura de log em teste |
| `node:buffer` | um `Buffer` é limitado a **4 GiB** |
| `node:http` | `http.Server` **não estende** `net.Server`; `listen(handle)` e as opções `fd`, `ipv6Only`, `signal` são ignoradas; `keepAlive` no servidor é no-op |
| `node:stream` | `isReadable`/`isWritable`/`isErrored`/`Readable.isDisturbed` só entendem streams de Node, não web streams |
| `node:path` | `matchesGlob` usa a semântica de `Bun.Glob`, não minimatch (`*` casa dotfiles, sem extglob) |
| `node:fs` | `Stats` não tem os getters `Temporal.Instant` (`atimeInstant` e afins) |

### O que é 🟡 parcial — e a parte que falta importa

| Módulo | O que falta, e o sintoma |
| --- | --- |
| **`node:crypto`** | BoringSSL: faltam os tipos de chave `ed448`, `x448`, `rsa-pss`, `dsa`, `dh`; **curvas EC além de P-224/256/384/521 — não há `secp256k1`**; cifras CCM, OCB, XTS e `chacha20-poly1305`. `argon2` e `setEngine` lançam. → **quebra assinatura de blockchain e hashing Argon2** |
| **`node:async_hooks`** | `AsyncLocalStorage` e `AsyncResource` funcionam. `createHook`, `executionAsyncId`, `triggerAsyncId`, `executionAsyncResource` são **stubs**; async ids são sempre `0`. Contexto não propaga para `MessagePort`/`BroadcastChannel`/`Worker` → **instrumentação APM baseada em hooks não vê nada** |
| **`node:tls`** | Faltam `pskCallback`, OCSP stapling (`requestOCSP`), os eventos de servidor `newSession`/`resumeSession` e as chaves de ticket de sessão (`ticketKeys` é ignorado) → **resumption de sessão não funciona entre processos**. Por causa do BoringSSL, `tlsSocket.renegotiate` sempre falha e `getEphemeralKeyInfo`/`getSharedSigalgs` não devolvem informação |
| **`node:https`** | `request`, `get`, `Agent` e `globalAgent` são implementados, incluindo pooling de conexão. `https.Server` é um `http.Server` com opções de TLS, não um `tls.Server`. Sockets de request **não** são `TLSSocket`: `encrypted`, `authorized` e `servername` funcionam, mas `getPeerCertificate` e `getCipher` **faltam**. `setSecureContext`, `addContext`, **`SNICallback`** e `handshakeTimeout` **não são suportados** → quebra autenticação por certificado de cliente, e quebra TLS multi-domínio por callback de SNI |
| **`node:child_process`** | `serialization: "advanced"` **só funciona entre processos Bun** — para IPC Bun↔Node use JSON. Não dá para passar `stdout`/`stderr` de um filho como `stdio` de outro |
| **`node:cluster`** | `net` e `dgram` são compartilhados pelo primário como no Node. **Servidores `node:http`/`node:https` em workers fazem bind próprio — balanceamento HTTP entre processos só em Linux** (`SO_REUSEPORT`). A doc diz "implementado, mas não testado em batalha" |
| **`node:perf_hooks`** | **`eventLoopUtilization` sempre devolve zeros**; não há entradas `gc`, `dns` nem `resource`; `performance.nodeTiming` é placeholder → **painel de event loop lag mente** |
| **`node:v8`** | `serialize`/`deserialize` usam o formato de fio do **JavaScriptCore, não o do V8** → payload serializado não atravessa entre Node e Bun. Sem `Serializer`/`Deserializer`, `queryObjects`, `promiseHooks` |
| **`node:module`** | `module.register` é **no-op** (a doc recomenda `Bun.plugin`); `syncBuiltinESMExports`, `module._load`, `module._pathCache` também. `findSourceMap` sempre devolve `undefined` → **loaders/hooks de instrumentação por `module.register` não rodam** |
| **`node:test`** | parcialmente implementado; a maioria das opções de `run` lança `ERR_NOT_IMPLEMENTED`, `test.only` não filtra. A doc recomenda **`bun:test`** ([Bun - Testes](bun-testes.md)) |
| **`node:worker_threads`** | `resourceLimits` e `trackUnmanagedFds` ignorados; `execArgv` só define `process.execArgv`; `eventLoopUtilization` é stub |
| **`node:util`** | faltam `diff`, `transferableAbortSignal`, `transferableAbortController` |
| **`node:vm`**, `node:wasi`, `node:inspector`, `node:repl`, `node:domain`, `node:diagnostics_channel` | parciais, com ressalvas na página |

### O que é 🔴 ausente

**Apenas `node:sea`** (Single Executable Applications). A doc indica `bun build --compile` no lugar ([Bun - Bundler e Build](bun-bundler-e-build.md)).

### `process` e globais

`process` é 🟡. Verificado:

- **`process.title` é no-op em macOS e Linux.**
- `getActiveResourcesInfo`, `_getActiveHandles`, `_getActiveRequests` **sempre devolvem array vazio**.
- `setSourceMapsEnabled` é no-op; `process.report.writeReport` **não escreve nada**.
- `process.binding` é parcial: `buffer`, `config`, `constants`, `fs`, `natives`, `tty_wrap`, `util`, `uv` existem; o resto lança.

Nos globais web, três detalhes que produzem bug silencioso:

- **`structuredClone`**: só `ArrayBuffer` e `MessagePort` são transferíveis, e **um `Error` clonado perde o `cause`**.
- **`ReadableStream`, `WritableStream` e `TransformStream` não podem ser transferidos** por `postMessage`/`structuredClone`.
- **`Request`**: faltam `keepalive` e `duplex`; `credentials`, `integrity`, `referrer` e `referrerPolicy` são **aceitos e ignorados** — não lançam.

| ID | Regra |
| --- | --- |
| `BUN-SYS-07` | Migração de Node **MUST** enumerar os módulos `node:*` usados pelo código **e pelas dependências transitivas** (grep no fonte e em `node_modules`, `bun why` para achar quem trouxe cada um) e conferir cada um na matriz oficial — 🟡 significa "importa e roda o happy path", não "compatível". |
| `BUN-SYS-08` | Código que depende de `secp256k1`, `argon2`, `ed448`/`x448` ou das cifras CCM/OCB/XTS/`chacha20-poly1305` **NEVER** presume `node:crypto` em Bun — BoringSSL não os tem. |
| `BUN-SYS-09` | Observabilidade **NEVER** se apoia em `createHook`, `executionAsyncId` ou `eventLoopUtilization` em Bun — são stubs que devolvem `0`. Use `AsyncLocalStorage`, que é implementado. |
| `BUN-SYS-10` | IPC entre um processo Bun e um processo Node **MUST** usar serialização JSON — `serialization: "advanced"` só funciona entre processos Bun. |

---

## 6. Deploy: imagem, memória, sinais e ambiente

**Imagem oficial.** `oven/bun`, com tags em `hub.docker.com/r/oven/bun/tags`. O `Dockerfile` da doc é multi-stage, e são **quatro** stages — `base`, `install`, `prerelease` e `release`. Os quatro importam: o `prerelease` é o que tem o código-fonte e as `devDependencies`, e é dele que o `release` copia os arquivos da aplicação. Cortar o `prerelease` e manter o `COPY --from=prerelease` produz um Dockerfile que não builda.

```dockerfile
# imagem oficial; tags em https://hub.docker.com/r/oven/bun/tags
FROM oven/bun:1 AS base
WORKDIR /usr/src/app

# 1. dependências em stage separado: cacheia entre builds
# dois installs, porque teste e build precisam das devDependencies
FROM base AS install
RUN mkdir -p /temp/dev
COPY package.json bun.lock /temp/dev/
# --frozen-lockfile: falha se o lockfile divergir, em vez de "resolver"
RUN cd /temp/dev && bun install --frozen-lockfile

RUN mkdir -p /temp/prod
COPY package.json bun.lock /temp/prod/
# --production: sem devDependencies no que vai para a imagem final
RUN cd /temp/prod && bun install --frozen-lockfile --production

# 2. stage com o fonte completo: é aqui que teste e build rodam
FROM base AS prerelease
COPY --from=install /temp/dev/node_modules node_modules
COPY..
ENV NODE_ENV=production
RUN bun test
RUN bun run build

# 3. imagem final: dependências de produção + o que o prerelease produziu
FROM base AS release
COPY --from=install /temp/prod/node_modules node_modules
COPY --from=prerelease /usr/src/app/index.ts.
COPY --from=prerelease /usr/src/app/package.json.

# 4. usuário não-root já existe na imagem
USER bun
EXPOSE 3000/tcp
# --no-env-file: a configuração vem do orquestrador, nunca de um.env na imagem
ENTRYPOINT [ "bun", "run", "--no-env-file", "index.ts" ]
```

As quatro decisões: **`--frozen-lockfile`** (build reprodutível, e falha ruidosa quando o lockfile está desatualizado — ver [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md)), **`--production`** na cópia que vai para a imagem final, **`USER bun`** (a imagem já traz o usuário) e **`--no-env-file`** no `ENTRYPOINT`, que é a terceira cláusula de `BUN-SYS-12` e a que mais se esquece: sem ela, um `.env` que escapou do `.dockerignore` é carregado em silêncio e sobrescreve o que o orquestrador injetou. A forma `bun run --no-env-file <arquivo>` é a documentada.

Acompanhe com um `.dockerignore` — a doc lista `.env` entre as entradas, junto de `node_modules`, `.git`, `Dockerfile*` e `.vscode`. Para composição local. Se a alternativa for distribuir um binário em vez de uma imagem com `node_modules`, o caminho é `bun build --compile` em [Bun - Bundler e Build](bun-bundler-e-build.md) § 8.

**`--smol`.** A descrição verificada é mais estreita do que o nome sugere: `--smol` faz o coletor de lixo **rodar com mais frequência**, o que pode desacelerar a execução. Bun já ajusta o tamanho do heap conforme a memória disponível (respeitando cgroups e outros limites) **com e sem a flag** — então `--smol` é útil principalmente quando você quer que o heap **cresça mais devagar**, não como um "modo container". Em `Worker`, o equivalente é `smol: true`.

**Sinais e shutdown.** `process.on("SIGTERM" | "SIGINT", …)` funciona. O ponto que decide se o shutdown é limpo está na doc de sinais, e contraria o hábito:

> Nem `"beforeExit"` nem `"exit"` são emitidos quando o processo é morto por um sinal para o qual **não há listener**. Para rodar limpeza em um sinal, registre o listener daquele sinal e chame `process.exit` a partir dele.

Ou seja: sem listener de `SIGTERM`, o container recebe o sinal do orquestrador e morre **sem** passar por `beforeExit`. Conexões em voo são cortadas.

**E o inverso, que é a metade esquecida:** registrar o listener **suprime a ação padrão do sinal**. O default de `SIGTERM` é terminar o processo; ao registrar um handler, você assume essa responsabilidade. Um listener que faz a limpeza e **não** chama `process.exit` deixa o processo vivo — o orquestrador espera o `terminationGracePeriod` inteiro e manda `SIGKILL`. O sintoma é um container que demora exatamente 30 segundos para morrer em todo deploy, e ninguém liga isso a uma linha faltando. **`process.exit` não é limpeza cosmética; é o que faz o processo sair.** Esta é a razão de `BUN-SYS-11` nomear as duas coisas.

```ts
const server = Bun.serve({ /* … */ });

async function desligar(sinal: string) {
 console.log({ msg: "shutdown iniciado", sinal });

 // para de aceitar; espera as requisições em voo terminarem
 await server.stop;
 await sql.close({ timeout: 5 });

 process.exit(0); // sem isto, o listener impede a saída padrão do sinal
}

// sem estes listeners, beforeExit/exit não rodam quando o sinal chega
process.on("SIGTERM", => desligar("SIGTERM")); // orquestrador
process.on("SIGINT", => desligar("SIGINT")); // Ctrl+C
```

`await server.stop` é o par correto: fecha keep-alive ociosas, espera as requisições em voo e resolve quando toda conexão fechou ([Bun - HTTP e Servidor](bun-http-e-servidor.md) § 6).

**Se o servidor não for `Bun.serve`.** `server.stop` é API de `Bun.serve`, e vale separar o que na regra é dela do que não é:

| Parte de `BUN-SYS-11` | Depende de `Bun.serve`? |
| --- | --- |
| Registrar listener de `SIGTERM`/`SIGINT` | **não** — é `process`, vale em qualquer servidor rodando sob Bun |
| Chamar `process.exit` ao fim do handler | **não** — é a ação padrão suprimida, mesma coisa em qualquer app |
| `await server.stop` como forma de drenar | **sim** — é a instância `Bun.serve` do passo "pare de aceitar e espere o que está em voo" |

Num app em `node:http` (Express, Fastify e o que mais rodar em cima dele), o passo do meio é `server.close`, que na semântica do Node para de aceitar conexões novas e chama o callback quando as existentes terminam. A matriz marca `node:http` como 🟢 e **não** lista `close` entre as lacunas — mas lista que `keepAlive` e `keepAliveInitialDelay` **no servidor são no-op**, e keep-alive ociosa é justamente o que costuma fazer um `close` pendurar em Node. **Não verificado nesta sessão:** o comportamento de `server.closeIdleConnections` e `server.closeAllConnections` sob Bun — a matriz não os menciona em nenhum dos sentidos. Se o seu shutdown depende deles, meça antes de confiar.

```ts
// equivalente em node:http — a estrutura é a mesma, o meio muda
import { createServer } from "node:http";
const server = createServer(app);

function desligar(sinal: string) {
 console.log({ msg: "shutdown iniciado", sinal });
 server.close(async => { // para de aceitar; espera as em voo
 await sql.close({ timeout: 5 });
 process.exit(0); // continua obrigatório, pela mesma razão
 });
}

process.on("SIGTERM", => desligar("SIGTERM"));
process.on("SIGINT", => desligar("SIGINT"));
```

O que fazer com um servidor `node:http` que já existe — manter, embrulhar ou migrar para `Bun.serve` — é decisão, não API, e está em [Backend no runtime Bun](backend-no-runtime-bun.md). [Bun - HTTP e Servidor](bun-http-e-servidor.md) § 7.2 declara o mesmo limite do lado do HTTP.

**Variáveis de ambiente.** Bun lê `.env` automaticamente, em ordem **crescente** de precedência: `.env` → `.env.production` / `.env.development` / `.env.test` (conforme `NODE_ENV`) → `.env.local`. `--env-file=...` (repetível) troca a lista; **`--no-env-file` desliga o carregamento automático**, e a doc aponta produção e CI/CD como o caso de uso — o container deve receber variáveis do orquestrador, não de um arquivo que vazou para a imagem. Contexto em `Arquivos.env não substituem secret management` e.

| ID | Regra |
| --- | --- |
| `BUN-SYS-11` | Serviço em container **MUST** registrar listener de `SIGTERM` (e `SIGINT`) que drene o servidor — `await server.stop` em `Bun.serve`, `server.close` em `node:http` — e **MUST** terminar chamando `process.exit`: sem o listener, `beforeExit`/`exit` não são emitidos e as conexões em voo são cortadas; com o listener e sem o `process.exit`, a saída padrão do sinal fica **suprimida** e o processo só morre no `SIGKILL` do orquestrador. |
| `BUN-SYS-12` | Imagem de produção **MUST** instalar com `bun install --frozen-lockfile --production`, **MUST** rodar como `USER bun` e **MUST** receber configuração pelo ambiente do orquestrador, com `--no-env-file` no `ENTRYPOINT` — arquivo `.env` **NEVER** vai para a imagem. |

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| `child_process.exec("ls " + entrada)` | o `/bin/sh` reparseia a string; `;` separa comandos | `` $`ls ${entrada}` `` — `BUN-SYS-01` |
| `` $`bash -c "echo ${entrada}"` `` | você abriu um shell explicitamente; o escaping de Bun não vale lá dentro | passar o valor como argumento, sem shell aninhado — `BUN-SYS-02` |
| `` $`git ls-remote origin ${branch}` `` com `branch` do usuário | `--upload-pack=...` é passado com segurança e o `git` obedece | rejeitar valor iniciado por `-`, ou usar `--` — `BUN-SYS-03` |
| Container que só morre no `SIGKILL`, 30 s depois de todo deploy | há listener de `SIGTERM`, mas ele não chama `process.exit`; o listener suprimiu a saída padrão do sinal | `process.exit` no fim do handler — `BUN-SYS-11` |
| `ENTRYPOINT [ "bun", "run", "index.ts" ]` sem `--no-env-file` | um `.env` que escapou do `.dockerignore` sobrescreve o que o orquestrador injetou, em silêncio | `bun run --no-env-file index.ts` — `BUN-SYS-12` |
| Copiar o Dockerfile da doc sem o stage `prerelease` | `COPY --from=prerelease` referencia stage inexistente; o build falha | manter os quatro stages — § 6 |
| "Conferi os `node:*` que eu importo" | o `node:crypto` que quebra quase sempre está numa dependência transitiva | enumerar `node_modules` também — `BUN-SYS-07` |
| `$.nothrow` no boot da aplicação | todo comando dali em diante passa a falhar em silêncio | `.nothrow` pontual — `BUN-SYS-04` |
| `bun:ffi` para uma dependência de produção | declarado experimental, com bugs conhecidos, pela própria doc | módulo Node-API — `BUN-SYS-05` |
| Assumir `secp256k1` em `node:crypto` | BoringSSL não implementa a curva; falha só quando a assinatura é chamada | biblioteca em JS/WASM, ou verificar antes — `BUN-SYS-08` |
| Painel de saúde lendo `eventLoopUtilization` | sempre devolve zeros em Bun; o gráfico fica reto e ninguém percebe | métrica própria — `BUN-SYS-09` |
| APM baseado em `createHook`/`executionAsyncId` | stubs; async ids sempre `0` | `AsyncLocalStorage`, que é implementado — `BUN-SYS-09` |
| `AsyncLocalStorage` esperando atravessar um `Worker` | contexto não propaga por `MessagePort`/`Worker`; o trace id some | enviar na mensagem — `BUN-SYS-06` |
| `serialization: "advanced"` em IPC com processo Node | só funciona entre processos Bun; a mensagem não chega | JSON — `BUN-SYS-10` |
| Substituir `process.stdout.write` para capturar log em teste | Bun escreve direto no file descriptor; nada é capturado | usar o mecanismo de captura de `bun:test` |
| Container sem listener de `SIGTERM` | `beforeExit`/`exit` não são emitidos; conexões em voo morrem no meio | listener + `server.stop` + `process.exit` — `BUN-SYS-11` |
| `.env` copiado para a imagem Docker | segredo versionado na camada da imagem, legível por quem puxar | variáveis do orquestrador + `--no-env-file` — `BUN-SYS-12` |
| `--smol` esperando reduzir uso de memória em container | a flag aumenta a frequência de GC; Bun já ajusta o heap por cgroup com e sem ela | ajustar o limite do container; usar `--smol` só para conter crescimento do heap |
| `node:cluster` para balancear HTTP em macOS | servidores HTTP em workers fazem bind próprio; só Linux balanceia (`SO_REUSEPORT`) | `reusePort` em Linux — [Bun - HTTP e Servidor](bun-http-e-servidor.md) |

---

## Checklist de revisão

- [ ] Nenhum `child_process.exec` com string concatenada? → `BUN-SYS-01`
- [ ] Nenhuma interpolação dentro de `bash -c` / `sh -c`? → `BUN-SYS-02`
- [ ] Argumentos de runtime são rejeitados quando começam por `-`, ou vêm depois de `--`? → `BUN-SYS-03`
- [ ] `$.nothrow` global ausente? → `BUN-SYS-04`
- [ ] Nenhum `bun:ffi` / `cc` em caminho de produção? → `BUN-SYS-05`
- [ ] Trace id enviado explicitamente ao `Worker`? → `BUN-SYS-06`
- [ ] A lista de `node:*` inclui `node_modules`, não só o `src`, e cada um foi conferido na matriz? → `BUN-SYS-07`
- [ ] Nenhum algoritmo ausente do BoringSSL em uso? → `BUN-SYS-08`
- [ ] Observabilidade sem `createHook` / `eventLoopUtilization`? → `BUN-SYS-09`
- [ ] IPC Bun↔Node em JSON? → `BUN-SYS-10`
- [ ] Listener de `SIGTERM` que drena (`server.stop` / `server.close`) **e** chama `process.exit`? → `BUN-SYS-11`
- [ ] `--frozen-lockfile --production`, `USER bun`, `--no-env-file` no `ENTRYPOINT` e nenhum `.env` na imagem? → `BUN-SYS-12`
- [ ] O Dockerfile tem os quatro stages, e todo `COPY --from=` aponta para um que existe? → § 6

---

## Relacionados

- [Bun](bun.md) — hub
- [Bun - HTTP e Servidor](bun-http-e-servidor.md) · [Bun - Runtime e APIs](bun-runtime-e-apis.md) · [Bun - Bundler e Build](bun-bundler-e-build.md) · [Bun - Dados e Persistência](bun-dados-e-persistencia.md) · [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) · [Bun - Testes](bun-testes.md)
- [Backend no runtime Bun](backend-no-runtime-bun.md) — o que fazer com um servidor `node:http` que já existe, e a decisão `Bun.serve` × [Hono](hono.md) × [Elysia](elysia.md)
- `Node.js` · · ·
- · `Arquivos.env não substituem secret management`
- · ·

## Fontes consultadas

Verificadas em **2026-08-15**:

- [Node.js Compatibility](https://bun.com/docs/runtime/nodejs-compat) — matriz módulo a módulo, globais, `process`
- [Shell](https://bun.com/docs/runtime/shell) — API, redirecionamento, builtins, seção de segurança
- [FFI](https://bun.com/docs/runtime/ffi) · [C Compiler](https://bun.com/docs/runtime/c-compiler) · [Node-API](https://bun.com/docs/runtime/node-api)
- [Workers](https://bun.com/docs/runtime/workers) · [Bun Runtime](https://bun.com/docs/runtime) (`--smol`)
- [Environment Variables](https://bun.com/docs/runtime/environment-variables) (`--no-env-file`) · [Containerize with Docker](https://bun.com/docs/guides/ecosystem/docker) — Dockerfile de quatro stages e `.dockerignore` · [Listen to OS signals](https://bun.com/docs/guides/process/os-signals)
- [`bun why`](https://bun.com/docs/pm/cli/why) — o que ele responde, e o que não · [Express e Bun](https://bun.com/docs/guides/ecosystem/express)
- Versão: `https://registry.npmjs.org/bun/latest` → **1.3.14**

**Notas de verificação** — pontos em que a fonte contraria o que se assume por hábito:

- **Apenas `node:sea` está marcado 🔴 na matriz inteira.** Todo o resto é 🟢 ou 🟡 — o que torna o risco de migração ser de *comportamento parcial*, não de módulo faltando.
- **A matriz é aferida contra Node.js v26**, declarado no topo da página.
- **`node:crypto` não tem `secp256k1`** nem as outras curvas fora de P-224/256/384/521, porque Bun usa BoringSSL. `argon2` lança.
- **`eventLoopUtilization` sempre devolve zeros**, e `createHook`/`executionAsyncId` são stubs com id `0` — instrumentação baseada neles não observa nada.
- **`AsyncLocalStorage` não propaga para `MessagePort`, `BroadcastChannel` nem eventos de `Worker`.**
- **`node:v8` `serialize`/`deserialize` usam o formato do JavaScriptCore, não o do V8** — payload não é intercambiável com Node.
- **Substituir `process.stdout.write` não captura a saída do `console`**: Bun escreve direto no file descriptor.
- **`process.title` é no-op em macOS e Linux**, e `process.report.writeReport` não escreve nada.
- **Resumption de sessão TLS não funciona entre processos** (sem `newSession`/`resumeSession`, `ticketKeys` ignorado).
- **`module.register` é no-op** — a doc recomenda `Bun.plugin` no lugar.
- **`Request` aceita e ignora** `credentials`, `integrity`, `referrer` e `referrerPolicy` em vez de lançar.
- **Um `Error` passado por `structuredClone` perde o `cause`**; streams web não são transferíveis.
- **`--smol` não é um "modo container"**: ele aumenta a frequência do GC. Bun já dimensiona o heap por cgroup com e sem a flag.
- **Sem listener explícito de um sinal, `beforeExit` e `exit` não são emitidos** quando o processo é morto por ele. E o inverso é igualmente contraintuitivo: **registrar o listener suprime a ação padrão do sinal**, então um handler sem `process.exit` deixa o processo vivo até o `SIGKILL`. As duas metades estão em `BUN-SYS-11`.
- **O Dockerfile oficial tem quatro stages**, não três: `base`, `install`, `prerelease` e `release`. O `install` roda **dois** installs (com e sem `--production`), e o `prerelease` é o que carrega o fonte e roda `bun test` / `bun run build`.
- **A matriz nomeia `SNICallback` sob `node:https`, não sob `node:tls`.** A linha completa de `node:https` é 🟡 e diz que `request`, `get`, `Agent` e `globalAgent` são implementados com pooling, que `https.Server` é um `http.Server` com opções de TLS, que os sockets de request não são `TLSSocket` (`encrypted`/`authorized`/`servername` funcionam; `getPeerCertificate`/`getCipher` faltam) e que `setSecureContext`, `addContext`, `SNICallback` e `handshakeTimeout` não são suportados.
- **`bun why` não enumera módulos `node:*`.** Ele explica por que um *pacote* está instalado, mostrando a cadeia de dependências. Não existe comando de Bun que produza a lista de `node:*` de uma árvore de dependências — `BUN-SYS-07` depende de grep.
- **O `llms-full.txt` do Bun está desatualizado em relação à página de compatibilidade ao vivo.** No arquivo consolidado, `node:crypto` aparece como *"Missing `secureHeapUsed` `setEngine` `setFips`"* e `node:https` como 🟢; a página ao vivo traz o texto completo do BoringSSL e marca `node:https` como 🟡. **A página ao vivo vence** — foi ela que este satélite seguiu.
- **`bun:ffi`, `cc`, `Worker` e os callbacks thread-safe de `JSCallback` estão todos marcados como experimentais** nas respectivas páginas.
- **`node:cluster` balanceia HTTP entre processos apenas em Linux**; em outros sistemas cada worker faz bind do próprio socket.
