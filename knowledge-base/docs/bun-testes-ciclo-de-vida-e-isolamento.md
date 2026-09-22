---
titulo: Bun - Testes - Ciclo de Vida e Isolamento
Link: https://bun.com/docs/test/lifecycle
tags:
  - bun
  - testing
  - agent-context
source: "Documentação oficial — https://bun.com/docs/test/lifecycle, /parallel"
verificado-em: 2026-08-20
---

# Bun - Testes - Ciclo de Vida e Isolamento

> **Quando o código roda e o que ele compartilha.** Os cinco hooks e o escopo definido pelo lugar da declaração · a ordem completa numa árvore aninhada · o preload como escopo global — e o que acontece com ele sob `--isolate` · `--parallel`, `--isolate`, `--no-isolate` e a lista do que a isolação reseta · concorrência dentro do arquivo (`test.concurrent`, `test.serial`, `--max-concurrency`) · dependência de ordem entre arquivos, que nenhuma flag conserta · `--shard` e `--timings` para CI.
>
> **Não cobre:** flags de descoberta e filtro ([Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md)) · restauração de mocks ([Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) § 3) · a receita de CI completa ([Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md) § 5).

Entrada: [Bun - Testes](bun-testes.md) · Base normativa: [Bun - Testes](bun-testes.md) § 6 · Família: `BUN-TEST-*` (esta nota é dona de `09`, `10`, `22`, `23`, `24`)

---

## 1. Conceito: o default é o oposto do que Jest treinou você a esperar

Sem nenhuma flag, `bun test` roda **todos os arquivos no mesmo processo, com um único `globalThis` compartilhado**. Não há isolação por arquivo. Estado deixado por `a.test.ts` — um spy, um módulo mockado, uma variável de módulo, uma conexão aberta — está lá quando `b.test.ts` começa.

Jest e Vitest fazem o contrário por default (um ambiente por arquivo), e é dessa diferença que sai a maior parte dos "passa sozinho, falha na suíte" de quem migra. Duas leituras erradas, ambas comuns:

- **"Isso é um bug do Bun."** Não é: é a razão de o runner ser rápido. Um processo, um global, sem custo de reconstruir ambiente por arquivo.
- **"Então basta ligar `--isolate` e esquecer."** Também não: `--isolate` faz o vazamento entre arquivos parar de existir, e **expõe** o teste que só passava por causa dele. A flag não conserta o teste — ela mostra a conta.

O mapa mental que organiza esta nota inteira: existem **três escopos**, e cada mecanismo pertence a um.

| Escopo | Quem vive nele | Como é reiniciado |
| --- | --- | --- |
| **Teste** | `beforeEach`/`afterEach`, `onTestFinished` | a cada teste, sempre |
| **Arquivo** | `beforeAll`/`afterAll` no topo do arquivo, estado de módulo | só com `--isolate` (implícito em `--parallel`) |
| **Execução** | hooks declarados em `preload`, `mock.module()` | nunca, dentro de uma invocação |

---

## 2. Os cinco hooks

| Hook | Escopo |
| --- | --- |
| `beforeAll` / `afterAll` | uma vez por **escopo onde foi declarado**: `describe`, arquivo, ou — num preload — a execução inteira |
| `beforeEach` / `afterEach` | antes/depois de cada teste do escopo |
| `onTestFinished` | depois de **todos** os `afterEach` de um teste específico |

**O escopo é o lugar da declaração, não uma opção de configuração.** Um `beforeAll` no topo do arquivo cobre o arquivo; dentro de um `describe`, cobre o bloco; num preload, cobre a execução.

### Ordem numa árvore aninhada

Com hooks no arquivo, num `describe` externo e num interno, a fonte declara esta sequência para cada teste:

```
1.  beforeAll   do arquivo
2.  beforeAll   do describe externo
3.  beforeAll   do describe interno
4.  beforeEach  do externo
5.  beforeEach  do interno
6.  corpo do teste
7.  afterEach   do interno
8.  afterEach   do externo
9.  afterAll    do interno
10. afterAll    do externo
11. afterAll    do arquivo
```

