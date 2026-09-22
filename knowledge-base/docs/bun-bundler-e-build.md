---
titulo: Bun - Bundler e Build
Link: https://bun.com/docs/bundler
tags:
 - bun
 - bundler
 - build
 - agent-context
source: "Documentação oficial — https://bun.com/docs"
verificado-em: 2026-08-15
---

# Bun - Bundler e Build

> `Bun.build` × `bun build` · `target` (`browser`/`bun`/`node`) e o que muda em cada · `external` × `packages` · splitting, `minify`, `sourcemap`, `define`, `loader` · plugins (`onResolve`/`onLoad`) · imports de HTML/CSS e o dev server com HMR · `--compile` para executável único · macros · onde Vite ainda ganha.
>
> **Não cobre:** resolução de módulos em runtime e transpilação sem bundle ([Bun - Runtime e APIs](bun-runtime-e-apis.md)) · instalação de dependências e lockfile ([Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md)) · o servidor que consome o artefato ([Bun - HTTP e Servidor](bun-http-e-servidor.md)) · imagem Docker e deploy ([Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md)).

Entrada: [Bun](bun.md) § 5 (árvores de decisão) · § 6 (regras normativas) · Base normativa: [Bun](bun.md)

Versão verificada: **Bun 1.3.14** (`bun@latest` no registry npm, 2026-08-15).

---

## 1. Conceito: o bundler existe para produzir artefato — a decisão real é `target` e o que fica externo

Bundler não é obrigatório em Bun. O runtime transpila TypeScript e JSX na importação, então código de servidor **roda sem build**. A doc é direta sobre isso: para `target: "bun"`, *"in many cases, it isn't necessary to bundle server-side code"*.

O que muda essa conclusão são três motivos concretos, e só eles:

1. **O código vai para o browser.** Aí não há escolha: TS/JSX precisam virar JS, e centenas de arquivos de `node_modules` precisam virar poucos.
2. **Você quer reduzir tempo de boot em produção.** Bundling move resolução, parse e transpilação de runtime para build time.
3. **Você quer um artefato único.** `--compile` produz um binário; imagem Docker sem `node_modules` é consequência disso — e é uma opção real de Dockerfile, não um detalhe de bundler. Se você chegou aqui vindo de "como containerizo isto", a § 8 desta nota é o destino, e o Dockerfile multi-stage convencional (com `node_modules` e `bun install --production`) está em [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) § 6. As duas formas são alternativas para o mesmo problema: `--compile` troca `node_modules` na imagem por um binário que já carrega o runtime.

Uma vez decidido que vai haver build, **duas opções decidem quase tudo o mais**: `target` (quais condições de resolução valem, qual runtime é assumido) e o que fica **externo** (o que não entra no bundle e será resolvido em runtime). Erra-se muito mais nessas duas do que em `minify` ou `splitting`.

E uma delimitação explícita da fonte, que evita expectativa errada: *"The Bun bundler is not intended to replace `tsc` for typechecking or generating type declarations."* Bundler não checa tipo. Typecheck continua sendo `tsc --noEmit` em passo separado — ver `TypeScript`.

---

## 2. `Bun.build` × `bun build`: mesma engine, ergonomia diferente

**Conceito.** As duas formas cobrem o mesmo conjunto de opções. A API programática ganha quando o build tem lógica (matriz de targets, plugins construídos em runtime, leitura do `metafile`); a CLI ganha para o caso simples de um script em `package.json`.

A diferença que importa em CI é o tratamento de falha: **`Bun.build` rejeita com um `AggregateError`**. Um `await Bun.build(...)` solto sem `try/catch` derruba o script com exit code diferente de zero — o que geralmente é o que você quer. Capturar e ignorar é como um build quebrado passa verde.

```ts
// build.ts — equivalente a: bun build./src/index.tsx --outdir./dist --target browser --minify
const resultado = await Bun.build({
 entrypoints: ["./src/index.tsx"],
 outdir: "./dist",
 target: "browser", // default
 format: "esm", // default
 splitting: true, // default false
 minify: true, // default false
 sourcemap: "linked", // default "none"; "linked" exige outdir
 define: {
 // chave = identificador; valor = string JSON que é inlinada
 "process.env.NODE_ENV": JSON.stringify("production"),
 __VERSAO__: JSON.stringify(Bun.env.GIT_SHA ?? "dev"),
 },
});

for (const artefato of resultado.outputs) {
 console.log(artefato.path, artefato.kind);
}
```

