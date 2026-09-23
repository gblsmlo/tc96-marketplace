# Three things you do not assume from memory

> They contradict habits brought from Jest and Vitest, and are the source of most errors in generated code.


These contradict habits brought from Jest and Vitest, and are the source of most errors in generated code.

**1. Without a flag, every file shares one `globalThis`.** There is no per-file isolation. "Leaked" does not mean "affected the next test": it means "affected the rest of the suite". Write as if the next file were going to read everything you left behind — because it will.

**2. `mock.restore` does not undo `mock.module`.** The three cleanups do different things, and the table is in [Bun - Testes - Mocks e Tempo](../../../../knowledge-base/bun-testes-mocks-e-tempo.md) § 3. `clearAllMocks` preserves the implementation; `resetAllMocks` removes it but does not restore the spy's original; only `restore` restores — and none of the three touches a module mock.

**3. Concurrency inside a file shares state.** `test.concurrent` (and the suite under `--concurrent`) isolates nothing: anything depending on order or mutable state has to be `test.serial` — `BUN-TEST-23`. And `onTestFinished` does not work in a concurrent test — `BUN-TEST-22`.

---


---

## Why these three, and not others

All three describe **the same kind of failure**: the test goes green and the verification did not
happen, or happened somewhere else. None of them produces an error, a warning or a wrong type —
which is why there is no way to find them by reading the code without knowing they exist.

| Jest/Vitest memory says | In Bun |
| --- | --- |
| each file has its own environment | one `globalThis` shared by all, without a flag |
| `restoreAllMocks` undoes everything | `mock.restore` does not touch a **module** mock (`BUN-TEST-03`) |
| `test.concurrent` isolates | it isolates nothing; mutable state requires `test.serial` (`BUN-TEST-23`) |
| `useFakeTimers` freezes `Date` | it does not swap the constructor; a date is `setSystemTime` (`BUN-TEST-20`) |

## Related

- [Bun - Testes](../../../../knowledge-base/bun-testes.md) § 2 — the execution model
- [Bun - Testes - Mocks e Tempo](../../../../knowledge-base/bun-testes-mocks-e-tempo.md) § 3 — the table of the three cleanups
- [Bun - Testes - Ciclo de Vida e Isolamento](../../../../knowledge-base/bun-testes-ciclo-de-vida-e-isolamento.md) — scope, preload, `--isolate`