`before*` vai de fora para dentro, `after*` de dentro para fora. É o que permite o padrão comum: banco no `beforeAll` do arquivo, transação no `beforeEach` do `describe`, rollback no `afterEach`.

### Dois comportamentos verificados que mudam decisão

- **`beforeAll` que lança pula todos os testes do escopo dele.** O relatório mostra testes pulados, não falhados — e é preciso ler a saída do hook para saber por quê. Setup que pode falhar por motivo ambiental (porta ocupada, banco fora) merece mensagem de erro explícita, porque a falha vai chegar disfarçada de "skip".
- **`onTestFinished` não é suportado em teste concorrente.** A fonte manda usar `test.serial` nesse caso.

```ts
import { test, onTestFinished } from "bun:test";

test("cria e limpa o arquivo temporário", async () => {
  const caminho = await criarTemp();
  onTestFinished(async () => { await rm(caminho); });   // registrado no ponto de uso
  expect(await Bun.file(caminho).exists()).toBe(true);
});
```

`onTestFinished` existe para cleanup **registrado onde o recurso é criado** — o que evita a distância entre `beforeEach` e `afterEach` quando só um teste precisa daquele recurso.

| ID | Regra |
| --- | --- |
| `BUN-TEST-22` | `onTestFinished` **NEVER** em teste concorrente — a fonte declara que não é suportado; use `test.serial`. |

---

## 3. Preload: o único escopo de execução — e o que `--isolate` faz com ele

```ts
// test/setup.ts
import { beforeAll, afterAll } from "bun:test";

let servidor: ReturnType<typeof Bun.serve>;

beforeAll(async () => { servidor = await subirServidorDeTeste(); });
afterAll(async () => { await servidor.stop(); });
```

```toml
[test]
preload = ["./test/setup.ts"]
```

> **Este exemplo deixa de ser "uma vez" no momento em que você liga `--parallel`. Leia antes de copiá-lo.**
>
> "Declarado num preload, cobre a execução inteira" vale no **default** (processo único, global compartilhado). Com `--parallel` — a recomendação de CI da § 4 — a fonte é explícita: *"Preload-level `beforeAll`/`afterAll` hooks still wrap every file, since a worker never knows which file is its last."* O `beforeAll` acima passa a rodar **uma vez por arquivo de teste**: cinquenta arquivos, cinquenta servidores subidos e derrubados, provavelmente disputando a mesma porta.
>
> As três saídas, em ordem de preferência:
>
> | Saída | Como | Custo |
> | --- | --- | --- |
> | Setup **por arquivo e isolado** | manter no preload, mas derivar porta/banco/diretório de `BUN_TEST_WORKER_ID` (§ 4) | subida repetida, sem colisão — é o caminho que escala |
> | Setup **idempotente e barato** | `globalThis.__servidor ??= await subir()` — funciona sob `--no-isolate`, **não** sob `--isolate`, que zera o global entre arquivos | funciona só numa configuração |
> | Recurso **fora** do runner | `docker compose up` ou serviço de CI antes de `bun test`; o preload só conecta | mais infra, zero surpresa — |
>
> A regra que sobra: **setup de preload é idempotente e barato, ou parametrizado por worker.** Setup caro e único não tem onde caber.

| ID | Regra |
| --- | --- |
| `BUN-TEST-24` | Setup declarado em `preload` **MUST** ser idempotente e barato, ou parametrizado por worker — sob `--parallel`/`--isolate` os hooks de nível de preload envolvem **cada arquivo**, não a execução. |

---

## 4. `--parallel`, `--isolate` e o que a isolação reseta

```bash
bun test --parallel                 # um worker por core; IMPLICA --isolate
bun test --parallel=4               # quatro workers
bun test --parallel --no-isolate    # um global por worker, não por arquivo
bun test --isolate                  # global novo por arquivo, sem paralelizar
```

