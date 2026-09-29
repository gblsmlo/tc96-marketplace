# The seven probes — before reading the code

> In a test suite, **the worst defects are invisible to reading**: the file looks complete,
> the tests look right, CI is green — and even so the file never ran, the gate never closed,
> or the suite only passes in today's order.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/bun-test-review/scripts/sondas.sh # mechanical ones only
bash ${CLAUDE_PLUGIN_ROOT}/skills/bun-test-review/scripts/sondas.sh --rodar # + the ones needing the suite up
```

| Probe | How | What it reveals |
| --- | --- | --- |
| **S1. Test that never runs** | `find. -path./node_modules -prune -o -name '*[Tt]est*' -print \| grep -Ev '\.(test\|spec)\.[cm]?[jt]sx?$\|_(test\|spec)\.[cm]?[jt]sx?$'` | `BUN-TEST-01` — a file outside the discovery pattern does not run and raises no warning |
| **S2. Order dependence** | `bun test --randomize; echo "exit=$?"` — and, if it fails, `bun test --randomize --seed <n>` to reproduce | `BUN-TEST-09` — the suite passes in discovery order and breaks in any other |
| **S3. Dependence on the shared global** | `bun test --isolate` | which files only passed because another ran first; under `--parallel` that is tomorrow's CI |
| **S4. Flakiness that is not about order** | `bun test --rerun-each 20` | a missing `await`, a real timer, concurrency — failure that a single run hides |
| **S5. Does the coverage gate close?** | `grep -nE 'coverageThreshold\|coverageReporter' bunfig.toml` and then `bun test --coverage; echo "exit=$?"` | `BUN-TEST-27`, `BUN-TEST-28` — a threshold without the `text` reporter (outside `--parallel`), or declared on `statements`, **fails nothing** |
| **S6. Does mock restoration exist?** | `grep -rn 'mock.restore' $(grep -oE '"[^"]+\.ts"' bunfig.toml \| tr -d '"')` — or `grep -rn 'preload' bunfig.toml` and read each file | `BUN-TEST-02` — without `mock.restore` in a preload, every `spyOn` in the suite is a leak candidate |
| **S7. Marks and commands** | `grep -rn '\.only(\|\.skip(' --include='*.test.*' --include='*.spec.*'.` and `grep -rn 'update-snapshots\|--retry\|tsc --noEmit' package.json.github/` | `BUN-TEST-05`, `BUN-TEST-08`, `BUN-TEST-11`, `BUN-TEST-18` — committed marks, `-u` in CI, global retry, missing typecheck |

S1, S6 and S7 are mechanical reading and run in seconds. S2, S3 and S4 need the suite up. S5 needs both: reading the configuration **and** checking the exit code.

**If S1 finds a file, or S5 shows an open gate, report before continuing.** In both cases reviewing content loses its point: a file that never ran has no assertion defect that matters, and a gate that never closes makes any discussion of coverage decorative.


---

## What the probe does not catch

| Not mechanically detectable | Rule | How to find it |
| --- | --- | --- |
| `expect` in a `catch`/callback without a count | `BUN-TEST-06` | look for `catch (` in the test file and check for `expect.assertions(n)` |
| a module mock expecting restoration | `BUN-TEST-03` | read each `mock.module` and see whether anything relies on undoing it |
| an expensive or non-idempotent preload | `BUN-TEST-24` | read the preload: a server or a migration there only breaks under `--parallel` |
| `test.serial` used for a dependency **between files** | `BUN-TEST-09` | it is the wrong fix: `serial` sequences within the file |

## Related

- `ordem-da-varredura.md` — what to do with what the probes pointed at
- `severidade-e-relatorio.md` — classify and write
- `mapa-de-ids.md` — where each `BUN-TEST-*` has its body
