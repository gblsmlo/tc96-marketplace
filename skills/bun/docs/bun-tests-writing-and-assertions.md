---
titulo: Bun - Tests - Writing and Assertions
Link: https://bun.com/docs/test/writing-tests
tags:
  - bun
  - testing
  - agent-context
source: "Official documentation — https://bun.com/docs/test/writing-tests, /snapshots"
verificado-em: 2026-08-20
---

# Bun - Tests - Writing and Assertions

> The body of the test file · `test`/`it`/`describe`, asynchronous and the `done` · timeout, `retry`, `repeats` · the full table of modifiers and what each one communicates · `test.each` and the format specifiers · the matcher catalog, including the ones that only exist in Bun and what is **not** implemented · assertion counting · custom matcher with `expect.extend` · `expectTypeOf` and why it verifies nothing at runtime · file and inline snapshots.
>
> **Does not cover:** discovery, filters and `bunfig.toml` ([Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md)) · mocks and clock ([Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md)) · hooks and order ([Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md)) · DOM matchers ([Bun - Tests - DOM and Components](bun-tests-dom-and-components.md)).

Entry: [Bun - Tests](bun-tests.md) · Normative base: [Bun - Tests](bun-tests.md) § 6 · Family: `BUN-TEST-*` (this note owns `05`, `06`, `08`, `11`, `16`, `17`, `18`, `19`)

---

## 1. Concept: the test is a claim, and the runner only decides whether it runs

A green test means one thing: **the assertions that executed passed**. It does not mean they executed. The distance between those two sentences is where almost every false positive in this note lives — an assertion inside a `catch` that was never reached, a forgotten `await`, an `expectTypeOf` that is a no-op, a snapshot re-recorded by reflex.

Hence the criterion that organizes the rest: every API below is presented with **what it communicates to whoever reads the report**, not only with what it does. `test.skip` and `test.failing` do almost the same thing mechanically and say opposite things. `toBe` and `toEqual` pass in the same cases until the day they do not.

---

## 2. `test`, `describe` and the asynchronous contour

```ts
import { test, describe, expect } from "bun:test";

test("soma dois inteiros", () => {
  expect(2 + 2).toBe(4);
});

describe("calculadora de frete", () => {
  test("cobra por faixa de peso", () => {
    expect(frete({ peso: 1200 })).toBe(2490);
  });
});
```

`it` is an alias of `test`. `describe` groups, nests, and its label becomes part of the test name for the purposes of `-t` ([Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) § 3.2).

**Asynchronous: `async`/`await`, and nothing else.**

```ts
test("busca o pedido", async () => {
  const pedido = await repo.buscar("p-1");
  expect(pedido.status).toBe("pago");
});
```

The `done` parameter exists for compatibility — and the source states the whole trap in one sentence: *"If your test function takes a `done` parameter, you must call it or the test hangs."* A test that hangs consumes the entire timeout (5 s by default) and fails for the wrong reason, hiding the real one. In new code, `done` has no use: every API that accepts a callback can be wrapped in a Promise.

| ID | Rule |
| --- | --- |
| `BUN-TEST-17` | An asynchronous test **MUST** use `async`/`await`. The `done` parameter **NEVER** in new code — if declared and not called, the test hangs until the timeout and fails for the wrong reason. † |

---

## 3. Timeout, `retry` and `repeats`

```ts
test("operação lenta", async () => {
  expect(await operacaoLenta()).toBe(42);
}, 500);                                   // third argument: ms

test("requisição instável", async () => {
  const r = await fetch("https://exemplo.com/api");
  expect(r.ok).toBe(true);
}, { retry: 3 });

test("garante estabilidade", () => {
  expect(Math.random()).toBeLessThan(1);
}, { repeats: 20 });                       // runs 21 times: 1 + 20
```

What the source states, and what changes how it is used:

- **Default timeout: 5000 ms**, overridable per test (third argument) or globally (`--timeout`). `0` or `Infinity` disable it.
- **The timeout throws an uncatchable exception.** No `try/catch` saves the test — it is intentional, to force the stop.
- **Bun kills the child processes** the test created with `Bun.spawn`, `Bun.spawnSync` or `node:child_process` when the timeout fires. A test that spawns a process and times out leaves no zombie.
- **`repeats: N` runs N+1 times** (the initial execution plus N repetitions).
- **`retry` and `repeats` cannot coexist** in the same test.

Where each one belongs:

| Situation | Use | Do not use |
| --- | --- | --- |
| Real and declared external instability (network, third-party service) | `{ retry: N }` on the test | global `--retry` — it anesthetizes the whole suite |
| Suspected flakiness to investigate | `{ repeats: 20 }`, or `--rerun-each` | `retry`, which hides exactly what you want to see |
| Legitimately slow operation (migration, build) | third argument with an explicit value | high global `--timeout`, which loosens all of them |
| Test that "sometimes hangs" | investigate; it is almost always a missing `await` or an uncalled `done` | timeout `0` |

**Disabling the timeout (`0`/`Infinity`) in a CI test trades a failure for a hung job.** It is useful locally, with the inspector open; it is not useful in a pipeline.

| ID | Rule |
| --- | --- |
| `BUN-TEST-16` | `retry` and `repeats` **NEVER** coexist in the same test — the source declares the combination invalid. |

---

## 4. Modifiers: what each one communicates

| Modifier | Mechanical semantics | What it communicates to whoever reads the report |
| --- | --- | --- |
| `test.skip` | does not run | nothing. The test disappears, and nobody is warned about anything |
| `test.todo` | does not run; with `--todo`, runs and **fails if it passes** | "this needs to be written" |
| `test.failing` | inverts the result: failing = passing; passing = **failing** | "there is a known bug here, and I want to know when it is fixed" |
| `test.only` | requires `bun test --only` to filter | nothing, in CI. It is a local debugging tool |
| `test.if(cond)` | runs only if the condition is true | "this test is valid only on this platform/architecture/flag" |
| `test.skipIf(cond)` / `test.todoIf(cond)` | skips / marks as todo conditionally | the same, from the negative side |
| `test.concurrent` | runs in parallel with the file's other concurrent tests | "this test shares no state" |
| `test.serial` | forces sequential execution (opt-out of `--concurrent`) | "this test depends on order or on shared state" |

`describe` accepts the same qualifiers (`describe.only`, `describe.skipIf`, `describe.each`, `describe.concurrent`), and they chain: `test.failing.each([...])(...)`.

### `skip` × `failing`: the only choice here that is not stylistic

`test.skip` removes the test from the report. The bug remains, the test vanishes, and on the day someone fixes the behavior by accident, **nothing warns** — the test stays skipped for months until someone asks why.

`test.failing` keeps the test running and **fails the moment it starts to pass**. That seems counterintuitive until you see the effect: the commit that fixes the bug breaks CI and the person is forced to remove the mark. The knowledge is not lost.

```ts
// known floating-point bug — I want to be told if it gets fixed
test.failing("soma decimal exata", () => {
  expect(0.1 + 0.2).toBe(0.3);
});
```

`skip` is for a deactivation with a deadline (a dependency went down, the environment changed today) — and deadline means a date in the comment, not an intention.

| ID | Rule |
| --- | --- |
| `BUN-TEST-08` | `test.only` **NEVER** is used as a way to disable the other tests — without `bun test --only` it filters nothing. |
| `BUN-TEST-11` | A test that documents a known bug **MUST** use `test.failing`, **NEVER** `test.skip` — `failing` warns when the bug is fixed. |

---

## 5. `test.each`: table of cases

```ts
test.each([
  [1, 2, 3],
  [3, 4, 7],
])("soma(%p, %p) = %p", (a, b, esperado) => {
  expect(a + b).toBe(esperado);
});

test.each([
  { peso: 500, faixa: "leve", valor: 1490 },
  { peso: 12000, faixa: "pesada", valor: 4990 },
])("frete de $peso g é $valor", ({ peso, valor }) => {
  expect(frete({ peso })).toBe(valor);
});
```

**The argument-passing rule:** a row that is an array becomes **separate arguments**; a row that is not an array (an object) becomes **a single argument**. Confusing the two produces `undefined` in the test body, not a type error.

Format specifiers in the title:

| Token | Replaced by |
| --- | --- |
| `%p` | pretty-format of the value |
| `%s` | string |
| `%d` / `%i` / `%f` | number / integer / float |
| `%j` | JSON |
| `%o` | object |
| `%#` | row index |
| `%%` | a literal `%` |

With objects, `$property` interpolates by name — it is what keeps the title readable when the table has five columns.

**When `each` is the right tool:** the test body is identical and only the data changes. When it is **not**: each row needs a different `expect`, or its own setup. In that case, `each` produces a body full of `if` — and three explicit tests are shorter and more readable than a table with branching.

---

