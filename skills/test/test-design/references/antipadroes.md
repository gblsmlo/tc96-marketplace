# Antipatterns this skill prevents, with IDs

> Step 6's check grid. Every row is a decision that, taken out of habit,
> produces a test that costs and does not pay. The text of the rule lives in the satellite.

| Antipattern | ID | Satellite |
| --- | --- | --- |
| Writing a test without knowing what can go wrong | `TS-CORE-01` | [Teste de Software](../../../../knowledge-base/docs/teste-de-software.md) |
| E2E as the default for anything | `TS-CORE-02` | [Teste de Software - Níveis e Escopo](../../../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md) |
| Business rule verified in E2E | `TS-NIV-02` | [Teste de Software - Níveis e Escopo](../../../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md) |
| The same logic verified at three levels | `TS-CORE-02` | [Teste de Software - Níveis e Escopo](../../../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md) |
| Inverted suite shape (*ice-cream cone*) | `TS-NIV-04` | [Teste de Software - Níveis e Escopo](../../../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md) |
| Proportion treated as a repository-wide policy | `TS-NIV-08` | [Teste de Software - Níveis e Escopo](../../../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md) |
| Replacing an internal collaborator that is your own code | `TS-NIV-05` | [Teste de Software - Níveis e Escopo](../../../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md) |
| Relying on the shared type alone as a contract test | `TS-NIV-09` | [Teste de Software - Níveis e Escopo](../../../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md) |
| Not naming the component level (everything becomes E2E) | `TS-NIV-07` | [Teste de Software - Níveis e Escopo](../../../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md) |
| Testing only the happy path | `TS-TIPO-02` | [Teste de Software - Tipos e Atributos de Qualidade](../../../../knowledge-base/docs/teste-de-software-tipos-e-atributos-de-qualidade.md) |
| One made-up value in the middle of the range | `TS-TEC-01` | [Teste de Software - Técnicas de Design de Caso](../../../../knowledge-base/docs/teste-de-software-tecnicas-de-design-de-caso.md) |
| Only the valid classes | `TS-TEC-02` | [Teste de Software - Técnicas de Design de Caso](../../../../knowledge-base/docs/teste-de-software-tecnicas-de-design-de-caso.md) |
| A list always with three items, never empty | `TS-TEC-03` | [Teste de Software - Técnicas de Design de Caso](../../../../knowledge-base/docs/teste-de-software-tecnicas-de-design-de-caso.md) |
| Only valid state transitions | `TS-TEC-04` | [Teste de Software - Técnicas de Design de Caso](../../../../knowledge-base/docs/teste-de-software-tecnicas-de-design-de-caso.md) |
| Combination reduced by arbitrary choice | `TS-TEC-09` | [Teste de Software - Técnicas de Design de Caso](../../../../knowledge-base/docs/teste-de-software-tecnicas-de-design-de-caso.md) |
| Replacing what the test came to prove | `TS-CORE-03` | [Teste de Software - Dublês de Teste](../../../../knowledge-base/docs/teste-de-software-dubles-de-teste.md) |
| Calling every double a "mock" | `TS-DUB-01` | [Teste de Software - Dublês de Teste](../../../../knowledge-base/docs/teste-de-software-dubles-de-teste.md) |
| Fake without declared fidelity | `TS-DUB-03` | [Teste de Software - Dublês de Teste](../../../../knowledge-base/docs/teste-de-software-dubles-de-teste.md) |
| Behavior verification by default | `TS-DUB-04` | [Teste de Software - Dublês de Teste](../../../../knowledge-base/docs/teste-de-software-dubles-de-teste.md) |
| Waiting for real time to pass | `TS-DUB-05` | [Teste de Software - Dublês de Teste](../../../../knowledge-base/docs/teste-de-software-dubles-de-teste.md) |
| Repository fake in place of a controlled database | `TS-DUB-08` | [Teste de Software - Dublês de Teste](../../../../knowledge-base/docs/teste-de-software-dubles-de-teste.md) |
| Non-functional requirement without a number | `TS-TIPO-05` | [Teste de Software - Tipos e Atributos de Qualidade](../../../../knowledge-base/docs/teste-de-software-tipos-e-atributos-de-qualidade.md) |
| Mean instead of percentile | `TS-TIPO-06` | [Teste de Software - Tipos e Atributos de Qualidade](../../../../knowledge-base/docs/teste-de-software-tipos-e-atributos-de-qualidade.md) |
| Not counting the static layer in the strategy | `TS-TIPO-08` | [Teste de Software - Tipos e Atributos de Qualidade](../../../../knowledge-base/docs/teste-de-software-tipos-e-atributos-de-qualidade.md) |

**Before citing any ID, check `mapa-de-ids.md`:** `TS-NIV-01`, `TS-DUB-02` and
`TS-SUI-02` are **aliases** and citing them makes the finding invalid.
