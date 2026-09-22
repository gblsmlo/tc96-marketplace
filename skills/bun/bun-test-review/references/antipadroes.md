# Antipadrões mais frequentes, com ID

> Grade de varredura rápida. Confira o corpo da regra pelo `mapa-de-ids.md`:
> a família inteira é declarada na § 6 do hub, e o corpo mora no satélite.

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| `expect` em `catch` sem contagem de asserções | `BUN-TEST-06` | [Bun - Testes - Escrita e Asserções](../../../../knowledge-base/docs/bun-testes-escrita-e-assercoes.md) |
| `spyOn` sem `mock.restore` garantido | `BUN-TEST-02` | [Bun - Testes - Mocks e Tempo](../../../../knowledge-base/docs/bun-testes-mocks-e-tempo.md) |
| Esperar que `mock.restore` desfaça `mock.module` | `BUN-TEST-03` | [Bun - Testes - Mocks e Tempo](../../../../knowledge-base/docs/bun-testes-mocks-e-tempo.md) |
| `mock.module` no corpo do teste para evitar conexão do módulo real | `BUN-TEST-04` | [Bun - Testes - Mocks e Tempo](../../../../knowledge-base/docs/bun-testes-mocks-e-tempo.md) |
| `test.serial` para dependência entre **arquivos** | `BUN-TEST-09` | [Bun - Testes - Ciclo de Vida e Isolamento](../../../../knowledge-base/docs/bun-testes-ciclo-de-vida-e-isolamento.md) |
| Banco, porta ou diretório compartilhado sob `--parallel` | `BUN-TEST-10` | [Bun - Testes - Ciclo de Vida e Isolamento](../../../../knowledge-base/docs/bun-testes-ciclo-de-vida-e-isolamento.md) |
| `beforeAll` caro no preload com `--parallel` ligado | `BUN-TEST-24` | [Bun - Testes - Ciclo de Vida e Isolamento](../../../../knowledge-base/docs/bun-testes-ciclo-de-vida-e-isolamento.md) |
| `onTestFinished` em teste concorrente | `BUN-TEST-22` | [Bun - Testes - Ciclo de Vida e Isolamento](../../../../knowledge-base/docs/bun-testes-ciclo-de-vida-e-isolamento.md) |
| Teste concorrente compartilhando estado mutável | `BUN-TEST-23` | [Bun - Testes - Ciclo de Vida e Isolamento](../../../../knowledge-base/docs/bun-testes-ciclo-de-vida-e-isolamento.md) |
| `test.skip` para bug conhecido | `BUN-TEST-11` | [Bun - Testes - Escrita e Asserções](../../../../knowledge-base/docs/bun-testes-escrita-e-assercoes.md) |
| `.only` commitado "para desabilitar o resto" | `BUN-TEST-08` | [Bun - Testes - Escrita e Asserções](../../../../knowledge-base/docs/bun-testes-escrita-e-assercoes.md) |
| `-u` no comando de CI, ou `__snapshots__/` ignorado no git | `BUN-TEST-05` | [Bun - Testes - Escrita e Asserções](../../../../knowledge-base/docs/bun-testes-escrita-e-assercoes.md) |
| Snapshot sobre objeto com `id` aleatório ou `Date` | `BUN-TEST-19` | [Bun - Testes - Escrita e Asserções](../../../../knowledge-base/docs/bun-testes-escrita-e-assercoes.md) |
| `expectTypeOf` tratado como verificação executada | `BUN-TEST-18` | [Bun - Testes - Escrita e Asserções](../../../../knowledge-base/docs/bun-testes-escrita-e-assercoes.md) |
| `retry` e `repeats` no mesmo teste | `BUN-TEST-16` | [Bun - Testes - Escrita e Asserções](../../../../knowledge-base/docs/bun-testes-escrita-e-assercoes.md) |
| Teste com parâmetro `done` | `BUN-TEST-17` | [Bun - Testes - Escrita e Asserções](../../../../knowledge-base/docs/bun-testes-escrita-e-assercoes.md) |
| `useFakeTimers` para fixar `new Date` | `BUN-TEST-20` | [Bun - Testes - Mocks e Tempo](../../../../knowledge-base/docs/bun-testes-mocks-e-tempo.md) |
| Asserção sobre data formatada sem fuso fixo | `BUN-TEST-21` | [Bun - Testes - Mocks e Tempo](../../../../knowledge-base/docs/bun-testes-mocks-e-tempo.md) |
| `import "@testing-library/jest-dom"` esperando os matchers | `BUN-TEST-12` | [Bun - Testes - DOM e Componentes](../../../../knowledge-base/docs/bun-testes-dom-e-componentes.md) |
| `GlobalRegistrator.register` dentro do arquivo de teste | `BUN-TEST-07` | [Bun - Testes - DOM e Componentes](../../../../knowledge-base/docs/bun-testes-dom-e-componentes.md) |
| Happy-dom e Testing Library num preload só, com import estático | `BUN-TEST-25` | [Bun - Testes - DOM e Componentes](../../../../knowledge-base/docs/bun-testes-dom-e-componentes.md) |
| `render` sem `cleanup` em `afterEach` | `BUN-TEST-26` | [Bun - Testes - DOM e Componentes](../../../../knowledge-base/docs/bun-testes-dom-e-componentes.md) |
| `user.click(...)` sem `await` | § 3 do satélite | [Bun - Testes - DOM e Componentes](../../../../knowledge-base/docs/bun-testes-dom-e-componentes.md) |
| `coverageThreshold` só com reporter `lcov`, fora de `--parallel` | `BUN-TEST-27` | [Bun - Testes - Cobertura e CI](../../../../knowledge-base/docs/bun-testes-cobertura-e-ci.md) |
| Limiar de cobertura declarado em `statements` | `BUN-TEST-28` | [Bun - Testes - Cobertura e CI](../../../../knowledge-base/docs/bun-testes-cobertura-e-ci.md) |
| `--reporter=junit` sem `--reporter-outfile` | `BUN-TEST-29` | [Bun - Testes - Cobertura e CI](../../../../knowledge-base/docs/bun-testes-cobertura-e-ci.md) |
| Arquivo nomeado `*.tests.ts` ou `teste*.ts` | `BUN-TEST-01` | [Bun - Testes - Execução e Configuração](../../../../knowledge-base/docs/bun-testes-execucao-e-configuracao.md) |
| Glob no argumento posicional, ou caminho sem `./` | `BUN-TEST-13` | [Bun - Testes - Execução e Configuração](../../../../knowledge-base/docs/bun-testes-execucao-e-configuracao.md) |
| `seed` sem `randomize = true` | `BUN-TEST-14` | [Bun - Testes - Execução e Configuração](../../../../knowledge-base/docs/bun-testes-execucao-e-configuracao.md) |
| `bun@latest` no CI | `BUN-TEST-15` | [Bun - Testes - Execução e Configuração](../../../../knowledge-base/docs/bun-testes-execucao-e-configuracao.md) |
| `--changed` como portão de merge | § 3.4 do satélite | [Bun - Testes - Execução e Configuração](../../../../knowledge-base/docs/bun-testes-execucao-e-configuracao.md) |
| `--retry` global no comando de CI | § 4 do satélite | [Bun - Testes - Execução e Configuração](../../../../knowledge-base/docs/bun-testes-execucao-e-configuracao.md) |
| `Bun.sleep` esperando render ou timer | sem ID — ver Passo 6 | [Bun - Testes - DOM e Componentes](../../../../knowledge-base/docs/bun-testes-dom-e-componentes.md) |

