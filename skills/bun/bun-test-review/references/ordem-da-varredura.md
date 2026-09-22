# The scan order, and flakiness diagnosis

1. **Assertion that may not have run** — `BUN-TEST-06`. It comes first because it is the defect that produces a green test with no verification at all: `expect` in a `catch`, in a callback, inside an `if`. Look for `catch (` in test files and check whether there is a count.
2. **Mock and spy leakage** — `BUN-TEST-02`, `BUN-TEST-03`, `BUN-TEST-04`. Every `spyOn` without guaranteed restoration; every `mock.module` expecting to be undone; every mock trying to avoid an import side effect outside the preload.
3. **Isolation and order** — `BUN-TEST-09`, `BUN-TEST-10`, `BUN-TEST-23`, `BUN-TEST-24`. State across files, a shared resource under `--parallel`, concurrency with mutable state, an expensive preload.
4. **Waiting and time** — a missing `await` on `userEvent`, `Bun.sleep`, `useFakeTimers` used to freeze a date (`BUN-TEST-20`), a formatted date without a timezone (`BUN-TEST-21`).
5. **Marks that erase signal** — `BUN-TEST-08`, `BUN-TEST-11`. A committed `.only`, a `.skip` covering a known bug.
6. **Snapshot** — `BUN-TEST-05`, `BUN-TEST-19`. `-u` in CI, `__snapshots__/` ignored, a non-deterministic field without a property matcher.
7. **DOM and component** — `BUN-TEST-07`, `BUN-TEST-12`, `BUN-TEST-25`, `BUN-TEST-26`. Registration outside the preload, matchers not registered, a single preload, missing `cleanup`.
8. **CI gates** — `BUN-TEST-15`, `BUN-TEST-18`, `BUN-TEST-27`, `BUN-TEST-28`, `BUN-TEST-29`. Unpinned version, missing typecheck, decorative threshold, `junit` without an outfile.
9. **Configuration** — `BUN-TEST-13`, `BUN-TEST-14`, `BUN-TEST-16`, `BUN-TEST-17`, `BUN-TEST-22`. A glob on the command line, `seed` without `randomize`, `retry` with `repeats`, `done`, `onTestFinished` in a concurrent test.

If a step produces a finding that invalidates the next one (the preload does not restore mocks; the suite does not pass with `--randomize`), **stop reviewing the interior** and report the change of shape, not the detail.

---

## Step 3 — Flakiness diagnosis: symptom → cause

The full tree is § 5.1 of the hub. The reading of the probes:

| Symptom | Likely cause | Rule / satellite |
| --- | --- | --- |
| Passes alone, fails together, and `--isolate` fixes it | state in the shared global: spy, mocked module, module state | `BUN-TEST-02`, `BUN-TEST-03`, `BUN-TEST-09` |
| Fails only with `--parallel` | an external resource shared across workers | `BUN-TEST-10` |
| Fails only with `--parallel`, and it is setup that starts something | preload hooks wrap **each file** | `BUN-TEST-24` |
| Fails within the same file, depending on order | concurrency with mutable state | `BUN-TEST-23` |
| A component finds an element from another test | shared `document` without cleanup | `BUN-TEST-26` |
| Intermittent failure with no order pattern | a missing `await`, or a real timer | [Bun - Testes - DOM e Componentes](../../../../knowledge-base/docs/bun-testes-dom-e-componentes.md) § 3 |
| Snapshot fails on every run | a non-deterministic field | `BUN-TEST-19` |
| A test "disappeared" from the report | `.skip`, or a file outside the pattern | `BUN-TEST-11`, `BUN-TEST-01` |
| All tests green and exit ≠ 0 | an unhandled error outside a test | [Bun - Testes - Execução e Configuração](../../../../knowledge-base/docs/bun-testes-execucao-e-configuracao.md) § 6 |
| `beforeAll` failed and the report shows "skip" | a hook error skips the whole scope | [Bun - Testes - Ciclo de Vida e Isolamento](../../../../knowledge-base/docs/bun-testes-ciclo-de-vida-e-isolamento.md) § 2 |

**`test.serial` never resolves a dependency between files** — it sequences within the file. If the fix proposed by someone (or by you) is `test.serial` for a test that depends on another file, it is wrong: `BUN-TEST-09`.

---

---

## Related

- [Bun - Testes](../../../../knowledge-base/docs/bun-testes.md) § 5.1 — the full flakiness tree
- `sondas.md` — what to run first
- `severidade-e-relatorio.md` — classify and report
