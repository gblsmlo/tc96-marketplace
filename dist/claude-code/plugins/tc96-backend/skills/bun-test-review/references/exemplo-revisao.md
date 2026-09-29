# Worked example — reviewing a suite under `bun test`

A monorepo, 180 tests, green CI, and a payment defect reached production.

---

## Step 1 — the probes, before reading a single test

```
$ bash scripts/sondas.sh --rodar

== S1. Test that never runs
./apps/api/test/webhookTests.ts ← outside the discovery pattern
== S6. Does mock restoration exist?
 bunfig.toml:4: preload = ["./test/setup.ts"]
 NO mock.restore in the suite
== S7. Marks and commands
 apps/web/test/cart.test.ts:12: test.only(
.github/workflows/ci.yml:29: bun test -u
== S5. Does the coverage gate close?
 bunfig.toml:8: coverageThreshold = { statements = 80 }
== S2. Order dependence → exit≠0 (FAILED)
== S3. Dependence on the global → exit=0 (passed)
== S4. Flakiness that is not about order → exit=0
```

**S1 and S5 triggered a stop.** And S2 failing with S3 passing is the classic signature:
state leaks through the shared `globalThis`, and `--isolate` hides the symptom.

## Step 2 — the reading, guided by the probes

`test/setup.ts` has no `afterEach( => mock.restore)`. Two files use `spyOn` without
restoring. And `apps/api/test/payment.test.ts:34` has an `expect` inside a `catch`, without
a count — the test passes when `charge` does **not** throw, which is exactly the defect that
reached production.

## The report

```markdown
## Suite review — bun test

### Blocking (4)

`BUN-TEST-01` — apps/api/test/webhookTests.ts
S1: the name matches no discovery pattern. The file never ran, and nothing warns.
Fix: rename to webhook.test.ts. Run it afterwards: it may have been red for months.
See Bun - Testes - Execução e Configuração.

`BUN-TEST-06` — apps/api/test/payment.test.ts:34
The assertion lives in the catch and the test passes when charge does not throw: no assertion runs.
Fix: expect.assertions(1) at the top, or switch to
 await expect(charge(...)).rejects.toThrow(PaymentDeclined).
See Bun - Testes - Escrita e Asserções.

`BUN-TEST-28` — bunfig.toml:8
S5: coverageThreshold declared on `statements`, which is not the metric evaluated.
The gate has never failed.
Fix: use `lines`/`functions`, and keep the `text` reporter in the list (BUN-TEST-27).
See Bun - Testes - Cobertura e CI.

`BUN-TEST-05` —.github/workflows/ci.yml:29
S7: `bun test -u` in CI rewrites the snapshots on every run: they never fail.
Fix: remove the -u. Updating a snapshot is a local, reviewed act.
See Bun - Testes - Escrita e Asserções.

### High (2)

`BUN-TEST-02` — test/setup.ts (absence) + apps/web/test/price.test.ts:9
S6 + S2: the preload does not restore mocks, and `bun test --randomize` fails. Two files use
 spyOn without restoring; state leaks through the shared globalThis (S3 passed, which is the
 signature of that leak).
Fix: afterEach( => mock.restore) in the preload — one line that closes the whole class.
 Then run --randomize again: whatever still fails is real order dependence.
See Bun - Testes - Mocks e Tempo.

`BUN-TEST-08` — apps/web/test/cart.test.ts:12
S7: test.only committed. If CI runs that file, it runs 1 test out of N.
Fix: remove it.
See Bun - Testes - Escrita e Asserções.

### Not a finding (recorded)

- 61% coverage in apps/api: low coverage is not a finding of this skill — the finding is the
 decorative threshold, above.
- "They should use Vitest": tool preference, out of scope.

### Not verified

- S4 ran with the suite already broken by S2; repeat after fixing the preload.
- Behavior under `--parallel` was not exercised: if any test uses an external resource,
 BUN-TEST-10 comes into play and requires a key derived from BUN_TEST_WORKER_ID.
```

## What this example demonstrates

| Decision | Where the rule is |
| --- | --- |
| two stops triggered before any reading | `sondas.md` |
| S2 failing **with** S3 passing named the cause | `ordem-da-varredura.md` § *Flakiness diagnosis* |
| the fix for the leak is **one line in the preload**, not file by file | `BUN-TEST-02` |
| low coverage did not become a finding; the decorative threshold did | `severidade-e-relatorio.md` |
| the probe that ran over a broken suite was declared inconclusive | § *Closing* |