| Flag | O que faz | Quando |
| --- | --- | --- |
| `--parallel[=N]` | distribui os **arquivos** entre N processos worker (default: número de cores); os arquivos entram na fila do worker que ficar livre | CI, e suíte local grande |
| `--isolate` | `globalThis` novo por arquivo, no mesmo processo | diagnosticar dependência entre arquivos sem mudar a paralelização |
| `--no-isolate` | arquivos compartilham global e registro de módulos dentro do worker | suíte de muitos arquivos pequenos, quando você **sabe** que não há vazamento |

### O que `--isolate` reseta entre arquivos

A sequência declarada pela fonte:

1. cria um `globalThis` novo;
2. limpa os registros de módulo ESM e CommonJS;
3. fecha servidores, sockets, watchers de arquivo e subprocessos;
4. cancela timers e restaura fake timers;
5. **reexecuta os scripts de `--preload`** no global novo.

Bun mantém em cache o fonte transpilado e o bytecode entre globals, então o custo não é reparsear tudo — é reavaliar módulos e preloads.

O item 3 merece nota: **a isolação fecha recurso vazado.** Um teste que esquece um servidor de pé não pendura a suíte sob `--isolate`. Isso é rede de segurança, não licença — o vazamento continua sendo bug, e sem `--isolate` ele pendura o processo.

### Worker: o que cada um recebe

Cada worker recebe `BUN_TEST_WORKER_ID` e `JEST_WORKER_ID` (índice base 1). É por aí que se dá a cada worker seu próprio banco, porta ou diretório:

```ts
const id = process.env.BUN_TEST_WORKER_ID ?? "1";
export const dbName = `app_test_${id}`;
export const porta = 3100 + Number(id);
```

Sem isso, `--parallel` transforma um teste correto em falha intermitente: dois workers gravando na mesma tabela, ou disputando a mesma porta.

### O que o coordenador faz

- **`--bail` tem granularidade de arquivo:** atingido o limite, o coordenador não inicia arquivos novos; os que já rodam terminam.
- **Cobertura, JUnit XML e escrita de snapshot são fundidos.** `--parallel --coverage --reporter=junit --reporter-outfile=junit.xml` produz **um** relatório ([Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md) § 4).
- As flags de execução são repassadas aos workers.

| ID | Regra |
| --- | --- |
| `BUN-TEST-10` | Teste que usa recurso externo compartilhado (banco, porta, diretório) **MUST** derivá-lo de `BUN_TEST_WORKER_ID` quando a suíte roda com `--parallel`. |

---

## 5. Concorrência **dentro** do arquivo

`--parallel` paraleliza arquivos entre processos. Concorrência é outra coisa: testes do **mesmo** arquivo que se sobrepõem, cooperativamente, num só thread e num só global.

```ts
test.concurrent("busca A", async () => { … });
test.concurrent("busca B", async () => { … });   // sobrepõe com A
test.serial("aplica migração", async () => { … }); // nunca sobrepõe
```

```bash
bun test --concurrent               # trata TODOS os testes como concurrent
bun test --max-concurrency=8        # teto de testes simultâneos (default 20)
```

```toml
[test]
concurrentTestGlob = "**/*.integration.test.ts"   # concorrência só onde vale
```

**O que a concorrência compra:** tempo de espera de I/O. Dez testes que cada um espera 200 ms de rede terminam em ~200 ms, não em 2 s. **O que ela não compra:** CPU — é um thread só. Teste que calcula não fica mais rápido concorrente.

**O que ela cobra:** os testes concorrentes compartilham o global. Dois testes que escrevem na mesma variável de módulo, na mesma tabela ou no mesmo `document` passam a interferir de forma que depende de tempo — a pior categoria de flaky. `test.serial` é o opt-out para o teste que precisa de ordem, e `--concurrent` global só é seguro numa suíte escrita para isso.

