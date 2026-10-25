---
titulo: Bun - Tests - DOM and Components
Link: https://bun.com/docs/test/dom
tags:
  - bun
  - testing
  - react
  - agent-context
source: "Official documentation — https://bun.com/docs/test/dom and https://bun.com/docs/guides/test/testing-library"
verificado-em: 2026-08-20
---

# Bun - Tests - DOM and Components

> The executable end-to-end recipe: happy-dom by preload, Testing Library, `expect.extend` (the step that is usually missing), types · interaction with `userEvent` and the choice between `findBy*`, `waitFor` and `act` · **what the component imports and `bun test` does not resolve like Vite does** · stubs for what happy-dom does not implement · how isolation changes the DOM registration.
>
> **Does not cover:** what to assert in a component test · stories and tests in a real browser (`Storybook - Testes e Interações`) · resolution of `paths` and `import.meta.env` in general ([Bun - Runtime and APIs](bun-runtime-and-apis.md)).

Entry: [Bun - Tests](bun-tests.md) · Normative base: [Bun - Tests](bun-tests.md) § 6 · Family: `BUN-TEST-*` (this note owns `07`, `12`, `25`, `26`)

---

## 1. Concept: the runner ships no DOM, and that is your decision

`document` and `window` do not exist in `bun test`. There is no `environment: "jsdom"` key to switch on, because there is no environment configuration layer: **the DOM comes in as code, in a preload script, registering globals before any test runs.**

This has a design consequence worth more than the recipe: since the DOM is opt-in by preload and the preload is global, **the whole suite either has a DOM or does not**. There is no "this file runs with jsdom and that one without". If the project has backend and frontend in the same suite, the backend also pays for the DOM registration — and the way out, when that bothers you, is to separate by `root`/`pathIgnorePatterns` and run two commands ([Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) § 2).

The implementation choice is **happy-dom**, which the source presents as *"leaner and faster"* than jsdom and treats as the replacement for `testEnvironment: "jsdom"`. **jsdom is not documented as a supported alternative:** nothing technically prevents injecting its globals, but there is no verified recipe.

---

## 2. Setup: two preloads, and the order between them matters

```bash
bun add -d @happy-dom/global-registrator \
           @testing-library/react @testing-library/dom @testing-library/jest-dom \
           @testing-library/user-event
```

```ts
// test/happydom.ts — preload 1: injects the browser globals
import { GlobalRegistrator } from "@happy-dom/global-registrator";

GlobalRegistrator.register();
```

```ts
// test/testing-library.ts — preload 2: registers matchers and cleanup
import { afterEach, expect } from "bun:test";
import { cleanup } from "@testing-library/react";
import * as matchers from "@testing-library/jest-dom/matchers";

expect.extend(matchers);

afterEach(() => {
  cleanup();
  document.body.innerHTML = "";
});
```

```toml
# bunfig.toml
[test]
preload = ["./test/happydom.ts", "./test/testing-library.ts"]
```

```ts
// test/matchers.d.ts — types only; without this, `toHaveTextContent` does not exist for tsc
import { TestingLibraryMatchers } from "@testing-library/jest-dom/matchers";
import { Matchers, AsymmetricMatchers } from "bun:test";

declare module "bun:test" {
  interface Matchers<T> extends TestingLibraryMatchers<typeof expect.stringContaining, void> {}
  interface AsymmetricMatchers extends TestingLibraryMatchers<any, any> {}
}
```

```tsx
/// <reference lib="dom" />
import { test, expect } from "bun:test";
import { render, screen } from "@testing-library/react";
import { ResumoCarrinho } from "./ResumoCarrinho";

test("shows the cart total", () => {
  render(<ResumoCarrinho itens={[{ id: "1", preco: 1990 }]} />);
  expect(screen.getByRole("status")).toHaveTextContent("R$ 19,90");
});
```

Four details, and three of them are the difference between the recipe working and not working:

**1. `expect.extend(matchers)` is mandatory.** `import "@testing-library/jest-dom"` alone — the form that works in Jest and in Vitest — does **not** register the matchers in `bun:test`. Without `expect.extend`, `toHaveTextContent` and `toBeInTheDocument` do not exist at runtime.

> **Internal divergence in the source, recorded.** The short DOM testing page shows `import '@testing-library/jest-dom'` in the test file and in a `test-setup.ts`; the dedicated Testing Library guide uses the explicit form, importing from `@testing-library/jest-dom/matchers` and going through `expect.extend`. The two pages of the same doc diverge. This note follows the guide — it is the form that works.

