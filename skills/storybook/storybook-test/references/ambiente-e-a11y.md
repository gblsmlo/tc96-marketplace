# Replacing the environment, and accessibility

It only comes in when the story moves up a level: page composition, a component talking to the BFF, a server-only module.

| Replace | How | Rule |
| --- | --- | --- |
| an observable callback | `fn` in `meta.args` | `SB-TEST-03` |
| a project or package module | `sb.mock` — **only** in `.storybook/preview.*` | `SB-MOCK-01` |
| the mock's behavior, per story | `mocked` in `beforeEach` | `SB-MOCK-04` |
| an HTTP request | MSW, through `mswLoader` + `beforeEach({ msw })` | `SB-MOCK-07` |
| clock, randomness, locale | a `beforeEach` that **returns** the cleanup | `SB-CTX-08` |

**The division worth memorizing:** the preview decides **what** is mocked; the story decides **how it behaves**. `sb.mock` in a story file does not work, and it does not fail in an obvious way.

Two details that break silently: a file in `__mocks__` has to be **JavaScript with ESM**, not TypeScript (`SB-MOCK-03`); and the mocked response's type reuses the type exported by the server, never retyped by hand (`SB-MOCK-07`).

**`fn` mocks need no manual restoration** — Storybook resets them between stories. It is the declared exception to `SB-TEST-07`.

---

## Step 4 — Accessibility

```ts
parameters: { a11y: { test: 'error' } }
```

**`'todo'` produces nothing in CI** — no error, no warning, no output. Only `'error'` fails (`SB-TEST-04`). A whole project on `'todo'` has a check that only exists for whoever opens the UI.

The ramp is the real problem: turning on `'error'` in an existing design system leaves CI red on day 1, and the only release valve produces zero output. Both ends are documented and the middle is not — it is an open item in [Storybook - Pendências de revisão](../../../../knowledge-base/storybook-pendencias-de-revisao.md). The workable way out is `'error'` per story or per component, advancing in waves, instead of globally in one go.

The addon disables the `region` rule by default, to avoid a **false positive** on an isolated component — a button outside a landmark is Storybook's normal, not a defect.
