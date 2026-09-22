# Antipadrões, com ID

> Confira o **caminho** antes de citar `SB-TS-*` ou `SB-RV-*`.

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| Prescrever `parameters.tanstack.*` sem ler `framework` | `SB-RV-04` | [[Storybook - React Vite]] |
| `RouterProvider` manual sob `tanstack-react` | `SB-TS-03` | [[Storybook - TanStack React]] |
| Citar `SB-TS-*` num projeto `react-vite` (ou o inverso) | § 6.2 do hub | [[Storybook]] |
| `expect` sem `await` na `play` | `SB-TEST-01` | [[Storybook - Testes e Interações]] |
| `getBy…` como primeira query em story assíncrona | `SB-TEST-10` | [[Storybook - Testes e Interações]] |
| Spy criado dentro da `play` em vez de `fn()` em `args` | `SB-TEST-03` | [[Storybook - Testes e Interações]] |
| `mount` não chamado com setup antes do render | `SB-TEST-02` | [[Storybook - Testes e Interações]] |
| Asseverar estado interno ou contagem de render | `SB-TEST-09` | [[Storybook - Testes e Interações]] |
| Query por classe ou `data-testid` onde existe papel | `SB-TEST-06` | [[Storybook - Testes e Interações]] |
| Disparar evento na mão em vez de `userEvent` | `SB-TEST-08` | [[Storybook - Testes e Interações]] |
| Projeto inteiro em `a11y.test: 'todo'` | `SB-TEST-04` | [[Storybook - Testes e Interações]] |
| Esperar que `bun test` execute stories | `SB-TEST-05` | [[Storybook - Testes e Interações]] |
| Estado da story embutido em `render` | `SB-CSF-04` | [[Storybook - Stories e Args]] |
| `title` computado ou por template string | `SB-CSF-03` | [[Storybook - Stories e Args]] |
| `Meta`/`StoryObj` do renderer em vez do framework | `SB-CORE-02` | [[Storybook]] |
| `@storybook/test` em código novo | `SB-CORE-01` | [[Storybook]] |
| Efeito colateral no corpo do módulo de story | `SB-CORE-06` | [[Storybook]] |
| Story que depende de outra ter rodado | `SB-CORE-05` | [[Storybook]] |
| `sb.mock()` dentro do arquivo de story | `SB-MOCK-01` | [[Storybook - Mocking]] |
| Comportamento de mock no topo do módulo | `SB-MOCK-04` | [[Storybook - Mocking]] |
| `__mocks__` escrito em TypeScript | `SB-MOCK-03` | [[Storybook - Mocking]] |
| Shape da resposta mockada redigitado à mão | `SB-MOCK-07` | [[Storybook - Mocking]] |
| Mockar `fetch` na mão em vez de MSW | § 3 do satélite | [[Storybook - Mocking]] |
| `beforeEach` que altera ambiente sem retornar limpeza | `SB-CTX-08` | [[Storybook - Decorators e Contexto]] |
| Estado mutável compartilhado sem reset | `SB-CTX-04` | [[Storybook - Decorators e Contexto]] |
| `globals` usado onde o correto era `args` | `SB-CTX-05` | [[Storybook - Decorators e Contexto]] |
| Decorator embrulhando o que o framework já embrulha | `SB-CTX-06` | [[Storybook - Decorators e Contexto]] |
| Componente de `packages/ui` que exige router para renderizar | `SB-TS-08` / `SB-RV-06` | a nota do caminho |
| `QueryClient` sem `retry: false` | `SB-TS-05` | [[Storybook - TanStack React]] |
| Tentar renderizar React Server Component | `SB-TS-06` | [[Storybook - TanStack React]] |
| Router compartilhado no topo do módulo sob `react-vite` | `SB-RV-03` | [[Storybook - React Vite]] |

