---
titulo: Bun - Tests - Mocks and Time
Link: https://bun.com/docs/test/mocks
tags:
  - bun
  - testing
  - agent-context
source: "Official documentation — https://bun.com/docs/test/mocks, /dates-times, reference/bun/test/jest"
verificado-em: 2026-08-20
---

# Bun - Tests - Mocks and Time

> `mock()`/`jest.fn()`, `spyOn()`, `mock.module()` · the full API of a mock (`.mock.calls`, `mockReturnValueOnce`, …) · **the three cleanups and what each one does not do** · why `mock.module()` needs the preload · dependency injection as the alternative to the mock · clock: `setSystemTime`, `useFakeTimers`, advancing timers, `TZ` · Vitest's `vi` surface.
>
> **Does not cover:** mock matchers (`.toHaveBeenCalledWith`) — they are in [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) § 6 · where the preload is declared ([Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) § 5) · what the preload's scope does under `--parallel` ([Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) § 3).

Entry: [Bun - Tests](bun-tests.md) · Normative base: [Bun - Tests](bun-tests.md) § 6 · Family: `BUN-TEST-*` (this note owns `02`, `03`, `04`, `20`, `21`)

---

## 1. Concept: a mock is declared coupling, not convenience

Every mock states two things: *"this unit depends on that one"* and *"this is the shape of that dependency"*. The second is a copy — and copies age. When the real gateway changes its signature, the mock stays green: the test now verifies that your code talks correctly to a service that no longer exists.

That is not an argument against mocks; it is the criterion for choosing among the three forms Bun offers, in order of increasing coupling:

| Form | What it couples | Price |
| --- | --- | --- |
| **Dependency injection** (passing the double as a parameter) | nothing beyond the interface you declared yourself | requires the code to accept the dependency from outside |
| `spyOn(obj, "method")` | the name of a method on an object the test already has in hand | restoration is your responsibility |
| `mock.module("./mod", …)` | the **module path** — a detail of file arrangement | process scope, not test scope (§ 4) |

The order of this table is the order of preference. When the code under test receives its dependencies, the test does not need a module mock — and the underlying decision (mock it, use a double, or bring up the real service) belongs to architecture, not to the runner:.

---

## 2. `mock()` and `spyOn()`

```ts
import { mock, spyOn, expect } from "bun:test";

// observable function, with its own implementation
const buscarCotacao = mock(async (cep: string) => ({ cep, valor: 1990 }));

await buscarCotacao("01310-100");
expect(buscarCotacao).toHaveBeenCalledTimes(1);
expect(buscarCotacao.mock.lastCall).toEqual(["01310-100"]);

// spy without replacing: the original method keeps running
const repo = new PedidoRepository();
const salvar = spyOn(repo, "salvar");

// spy and replace
spyOn(repo, "buscar").mockResolvedValue({ id: "p-1", status: "pago" });
```

`jest.fn()` and `vi.fn()` are equivalent to `mock()`. The choice between `mock()` and `spyOn()` is objective: **`spyOn` when the object already exists and you want to observe it; `mock` when you are fabricating the dependency.**

### Surface of a mock

| Property / method | What it gives |
| --- | --- |
| `.mock.calls` | array of arguments, one entry per call |
| `.mock.results` | array of return values, one entry per call |
| `.mock.instances` | instances created with `new` |
| `.mock.contexts` | the `this` of each call |
| `.mock.lastCall` | arguments of the most recent call |
| `.mockImplementation(fn)` / `.mockImplementationOnce(fn)` | sets the implementation — permanently / only for the next call |
| `.mockReturnValue(v)` / `.mockReturnValueOnce(v)` | sets the return value |
| `.mockResolvedValue(v)` / `.mockRejectedValue(e)` | sets a resolved / rejected Promise |
| `.mockClear()` | clears history, **keeps** the implementation |
| `.mockReset()` | clears history **and** removes the implementation |
| `.mockRestore()` | restores the original implementation (spy) |

**`...Once` is the way to test a sequence**: the first call fails, the second works — that is how you test retry without waiting real time.

```ts
const cobrar = mock<() => Promise<string>>();
cobrar.mockRejectedValueOnce(new Error("timeout")).mockResolvedValue("aprovado");

expect(await cobrarComRetry(cobrar)).toBe("aprovado");
expect(cobrar).toHaveBeenCalledTimes(2);
```

---

## 3. The three cleanups, and what each one does not do

