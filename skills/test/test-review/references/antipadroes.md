# Most frequent antipatterns, with IDs

> Quick scan grid. Check the ID in `mapa-de-ids.md` before citing — three are
> aliases and citing them makes the finding invalid.

| Antipattern | ID | Satellite |
| --- | --- | --- |
| A CI gate that runs and does not fail | `TS-PROC-03` | [Teste de Software - Processo e Artefatos](../../../../knowledge-base/teste-de-software-processo-e-artefatos.md) |
| Coverage target as a quality indicator | `TS-CORE-05` | [Teste de Software - Técnicas de Design de Caso](../../../../knowledge-base/teste-de-software-tecnicas-de-design-de-caso.md) |
| Inverted shape (*ice-cream cone*) | `TS-NIV-04` | [Teste de Software - Níveis e Escopo](../../../../knowledge-base/teste-de-software-niveis-e-escopo.md) |
| Business rule verified in E2E | `TS-NIV-02` | [Teste de Software - Níveis e Escopo](../../../../knowledge-base/teste-de-software-niveis-e-escopo.md) |
| The same logic at three levels | `TS-CORE-02` | [Teste de Software - Níveis e Escopo](../../../../knowledge-base/teste-de-software-niveis-e-escopo.md) |
| Global proportion instead of per module | `TS-NIV-08` | [Teste de Software - Níveis e Escopo](../../../../knowledge-base/teste-de-software-niveis-e-escopo.md) |
| Component level not named (everything becomes E2E) | `TS-NIV-07` | [Teste de Software - Níveis e Escopo](../../../../knowledge-base/teste-de-software-niveis-e-escopo.md) |
| Shared type treated as a tested contract | `TS-NIV-09` | [Teste de Software - Níveis e Escopo](../../../../knowledge-base/teste-de-software-niveis-e-escopo.md) |
| Only the happy path covered | `TS-TIPO-02` | [Teste de Software - Tipos e Atributos de Qualidade](../../../../knowledge-base/teste-de-software-tipos-e-atributos-de-qualidade.md) |
| Static layer not counted (or `strict` off) | `TS-TIPO-08` | [Teste de Software - Tipos e Atributos de Qualidade](../../../../knowledge-base/teste-de-software-tipos-e-atributos-de-qualidade.md) |
| Non-functional requirement without a number | `TS-TIPO-05` | [Teste de Software - Tipos e Atributos de Qualidade](../../../../knowledge-base/teste-de-software-tipos-e-atributos-de-qualidade.md) |
| Mean instead of percentile | `TS-TIPO-06` | [Teste de Software - Tipos e Atributos de Qualidade](../../../../knowledge-base/teste-de-software-tipos-e-atributos-de-qualidade.md) |
| Automated scan reported as coverage of the attribute | `TS-TIPO-07` | [Teste de Software - Tipos e Atributos de Qualidade](../../../../knowledge-base/teste-de-software-tipos-e-atributos-de-qualidade.md) |
| Retest without regression | `TS-TIPO-04` | [Teste de Software - Tipos e Atributos de Qualidade](../../../../knowledge-base/teste-de-software-tipos-e-atributos-de-qualidade.md) |
| Automated suite as the whole strategy | `TS-TIPO-09` | [Teste de Software - Tipos e Atributos de Qualidade](../../../../knowledge-base/teste-de-software-tipos-e-atributos-de-qualidade.md) |
| Mocking what the test came to prove | `TS-CORE-03` | [Teste de Software - Dublês de Teste](../../../../knowledge-base/teste-de-software-dubles-de-teste.md) |
| Fake without declared fidelity | `TS-DUB-03` | [Teste de Software - Dublês de Teste](../../../../knowledge-base/teste-de-software-dubles-de-teste.md) |
| Repository fake in place of a controlled database | `TS-DUB-08` | [Teste de Software - Dublês de Teste](../../../../knowledge-base/teste-de-software-dubles-de-teste.md) |
| Real clock in a test about time | `TS-DUB-05` | [Teste de Software - Dublês de Teste](../../../../knowledge-base/teste-de-software-dubles-de-teste.md) |
| Shared pre-existing data | `TS-SUI-05` | [Teste de Software - Confiabilidade da Suíte](../../../../knowledge-base/teste-de-software-confiabilidade-da-suite.md) |
| A test that cannot fail, kept | `TS-SUI-10` | [Teste de Software - Confiabilidade da Suíte](../../../../knowledge-base/teste-de-software-confiabilidade-da-suite.md) |
| `skip` with neither reason nor deadline | `TS-SUI-11` | [Teste de Software - Confiabilidade da Suíte](../../../../knowledge-base/teste-de-software-confiabilidade-da-suite.md) |
| Test observing implementation | `TS-CORE-07` | [Teste de Software - Confiabilidade da Suíte](../../../../knowledge-base/teste-de-software-confiabilidade-da-suite.md) |
| Ambiguous requirement accepted as done | `TS-PROC-01` | [Teste de Software - Processo e Artefatos](../../../../knowledge-base/teste-de-software-processo-e-artefatos.md) |
| Severity and priority in a single field | `TS-PROC-04` | [Teste de Software - Processo e Artefatos](../../../../knowledge-base/teste-de-software-processo-e-artefatos.md) |
| Test effort spread uniformly | `TS-PROC-09` | [Teste de Software - Processo e Artefatos](../../../../knowledge-base/teste-de-software-processo-e-artefatos.md) |
| Coverage tracked instead of escapes | `TS-PROC-10` | [Teste de Software - Processo e Artefatos](../../../../knowledge-base/teste-de-software-processo-e-artefatos.md) |
| Production defect with no test that catches it | `TS-CORE-06` | [Teste de Software](../../../../knowledge-base/teste-de-software.md) |
| Green suite treated as fitness for the user | `TS-CORE-08` | [Teste de Software](../../../../knowledge-base/teste-de-software.md) |
