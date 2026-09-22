---
titulo: Bun - Runtime e APIs
Link: https://bun.com/docs/runtime
tags:
 - bun
 - runtime
 - agent-context
source: "Documentação oficial — https://bun.com/docs"
verificado-em: 2026-08-15
---

# Bun - Runtime e APIs

> Execução direta de TS/JSX · resolução de módulos, `paths` e transform de JSX · interop ESM/CJS · `Bun.file` e `Bun.write` × `node:fs` · carregamento e precedência de `.env`, e a ressalva do `import.meta.env` do Vite · `Bun.spawn`/`spawnSync` · `Bun.password` e hashing · `--watch` × `--hot` · `bunfig.toml` e `--preload` · `using` e `Symbol.dispose` · utilitários globais que aparecem em código real.
>
> **Não cobre:** `Bun.serve` e HTTP ([Bun - HTTP e Servidor](bun-http-e-servidor.md)) · `Bun.build`, bundler e HMR de browser ([Bun - Bundler e Build](bun-bundler-e-build.md)) · `Bun.$` e a matriz de compatibilidade Node ([Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md)) · `bun install` e lockfile ([Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md)) · `bun test` ([Bun - Testes](bun-testes.md)).

Entrada: [Bun](bun.md) · Base normativa: [Bun](bun.md) § 6

---

## 1. Conceito: o runtime não é "Node mais rápido" — ele muda o que precisa de build e o que precisa de import

Duas mudanças estruturais, e delas decorre quase tudo o que diferencia código escrito para Bun.

**A primeira: não há passo de build para executar.** `bun index.tsx` roda. Bun transpila cada arquivo em voo com o transpiler nativo antes de executar, e por isso `.ts`, `.tsx`, `.jsx` e `.mts` são entrypoints legítimos. O que desaparece do projeto: `ts-node`, `tsx`, `swc-node`, o `outDir` de desenvolvimento e a distinção entre "código-fonte" e "código executável". O que **não** desaparece: o type checking. Bun lê o `tsconfig.json` para decidir o transform de JSX e resolver `paths` — ele não valida um único tipo. Um projeto Bun sem `tsc --noEmit` no CI não tem verificação de tipos em lugar nenhum.

**A segunda: as APIs nativas são globais.** `Bun.file`, `Bun.write`, `Bun.spawn`, `Bun.password` estão em `globalThis` sem import. Isso remove a linha de import e adiciona um acoplamento: o arquivo passa a exigir o processo `bun`. Não é um detalhe de estilo — é a diferença entre um módulo que roda em qualquer runtime e um que não roda. Biblioteca publicada em npm usa `node:*`; aplicação que você controla pode acoplar, desde que a decisão seja consciente.

O resto desta nota é a consequência dessas duas escolhas: onde a API do Bun é melhor que a do Node, onde ela não cobre o caso, e onde a diferença produz bug.

---

## 2. Execução, resolução de módulos e interop ESM/CJS

### Executar

`bun run <arquivo>` e a forma curta `bun <arquivo>` são idênticas. Para scripts de `package.json`, `bun run <script>`.

```bash
bun index.tsx # roda TS + JSX, sem build
bun run dev # script do package.json
bun run --bun vite # força o runtime do Bun num CLI com shebang node
echo "console.log(1)" | bun run - # lê do stdin, tratado como TypeScript+JSX
```

Duas armadilhas de linha de comando, ambas verificadas na fonte:

- **Flags do Bun vêm logo depois de `bun`.** `bun --watch run dev` funciona; `bun run dev --watch` passa `--watch` para o script.
- **Comando embutido vence script de mesmo nome.** `bun <script>` só funciona se `<script>` não colidir com um comando do `bun`. Em automação, use sempre a forma explícita `bun run <script>`.

A ordem de resolução de `bun run <x>` é: **script do `package.json` → arquivo-fonte → binário de dependência do projeto → comando do sistema** (o último só com `bun run` explícito). Caminhos absolutos e caminhos iniciados por `./` são sempre tratados como arquivo.

### Resolver imports

Bun implementa o algoritmo de resolução do Node.js, com extensões opcionais. Para `import { x } from "./hello"` numa importação ESM local, a ordem tentada é `.tsx`, `.jsx`, `.mts`, `.ts`, `.mjs`, `.js`, `.cts`, `.cjs`, `.json`, e depois os mesmos como `hello/index.*`. A ordem muda por contexto: `require` tenta as extensões CommonJS antes das ESM, e imports dentro de `node_modules` tentam JavaScript antes de TypeScript.

Uma regra de compatibilidade com TypeScript vale a pena conhecer porque parece bug: **`from "./x.js"` também resolve `./x.ts`**. É a *file extension substitution* do compilador TypeScript, que permite arquivos-fonte se referirem uns aos outros pelo caminho compilado. Fora de `node_modules`, `.mjs` também casa `.mts`. `.cjs` **não** é reescrito para `.cts`.

Re-mapeamento de caminho vem de `compilerOptions.paths` no `tsconfig.json` (ou `jsconfig.json`), e de `"imports"` no `package.json` com o prefixo `#`. Os dois mecanismos funcionam juntos. **`resolve.alias` do `vite.config.ts` não é lido pelo Bun** — projeto que declarou o alias só ali quebra assim que roda fora do Vite (por exemplo em `bun test`). O alias precisa existir em `compilerOptions.paths`.

### JSX: o transform vem do `tsconfig.json`, e `react-jsx` é o valor esperado

Bun transpila JSX sem plugin, e lê a configuração do mesmo `tsconfig.json`/`jsconfig.json` que já dá `paths`. Quatro opções, verificadas na fonte:

