---
Link: https://bun.com/docs/test
tags:
 - bun
 - testing
 - agent-context
source: "Documentação oficial — https://bun.com/docs/test (test runner), /discovery, /configuration, /runtime-behavior"
verificado-em: 2026-08-20
---

# Bun - Testes - Execução e Configuração

> Como o runner **encontra** o arquivo, **filtra** o que roda e **de onde tira** configuração · descoberta e exclusões · filtro posicional × `-t` × `--only` × `--todo` × `--changed` · `bunfig.toml [test]` chave por chave · o ambiente que o runner impõe (`NODE_ENV`, `TZ`, exit code) · watch, hot, inspect, randomize, bail, retry, timeout.
>
> **Não cobre:** o que escrever dentro do arquivo ([Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md)) · isolamento, `--parallel`, `--shard` ([Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md)) · cobertura e reporters ([Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md)) · flags gerais do runtime fora de teste ([Bun - Runtime e APIs](bun-runtime-e-apis.md)).

Entrada: [Bun - Testes](bun-testes.md) · Base normativa: [Bun - Testes](bun-testes.md) § 6 · Família: `BUN-TEST-*` (esta nota é dona de `01`, `13`, `14`, `15`)

---

## 1. Conceito: o runner é um modo do runtime, não uma ferramenta separada

`bun test` não é um binário nem um pacote: é o mesmo runtime que executa `bun./index.ts`, ligado num modo que descobre arquivos, injeta globais de teste e reporta resultado. Três consequências práticas caem daí, e elas explicam quase toda diferença em relação a Jest e Vitest:

1. **Não há etapa de transformação para configurar.** TypeScript, JSX, `paths` do `tsconfig.json`, `.env` — tudo que o runtime já resolve, o runner resolve igual. `ts-jest`, `babel-jest`, `@swc/jest` e o bloco `transform` não têm equivalente porque não têm função ([Bun - Runtime e APIs](bun-runtime-e-apis.md) § 1).
2. **Configuração de teste mora onde mora a do runtime**: `bunfig.toml`, não um `jest.config.js` paralelo. E o que o runner lê é a seção `[test]` — mais as chaves de topo (`define`, `loader`), que valem para qualquer execução.
3. **O que o runtime não resolve, o runner também não.** Plugin de Vite, `resolve.alias` do `vite.config.ts`, transformação de SVG em componente: nada disso existe aqui, porque nada disso existia no runtime ([Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md) § 4).

A decisão que sobra para você é **o recorte**: quais arquivos entram, quais rodam nesta invocação, e qual ambiente eles enxergam. É o assunto desta nota.

---

## 2. Descoberta: o que entra na suíte

`bun test` varre o diretório de trabalho recursivamente atrás de quatro padrões:

- `*.test.{js|jsx|ts|tsx|mjs|cjs|mts|cts}`
- `*_test.{…}`
- `*.spec.{…}`
- `*_spec.{…}`

E exclui, sem você pedir: `node_modules`, diretórios ocultos (começando com `.`) e arquivos que não sejam JavaScript/TypeScript.

**Arquivo fora do padrão não roda e não avisa.** É o modo de falha mais barato de evitar e o mais irritante de descobrir: `pedidos.tests.ts` (plural), `testePedidos.ts`, `pedidos-test.ts` (hífen) — nenhum casa. A suíte fica verde porque o arquivo nunca existiu para o runner.

Dois cortes de escopo, e a diferença entre eles importa:

| Opção | Onde | O que faz |
| --- | --- | --- |
| `root` | `bunfig.toml` | limita **onde o runner varre**. Fora dessa raiz, o arquivo não é nem considerado |
| `pathIgnorePatterns` | `bunfig.toml` (`--path-ignore-patterns` na CLI) | remove da descoberta caminhos que casariam, por glob |

```toml
[test]
root = "src"
pathIgnorePatterns = ["**/fixtures/**", "**/*.e2e.test.ts"]
```

`root` é o corte estrutural (monorepo, pacote); `pathIgnorePatterns` é o corte por categoria (fixtures que parecem teste, suíte e2e que roda em outro job). Usar `pathIgnorePatterns` para excluir uma pasta inteira funciona, mas esconde a intenção — se a suíte só vive em `src`, declare `root`.