E o detalhe que morde: **`onTestFinished` não funciona em teste concorrente** (`BUN-TEST-22`).

| ID | Regra |
| --- | --- |
| `BUN-TEST-23` | Teste marcado `concurrent` (ou suíte sob `--concurrent`) **NEVER** compartilha estado mutável com outro teste do mesmo arquivo — quem depende de ordem ou de estado compartilhado **MUST** ser `test.serial`. † |

---

## 6. Dependência de ordem: dois problemas com o mesmo nome

Vale separá-los, porque o remédio de um não serve para o outro:

| Sintoma | Escopo | Remédio |
| --- | --- | --- |
| Testes do **mesmo arquivo** interferem entre si sob concorrência | dentro do arquivo | `test.serial` |
| Um arquivo só passa porque **outro arquivo** rodou antes e deixou estado no global | entre arquivos | **corrigir o teste** — não há flag |

`test.serial` sequencia **dentro** do arquivo. Aplicá-lo a um teste que depende de outro arquivo não muda nada: o problema não é a ordem interna, é o global compartilhado ter desaparecido. E **não existe flag que restaure o global compartilhado sob `--isolate`** — é exatamente o que `--isolate` remove. `--parallel --no-isolate` dá um global por *worker*, mas a distribuição de arquivos entre workers não é a ordem do seu teste: ele torna a falha intermitente em vez de resolvê-la, o que é pior.

Como se detecta, antes do CI:

```bash
bun test --randomize            # ordem aleatória; a suíte precisa passar assim
bun test --randomize --seed 42  # reproduz a ordem que revelou a falha
bun test --isolate              # global novo por arquivo, sem paralelizar — isola a causa
bun test --rerun-each 10        # repete cada arquivo; pega flaky que não é de ordem
```

A correção tem sempre a mesma forma: **mover o estado de que o arquivo depende para dentro dele** — `beforeAll`/`beforeEach` no próprio arquivo, ou uma fixture que constrói o que o teste precisa. Se o custo disso for alto, o sinal é que o setup pertence ao preload, e aí ele precisa ser idempotente (`BUN-TEST-24`).

| ID | Regra |
| --- | --- |
| `BUN-TEST-09` | Teste que depende de estado deixado por **outro arquivo** **MUST** ser corrigido movendo o setup para dentro do próprio arquivo — `test.serial` **NEVER** resolve isso (ele sequencia dentro do arquivo) e nenhuma flag restaura o global compartilhado sob `--isolate`; a detecção é `bun test --randomize`. |

---

## 7. `--shard` e `--timings`: dividir entre máquinas

```bash
bun test --shard=1/4        # primeira de quatro fatias determinísticas
bun test --update-timings   # grava a duração por arquivo
bun test --timings=.timings.json --shard=2/4
```

- **`--shard=i/n`** roda a i-ésima de n fatias, sem coordenador entre máquinas: cada runner decide sozinho o que lhe cabe, de forma determinística, com índice base 1 (a mesma convenção de Jest e Vitest).
- **`--timings=<arquivo>`** lê a duração de cada arquivo de execuções anteriores e corta as fatias por **tempo total**, não por contagem de arquivos. `--update-timings` grava. Combinado com `--shard`, cada shard escreve só os arquivos dele — as saídas são disjuntas e se combinam sem merge. Caminhos que ainda não existem na tabela são ignorados.

Sem `--timings`, quatro shards com o mesmo número de arquivos podem levar tempos muito diferentes: um arquivo de integração vale trinta de unidade. É o ganho concreto, e ele exige que o arquivo de timings seja **persistido entre execuções de CI** (cache do runner, ou artefato commitado).