| Opção | Vale quando | Efeito |
| --- | --- | --- |
| `jsx` | sempre | escolhe o transform (tabela abaixo) |
| `jsxFactory` | só com `jsx: "react"` | nome da função de elemento; default `"React.createElement"` (Preact: `"h"`) |
| `jsxFragmentFactory` | só com `jsx: "react"` | nome do fragment `<>`; default `"React.Fragment"` |
| `jsxImportSource` | só com `"react-jsx"`/`"react-jsxdev"` | de onde importar o runtime; default `"react"` (Bun anexa `/jsx-runtime` ou `/jsx-dev-runtime`) |

| Valor de `jsx` | Para o que `<Box width={5}>Olá</Box>` transpila |
| --- | --- |
| `"react"` | `React.createElement(Box, { width: 5 }, "Olá")` — exige `React` em escopo |
| `"react-jsx"` | `import { jsx } from "react/jsx-runtime"` — **não** exige import de `React` |
| `"react-jsxdev"` | `import { jsxDEV } from "react/jsx-dev-runtime"`, com argumentos extras de debug |
| `"preserve"` | **não suportado** — a fonte diz literalmente que `"preserve"` não é suportado pelo Bun atualmente |

O ponto que desbloqueia projeto React vindo do Vite: **`"jsx": "react-jsx"` — o valor que os templates de Vite + React já trazem — é exatamente o que Bun espera.** Não há passo de configuração; é o mesmo valor que o `tsconfig.json` recomendado pela própria doc do Bun usa. Quem tinha JSX funcionando no Vite tem JSX funcionando em `bun test` sem tocar em nada, desde que o `tsconfig.json` seja o que declara o transform. Um projeto que declarou `"jsx": "preserve"` (delegando o transform ao bundler) é o caso que **não** roda.

As mesmas quatro chaves podem ser declaradas em `bunfig.toml` (§ 9), e existem pragmas por arquivo: `// @jsx h`, `// @jsxFrag MyFragment`, `// @jsxImportSource preact`.

### ESM e CJS no mesmo arquivo

```ts
import { criarPedido } from "./pedidos.ts";
const { formatarMoeda } = require("./formatacao.cjs"); // no mesmo arquivo, sem cerimônia
```

`require` de um módulo ESM devolve o *module namespace*; `require` de um CJS devolve `module.exports`. A **única** quebra: `require` de um módulo com **top-level `await`** falha, porque `require` é síncrono por definição. Use `import` estático ou `import` dinâmico.

### `import.meta`

```ts
import.meta.dir; // "/app/src" — equivale a __dirname
import.meta.path; // "/app/src/pedidos.ts" — equivale a __filename
import.meta.file; // "pedidos.ts"
import.meta.url; // "file:///app/src/pedidos.ts"
import.meta.main; // true se este arquivo foi o entrypoint de `bun run`
import.meta.env; // alias de process.env
await import.meta.resolve("zod"); // URL do módulo resolvido
```

`import.meta.dirname` e `import.meta.filename` existem como aliases, por compatibilidade com Node.

### Auto-install: o comportamento que surpreende em container

Se Bun **não encontra `node_modules`** no diretório de trabalho nem acima dele, ele abandona a resolução estilo Node e passa a **instalar cada pacote importado na hora**, no cache global. A versão vem de `bun.lock`, senão de um `package.json` acima na árvore, senão de `latest`. Para um script solto isso é uma conveniência real; numa imagem de produção onde `node_modules` não foi copiado, é uma instalação silenciosa da rede em tempo de execução — com `latest`.

Desligue com `--no-install`, ou garanta que `node_modules` exista.

| ID | Regra |
| --- | --- |
| `BUN-RT-12` | Execução em produção **MUST** ter `node_modules` presente ou rodar com `--no-install` — sem isso, o auto-install resolve dependências da rede em runtime. |

## 3. Arquivos: `Bun.file`, `Bun.write` e onde `node:fs` continua obrigatório

A divisão é limpa e a própria doc a declara: **`Bun.file` e `Bun.write` tratam do conteúdo de um arquivo; tudo o que é sobre o sistema de arquivos continua em `node:fs`.**

> "For operations they don't cover, such as `mkdir` or `readdir`, use Bun's nearly complete implementation of the `node:fs` module."

### Ler

`Bun.file(path)` devolve um `BunFile`, que é **preguiçoso**: criar a referência não lê nada do disco. A interface é a de um `Blob`.

```ts
const contrato = Bun.file("contratos/2026-08.json");

contrato.size; // bytes — 0 também para arquivo inexistente
contrato.type; // MIME type; default "text/plain;charset=utf-8"

await contrato.json; // conteúdo como objeto
await contrato.text; // como string
await contrato.bytes; // Uint8Array
contrato.stream; // ReadableStream, sem carregar tudo em memória

await contrato.exists; // ← a checagem correta de existência
```

A checagem de existência é onde código gerado erra. `size` de um arquivo inexistente é `0`, e `type` volta com o default — nenhum dos dois distingue "vazio" de "não existe". Só `await file.exists` responde.

`Bun.stdin`, `Bun.stdout` e `Bun.stderr` são instâncias de `BunFile`, o que faz `await Bun.write(Bun.stdout, Bun.file(p))` ser um `cat`.

### Escrever

`Bun.write(destino, dados)` aceita destino `string | URL | BunFile | number` e dados `string | Blob | BunFile | ArrayBuffer | TypedArray | Response`, escolhendo a syscall mais rápida para cada combinação.

```ts
await Bun.write("saida.txt", "conteúdo"); // string
await Bun.write(Bun.file("copia.pdf"), Bun.file("orig.pdf")); // cópia de arquivo
await Bun.write("index.html", await fetch("https://exemplo.com")); // corpo da resposta
```

Que uma resposta HTTP seja um argumento válido é o ponto: não há `pipeline`, nem `createWriteStream`, nem conversão manual.

