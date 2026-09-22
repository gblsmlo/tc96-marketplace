# Antipadrões mais frequentes, com ID

> Grade de varredura rápida. Confira o corpo da regra pelo `mapa-de-ids.md`:
> a família inteira é declarada na § 6 do hub, e o corpo mora no satélite.

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| `expect` em `catch` sem contagem de asserções | `BUN-TEST-06` | [[Bun - Testes - Escrita e Asserções]] |
| `spyOn` sem `mock.restore()` garantido | `BUN-TEST-02` | [[Bun - Testes - Mocks e Tempo]] |
| Esperar que `mock.restore()` desfaça `mock.module()` | `BUN-TEST-03` | [[Bun - Testes - Mocks e Tempo]] |
| `mock.module()` no corpo do teste para evitar conexão do módulo real | `BUN-TEST-04` | [[Bun - Testes - Mocks e Tempo]] |
| `test.serial` para dependência entre **arquivos** | `BUN-TEST-09` | [[Bun - Testes - Ciclo de Vida e Isolamento]] |
| Banco, porta ou diretório compartilhado sob `--parallel` | `BUN-TEST-10` | [[Bun - Testes - Ciclo de Vida e Isolamento]] |
| `beforeAll` caro no preload com `--parallel` ligado | `BUN-TEST-24` | [[Bun - Testes - Ciclo de Vida e Isolamento]] |
| `onTestFinished` em teste concorrente | `BUN-TEST-22` | [[Bun - Testes - Ciclo de Vida e Isolamento]] |
| Teste concorrente compartilhando estado mutável | `BUN-TEST-23` | [[Bun - Testes - Ciclo de Vida e Isolamento]] |
| `test.skip` para bug conhecido | `BUN-TEST-11` | [[Bun - Testes - Escrita e Asserções]] |
| `.only` commitado "para desabilitar o resto" | `BUN-TEST-08` | [[Bun - Testes - Escrita e Asserções]] |
| `-u` no comando de CI, ou `__snapshots__/` ignorado no git | `BUN-TEST-05` | [[Bun - Testes - Escrita e Asserções]] |
| Snapshot sobre objeto com `id` aleatório ou `Date` | `BUN-TEST-19` | [[Bun - Testes - Escrita e Asserções]] |
| `expectTypeOf` tratado como verificação executada | `BUN-TEST-18` | [[Bun - Testes - Escrita e Asserções]] |
| `retry` e `repeats` no mesmo teste | `BUN-TEST-16` | [[Bun - Testes - Escrita e Asserções]] |
| Teste com parâmetro `done` | `BUN-TEST-17` | [[Bun - Testes - Escrita e Asserções]] |
| `useFakeTimers` para fixar `new Date()` | `BUN-TEST-20` | [[Bun - Testes - Mocks e Tempo]] |
| Asserção sobre data formatada sem fuso fixo | `BUN-TEST-21` | [[Bun - Testes - Mocks e Tempo]] |
| `import "@testing-library/jest-dom"` esperando os matchers | `BUN-TEST-12` | [[Bun - Testes - DOM e Componentes]] |
| `GlobalRegistrator.register()` dentro do arquivo de teste | `BUN-TEST-07` | [[Bun - Testes - DOM e Componentes]] |
| Happy-dom e Testing Library num preload só, com import estático | `BUN-TEST-25` | [[Bun - Testes - DOM e Componentes]] |
| `render` sem `cleanup()` em `afterEach` | `BUN-TEST-26` | [[Bun - Testes - DOM e Componentes]] |
| `user.click(...)` sem `await` | § 3 do satélite | [[Bun - Testes - DOM e Componentes]] |
| `coverageThreshold` só com reporter `lcov`, fora de `--parallel` | `BUN-TEST-27` | [[Bun - Testes - Cobertura e CI]] |
| Limiar de cobertura declarado em `statements` | `BUN-TEST-28` | [[Bun - Testes - Cobertura e CI]] |
| `--reporter=junit` sem `--reporter-outfile` | `BUN-TEST-29` | [[Bun - Testes - Cobertura e CI]] |
| Arquivo nomeado `*.tests.ts` ou `teste*.ts` | `BUN-TEST-01` | [[Bun - Testes - Execução e Configuração]] |
| Glob no argumento posicional, ou caminho sem `./` | `BUN-TEST-13` | [[Bun - Testes - Execução e Configuração]] |
| `seed` sem `randomize = true` | `BUN-TEST-14` | [[Bun - Testes - Execução e Configuração]] |
| `bun@latest` no CI | `BUN-TEST-15` | [[Bun - Testes - Execução e Configuração]] |
| `--changed` como portão de merge | § 3.4 do satélite | [[Bun - Testes - Execução e Configuração]] |
| `--retry` global no comando de CI | § 4 do satélite | [[Bun - Testes - Execução e Configuração]] |
| `Bun.sleep` esperando render ou timer | sem ID — ver Passo 6 | [[Bun - Testes - DOM e Componentes]] |