This is where "the test passes alone and fails in the suite" is born. Three global calls, different scopes:

| Call | Clears history (`.mock.calls`, `.results`, `.instances`, `.contexts`) | Removes the implementation from `mockReturnValue`/`mockImplementation` | Restores the spy's original implementation | Undoes `mock.module()` |
| --- | --- | --- | --- | --- |
| `mock.clearAllMocks()` | yes | **no** | no | no |
| `jest.resetAllMocks()` / `vi.resetAllMocks()` | yes | yes | **no** | no |
| `mock.restore()` | yes | yes | **yes** | **no** |

The last column is the trap, and the source is literal: `mock.restore()` *"does not reset modules overridden with `mock.module()`"*.

The correct default for almost every project is one line, in the preload:

```ts
// test/setup.ts  →  bunfig.toml: [test] preload = ["./test/setup.ts"]
import { afterEach, mock } from "bun:test";

afterEach(() => {
  mock.restore();
});
```

Putting this in the preload, and not in each file, is the recommendation of the docs themselves — and it is what prevents a new file, written by someone who did not read this note, from leaking a spy into the rest of the suite. Without `--isolate`, **a single global is shared by all files** ([Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) § 2): the spy does not leak into the next test, it leaks into the next *hour* of the suite.

| ID | Rule |
| --- | --- |
| `BUN-TEST-02` | `spyOn` **MUST** have guaranteed restoration (`mock.restore()` in `afterEach` or in the preload) — without it the spy leaks into the following tests. |

---

## 4. `mock.module()`: process scope and the side effect that already happened

```ts
mock.module("./gateway-pagamento", () => ({
  cobrar: mock(async () => ({ status: "aprovado" as const })),
}));
```

What the source declares, and what follows from each statement:

- **Works for `import` and for `require`**, and the specifier is resolved like a normal import: relative path, absolute path or package name (`mock.module("pg", …)`).
- **Updates the module even if it has already been imported** — ESM live bindings reflect the swap in every existing importer.
- **But the original module has already been evaluated**: *"its side effects have already happened"*. If it opens a connection, registers a listener, reads env or instantiates a client at the top of the file, that happened before your mock.
- **`mock.restore()` does not undo it.** The module stays mocked for the rest of the test process.

The two operational consequences are the same decision seen from two angles: **a module mock belongs in the preload.**

```toml
# bunfig.toml
[test]
preload = ["./test/mocks/gateway.ts", "./test/setup.ts"]
```

```ts
// test/mocks/gateway.ts — runs before any test file
import { mock } from "bun:test";

mock.module("./src/gateway-pagamento", () => ({
  cobrar: mock(async () => ({ status: "aprovado" as const })),
}));
```

**Do not count on hoisting.** In Vitest, `vi.mock` is hoisted to the top of the file by the transformer. Bun's source does not declare that behavior for `mock.module` nor for `vi.mock` — treat it as **not hoisted**: the call runs where it is written, after the file's imports. When the goal is to prevent the evaluation of the original, the preload is the only guarantee.

| ID | Rule |
| --- | --- |
| `BUN-TEST-03` | `mock.module()` is **NEVER** undone by `mock.restore()`; a module mock **MUST** be registered in `--preload` or treated as global state of the test process. |
| `BUN-TEST-04` | A mock whose goal is to prevent an import side effect (connection, listener, env read at the top) **MUST** be registered in `--preload` — mocking after the import does not undo what already ran. |

### The alternative that makes all of this unnecessary

```ts
// instead of mocking the module, receive the dependency
export function criarServicoDePedidos(deps: { gateway: Gateway; agora: () => Date }) {
  return {
    async pagar(pedido: Pedido) {
      const r = await deps.gateway.cobrar(pedido);
      return { ...pedido, pagoEm: deps.agora(), status: r.status };
    },
  };
}

// in the test: no module mock, no global scope, no restoration
const servico = criarServicoDePedidos({
  gateway: { cobrar: mock(async () => ({ status: "aprovado" as const })) },
  agora: () => new Date("2026-01-01T00:00:00Z"),
});
```

This is not architectural dogma: it is the form of test that **has no global scope to leak**. When a module is mocked by three different test files, the signal is usually that the dependency wanted to be a parameter.

---

## 5. Time: freezing, advancing and the timezone

Two distinct needs, and distinct APIs:

| I need | API |
| --- | --- |
| A fixed date (`new Date()`, `Date.now()`, `Intl.DateTimeFormat`) | `setSystemTime(date)` |
| To make time **pass** (`setTimeout`, `setInterval`, debounce, polling) | `jest.useFakeTimers()` + `jest.advanceTimersByTime(ms)` |

```ts
import { test, expect, jest, setSystemTime } from "bun:test";

test("marks the order with the payment date", () => {
  setSystemTime(new Date("2026-01-01T00:00:00.000Z"));
  expect(pagar(pedido).pagoEm.toISOString()).toBe("2026-01-01T00:00:00.000Z");
  setSystemTime();                                   // no argument: back to the real clock
});

test("debounce fires once after 300 ms", () => {
  jest.useFakeTimers();
  const cb = jest.fn();
  const enviar = debounce(cb, 300);

  enviar(); enviar(); enviar();
  expect(cb).not.toHaveBeenCalled();

  jest.advanceTimersByTime(300);
  expect(cb).toHaveBeenCalledTimes(1);

  jest.useRealTimers();
});
```

Verified surface: `jest.useFakeTimers()` (accepts `'modern'`, `'legacy'` or `{ now }`), `jest.useRealTimers()`, `jest.setSystemTime()` / `setSystemTime()`, `jest.now()`, `jest.advanceTimersByTime(ms)`, `advanceTimersToNextTimer()`, `runAllTimers()`, `getTimerCount()`, `clearAllTimers()`.

### The difference from Jest that changes the code

**In `bun:test`, `useFakeTimers` does not replace the `Date` constructor.** The source declares this explicitly, and the reason is to avoid the class of bug where `Date !== Date` after turning on fake timers — code that does `instanceof Date` or compares constructors breaks under Jest and does not break here.

What follows: **to pin a date, `setSystemTime` is the API, not `useFakeTimers`.** The two things are orthogonal — one controls *what time it is*, the other controls *whether time moves*. They combine, and `jest.setSystemTime()` works together with `advanceTimersByTime()`.

> **Recorded source divergence.** The 1.4 release post describes `jest.useFakeTimers()` as controlling *"`setTimeout`, `setInterval`, and `Date`"*, while the dates and times page states that the `Date` constructor does **not** change with `useFakeTimers`. The two sentences coexist if read as different planes — the clock that `Date.now()` consults becomes the fake one; the *identity* of the constructor is not swapped — but the post's wording is loose. This note follows the dates and times page, which is the specific one.

Fine detail verified: since 1.3.6, `advanceTimersByTime(0)` fires `setTimeout(fn, 0)` callbacks — which internally are scheduled with 1 ms, as the HTML spec says. And component testing libraries (`@testing-library/react`) detect fake timers and advance the clock instead of waiting real time.

### Timezone

The runner sets `TZ=Etc/UTC` when `TZ` is not in the environment ([Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) § 6). This makes the suite deterministic **on your machine and in CI** — and leaves an implicit dependency: the same test runs differently in an environment that sets `TZ`.

```bash
TZ=America/Sao_Paulo bun test ./src/relatorio.test.ts
```

```ts
process.env.TZ = "America/Sao_Paulo";   // takes effect from here on, in the same process
```

Unlike Jest, the timezone can be switched **several times during the same run** and the effect is immediate — which allows testing formatting in two timezones in the same file. What does not change: an assertion on a *formatted* date or time needs to say in which timezone it holds.

| ID | Rule |
| --- | --- |
| `BUN-TEST-20` | Freezing a date **MUST** use `setSystemTime` — `useFakeTimers` does not swap the `Date` constructor in `bun:test`, unlike Jest. |
| `BUN-TEST-21` | An assertion on a **formatted** date or time **MUST** pin the timezone explicitly (`TZ` on the command, or `process.env.TZ` in the test) — the runner's `Etc/UTC` only holds while `TZ` is not defined in the environment. † |

---

## 6. The `vi` surface, for those arriving from Vitest

The `vi` object exists as a global and imports from `vitest` are rewritten internally to `bun:test`. The verified subset:

| Vitest | In `bun:test` | Difference that matters |
| --- | --- | --- |
| `vi.fn()` | `vi.fn()` / `mock()` | — |
| `vi.spyOn()` | `vi.spyOn()` / `spyOn()` | — |
| `vi.mock("./mod", factory)` | `vi.mock` exists; the native form is `mock.module()` | **do not assume hoisting** — § 4 |
| `vi.clearAllMocks()` | `mock.clearAllMocks()` | scopes differ from Vitest's — read the table in § 3 |
| `vi.resetAllMocks()` | `jest.resetAllMocks()` / `vi.resetAllMocks()` | same |
| `vi.restoreAllMocks()` | `mock.restore()` | does **not** undo `mock.module()` |
| `vi.useFakeTimers()` | `jest.useFakeTimers()` | `Date` is not rebuilt — § 5 |
| `vi.setSystemTime()` | `setSystemTime()` / `jest.setSystemTime()` | — |
| `vi.advanceTimersByTime()` | `jest.advanceTimersByTime()` | — |

The full migration map (including configuration, which is the part that does **not** migrate) is in [Bun - Tests](bun-tests.md) § 5.4.

---

## Antipatterns

| Antipattern | Why it fails | What to do |
| --- | --- | --- |
| `spyOn` without `mock.restore()` in `afterEach` | without `--isolate` the global is shared by all files; the spy leaks into the whole suite | `afterEach(() => mock.restore())` in the preload — `BUN-TEST-02` |
| Expecting `mock.restore()` to undo `mock.module()` | the source is explicit: it does not undo it; the module stays mocked in the process | register in the preload and treat as global — `BUN-TEST-03` |
| `mock.module()` in the test body to avoid the real module's connection | the module was already evaluated on import; the connection already opened | `--preload` / `[test] preload` — `BUN-TEST-04` |
| Assuming `mock.module`/`vi.mock` is hoisted as in Vitest | the source does not declare hoisting; the call runs after the imports | preload — `BUN-TEST-04` |
| `mock.clearAllMocks()` expecting the implementation to come back | it clears history and **keeps** the implementation | `mock.restore()` — § 3 |
| `jest.resetAllMocks()` expecting to restore the spy's original method | reset removes the implementation, it does not restore the original | `mock.restore()` — § 3 |
| `useFakeTimers()` to pin `new Date()` | the `Date` constructor is not swapped in `bun:test` | `setSystemTime(date)` — `BUN-TEST-20` |
| Assertion on a formatted date without declaring the timezone | passes by inheriting `TZ=Etc/UTC` and breaks in an environment that sets `TZ` | pin `TZ` — `BUN-TEST-21` |
| `await Bun.sleep(400)` to wait for a debounce | a test with sleep is slow and flaky | `useFakeTimers` + `advanceTimersByTime` — § 5 |
| Mocking the same module in three test files | the mock became the real interface, without anyone having decided that | receive the dependency as a parameter — § 4 |
| Module mock whose shape is never checked against the real one | the test verifies a conversation with a service that no longer exists | separate contract / integration test — |

---

## Review checklist

- [ ] Is there a `mock.restore()` in `afterEach` (preferably in the preload)? → `BUN-TEST-02`
- [ ] Does no `mock.module()` count on automatic restoration? → `BUN-TEST-03`
- [ ] Are the mocks that avoid import effects in the preload? → `BUN-TEST-04`
- [ ] Does no code depend on hoisting of `mock.module`/`vi.mock`? → `BUN-TEST-04`
- [ ] Do fixed dates use `setSystemTime`, not `useFakeTimers`? → `BUN-TEST-20`
- [ ] Do assertions on formatted dates declare the timezone? → `BUN-TEST-21`
- [ ] No `sleep` waiting for a timer? → § 5
- [ ] Does each module mock have a justification that dependency injection would not resolve? → § 4

---

## Related

- [Bun - Tests](bun-tests.md) — hub, mental model, API map, decision trees
- [Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) · [Bun - Tests - Writing and Assertions](bun-tests-writing-and-assertions.md) · [Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) · [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md) · [Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md)
- — mock, double or real service
- — what to test, before how

## Sources consulted

Verified on **2026-08-20**: [Mocks](https://bun.com/docs/test/mocks) · [Dates and times](https://bun.com/docs/test/dates-times) · [`jest` object](https://bun.com/reference/bun/test/jest) · [`useFakeTimers`](https://bun.com/reference/bun/test/jest/useFakeTimers) · [`advanceTimersByTime`](https://bun.com/reference/bun/test/jest/advanceTimersByTime) · [`vi` property](https://bun.com/reference/bun/test/vi) · [Bun 1.4](https://bun.com/blog/bun-v1.4) and [Bun v1.3.6](https://bun.com/blog/bun-v1.3.6) (fake timers).