### Escrever incrementalmente

```ts
const relatorio = Bun.file("relatorio.ndjson");
const writer = relatorio.writer({ highWaterMark: 1024 * 1024 });

for (const pedido of pedidos) {
 writer.write(JSON.stringify(pedido) + "\n"); // bufferiza
}

await writer.flush; // grava o buffer; devolve o número de bytes
await writer.end; // fecha
```

O detalhe operacional: **o processo `bun` não encerra enquanto o `FileSink` estiver aberto.** Quem esquece `.end` produz um script que "trava no fim". `writer.unref` desliga esse vínculo, e `writer.ref` o restabelece.

### O critério de escolha

| Operação | Use | Por quê |
| --- | --- | --- |
| Ler arquivo inteiro | `Bun.file.text/.json/.bytes` | assíncrono, sem `readFile` + parse manual |
| Ler grande / streaming | `Bun.file.stream` | `ReadableStream` padrão, integra com `Response` |
| Escrever payload pronto | `Bun.write` | escolhe a syscall; aceita `Response` e `BunFile` |
| Escrever em loop | `file.writer` (`FileSink`) | buffer com high water mark |
| Append | `node:fs` | `Bun.write` sobrescreve |
| `mkdir`, `readdir`, `rm`, `stat`, `chmod`, `watch` | `node:fs` / `node:fs/promises` | não há equivalente em `Bun.*` |
| API idêntica à do Node (lib compartilhada) | `node:fs` | portabilidade |

**Sobre síncrono:** `node:fs` expõe `readFileSync` e amigos, e eles funcionam em Bun. Em CLI de vida curta, tudo bem. Dentro de um handler de `Bun.serve`, cada chamada síncrona bloqueia o event loop do processo inteiro — e como Bun.serve atende muitas conexões no mesmo loop, o custo não é local.

| ID | Regra |
| --- | --- |
| `BUN-RT-01` | Operação de **diretório** (`mkdir`, `readdir`, `rm`, `stat`) **MUST** usar `node:fs` — `Bun.file`/`Bun.write` só tratam conteúdo de arquivo. |
| `BUN-RT-02` | `Bun.file(path)` **NEVER** é tratado como leitura — a referência é preguiçosa; nada é lido até `.text`/`.json`/`.bytes`/`.stream`. |
| `BUN-RT-03` | Existência de arquivo **MUST** ser checada com `await file.exists` — `size === 0` também é o valor de um arquivo inexistente. |
| `BUN-RT-04` | `FileSink` **MUST** ser encerrado com `.end` (ou desvinculado com `.unref`) — sem isso o processo não termina. |

---

## 4. Ambiente: `.env`, precedência e por que `Bun.env` não é diferente de `process.env`

Bun lê arquivos `.env` automaticamente. `dotenv` e `dotenv-expand` são desnecessários — a fonte diz isso literalmente.

**A ordem, verificada na fonte, é de precedência crescente:**

1. `.env`
2. `.env.production` · `.env.development` · `.env.test` — conforme `NODE_ENV`
3. `.env.local`

Ou seja: `.env.local` ganha de `.env.production`, que ganha de `.env`. É o inverso do que a leitura de cima para baixo sugere, e é a origem de "por que meu valor de produção não aplicou".

Controles explícitos:

```bash
bun --env-file=.env.ci src/index.ts # substitui quais arquivos são lidos
bun --env-file=.env.a --env-file=.env.b run build # múltiplos
bun run --no-env-file index.ts # desliga o carregamento automático
```

```toml
# bunfig.toml — desliga por projeto
env = false
```

Arquivos passados com `--env-file` continuam sendo lidos mesmo com o carregamento automático desligado.

**Expansão é o default.** `BAR=hello$FOO` resolve `$FOO`. Para um `$` literal — o caso real é senha gerada — escape com barra invertida:

```ini
DB_PASSWORD=s3nh4\$com\$cifrao
DB_URL=postgres://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME # expansão útil
```

**Leitura.** `process.env`, `Bun.env` e `import.meta.env` são **o mesmo objeto** — a fonte descreve os dois últimos como aliases. Dentro do Bun, escolher entre eles é estilo. Em TypeScript, todas as propriedades são `string | undefined`; para declarar uma como obrigatória, use interface merging:

```ts
declare module "bun" {
 interface Env {
 DATABASE_URL: string;
 }
}
```

Isso muda o **tipo**, não a realidade: a variável continua podendo estar ausente em runtime. A validação na inicialização continua necessária — é o que argumenta, e o mecanismo natural é um schema.

### A ressalva que "é o mesmo objeto" esconde: `import.meta.env` no Vite é outra coisa

"São aliases, escolher é estilo" vale **dentro do Bun**. Num projeto que também roda sob Vite — o caso do app React que usa `import.meta.env.VITE_API_URL` nos componentes — os dois `import.meta.env` são objetos diferentes, e a diferença aparece exatamente quando o mesmo componente passa a rodar em `bun test`:

| | Bun | Vite |
| --- | --- | --- |
| O que é | alias de `process.env`, lido em runtime | constantes **substituídas estaticamente** em build (e globais em dev) |
| Filtro de nome | nenhum — toda variável do ambiente aparece | só as com prefixo `VITE_` chegam ao código do cliente (`envPrefix` ajusta) |
| Qual `.env` é lido | `.env` < `.env.{NODE_ENV}` < `.env.local` | por **modo**: `.env` < `.env.local` < `.env.[mode]` < `.env.[mode].local` |
| `MODE`, `DEV`, `PROD`, `BASE_URL` | **não existem** — `process.env` não tem essas chaves | injetadas pelo Vite |

As consequências práticas, na ordem em que mordem:

