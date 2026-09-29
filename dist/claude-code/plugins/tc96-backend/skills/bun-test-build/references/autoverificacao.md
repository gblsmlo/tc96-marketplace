# Self-check before delivering

Do not deliver a test without going through this list. Every line is a failure that stays **green**:

- [ ] Does the file match a discovery pattern? → `BUN-TEST-01`
- [ ] Does every assertion in a `catch`, callback or `if` have `expect.assertions(n)`? → `BUN-TEST-06`
- [ ] Does every `spyOn` have guaranteed restoration? → `BUN-TEST-02`
- [ ] Does no `mock.module` rely on automatic restoration? → `BUN-TEST-03`
- [ ] No `.only`, and is a known bug in `test.failing`? → `BUN-TEST-08`, `BUN-TEST-11`
- [ ] No `Bun.sleep` waiting on a render or a timer?
- [ ] Does an object snapshot with a varying field use property matchers? → `BUN-TEST-19`
- [ ] Component: is `cleanup` present and every `userEvent` awaited? → `BUN-TEST-26`
- [ ] Does a formatted date have a fixed timezone? → `BUN-TEST-21`
- [ ] Does a concurrent test avoid sharing mutable state? → `BUN-TEST-23`

And the two that require execution, not reading:

```bash
bun test./path/to-the-new.test.ts # passes in isolation
bun test --randomize # the suite still passes in random order
tsc --noEmit # the runner does not type-check — BUN-TEST-18
```

**Actually run all three.** "Should pass" is not verification: if you did not run it, declare that you did not. If `--randomize` broke after your test, you have just introduced order dependence (`BUN-TEST-09`): the setup it depends on has to move into the file itself, and no flag replaces that. The full diagnosis is `bun-test-review`.

---

## What to deliver

Three parts, always, and the third is the one that usually goes missing:

1. **The code** — the test or the configuration, in the pattern the suite already uses. If the repository has the right pattern in another file, extend that pattern rather than introducing a new one.
2. **What was run**, with the result: which of the three commands above ran and what they returned. Paste the output when the output is the argument.
3. **What was not verified**, named. A suite that does not start, a database that is down, `tsc` not run: say which and why. **"Should pass" is not a result** — declaring the gap is what separates a verified delivery from a plausible one.

---


---

## Script

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/bun-test-build/scripts/autoverificar.sh test/session.test.ts
```

It covers the mechanical items and marks as **heuristic** the four that require reading
(assertion in `catch`, timezone, `cleanup`, awaited `userEvent`).
