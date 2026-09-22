---
Link: https://bun.com/docs/test/writing-tests
tags:
 - bun
 - testing
 - agent-context
source: "Documentação oficial — https://bun.com/docs/test/writing-tests, /snapshots"
verificado-em: 2026-08-20
---

# Bun - Testes - Escrita e Asserções

> O corpo do arquivo de teste · `test`/`it`/`describe`, assíncrono e o `done` · timeout, `retry`, `repeats` · a tabela completa de modificadores e o que cada um comunica · `test.each` e os especificadores de formato · o catálogo de matchers, incluindo os que só existem em Bun e o que **não** está implementado · contagem de asserções · matcher próprio com `expect.extend` · `expectTypeOf` e por que ele não verifica nada em runtime · snapshots em arquivo e inline.
>
> **Não cobre:** descoberta, filtros e `bunfig.toml` ([Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md)) · mocks e relógio ([Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md)) · hooks e ordem ([Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md)) · matchers de DOM ([Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md)).

Entrada: [Bun - Testes](bun-testes.md) · Base normativa: [Bun - Testes](bun-testes.md) § 6 · Família: `BUN-TEST-*` (esta nota é dona de `05`, `06`, `08`, `11`, `16`, `17`, `18`, `19`)

---

## 1. Conceito: o teste é uma afirmação, e o runner só decide se ela roda

Um teste verde significa uma coisa: **as asserções que executaram passaram**. Não significa que elas executaram. A distância entre essas duas frases é onde vive quase todo falso positivo desta nota — asserção dentro de `catch` que nunca foi alcançado, `await` esquecido, `expectTypeOf` que é no-op, snapshot regravado por reflexo.

Daí o critério que organiza o resto: cada API abaixo é apresentada com **o que ela comunica a quem lê o relatório**, não só com o que ela faz. `test.skip` e `test.failing` fazem quase a mesma coisa mecanicamente e dizem coisas opostas. `toBe` e `toEqual` passam nos mesmos casos até o dia em que não passam.

---

## 2. `test`, `describe` e o contorno assíncrono

```ts
import { test, describe, expect } from "bun:test";

test("soma dois inteiros", => {
 expect(2 + 2).toBe(4);
});

describe("calculadora de frete", => {
 test("cobra por faixa de peso", => {
 expect(frete({ peso: 1200 })).toBe(2490);
 });
});
```

`it` é alias de `test`. `describe` agrupa, aninha, e o rótulo dele passa a fazer parte do nome do teste para efeito de `-t` ([Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) § 3.2).

**Assíncrono: `async`/`await`, e só.**

```ts
test("busca o pedido", async => {
 const pedido = await repo.buscar("p-1");
 expect(pedido.status).toBe("pago");
});
```

O parâmetro `done` existe por compatibilidade — e a fonte declara a armadilha inteira numa frase: *"If your test function takes a `done` parameter, you must call it or the test hangs."* Um teste que pendura consome o timeout inteiro (5 s por default) e falha por motivo errado, escondendo o real. Em código novo, `done` não tem uso: toda API que aceita callback pode ser envolvida numa Promise.

| ID | Regra |
| --- | --- |
| `BUN-TEST-17` | Teste assíncrono **MUST** usar `async`/`await`. O parâmetro `done` **NEVER** em código novo — se declarado e não chamado, o teste pendura até o timeout e falha por motivo errado. † |

---

## 3. Timeout, `retry` e `repeats`

```ts
test("operação lenta", async => {
 expect(await operacaoLenta).toBe(42);
}, 500); // terceiro argumento: ms

test("requisição instável", async => {
 const r = await fetch("https://exemplo.com/api");
 expect(r.ok).toBe(true);
}, { retry: 3 });

test("garante estabilidade", => {
 expect(Math.random).toBeLessThan(1);
}, { repeats: 20 }); // roda 21 vezes: 1 + 20
```

O que a fonte declara, e que muda como se usa:

- **Timeout default: 5000 ms**, sobreponível por teste (terceiro argumento) ou globalmente (`--timeout`). `0` ou `Infinity` desabilitam.
- **O timeout lança exceção não capturável.** Não há `try/catch` que salve o teste — é intencional, para forçar a parada.
- **Bun mata os processos filhos** que o teste criou com `Bun.spawn`, `Bun.spawnSync` ou `node:child_process` quando o timeout estoura. Um teste que sobe um processo e estoura não deixa zumbi.
- **`repeats: N` roda N+1 vezes** (a execução inicial mais N repetições).
- **`retry` e `repeats` não podem coexistir** no mesmo teste.

Onde cada um pertence:

| Situação | Use | Não use |
| --- | --- | --- |
| Instabilidade externa real e declarada (rede, serviço de terceiro) | `{ retry: N }` no teste | `--retry` global — anestesia a suíte inteira |
| Suspeita de flakiness a investigar | `{ repeats: 20 }`, ou `--rerun-each` | `retry`, que esconde exatamente o que você quer ver |
| Operação legitimamente lenta (migração, build) | terceiro argumento com valor explícito | `--timeout` global alto, que afrouxa todos |
| Teste que "às vezes trava" | investigar; quase sempre é `await` faltando ou `done` não chamado | timeout `0` |

**Desabilitar timeout (`0`/`Infinity`) num teste de CI troca uma falha por um job pendurado.** É útil localmente, com o inspector aberto; não é útil num pipeline.

| ID | Regra |
| --- | --- |
| `BUN-TEST-16` | `retry` e `repeats` **NEVER** coexistem no mesmo teste — a fonte declara a combinação inválida. |

---

## 4. Modificadores: o que cada um comunica

| Modificador | Semântica mecânica | O que comunica a quem lê o relatório |
| --- | --- | --- |
| `test.skip` | não roda | nada. O teste desaparece, e ninguém é avisado de nada |
| `test.todo` | não roda; com `--todo`, roda e **falha se passar** | "isto precisa ser escrito" |
| `test.failing` | inverte o resultado: falhar = passar; passar = **falhar** | "existe um bug conhecido aqui, e quero saber quando ele for corrigido" |
| `test.only` | exige `bun test --only` para filtrar | nada, em CI. É ferramenta de depuração local |
| `test.if(cond)` | roda só se a condição for verdadeira | "este teste é válido só nesta plataforma/arquitetura/flag" |
| `test.skipIf(cond)` / `test.todoIf(cond)` | pula / marca como todo condicionalmente | o mesmo, pelo lado negativo |
| `test.concurrent` | roda em paralelo com outros concorrentes do arquivo | "este teste não compartilha estado" |
| `test.serial` | força execução sequencial (opt-out de `--concurrent`) | "este teste depende de ordem ou de estado compartilhado" |

`describe` aceita os mesmos qualificadores (`describe.only`, `describe.skipIf`, `describe.each`, `describe.concurrent`), e eles encadeiam: `test.failing.each([...])(...)`.

### `skip` × `failing`: a única escolha aqui que não é estilística

`test.skip` remove o teste do relatório. O bug continua, o teste some, e no dia em que alguém corrige o comportamento por acaso, **nada avisa** — o teste segue pulado por meses até alguém perguntar por que.

`test.failing` mantém o teste rodando e **falha no momento em que ele começa a passar**. Isso parece contraintuitivo até você ver o efeito: o commit que corrige o bug quebra o CI e a pessoa é obrigada a remover a marca. O conhecimento não se perde.

```ts
// bug conhecido em ponto flutuante — quero ser avisado se for corrigido
test.failing("soma decimal exata", => {
 expect(0.1 + 0.2).toBe(0.3);
});
```

`skip` é para desativação com prazo (uma dependência caiu, o ambiente mudou hoje) — e prazo significa data no comentário, não intenção.

