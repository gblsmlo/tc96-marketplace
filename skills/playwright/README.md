# Playwright skills — the E2E triad

Three skills, one directory each. The split is **write · audit · diagnose**, and in
Playwright it is deliberate: diagnosis starts **outside the code**, in the trace.

| Skill | The question it answers | Source | Internal support |
| --- | --- | --- | --- |
| `playwright-build` | how do I write this E2E test? | [Playwright - Locators](../../knowledge-base/playwright-locators.md) | 5 references + 1 example + 1 script |
| `playwright-review` | does this suite have defects? | [Playwright](../../knowledge-base/playwright.md) | 5 references + 1 audit + 2 scripts |
| `playwright-diagnose` | why does **this** test fail? | [Playwright - Debug e Trace](../../knowledge-base/playwright-debug-e-trace.md) | 5 references + 1 diagnosis + 1 script |

**Before all three comes `test-design`:** if what can go wrong is a business rule, the
test **is not E2E** (`TS-CORE-02`).

## What each package added

| Skill | Gained | Gap it closed |
| --- | --- | --- |
| `playwright-build` | **`scripts/autoverificar.sh`** — the 12 items of Step 6, executable | the checklist existed; running it was manual |
| `playwright-review` | **`scripts/sondas.sh`** — S1 to S8, executable | the eight probes were loose commands in a table |
| `playwright-diagnose` | **`scripts/isolar.sh`** — the whole bisection, with the reading of each result | the battery was described, but assembling it was the reader's job |

`isolar.sh` prints, for each run, **the hypothesis it eliminates** — and repeats the
warning the skill makes twice: `--workers=1` **diagnoses, it does not fix**.

## The ID map

`mapa-de-ids.md` is **generated** and identical across the three, by
`playwright-review/scripts/gerar-mapa-de-ids.sh`. It indexes the **85** `PW-*` by satellite and
section — the number the skill itself declares — plus the whole of § 6.2: the two aliases
(`PW-ACT-07`, `PW-LOC-07`) **and** the four rules that *look* like aliases and remain citable.

```bash
bash plugins/tc96-e2e/skills/playwright-review/scripts/gerar-mapa-de-ids.sh
bash scripts/instalar.sh
```

<!-- tokens:inicio -->
## Context budget

Measured by `skill-validator` (tiktoken), on 2026-09-05. **The number that matters is the
`SKILL.md` column**: it is what enters the context before the skill decides what to open.
References load on demand, one at a time.

| Skill | `SKILL.md` | largest `references/` | total | refs |
| --- | ---: | --- | ---: | ---: |
| `playwright-build` | 1.767 | `mapa-de-ids.md` (4.032) | 9.531 | 6 |
| `playwright-diagnose` | 1.676 | `mapa-de-ids.md` (4.032) | 9.059 | 6 |
| `playwright-review` | 1.412 | `mapa-de-ids.md` (4.032) | 12.033 | 6 |

Loading all 3 skills in this group at once would cost **4.855 tokens** in `SKILL.md` alone,
and **30.623** with every reference. That is why each skill declares what it must **never** load.

Regenerate: `bash scripts/medir.sh`
<!-- tokens:fim -->

## Related

- [Skills index](../README.md) · [Playwright](../../knowledge-base/playwright.md) § 7 — the contract
- `tc96-core: test family` — the concept layer, which comes first
- `tc96-backend: bun family` — unit and integration
