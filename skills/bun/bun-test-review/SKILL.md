---
nome: bun-test-review
descricao: Review an existing `bun test` suite and diagnose flaky tests, citing `BUN-TEST-*` IDs, with seven executable probes for the defects that reading code does not find — use when the task is reviewing a project's tests, investigating "passes alone and fails in the suite", finding a test that never runs, checking whether the coverage and type gates actually close, or classifying the severity of a test finding. Do not use to write a new test or configure a suite from scratch, which is bun-test-build, nor for the shape of the suite across levels, which is test-review.
tipo: skill
familia: bun
idioma: en
fonte: "[Bun - Testes](../../../knowledge-base/docs/bun-testes.md)"
docs:
  - /oven-sh/bun
tags:
  - skill
  - bun
  - testing
  - code-review
---

# bun-test-review

> **Source of this skill:** [Bun - Testes](../../../knowledge-base/docs/bun-testes.md) — the normative § 6 (`BUN-TEST-01` to `BUN-TEST-29`), § 6.1 with the seven silent-violation rules, and § 5.1 with the flakiness tree.
> This skill **does not contain** the text of the rules — it says what to run, in what order to scan, how to classify and how to report.
> **API surface:** resolve it through Context7 — `/oven-sh/bun`. Signature, option and per-version behavior come from there; the rule and the ID come from the knowledge base.

Contract this skill implements: [Bun - Testes](../../../knowledge-base/docs/bun-testes.md) § 7 ("Contrato de skill").

---

## When to use

Reviewing a suite that **already exists** under `bun test`, or diagnosing a test that fails intermittently.

| Situation | Go to |
| --- | --- |
| writing a new test, configuring the suite | `bun-test-build` |
| the **shape** of the suite across levels (E2E × unit × component) | `test-review` |
| the suite as a system: flakiness rate, credibility | `test-diagnose` |
| an E2E test that fails | `playwright-diagnose` |
| reviewing the component, not its test | `react-review` |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | [Bun - Testes](../../../knowledge-base/docs/bun-testes.md) § 2 | one `globalThis` shared by every file is the default |
| 2 | [Bun - Testes](../../../knowledge-base/docs/bun-testes.md) § 6 and § 6.1 | the rules, and the seven silent-violation ones |
| 3 | `references/mapa-de-ids.md` | before citing — and to find **which satellite** holds the body |
| 4 | [Bun - Testes](../../../knowledge-base/docs/bun-testes.md) § 5.1 | the flakiness tree |
| 5 | the satellite for the finding | only after you have the cause |

**Never load all six satellites.** And **never invent an ID** — the family runs from `BUN-TEST-01` to `BUN-TEST-29`.

References in this skill:

| File | What for |
| --- | --- |
| `references/sondas.md` | the seven probes, the stops, and what they do not catch |
| `references/ordem-da-varredura.md` | the nine steps, and the symptom → cause table for flakiness |
| `references/severidade-e-relatorio.md` | classification, finding format, and the finding × opinion cut |
| `references/antipadroes.md` | the antipattern grid with ID and satellite |
| `references/mapa-de-ids.md` | the 29 `BUN-TEST-*`: declaration, **satellite of the body** and section |
| `references/exemplo-revisao.md` | a whole review, from the probes to the "not verified" |
| `scripts/sondas.sh` | runs the mechanical ones; with `--rodar`, also the ones that need the suite up |
| `scripts/gerar-mapa-de-ids.sh` | regenerates the map in both skills |

---

## Step 1 — Probe before reading

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/bun-test-review/scripts/sondas.sh --rodar
```

**Two mandatory stops:**

| Probe | If it shows… | Why |
| --- | --- | --- |
| S1 | a file outside the discovery pattern | a file that never ran has no assertion defect that matters |
| S5 | a coverage gate that does not fail | any discussion of coverage becomes decorative |

And one reading that names the cause by itself: **S2 fails and S3 passes** → state leaking through the shared `globalThis`. With that switched on, criticizing assertions one by one is noise.

---

## Step 2 — Scan in the order that fails most

`references/ordem-da-varredura.md`: assertion that may not have run → mock and spy leakage → isolation and order → waiting and time → marks that erase signal → snapshot → DOM and component → CI gates → configuration.

If a step produces a finding that invalidates the next one (the preload does not restore mocks; the suite does not pass with `--randomize`), **stop reviewing the interior**.

---

## Step 3 — Diagnose flakiness by symptom

The symptom → cause table is in the same reference. Two readings that decide on their own:

- **passes alone, fails together, and `--isolate` fixes it** → state in the shared global (`BUN-TEST-02`, `-03`, `-09`);
- **fails only with `--parallel`** → an external resource shared across workers (`BUN-TEST-10`), or a preload that starts something (`BUN-TEST-24`).

**`test.serial` never resolves a dependency between files** — it sequences within the file. A proposed fix using `serial` for a cross-file dependency is wrong (`BUN-TEST-09`).

---

## Step 4 — Classify and report

`references/severidade-e-relatorio.md`. The criterion between Blocking and High: **does the defect make CI lie?** A test that does not run and a gate that does not close produce false green — a different category from "fragile test".

Four-part format, with `file:line` always, and **the probe's evidence pasted in** when the finding is about shape.

---

## Step 5 — Closing

1. **Turn a probe into a gate** — `--randomize` in CI, `tsc --noEmit` as its own step, threshold on `lines`.
2. **Order by severity**, not by directory.
3. **Declare what was not verified** — a probe run over an already-broken suite is not conclusive.
4. **If the fix is writing a test**, the source becomes `bun-test-build`.

---

## Example

A monorepo with 180 tests and green CI. The probes find a file that **never ran**, a `coverageThreshold` on `statements` (which does not fail), `-u` in CI, a committed `.only`, and `--randomize` failing while `--isolate` passes — the signature of leakage through the shared global. The fix for the leakage is **one line in the preload**, not file by file.

Full review: `references/exemplo-revisao.md`.

---

## Related

- [Bun - Testes](../../../knowledge-base/docs/bun-testes.md) — source of this skill: § 2, § 5.1, § 6, § 6.1, § 7
- `bun-test-build` — the sibling skill
- `test-review` · `test-diagnose` — the concept layer
- `playwright-review` — the equivalent audit in E2E
- `react-review` · `drizzle-review` — where the finding format comes from
