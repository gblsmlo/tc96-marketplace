# The scan order

> By impact on the suite's ability to **give signal** — not by directory.
> If a step produces a finding that invalidates the next one, **stop auditing the interior** and
> report the change of shape.

| # | Question | IDs | Why in this position |
| --- | --- | --- | --- |
| 1 | **Does the gate lie?** | `TS-PROC-03`, `TS-CORE-05` | it produces **false institutional confidence**, not just one bad test |
| 2 | **Is the shape inverted?** | `TS-NIV-04`, `TS-CORE-02`, `TS-NIV-02` | mass in E2E; the same logic at three levels; business rules in E2E |
| 3 | **Is there an uncovered risk class?** | `TS-TIPO-02` | the five states; the **error** one is the most absent and the most visible |
| 4 | **Does the static layer count?** | `TS-TIPO-08` | `strict` off, lint without the rules that catch what types do not |
| 5 | **Does the non-functional attribute have a number?** | `TS-TIPO-05`, `TS-TIPO-06` | "it should be fast"; mean instead of percentile |
| 6 | **Is the contract with the outside verified?** | `TS-NIV-09` | a shared type treated as a complete test |
| 7 | **Is the replacement in the right place?** | `TS-CORE-03`, `TS-DUB-03`, `TS-DUB-08` | mocking what the test came to prove; a fake without fidelity |
| 8 | **Is determinism a decision or an accident?** | `TS-SUI-05`, `TS-DUB-05` | if there is active flakiness, **stop** and go to `test-diagnose` |
| 9 | **Did the retest become a regression test?** | `TS-TIPO-03`, `TS-TIPO-04` | a fix verified only in the ticket |
| 10 | **Does exploratory testing exist?** | `TS-TIPO-09` | an automated suite as the whole strategy: excellent regression, zero discovery |
| 11 | **Is there a test that does not pay?** | `TS-SUI-10` | a level duplicate, a getter test, a test written for a coverage target |

---

## The three conclusions, which do not mix

A report from this skill separates:

| Conclusion | Whose it is |
| --- | --- |
| **not protected** — a risk class with no test | this skill's |
| **at the wrong level** — the shape | this skill's |
| **broken** — a defect in the test, `file:line` | `playwright-review` · `bun-test-review` |

A repository can pass both tool skills and fail here — and it is the most common case: 200 of
the 214 tests are E2E, all well written, and none covers the error state.

---

## Related

- `sondas.md` — what to run first
- `severidade-e-relatorio.md` — classify and report
- `test-diagnose` — when the scan finds active flakiness
