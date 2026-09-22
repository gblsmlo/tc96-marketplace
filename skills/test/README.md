# Test skills — the concept layer

Three skills, one directory each. They decide **what**, **at which level** and **whether the
suite protects** — and they never write tests: that belongs to the tool layer
(`hermes-e2e: playwright family`, `hermes-backend: bun family`, `storybook-test`).

| Skill | The question it answers | Source | Internal support |
| --- | --- | --- | --- |
| `test-design` | what test do I write, and at which level? | [Teste de Software - Níveis e Escopo](../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md) | 4 references + 1 example + 1 script |
| `test-review` | does this suite protect anything? | [Teste de Software](../../knowledge-base/docs/teste-de-software.md) | 4 references + 1 audit + 1 script |
| `test-diagnose` | why does nobody trust this suite? | [Teste de Software - Confiabilidade da Suíte](../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md) | 4 references + 1 diagnosis + 1 script |

**The order is concept → tool.** Skipping this layer produces **E2E by default**, the
highest-cost antipattern in this stack (`TS-CORE-02`).

## What each package added

| Skill | Gained | Gap it closed |
| --- | --- | --- |
| `test-design` | `references/` per step, and the 24-antipattern grid split out | the SKILL.md had 291 lines and drowned the procedure in tables |
| `test-review` | **`scripts/sondas-suite.sh`** — S1 to S9, executable | the nine probes existed only as a description in a table |
| `test-diagnose` | **`scripts/medir-flakiness.sh`** — anesthetic inventory + measured rate | "without the rate there is no diagnosis" was a rule with no instrument |

`medir-flakiness.sh` does the two things the skill requires before opining: it **inventories the
anesthetics already installed** (retry, `workers: 1`, `skip`, fixed-time waits, real clock,
numeric prefix, `try/catch` in the body) and **measures the rate** by repeating the command N
times, comparing against the ~1% threshold.

## The ID map

`mapa-de-ids.md` is **generated** and identical across the three, by
`test-design/scripts/gerar-mapa-de-ids.sh`. It indexes the **64** `TS-*` by satellite and
section — the same number § 6.2 of the hub declares, which serves as the check — and carries
the alias table: `TS-NIV-01`, `TS-DUB-02` and `TS-SUI-02` are **not** cited.

```bash
bash plugins/hermes-core/skills/test-design/scripts/gerar-mapa-de-ids.sh
bash scripts/instalar.sh
```

<!-- tokens:inicio -->
## Context budget

Measured by `skill-validator` (tiktoken), on 2026-09-05. **The number that matters is the
`SKILL.md` column**: it is what enters the context before the skill decides what to open.
References load on demand, one at a time.

| Skill | `SKILL.md` | largest `references/` | total | refs |
| --- | ---: | --- | ---: | ---: |
| `test-design` | 2.032 | `mapa-de-ids.md` (3.085) | 8.482 | 6 |
| `test-diagnose` | 1.994 | `mapa-de-ids.md` (3.085) | 9.365 | 6 |
| `test-review` | 1.631 | `mapa-de-ids.md` (3.085) | 9.941 | 6 |

Loading all 3 skills in this group at once would cost **5.657 tokens** in `SKILL.md` alone,
and **27.788** with every reference. That is why each skill declares what it must **never** load.

Regenerate: `bash scripts/medir.sh`
<!-- tokens:fim -->

## Related

- [Skills index](../README.md) · [Teste de Software](../../knowledge-base/docs/teste-de-software.md) § 7 — the contract all three implement
- `hermes-e2e: playwright family` · `hermes-backend: bun family` — the tool layer