## 6. Matchers: the catalog and the three decisions that matter

### 6.1 The catalog

| Category | Matchers |
| --- | --- |
| Equality | `.toBe`, `.toEqual`, `.toStrictEqual`, `.not` |
| Presence | `.toBeNull`, `.toBeUndefined`, `.toBeDefined`, `.toBeNaN`, `.toBeTruthy`, `.toBeFalsy` |
| String / array | `.toContain`, `.toContainEqual`, `.toHaveLength`, `.toMatch`, `expect.stringContaining`, `expect.stringMatching`, `expect.arrayContaining` |
| Object | `.toHaveProperty`, `.toMatchObject`, `expect.objectContaining`, `.toContainAllKeys`, `.toContainValue`, `.toContainValues`, `.toContainAllValues`, `.toContainAnyValues` |
| Number | `.toBeCloseTo`, `expect.closeTo`, `.toBeGreaterThan`, `.toBeGreaterThanOrEqual`, `.toBeLessThan`, `.toBeLessThanOrEqual` |
| Function / class | `.toThrow`, `.toBeInstanceOf` |
| Promise | `.resolves`, `.rejects` |
| Mock | `.toHaveBeenCalled`, `.toHaveBeenCalledTimes`, `.toHaveBeenCalledWith`, `.toHaveBeenLastCalledWith`, `.toHaveBeenNthCalledWith`, `.toHaveReturned`, `.toHaveReturnedTimes`, `.toHaveReturnedWith`, `.toHaveLastReturnedWith`, `.toHaveNthReturnedWith` |
| Snapshot | `.toMatchSnapshot`, `.toMatchInlineSnapshot`, `.toThrowErrorMatchingSnapshot`, `.toThrowErrorMatchingInlineSnapshot` |
| Utilities | `expect.extend`, `expect.anything`, `expect.any`, `expect.assertions`, `expect.hasAssertions` |

**Not implemented:** `expect.addSnapshotSerializer()`. A custom snapshot serializer does not exist — which limits snapshots to values the default formatter represents well (§ 9).