Detalhe fácil de errar em `define`: **o valor é uma string JSON**, não o valor. `define: { API_URL: "https://x" }` inlina o identificador `https://x` e quebra o parse. `JSON.stringify(...)` sempre.

| ID | Regra |
| --- | --- |
| `BUN-BUILD-01` | Script de build **MUST** deixar o `AggregateError` de `Bun.build` propagar (ou sair com código diferente de zero) — build quebrado **NEVER** termina com sucesso. |
| `BUN-BUILD-02` | Valores de `define` **MUST** ser produzidos por `JSON.stringify` — a opção inlina o texto literalmente. |

---

## 3. `target`: a opção que decide resolução, globais e polyfill

**Conceito.** `target` não é um rótulo de saída. Ele muda **qual export condition vence** na resolução e o que o bundler assume existir no ambiente.

| `target` | Export condition | O que assume | Marca no output |
| --- | --- | --- | --- |
| `"browser"` | `"browser"` | **default.** `node:*` importa, mas nem tudo funciona — a doc cita `fs.readFile` como exemplo do que não roda | — |
| `"bun"` | condições do Bun | runtime Bun completo; alvo de app fullstack com HTML importado no servidor | pragma `// @bun` (o runtime pula a retranspilação) |
| `"node"` | `"node"` | Node.js. **Bun não faz polyfill do global `Bun` nem dos módulos `bun:*`** | — |

Dois defaults implícitos que surpreendem:

- **Shebang de Bun no entrypoint (`#!/usr/bin/env bun`) muda o default de `target` para `"bun"`.**
- **`format: "cjs"` muda o default de `target` de `"browser"` para `"node"`.**

`format` aceita `"esm"` (default), `"cjs"` e `"iife"`; a doc marca **`cjs` e `iife` como experimentais**. Combinar `target: "bun"` com `format: "cjs"` gera o pragma `// @bun @bun-cjs`, e a doc avisa que **esse wrapper CommonJS não é compatível com Node.js** — bundle marcado assim não roda lá.

| ID | Regra |
| --- | --- |
| `BUN-BUILD-03` | `target` **MUST** ser declarado explicitamente em todo build de produção — o default (`"browser"`, ou `"bun"`/`"node"` por shebang/format) muda a resolução em silêncio. |
| `BUN-BUILD-04` | Código que usa `Bun.*` ou `bun:*` **NEVER** é bundleado com `target: "node"` — não há polyfill; a falha aparece só em runtime. |

---

## 4. `external` e `packages`: o que sai do bundle

**Conceito.** Duas opções resolvem problemas parecidos em granularidades diferentes.

- **`external: ["react", "lodash"]`** — lista explícita. O import fica no output como está, para ser resolvido em runtime.
- **`packages: "external"`** — desliga o bundling de **todas** as dependências de uma vez. Bun trata como pacote qualquer import cujo caminho não comece com `.`, `..` ou `/`. Default é `"bundle"`.

O critério prático:

| Situação | Escolha |
| --- | --- |
| Bundle de browser para app próprio | tudo interno (default) |
| Biblioteca publicada no npm | `packages: "external"` — dependências resolvidas pelo consumidor |
| Servidor que continua com `node_modules` ao lado | `packages: "external"` |
| Servidor em imagem enxuta, sem `node_modules` | default (`"bundle"`), ou `--compile` |
| Addon nativo / `.node` que não pode ser bundleado | `external` só para ele |

**`splitting`** (default `false`) só faz sentido com múltiplos entrypoints ou `import` dinâmico: o código compartilhado vira um chunk com hash de conteúdo no nome. Ligar splitting com um único entrypoint e nenhum import dinâmico não produz chunk nenhum — só ruído no output.

| ID | Regra |
| --- | --- |
| `BUN-BUILD-05` | Biblioteca publicada em registry **MUST** ser bundleada com `packages: "external"` — dependência bundleada duplica código e quebra deduplicação no consumidor. |

---

## 5. `minify`, `sourcemap`, `loader`