| ID | Regra |
| --- | --- |
| `BUN-TEST-01` | Arquivo de teste **MUST** casar um dos padrões de descoberta (`*.test.*`, `*_test.*`, `*.spec.*`, `*_spec.*`) — arquivo fora do padrão não roda e não gera aviso. |

---

## 3. Filtros: o que roda nesta invocação

Cinco mecanismos independentes, e eles se combinam.

```bash
bun test # tudo que a descoberta encontrou
bun test pedidos api # filtro por SUBSTRING de caminho
bun test./src/pedidos.test.ts # arquivo específico — o./ é obrigatório
bun test -t "calcula frete" # filtro por NOME do teste (regex)
bun test --only # só o que está marcado test.only/describe.only
bun test --todo # inclui os test.todo na execução
bun test --changed # só arquivos alcançados pelo que mudou no git
```

### 3.1 Posicional: substring de caminho, não glob

O argumento posicional casa **trecho de caminho**. `bun test utils` roda `src/utils/string.test.ts` e `lib/utils/array_test.js`. Glob **não** é suportado: `bun test "src/**/*.test.ts"` não faz o que parece.

Para apontar um arquivo, o caminho precisa começar com `./` ou `/`. Sem o prefixo, `pedidos.test.ts` é lido como substring — o que, por coincidência, costuma funcionar, e é justamente por isso que a regra passa desapercebida até o dia em que dois arquivos casam.

### 3.2 `-t`: regex contra o nome completo

`-t` / `--test-name-pattern` casa contra o nome do teste **prefixado pelos rótulos dos `describe` que o contêm**, separados por espaço. Um `test("soma corretamente")` dentro de `describe("Operações de matemática")` é alcançado por `-t "Operações de matemática soma"` — e também por `-t "soma"`, porque é regex parcial.

Consequência de desenho: **o texto do `describe` é endereço**. Renomear um `describe` quebra o filtro de quem depurava aquele bloco, e um `describe` genérico (`"testes"`, `"unit"`) não ajuda ninguém a filtrar nada.

### 3.3 `--only` e `--todo`: os dois filtros que invertem o hábito

- **`test.only` só tem efeito com `bun test --only`.** No Jest, um `.only` esquecido silencia o resto do arquivo. Aqui, ele não filtra nada sem a flag — e o efeito prático se inverte: o `.only` esquecido não quebra o CI, mas também não fez o que o autor achou que fez. E se alguém acrescentar `--only` ao comando do CI, a suíte inteira desaparece de uma vez.
- **`test.todo` não roda por padrão.** Com `bun test --todo`, os todos executam, falha de todo **não** é erro, e todo que **passa** é marcado como falha — para forçar a remoção da marca ou o conserto do teste.

> **Divergência entre páginas da fonte, registrada.** A referência de API descreve `only` como *"Skips all other tests, except this test"*, enquanto a página de escrita de testes mostra `bun test --only` como o comando que roda só os marcados. As duas afirmações não coincidem. Esta nota segue a página de escrita de testes — a flag é o gatilho — e a consequência operacional (`BUN-TEST-08`) é a mesma nos dois lados: não commitar `.only`.

### 3.4 `--changed`: filtro por grafo de import

`bun test --changed` roda apenas os arquivos de teste cujo **grafo de import alcança** um arquivo que o git reporta como modificado. `--changed=main` ou `--changed=HEAD~1` compara contra um branch, tag ou commit em vez do working tree.

```bash
bun test --changed --watch # loop de desenvolvimento: só o que seu diff afeta
bun test --changed=main # pré-commit / job rápido de PR
```

É o filtro que substitui convenção de nome e configuração manual: editar um utilitário profundo e rodar `bun test --changed` traz os testes que dependem dele transitivamente, sem você saber quais são.

**O que ele não é:** portão de merge. Um teste pode quebrar por mudança que o grafo de import não vê — variável de ambiente, migração de banco, fixture, ordem de execução. `--changed` acelera o loop e o job de PR; a suíte inteira continua sendo o que autoriza o merge (`BUN-TEST-15`, e a receita em [Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md) § 5).

---

## 4. Modos de execução e flags de comportamento

