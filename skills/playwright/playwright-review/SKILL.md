---
nome: playwright-review
descricao: Audit an existing Playwright suite with eight executable probes before reading code, an eleven-level scan by defect frequency, an extra checklist for agent-generated tests, and findings with `PW-*` IDs — use when the task is reviewing a repository's or a PR's E2E suite, hunting for an assertion that asserts nothing, a time-based wait, a fragile locator, a committed session, a `test.only` with no gate, a disabled trace or a misconfigured shard. Do not use to write a new test, which is playwright-build, to diagnose a concrete failure, which is playwright-diagnose, nor to audit the shape of the suite across levels, which is test-review.
tipo: skill
familia: playwright
idioma: en
fonte: "[Playwright](../../../knowledge-base/docs/playwright.md)"
docs:
  - /microsoft/playwright
tags:
  - skill
  - playwright
  - testing
  - code-review
---

# playwright-review

> **Source of this skill:** [Playwright](../../../knowledge-base/docs/playwright.md) — the normative § 6 (85 rules), § 6.1 with the satellites' critical ones, and § 6.2 with the canonical IDs. The body of each family lives in the satellite that owns the ID.
> This skill **does not contain** the text of the rules — it says what to run, in what order to scan, how to classify and how to report.
> **API surface:** resolve it through Context7 — `/microsoft/playwright`. Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

Contract this skill implements: [Playwright](../../../knowledge-base/docs/playwright.md) § 7 ("Contrato de skill").

---

## When to use

Auditing an E2E suite that **already exists**: the whole repository, a directory, or a PR's tests.

| Situation | Go to |
| --- | --- |
| writing or rewriting a test | `playwright-build` |
| one concrete failure, or flakiness with a trace available | `playwright-diagnose` |
| the **shape** of the suite across levels (E2E × unit × component) | `test-review` |
| an unstable suite as a system, flakiness rate | `test-diagnose` |
| reviewing a test under `bun test` | `bun-test-review` |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Playwright](../../../knowledge-base/docs/playwright.md) § 0 | the Node floor and the timeout table |
| 2 | [Playwright](../../../knowledge-base/docs/playwright.md) § 6 and § 6.1 | the inviolable rules and the critical ones |
| 3 | `references/mapa-de-ids.md` | **required before citing** — two IDs are aliases |
| 4 | the satellite for the finding | via § 4 of the hub |

**Never load all twelve satellites.**

References in this skill:

| File | What for |
| --- | --- |
| `references/sondas.md` | the eight probes, the three mandatory stops, and what they do not catch |
| `references/ordem-da-varredura.md` | the 11 levels, and the extra checklist for agent-generated tests |
| `references/severidade-e-relatorio.md` | classification, format with probe evidence, the cut, the closing |
| `references/antipadroes.md` | ~70 antipatterns with ID and satellite |
| `references/mapa-de-ids.md` | the 85 `PW-*` by satellite and section |
| `references/exemplo-auditoria.md` | a whole audit, from the probe to the "not verified" |
| `scripts/sondas.sh` | runs the eight probes |
| `scripts/gerar-mapa-de-ids.sh` | regenerates the map across the three Playwright skills |

---

## Step 1 — Probe before reading

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/playwright-review/scripts/sondas.sh e2e
```

**Three mandatory stops:**

| Probe | If it shows… | Why |
| --- | --- | --- |
| S2 | `.only` without `forbidOnly` | CI may be green running **1 of N** |
| S8 | `storageState` outside `.gitignore` | a **security finding**, report it separately and first |
| S3 | `trace: 'off'` | the flakiness audit **stops here**: the first finding is the configuration |

And a fourth, blocking without interrupting: **S6 without `no-floating-promises`** — an assertion without `await` always passes and nobody sees it.

---

## Step 2 — Scan in the order that fails most

`references/ordem-da-varredura.md`: an assertion that asserts nothing → an invented wait → a fragile locator → an action that switches off verification → isolation and session → **wrong level** → structure → network and data → snapshots → configuration and CI → style.

If the suite has agent tests, **also** apply the extra checklist — the central item is **an assertion deleted by a healer**: the easiest way to make a test pass is to remove what it asserted (`PW-AGT-05`).

---

## Step 3 — Classify and report

`references/severidade-e-relatorio.md`. Blocking is what **makes CI lie**; High is what produces flakiness today; Medium is debt.

For a probe, **the evidence is the command's output** — paste it, including the exit code when the exit code is the finding.

**Three things are not findings:** the absence of a test, `getByTestId` with the debt recorded, and the choice of suite proportion (that is `TS-CORE-02`, in `test-review`).

---

## Step 4 — Closing

1. **Turn a probe into a gate** — `forbidOnly`, `trace`, lint, `.gitignore`.
2. **Separate "not protected" from "broken"**, and **"wrong level" from "bad test"**: the second is fixed by moving, not by improving.
3. **Order by severity**, not by file.
4. **An exposed credential goes separately and first.**
5. **Declare what was not verified.**
6. **If the fix is writing a test**, the source becomes `playwright-build`.

---

## Example

A suite of 214 tests, CI green. The probes find `.only` without `forbidOnly`, `trace: 'off'`, `storageState` outside `.gitignore` and the two packages' versions out of lockstep under Node 20. **Three stops fire.** The credential goes first and separately; "there is too much E2E" is handed back to the strategy skill; what the grep did not cover is declared.

Full audit: `references/exemplo-auditoria.md`.

---

## Related

- [Playwright](../../../knowledge-base/docs/playwright.md) — source of this skill: § 6, § 6.1, § 6.2, § 7
- `playwright-build` · `playwright-diagnose` — the sibling skills
- `test-review` — audits the **shape** across levels; this one audits the **tests**
- `bun-test-review` — the equivalent audit under Bun
- `react-review` · `drizzle-review` — where the finding format comes from
