---
titulo: Bun - Testes
Link: https://bun.com/docs/test
tags:
 - bun
 - testing
 - reference
 - agent-context
source: "Documentação oficial — bun.com/docs/test (test runner), guias de Testing Library e migração"
verificado-em: 2026-08-20
---

# Bun - Testes — referência conduzida

> **O que esta nota é.** O ponto de entrada único para `bun test` neste vault: para mim ao consultar, e para agentes de código ao escrever, corrigir ou revisar teste. Não é um resumo linear da documentação — é um **roteador**. Ela decide o que carregar, oferece o modelo mental que faz o resto fazer sentido, e expõe regras citáveis que uma skill ou um code review pode referenciar por ID.
>
> **O que não é.** Não substitui a fonte. Quando houver divergência, [bun.com/docs/test](https://bun.com/docs/test) vence, e esta nota deve ser corrigida. E não decide **o que** testar: isso é.

Inventário verificado diretamente em bun.com em **2026-08-20**, contra **Bun 1.4.0** (`latest` no npm na mesma data).
Ver [Fontes consultadas](#fontes-consultadas).

---

## 1. Como usar esta doc

### Para um humano

Leia a § 2 uma vez — são cinco afirmações, e três delas contrariam o hábito trazido de Jest ou Vitest. Depois use a § 4 como índice e a § 5 quando estiver entre duas APIs. Os satélites são leitura sob demanda, nunca em ordem.

### Para um agente de código

Carregue nesta ordem, parando assim que tiver o suficiente:

| Passo | Carregar | Quando |
| --- | --- | --- |
| 1 | Esta nota (§ 2, § 3, § 5, § 6) | sempre que a tarefa envolver teste em Bun |
| 2 | [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) | sempre que for **escrever ou editar** um arquivo de teste |
| 3 | O satélite do domínio tocado | quando a tarefa toca mock, isolamento, DOM, cobertura — use a § 4 para descobrir qual |
| 4 | [Bun](bun.md) § 2 e § 3 | quando o teste toca API do runtime (`Bun.file`, `Bun.serve`, `bun:sqlite`) |

**Regra de economia de contexto:** nunca carregue os seis satélites. Escrever um teste de unidade precisa de § 2 + § 6 + [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md). Diagnosticar "passa sozinho, falha na suíte" precisa de § 5.1 + [Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) — e de mais nada. Os três recortes prontos estão na § 7.

### Convenções e vocabulário

Todos os exemplos são TypeScript e importam de `bun:test` explicitamente, mesmo onde o global existiria (§ 3).

| Termo | Significado nesta doc |
| --- | --- |
| **runner** | o modo `bun test` do mesmo binário que executa a aplicação — não é um pacote separado |
| **preload** | script declarado em `[test] preload` / `--preload`, avaliado **antes** dos arquivos de teste |
| **escopo de execução** | o que vive por invocação inteira: hooks de preload, `mock.module`. Não é reiniciado entre arquivos |
| **escopo de arquivo** | o que vive por arquivo: `beforeAll` no topo, estado de módulo. Só é reiniciado com `--isolate` |
| **isolação** | `globalThis` novo por arquivo (`--isolate`, implícito em `--parallel`) |
| **worker** | processo que recebe arquivos sob `--parallel`; identificado por `BUN_TEST_WORKER_ID` |
| **concorrência** | testes do **mesmo** arquivo se sobrepondo num só thread (`test.concurrent`) — não é paralelismo |
| **shard** | fatia determinística da suíte, para dividir entre máquinas de CI (`--shard=i/n`) |
| **falso positivo** | teste verde cuja asserção não executou. É a categoria de defeito que esta doc mais combate |

---

## 2. Modelo mental

Cinco afirmações. Quase todo erro que um agente comete em `bun test` viola uma delas.

**1. O runner é um modo do runtime, não uma ferramenta.** TypeScript, JSX, `paths`, `.env` e loaders já funcionavam antes do teste existir — não há etapa de transformação para configurar, e por isso `ts-jest`, `babel-jest` e o bloco `transform` não têm equivalente. O outro lado da mesma moeda: **o que o runtime não resolve, o teste também não** — plugin de Vite, `resolve.alias`, SVG como componente.

**2. O default é um global compartilhado por todos os arquivos.** Um processo, um `globalThis`, todos os arquivos dentro dele. Estado deixado por um arquivo está visível no seguinte. Jest e Vitest fazem o contrário por default, e é dessa diferença que sai a maioria dos "passa sozinho, falha na suíte". Isolação existe (`--isolate`, implícito em `--parallel`) e **não conserta** o teste: ela expõe a conta.

**3. Verde significa "as asserções que rodaram passaram" — não que elas rodaram.** Asserção dentro de `catch` que nunca foi alcançado, `await` esquecido num `userEvent`, `expectTypeOf` que é no-op, snapshot regravado por reflexo: quatro formas de teste verde que não verifica nada. `expect.assertions(n)` existe para essa classe de defeito, e é o único mecanismo que a pega.

**4. Mock tem escopo, e o escopo raramente é o que você quer.** As três limpezas fazem coisas diferentes, e `mock.restore` **não** desfaz `mock.module` — mock de módulo é estado de processo. Como o default é um global compartilhado, "vazou" não significa "afetou o próximo teste": significa "afetou o resto da suíte".

**5. Configuração de teste mora no `bunfig.toml`, e o comando é só o que varia por invocação.** Se `bun test` puro não funciona no projeto, a configuração está no lugar errado. Isso importa mais aqui do que em outros runners, porque é o comando que qualquer pessoa — ou agente — roda sem ler documentação.

> **A inversão que importa.** É tentador ler `bun test` como "Jest mais rápido, sem config". A velocidade e a ausência de config são reais, mas vêm de uma escolha de arquitetura — um processo, um global — que muda o que **você** precisa garantir. Jest te dava isolamento de graça e cobrava em configuração e tempo. Bun te dá velocidade e configuração zero, e cobra em disciplina de estado. Trocar de runner sem trocar de disciplina é o caminho para uma suíte que passa por acidente.

---

## 3. Fronteiras de import e ambiente

**O que vem de `bun:test`:**

```ts
import {
 test, it, describe, expect,
 beforeAll, beforeEach, afterEach, afterAll, onTestFinished,
 mock, spyOn, jest, vi,
 setSystemTime, expectTypeOf,
} from "bun:test";
```

Tudo isso também existe como global. **Prefira o import**: é o que faz o arquivo passar em `tsc --noEmit` sem depender de declaração global, e o que deixa explícito, na revisão, que aquele `mock` é o do runner.

| Fronteira | Regra |
| --- | --- |
| `import { … } from "vitest"` | **reescrito internamente** para `bun:test`. Muito teste de Vitest roda sem edição — o que não migra é a configuração (§ 5.4) |
| `import { … } from "@jest/globals"` | idem |
| `jest.*` e `vi.*` | existem como objetos de compatibilidade; a superfície verificada está em [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) § 6 |
| `document`, `window` | **não existem** por default. Entram por preload, como código ([Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md)) |
| `vite.config.ts` / `vitest.config.ts` | **não são lidos**. Nem `resolve.alias`, nem `define`, nem plugins |
| `jest.config.js` | não é lido. O equivalente é `[test]` no `bunfig.toml` |

**Ambiente imposto pelo runner:** `NODE_ENV="test"` (se ainda não definida) e `TZ="Etc/UTC"` (se `TZ` não estiver definida). E o exit code inclui uma condição que surpreende: **erro não tratado fora de qualquer teste faz o processo sair `1` mesmo com todos os testes verdes** ([Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) § 6).

---

## 4. Mapa da API

Superfície verificada em bun.com/docs. A coluna **Satélite** diz o que carregar, **e em que seção**.

**Esta tabela é índice de roteamento, não allow-list.** API ausente daqui significa "não verificada nesta doc" — consulte a fonte e atualize a nota. Ao acrescentar API a um satélite, acrescente a linha aqui.

### Execução, descoberta e configuração

| API / flag | Para que serve | Satélite |
| --- | --- | --- |
| `bun test` e os quatro padrões de nome | o que entra na suíte | [Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) § 2 |
| `root`, `pathIgnorePatterns` | recortar a suíte | [Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) § 2 |
| filtro posicional, `-t`/`--test-name-pattern` | rodar um subconjunto | [Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) § 3 |
| `--only`, `--todo` | ativar `test.only` / rodar os `test.todo` | [Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) § 3.3 |
| `--changed[=<ref>]` | só os testes que o diff alcança, por grafo de import | [Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) § 3.4 |
| `--watch`, `--hot`, `--inspect`, `--inspect-brk` | loop de desenvolvimento e depuração | [Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) § 4 |
| `--randomize`, `--seed`, `--rerun-each` | caçar dependência de ordem e flaky | [Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) § 4 |
| `--timeout`, `--bail`, `--retry`, `--smol` | comportamento de execução | [Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) § 4 |
| `bunfig.toml [test]` (17 chaves) | configuração persistente | [Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) § 5 |
| `NODE_ENV`, `TZ`, exit code | o ambiente que o runner impõe | [Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) § 6 |

### Escrita e asserção

| API | Para que serve | Satélite |
| --- | --- | --- |
| `test`, `it`, `describe` | estrutura do arquivo | [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) § 2 |
| terceiro argumento de timeout, `{ retry }`, `{ repeats }` | controle por teste | [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) § 3 |
| `test.skip`/`todo`/`failing`/`only`/`if`/`skipIf`/`todoIf` | modificadores, e o que cada um comunica | [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) § 4 |
| `test.each`, `describe.each`, `%p`/`%s`/`$prop` | tabela de casos | [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) § 5 |
| catálogo de matchers, e o que **não** está implementado | asserção | [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) § 6.1 |
| `toBe` × `toEqual` × `toStrictEqual` | escolher a igualdade certa | [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) § 6.2 |
| `.toThrow`, `.rejects`, `.resolves` | testar erro | [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) § 6.3 |
| `expect.assertions`, `expect.hasAssertions` | garantir que a asserção rodou | [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) § 7 |
| `expect.extend` | matcher próprio | [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) § 8.1 |
| `expectTypeOf` | expectativa de tipo (no-op em runtime) | [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) § 8.2 |
| `toMatchSnapshot`, `toMatchInlineSnapshot`, property matchers, `-u` | snapshots | [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) § 9 |

### Mocks e tempo

| API | Para que serve | Satélite |
| --- | --- | --- |
| `mock`, `jest.fn`, `vi.fn` | função observável | [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) § 2 |
| `spyOn(obj, "metodo")` | espiar (e opcionalmente substituir) | [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) § 2 |
| `.mock.calls`/`.results`/`.lastCall`, `mockReturnValueOnce`, `mockResolvedValue` | inspeção e roteiro de retorno | [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) § 2 |
| `mock.clearAllMocks`, `jest.resetAllMocks`, `mock.restore` | **as três limpezas, e o que cada uma não faz** | [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) § 3 |
| `mock.module(especificador, factory)` | mock de módulo — escopo de processo | [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) § 4 |
| `setSystemTime`, `jest.now` | congelar data | [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) § 5 |
| `useFakeTimers`, `advanceTimersByTime`, `runAllTimers`, `getTimerCount` | fazer o tempo passar | [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) § 5 |
| `TZ` / `process.env.TZ` em teste | fuso na asserção de data | [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) § 5 |
| objeto `vi` | superfície de compatibilidade Vitest | [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) § 6 |

### Ciclo de vida, isolamento e paralelismo

| API / flag | Para que serve | Satélite |
| --- | --- | --- |
| `beforeAll`, `beforeEach`, `afterEach`, `afterAll` | ciclo de vida, com escopo pelo lugar da declaração | [Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) § 2 |
| `onTestFinished` | cleanup registrado no ponto de uso | [Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) § 2 |
| `[test] preload` como escopo de execução | setup global — e o que muda sob isolação | [Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) § 3 |
| `--parallel`, `--isolate`, `--no-isolate` | isolamento e paralelismo entre arquivos | [Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) § 4 |
| `BUN_TEST_WORKER_ID`, `JEST_WORKER_ID` | recurso externo por worker | [Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) § 4 |
| `test.concurrent`, `test.serial`, `--concurrent`, `--max-concurrency`, `concurrentTestGlob` | concorrência dentro do arquivo | [Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) § 5 |
| `--shard=i/n`, `--timings`, `--update-timings` | dividir entre máquinas de CI | [Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) § 7 |

### DOM e componentes

| API | Para que serve | Satélite |
| --- | --- | --- |
| `GlobalRegistrator.register` (happy-dom) | injetar `document`/`window` | [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md) § 2 |
| `expect.extend(matchers)` de `jest-dom` | registrar `toBeInTheDocument` e afins | [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md) § 2 |
| `matchers.d.ts`, `/// <reference lib="dom" />` | tipos | [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md) § 2 |
| `cleanup` | limpar o `document` entre testes | [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md) § 2 |
| `userEvent`, `findBy*`, `waitFor`, `act` | interação e espera | [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md) § 3 |
| loaders, `import.meta.env`, `paths` no teste | o que o Vite fazia e aqui é outra coisa | [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md) § 4 |
| stubs de `ResizeObserver`, `matchMedia` | o que happy-dom não implementa | [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md) § 5 |

### Cobertura, reporters e CI

| API / flag | Para que serve | Satélite |
| --- | --- | --- |
| `--coverage`, `--coverage-reporter`, `coverageDir` | medir cobertura | [Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md) § 2 |
| `coverageThreshold` | **o portão — e as duas condições que o desligam em silêncio** | [Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md) § 3 |
| `--reporter=junit`, `--reporter-outfile`, `--dots` | formato de saída | [Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md) § 4 |
| anotações de GitHub Actions | falha na linha do PR, sem configuração | [Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md) § 4 |
| workflow com `--parallel`, `--shard`, `--changed` | receita de CI | [Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md) § 5 |

**Deliberadamente fora deste mapa:** reporter customizado via WebKit Inspector Protocol (mencionado em [Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md) § 4, sem detalhe), compatibilidade com `node:test`, e a lista completa de matchers de `expectTypeOf`. Existem na fonte; a ausência aqui significa **"não verificado nesta doc"**.

---

## 5. Árvores de decisão

### 5.1 "Passa sozinho, falha na suíte"

O sintoma mais comum, e o que tem mais causas distintas.

```
O teste passa isolado e falha junto com os outros?
├── Falha só quando outro arquivo roda antes
│ → estado no global compartilhado. Detecte: bun test --randomize
│ ├── É spy não restaurado? → mock.restore no preload — BUN-TEST-02
│ ├── É mock.module? → escopo de processo; registre no preload — BUN-TEST-03
│ └── É estado de módulo/fixture? → mover o setup para dentro do arquivo — BUN-TEST-09
│ (test.serial NÃO resolve: ele sequencia dentro do arquivo)
├── Falha só com --parallel
│ ├── Dois testes disputam banco/porta/diretório → derive de BUN_TEST_WORKER_ID — BUN-TEST-10
│ └── O preload sobe algo caro (servidor, migração) → hooks de preload envolvem CADA arquivo — BUN-TEST-24
├── Falha só quando outro teste do MESMO arquivo roda antes
│ ├── Há test.concurrent / --concurrent? → estado compartilhado entre concorrentes — BUN-TEST-23
│ └── Componente: o DOM tem resto do teste anterior → cleanup em afterEach — BUN-TEST-26
└── Falha de forma intermitente, sem padrão de ordem
 → bun test --rerun-each 20; suspeite de await faltando e de timer real
```

Detalhe em [Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) § 6.

### 5.2 "Preciso substituir uma dependência"

```
O código sob teste recebe a dependência de fora (parâmetro, construtor, contexto)?
├── SIM → passe um duplo. Sem mock, sem escopo global, sem restauração.
│ É a forma preferida. [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) § 4
└── NÃO
 ├── A dependência é método de um objeto que o teste tem em mãos?
 │ → spyOn(obj, "metodo") + mock.restore garantido — BUN-TEST-02
 └── É um módulo importado?
 ├── O import do original tem efeito colateral (conexão, listener, env)?
 │ → mock.module em [test] preload — BUN-TEST-04 (não há outra forma)
 └── Não tem efeito colateral?
 → mock.module serve, mas é escopo de PROCESSO — BUN-TEST-03
 Se três arquivos mockam o mesmo módulo, a dependência queria ser parâmetro.
```

### 5.3 "Preciso controlar o tempo"

```
Preciso de uma data fixa (new Date, Date.now, Intl)?
└── setSystemTime(new Date("…")) — NÃO é useFakeTimers — BUN-TEST-20

Preciso que o tempo PASSE (setTimeout, debounce, polling, retry com backoff)?
└── jest.useFakeTimers + jest.advanceTimersByTime(ms)

Preciso das duas coisas?
└── as duas combinam; setSystemTime funciona junto do avanço de timers

Vou asserir sobre data ou hora FORMATADA?
└── fixe o fuso: TZ=… no comando, ou process.env.TZ no teste — BUN-TEST-21
 (o Etc/UTC do runner só vale enquanto TZ não estiver no ambiente)

Estou tentado a usar sleep?
└── nunca. Em componente: findBy*/waitFor. Em timer: fake timers.
```

### 5.4 "Vim do Jest / do Vitest"

O código de teste quase sempre roda sem edição — imports de `vitest` e de `@jest/globals` são reescritos para `bun:test`, e o objeto `vi` existe. **O que não migra é a configuração**, porque ela vivia num arquivo que o Bun não lê.

| Vitest / Jest | Em `bun test` | Observação |
| --- | --- | --- |
| `setupFiles` / `setupFilesAfterEnv` / `test.setupFiles` | `[test] preload` | mesmo papel; o **escopo** difere sob `--parallel` — `BUN-TEST-24` |
| `globals: true` | não existe, e não precisa | globais já existem **e** são importáveis de `bun:test` |
| `environment: "jsdom"` / `"happy-dom"` | happy-dom via `GlobalRegistrator` no preload | não é chave de config; é código — `BUN-TEST-07` |
| `testEnvironment: "jsdom"` (Jest) | idem. **jsdom não é oferecido como alternativa suportada** | [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md) § 1 |
| `vi.mock("./mod", factory)` | `mock.module("./mod", factory)` (`vi.mock` existe) | **não assuma hoisting** — `BUN-TEST-04` |
| `vi.fn` / `vi.spyOn` | `mock` / `spyOn` — as formas `vi.*` também existem | |
| `vi.resetAllMocks` / `vi.restoreAllMocks` | ver a tabela das três limpezas | os escopos **não** coincidem com os do Vitest |
| `vi.useFakeTimers` | `jest.useFakeTimers` | o construtor `Date` **não** é trocado — `BUN-TEST-20` |
| `testTimeout` | `--timeout <ms>` (default `5000`) | vira flag, não config |
| `bail` | `--bail` | granularidade de **arquivo** |
| `coverage.*` | `[test] coverage*` | limiar é **fração** (`0.9`), e tem duas condições silenciosas — `BUN-TEST-27`, `BUN-TEST-28` |
| `testPathIgnorePatterns` / `test.exclude` | `[test] pathIgnorePatterns` | |
| `rootDir` / `test.root` | `[test] root` | |
| `transform`, `extensionsToTreatAsEsm`, `haste`, `watchman`, `verbose` | **não existem** | irrelevantes: TS e JSX são nativos |
| `resolve.alias` do `vite.config.ts` | **ignorado** | Bun lê `compilerOptions.paths` |
| `define` do `vite.config.ts` | `define` no topo do `bunfig.toml` | `import.meta.env.VITE_*` é caso à parte |
| plugins do Vite (SVGR, CSS Modules…) | **não existem** | é a lacuna real — [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md) § 4 |
| `/// <reference types="bun-types/test-globals" />` | opção para tipar os globais num arquivo do projeto | ou importar de `bun:test`, que é a forma preferida aqui |

### 5.5 "Como monto o comando de CI"

```
Suíte pequena (< ~2 min)?
└── bun test --parallel --coverage
 + passo separado de tsc --noEmit — BUN-TEST-18

Suíte grande?
└── matriz de --shard=i/n, com --timings cacheado entre execuções
 (sem o cache, a divisão volta a ser por contagem de arquivos)

Quer feedback rápido no PR?
└── job extra com --changed=origin/<base>
 NUNCA como portão de merge: o grafo de import não vê env, migração nem fixture

Precisa de relatório para o CI (GitLab, Jenkins)?
└── --reporter=junit --reporter-outfile=./junit.xml — BUN-TEST-29
 No GitHub Actions, as anotações saem sem configuração nenhuma

Vai ligar limiar de cobertura?
└── mantenha "text" nos reporters — BUN-TEST-27
 e não confie em "statements" — BUN-TEST-28
```

Receita completa em [Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md) § 5.

### 5.6 "O teste de componente não funciona"

```
"document is not defined"
└── falta o preload de happy-dom — BUN-TEST-07

"toBeInTheDocument is not a function"
└── falta expect.extend(matchers) — BUN-TEST-12
 (import "@testing-library/jest-dom" sozinho NÃO registra nada)

"Cannot find name 'document'" (só no tsc)
└── /// <reference lib="dom" /> no topo do arquivo

"screen.getByRole found multiple elements"
└── falta cleanup em afterEach — BUN-TEST-26

A asserção roda antes do re-render
└── await no userEvent; e prefira findBy* a waitFor + getBy*

O componente importa SVG/CSS/import.meta.env e quebra
└── é a fronteira com o Vite — [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md) § 4
 A saída que dispensa a lista: componente puro, configuração por prop

Depende de tamanho, layout ou rolagem
└── happy-dom não mede. Teste de browser — [Storybook - Testes e Interações](storybook-testes-e-interacoes.md)
```

---

## 6. Regras normativas

Regras citáveis por ID. Uma skill, um prompt de revisão ou um comentário de PR pode referenciar `BUN-TEST-27` sem repetir o texto. **São 29 regras** — a família `BUN-TEST-*` inteira, distribuída assim: Execução 4 · Escrita 8 · Mocks 5 · Ciclo de vida 5 · DOM 4 · Cobertura 3.

**Convenção:** `MUST` / `NEVER` são normativos. Violação é bug, não questão de estilo.
**Marcação de origem:** regra sem marca vem de afirmação explícita da fonte. Regra marcada **†** é decisão desta doc — coerente com a fonte, mas não ditada por ela. Uma revisão pode discutir uma regra †; não pode discutir as outras sem ir à fonte.

> **O satélite é canônico.** As linhas abaixo reproduzem o texto do satélite **verbatim**. Em qualquer divergência, o satélite vence e esta tabela é o bug — a § 7 manda citar por ID sem parafrasear, e duas cópias divergentes de uma regra normativa inviabilizam isso.

### `01`, `13`–`15` — execução e configuração · [Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md)

| ID | Regra |
| --- | --- |
| `BUN-TEST-01` | Arquivo de teste **MUST** casar um dos padrões de descoberta (`*.test.*`, `*_test.*`, `*.spec.*`, `*_spec.*`) — arquivo fora do padrão não roda e não gera aviso. |
| `BUN-TEST-13` | Filtro posicional que aponta um **arquivo** **MUST** começar com `./` ou `/` — sem o prefixo é filtro por substring de caminho, e glob **NEVER** é aceito. |
| `BUN-TEST-14` | `seed` no `bunfig.toml` **MUST** vir acompanhado de `randomize = true` — sem isso não tem efeito, e a falha é silenciosa. |
| `BUN-TEST-15` | Pipeline de CI **MUST** pinar a versão do Bun (`oven-sh/setup-bun` com `bun-version` fixo, ou imagem com tag) — flags e defaults do runner mudam entre minors, e `latest` transforma isso em falha sem commit. † |

### `05`, `06`, `08`, `11`, `16`–`19` — escrita e asserções · [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md)

| ID | Regra |
| --- | --- |
| `BUN-TEST-05` | `--update-snapshots` (`-u`) **NEVER** aparece no comando de teste do CI, e o diretório `__snapshots__/` **MUST** estar versionado — snapshot fora do repositório não é asserção. |
| `BUN-TEST-06` | Teste cuja asserção vive em `catch`, callback ou branch condicional **MUST** declarar `expect.assertions(n)` ou `expect.hasAssertions`. |
| `BUN-TEST-08` | `test.only` **NEVER** é usado como forma de desabilitar os demais testes — sem `bun test --only` ele não filtra nada. |
| `BUN-TEST-11` | Teste que documenta bug conhecido **MUST** usar `test.failing`, **NEVER** `test.skip` — `failing` avisa quando o bug é corrigido. |
| `BUN-TEST-16` | `retry` e `repeats` **NEVER** coexistem no mesmo teste — a fonte declara a combinação inválida. |
| `BUN-TEST-17` | Teste assíncrono **MUST** usar `async`/`await`. O parâmetro `done` **NEVER** em código novo — se declarado e não chamado, o teste pendura até o timeout e falha por motivo errado. † |
| `BUN-TEST-18` | `expectTypeOf` **NEVER** conta como verificação executada — é no-op em runtime, e o CI **MUST** rodar `tsc --noEmit` num passo separado. |
| `BUN-TEST-19` | Snapshot de objeto com campo não determinístico (id gerado, data, hash) **MUST** declarar property matchers (`{ id: expect.any(String) }`) — sem isso o snapshot falha sempre e o time passa a rodar `-u` por reflexo. † |

### `02`–`04`, `20`, `21` — mocks e tempo · [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md)

| ID | Regra |
| --- | --- |
| `BUN-TEST-02` | `spyOn` **MUST** ter restauração garantida (`mock.restore` em `afterEach` ou no preload) — sem isso o spy vaza para os testes seguintes. |
| `BUN-TEST-03` | `mock.module` **NEVER** é desfeito por `mock.restore`; mock de módulo **MUST** ser registrado em `--preload` ou tratado como estado global do processo de teste. |
| `BUN-TEST-04` | Mock cujo objetivo é impedir efeito colateral de import (conexão, listener, leitura de env no topo) **MUST** ser registrado em `--preload` — mockar depois do import não desfaz o que já rodou. |
| `BUN-TEST-20` | Congelar data **MUST** usar `setSystemTime` — `useFakeTimers` não troca o construtor `Date` em `bun:test`, ao contrário do Jest. |
| `BUN-TEST-21` | Asserção sobre data ou hora **formatada** **MUST** fixar o fuso explicitamente (`TZ` no comando, ou `process.env.TZ` no teste) — o `Etc/UTC` do runner só vale enquanto `TZ` não estiver definida no ambiente. † |

### `09`, `10`, `22`–`24` — ciclo de vida e isolamento · [Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md)

| ID | Regra |
| --- | --- |
| `BUN-TEST-09` | Teste que depende de estado deixado por **outro arquivo** **MUST** ser corrigido movendo o setup para dentro do próprio arquivo — `test.serial` **NEVER** resolve isso (ele sequencia dentro do arquivo) e nenhuma flag restaura o global compartilhado sob `--isolate`; a detecção é `bun test --randomize`. |
| `BUN-TEST-10` | Teste que usa recurso externo compartilhado (banco, porta, diretório) **MUST** derivá-lo de `BUN_TEST_WORKER_ID` quando a suíte roda com `--parallel`. |
| `BUN-TEST-22` | `onTestFinished` **NEVER** em teste concorrente — a fonte declara que não é suportado; use `test.serial`. |
| `BUN-TEST-23` | Teste marcado `concurrent` (ou suíte sob `--concurrent`) **NEVER** compartilha estado mutável com outro teste do mesmo arquivo — quem depende de ordem ou de estado compartilhado **MUST** ser `test.serial`. † |
| `BUN-TEST-24` | Setup declarado em `preload` **MUST** ser idempotente e barato, ou parametrizado por worker — sob `--parallel`/`--isolate` os hooks de nível de preload envolvem **cada arquivo**, não a execução. |

### `07`, `12`, `25`, `26` — DOM e componentes · [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md)

| ID | Regra |
| --- | --- |
| `BUN-TEST-07` | Registro de DOM (`GlobalRegistrator.register`) **MUST** acontecer em `[test] preload`, **NEVER** dentro de um arquivo de teste. |
| `BUN-TEST-12` | Matcher de `@testing-library/jest-dom` **MUST** ser registrado com `expect.extend` num preload — o `import` do pacote sozinho não registra nada em `bun:test`. |
| `BUN-TEST-25` | `GlobalRegistrator.register` e os pacotes `@testing-library/*` **MUST** viver em preloads separados, nesta ordem — num arquivo único, os pacotes **MUST** ser carregados por `await import` depois do registro. |
| `BUN-TEST-26` | Arquivo que renderiza componente **MUST** ter `cleanup` em `afterEach` (de preferência no preload) — o `document` é compartilhado entre os testes do arquivo. |

### `27`–`29` — cobertura e CI · [Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md)

| ID | Regra |
| --- | --- |
| `BUN-TEST-27` | `coverageThreshold` **MUST** vir acompanhado do reporter `text` habilitado em toda execução fora de `--parallel` — com apenas `--coverage-reporter=lcov` o processo sai `0` mesmo abaixo do limiar. |
| `BUN-TEST-28` | `coverageThreshold` **NEVER** depende da chave `statements` — ela é aceita e **não** é aplicada; o portão real é `lines` e `functions`. |
| `BUN-TEST-29` | `--reporter=junit` **MUST** vir acompanhado de `--reporter-outfile` — a fonte declara o par obrigatório. |

### 6.1 O caminho mínimo

Estas sete **viajam com qualquer tarefa de teste**, mesmo quando o satélite correspondente não foi carregado. Critério de entrada: a violação é **silenciosa** — não há erro em dev, e o teste fica verde.

| ID | Por que é silenciosa |
| --- | --- |
| `BUN-TEST-02` | o spy vaza e o defeito aparece em outro arquivo, horas depois |
| `BUN-TEST-03` | o módulo continua mockado no resto do processo, sem aviso |
| `BUN-TEST-05` | o snapshot passa a registrar a regressão em vez de pegá-la |
| `BUN-TEST-06` | o teste passa **sem executar asserção nenhuma** |
| `BUN-TEST-09` | a suíte passa na ordem de hoje e quebra na de amanhã |
| `BUN-TEST-27` | o portão de cobertura sai `0` abaixo do limiar |
| `BUN-TEST-28` | o limiar declarado não existe |

---

## 7. Contrato de skill

Como uma skill de teste em Bun deve consumir esta doc.

### O que carregar

```
SEMPRE: Docs/Bun - Testes.md § 2 (modelo mental)
 Docs/Bun - Testes.md § 3 (fronteiras de import)
 Docs/Bun - Testes.md § 6.1 (o caminho mínimo)

AO ESCREVER teste novo:
 Docs/Bun - Testes - Escrita e Asserções.md

AO SUBSTITUIR dependência (mock, spy, duplo) ou controlar tempo:
 Docs/Bun - Testes - Mocks e Tempo.md + § 5.2 / § 5.3

AO DIAGNOSTICAR "passa sozinho, falha na suíte" ou flaky:
 § 5.1 + Docs/Bun - Testes - Ciclo de Vida e Isolamento.md

AO TESTAR componente React:
 Docs/Bun - Testes - DOM e Componentes.md

AO MEXER em CI, cobertura ou reporter:
 Docs/Bun - Testes - Cobertura e CI.md

AO CONFIGURAR o projeto do zero:
 Docs/Bun - Testes - Execução e Configuração.md § 5
 + Docs/Bun - Testes - DOM e Componentes.md § 2 (se houver componente)

NUNCA: os seis satélites de uma vez
 inventar flag, chave de bunfig ou assinatura de matcher
 — o que não estiver na § 4 MUST ser conferido em bun.com/docs
```

Três recortes prontos, para as tarefas mais frequentes:

| Tarefa | Carregar |
| --- | --- |
| "escreva testes para este módulo" | § 2 + § 6.1 + Escrita e Asserções |
| "este teste está flaky" | § 5.1 + Ciclo de Vida e Isolamento |
| "configure teste neste projeto" | § 3 + Execução e Configuração § 5 + (DOM § 2 se houver componente) |

### Como citar

Achados de revisão citam o ID e o satélite, e não parafraseiam:

> `BUN-TEST-27` — `coverageThreshold` declarado com `coverageReporter = ["lcov"]`. Fora de `--parallel`, o limiar não é checado e o job sai `0` abaixo do número.
> Ver [Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md).

### Invariantes que a skill deve fazer valer

1. **Asserção que pode não rodar precisa de contagem.** Todo `expect` dentro de `catch`, callback ou `if` vem com `expect.assertions(n)` (`BUN-TEST-06`). É a invariante que mais pega código gerado.
2. **Todo `spyOn` tem restauração garantida**, e a garantia mora no preload, não no arquivo (`BUN-TEST-02`).
3. **Mock de módulo é estado de processo.** Se a skill escreve `mock.module`, ela decidiu por um efeito que dura a execução inteira — e isso precisa ser intencional (`BUN-TEST-03`, `BUN-TEST-04`).
4. **Nada de `sleep`.** Espera é `findBy*`, `waitFor` ou fake timers. `Bun.sleep` num teste é achado.
5. **Type checking é passo separado.** Nenhuma entrega está verificada sem `tsc --noEmit` (`BUN-TEST-18`).
6. **Verificar antes de afirmar.** Flag, chave de `bunfig.toml` ou matcher que não está na § 4 não foi verificado nesta doc: consulte bun.com/docs e **atualize a nota**.
7. **Confirmar a versão.** `bun --version` antes de assumir que uma flag existe; a doc já esteve à frente do binário publicado (ver [Fontes consultadas](#fontes-consultadas)).

### Ao criar uma nova skill

Derive-a de **um** satélite, não desta nota inteira: uma skill de teste de componente carrega [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md) + § 2 + § 6.1, e nada mais. Registre no início da skill qual satélite é sua fonte, para que a atualização da doc propague. É o mesmo contrato de [Bun](bun.md) § 7 e [React.js](react-js.md) § 7.

---

## 8. Pontes com o stack

| Fronteira | Onde a decisão vive |
| --- | --- |
| **O que testar, e se vale testar** | — o runner não decide isso, e esta doc não tenta |
| **Integração externa: mock, duplo ou serviço real** | — a § 5.2 escolhe o *mecanismo*, não a *estratégia* |
| **O que asseverar num componente** | — DOM disponível não implica testar implementação |
| **Componente em browser real** | [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) — o addon-vitest roda em Playwright e **não** roda sob `bun test`; o monorepo fica com dois runners por desenho |
| **Servidor HTTP sob teste** | [Bun - HTTP e Servidor](bun-http-e-servidor.md) — `Bun.serve` em `beforeAll`, `server.stop` em `afterAll`, porta por worker (`BUN-TEST-10`) |
| **Banco em teste** | [Bun - Dados e Persistência](bun-dados-e-persistencia.md) — `bun:sqlite` em memória para unidade; banco por worker para integração |
| **Instalação e pin de versão em CI** | [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) — `bun ci`, lockfile versionado |
| **Handler de rota tipado sob teste** | [Hono - Validação e RPC](hono-validacao-e-rpc.md) · [Elysia - Schema e Eden](elysia-schema-e-eden.md) — `app.request` / Eden dispensam subir servidor |
| **Mutation e cache no frontend** | [TanStack Query - Mutations e Invalidação](tanstack-query-mutations-e-invalidacao.md) — `QueryClient` novo por teste, `retry: false` |
| **Trunk-based e portão de teste** | |

---

## Relacionados

- [Bun](bun.md) — hub do runtime; esta estrutura é a família `BUN-TEST-*` dele
- [Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) · [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) · [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) · [Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) · [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md) · [Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md)
- [Bun - Runtime e APIs](bun-runtime-e-apis.md) · [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) · [Bun - HTTP e Servidor](bun-http-e-servidor.md) · [Bun - Dados e Persistência](bun-dados-e-persistencia.md)
- · ·
- [Storybook - Testes e Interações](storybook-testes-e-interacoes.md) · [React.js](react-js.md) · `TypeScript` · [Github Actions](github-actions.md)

## Fontes consultadas

Verificadas em **2026-08-20**, contra `bun` **1.4.0** (`npm view bun dist-tags` → `latest: 1.4.0`):

- [Test runner](https://bun.com/docs/test) · [Writing tests](https://bun.com/docs/test/writing-tests) · [Test configuration](https://bun.com/docs/test/configuration)
- [Runtime behavior](https://bun.com/docs/test/runtime-behavior) · [Finding tests](https://bun.com/docs/test/discovery) · [Parallel & isolated test runs](https://bun.com/docs/test/parallel)
- [Lifecycle hooks](https://bun.com/docs/test/lifecycle) · [Mocks](https://bun.com/docs/test/mocks) · [Snapshots](https://bun.com/docs/test/snapshots) · [Dates and times](https://bun.com/docs/test/dates-times)
- [DOM testing](https://bun.com/docs/test/dom) · [Code coverage](https://bun.com/docs/test/code-coverage) · [Test Reporters](https://bun.com/docs/test/reporters)
- [Using Testing Library with Bun](https://bun.com/docs/guides/test/testing-library) · [Migrate from Jest](https://bun.com/docs/guides/test/migrate-from-jest)
- Referência de API: [`jest` object](https://bun.com/reference/bun/test/jest) · [`vi`](https://bun.com/reference/bun/test/vi) · [`useFakeTimers`](https://bun.com/reference/bun/test/jest/useFakeTimers) · [`advanceTimersByTime`](https://bun.com/reference/bun/test/jest/advanceTimersByTime) · [`Test.only`](https://bun.com/reference/bun/test/Test/only)
- [Bun 1.4](https://bun.com/blog/bun-v1.4) e [Bun v1.3.6](https://bun.com/blog/bun-v1.3.6) — `--parallel`, `--isolate`, `--shard`, `--timings`, `--changed`, fake timers
- [Jest compatibility tracking issue](https://github.com/oven-sh/bun/issues/1825) — citada pela própria doc como referência de estado

### O que a verificação contrariou

- **O default é um único global compartilhado por todos os arquivos**, num processo só. Isolamento por arquivo só existe com `--isolate` (implícito em `--parallel`). É o oposto do que Jest e Vitest treinam a esperar.
- **`coverageThreshold` tem duas condições silenciosas que ninguém supõe:** a chave `statements` é **aceita e não aplicada**, e **fora de `--parallel` a checagem só roda com o reporter `text` habilitado** — execuções com apenas `--coverage-reporter=lcov` saem `0` independentemente do número. Um projeto pode ter portão de cobertura que nunca fechou.
- **`mock.restore` não desfaz `mock.module`.** Está escrito na fonte, e é a diferença de escopo mais fácil de violar da API.
- **As três limpezas fazem coisas diferentes:** `clearAllMocks` preserva a implementação, `resetAllMocks` a remove mas não restaura o original do spy, só `restore` restaura.
- **`useFakeTimers` não troca o construtor `Date`** em `bun:test` — a fonte diz que é para evitar o bug de `Date !== Date` do Jest. Congelar data é `setSystemTime`.
- **`test.only` exige `bun test --only`.** E aqui as páginas da fonte divergem: a referência de API descreve `only` como já pulando os demais testes; a página de escrita de testes mostra a flag como o gatilho.
- **`test.todo` que passa é reportado como falha** sob `--todo`, para forçar a remoção da marca.
- **`--shard` é descrito de duas formas na própria fonte:** fatia contígua por caminho (página de paralelismo) e round-robin determinístico (post de release da 1.4). Não dependa de localidade.
- **Filtro posicional não aceita glob**, e caminho de arquivo precisa começar com `./` ou `/`.
- **`-t` casa contra o nome prefixado pelos rótulos dos `describe`**, separados por espaço — o texto do `describe` é endereço.
- **`seed` no `bunfig.toml` não faz nada sem `randomize = true`.**
- **`bun test` define `TZ=Etc/UTC`** salvo override, e `NODE_ENV=test` salvo se já definida.
- **Erro não tratado fora de qualquer teste faz o processo sair `1`**, mesmo com todos os testes verdes.
- **Timeout lança exceção não capturável e mata os processos filhos** criados pelo teste com `Bun.spawn`, `Bun.spawnSync` ou `node:child_process`.
- **`beforeAll` que lança pula todos os testes do escopo** — a falha chega disfarçada de "skip", não de erro.
- **`repeats: N` roda N+1 vezes**, e `retry` com `repeats` é combinação inválida.
- **Se o teste declara `done`, ele precisa chamá-lo — ou pendura** até o timeout.
- **`expect.addSnapshotSerializer` não está implementado.** Serializador customizado de snapshot não existe.
- **`expectTypeOf` é no-op em runtime.** A verificação exige `tsc` num passo separado.
- **`onTestFinished` não funciona em teste concorrente.**
- **`--isolate` reexecuta os scripts de preload a cada arquivo**, além de criar `globalThis` novo, limpar os registros de módulo, fechar servidores/sockets/watchers/subprocessos e cancelar timers.
- **Hooks de nível de preload envolvem cada arquivo sob `--parallel`** — "uma vez por execução" deixa de valer exatamente onde mais dói.
- **`import "@testing-library/jest-dom"` não basta**, e as duas páginas da fonte divergem: a página de DOM mostra o import simples, o guia de Testing Library usa `expect.extend(matchers)`. A que funciona é a do guia.
- **A ordem dos preloads importa:** `@testing-library/*` precisa ser avaliado depois de `GlobalRegistrator.register`.
- **No runtime, `import logo from "./logo.svg"` resolve para o caminho absoluto em disco**, não para uma URL como no Vite.
- **jsdom não é oferecido como alternativa.** happy-dom é o caminho documentado.
- **Imports de `vitest` e de `@jest/globals` são reescritos para `bun:test`.** Muito teste de Vitest roda sem edição; o que não migra é a configuração.
- **`--reporter=junit` exige `--reporter-outfile`**, e o XML não inclui stdout/stderr por teste nem timestamp preciso por caso.
- **No GitHub Actions, as anotações saem sem configuração nenhuma.**

### O que mudou desde a verificação anterior (2026-08-15)

- **A divergência doc × binário está resolvida.** Em 2026-08-15, a página de `--parallel` mostrava saída rotulada `bun test v1.4.0` enquanto o `latest` do npm era 1.3.14; hoje `latest` **é** 1.4.0. As flags `--parallel`, `--isolate`, `--shard` e `--timings` estão no binário publicado. O aviso operacional some; a regra de **pinar a versão** fica (`BUN-TEST-15`), porque foi ela que absorveu a lição.
- **`--changed` entrou no mapa** (filtro por grafo de import, introduzido na 1.4) — e com ele a fronteira entre job de PR e portão de merge.
- **As duas condições silenciosas do `coverageThreshold`** não estavam registradas: a nota anterior tratava `statements` como métrica válida e o limiar como portão incondicional. As duas afirmações estavam erradas.
- **A estrutura passou de uma nota de 717 linhas para hub + seis satélites**, e a família `BUN-TEST-*` foi de 12 para 29 regras. Os IDs `01`–`12` **mantêm texto e significado**: citações antigas continuam válidas, e a § 6 diz qual satélite é dono de cada um.

### O que não foi verificado (declarado, não inventado)

- **`import "./Botao.css"` e CSS Modules sob `bun test`**: a fonte documenta `css` como loader e o comportamento no bundler, e não declara o comportamento no runtime. [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md) § 4 dá a sonda e a saída.
- **`IntersectionObserver` no happy-dom**: a fonte stuba `ResizeObserver` e `matchMedia` e não menciona este.
- **Idempotência e custo de `GlobalRegistrator.register` sob reexecução por arquivo**: é comportamento do happy-dom, não declarado pela doc do Bun. Meça antes de assumir que `--parallel` acelera uma suíte de DOM.
- **Hoisting de `mock.module`/`vi.mock`**: a fonte não declara que sejam içados como no Vitest. Trate como não içados.
- **Detalhe do protocolo de reporter customizado** (domínios `TestReporter` e `LifecycleReporter`): existe, e não foi explorado aqui.
- **`--only` não aparece na lista de flags da CLI** que a fonte publica, embora a página de escrita de testes o use. Comportamento tratado como verificado pela prosa; a listagem, como incompleta.
