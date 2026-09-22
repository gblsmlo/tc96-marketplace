# As seis tarefas

> Cada recorte assume que o Carregamento mínimo já aconteceu e **nomeia o satélite que falta**.
> O conteúdo do satélite não é repetido aqui — é citado.

## Mapa de tarefa → nota

| A tarefa é… | Satélite | Árvore |
| --- | --- | --- |
| escrever teste, escolher matcher, modificador, snapshot | [Bun - Testes - Escrita e Asserções](../../../../knowledge-base/docs/bun-testes-escrita-e-assercoes.md) | — |
| substituir dependência: mock, spy, duplo | [Bun - Testes - Mocks e Tempo](../../../../knowledge-base/docs/bun-testes-mocks-e-tempo.md) | § 5.2 |
| congelar data, avançar timer, fuso | [Bun - Testes - Mocks e Tempo](../../../../knowledge-base/docs/bun-testes-mocks-e-tempo.md) | § 5.3 |
| testar componente React, DOM, interação | [Bun - Testes - DOM e Componentes](../../../../knowledge-base/docs/bun-testes-dom-e-componentes.md) | § 5.6 |
| hooks, preload, escopo de setup | [Bun - Testes - Ciclo de Vida e Isolamento](../../../../knowledge-base/docs/bun-testes-ciclo-de-vida-e-isolamento.md) | — |
| `bunfig.toml [test]`, descoberta, filtros | [Bun - Testes - Execução e Configuração](../../../../knowledge-base/docs/bun-testes-execucao-e-configuracao.md) | — |
| cobertura, reporter, workflow de CI | [Bun - Testes - Cobertura e CI](../../../../knowledge-base/docs/bun-testes-cobertura-e-ci.md) | § 5.5 |
| vim do Jest ou do Vitest | [Bun - Testes](../../../../knowledge-base/docs/bun-testes.md) § 5.4 (mapa de equivalência) | § 5.4 |

---

Seis recortes. Cada um assume que o Carregamento mínimo já aconteceu e nomeia o satélite que falta — não repita o conteúdo do satélite aqui, cite-o.

### 1. Escrever teste novo

1. **Nome do arquivo primeiro.** `*.test.ts`, `*_test.ts`, `*.spec.ts` ou `*_spec.ts` — `BUN-TEST-01`. Arquivo fora do padrão não roda e nada avisa.
2. **Importe de `bun:test`**, não confie nos globais: é o que passa em `tsc --noEmit` sem declaração global.
3. **Nomeie o `describe` pela unidade sob teste** — o rótulo dele é o endereço de `-t`.
4. **Toda asserção condicional declara contagem.** `expect` dentro de `catch`, callback ou `if` exige `expect.assertions(n)` — `BUN-TEST-06`. Para rejeição de Promise, prefira `await expect(fn).rejects.toThrow(X)`.
5. **Escolha a igualdade:** `toBe` para primitivo e identidade, `toEqual` para objeto, `toStrictEqual` quando a forma exata é o contrato.
6. **`.toThrow` sempre com classe ou mensagem** — sem argumento, ele aceita o `TypeError` de você ter quebrado a chamada.
7. **Assíncrono é `async`/`await`.** Nunca `done` — `BUN-TEST-17`.
8. **Instabilidade declarada usa `{ retry: N }` no teste**, nunca `--retry` global — e `retry` com `repeats` é combinação inválida, `BUN-TEST-16`.
9. **Bug conhecido é `test.failing`**, nunca `test.skip` — `BUN-TEST-11`. E nenhum `.only` sai do seu terminal — `BUN-TEST-08`.
10. **Snapshot só com campo determinístico**, ou com property matchers — `BUN-TEST-19`.

### 2. Substituir uma dependência

Percorra a árvore da § 5.2 do hub, nesta ordem de preferência:

1. **O código recebe a dependência de fora?** Passe um duplo. Sem mock, sem escopo global, sem restauração — é a saída que não tem o que vazar.
2. **É método de objeto que o teste tem em mãos?** `spyOn`, **com restauração garantida** no preload — `BUN-TEST-02`.
3. **É módulo importado?** `mock.module`, e então duas decisões obrigatórias:
 - se o objetivo é impedir efeito colateral do import (conexão, listener, env no topo), o registro vai em `[test] preload` — `BUN-TEST-04`. Não há outra forma: o original já foi avaliado;
 - `mock.restore` **não** desfaz — o módulo fica mockado no resto do processo — `BUN-TEST-03`.