```bash
bun test --watch # reexecuta ao salvar
bun test --hot # preserva estado entre execuções, mais agressivo
bun test --timeout 10000 # por teste; default 5000
bun test --bail # para na primeira falha (default 1)
bun test --bail=5 # para na quinta
bun test --retry 2 # repete o que falhou; { retry: N } por teste sobrepõe
bun test --rerun-each 10 # roda cada arquivo 10 vezes — caça flaky
bun test --randomize # ordem aleatória
bun test --randomize --seed 42 # reproduz a ordem que revelou a falha
bun test --inspect # abre o inspector; --inspect-brk pausa no início
bun test --smol # reduz uso de memória
```

Calibração de uso — a diferença entre a flag existir e ela servir para algo:

| Sintoma | Flag | Por que essa |
| --- | --- | --- |
| "passa sozinho, falha na suíte" | `--randomize`, depois `--seed <n>` | expõe dependência de ordem e a torna reproduzível |
| "falha uma vez a cada vinte execuções" | `--rerun-each 20` | repete o arquivo até a falha aparecer, sem depender do CI |
| CI lento e a primeira falha já decide | `--bail` | não gasta minutos em arquivos que não vão mudar o resultado |
| teste de rede legitimamente instável | `{ retry: N }` **no teste**, não `--retry` global | `--retry` global esconde flakiness real do resto da suíte |
| depurar um teste específico | `-t "nome"` + `--inspect-brk` | não requer editar o arquivo, e não deixa `.only` para trás |

**`--retry` global é anestesia.** Ele existe, e transforma "às vezes falha" em "quase sempre passa" — inclusive para o teste que estava certo em falhar. Retry pertence ao teste que tem motivo declarado para ser instável (chamada de rede real, relógio, concorrência externa), e não ao comando.

`--watch` e `--hot` têm a mesma diferença que fora de teste: `--watch` reinicia o processo, `--hot` tenta preservar estado. Para teste, `--watch` é o default sensato — estado preservado entre execuções é exatamente o que uma suíte não quer ([Bun - Runtime e APIs](bun-runtime-e-apis.md) § 6).

---

## 5. `bunfig.toml [test]` — a superfície completa

Tudo abaixo foi verificado na página de configuração. Onde a fonte declara default, ele está na coluna.

| Chave | Default | O que faz |
| --- | --- | --- |
| `root` | raiz do projeto | diretório que o runner varre |
| `preload` | — | scripts carregados antes dos testes (array) |
| `pathIgnorePatterns` | — | exclui caminhos da descoberta, por glob |
| `smol` | `false` | modo de menor uso de memória |
| `concurrentTestGlob` | — | arquivos que casam o glob rodam com execução concorrente ligada |
| `randomize` | `false` | ordem aleatória de execução |
| `seed` | — | semente para ordem reproduzível — **exige `randomize = true`** |
| `retry` | `0` | retry default para todos os testes |
| `rerunEach` | — | reexecuta cada arquivo N vezes |
| `coverage` | `false` | liga cobertura por default |
| `coverageReporter` | `["text"]` | formatos de relatório |
| `coverageDir` | `"coverage"` | diretório de saída |
| `coverageSkipTestFiles` | `true` | exclui os próprios arquivos de teste do relatório |
| `coverageThreshold` | — | limiar de cobertura (fração `0.0`–`1.0`) — ver [Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md) § 3 |
| `coveragePathIgnorePatterns` | — | exclui caminhos do cálculo de cobertura |
| `coverageIgnoreSourcemaps` | `false` | ignora sourcemaps no cálculo — caso avançado |
| `[test.reporter] junit` | — | caminho do XML JUnit ([Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md) § 4) |

```toml
# bunfig.toml
[test]
root = "src"
preload = ["./test/happydom.ts", "./test/setup.ts"]
pathIgnorePatterns = ["**/fixtures/**"]
coverage = true
coverageReporter = ["text", "lcov"]
coverageThreshold = { lines = 0.85, functions = 0.85 }

# fora de [test]: valem para qualquer execução do runtime
loader = { ".css" = "text" }
define = { "process.env.FEATURE_X" = "\"off\"" }
```

> **Uma chave a mais, não verificada.** [Bun - Runtime e APIs](bun-runtime-e-apis.md) § 5 registra também `onlyFailures` em `[test]`, verificada em 2026-08-15. A página de configuração consultada em 2026-08-20 **não a lista**, e a listagem de flags da CLI também não traz `--only-failures`. A chave provavelmente existe (há trabalho publicado sobre a flag); o que não existe é declaração da fonte que eu tenha visto hoje. Trate como não verificada e confirme com `bun test --help` antes de commitar.