| ID | Regra |
| --- | --- |
| `BUN-TEST-08` | `test.only` **NEVER** é usado como forma de desabilitar os demais testes — sem `bun test --only` ele não filtra nada. |
| `BUN-TEST-11` | Teste que documenta bug conhecido **MUST** usar `test.failing`, **NEVER** `test.skip` — `failing` avisa quando o bug é corrigido. |

---

## 5. `test.each`: tabela de casos

```ts
test.each([
 [1, 2, 3],
 [3, 4, 7],
])("soma(%p, %p) = %p", (a, b, esperado) => {
 expect(a + b).toBe(esperado);
});

test.each([
 { peso: 500, faixa: "leve", valor: 1490 },
 { peso: 12000, faixa: "pesada", valor: 4990 },
])("frete de $peso g é $valor", ({ peso, valor }) => {
 expect(frete({ peso })).toBe(valor);
});
```

**A regra de passagem de argumentos:** linha que é array vira **argumentos separados**; linha que não é array (um objeto) vira **um único argumento**. Confundir os dois produz `undefined` no corpo do teste, não erro de tipo.

Especificadores de formato no título:

| Token | Substitui por |
| --- | --- |
| `%p` | pretty-format do valor |
| `%s` | string |
| `%d` / `%i` / `%f` | número / inteiro / float |
| `%j` | JSON |
| `%o` | objeto |
| `%#` | índice da linha |
| `%%` | um `%` literal |

Com objetos, `$propriedade` interpola pelo nome — é o que torna o título legível quando a tabela tem cinco colunas.

**Quando `each` é a ferramenta certa:** o corpo do teste é idêntico e só os dados mudam. Quando ele **não** é: cada linha precisa de um `expect` diferente, ou de setup próprio. Nesse caso, `each` produz um corpo cheio de `if` — e três testes explícitos são mais curtos e mais legíveis que uma tabela com ramificação.

---

## 6. Matchers: o catálogo e as três decisões que importam

### 6.1 O catálogo

| Categoria | Matchers |
| --- | --- |
| Igualdade | `.toBe`, `.toEqual`, `.toStrictEqual`, `.not` |
| Presença | `.toBeNull`, `.toBeUndefined`, `.toBeDefined`, `.toBeNaN`, `.toBeTruthy`, `.toBeFalsy` |
| String / array | `.toContain`, `.toContainEqual`, `.toHaveLength`, `.toMatch`, `expect.stringContaining`, `expect.stringMatching`, `expect.arrayContaining` |
| Objeto | `.toHaveProperty`, `.toMatchObject`, `expect.objectContaining`, `.toContainAllKeys`, `.toContainValue`, `.toContainValues`, `.toContainAllValues`, `.toContainAnyValues` |
| Número | `.toBeCloseTo`, `expect.closeTo`, `.toBeGreaterThan`, `.toBeGreaterThanOrEqual`, `.toBeLessThan`, `.toBeLessThanOrEqual` |
| Função / classe | `.toThrow`, `.toBeInstanceOf` |
| Promise | `.resolves`, `.rejects` |
| Mock | `.toHaveBeenCalled`, `.toHaveBeenCalledTimes`, `.toHaveBeenCalledWith`, `.toHaveBeenLastCalledWith`, `.toHaveBeenNthCalledWith`, `.toHaveReturned`, `.toHaveReturnedTimes`, `.toHaveReturnedWith`, `.toHaveLastReturnedWith`, `.toHaveNthReturnedWith` |
| Snapshot | `.toMatchSnapshot`, `.toMatchInlineSnapshot`, `.toThrowErrorMatchingSnapshot`, `.toThrowErrorMatchingInlineSnapshot` |
| Utilitários | `expect.extend`, `expect.anything`, `expect.any`, `expect.assertions`, `expect.hasAssertions` |

**Não implementado:** `expect.addSnapshotSerializer`. Serializador customizado de snapshot não existe — o que limita snapshot a valores que o formatador default representa bem (§ 9).

