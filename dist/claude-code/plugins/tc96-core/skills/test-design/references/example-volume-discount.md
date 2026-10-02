# Worked example — volume discount at checkout

Task: *"cover the volume discount at checkout"*.

---

## Step 1 — the sentence

> "A discount above 50% can be applied without going through manager approval."

Subject and wrong behavior: actionable. Compare with "checkout might break", which points at no
level at all.

## Step 2 — the level

It is a **business rule**, not a journey → unit (`TS-NIV-02`). E2E gets **one** case: the
screen displays the value the calculation produced.

## Step 3 — the proportion

The pricing module is dense calculation → **pyramid**, mass in unit tests (`TS-NIV-08`).

## Step 4 — the cases

The rule has a range (0–50% free, above that requires approval) → **boundary value** (`TS-TEC-01`):

| Discount | Expected | Why |
| --- | --- | --- |
| 0% | applies | lower boundary |
| 50% | applies | **the limit** |
| 50.01% | requires approval | just above |
| 100% | requires approval | extreme |
| −5% | rejects | invalid class (`TS-TEC-02`) |

Plus state transition: approving an **already approved** discount, and applying a **rejected** one
(`TS-TEC-04`).

## Step 5 — replacement

The calculation is pure: **nothing to replace**. E2E needs an existing order → create it through
the API, not through the UI (`TS-CORE-03`). If the rule uses "promotion date", the clock is
controlled (`TS-DUB-05`).

## The result

**5 unit tests + 2 transition tests + 1 E2E.**

The intuitive alternative — 8 E2E runs through checkout — would cost minutes per run, would fail
on any defect along the way, and would diagnose worse. It is the same number of cases buying far
less information.

## Step 7 — the handoff

| Level | Continues in |
| --- | --- |
| unit, transition | `bun-test-build` |
| E2E | `playwright-build` |

Deliver together: **level, derived cases and what will be replaced**. The tool skill implements;
it does not reopen those questions.
