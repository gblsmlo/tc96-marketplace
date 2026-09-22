# Worked example — the session expires in 30 minutes

Task: *"test that the session expires 30 minutes after the last access"*.

**The task is about time**, so the first decision is not how to write the test — it is which time API to use. The "three things you do not assume from memory" already answer it: `useFakeTimers` does **not** swap the `Date` constructor; freezing a date is `setSystemTime`, and the two are orthogonal (`BUN-TEST-20`).

```ts
import { test, expect, beforeEach, afterEach, setSystemTime, spyOn } from 'bun:test';
import { sessionExpired, recordAccess } from '../src/session';
import * as audit from '../src/audit';

const T0 = new Date('2026-03-10T12:00:00.000Z');

beforeEach( => setSystemTime(T0));
afterEach( => setSystemTime); // gives the real clock back

test('session does not expire before 30 min', => {
 recordAccess('s1');
 setSystemTime(new Date(T0.getTime + 29 * 60_000));
 expect(sessionExpired('s1')).toBe(false);
});

test('session expires at exactly 30 min', => {
 recordAccess('s1');
 setSystemTime(new Date(T0.getTime + 30 * 60_000));
 expect(sessionExpired('s1')).toBe(true);
});

test('expiration is audited once', => {
 const log = spyOn(audit, 'record');
 recordAccess('s1');
 setSystemTime(new Date(T0.getTime + 31 * 60_000));
 sessionExpired('s1');
 expect(log).toHaveBeenCalledTimes(1);
 log.mockRestore; // guaranteed restoration
});
```

**The decisions, and what each one prevented:**

| Decision | Alternative that goes **green and wrong** | Rule |
| --- | --- | --- |
| `setSystemTime` to freeze the date | `useFakeTimers` — it does not swap `Date`, and the test passes by chance | `BUN-TEST-20` |
| `afterEach( => setSystemTime)` | the clock leaking into the following tests | `BUN-TEST-20` |
| explicit `log.mockRestore` | the spy leaking across the whole suite | `BUN-TEST-02` |
| 29 / 30 / 31 min | just "a lot of time passed" — does not catch `>` × `>=` | boundary value, [Teste de Software - Técnicas de Design de Caso](../../../../knowledge-base/docs/teste-de-software-tecnicas-de-design-de-caso.md) |
| absolute instant in UTC | a real `new Date`, and the test fails at the day boundary | `BUN-TEST-21` |
| `expect` in the body, not in `catch` | an assertion that never runs | `BUN-TEST-06` |

**What was run**, which is the part that usually goes missing:

```bash
bun test./test/session.test.ts # 3 pass, 0 fail
bun test --randomize # 41 pass — the suite survives random order
tsc --noEmit # no errors
```

**What was not verified:** behavior under `--parallel`, because this module keeps the session registry in process memory — if it moves to Redis, `BUN-TEST-10` comes into play and the test needs a per-worker key.

---

## Boundary with the other skills
