# Self-check before delivering

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/storybook-test/scripts/autoverificar.sh src
```

| # | Check | Rule |
| --- | --- | --- |
| 1 | the `framework` was read before any router prescription | `SB-CFG-01` |
| 2 | no `SB-TS-*` prescribed in a `react-vite` project, and vice versa | § 6.2 of the hub |
| 3 | every `expect` has `await` | `SB-TEST-01` |
| 4 | the first query of an async story is `findBy…` | `SB-TEST-10` |
| 5 | the callback is `fn` in `args`, not a function in `render` | `SB-TEST-03` |
| 6 | `mount` destructured and called, if there is setup before the render | `SB-TEST-02` |
| 7 | no assertion about internal implementation | `SB-TEST-09` |
| 8 | queries by role/label, not by class or an unnecessary test id | `SB-TEST-06` |
| 9 | what distinguishes the story is `args` | `SB-CSF-04` |
| 10 | `sb.mock` only in the preview; behavior in `beforeEach` | `SB-MOCK-01`, `SB-MOCK-04` |
| 11 | a `beforeEach` that changes the environment returns the cleanup | `SB-CTX-08` |
| 12 | utilities from `storybook/test`, without the `@` | `SB-CORE-01` |
| 13 | `a11y.test` is `'error'` where CI is expected to fail | `SB-TEST-04` |
| 14 | the `Meta`/`StoryObj` import is from the framework's package | `SB-CORE-02` |

And the check worth more than the fourteen: **break the component on purpose and confirm the story goes red.** Invert a condition, remove the handler. If nothing breaks, the `play` asserts nothing — `TS-TEC-08` in [Teste de Software - Técnicas de Design de Caso](../../../../knowledge-base/teste-de-software-tecnicas-de-design-de-caso.md).

**Then run:** `vitest run --project=storybook`. Not `vitest` — without `run` it enters watch mode.
