# Severity, format and the cut

| Severity | What goes in |
| --- | --- |
| **Blocking** | a test that **never runs** (`BUN-TEST-01`); an assertion that never executes (`BUN-TEST-06`); a coverage gate that does not fail (`BUN-TEST-27`, `BUN-TEST-28`); `-u` in CI (`BUN-TEST-05`); missing typecheck (`BUN-TEST-18`) |
| **High** | mock/spy leakage (`BUN-TEST-02`, `BUN-TEST-03`); order dependence between files (`BUN-TEST-09`); a shared resource under `--parallel` (`BUN-TEST-10`); an unregistered DOM matcher (`BUN-TEST-12`); a committed `.only` (`BUN-TEST-08`) |
| **Medium** | missing `cleanup` (`BUN-TEST-26`); a missing `await` on `userEvent`; a snapshot without a property matcher (`BUN-TEST-19`); a `.skip` on a known bug (`BUN-TEST-11`); an unpinned version (`BUN-TEST-15`) |
| **Low** | preference without an ID — **not a finding**, see Step 6 |

The criterion that decides between Blocking and High: **does the defect make CI lie?** A test that does not run and a gate that does not close produce false green — a different category of problem from "fragile test".

---

## Step 5 — Output format of a finding

Four parts, the same contract as `react-review` and `drizzle-review`:

```
`RULE-ID` — file:line
<what is wrong, one sentence>
Fix: <concrete change>
See the corresponding satellite.
```

### Example

```
`BUN-TEST-06` — apps/api/test/payment.test.ts:34
The assertion lives in the catch and the test passes when charge does not throw: no assertion runs.
Fix: expect.assertions(1) at the top, or switch to await expect(charge(...)).rejects.toThrow(PaymentDeclined).
See Bun - Testes - Escrita e Asserções.
```

Rules of the format:

- **ID checked against § 6** before writing.
- **`file:line` always.** For a probe, the evidence is the command's output — paste it, including the exit code when the exit code is the finding (S5).
- **Concrete fix.** If the suite already has the right pattern in another file, point at that file: extending the established pattern is worth more than introducing a new one.
- **One satellite link.**

---

## Step 6 — The cut: finding × opinion

**A finding without a rule ID is an opinion**, with three ways out:

1. **There is an ID** → a finding, cite the ID.
2. **There is no ID, but there is a normative note** (what to test, external-integration policy, what to assert in a component) → cite the note: "", "". Do not invent `BUN-TEST-*`.
3. **Neither ID nor note** → a separate "Suggestions (no rule)" section, never mixed with the findings.

Two cases that are **not** findings, and confusing them burns the report's credibility:

- **Absence of a test.** "This module has no test" is a strategy decision, not a rule violation —. Report it as a question, not as a defect.
- **Assertion style.** `toEqual` where you would use `toStrictEqual` is only a finding if the exact shape is the contract. Without that argument, it is preference.

If the scan finds a recurring, real defect with no matching rule, the right product is a **rule proposal** for [Bun - Testes](../../../../knowledge-base/docs/bun-testes.md) § 6 — suggested ID, text and the case that motivated it — not a fake citation.