> **Divergência de fonte registrada.** A página de paralelismo descreve a distribuição do `--shard` como *arquivos ordenados por caminho, com cada máquina levando uma fatia contígua*; o post de release da 1.4 descreve a mesma flag como *round-robin determinístico*. As duas formas são determinísticas e não exigem coordenação — a consequência prática (você pode rodar shards independentes e a união cobre a suíte) é idêntica. O que muda é a **localidade**: sob fatia contígua, arquivos vizinhos caem na mesma máquina; sob round-robin, não. Não conte com localidade em nenhuma das leituras, e não presuma que uma pasta inteira roda no mesmo shard.

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| `beforeAll` caro no preload (subir servidor, migrar banco) com `--parallel` ligado | os hooks de preload envolvem **cada arquivo**; vira um servidor por arquivo, disputando a porta | derivar de `BUN_TEST_WORKER_ID`, tornar idempotente, ou subir fora do runner — `BUN-TEST-24` |
| Testes compartilhando a mesma tabela ou porta ao ligar `--parallel` | os workers colidem e a falha parece flaky | derivar o recurso do worker id — `BUN-TEST-10` |
| `test.serial` num teste que depende de outro **arquivo** | `serial` sequencia dentro do arquivo; a dependência entre arquivos continua | mover o setup para dentro do arquivo — `BUN-TEST-09` |
| `--parallel --no-isolate` para "consertar" teste que depende de ordem | devolve um global por worker, mas não a sua ordem; a falha fica intermitente | corrigir o teste — `BUN-TEST-09` |
| `--concurrent` global numa suíte que não foi escrita para isso | testes do mesmo arquivo passam a interferir por tempo | concorrência por `concurrentTestGlob` ou por teste — `BUN-TEST-23` |
| `onTestFinished` dentro de `test.concurrent` | não é suportado; o cleanup não roda | `test.serial`, ou `afterEach` — `BUN-TEST-22` |
| Confiar na ordem de declaração entre arquivos ("o de setup roda primeiro") | a ordem de descoberta não é contrato, e `--parallel` a destrói | fixture explícita no arquivo que precisa |
| `--shard` sem `--timings` numa suíte com arquivos muito desiguais | um shard leva 8 minutos e outro 40 segundos | gravar e cachear timings — § 7 |
| Presumir que uma pasta inteira cai no mesmo shard | a distribuição não garante localidade em nenhuma das duas leituras da fonte | não depender de localidade — § 7 |
| Estado global vazado "que não incomoda ninguém" | sem `--isolate` ele viaja para todos os arquivos seguintes | `mock.restore()` no preload e fixtures por arquivo — [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) § 3 |

---

## Checklist de revisão

- [ ] A suíte passa com `--randomize`? Se não, há dependência de ordem — e `test.serial` não é o remédio. → `BUN-TEST-09`
- [ ] Recursos externos são derivados de `BUN_TEST_WORKER_ID`? → `BUN-TEST-10`
- [ ] Nenhum `onTestFinished` em teste concorrente? → `BUN-TEST-22`
- [ ] Testes concorrentes não compartilham estado mutável? → `BUN-TEST-23`
- [ ] Nenhum setup caro e não idempotente no preload, com `--parallel` ligado? → `BUN-TEST-24`
- [ ] A suíte passa com `--isolate` (ou seja, sem depender do global compartilhado)?
- [ ] Se o CI usa `--shard`, o arquivo de `--timings` é persistido entre execuções?
- [ ] Hooks estão declarados no escopo mais estreito que resolve o problema?

---

## Relacionados

- [Bun - Testes](bun-testes.md) — hub, modelo mental, mapa da API, árvores de decisão
- [Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) · [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) · [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) · [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md) · [Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md)
- — subir dependência fora do runner
- — o que testar, antes de como

## Fontes consultadas

Verificadas em **2026-08-20**: [Lifecycle hooks](https://bun.com/docs/test/lifecycle) · [Parallel & isolated test runs](https://bun.com/docs/test/parallel) · [Test configuration](https://bun.com/docs/test/configuration) · [Test runner](https://bun.com/docs/test) · [Bun 1.4](https://bun.com/blog/bun-v1.4).