**2. Two preload files, in this order, and not a single one.** The source states the reason: in a single preload, the `@testing-library/*` packages need to be loaded with `await import()` **after** `GlobalRegistrator.register()`, because they inspect browser globals at the moment they are evaluated. Two files in the right order solve it without `await import()`.

**2a. The `void` in `TestingLibraryMatchers<…, void>` is load-bearing.** It looks like a typo for `T`, and it is not. `bun:test` already declares `toBeEmpty()` returning `void`; jest-dom declares its own `toBeEmpty()` returning the second type argument. With `void` the two signatures are identical and the interfaces merge. With `T`, `tsc` fails inside `node_modules/bun-types` with `TS2320: Interface 'Matchers<T>' cannot simultaneously extend types 'MatchersBuiltin<T>' and 'TestingLibraryMatchers<…, T>'`, on `toBeEmpty`. Keep `void`; do not reach for `Omit<…, "toBeEmpty">` to work around an error the original recipe never had. Verified with `typescript` 5.9.3 and 7.0.2, `@types/bun` 1.4.4, `@testing-library/jest-dom` 6.10.0 and 7.0.1, on 2026-10-25.

**3. `/// <reference lib="dom" />` at the top of the test file** resolves *"Cannot find name 'document'"*. It is a type problem, not a runtime one — and it is per file.

**4. `cleanup()` in `afterEach`, in the preload.** The `document` is shared between tests of the same file: without cleanup, `getByRole` starts finding elements rendered by the previous test and fails with "found multiple elements". The doc shows `cleanup()` plus `document.body.innerHTML = ""` — the second line covers what was written to the DOM outside `render`.

| ID | Rule |
| --- | --- |
| `BUN-TEST-07` | DOM registration (`GlobalRegistrator.register()`) **MUST** happen in `[test] preload`, **NEVER** inside a test file. |
| `BUN-TEST-12` | A `@testing-library/jest-dom` matcher **MUST** be registered with `expect.extend` in a preload — the package `import` alone registers nothing in `bun:test`. |
| `BUN-TEST-25` | `GlobalRegistrator.register()` and the `@testing-library/*` packages **MUST** live in separate preloads, in this order — in a single file, the packages **MUST** be loaded by `await import()` after the registration. |
| `BUN-TEST-26` | A file that renders a component **MUST** have `cleanup()` in `afterEach` (preferably in the preload) — the `document` is shared between the file's tests. |

### DOM without React

The full recipe is for components. To test code that only manipulates the DOM, preload 1 is enough:

```ts
test("registers the custom element", () => {
  class Contador extends HTMLElement {
    constructor() { super(); this.innerHTML = "<p>0</p>"; }
  }
  customElements.define("app-contador", Contador);

  document.body.innerHTML = "<app-contador></app-contador>";
  expect(document.querySelector("app-contador p")?.textContent).toBe("0");
});
```

---

## 3. Interaction: click, type, wait

Nothing here is Bun-specific — `userEvent`, `fireEvent`, `waitFor` and `act` belong to Testing Library and work on top of the globals that happy-dom installed. What changes in `bun test` is only that there is no environment to configure.

```tsx
/// <reference lib="dom" />
import { test, expect } from "bun:test";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

test("adds the item to the cart on click", async () => {
  const user = userEvent.setup();          // always before render
  render(<BotaoAdicionar produtoId="p-1" />);

  await user.click(screen.getByRole("button", { name: /adicionar/i }));

  // findBy* already embeds waitFor — prefer it over waitFor + getBy*
  expect(await screen.findByRole("status")).toHaveTextContent("1 item");

  // waitFor for a condition that is not "element exists"
  await waitFor(() => expect(screen.getByRole("button")).toBeDisabled());
});
```

| You need | Use | Do not use |
| --- | --- | --- |
| Simulate a user (click, type, tab, hover) | `userEvent` — fires the real sequence of events | `fireEvent.click` for a user flow |
| Fire **one** specific event (`change` of a library-controlled input, `scroll`) | `fireEvent` | `userEvent` for an isolated synthetic event |
| Wait for something to appear | `await screen.findBy*` | `waitFor` + `getBy*` — more verbose, same thing |
| Wait for a condition that is not "element exists" | `await waitFor(() => expect(…))` | `Bun.sleep` — a test with sleep is a flaky test |
| Wrap a state update made outside an event | `act()` | wrapping `render`/`userEvent`, which already call `act` internally |

**`userEvent` is asynchronous.** `user.click` returns a Promise, and forgetting the `await` produces an assertion that runs before the re-render. Combined with `BUN-TEST-06` (assertion in a callback without a count), it is the most common pair of mistakes in component tests.