**Jest compatibility is not total, and the source says so**: *"Bun aims for compatibility with Jest, but not everything is implemented"*, with a [tracking issue](https://github.com/oven-sh/bun/issues/1825) cited as the reference for its status. "It exists in Jest" is not evidence that it exists here — checking before using is the invariant of [Bun](bun.md) § 7.

### 6.2 `toBe` × `toEqual` × `toStrictEqual`

| Matcher | Compares | Use when |
| --- | --- | --- |
| `.toBe` | identity (`Object.is`) | primitive, or when the identity of the reference **is** the claim |
| `.toEqual` | structure, recursively; ignores `undefined` in properties | the normal case for object and array |
| `.toStrictEqual` | structure **plus** class type and `undefined` properties | the object crosses a boundary where the exact shape matters (serialization, API contract) |

The difference that bites: `expect({ a: 1, b: undefined }).toEqual({ a: 1 })` **passes**; with `toStrictEqual`, it fails. If the object is going to become JSON, `toEqual` is right (the key disappears anyway). If it is going into an `Object.keys`, it is not.

### 6.3 `.toThrow` and the error test

```ts
expect(() => validar(pedidoInvalido)).toThrow(ValidacaoError);
expect(() => validar(pedidoInvalido)).toThrow(/cep/i);
await expect(cobrar(pedidoInvalido)).rejects.toThrow(PagamentoRecusado);
```

Three forms, and the third is the one most often missing in generated code: for an asynchronous function, `.rejects` is the path — wrapping in `try/catch` works, but requires assertion counting (§ 7) so it does not pass silently.

**`.toThrow()` with no argument accepts any error**, including the `TypeError` that shows up when you broke the call. Passing the class or the message is what makes the test claim something.

---

## 7. Assertion counting: the antidote to the false positive

```ts
test("propaga o erro do gateway", async () => {
  expect.assertions(1);                        // exactly one assertion must run
  try {
    await cobrar(pedidoInvalido);
  } catch (e) {
    expect(e).toBeInstanceOf(PagamentoRecusado);
  }
});

test("chama o callback de progresso", async () => {
  expect.hasAssertions();                      // at least one
  await enviar(arquivo, (pct) => {
    expect(pct).toBeGreaterThanOrEqual(0);
  });
});
```

Without `expect.assertions(1)`, the first test **passes when `cobrar` does not throw** — the `catch` simply does not execute, no assertion runs, and the runner has no way of knowing something was missing. It is the most common false positive in asynchronous tests, and the only mechanism that catches it is the count.

Where it is mandatory: every time the assertion is inside a `catch`, a callback, or an `if`. That is, every time **the path to the `expect` is conditional**.

| ID | Rule |
| --- | --- |
| `BUN-TEST-06` | A test whose assertion lives in a `catch`, callback or conditional branch **MUST** declare `expect.assertions(n)` or `expect.hasAssertions()`. |

---

## 8. Custom matcher and type verification

### 8.1 `expect.extend`

```ts
// test/matchers.ts — registered in a preload
import { expect } from "bun:test";

expect.extend({
  toBeCentavos(recebido: unknown) {
    const ok = Number.isInteger(recebido) && (recebido as number) >= 0;
    return {
      pass: ok,
      message: () =>
        `esperava inteiro não negativo em centavos, recebi ${JSON.stringify(recebido)}`,
    };
  },
});
```

A custom matcher pays off when the same composite assertion appears in many tests **and** the default failure message does not say what is wrong. The real gain is the message: `expect(valor).toBeCentavos()` fails explaining the domain, while three chained `expect` calls fail explaining arithmetic.

The same mechanism is what registers the matchers of `@testing-library/jest-dom` — and there it is not a convenience, it is mandatory (`BUN-TEST-12`, in [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md) § 2).

### 8.2 `expectTypeOf` verifies nothing at runtime

```ts
import { expectTypeOf } from "bun:test";

expectTypeOf<string>().toEqualTypeOf<string>();
expectTypeOf(saudar).parameters.toEqualTypeOf<[string]>();
expectTypeOf(Promise.resolve(42)).resolves.toBeNumber();
```

The API is compatible with Vitest's and is a **no-op at runtime**: an entire file of `expectTypeOf` passes in `bun test` without checking a single type. The verification happens in `tsc --noEmit`, in a separate step — the source itself instructs `bunx tsc --noEmit`.

That does not diminish the API: writing a type expectation *in the test file* keeps the contract close to the behavior. Just do not count it as an executed test.

| ID | Rule |
| --- | --- |
| `BUN-TEST-18` | `expectTypeOf` **NEVER** counts as an executed verification — it is a no-op at runtime, and the CI **MUST** run `tsc --noEmit` in a separate step. |

---

## 9. Snapshots

```ts
test("serializa o pedido para o gateway", () => {
  expect(montarPayload(pedido)).toMatchSnapshot();
});
```

On the first run, Bun writes to `__snapshots__/<file>.snap`, next to the test file:

```
projeto/
├── pedido.test.ts
└── __snapshots__/
    └── pedido.test.ts.snap
```

| Matcher | Where it writes |
| --- | --- |
| `toMatchSnapshot()` | `__snapshots__/*.snap` |
| `toMatchInlineSnapshot()` | inside the test file itself, inserted automatically |
| `toThrowErrorMatchingSnapshot()` | `.snap` file, with the error message |
| `toThrowErrorMatchingInlineSnapshot()` | inline |

**Inline × file:** inline is for a small value you want to see next to the assertion (an error message, a three-key object). File is for a large payload — and pays the price of the diff living far from the test.

### Non-deterministic fields

```ts
expect(usuario).toMatchSnapshot({
  id: expect.any(String),
  criadoEm: expect.any(String),
});
```

Without property matchers, a random `id` or a `new Date()` make the snapshot fail on **every** run. What happens in practice is not that the team fixes the test: it is that the team learns to run `-u` by reflex — and from then on the snapshot stops verifying anything.

### `--update-snapshots` is a command for a person

`bun test -u` regenerates. It exists for the moment when **you changed the output on purpose** and are going to read the diff before committing. In the CI test command, it turns the snapshot from an assertion into a record: it starts writing whatever the code produces, including the regression it should have caught.

And the other half: `__snapshots__/` **versioned**. A snapshot outside the repository is generated on the first run of every machine and always passes.

**Verified limit:** a custom serializer (`expect.addSnapshotSerializer`) **is not implemented**. A value whose default representation is poor (a class instance with a lot of internal state, a buffer) is not a good snapshot candidate here — assert fields.

| ID | Rule |
| --- | --- |
| `BUN-TEST-05` | `--update-snapshots` (`-u`) **NEVER** appears in the CI test command, and the `__snapshots__/` directory **MUST** be versioned — a snapshot outside the repository is not an assertion. |
| `BUN-TEST-19` | A snapshot of an object with a non-deterministic field (generated id, date, hash) **MUST** declare property matchers (`{ id: expect.any(String) }`) — without that the snapshot always fails and the team starts running `-u` by reflex. † |

---

## Antipatterns

| Antipattern | Why it fails | What to do |
| --- | --- | --- |
| `expect` inside `catch` without `expect.assertions(n)` | if the function does not throw, the `catch` does not run and the test passes without verifying anything | `expect.assertions(1)` or `.rejects` — `BUN-TEST-06` |
| `test("...", (done) => { … })` without calling `done` | the test hangs until the timeout and fails for the wrong reason | `async`/`await` — `BUN-TEST-17` |
| `test.skip` for a known bug | the test vanishes from the report and nobody notices when the bug is fixed | `test.failing` — `BUN-TEST-11` |
| `test.only` left in the code "because it disables the rest" | without `--only` it filters nothing; if the CI starts passing the flag, the rest of the suite disappears | `-t "name"` locally, and do not commit `.only` — `BUN-TEST-08` |
| `{ retry: 2, repeats: 5 }` in the same test | the source declares the combination invalid | pick one — `BUN-TEST-16` |
| `.toThrow()` with no argument | accepts any error, including the `TypeError` from you having broken the call | pass the class or the message |
| `try/catch` to test a Promise rejection | requires assertion counting so it does not pass silently | `await expect(fn()).rejects.toThrow(X)` |
| `expectTypeOf` as if it verified at runtime | it is a no-op; the file passes without checking a single type | `tsc --noEmit` in a separate step — `BUN-TEST-18` |
| `toMatchSnapshot()` on an object with a random `id` or a `Date` | fails on every run, and the team learns to run `-u` by reflex | property matchers — `BUN-TEST-19` |
| `-u` in the CI test command | the snapshot starts recording any output, including the regression | `-u` is a command for a person, and the diff goes to the PR — `BUN-TEST-05` |
| `__snapshots__/` in `.gitignore` | it is generated on the first run of every machine and always passes | version it — `BUN-TEST-05` |
| `timeout: 0` in a CI test | trades a failure for a hung job | fix the cause (almost always a missing `await`) |
| `test.each` with `if` in the body to handle each row | the table stopped being a table; three explicit tests are smaller | separate tests |
| Object row in `each` destructured as an array | the object becomes **one** argument; the following parameters are left `undefined` | `({ a, b }) => …` |

---

## Review checklist

- [ ] Does every conditional assertion (in `catch`, callback, `if`) have `expect.assertions(n)`? → `BUN-TEST-06`
- [ ] Does no test use `done`? → `BUN-TEST-17`
- [ ] Are known bugs marked as `test.failing`, not `test.skip`? → `BUN-TEST-11`
- [ ] No `.only` committed? → `BUN-TEST-08`
- [ ] Does no test combine `retry` and `repeats`? → `BUN-TEST-16`
- [ ] Does `.toThrow` receive a class or a message, never empty?
- [ ] Do snapshots of objects with a variable field use property matchers? → `BUN-TEST-19`
- [ ] Does the CI run without `-u`, and is `__snapshots__/` versioned? → `BUN-TEST-05`
- [ ] Is there a separate `tsc --noEmit` step? → `BUN-TEST-18`
- [ ] `toStrictEqual` where the exact shape of the object is the contract?

---

## Related

- [Bun - Tests](bun-tests.md) — hub, mental model, API map, decision trees
- [Bun - Tests - Execution and Configuration](bun-tests-execution-and-configuration.md) · [Bun - Tests - Mocks and Time](bun-tests-mocks-and-time.md) · [Bun - Tests - Lifecycle and Isolation](bun-tests-lifecycle-and-isolation.md) · [Bun - Tests - DOM and Components](bun-tests-dom-and-components.md) · [Bun - Tests - Coverage and CI](bun-tests-coverage-and-ci.md)
- — what to test, before how
- `TypeScript` — `tsc --noEmit` as a verification step

## Sources consulted

Verified on **2026-08-20**: [Writing tests](https://bun.com/docs/test/writing-tests) · [Snapshots](https://bun.com/docs/test/snapshots) · [Test runner](https://bun.com/docs/test) · [Runtime behavior](https://bun.com/docs/test/runtime-behavior) · [Jest compatibility tracking issue](https://github.com/oven-sh/bun/issues/1825) (cited by the source as the reference for its status).