**Opção de linha de comando sempre vence o arquivo de configuração.** É o que permite ter `coverage = true` no `bunfig.toml` para o CI e ainda rodar sem cobertura localmente.

**`seed` sem `randomize` não faz nada.** A fonte é explícita, e a falha é silenciosa: você commita a semente achando que fixou a ordem, e a ordem continua sendo a de descoberta.

| ID | Regra |
| --- | --- |
| `BUN-TEST-13` | Filtro posicional que aponta um **arquivo** **MUST** começar com `./` ou `/` — sem o prefixo é filtro por substring de caminho, e glob **NEVER** é aceito. |
| `BUN-TEST-14` | `seed` no `bunfig.toml` **MUST** vir acompanhado de `randomize = true` — sem isso não tem efeito, e a falha é silenciosa. |

---

## 6. O ambiente que o runner impõe

O runner muda o ambiente do processo antes de rodar qualquer teste. Duas variáveis, e as duas mudam o comportamento do código sob teste:

| Variável | Valor | Condição |
| --- | --- | --- |
| `NODE_ENV` | `"test"` | só se ainda não estiver definida no ambiente ou num `.env` carregado |
| `TZ` | `Etc/UTC` | a menos que `TZ` já esteja definida — mantém datas determinísticas entre máquinas |

```bash
NODE_ENV=development bun test # override explícito
TZ=America/Sao_Paulo bun test # testar o comportamento em fuso local
```

`TZ=Etc/UTC` é uma decisão de determinismo com efeito colateral: um teste que formata data passa na sua máquina e no CI, e **falharia** num ambiente que define `TZ`. Quem asserta sobre data formatada deve fixar o fuso explicitamente em vez de herdar o default (`BUN-TEST-21`, em [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) § 5).

### Globais injetados

Disponíveis sem import: `test`, `it`, `describe`, `expect`, `beforeAll`, `beforeEach`, `afterAll`, `afterEach`, `jest`, `vi`. Todos também são importáveis de `bun:test`:

```ts
import { test, describe, expect, beforeEach, mock, spyOn } from "bun:test";
```

**Prefira o import.** O global existe para compatibilidade e para teste rápido; o import explícito é o que faz o arquivo funcionar sob `tsc --noEmit` sem depender de declaração global, e é o que deixa óbvio, na revisão, que aquele `mock` é o do runner. Imports de `vitest` e de `@jest/globals` são reescritos internamente para `bun:test`, o que é o motivo pelo qual muita suíte de Vitest roda sem edição ([Bun - Testes](bun-testes.md) § 5.4).

### Exit code: o que faz o CI vermelho

| Código | Quando |
| --- | --- |
| `0` | todos os testes passaram **e** nenhum erro não tratado apareceu |
| `1` | houve falha de teste **ou** erro/rejeição não tratada |

A segunda metade da linha `1` é a que surpreende: **erro não tratado ou promise rejeitada fora de qualquer teste derruba a execução, mesmo que todos os testes passem.** Um `setInterval` que estoura depois do último `afterEach`, um listener que rejeita, um cleanup que lança — tudo isso vira exit `1` sem nenhum teste vermelho no relatório. É comportamento correto, e é a razão de o relatório e o exit code discordarem de vez em quando.

Handlers próprios são possíveis (`process.on("uncaughtException")`, `process.on("unhandledRejection")`), e **quase sempre são a decisão errada num teste**: eles transformam o sinal em silêncio.

### Flags de runtime que valem no teste

`--define`, `--loader`, `--tsconfig-override`, `--env-file`, `--preload`, `--smol`. São as mesmas do runtime, e o lugar delas geralmente é o `bunfig.toml`, não o comando — comando é para o que varia por invocação.

---

## 7. Receita: os scripts que um projeto precisa

```json
{
 "scripts": {
 "test": "bun test",
 "test:watch": "bun test --watch",
 "test:changed": "bun test --changed --watch",
 "test:ci": "bun test --parallel --coverage --reporter=junit --reporter-outfile=./junit.xml",
 "typecheck": "tsc --noEmit"
 }
}
```

Quatro decisões embutidas aí, todas defensáveis por escrito:

- **`test` sem flag nenhuma.** É o comando que qualquer pessoa (ou agente) roda sem ler documentação. Se ele precisa de flags para funcionar, elas pertencem ao `bunfig.toml`.
- **`test:changed` é o loop de desenvolvimento**, não o de verificação.
- **`test:ci` é o único lugar com `--parallel`**, porque é o único ambiente onde o isolamento por arquivo é obrigatório ([Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) § 4).
- **`typecheck` é passo separado e não opcional.** `bun test` não checa tipo nenhum: um arquivo cheio de `expectTypeOf` passa sem verificar nada (`BUN-TEST-18`).

| ID | Regra |
| --- | --- |
| `BUN-TEST-15` | Pipeline de CI **MUST** pinar a versão do Bun (`oven-sh/setup-bun` com `bun-version` fixo, ou imagem com tag) — flags e defaults do runner mudam entre minors, e `latest` transforma isso em falha sem commit. † |

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| `pedidos.tests.ts`, `testePedidos.ts`, `pedidos-test.ts` | não casa nenhum padrão de descoberta; nunca roda, e nada avisa | `pedidos.test.ts` — `BUN-TEST-01` |
| `bun test "src/**/*.test.ts"` | glob não é suportado; o argumento vira substring de caminho | caminho com `./`, ou `root`/`pathIgnorePatterns` — `BUN-TEST-13` |
| `bun test pedidos.test.ts` (sem `./`) | é filtro por substring; casa qualquer caminho que contenha o texto | `bun test./src/pedidos.test.ts` — `BUN-TEST-13` |
| `seed = 12345` no `bunfig.toml` sem `randomize = true` | não tem efeito, e nada avisa; a ordem continua sendo a de descoberta | declarar as duas chaves — `BUN-TEST-14` |
| `--retry 3` no comando de teste do CI | esconde flakiness real e mascara o teste que estava certo em falhar | `{ retry: N }` no teste que tem motivo declarado |
| `--changed` como portão de merge | o grafo de import não vê env, migração, fixture nem ordem | `--changed` no job de PR; suíte inteira no merge — `BUN-TEST-15` |
| `describe("testes", …)` | o rótulo do `describe` é o endereço de `-t`; genérico não endereça nada | nomear o `describe` pela unidade sob teste |
| `bun test` sem `tsc --noEmit` no CI | o runner não checa tipo; `expectTypeOf` é no-op em runtime | passo separado de typecheck — `BUN-TEST-18` |
| `bun@latest` no CI | flags do runner mudam entre minors; a suíte quebra sem commit | pinar a versão — `BUN-TEST-15` |
| `process.on("unhandledRejection")` para calar erro em teste | transforma o sinal em silêncio e devolve exit `0` a um processo defeituoso | deixar estourar; o exit `1` é a informação |

---

## Checklist de revisão

- [ ] Todo arquivo de teste casa um dos padrões de descoberta? → `BUN-TEST-01`
- [ ] O recorte da suíte está em `root`/`pathIgnorePatterns`, não em glob no comando? → `BUN-TEST-13`
- [ ] Se há `seed`, há `randomize = true`? → `BUN-TEST-14`
- [ ] A versão do Bun está pinada no CI? → `BUN-TEST-15`
- [ ] O script `test` roda sem flag obrigatória (o resto está no `bunfig.toml`)?
- [ ] Existe passo separado de `tsc --noEmit`? → `BUN-TEST-18`
- [ ] Nenhum `--retry` global no comando de CI?
- [ ] Asserção sobre data fixa o fuso, em vez de herdar `TZ=Etc/UTC`? → `BUN-TEST-21`

---

## Relacionados

- [Bun - Testes](bun-testes.md) — hub, modelo mental, mapa da API, árvores de decisão
- [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) · [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) · [Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) · [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md) · [Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md)
- [Bun - Runtime e APIs](bun-runtime-e-apis.md) — `bunfig.toml`, `.env`, `paths`, `--watch` × `--hot`
- [Bun - Gerenciador de Pacotes](bun-gerenciador-de-pacotes.md) — instalação em CI, pin de versão
- — o que testar, antes de como

## Fontes consultadas

Verificadas em **2026-08-20**: [Test runner](https://bun.com/docs/test) · [Finding tests](https://bun.com/docs/test/discovery) · [Test configuration](https://bun.com/docs/test/configuration) · [Runtime behavior](https://bun.com/docs/test/runtime-behavior) · [Writing tests](https://bun.com/docs/test/writing-tests) · [Bun 1.4](https://bun.com/blog/bun-v1.4) (para `--changed`).