**On the clock:** `@testing-library/react` detects fake timers and advances the clock instead of waiting real time — which makes `useFakeTimers` viable in a component test with debounce ([Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) § 5).

---

## 4. What the component imports and `bun test` does not resolve like Vite does

This is the list that decides whether the recipe works in **your** component. Each line is something Vite did through a plugin and that here is something else — or nothing.

| In the component | Under `bun test` | Status |
| --- | --- | --- |
| `import logo from "./logo.svg"` | `file` loader: Bun checks that the file exists and the import resolves to the **absolute path on disk** | verified — it is a **different string** from the URL Vite delivers; an assertion on the rendered `src` needs to reflect that |
| `import { ReactComponent as Logo } from "./logo.svg"` (SVGR) | **does not work** — it is a Vite plugin, and Bun does not have Vite's plugin chain | verified by absence |
| `import "./Botao.css"` | **not verified** — the source documents `css` as a loader and the behavior in the *bundler*, and does not state what happens at runtime | see the probe below |
| `import estilos from "./Botao.module.css"` (CSS Modules) | **not verified** | same |
| `import texto from "./termos.txt"` | `text` loader: the content arrives as a string | verified |
| `import dados from "./seed.json"` | parsed, as in Vite | verified |
| `import { api } from "@/lib/api"` | resolved by `compilerOptions.paths`; **`resolve.alias` from `vite.config.ts` is ignored** | verified — [Bun - Runtime and APIs](bun-runtime-and-apis.md) § 2 |
| `import.meta.env.VITE_API_URL` | **works** if the variable is in the environment or in a `.env` that Bun loads — Bun does not filter by prefix | verified |
| `import.meta.env.MODE` / `.DEV` / `.PROD` / `.BASE_URL` | **`undefined`** — they are constants injected by Vite; under Bun, `import.meta.env` is `process.env` | verified — [Bun - Runtime and APIs](bun-runtime-and-apis.md) § 4 |
| `<Componente />` (JSX) | native, no plugin, as long as `compilerOptions.jsx` is not `"preserve"` | verified |

**The way out for the unverified imports (CSS and CSS Modules):** do not find out in production tests. Run a probe and see what happens in your version:

```bash
echo 'import "./src/Botao.css"; console.log("ok");' > /tmp/probe.ts && bun /tmp/probe.ts
```

If it fails or brings something unexpected, the verified remedy is to map the extension to a harmless loader:

```toml
# bunfig.toml — treats .css as text instead of leaving the result undefined
loader = { ".css" = "text" }
```

This disables any assertion on a class generated by CSS Modules — which, for a test that observes behavior, is the right outcome anyway.

**And the way out that dispenses with the whole list:** a component that receives configuration by prop, and a test that renders the pure component instead of the container, touches neither `import.meta.env` nor assets. The gap above is proportional to how much the component depends on the build.

---

## 5. Limits of happy-dom, and what to do about them

What does not come ready: the doc itself shows the preload **registering stubs**, which is the acknowledgement that layout and media APIs are not there.

```ts
// test/happydom.ts — after GlobalRegistrator.register()
import { jest } from "bun:test";

global.ResizeObserver = class ResizeObserver {
  observe() {}
  unobserve() {}
  disconnect() {}
};

Object.defineProperty(window, "matchMedia", {
  writable: true,
  value: jest.fn().mockImplementation((query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: jest.fn(),
    removeListener: jest.fn(),
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn(),
  })),
});
```

`ResizeObserver` and `matchMedia` are the two the source stubs explicitly. **`IntersectionObserver` is not mentioned by the source** — if the component uses viewport lazy-loading, assume it needs the same treatment and verify first.

And the limit no stub resolves: **none of this measures.** `getBoundingClientRect` returns zeros. A test that depends on real dimensions, on layout or on scrolling is not a unit test — it is a browser test, and its place is elsewhere (`Storybook - Testes e Interações`, or Playwright).

---

## 6. Isolation and the DOM registration

Under `--isolate` — implicit in `--parallel` — the source states that, between files, Bun creates a new `globalThis`, clears the module registries, closes servers and sockets, and **re-executes the preload scripts** ([Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) § 4). Direct consequence: **`GlobalRegistrator.register()` runs once per test file**, and each file gets a clean `document`.

The upside is large: DOM leaking between files — the `getByRole` that finds two elements because the previous file did not clean up — stops being possible by construction. `cleanup()` remains necessary **between tests of the same file** (`BUN-TEST-26`), and that is why it lives in the preload's `afterEach`.