**Conceito.** Os três compõem o artefato de produção, e cada um tem uma pegadinha.

**`minify`** (default `false`) aceita booleano ou granular: `{ whitespace, identifiers, syntax }`. Na CLI, `--minify-whitespace`, `--minify-identifiers`, `--minify-syntax`.

**`sourcemap`** (default `"none"`):

| Valor | Produz | Observação |
| --- | --- | --- |
| `"none"` | nada | default |
| `"linked"` | `.js.map` separado + comentário `//# sourceMappingURL` | **exige `outdir`** |
| `"external"` | `.js.map` separado, **sem** o comentário | insere `//# debugId=…` para casar bundle e mapa |
| `"inline"` | mapa em base64 no fim do bundle | infla o artefato servido ao cliente |

Para browser, `"external"` é o que dá stack trace legível no coletor de erros sem publicar o mapa junto do bundle — o `debugId` é o que liga os dois. `"inline"` em bundle de produção manda o código-fonte inteiro para todo visitante.

**`loader`** mapeia extensão para um loader embutido. Os nomes verificados: `js`, `jsx`, `ts`, `tsx`, `json`, `jsonc`, `toml`, `yaml`, `file`, `napi`, `wasm`, `text`, `css`, `html`.

```ts
await Bun.build({
 entrypoints: ["./src/index.tsx"],
 outdir: "./dist",
 loader: {
 ".png": "dataurl", // inlina como data: URI
 ".sql": "text", // importa como string
 },
});
```

**`bytecode`** merece nota porque as restrições são estritas: exige `target: "bun"` e uma versão de Bun correspondente. Em CommonJS funciona com ou sem `compile`, gerando `.jsc` ao lado do entrypoint; **em ESM exige `compile: true`**. Sem `format` explícito, `bytecode` assume CommonJS. Não ofusca o código-fonte.

| ID | Regra |
| --- | --- |
| `BUN-BUILD-06` | Bundle de browser em produção **NEVER** usa `sourcemap: "inline"` — use `"external"` e envie o mapa ao coletor de erros. |

---

## 6. Plugins: a mesma API para runtime e bundler

**Conceito.** A API de plugin é **universal**: o mesmo objeto estende o bundler e o runtime. Um plugin é `{ name, setup(build) }`.

Hooks verificados: `onStart` (bundle começou; pode devolver Promise, e o bundler espera), `onResolve` (antes de resolver um módulo), `onLoad` (antes de carregar), `onBeforeParse` (addon nativo zero-copy na thread do parser), `onEnd` (bundle terminou, recebe o `BuildOutput`).

`onResolve` e `onLoad` recebem `{ filter: RegExp, namespace?: string }`. Namespace é o prefixo do módulo no código transpilado; o default é `"file"`, e `"bun"` / `"node"` cobrem os módulos embutidos.

```ts
import type { BunPlugin } from "bun";

// carrega.sql como string exportada por default
const sqlPlugin: BunPlugin = {
 name: "sql-loader",
 setup(build) {
 build.onLoad({ filter: /\.sql$/ }, async ({ path }) => ({
 loader: "js",
 contents: `export default ${JSON.stringify(await Bun.file(path).text)};`,
 }));
 },
};

await Bun.build({ entrypoints: ["./src/index.ts"], outdir: "./dist", plugins: [sqlPlugin] });
```

`filter` é uma `RegExp` aplicada ao caminho. Um filtro largo demais (`/.*/`) faz o callback rodar para cada módulo do grafo, incluindo tudo em `node_modules` — é a causa mais comum de build lento com plugin próprio.

| ID | Regra |
| --- | --- |
| `BUN-BUILD-07` | `filter` de `onLoad`/`onResolve` **MUST** ser ancorado na extensão ou no namespace pretendido — filtro largo executa o callback para todo módulo do grafo. |

---

## 7. HTML, CSS e o dev server: útil, e declarado *work in progress*

**Conceito.** `bun./index.html` sobe um dev server sem configuração: Bun varre o HTML com `HTMLRewriter`, acha `<script>` e `<link>`, roda bundler + transpiler + parser de CSS, reescreve os caminhos com hash e serve.

