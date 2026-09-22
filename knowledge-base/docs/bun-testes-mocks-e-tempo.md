---
titulo: Bun - Testes - Mocks e Tempo
Link: https://bun.com/docs/test/mocks
tags:
 - bun
 - testing
 - agent-context
source: "Documentação oficial — https://bun.com/docs/test/mocks, /dates-times, reference/bun/test/jest"
verificado-em: 2026-08-20
---

# Bun - Testes - Mocks e Tempo

> `mock`/`jest.fn`, `spyOn`, `mock.module` · a API completa de um mock (`.mock.calls`, `mockReturnValueOnce`, …) · **as três limpezas e o que cada uma não faz** · por que `mock.module` precisa do preload · injeção de dependência como alternativa ao mock · relógio: `setSystemTime`, `useFakeTimers`, avanço de timers, `TZ` · a superfície `vi` do Vitest.
>
> **Não cobre:** matchers de mock (`.toHaveBeenCalledWith`) — estão em [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) § 6 · onde o preload é declarado ([Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) § 5) · o que o escopo do preload faz sob `--parallel` ([Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) § 3).

Entrada: [Bun - Testes](bun-testes.md) · Base normativa: [Bun - Testes](bun-testes.md) § 6 · Família: `BUN-TEST-*` (esta nota é dona de `02`, `03`, `04`, `20`, `21`)

---

## 1. Conceito: mock é acoplamento declarado, não conveniência

Todo mock afirma duas coisas: *"esta unidade depende daquela"* e *"esta é a forma daquela dependência"*. A segunda é uma cópia — e cópia envelhece. Quando o gateway real muda a assinatura, o mock continua verde: o teste passa a verificar que seu código conversa corretamente com um serviço que não existe mais.

Isso não é argumento contra mock; é o critério para escolher entre as três formas que Bun oferece, em ordem de acoplamento crescente:

| Forma | O que ela acopla | Preço |
| --- | --- | --- |
| **Injeção de dependência** (passar o duplo por parâmetro) | nada além da interface que você mesmo declarou | exige que o código aceite a dependência de fora |
| `spyOn(obj, "metodo")` | o nome do método num objeto que o teste já tem em mãos | restauração é sua responsabilidade |
| `mock.module("./mod", …)` | o **caminho do módulo** — um detalhe de arranjo de arquivos | escopo de processo, não de teste (§ 4) |

A ordem dessa tabela é a ordem de preferência. Quando o código sob teste recebe suas dependências, teste não precisa de mock de módulo — e a decisão de fundo (mockar, usar um duplo, ou subir o serviço real) é de arquitetura, não de runner:.

---

## 2. `mock` e `spyOn`

```ts
import { mock, spyOn, expect } from "bun:test";

// função observável, com implementação própria
const buscarCotacao = mock(async (cep: string) => ({ cep, valor: 1990 }));

await buscarCotacao("01310-100");
expect(buscarCotacao).toHaveBeenCalledTimes(1);
expect(buscarCotacao.mock.lastCall).toEqual(["01310-100"]);

// espiar sem substituir: o método original continua rodando
const repo = new PedidoRepository;
const salvar = spyOn(repo, "salvar");

// espiar e substituir
spyOn(repo, "buscar").mockResolvedValue({ id: "p-1", status: "pago" });
```

`jest.fn` e `vi.fn` são equivalentes a `mock`. A escolha entre `mock` e `spyOn` é objetiva: **`spyOn` quando o objeto já existe e você quer observá-lo; `mock` quando você está fabricando a dependência.**

### Superfície de um mock