**What was not verified:** whether `GlobalRegistrator.register()` is idempotent and what the cost of repeating it per file is. Bun's source states that the preload is re-executed; the registrator's behavior under re-execution belongs to happy-dom, and there is no statement about it. **Measure before concluding that `--parallel` speeds up a DOM suite:** with many small files, the cost of rebuilding the DOM per file can exceed the gain, and `--parallel --no-isolate` is the alternative — at the price of bringing back the leak between files of the same worker.

---

## Antipatterns

| Antipattern | Why it fails | What to do |
| --- | --- | --- |
| `GlobalRegistrator.register()` inside the test file | registers too late for modules that check `typeof window` at the top, and needs to be repeated in every file | `[test] preload` — `BUN-TEST-07` |
| `import "@testing-library/jest-dom"` and expecting `toHaveTextContent` | the import alone registers no matcher in `bun:test`; the matcher does not exist at runtime | `expect.extend(matchers)` in the preload — `BUN-TEST-12` |
| Putting happy-dom and Testing Library in a single preload, with a static import | the packages inspect browser globals on evaluation, before the registration | two preloads, in this order — `BUN-TEST-25` |
| `@testing-library/react` without `cleanup()` in `afterEach` | the `document` is shared; `getByRole` finds elements from the previous test | `cleanup()` + clear `document.body` — `BUN-TEST-26` |
| `user.click(...)` without `await` | `userEvent` is asynchronous; the assertion runs before the re-render | `await user.click(...)` — § 3 |
| `waitFor` + `getBy*` to wait for an element to appear | more verbose and with a worse error message than the ready-made form | `await screen.findBy*` — § 3 |
| `await Bun.sleep(300)` to wait for a render | a test with sleep is flaky and slow | `findBy*` / `waitFor` — § 3 |
| Asserting on `import.meta.env.MODE`/`.DEV` in a component under `bun test` | they are Vite constants; under Bun, `import.meta.env` is `process.env` and they are `undefined` | receive configuration by prop — § 4 |
| Relying on `resolve.alias` from `vite.config.ts` in the test | Bun does not read `vite.config`; the import does not resolve | declare it in `compilerOptions.paths` — § 4 |
| Assertion on the `src` of an imported image expecting Vite's URL | the `file` loader resolves to the absolute path on disk | assert on presence/`alt`, not on the path string — § 4 |
| Test that depends on a real `getBoundingClientRect` | happy-dom does not measure; it returns zeros | browser test — § 5 |
| Assuming `IntersectionObserver` exists because `ResizeObserver` was stubbed | the source does not mention the former | stub and verify — § 5 |
| Concluding that `--parallel` speeds up the DOM suite without measuring | the DOM is rebuilt per file; it can cost more than the gain | measure; consider `--no-isolate` — § 6 |

---

## Review checklist

- [ ] Is the happy-dom registration in `[test] preload`? → `BUN-TEST-07`
- [ ] Do the `jest-dom` matchers go through `expect.extend`? → `BUN-TEST-12`
- [ ] Are happy-dom and Testing Library in separate preloads, in this order? → `BUN-TEST-25`
- [ ] Is there `cleanup()` in `afterEach`? → `BUN-TEST-26`
- [ ] Is every `userEvent` awaited? → § 3
- [ ] Do the waits use `findBy*`/`waitFor`, never `sleep`? → § 3
- [ ] Does the component under test receive configuration by prop, instead of reading `import.meta.env`? → § 4
- [ ] Are the aliases in `compilerOptions.paths`, and is `compilerOptions.jsx` not `"preserve"`? → § 4
- [ ] Are the necessary stubs (`ResizeObserver`, `matchMedia`, and `IntersectionObserver` if used) in the preload? → § 5
- [ ] Does the test file have `/// <reference lib="dom" />`? → § 2

---

## Related

- [Bun - Tests](bun-tests.md) — hub, mental model, API map, decision trees
- [Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) · [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) · [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) · [Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) · [Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md)
- — what to assert in a component test
- `Storybook - Testes e Interações` — the same component tested in a real browser
- `React.js` · [Bun - Runtime and APIs](bun-runtime-and-apis.md) — `paths`, `import.meta.env`, loaders

## Sources consulted

Verified on **2026-08-20**: [DOM testing](https://bun.com/docs/test/dom) · [Using Testing Library with Bun](https://bun.com/docs/guides/test/testing-library) · [Parallel & isolated test runs](https://bun.com/docs/test/parallel) · [Loaders](https://bun.com/docs/bundler/loaders) · [JSX](https://bun.com/docs/runtime/jsx) · [Bun 1.4](https://bun.com/blog/bun-v1.4) (fake timers and Testing Library).