```bash
bun./index.html # SPA: o HTML vira fallback de todas as rotas
bun./index.html./about.html # MPA: / e /about
bun./**/*.html # glob; o prefixo comum vira a base
```

O mesmo import de HTML funciona dentro do servidor, ligando esta nota a [Bun - HTTP e Servidor](bun-http-e-servidor.md):

```ts
import painel from "./painel.html";

Bun.serve({
 routes: {
 "/": painel, // bundleado e servido
 "/api/pedidos": { GET: => Response.json(listarPedidos) },
 },
 development: { hmr: true, console: true }, // console: ecoa log do browser no terminal
});
```

O que `development` liga e desliga, verificado:

| | `development: true` | `development: false` |
| --- | --- | --- |
| Sourcemap | header `SourceMap` presente | desligado |
| Minificação | **desligada** | ligada |
| HMR | ligado (salvo `hmr: false`) | desligado |
| Bundling do `.html` | **rebundle a cada request** | lazy no primeiro request, cacheado em memória até reiniciar |
| `Cache-Control` / `ETag` | — | enviados |

Para produção há o caminho AOT, disponível **desde Bun v1.2.17**: `bun build --target=bun --production --outdir=dist./src/index.ts` transforma o import de HTML em um manifesto pré-construído, e `Bun.serve` passa a servir sem bundlar nada em runtime.

**Estado de estabilidade — não presuma.** A própria doc marca duas coisas:

> "The fullstack dev server is a work in progress. Features and APIs may change."

> "The HMR API is still a work in progress. Some features are missing."

Na tabela de `import.meta.hot`, `invalidate` e `send` estão marcados como **não implementados**, e `prune` como parcial (*"callback is currently never called"*). `accept`, `data`, `dispose`, `on`/`off` funcionam. E há uma restrição sintática que quebra código em silêncio: para a eliminação de código morto funcionar, **a frase `import.meta.hot.<API>` tem que aparecer inteira e direta**. `const hot = import.meta.hot; hot.accept` não funciona.

| ID | Regra |
| --- | --- |
| `BUN-BUILD-08` | APIs de `import.meta.hot` **MUST** ser chamadas na forma completa `import.meta.hot.x`, sem passar por variável ou argumento — o contrário quebra a eliminação em produção. |
| `BUN-BUILD-09` | Deploy de app fullstack **MUST** usar build AOT (`bun build --target=bun --production`) ou `development: false`; o dev server **NEVER** serve produção. |

---

## 8. `--compile`: um binário, com limites declarados

**Conceito.** `--compile` embute o bundle **e uma cópia do runtime Bun** num único executável. Todas as APIs embutidas de Bun e Node continuam funcionando dentro dele.

```bash
# produção, conforme a recomendação da doc
bun build./src/servidor.ts --compile --minify --sourcemap --bytecode --outfile./servidor

# cross-compile: alvo declarado explicitamente
bun build./src/servidor.ts --compile --target=bun-linux-x64 --outfile./servidor
```

O que cada flag faz, verificado: `--minify` encolhe o output; `--sourcemap` embute um mapa comprimido com zstd, e Bun o resolve sozinho quando um erro acontece; `--bytecode` move o parse do JavaScriptCore de runtime para build time (a doc mostra `tsc` iniciando **2x mais rápido**), sem ofuscar o fonte.

**Limitações declaradas** — `--compile` não aceita:

- `--outdir` (use `--outfile`)
- `--public-path`
- `--target=node`
- `--target=browser` sem entrypoint HTML
- `--no-bundle` (o compile sempre bundleia tudo)

`--compile` **suporta** `--splitting` (chunks carregados em runtime pelo próprio binário) e plugins.

**No Dockerfile, `--compile` é a alternativa à imagem com `node_modules`.** Um binário produzido aqui roda numa imagem base sem Bun instalado e sem `node_modules` copiado — o custo é cross-compile explícito (`BUN-BUILD-10`) quando a máquina de build difere do destino, e uma imagem maior por binário do que a soma dos fontes. O caminho convencional, com `oven/bun` + `bun install --frozen-lockfile --production`, está em [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) § 6 com o Dockerfile completo e as regras de deploy (`BUN-SYS-11`, `BUN-SYS-12`). Escolher entre os dois é escolher entre "imagem menor, um passo de build a mais" e "imagem com runtime instalado, deploy igual ao de qualquer app Node".