1. `import.meta.env.VITE_API_URL` **funciona** sob `bun test`, desde que a variável esteja no ambiente ou num `.env` que o Bun carregue — porque Bun não filtra por prefixo. O nome não muda.
2. `import.meta.env.MODE` / `.DEV` / `.PROD` / `.BASE_URL` viram `undefined` sob Bun. Componente que ramifica em `import.meta.env.DEV` cai no ramo de produção dentro do teste, sem erro.
3. O arquivo lido muda: `bun test` roda com `NODE_ENV=test` (ver [Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) § 6), então a camada de modo que o Bun aplica é `.env.test` — não o `.env.development` que o `vite dev` carregaria.
4. Variável **sem** prefixo `VITE_` é invisível no browser e visível sob `bun test`. Um teste pode passar lendo um valor que o app nunca enxerga em produção.

Se o componente precisa de configuração, receber por prop ou por um módulo de config injetável é o que remove a divergência inteira. Ver [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md) § 4.

E a fronteira que o mecanismo não resolve: **`.env` é conveniência de desenvolvimento, não secret management**. Ver `Arquivos.env não substituem secret management`.

| ID | Regra |
| --- | --- |
| `BUN-RT-05` | Segredo de produção **NEVER** vem de arquivo `.env` carregado pelo runtime. |
| `BUN-RT-06` | Variável de ambiente **MUST** ser validada na inicialização; o tipo declarado por interface merging **NEVER** é tratado como garantia de presença. |
| `BUN-RT-07` | `$` literal em valor de `.env` **MUST** ser escapado com `\` — Bun expande variáveis por padrão. |

---

## 5. Processos: `Bun.spawn` × `Bun.spawnSync`

A regra de bolso está na própria fonte: *"the asynchronous `Bun.spawn` API is better for HTTP servers and apps, and `Bun.spawnSync` is better for building command-line tools."*

```ts
const proc = Bun.spawn(["git", "log", "--oneline", "-n", "20"], {
 cwd: "/srv/repo",
 env: {...process.env, GIT_PAGER: "cat" },
 timeout: 10_000, // ms; mata o processo ao estourar
 killSignal: "SIGKILL", // default é SIGTERM
 onExit(_proc, exitCode, signalCode, error) {
 // …
 },
});

const saida = await proc.stdout.text; // stdout é ReadableStream por default
await proc.exited; // Promise que resolve no encerramento
proc.exitCode; // null | number
```

Defaults que importam: `stdin` é `null` (nenhuma entrada), `stdout` é `"pipe"`, `stderr` é `"inherit"`. Quem quer capturar `stderr` precisa pedir `stderr: "pipe"` explicitamente.

Cancelamento cooperativo usa `AbortSignal` — o mesmo mecanismo de:

```ts
const controller = new AbortController;
const proc = Bun.spawn({ cmd: ["ffmpeg", "-i", entrada, saida], signal: controller.signal });
// …
controller.abort; // envia killSignal (default SIGTERM)
```

Escrever no stdin exige `stdin: "pipe"`, que devolve um `FileSink`:

```ts
const proc = Bun.spawn(["wc", "-l"], { stdin: "pipe" });
proc.stdin.write(conteudo);
proc.stdin.end;
```

`Bun.spawnSync` bloqueia e devolve um `SyncSubprocess`, com três diferenças declaradas: tem `success` (boolean do exit code zero), `stdout`/`stderr` são `Buffer` em vez de `ReadableStream`, e **não tem `stdin`**. Para saída potencialmente ilimitada, `maxBuffer` limita quantos bytes o processo pode emitir antes de ser morto.

```ts
const r = Bun.spawnSync({ cmd: ["yes"], maxBuffer: 100 });
```

O processo `bun` pai não termina enquanto houver filho vivo; `proc.unref` desfaz esse vínculo.

| ID | Regra |
| --- | --- |
| `BUN-RT-08` | Handler de servidor HTTP **NEVER** chama `Bun.spawnSync` nem uma API `*Sync` de `node:fs` — bloqueia o event loop do processo inteiro. |
| `BUN-RT-09` | Subprocesso de duração não garantida **MUST** receber `timeout` ou `signal`. |

---

## 6. Hashing e senha: três APIs que não são intercambiáveis

| API | Natureza | Para quê |
| --- | --- | --- |
| `Bun.password` | criptográfica, com salt e custo | **senha de usuário** — argon2id (default) ou bcrypt |
| `Bun.CryptoHasher` | criptográfica, incremental | integridade, assinatura, checksum forte (sha256, blake2b, sha3, …) |
| `Bun.hash.*` | **não criptográfica** | hash de tabela, dedupe, particionamento — wyhash (default), xxHash, crc32, murmur |

A fonte descreve `Bun.hash` explicitamente como *"utilities for non-cryptographic hashing"*, otimizado para velocidade em detrimento de resistência a colisão. Usá-lo para senha, token ou qualquer coisa que precise resistir a um adversário é uma vulnerabilidade, não uma escolha de performance.

```ts
// Cadastro
const hash = await Bun.password.hash(senhaEmClaro);
// => "$argon2id$v=19$m=65536,t=2,p=1$…" salt já embutido