| Propriedade / método | O que dá |
| --- | --- |
| `.mock.calls` | array de argumentos, uma entrada por chamada |
| `.mock.results` | array de retornos, uma entrada por chamada |
| `.mock.instances` | instâncias criadas com `new` |
| `.mock.contexts` | o `this` de cada chamada |
| `.mock.lastCall` | argumentos da chamada mais recente |
| `.mockImplementation(fn)` / `.mockImplementationOnce(fn)` | define implementação — permanente / só na próxima chamada |
| `.mockReturnValue(v)` / `.mockReturnValueOnce(v)` | define retorno |
| `.mockResolvedValue(v)` / `.mockRejectedValue(e)` | define Promise resolvida / rejeitada |
| `.mockClear` | limpa histórico, **mantém** implementação |
| `.mockReset` | limpa histórico **e** remove implementação |
| `.mockRestore` | restaura a implementação original (spy) |

**`...Once` é a forma de testar sequência**: primeira chamada falha, segunda funciona — é assim que se testa retry sem esperar tempo real.

```ts
const cobrar = mock< => Promise<string>>;
cobrar.mockRejectedValueOnce(new Error("timeout")).mockResolvedValue("aprovado");

expect(await cobrarComRetry(cobrar)).toBe("aprovado");
expect(cobrar).toHaveBeenCalledTimes(2);
```

---

## 3. As três limpezas, e o que cada uma não faz

É aqui que "o teste passa sozinho e falha na suíte" nasce. Três chamadas globais, escopos diferentes:

| Chamada | Zera histórico (`.mock.calls`, `.results`, `.instances`, `.contexts`) | Remove implementação de `mockReturnValue`/`mockImplementation` | Restaura a implementação original do spy | Desfaz `mock.module` |
| --- | --- | --- | --- | --- |
| `mock.clearAllMocks` | sim | **não** | não | não |
| `jest.resetAllMocks` / `vi.resetAllMocks` | sim | sim | **não** | não |
| `mock.restore` | sim | sim | **sim** | **não** |

A última coluna é a armadilha, e a fonte é literal: `mock.restore` *"does not reset modules overridden with `mock.module`"*.

O default correto para quase todo projeto é uma linha, no preload:

```ts
// test/setup.ts → bunfig.toml: [test] preload = ["./test/setup.ts"]
import { afterEach, mock } from "bun:test";

afterEach( => {
 mock.restore;
});
```

Colocar isso no preload, e não em cada arquivo, é a recomendação da própria doc — e é o que impede que um arquivo novo, escrito por alguém que não leu esta nota, vaze spy para o resto da suíte. Sem `--isolate`, **um único global é compartilhado por todos os arquivos** ([Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) § 2): o spy não vaza para o próximo teste, vaza para a próxima *hora* de suíte.

| ID | Regra |
| --- | --- |
| `BUN-TEST-02` | `spyOn` **MUST** ter restauração garantida (`mock.restore` em `afterEach` ou no preload) — sem isso o spy vaza para os testes seguintes. |

---

## 4. `mock.module`: escopo de processo e o efeito colateral já ocorrido

```ts
mock.module("./gateway-pagamento", => ({
 cobrar: mock(async => ({ status: "aprovado" as const })),
}));
```

O que a fonte declara, e o que decorre de cada afirmação:

- **Funciona para `import` e para `require`**, e o especificador é resolvido como um import normal: caminho relativo, absoluto ou nome de pacote (`mock.module("pg", …)`).
- **Atualiza o módulo mesmo se ele já tiver sido importado** — as live bindings do ESM refletem a troca em todos os importadores existentes.
- **Mas o módulo original já foi avaliado**: *"its side effects have already happened"*. Se ele abre conexão, registra listener, lê env ou instancia cliente no topo do arquivo, isso aconteceu antes do seu mock.
- **`mock.restore` não desfaz.** O módulo continua mockado pelo resto do processo de teste.

As duas consequências operacionais são a mesma decisão vista de dois ângulos: **mock de módulo pertence ao preload.**

```toml
# bunfig.toml
[test]
preload = ["./test/mocks/gateway.ts", "./test/setup.ts"]
```

```ts
// test/mocks/gateway.ts — roda antes de qualquer arquivo de teste
import { mock } from "bun:test";

mock.module("./src/gateway-pagamento", => ({
 cobrar: mock(async => ({ status: "aprovado" as const })),
}));
```

