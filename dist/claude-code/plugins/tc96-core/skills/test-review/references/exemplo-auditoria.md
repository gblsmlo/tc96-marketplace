# Worked example — auditing a suite

An e-commerce repository, 214 cases, CI green for months, and defects reaching production.

---

## Step 1 — the probes, before opening a single test

```
$ bash scripts/sondas-suite.sh.

== S1. The suite's shape
 e2e/ 187 cases
 packages/ 22 cases
 apps/ 5 cases
 ─── total: 214 cases ← 87% in E2E
== S3. Does the static layer count?
 tsconfig.json:4: "strict": false ← and there is Playwright in the project
 -- no-floating-promises: ABSENT ← blocking
== S4. Does the gate close?
.github/workflows/ci.yml:41: continue-on-error: true
== S5. Coverage target
 package.json:22: "coverageThreshold": { "global": { "lines": 80 } }
== S6. Risk classes
 error 2 files ← out of 214 cases
 empty 0 files
== S9. skip
 e2e/payment.spec.ts:14: test.skip("3DS",...)
```

**Two stops fired at the same time** (S1 inverted, S4 with no failure). Report them
before auditing any interior.

## Step 2 — what reading adds

Sampling 10 files from `e2e/`: **7 verify business rules**, not journeys
(`TS-NIV-02`). That is not a bad shape by accident — it is the cause of the shape.

## Step 3 — the report

```markdown
## Test strategy audit — store

### Blocking (2)

`TS-PROC-03` —.github/workflows/ci.yml:41
S4: the test job has continue-on-error: true. CI has never failed on a red test.
Fix: remove the line. If the goal was not to block while the suite is unstable,
 the way is test-diagnose, not a gate that lies.
See Teste de Software - Processo e Artefatos.

`TS-TIPO-08` — tsconfig.json:4 + absence of no-floating-promises
S3: strict off, and no no-floating-promises in a project with Playwright — there may be
 any number of `expect(...)` without await, and none shows up as a failure.
Fix: turn on strict and the lint rule; run it once and treat what appears as an
 inventory of assertions that assert nothing.
See Teste de Software - Tipos e Atributos de Qualidade, and Playwright PW-CORE-04.

### High (3)

`TS-NIV-04` — e2e/ (187 cases) × packages/ (22 cases)
S1: 87% of the cases are E2E. Sampling 10 files: 7 verify business rules.
Fix: move rule assertions to unit tests; one E2E per journey. Start with
 e2e/discount.spec.ts (23 cases about discount ranges).
See Teste de Software - Níveis e Escopo.

`TS-TIPO-02` — the whole suite
S6: 2 files mention errors, none mentions the empty state, across 214 cases.
Fix: per critical flow, list the five states and cover error and empty at the
 component level, which is where they cost least. Start with checkout and payments.
See Teste de Software - Tipos e Atributos de Qualidade.

`TS-CORE-05` — package.json:22
S5: a coverageThreshold of 80% treated as a quality gate.
Fix: replace the target with risk classes covered. Coverage can still be measured —
 just not as an approval criterion.
See Teste de Software - Técnicas de Design de Caso.

### Medium (1)

`TS-SUI-11` — e2e/payment.spec.ts:14
S9: test.skip("3DS") with no reason and no issue. Payments is the product's highest-risk flow.
Fix: an issue with a deadline, or remove the test. An anonymous skip in a critical flow is the
 worst combination: it looks covered and is not.
See Teste de Software - Confiabilidade da Suíte.

### Not a finding (recorded so it does not come back to the discussion)

- 62% coverage in packages/: low coverage is not a finding (TS-CORE-05).
- Mass in integration in apps/bff: that is a trophy, not an inverted shape.

### Not verified

- S2 (duration): the suite does not start on this machine — no Docker for the database. The
 per-level measurement stays open, and it decides whether the gate is runnable before the PR.
- S8 (escapes): no access to the full history; the clone is shallow.
```

## What this example demonstrates

| Decision | Where the rule is |
| --- | --- |
| two stops fired and came before everything | `sondas.md` § *Three mandatory stops* |
| the reading sample explained the shape the probe measured | `sondas.md` § *What the probe does not measure* |
| low coverage and mass in integration did **not** become findings | `severidade-e-relatorio.md` § *The cut* |
| every fix has a named starting point | `severidade-e-relatorio.md` § *Format* |
| what did not run was declared, not omitted | `severidade-e-relatorio.md` § *Closing* |