// Login
const ok = await Bun.password.verify(senhaEmClaro, usuario.senhaHash);
```

Pontos verificados que evitam erro:

- **O salt é gerado automaticamente e vai dentro do hash.** Não existe parâmetro de salt, e guardar um salt separado é redundância.
- **`verify` detecta o algoritmo a partir do próprio hash** (PHC para argon2, MCF para bcrypt). Trocar o algoritmo de `hash` não invalida os hashes antigos.
- **Existem `hashSync`/`verifySync`**, e a doc avisa que são caros: *"These functions are computationally expensive, so a blocking API can degrade application performance."* Num servidor, use as versões assíncronas.
- **Com bcrypt, senha acima de 72 bytes passa por SHA-512 antes**, em vez de ser truncada silenciosamente como na implementação clássica.
- `algorithm: "argon2id" | "argon2i" | "argon2d"` com `memoryCost` (KiB, mínimo 8) e `timeCost`; `algorithm: "bcrypt"` com `cost` entre 4 e 31. Os valores dos exemplos da doc são baixos de propósito — não os copie para produção sem calibrar.

| ID | Regra |
| --- | --- |
| `BUN-RT-10` | Senha **MUST** ser tratada com `Bun.password`; `Bun.hash` **NEVER** toca senha, token ou segredo — é hash não criptográfico. |

---

## 7. `--watch` × `--hot`: a diferença é a semântica do estado

Não são dois níveis de agressividade da mesma coisa. São dois modelos de reload.

| | `--watch` | `--hot` |
| --- | --- | --- |
| O que faz | **hard restart**: mata e reinicia o processo | **soft reload**: reavalia os módulos no processo vivo |
| `globalThis` | zerado a cada reload | **preservado** |
| Conexões, timers, servidor | perdidos | mantidos |
| Argumentos e env | os mesmos da execução inicial | — |
| Antes de reiniciar | roda os handlers do sinal de kill (`SIGTERM` por padrão, ajustável com `--watch-kill-signal`) | — |
| Se o processo crashar | tenta reiniciar | — |
| Alcance | arquivos importados, incluindo `bun test` | arquivos importados **fora de `node_modules`** |
| Bom para | testes, CLI, qualquer coisa que exija estado limpo | servidor HTTP em desenvolvimento |

```ts
// Com --hot, isto conta reloads em vez de reiniciar do zero:
declare global { var reloads: number }
globalThis.reloads ??= 0;
globalThis.reloads++;

Bun.serve({
 port: 3000,
 routes: {
 // `routes` e não `fetch` solto — BUN-HTTP-01. Ver [Bun - HTTP e Servidor](bun-http-e-servidor.md).
 "/reloads": => new Response(`reloads: ${globalThis.reloads}`),
 },
});
```

Onde isso vira bug: **estado preservado esconde erro de inicialização.** Um cache populado no primeiro load continua populado depois de você quebrar o código que o popula; um pool de conexões sobrevive à mudança que deveria recriá-lo. Para servidor em desenvolvimento, o benefício (não perder conexão, refresh instantâneo) compensa. Para teste, quase nunca — a própria doc de `bun test` recomenda `--watch`: *"For most tests, use `--watch`: it gives better isolation between runs."*

Duas notas de escopo: `bun --hot` **não é** HMR de browser. É o equivalente de servidor. HMR de frontend está em [Bun - Bundler e Build](bun-bundler-e-build.md). E `--no-clear-screen` impede a limpeza do terminal a cada reload — útil quando várias instâncias rodam em paralelo e uma apagaria os erros da outra.

| ID | Regra |
| --- | --- |
| `BUN-RT-11` | `--hot` **NEVER** é usado onde o resultado depende de estado limpo (testes, jobs, verificação de inicialização) — nesses casos, `--watch`. |

---

## 8. Utilitários globais que aparecem em código real

Não é a lista completa (ver [Bun](bun.md) § 4 para o que ficou fora do mapa) — é o subconjunto que substitui dependência de npm.

```ts
Bun.version; // "1.3.x" — versão do CLI em execução
Bun.main; // caminho absoluto do entrypoint
import.meta.path === Bun.main; // "este arquivo foi executado diretamente?"

Bun.which("psql"); // caminho do executável, ou null — substitui o pacote `which`
Bun.randomUUIDv7; // UUID v7 monotônico, ordenável, bom para chave de banco
await Bun.sleep(250); // Promise; há Bun.sleepSync para CLI
Bun.deepEquals(a, b); // igualdade estrutural
Bun.escapeHTML(entradaDoUsuario);
Bun.fileURLToPath(import.meta.url);
Bun.pathToFileURL("/srv/app/index.ts");

Bun.gzipSync(bytes); Bun.gunzipSync(bytes);
Bun.zstdCompressSync(bytes); await Bun.zstdDecompress(bytes);

await Bun.readableStreamToText(stream);
await Bun.readableStreamToJSON(stream);
await Bun.readableStreamToFormData(stream);
```

Sobre `Bun.randomUUIDv7`: a doc detalha a garantia de monotonicidade — o contador é atômico e seguro entre Workers no mesmo processo, e quando ele estoura no mesmo milissegundo Bun avança o timestamp em vez de dar a volta, mantendo os UUIDs estritamente crescentes. Aceita `"hex"` (default), `"base64"`, `"base64url"` ou `"buffer"` como encoding. Para chave primária ordenável, é a escolha certa sobre `crypto.randomUUID` (v4).

Sobre streams: Bun implementa os tipos Web (`ReadableStream`, `WritableStream`, `TransformStream`) como globais, e também `node:stream`. Os dois convivem, mas a doc de compatibilidade registra que `isReadable`/`isWritable`/`Readable.isDisturbed` de `node:stream` só entendem streams do Node, não streams Web. Contexto conceitual em e.

---

## 9. `bunfig.toml`: um arquivo, quatro escopos de comando, e um merge global × projeto

`bunfig.toml` é a configuração persistente do Bun inteiro — runtime, `bun install`, `bun test` e `bun run` na mesma árvore. Tudo o que ele faz também existe como flag de linha de comando; ele é o lugar onde a decisão para de ser digitada a cada execução.

### Onde o arquivo vive

| Escopo | Caminho | Nome |
| --- | --- | --- |
| Projeto | raiz do projeto, ao lado do `package.json` | `bunfig.toml` |
| Global | `$HOME/.bunfig.toml` ou `$XDG_CONFIG_HOME/.bunfig.toml` | `.bunfig.toml` — **com ponto** |

O nome muda entre os dois: o do projeto não tem ponto, o global tem. Copiar um para o outro lugar sem renomear produz um arquivo que nunca é lido, e o Bun não avisa.

### Precedência

1. **Global e projeto são combinados por `shallow merge`**, com o do projeto vencendo o global.
2. **Flag de linha de comando vence o `bunfig.toml`**, onde a opção equivalente existe.
3. **Exceção verificada, e é a que surpreende:** para `bun run`, Bun carrega automaticamente **apenas** o `bunfig.toml` local do projeto — ele não procura o `.bunfig.toml` global. Configuração global de `[run]` não se aplica a `bun run`.

Que o merge seja *shallow* importa na prática: declarar `[install]` no projeto substitui a tabela `[install]` inteira do global, não campo a campo.

**Em monorepo: não verificado.** A fonte documenta o par global × projeto e nada sobre workspaces — não há declaração de que o `bunfig.toml` da raiz seja herdado por um pacote membro, nem de que os dois sejam mesclados. Enquanto isso não for confirmado, trate o `bunfig.toml` como resolvido a partir do diretório onde o comando roda e não conte com herança.

### As seções que este corpus usa

```toml
# bunfig.toml — raiz do projeto