**Não conte com hoisting.** No Vitest, `vi.mock` é içado para o topo do arquivo pelo transformador. A fonte do Bun não declara esse comportamento para `mock.module` nem para `vi.mock` — trate como **não içado**: a chamada roda onde está escrita, depois dos imports do arquivo. Quando o objetivo é impedir a avaliação do original, preload é a única garantia.

| ID | Regra |
| --- | --- |
| `BUN-TEST-03` | `mock.module` **NEVER** é desfeito por `mock.restore`; mock de módulo **MUST** ser registrado em `--preload` ou tratado como estado global do processo de teste. |
| `BUN-TEST-04` | Mock cujo objetivo é impedir efeito colateral de import (conexão, listener, leitura de env no topo) **MUST** ser registrado em `--preload` — mockar depois do import não desfaz o que já rodou. |

### A alternativa que dispensa tudo isso

```ts
// em vez de mockar o módulo, receber a dependência
export function criarServicoDePedidos(deps: { gateway: Gateway; agora: => Date }) {
 return {
 async pagar(pedido: Pedido) {
 const r = await deps.gateway.cobrar(pedido);
 return {...pedido, pagoEm: deps.agora, status: r.status };
 },
 };
}

// no teste: nenhum mock de módulo, nenhum escopo global, nenhuma restauração
const servico = criarServicoDePedidos({
 gateway: { cobrar: mock(async => ({ status: "aprovado" as const })) },
 agora: => new Date("2026-01-01T00:00:00Z"),
});
```

Isso não é dogma de arquitetura: é a forma de teste que **não tem escopo global para vazar**. Quando um módulo é mockado por três arquivos de teste diferentes, o sinal costuma ser que a dependência queria ser parâmetro.

---

## 5. Tempo: congelar, avançar e o fuso

Duas necessidades distintas, e APIs distintas:

| Preciso de | API |
| --- | --- |
| Uma data fixa (`new Date`, `Date.now`, `Intl.DateTimeFormat`) | `setSystemTime(date)` |
| Fazer o tempo **passar** (`setTimeout`, `setInterval`, debounce, polling) | `jest.useFakeTimers` + `jest.advanceTimersByTime(ms)` |

```ts
import { test, expect, jest, setSystemTime } from "bun:test";

test("marca o pedido com a data de pagamento", => {
 setSystemTime(new Date("2026-01-01T00:00:00.000Z"));
 expect(pagar(pedido).pagoEm.toISOString).toBe("2026-01-01T00:00:00.000Z");
 setSystemTime; // sem argumento: volta ao relógio real
});

test("debounce dispara uma vez após 300 ms", => {
 jest.useFakeTimers;
 const cb = jest.fn;
 const enviar = debounce(cb, 300);

 enviar; enviar; enviar;
 expect(cb).not.toHaveBeenCalled;

 jest.advanceTimersByTime(300);
 expect(cb).toHaveBeenCalledTimes(1);

 jest.useRealTimers;
});
```

Superfície verificada: `jest.useFakeTimers` (aceita `'modern'`, `'legacy'` ou `{ now }`), `jest.useRealTimers`, `jest.setSystemTime` / `setSystemTime`, `jest.now`, `jest.advanceTimersByTime(ms)`, `advanceTimersToNextTimer`, `runAllTimers`, `getTimerCount`, `clearAllTimers`.

### A diferença em relação ao Jest que muda o código

**Em `bun:test`, `useFakeTimers` não substitui o construtor `Date`.** A fonte declara isso explicitamente, e o motivo é evitar a classe de bug em que `Date !== Date` depois de ligar os fake timers — código que faz `instanceof Date` ou compara construtores quebra sob o Jest e não quebra aqui.

O que decorre: **para fixar uma data, `setSystemTime` é a API, não `useFakeTimers`.** As duas coisas são ortogonais — uma controla *que hora é*, a outra controla *se o tempo anda*. Elas se combinam, e `jest.setSystemTime` funciona junto de `advanceTimersByTime`.

