# Environment and structure

> Steps 4 and 5. The trees are § 5.4 of the [Playwright](../../../../knowledge-base/docs/playwright.md) hub.

---

## What to replace

One question decides it:

> **If the real dependency diverged, should this test break?**
> Yes → do not replace it. No → replace it.

| Replace | How | Rule |
| --- | --- | --- |
| a third party I do not own | `page.route(…)` + `fulfill` | `PW-NET-01` |
| a real response with one adjustment | `route.fetch` + `fulfill({ response, json })` | — |
| a browser API | `page.addInitScript` **before** the `goto` | `PW-NET-02` |
| clock and randomness | `page.clock` | `PW-NET-07` |
| the session | `storageState` through a setup project | `PW-AUTH-01` |
| **none of the above: server state** | create it for real through `request` | `PW-NET-06` |

A mock that reproduces the shape of a response **derives from the type exported by the server**, never
retyped by hand (`PW-NET-04`) — `elysia-schema`, or Hono through Context7, `/websites/hono_dev`.

---

## Structure

| You need… | Use | Rule |
| --- | --- | --- |
| a sequence of actions on one screen | a page object, `readonly` locators in the constructor | `PW-STR-01` |
| setup with a lifecycle, reused across files | a fixture, delivered through `await use(v)` | `PW-FIX-01`, `PW-FIX-03` |
| a suite parameter | an option fixture + `projects[].use` | `PW-FIX-04` |
| external state created once | a setup project with `dependencies` | `PW-CFG-03` |
| login | a setup project + `storageState` | `PW-AUTH-01` |

Three invariants that generate rework when ignored:

- **A page object contains no business-rule assertion** (`PW-STR-02`) — otherwise the negative-path
 test cannot reuse the method.
- **A page object does not return `Promise<string>`** — it returns a `Locator`, otherwise it pushes
 `PW-EXP-01` onto every test that uses it.
- **`test` and `expect` come from a single module in the project** (`PW-FIX-05`) — importing the base
 and the derived one in the same file makes the fixtures disappear **with no compilation error**.
 Re-export both from `fixtures.ts`.

A test with more than one business step gets `test.step` (`PW-DBG-03`) — that is what turns
"failed on action 19" into "failed while checking out".

---

## Related

- [Playwright - Rede e Mocking](../../../../knowledge-base/docs/playwright-rede-e-mocking.md) · [Playwright - Autenticação e Isolamento](../../../../knowledge-base/docs/playwright-autenticacao-e-isolamento.md) · [Playwright - Fixtures](../../../../knowledge-base/docs/playwright-fixtures.md) · [Playwright - Estrutura de Testes](../../../../knowledge-base/docs/playwright-estrutura-de-testes.md)
- `autoverificacao.md` — what to check after writing