**A compatibilidade com Jest não é total, e a fonte diz isso**: *"Bun aims for compatibility with Jest, but not everything is implemented"*, com uma [issue de rastreamento](https://github.com/oven-sh/bun/issues/1825) citada como referência de estado. "Existe no Jest" não é evidência de que existe aqui — conferir antes de usar é a invariante do [Bun](bun.md) § 7.

### 6.2 `toBe` × `toEqual` × `toStrictEqual`

| Matcher | Compara | Use quando |
| --- | --- | --- |
| `.toBe` | identidade (`Object.is`) | primitivo, ou quando a identidade da referência **é** a afirmação |
| `.toEqual` | estrutura, recursivamente; ignora `undefined` em propriedades | o caso normal para objeto e array |
| `.toStrictEqual` | estrutura **mais** tipo de classe e propriedades `undefined` | o objeto atravessa uma fronteira onde a forma exata importa (serialização, contrato de API) |

A diferença que morde: `expect({ a: 1, b: undefined }).toEqual({ a: 1 })` **passa**; com `toStrictEqual`, falha. Se o objeto vai virar JSON, `toEqual` está certo (a chave desaparece de qualquer forma). Se ele vai para um `Object.keys`, não está.

### 6.3 `.toThrow` e o teste de erro

```ts
expect( => validar(pedidoInvalido)).toThrow(ValidacaoError);
expect( => validar(pedidoInvalido)).toThrow(/cep/i);
await expect(cobrar(pedidoInvalido)).rejects.toThrow(PagamentoRecusado);
```

Três formas, e a terceira é a que mais falta em código gerado: para função assíncrona, `.rejects` é o caminho — envolver em `try/catch` funciona, mas exige contagem de asserções (§ 7) para não passar em silêncio.

**`.toThrow` sem argumento aceita qualquer erro**, inclusive o `TypeError` que aparece quando você quebrou a chamada. Passar a classe ou a mensagem é o que faz o teste afirmar algo.

---

## 7. Contagem de asserções: o antídoto do falso positivo

```ts
test("propaga o erro do gateway", async => {
 expect.assertions(1); // exatamente uma asserção deve rodar
 try {
 await cobrar(pedidoInvalido);
 } catch (e) {
 expect(e).toBeInstanceOf(PagamentoRecusado);
 }
});

test("chama o callback de progresso", async => {
 expect.hasAssertions; // ao menos uma
 await enviar(arquivo, (pct) => {
 expect(pct).toBeGreaterThanOrEqual(0);
 });
});
```

Sem `expect.assertions(1)`, o primeiro teste **passa quando `cobrar` não lança** — o `catch` simplesmente não executa, nenhuma asserção roda, e o runner não tem como saber que faltou algo. É o falso positivo mais comum em teste assíncrono, e o único mecanismo que o pega é a contagem.

Onde ela é obrigatória: toda vez que a asserção está dentro de `catch`, de callback, ou de um `if`. Ou seja, toda vez que **o caminho até o `expect` é condicional**.

| ID | Regra |
| --- | --- |
| `BUN-TEST-06` | Teste cuja asserção vive em `catch`, callback ou branch condicional **MUST** declarar `expect.assertions(n)` ou `expect.hasAssertions`. |

---

## 8. Matcher próprio e verificação de tipo

### 8.1 `expect.extend`

```ts
// test/matchers.ts — registrado num preload
import { expect } from "bun:test";

expect.extend({
 toBeCentavos(recebido: unknown) {
 const ok = Number.isInteger(recebido) && (recebido as number) >= 0;
 return {
 pass: ok,
 message: =>
 `esperava inteiro não negativo em centavos, recebi ${JSON.stringify(recebido)}`,
 };
 },
});
```

Um matcher próprio vale a pena quando a mesma asserção composta aparece em muitos testes **e** a mensagem de falha default não diz o que está errado. O ganho real é a mensagem: `expect(valor).toBeCentavos` falha explicando o domínio, enquanto três `expect` encadeados falham explicando aritmética.

O mesmo mecanismo é o que registra os matchers de `@testing-library/jest-dom` — e ali ele não é conveniência, é obrigatório (`BUN-TEST-12`, em [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md) § 2).

### 8.2 `expectTypeOf` não verifica nada em runtime

```ts
import { expectTypeOf } from "bun:test";

expectTypeOf<string>.toEqualTypeOf<string>;
expectTypeOf(saudar).parameters.toEqualTypeOf<[string]>;
expectTypeOf(Promise.resolve(42)).resolves.toBeNumber;
```

A API é compatível com a do Vitest e é **no-op em runtime**: um arquivo inteiro de `expectTypeOf` passa em `bun test` sem checar tipo nenhum. A verificação acontece em `tsc --noEmit`, num passo separado — a própria fonte instrui `bunx tsc --noEmit`.

Isso não desmerece a API: escrever expectativa de tipo *no arquivo de teste* mantém o contrato perto do comportamento. Só não conte como teste executado.

| ID | Regra |
| --- | --- |
| `BUN-TEST-18` | `expectTypeOf` **NEVER** conta como verificação executada — é no-op em runtime, e o CI **MUST** rodar `tsc --noEmit` num passo separado. |

---

## 9. Snapshots

```ts
test("serializa o pedido para o gateway", => {
 expect(montarPayload(pedido)).toMatchSnapshot;
});
```

Na primeira execução, Bun grava em `__snapshots__/<arquivo>.snap`, ao lado do arquivo de teste:

```
projeto/
├── pedido.test.ts
└── __snapshots__/
 └── pedido.test.ts.snap
```

| Matcher | Onde grava |
| --- | --- |
| `toMatchSnapshot` | `__snapshots__/*.snap` |
| `toMatchInlineSnapshot` | dentro do próprio arquivo de teste, inserido automaticamente |
| `toThrowErrorMatchingSnapshot` | arquivo `.snap`, com a mensagem do erro |
| `toThrowErrorMatchingInlineSnapshot` | inline |

**Inline × arquivo:** inline serve para valor pequeno que você quer ver ao lado da asserção (uma mensagem de erro, um objeto de três chaves). Arquivo serve para payload grande — e paga o preço de o diff ficar longe do teste.

### Campos não determinísticos

```ts
expect(usuario).toMatchSnapshot({
 id: expect.any(String),
 criadoEm: expect.any(String),
});
```

Sem property matchers, um `id` aleatório ou um `new Date` fazem o snapshot falhar em **toda** execução. O que acontece na prática não é o time consertar o teste: é o time aprender a rodar `-u` por reflexo — e a partir daí o snapshot deixa de verificar qualquer coisa.

### `--update-snapshots` é comando de pessoa

`bun test -u` regenera. Ele existe para o momento em que **você mudou a saída de propósito** e vai ler o diff antes de commitar. No comando de teste do CI, ele converte o snapshot de asserção em registro: passa a gravar o que quer que o código produza, incluindo a regressão que deveria pegar.

E a outra metade: `__snapshots__/` **versionado**. Snapshot fora do repositório é gerado na primeira execução de cada máquina e passa sempre.

**Limite verificado:** serializador customizado (`expect.addSnapshotSerializer`) **não está implementado**. Valor cuja representação default é ruim (instância de classe com muito estado interno, buffer) não é bom candidato a snapshot aqui — asserte campos.

| ID | Regra |
| --- | --- |
| `BUN-TEST-05` | `--update-snapshots` (`-u`) **NEVER** aparece no comando de teste do CI, e o diretório `__snapshots__/` **MUST** estar versionado — snapshot fora do repositório não é asserção. |
| `BUN-TEST-19` | Snapshot de objeto com campo não determinístico (id gerado, data, hash) **MUST** declarar property matchers (`{ id: expect.any(String) }`) — sem isso o snapshot falha sempre e o time passa a rodar `-u` por reflexo. † |

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| `expect` dentro de `catch` sem `expect.assertions(n)` | se a função não lançar, o `catch` não roda e o teste passa sem verificar nada | `expect.assertions(1)` ou `.rejects` — `BUN-TEST-06` |
| `test("...", (done) => { … })` sem chamar `done` | o teste pendura até o timeout e falha por motivo errado | `async`/`await` — `BUN-TEST-17` |
| `test.skip` para bug conhecido | o teste some do relatório e ninguém percebe quando o bug é corrigido | `test.failing` — `BUN-TEST-11` |
| `test.only` deixado no código "porque desabilita o resto" | sem `--only` não filtra nada; se o CI passar a flag, o resto da suíte desaparece | `-t "nome"` localmente, e não commitar `.only` — `BUN-TEST-08` |
| `{ retry: 2, repeats: 5 }` no mesmo teste | a fonte declara a combinação inválida | escolher um — `BUN-TEST-16` |
| `.toThrow` sem argumento | aceita qualquer erro, inclusive o `TypeError` de você ter quebrado a chamada | passar a classe ou a mensagem |
| `try/catch` para testar rejeição de Promise | exige contagem de asserções para não passar em silêncio | `await expect(fn).rejects.toThrow(X)` |
| `expectTypeOf` como se verificasse em runtime | é no-op; o arquivo passa sem checar tipo nenhum | `tsc --noEmit` em passo separado — `BUN-TEST-18` |
| `toMatchSnapshot` sobre objeto com `id` aleatório ou `Date` | falha em toda execução, e o time aprende a rodar `-u` por reflexo | property matchers — `BUN-TEST-19` |
| `-u` no comando de teste do CI | o snapshot passa a registrar qualquer saída, inclusive a regressão | `-u` é comando de pessoa, e o diff vai para o PR — `BUN-TEST-05` |
| `__snapshots__/` no `.gitignore` | é gerado na primeira execução de cada máquina e passa sempre | versionar — `BUN-TEST-05` |
| `timeout: 0` num teste de CI | troca uma falha por um job pendurado | corrigir a causa (quase sempre `await` faltando) |
| `test.each` com `if` no corpo para tratar cada linha | a tabela deixou de ser tabela; três testes explícitos são menores | testes separados |
| Linha de objeto em `each` desestruturada como array | objeto vira **um** argumento; os parâmetros seguintes ficam `undefined` | `({ a, b }) => …` |

---

## Checklist de revisão

- [ ] Toda asserção condicional (em `catch`, callback, `if`) tem `expect.assertions(n)`? → `BUN-TEST-06`
- [ ] Nenhum teste usa `done`? → `BUN-TEST-17`
- [ ] Bugs conhecidos estão como `test.failing`, não `test.skip`? → `BUN-TEST-11`
- [ ] Nenhum `.only` commitado? → `BUN-TEST-08`
- [ ] Nenhum teste combina `retry` e `repeats`? → `BUN-TEST-16`
- [ ] `.toThrow` recebe classe ou mensagem, nunca vazio?
- [ ] Snapshots de objeto com campo variável usam property matchers? → `BUN-TEST-19`
- [ ] O CI roda sem `-u`, e `__snapshots__/` está versionado? → `BUN-TEST-05`
- [ ] Existe passo `tsc --noEmit` separado? → `BUN-TEST-18`
- [ ] `toStrictEqual` onde a forma exata do objeto é o contrato?

---

## Relacionados

- [Bun - Testes](bun-testes.md) — hub, modelo mental, mapa da API, árvores de decisão
- [Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) · [Bun - Testes - Mocks e Tempo](bun-testes-mocks-e-tempo.md) · [Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) · [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md) · [Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md)
- — o que testar, antes de como
- `TypeScript` — `tsc --noEmit` como passo de verificação

## Fontes consultadas

Verificadas em **2026-08-20**: [Writing tests](https://bun.com/docs/test/writing-tests) · [Snapshots](https://bun.com/docs/test/snapshots) · [Test runner](https://bun.com/docs/test) · [Runtime behavior](https://bun.com/docs/test/runtime-behavior) · [Jest compatibility tracking issue](https://github.com/oven-sh/bun/issues/1825) (citada pela fonte como referência de estado).