> **Divergência de fonte registrada.** O post de release da 1.4 descreve `jest.useFakeTimers` como controlando *"`setTimeout`, `setInterval`, and `Date`"*, enquanto a página de datas e horas afirma que o construtor `Date` **não** muda com `useFakeTimers`. As duas frases convivem se lidas como planos diferentes — o relógio que `Date.now` consulta passa a ser o falso; a *identidade* do construtor não é trocada — mas a formulação do post é solta. Esta nota segue a página de datas e horas, que é a específica.

Detalhe fino verificado: desde a 1.3.6, `advanceTimersByTime(0)` dispara callbacks de `setTimeout(fn, 0)` — que internamente são agendados com 1 ms, conforme a spec HTML. E bibliotecas de teste de componente (`@testing-library/react`) detectam fake timers e avançam o relógio em vez de esperar tempo real.

### Fuso horário

O runner define `TZ=Etc/UTC` quando `TZ` não está no ambiente ([Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) § 6). Isso torna a suíte determinística **na sua máquina e no CI** — e deixa uma dependência implícita: o mesmo teste roda diferente num ambiente que define `TZ`.

```bash
TZ=America/Sao_Paulo bun test./src/relatorio.test.ts
```

```ts
process.env.TZ = "America/Sao_Paulo"; // vale a partir daqui, no mesmo processo
```

Ao contrário do Jest, o fuso pode ser trocado **várias vezes durante a mesma execução** e o efeito é imediato — o que permite testar formatação em dois fusos no mesmo arquivo. O que não muda: asserção sobre data ou hora *formatada* precisa dizer em que fuso ela vale.

| ID | Regra |
| --- | --- |
| `BUN-TEST-20` | Congelar data **MUST** usar `setSystemTime` — `useFakeTimers` não troca o construtor `Date` em `bun:test`, ao contrário do Jest. |
| `BUN-TEST-21` | Asserção sobre data ou hora **formatada** **MUST** fixar o fuso explicitamente (`TZ` no comando, ou `process.env.TZ` no teste) — o `Etc/UTC` do runner só vale enquanto `TZ` não estiver definida no ambiente. † |

---

## 6. A superfície `vi`, para quem chega do Vitest

O objeto `vi` existe como global e imports de `vitest` são reescritos internamente para `bun:test`. O subconjunto verificado:

| Vitest | Em `bun:test` | Diferença que importa |
| --- | --- | --- |
| `vi.fn` | `vi.fn` / `mock` | — |
| `vi.spyOn` | `vi.spyOn` / `spyOn` | — |
| `vi.mock("./mod", factory)` | `vi.mock` existe; a forma nativa é `mock.module` | **não assuma hoisting** — § 4 |
| `vi.clearAllMocks` | `mock.clearAllMocks` | escopos diferentes dos do Vitest — ler a tabela da § 3 |
| `vi.resetAllMocks` | `jest.resetAllMocks` / `vi.resetAllMocks` | idem |
| `vi.restoreAllMocks` | `mock.restore` | **não** desfaz `mock.module` |
| `vi.useFakeTimers` | `jest.useFakeTimers` | `Date` não é reconstruído — § 5 |
| `vi.setSystemTime` | `setSystemTime` / `jest.setSystemTime` | — |
| `vi.advanceTimersByTime` | `jest.advanceTimersByTime` | — |

O mapa completo de migração (incluindo configuração, que é a parte que **não** migra) está em [Bun - Testes](bun-testes.md) § 5.4.

---

## Antipadrões

