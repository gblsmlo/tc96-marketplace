# Measure before opining

> This skill distinguishes itself from hallway conversation exactly here: **flakiness has a
> number, and the number has a threshold.**

---

## Step 0 — the question that comes first

> **Are the failures real product defects?**

If so, **the suite did its job** and there is nothing to diagnose. Confusing "too much red"
with "bad suite" is how a team switches off the only thing that was warning them.

The distinguishing signal: a **deterministic** failure (always in the same place, with the same
message) is a defect; an **intermittent** failure is the suite. Only the second case belongs to
this skill.

---

## The measurements

| Metric | How to obtain it | Reference |
| --- | --- | --- |
| **flakiness rate** | runs that failed and passed on re-run ÷ total, in the CI history — or `scripts/medir-flakiness.sh` | **~1% is where the suite loses value**; Google's index is ~0.15% |
| **useless investigations/day** | rate × number of tests × runs per day | 0.1% × 10,000 = **10 per day** |
| **escape rate** | defects found in production ÷ total defects | the most honest metric there is |
| **duration** | suite time per level | if nobody runs it before the PR, it has stopped being a gate |
| **active retry** | the script's inventory | retry is an anesthetic (`TS-SUI-03`) |
| **accumulated `skip`** | the script's inventory | debt, and frequently hidden flakiness |

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/test-diagnose/scripts/medir-flakiness.sh "bun test" 20
```

The script does two things: it **inventories the anesthetics already installed** (retry,
workers=1, `skip`, fixed-time waits, real clock, numeric prefix, `try/catch` in the body) and
**measures the rate** by repeating the command N times.

---

## Why the rate, and not the impression

A suite at 0.05% flakiness and one at 3% have the **same perceived symptom** ("it fails
sometimes") and opposite prognoses: the first is healthy and someone got unlucky; the second has
lost value and needs intervention.

**The argument that closes any discussion about "living with flaky":** above ~1%, people stop
believing the red — and the **real** red passes along with the false ones. The cost is not the
time to re-run; it is the loss of signal (`TS-CORE-04`).

**Beware the zero.** 20 green runs do not prove the absence of a 1-in-50 flake. If the measured
rate is 0 and the team reports instability, the right measurement is the **CI history**, not one
more local round.

---

## Related

- [Teste de Software - Confiabilidade da Suíte](../../../../knowledge-base/teste-de-software-confiabilidade-da-suite.md) § 1 — the arithmetic
- [Teste de Software](../../../../knowledge-base/teste-de-software.md) § 2, claim 5 — an untrustworthy suite is worse than none
- `causas-de-flake.md` — the next step, once you have the number
