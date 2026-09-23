# Antipatterns, with IDs

> Check the **path** before citing `SB-TS-*` or `SB-RV-*`.

| Antipattern | ID | Satellite |
| --- | --- | --- |
| Prescribing `parameters.tanstack.*` without reading `framework` | `SB-RV-04` | [Storybook - React Vite](../../../../knowledge-base/storybook-react-vite.md) |
| A manual `RouterProvider` under `tanstack-react` | `SB-TS-03` | [Storybook - TanStack React](../../../../knowledge-base/storybook-tanstack-react.md) |
| Citing `SB-TS-*` in a `react-vite` project (or the reverse) | § 6.2 of the hub | [Storybook](../../../../knowledge-base/storybook.md) |
| `expect` without `await` in the `play` | `SB-TEST-01` | [Storybook - Testes e Interações](../../../../knowledge-base/storybook-testes-e-interacoes.md) |
| `getBy…` as the first query in an async story | `SB-TEST-10` | [Storybook - Testes e Interações](../../../../knowledge-base/storybook-testes-e-interacoes.md) |
| A spy created inside the `play` instead of `fn` in `args` | `SB-TEST-03` | [Storybook - Testes e Interações](../../../../knowledge-base/storybook-testes-e-interacoes.md) |
| `mount` not called with setup before the render | `SB-TEST-02` | [Storybook - Testes e Interações](../../../../knowledge-base/storybook-testes-e-interacoes.md) |
| Asserting internal state or render counts | `SB-TEST-09` | [Storybook - Testes e Interações](../../../../knowledge-base/storybook-testes-e-interacoes.md) |
| Querying by class or `data-testid` where a role exists | `SB-TEST-06` | [Storybook - Testes e Interações](../../../../knowledge-base/storybook-testes-e-interacoes.md) |
| Dispatching an event by hand instead of `userEvent` | `SB-TEST-08` | [Storybook - Testes e Interações](../../../../knowledge-base/storybook-testes-e-interacoes.md) |
| A whole project on `a11y.test: 'todo'` | `SB-TEST-04` | [Storybook - Testes e Interações](../../../../knowledge-base/storybook-testes-e-interacoes.md) |
| Expecting `bun test` to run stories | `SB-TEST-05` | [Storybook - Testes e Interações](../../../../knowledge-base/storybook-testes-e-interacoes.md) |
| Story state embedded in `render` | `SB-CSF-04` | [Storybook - Stories e Args](../../../../knowledge-base/storybook-stories-e-args.md) |
| A computed or template-string `title` | `SB-CSF-03` | [Storybook - Stories e Args](../../../../knowledge-base/storybook-stories-e-args.md) |
| `Meta`/`StoryObj` from the renderer instead of the framework | `SB-CORE-02` | [Storybook](../../../../knowledge-base/storybook.md) |
| `@storybook/test` in new code | `SB-CORE-01` | [Storybook](../../../../knowledge-base/storybook.md) |
| A side effect in the story module's body | `SB-CORE-06` | [Storybook](../../../../knowledge-base/storybook.md) |
| A story that depends on another having run | `SB-CORE-05` | [Storybook](../../../../knowledge-base/storybook.md) |
| `sb.mock` inside the story file | `SB-MOCK-01` | [Storybook - Mocking](../../../../knowledge-base/storybook-mocking.md) |
| Mock behavior at the top of the module | `SB-MOCK-04` | [Storybook - Mocking](../../../../knowledge-base/storybook-mocking.md) |
| `__mocks__` written in TypeScript | `SB-MOCK-03` | [Storybook - Mocking](../../../../knowledge-base/storybook-mocking.md) |
| The mocked response's shape retyped by hand | `SB-MOCK-07` | [Storybook - Mocking](../../../../knowledge-base/storybook-mocking.md) |
| Mocking `fetch` by hand instead of MSW | § 3 of the satellite | [Storybook - Mocking](../../../../knowledge-base/storybook-mocking.md) |
| A `beforeEach` that changes the environment without returning the cleanup | `SB-CTX-08` | [Storybook - Decorators e Contexto](../../../../knowledge-base/storybook-decorators-e-contexto.md) |
| Shared mutable state without a reset | `SB-CTX-04` | [Storybook - Decorators e Contexto](../../../../knowledge-base/storybook-decorators-e-contexto.md) |
| `globals` used where `args` was correct | `SB-CTX-05` | [Storybook - Decorators e Contexto](../../../../knowledge-base/storybook-decorators-e-contexto.md) |
| A decorator wrapping what the framework already wraps | `SB-CTX-06` | [Storybook - Decorators e Contexto](../../../../knowledge-base/storybook-decorators-e-contexto.md) |
| A `packages/ui` component that requires a router to render | `SB-TS-08` / `SB-RV-06` | the path note |
| `QueryClient` without `retry: false` | `SB-TS-05` | [Storybook - TanStack React](../../../../knowledge-base/storybook-tanstack-react.md) |
| Trying to render a React Server Component | `SB-TS-06` | [Storybook - TanStack React](../../../../knowledge-base/storybook-tanstack-react.md) |
| A shared router at the top of the module under `react-vite` | `SB-RV-03` | [Storybook - React Vite](../../../../knowledge-base/storybook-react-vite.md) |