Sinal de parada: se três arquivos mockam o mesmo módulo, a dependência queria ser parâmetro. Diga isso em vez de escrever o quarto mock.

### 3. Controlar data e tempo

| Preciso de | API | Regra |
| --- | --- | --- |
| data fixa | `setSystemTime(new Date(...))` | `BUN-TEST-20` — `useFakeTimers` **não** troca o construtor `Date` |
| tempo passar (debounce, polling, retry) | `jest.useFakeTimers` + `advanceTimersByTime(ms)` | — |
| asserção sobre data **formatada** | fixar `TZ` explicitamente | `BUN-TEST-21` |

`Bun.sleep` para esperar timer não entra em teste.

### 4. Testar componente React

Verifique a receita completa em [Bun - Testes - DOM e Componentes](../../../../knowledge-base/docs/bun-testes-dom-e-componentes.md) § 2 antes de escrever a primeira linha — ela tem quatro peças, e três falham em silêncio se faltarem:

1. `GlobalRegistrator.register` em preload, nunca no arquivo de teste — `BUN-TEST-07`;
2. **dois** preloads, nesta ordem: happy-dom, depois `@testing-library/*` — `BUN-TEST-25`;
3. `expect.extend(matchers)` de `@testing-library/jest-dom/matchers` — o `import` do pacote sozinho **não registra nada**, `BUN-TEST-12`;
4. `cleanup` em `afterEach` — `BUN-TEST-26`.

Ao escrever: `await` em todo `userEvent`, `findBy*` para esperar elemento, `waitFor` só para condição que não é "elemento existe". Antes de asserir sobre asset, `import.meta.env` ou CSS, leia § 4 do satélite — é a fronteira com o Vite, e a saída costuma ser receber configuração por prop.

### 5. Configurar a suíte de um projeto

1. `bunfig.toml`, seção `[test]` — a superfície completa está em [Bun - Testes - Execução e Configuração](../../../../knowledge-base/docs/bun-testes-execucao-e-configuracao.md) § 5.
2. Um preload com `afterEach( => mock.restore)`. É a linha que impede que um arquivo escrito por quem não leu a doc vaze spy para a suíte inteira.
3. Scripts: `test` **sem flag obrigatória** (o resto vai no `bunfig.toml`), `test:watch`, `test:changed`, `test:ci`, `typecheck`.
4. Se houver componente, os dois preloads de DOM (tarefa 4).
5. `seed` só com `randomize = true` — `BUN-TEST-14`.
6. Recorte com `root`/`pathIgnorePatterns`, não com glob no comando — `BUN-TEST-13`.
7. Setup declarado em preload é **idempotente e barato, ou parametrizado por worker** — `BUN-TEST-24`. Servidor ou migração no preload é o erro que só aparece quando alguém liga `--parallel`.

### 6. Montar o comando de CI

Receita em [Bun - Testes - Cobertura e CI](../../../../knowledge-base/docs/bun-testes-cobertura-e-ci.md) § 5. As decisões que não são negociáveis:

- versão do Bun **pinada** — `BUN-TEST-15`;
- `bun ci`, não `bun install` — `BUN-PKG-02`;
- `tsc --noEmit` como passo próprio — `BUN-TEST-18`, porque `expectTypeOf` é no-op em runtime;
- `--parallel`, e então recurso externo derivado de `BUN_TEST_WORKER_ID` — `BUN-TEST-10`;
- sem `-u` — `BUN-TEST-05` — e sem `--retry` global;
- se houver `coverageThreshold`, o reporter `text` fica na lista — `BUN-TEST-27` — e o limiar usa `lines`/`functions`, nunca `statements` — `BUN-TEST-28`;
- `--reporter=junit` sempre com `--reporter-outfile` — `BUN-TEST-29`;
- `--changed` no job de PR, **nunca** como portão de merge.

---

## Relacionados

- [Bun - Testes](../../../../knowledge-base/docs/bun-testes.md) § 5 — as árvores de decisão
- `armadilhas-do-runner.md` — o que não se assume de memória
- `autoverificacao.md` — o que conferir antes de entregar