| ID | Regra |
| --- | --- |
| `BUN-BUILD-10` | Binário de `--compile` para deploy **MUST** declarar `--target=bun-<os>-<arch>` quando a máquina de build difere do destino — cross-compile não é inferido. |

---

## 9. Macros: bundle-time, e não marcadas como experimentais

**Conceito.** Uma macro é uma função JavaScript comum que roda **durante o bundle**; Bun inlina o retorno no output e o fonte da função não vai para o bundle. Ativa-se pelo import attribute:

```ts
import { hashDoCommit } from "./git.ts" with { type: "macro" };

console.log(`build ${hashDoCommit}`); // vira uma string literal no bundle
```

Status na fonte: **a página de Macros não traz marcação de experimental ou beta**. O que ela traz são restrições duras, e é nelas que o código quebra:

- **Só valores serializáveis.** JSON funciona; função e instância de classe não. `Response` e `Blob` têm serialização especial guiada pelo `Content-Type` — uma macro pode devolver o resultado de `fetch` direto.
- **Argumentos precisam ser estaticamente conhecidos.** Passar uma variável calculada em runtime é erro de build.
- **Macros rodam de forma síncrona no transpiler, na fase de visita — antes dos plugins.**
- **Código em `node_modules` não pode invocar macro** (barreira de segurança). Seu código pode importar macro *de* um pacote.
- `--no-macros` desliga tudo, com erro de build.

A eliminação de código morto roda **depois** da macro, então `if (macroQueRetornaFalse) { … }` some do bundle quando `minify.syntax` está ligado. É o mecanismo para compilar feature flags para fora.

| ID | Regra |
| --- | --- |
| `BUN-BUILD-11` | Macro **NEVER** recebe argumento cujo valor dependa de runtime, e **MUST** devolver apenas valor serializável (JSON, `Response` ou `Blob`). |

---

## 10. Onde Vite ainda ganha, e onde Bun já cobre

Uma comparação honesta é o que torna esta nota útil. Verificado na doc oficial de Bun; a coluna de Vite reflete o que a doc de Bun **não** oferece.

| Situação | Escolha | Por quê |
| --- | --- | --- |
| SPA React em produção, com ecossistema de plugins (Tailwind via plugin oficial, SVGR, i18n, análise de bundle) | **Vite** | Bun tem plugins, mas o ecossistema publicado é do Vite; a doc de Bun cita suporte a Tailwind e pouco mais |
| App React com HMR sofisticado e Fast Refresh maduro | **Vite** | a API de HMR de Bun é declarada *work in progress*, com `invalidate` e `send` não implementados |
| Framework de meta-nível (Next, Remix, SvelteKit, TanStack Start) | **o bundler do framework** | o build é parte do framework, não uma escolha sua |
| Landing page ou SPA pequena, sem plugin de terceiro | **Bun** | `bun./index.html` sobe sem configuração e sem dependência |
| App fullstack em que servidor e cliente moram no mesmo processo | **Bun** | HTML importado no servidor + AOT build produz um artefato só |
| CLI distribuída como binário | **Bun** | `--compile` não tem equivalente direto em Vite |
| Bundle de servidor para reduzir boot e imagem | **Bun** | `target: "bun"` + `--compile`, sem `node_modules` no destino |
| Biblioteca publicada no npm | **Bun**, com ressalva | `packages: "external"` cobre o bundle; os `.d.ts` continuam sendo trabalho do `tsc` |

Regra prática: **quanto mais o build é do frontend, mais Vite ganha; quanto mais o build é do artefato de servidor ou do binário, mais Bun ganha.** Os dois convivem — a doc oficial tem guia de Vite rodando sob Bun.

### 10.1 O caso que as duas linhas cobrem: SPA React com um backend pequeno

As linhas "SPA React em produção com plugins → **Vite**" e "app fullstack no mesmo processo → **Bun**" descrevem o mesmo app quando alguém tem uma SPA React e um backend de dez rotas. É o caso mais comum, e a tabela sozinha não desempata. O desempate:

| Pergunta | Se sim | Por quê |
| --- | --- | --- |
| O frontend depende de algum plugin de Vite que não seja Tailwind? (SVGR, i18n, análise de bundle, mdx, plugin de framework) | **Vite** | é o único critério que não tem contorno: o plugin não existe no formato de Bun e portá-lo é trabalho seu |
| Trocar o Vite obrigaria alguém a debugar HMR durante a semana de entrega? | **Vite** | a API de HMR de Bun é declarada *work in progress* pela própria doc |
| O deploy hoje é dois artefatos (estático + servidor) e isso já dói — CORS, duas pipelines, dois domínios? | **Bun** | o import de HTML no servidor colapsa os dois em um processo; ver [Bun - HTTP e Servidor](bun-http-e-servidor.md) § 7.1 |
| O backend vai crescer e você quer um artefato só? | **Bun** | AOT + `--compile` fecham o ciclo sem segundo bundler |
| Nenhuma das anteriores | **fique com o Vite** | é a opção com custo de reversão zero: manter o Vite não fecha nenhuma porta, e a decisão pode esperar |

O padrão por trás: **o custo de sair do Vite é proporcional ao número de plugins**, e o ganho de entrar no Bun é proporcional a quanto o servidor importa. SPA com backend pequeno e três plugins fica no Vite; SPA com backend crescendo e nenhum plugin além de Tailwind é exatamente o caso em que o caminho fullstack de Bun paga.

### 10.2 Fast Refresh e "hot reloading" não são a mesma promessa

A decisão acima depende de uma pergunta concreta — *o hot reload preserva o estado do componente?* — e a resposta verificável é parcial:

- **Bun tem a transformação de Fast Refresh.** A CLI expõe a flag `--react-fast-refresh`, descrita na fonte como *"Enable React Fast Refresh transform (for development testing)"*.
- **A doc de HMR reconhece Fast Refresh como participante do mecanismo**, na cláusula que descreve o fallback: *"When no modules call `import.meta.hot.accept` (and there isn't React Fast Refresh or a plugin calling it for you), the page reloads when the file updates."* Ou seja, sem Fast Refresh (ou um `accept` explícito) o comportamento é **recarregar a página** — e recarregar a página perde o estado, sempre.
- **Não verificado:** se o template de `bun init --react` liga a transformação, e se o estado de componente é preservado através de um hot update. A doc do template diz apenas *"starts the API server and the React app with hot reloading"*, sem qualificar. A página de HMR não afirma preservação de estado de React em lugar nenhum; o que ela documenta para preservar estado é o `import.meta.hot.data`, que é manual e por módulo.

Consequência prática, e é o que interessa à decisão: **não presuma paridade de Fast Refresh com o `@vitejs/plugin-react`**. Se preservar o estado do formulário enquanto se edita o componente é parte do fluxo de trabalho da equipe, isso precisa ser testado no seu projeto antes da troca, não deduzido da doc.

### 10.3 O que rodar Vite sob `--bun` dá, segundo a fonte

O guia oficial de Vite recomenda `bunx --bun vite`, e é justo perguntar o que se ganha. **A fonte declara mecanismo, não benefício** — vale registrar exatamente isso, porque a recomendação circula como se fosse ganho de performance:

- O que `--bun` faz: *"The `--bun` flag tells Bun to run Vite's CLI using `bun` instead of `node`; by default Bun respects Vite's `#!/usr/bin/env node` shebang line."* Sem a flag, Bun **sobe um processo `node`** para executar o binário do Vite.
- Como faz: `--bun` cria um symlink para o executável do Bun chamado `"node"` num diretório temporário e o coloca no `PATH` durante a execução do script — então processos filhos que chamem `node` também caem no Bun.
- **A doc não declara nenhum ganho de tempo de build, de dev server ou de capacidade.** Nenhum número, nenhuma comparação. Quem quiser afirmar ganho precisa medir no próprio projeto.

E a consequência mais citada — `--bun` desligar o carregamento automático de `.env` — **não é uma perda acidental, é comportamento deliberado de paridade com Node**, e a fonte explica por quê: *"When Bun is invoked as `node` … automatic `.env` loading is disabled to match Node.js. This lets tools with their own mode-aware `.env` resolution, such as Vite's `loadEnv`, pick the correct `.env.{mode}` file instead of seeing Bun's pre-populated values as shell-set overrides."* Para um projeto Vite isso é o comportamento **correto**: é o que faz `.env.production` e o filtro por prefixo `VITE_` funcionarem como o Vite espera, em vez de o Bun pré-popular tudo. `--env-file` explícito continua sendo respeitado.