| Antipadrão | Por que falha | O que fazer |
| --- | --- | --- |
| `spyOn` sem `mock.restore` em `afterEach` | sem `--isolate` o global é compartilhado por todos os arquivos; o spy vaza para a suíte inteira | `afterEach( => mock.restore)` no preload — `BUN-TEST-02` |
| Esperar que `mock.restore` desfaça `mock.module` | a fonte é explícita: não desfaz; o módulo segue mockado no processo | registrar no preload e tratar como global — `BUN-TEST-03` |
| `mock.module` no corpo do teste para evitar a conexão do módulo real | o módulo já foi avaliado no import; a conexão já abriu | `--preload` / `[test] preload` — `BUN-TEST-04` |
| Assumir que `mock.module`/`vi.mock` é içado como no Vitest | a fonte não declara hoisting; a chamada roda depois dos imports | preload — `BUN-TEST-04` |
| `mock.clearAllMocks` esperando que a implementação volte | ela zera histórico e **mantém** a implementação | `mock.restore` — § 3 |
| `jest.resetAllMocks` esperando restaurar o método original do spy | reset remove implementação, não restaura o original | `mock.restore` — § 3 |
| `useFakeTimers` para fixar `new Date` | o construtor `Date` não é trocado em `bun:test` | `setSystemTime(date)` — `BUN-TEST-20` |
| Asserção sobre data formatada sem declarar fuso | passa por herdar `TZ=Etc/UTC` e quebra em ambiente que define `TZ` | fixar `TZ` — `BUN-TEST-21` |
| `await Bun.sleep(400)` para esperar um debounce | teste com sleep é lento e flaky | `useFakeTimers` + `advanceTimersByTime` — § 5 |
| Mockar o mesmo módulo em três arquivos de teste | o mock virou a interface real, sem ninguém ter decidido isso | receber a dependência por parâmetro — § 4 |
| Mock de módulo cuja forma nunca é conferida contra o real | o teste verifica conversa com um serviço que não existe mais | teste de contrato / integração à parte — |

---

## Checklist de revisão

- [ ] Existe `mock.restore` em `afterEach` (de preferência no preload)? → `BUN-TEST-02`
- [ ] Nenhum `mock.module` conta com restauração automática? → `BUN-TEST-03`
- [ ] Mocks que evitam efeito de import estão no preload? → `BUN-TEST-04`
- [ ] Nenhum código depende de hoisting de `mock.module`/`vi.mock`? → `BUN-TEST-04`
- [ ] Datas fixas usam `setSystemTime`, não `useFakeTimers`? → `BUN-TEST-20`
- [ ] Asserções sobre data formatada declaram o fuso? → `BUN-TEST-21`
- [ ] Nenhum `sleep` esperando timer? → § 5
- [ ] Cada mock de módulo tem justificativa que a injeção de dependência não resolveria? → § 4

---

## Relacionados

- [Bun - Testes](bun-testes.md) — hub, modelo mental, mapa da API, árvores de decisão
- [Bun - Testes - Execução e Configuração](bun-testes-execucao-e-configuracao.md) · [Bun - Testes - Escrita e Asserções](bun-testes-escrita-e-assercoes.md) · [Bun - Testes - Ciclo de Vida e Isolamento](bun-testes-ciclo-de-vida-e-isolamento.md) · [Bun - Testes - DOM e Componentes](bun-testes-dom-e-componentes.md) · [Bun - Testes - Cobertura e CI](bun-testes-cobertura-e-ci.md)
- — mock, duplo ou serviço real
- — o que testar, antes de como

## Fontes consultadas

Verificadas em **2026-08-20**: [Mocks](https://bun.com/docs/test/mocks) · [Dates and times](https://bun.com/docs/test/dates-times) · [`jest` object](https://bun.com/reference/bun/test/jest) · [`useFakeTimers`](https://bun.com/reference/bun/test/jest/useFakeTimers) · [`advanceTimersByTime`](https://bun.com/reference/bun/test/jest/advanceTimersByTime) · [`vi` property](https://bun.com/reference/bun/test/vi) · [Bun 1.4](https://bun.com/blog/bun-v1.4) e [Bun v1.3.6](https://bun.com/blog/bun-v1.3.6) (fake timers).