# --- topo: runtime ---
preload = ["./instrumentacao.ts"] # roda antes de qualquer entrypoint
jsx = "react-jsx" # mesmas chaves do tsconfig (§ 2)
env = false # desliga o carregamento automático de.env (§ 4)
logLevel = "warn" # "debug" | "warn" | "error"

[install]
linker = "isolated" # "hoisted" | "isolated" → [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) § 5
ignoreScripts = true # bloqueia lifecycle scripts → § 4 daquela nota
minimumReleaseAge = 259200 # segundos
frozenLockfile = true # equivale a --frozen-lockfile
production = false # sem devDependencies; congela o lockfile

[test]
preload = ["./happydom.ts", "./testing-library.ts"] # → [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md) § 2
root = "."
coverageThreshold = { lines = 0.9 }
pathIgnorePatterns = ["**/fixtures/**"]

[run]
bun = true # apelida `node` para `bun` dentro de scripts
shell = "system" # "bun" | "system"
silent = false

[serve]
port = 3000 # porta default de Bun.serve
```

O exemplo mostra o que este corpus usa; as seções têm mais chaves. O que cada uma alcança, e onde a nota detalha: **topo** = runtime (`preload`, `jsx*`, `env`, `define`, `loader`, `smol`, `logLevel`, `console.depth`) → § 2 e § 4 · **`[install]`** = `bun install`/`add`/`ci` (`linker`, `hoist`, `ignoreScripts`, `frozenLockfile`, `production`, `registry`, `scopes`, `minimumReleaseAge*`, `globalStore`, `saveTextLockfile`, `auto`, `security.scanner`, `cache.*`) → [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) · **`[test]`** = `bun test` (`preload`, `root`, `coverage*`, `pathIgnorePatterns`, `randomize`, `seed`, `retry`, `rerunEach`, `concurrentTestGlob`, `onlyFailures`, `reporter.*`) → [Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) § 5 · **`[run]`** = `bun run` (`bun`, `shell`, `silent`, `elide-lines`, `noOrphans`) → § 2 · **`[serve]`** = `port` default de `Bun.serve` → [Bun - HTTP e Servidor](bun-http-e-servidor.md).

A chave `[test] preload` é descrita pela fonte como *"the same as the top-level `preload` field, but only applies to `bun test`"*. Não é um mecanismo à parte — é o mesmo campo com escopo menor.

### `--preload` (e `-r`): rodar código antes do entrypoint

O equivalente de linha de comando do `preload`, e o análogo do `node --require`:

```bash
bun --preload./setup.ts run./index.ts # flag do runtime → antes do subcomando
bun -r./setup.ts index.ts # -r é alias de --preload
bun test --preload./happydom.ts # ad-hoc; a forma persistente é [test] preload
```

Três pontos operacionais:

- **A flag é do runtime, então vem antes do subcomando.** `bun run./index.ts --preload./setup.ts` repassa `--preload` ao script — o preload nunca roda. É a mesma armadilha de `bun run dev --watch` (§ 2).
- **Para que serve:** registrar plugin, injetar global, instalar instrumentação — sem poluir o entrypoint com um `import` que só existe por causa do efeito colateral. Em `bun test` é o único lugar que roda *antes* dos imports do arquivo de teste, e por isso é onde vivem `mock.module` e `GlobalRegistrator.register` (`BUN-TEST-04`, `BUN-TEST-07`).
- **`--import` não foi confirmado.** Node tem `--import` para o equivalente ESM de `--require`; não encontrei declaração na doc do Bun de que a flag exista ou seja aceita. Use `--preload`/`-r`, que estão documentados.

---

## 10. `using`: o recurso se fecha sozinho, e isso não é erro de digitação

`using db = new Database("app.sqlite")` e `await using reserved = await sql.reserve` aparecem no corpus como padrão recomendado, e leem-se como `const` mal escrito para quem não viu a feature. Não é: `using` é uma **declaração** da proposta TC39 de *Explicit Resource Management*, e o que ela faz é chamar o descarte do recurso ao sair do escopo, inclusive por exceção ou `return` antecipado.

```ts
{
 using arquivo = Bun.file("pedidos.ndjson").writer;
 arquivo.write(linha);
} // ← aqui o [Symbol.dispose] do writer é chamado, mesmo se a linha acima lançar
```

O que é preciso saber antes de usar:

| Ponto | Estado verificado |
| --- | --- |
| Padrão | TC39, **stage 3** — não é JavaScript ratificado |
| Suporte no motor | `using` e `await using` são suportados nativamente no JavaScriptCore, o motor do Bun |
| Como funciona | o protótipo do objeto define `[Symbol.dispose]`, ou `[Symbol.asyncDispose]` para recurso assíncrono (`await using`) |
| APIs do Bun | dezenas, incluindo `Bun.spawn`, `Bun.serve`, `Bun.connect`, `Bun.listen` e `bun:sqlite` |
| `DisposableStack` / `AsyncDisposableStack` | implementados no Bun 1.3 — para acumular vários recursos num escopo só |
| TypeScript | **exige TS ≥ 5.2**, que introduziu a sintaxe |
| `tsconfig.json` | `lib` precisa incluir `"esnext"` ou `"esnext.disposable"`; o `lib: ["ESNext"]` do tsconfig recomendado pelo Bun já cobre |

A consequência de esquecer o `lib`: o código roda e o `tsc --noEmit` reprova, com erro sobre `Symbol.dispose` ausente. É falha de configuração de tipo, não de runtime.

E a fronteira: `using` é uma feature de **linguagem**, não do Bun. Um arquivo que a usa e é transpilado por outra ferramenta (ou consumido por um runtime sem `Symbol.dispose`) precisa de polyfill. Dentro de um app que roda em Bun, não precisa.

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| `if (Bun.file(p).size > 0)` para testar existência | arquivo inexistente também tem `size === 0`; a condição confunde "vazio" com "ausente" | `await Bun.file(p).exists` — `BUN-RT-03` |
| `const conteudo = Bun.file(p)` e usar `conteudo` como string | `Bun.file` devolve um `BunFile` preguiçoso, não o conteúdo; nada foi lido ainda | `await Bun.file(p).text` — `BUN-RT-02` |
| `writer.write(...)` em loop sem `.end` | o processo `bun` fica vivo esperando o `FileSink` fechar; o script "trava no fim" | `await writer.end`, ou `writer.unref` — `BUN-RT-04` |
| `readFileSync`/`spawnSync` dentro de handler de `Bun.serve` | bloqueia o event loop; sob carga, degrada todas as conexões, não só a atual | `Bun.file.text` / `Bun.spawn` — `BUN-RT-08` |
| `Bun.spawn` de comando externo sem `timeout` nem `signal` | processo pendurado mantém o pai vivo e vaza para o próximo deploy | `{ timeout, killSignal }` ou `{ signal }` — `BUN-RT-09` |
| `Bun.hash(senha)` ou `new Bun.CryptoHasher("sha256")` para senha | `Bun.hash` é não criptográfico; sha256 sem salt nem custo é quebrável por força bruta | `Bun.password.hash` / `.verify` — `BUN-RT-10` |
| `.env.production` esperando vencer `.env.local` | a precedência é crescente e `.env.local` é o último da lista | não versionar `.env.local` em máquina de deploy; usar `--env-file` explícito |
| Senha com `$` literal em `.env` sem escape | Bun expande `$VAR` por padrão; o valor chega truncado ou vazio | escapar com `\$` — `BUN-RT-07` |
| `bun --hot` para rodar a suíte de testes | estado global preservado entre reloads mascara falha de setup e vaza entre execuções | `bun test --watch` — `BUN-RT-11` |
| Imagem de container sem `node_modules`, contando com "o Bun resolve" | sem `node_modules`, Bun instala da rede em runtime e pode resolver `latest` | copiar `node_modules` (ou `bun ci` no build) e rodar com `--no-install` — `BUN-RT-12` |
| `bun run dev --watch` | `bun` repassa flags do fim do comando ao script; o watch nunca é ativado | `bun --watch run dev` |
| `bun run./index.ts --preload./setup.ts` | mesma armadilha: `--preload` vira argumento do script e o preload não roda | `bun --preload./setup.ts run./index.ts` — § 9 |
| Alias de path declarado só em `resolve.alias` do `vite.config.ts` | Bun não lê o `vite.config`; o import quebra em `bun test` e em qualquer execução fora do Vite | declarar em `compilerOptions.paths` — § 2 |
| `"jsx": "preserve"` no `tsconfig.json` de um projeto que roda em Bun | a fonte declara `"preserve"` não suportado; não há transform e o JSX não executa | `"react-jsx"` — § 2 |
| Ler `import.meta.env.DEV`/`.MODE` num componente que também roda em `bun test` | são constantes injetadas pelo Vite; sob Bun, `import.meta.env` é `process.env` e elas são `undefined` | receber por prop/config injetável — § 4 |
| Copiar o `bunfig.toml` do projeto para `$HOME/bunfig.toml` | o arquivo global se chama `.bunfig.toml`, com ponto; sem o ponto ele nunca é lido, e nada avisa | `$HOME/.bunfig.toml` — § 9 |
| `using` num projeto com TS < 5.2 ou sem `esnext.disposable` no `lib` | roda, mas `tsc --noEmit` reprova por `Symbol.dispose` ausente | TS ≥ 5.2 e `lib: ["ESNext"]` — § 10 |

---

## Checklist de revisão

- [ ] Existe `tsc --noEmit` no CI? O runtime não checa tipos.
- [ ] Toda checagem de existência de arquivo usa `.exists`? → `BUN-RT-03`
- [ ] Todo `FileSink` aberto é encerrado ou desvinculado? → `BUN-RT-04`
- [ ] Nenhuma chamada `*Sync` dentro de handler HTTP? → `BUN-RT-08`
- [ ] Todo `Bun.spawn` de comando externo tem `timeout` ou `signal`? → `BUN-RT-09`
- [ ] Senha usa `Bun.password`, e nada mais? → `BUN-RT-10`
- [ ] Variáveis de ambiente são validadas na inicialização? → `BUN-RT-06`
- [ ] Segredo de produção vem de secret manager, não de `.env`? → `BUN-RT-05`
- [ ] O modo de reload escolhido é o certo para o caso (`--watch` para teste, `--hot` para servidor)? → `BUN-RT-11`
- [ ] A imagem de produção tem `node_modules` ou roda com `--no-install`? → `BUN-RT-12`
- [ ] `compilerOptions.jsx` é `"react-jsx"` (ou `"react"`/`"react-jsxdev"`), nunca `"preserve"`? → § 2
- [ ] Todo alias de path existe em `compilerOptions.paths`, e não só no `vite.config.ts`? → § 2
- [ ] Nenhum componente compartilhado depende de `import.meta.env.MODE`/`.DEV`/`.PROD`? → § 4
- [ ] Toda flag do runtime (`--watch`, `--hot`, `--preload`, `-r`) vem **antes** do subcomando? → § 9

---

## Relacionados

- [Bun](bun.md) — hub, mapa da API, árvores de decisão
- [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) · [Bun - Testes](bun-testes.md) · [Bun - HTTP e Servidor](bun-http-e-servidor.md) · [Bun - Bundler e Build](bun-bundler-e-build.md) · [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md)
- `Node.js` · · `TypeScript`
- · `Arquivos.env não substituem secret management` ·
- · ·
-

## Fontes consultadas

Verificadas em **2026-08-15**:

- [Bun Runtime](https://bun.com/docs/runtime) · [Watch Mode](https://bun.com/docs/runtime/watch-mode)
- [Module Resolution](https://bun.com/docs/runtime/module-resolution) · [JSX](https://bun.com/docs/runtime/jsx) · [Auto-install](https://bun.com/docs/runtime/auto-install)
- [File I/O](https://bun.com/docs/runtime/file-io) · [Streams](https://bun.com/docs/runtime/streams)
- [Environment Variables](https://bun.com/docs/runtime/environment-variables)
- [Spawn](https://bun.com/docs/runtime/child-process) · [Hashing](https://bun.com/docs/runtime/hashing) · [Utils](https://bun.com/docs/runtime/utils)
- [Globals](https://bun.com/docs/runtime/globals) · [TypeScript](https://bun.com/docs/typescript) · [Node.js Compatibility](https://bun.com/docs/runtime/nodejs-compat)
- [bunfig.toml](https://bun.com/docs/runtime/bunfig) · [Loaders](https://bun.com/docs/bundler/loaders)
- Fora da fonte oficial do Bun, para a comparação de `import.meta.env`: [Vite — Env Variables and Modes](https://vite.dev/guide/env-and-mode); para o requisito de versão de `using`: [TypeScript 5.2 release notes](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-5-2.html)

**O que a verificação contrariou:**

- **A precedência de `.env` é crescente na ordem listada**: `.env` < `.env.{NODE_ENV}` < `.env.local`. `.env.local` vence `.env.production`.
- **`Bun.env` e `import.meta.env` são aliases de `process.env`**, não objetos distintos. Não há diferença semântica entre eles.
- **Bun desliga o carregamento automático de `.env` quando invocado como `node`** (`bun --bun`, `bunx --bun`, symlink `node`), para não atropelar a resolução de `.env.{mode}` de ferramentas como o Vite.
- **`Bun.hash` é declaradamente não criptográfico.** O nome sugere o contrário e a proximidade com `Bun.password` na mesma página aumenta o risco de troca.
- **`bcrypt` em `Bun.password` não trunca senha acima de 72 bytes** — passa por SHA-512 antes, diferente da implementação clássica.
- **Sem `node_modules`, o runtime instala pacotes da rede em tempo de execução**, resolvendo `latest` quando não há lockfile nem `package.json` acima.
- **`from "./x.js"` resolve `./x.ts`**, por compatibilidade com o compilador TypeScript. `.cjs` **não** é reescrito para `.cts`.
- **`--watch` roda os handlers do sinal de kill antes de reiniciar** (`SIGTERM` por padrão), o que dá lugar para shutdown limpo — comportamento ausente da maioria dos watchers.
- **O transpiler de runtime tem cache em disco** para arquivos acima de 4 KB (`BUN_RUNTIME_TRANSPILER_CACHE_PATH`), desligado automaticamente nas imagens Docker oficiais.
- **`"jsx": "preserve"` não é suportado.** Os outros três valores (`"react"`, `"react-jsx"`, `"react-jsxdev"`) são. O `tsconfig.json` que a própria doc do Bun recomenda traz `"jsx": "react-jsx"` — o mesmo valor dos templates de Vite + React, o que faz o caso mais comum não exigir configuração alguma.
- **O arquivo global de configuração se chama `.bunfig.toml`** (com ponto), e o do projeto `bunfig.toml` (sem). Os dois são combinados por *shallow merge*, com o do projeto vencendo.
- **`bun run` não lê o `bunfig.toml` global.** É a única exceção documentada à regra de merge: para `bun run`, só o arquivo local do projeto é carregado automaticamente.
- **`-r` é alias de `--preload`**, e o comportamento é declarado como análogo ao `node --require`. Não confirmei existência de `--import` no Bun.
- **No runtime, `import logo from "./logo.svg"` resolve para o caminho absoluto do arquivo em disco**, não para uma URL — o loader `file` verifica que o arquivo existe e devolve o path. É outra coisa do que o Vite entrega ao mesmo import.
- **`using` é feature de linguagem em stage 3**, suportada nativamente no JavaScriptCore e exigindo TypeScript ≥ 5.2 com `esnext.disposable` no `lib`. Não é açúcar do Bun, e não é `const`.