Sobre publicação de estático, ver.

> A doc lista `--app` e a flag de React Server Components (Bun Bake) explicitamente como **EXPERIMENTAL**. Não é caminho para produção hoje. A flag `--react-compiler` também é marcada **Experimental**.

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| Contar com o bundler para pegar erro de tipo | a doc declara que o bundler não substitui `tsc`; ele apaga os tipos sem checar | `tsc --noEmit` em passo separado no CI |
| `define: { API_URL: "https://api.exemplo.com" }` | o valor é inlinado como texto literal, gerando identificador inválido | `JSON.stringify(...)` — `BUN-BUILD-02` |
| Omitir `target` e assumir que servidor é o default | o default é `"browser"`; shebang e `format: "cjs"` mudam isso em silêncio | declarar `target` sempre — `BUN-BUILD-03` |
| `target: "node"` em código que usa `Bun.serve` ou `bun:sqlite` | não há polyfill do global `Bun` nem de `bun:*`; quebra só em runtime | `target: "bun"` — `BUN-BUILD-04` |
| `try { await Bun.build(...) } catch {}` no script de build | o `AggregateError` é engolido e o CI passa com artefato quebrado | deixar propagar — `BUN-BUILD-01` |
| `sourcemap: "inline"` no bundle de browser | o código-fonte inteiro é baixado por cada visitante | `"external"` + upload do mapa — `BUN-BUILD-06` |
| Publicar biblioteca com dependências bundleadas | duplica React/lodash no consumidor e quebra a deduplicação | `packages: "external"` — `BUN-BUILD-05` |
| `const hot = import.meta.hot; hot.accept` | a eliminação de código morto exige a frase inteira e direta; em produção quebra | `import.meta.hot.accept` — `BUN-BUILD-08` |
| Servir produção com `development: true` | rebundle a cada request, sem minificação, sem `Cache-Control` nem `ETag` | build AOT ou `development: false` — `BUN-BUILD-09` |
| `bun build --compile --outdir dist` | `--compile` não aceita `--outdir`; o build falha | `--outfile` — `BUN-BUILD-10` |
| Macro recebendo valor calculado em runtime | argumento de macro precisa ser estaticamente conhecido; é erro de build | passar constante ou o retorno de outra macro — `BUN-BUILD-11` |
| `filter: /.*/` em `onLoad` | o callback roda para todo módulo, inclusive `node_modules` inteiro | ancorar por extensão ou namespace — `BUN-BUILD-07` |

---

## Checklist de revisão

- [ ] `target` está declarado explicitamente? → `BUN-BUILD-03`
- [ ] Nenhum `Bun.*` / `bun:*` sob `target: "node"`? → `BUN-BUILD-04`
- [ ] Todo valor de `define` passa por `JSON.stringify`? → `BUN-BUILD-02`
- [ ] A falha de `Bun.build` derruba o processo? → `BUN-BUILD-01`
- [ ] `sourcemap` de produção é `"external"`, não `"inline"`? → `BUN-BUILD-06`
- [ ] Biblioteca publicada usa `packages: "external"`? → `BUN-BUILD-05`
- [ ] `import.meta.hot.*` sempre na forma completa? → `BUN-BUILD-08`
- [ ] Produção roda AOT ou `development: false`? → `BUN-BUILD-09`
- [ ] Cross-compile declara `--target=bun-<os>-<arch>`? → `BUN-BUILD-10`
- [ ] Macros recebem só valor estático e devolvem só serializável? → `BUN-BUILD-11`
- [ ] `filter` de plugin é ancorado? → `BUN-BUILD-07`
- [ ] Existe um `tsc --noEmit` em algum passo do CI?

---

## Relacionados

- [Bun](bun.md) — hub
- [Bun - HTTP e Servidor](bun-http-e-servidor.md) · [Bun - Runtime e APIs](bun-runtime-e-apis.md) · [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) · [Bun - Dados e Persistência](bun-dados-e-persistencia.md) · [Bun - Shell, FFI e Compat Node](bun-shell-ffi-e-compat-node.md) · [Bun - Testes](bun-testes.md)
- · `TypeScript` · [React.js](react-js.md) · `Next.js` · `Tailwindcss`
- · `Github Actions`

## Fontes consultadas

Verificadas em **2026-08-15**:

- [Bundler](https://bun.com/docs/bundler) — API completa, `target`, `format`, `splitting`, `minify`, `sourcemap`, `external`, `packages`, `define`, `loader`, `bytecode`
- [Fullstack dev server](https://bun.com/docs/bundler/fullstack) · [Hot reloading](https://bun.com/docs/bundler/hot-reloading) · [HTML & static sites](https://bun.com/docs/bundler/html-static)
- [Single-file executable](https://bun.com/docs/bundler/executables) · [Plugins](https://bun.com/docs/bundler/plugins) · [Macros](https://bun.com/docs/bundler/macros)
- [`bun build` (CLI)](https://bun.com/docs/cli/build) — `--react-fast-refresh`, `--react-compiler`
- [Build a React app with Bun](https://bun.com/docs/guides/ecosystem/react) — template `bun init --react` · [Vite com Bun](https://bun.com/docs/guides/ecosystem/vite) · [`bunx`](https://bun.com/docs/pm/cli/bunx) e [`bun run`](https://bun.com/docs/cli/run) — o que `--bun` faz
- [Environment variables](https://bun.com/docs/runtime/environment-variables) — por que `--bun` desliga o carregamento automático de `.env`
- Versão: `https://registry.npmjs.org/bun/latest` → **1.3.14**

**Notas de verificação** — pontos em que a fonte contraria o que se assume por hábito:

- **O dev server fullstack e a API de HMR são declarados *work in progress* na própria doc.** `import.meta.hot.invalidate` e `.send` aparecem como **não implementados**, e `.prune` como parcial (*"callback is currently never called"*).
- **`format: "cjs"` e `"iife"` são experimentais**, e `cjs` muda o default de `target` de `"browser"` para `"node"`.
- **Um shebang `#!/usr/bin/env bun` no entrypoint muda o default de `target` para `"bun"`** — sem nenhuma flag.
- **`target: "bun"` + `format: "cjs"` gera um wrapper CommonJS que a doc declara incompatível com Node.js.**
- **Macros não estão marcadas como experimentais**, ao contrário do que a raridade da feature sugere. As restrições reais são serialização e argumentos estáticos.
- **Macros rodam antes dos plugins** — síncronas, na fase de visita do transpiler.
- **`--compile` não aceita `--outdir`, `--public-path`, `--target=node` nem `--no-bundle`**, mas **aceita** `--splitting` e plugins.
- **`bytecode` em ESM exige `compile: true`**; em CommonJS funciona sozinho. Sem `format` explícito, assume CommonJS.
- **`sourcemap: "linked"` exige `outdir`**, e `"external"` adiciona um `debugId` para casar bundle e mapa.
- **`--app` e a flag de React Server Components (Bun Bake) estão marcados EXPERIMENTAL** na ajuda da CLI.
- A doc afirma explicitamente que **o bundler não substitui `tsc`** para typecheck ou geração de `.d.ts`.
- **Existe uma flag `--react-fast-refresh`** em `bun build`, descrita como *"for development testing"*. Mas **não foi verificado** se o template `bun init --react` a liga, nem se o estado de componente sobrevive a um hot update — a doc do template diz só "hot reloading", e a página de HMR nunca afirma preservação de estado de React. O único mecanismo de preservação que ela documenta é o `import.meta.hot.data`, manual e por módulo.
- **A recomendação de rodar Vite sob `--bun` não vem acompanhada de benefício declarado.** A fonte descreve só o mecanismo: executar a CLI no runtime do Bun em vez de subir um processo `node`, com um symlink `node` → Bun no `PATH` durante a execução. Nenhum número, nenhuma comparação de tempo.
- **`--bun` desligar o carregamento automático de `.env` é deliberado, não regressão.** A doc explica que é paridade com Node para que o `loadEnv` do Vite resolva `.env.{mode}` corretamente em vez de ver valores já populados pelo Bun. `--env-file` explícito continua valendo.
