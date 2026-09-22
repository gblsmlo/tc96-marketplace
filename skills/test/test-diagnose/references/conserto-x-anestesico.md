# Fix × anesthetic

> Seven "fixes" that make the red disappear without solving anything. If you are
> proposing one of them, go back to the ten causes.

| Anesthetic | What it hides | Rule |
| --- | --- | --- |
| retry | a diagnosable defect, and the real red along with it | `TS-SUI-03` |
| fixed-time wait | the condition that should have been waited on | `TS-SUI-07` |
| a single worker | coupling between tests | `TS-SUI-09` |
| numeric prefix on the files | order dependence, now encoded | § 8.4 of the satellite |
| `skip` without an issue | the debt, now anonymous | `TS-SUI-11` |
| `try/catch` in the test body | the whole test — it never fails | § 5 of the satellite |
| removing the failing assertion | exactly what the test was verifying | `TS-SUI-04` |

**The last two are the worst because they are invisible in review**: the file still
looks like a test. The inventory in `scripts/medir-flakiness.sh` looks for both.

**Retry deserves a note.** It has a legitimate use: absorbing **residual** instability in an
already healthy suite, with the attempt's trace recorded. Above ~1% flakiness, it stops being a
safety net and becomes a blindfold.

---

## Most frequent antipatterns, with IDs

| Antipattern | ID | Satellite |
| --- | --- | --- |
| Living with flakiness as a pragmatic choice | `TS-CORE-04` | [Teste de Software - Confiabilidade da Suíte](../../../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md) |
| Retry to silence flakiness | `TS-SUI-03` | [Teste de Software - Confiabilidade da Suíte](../../../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md) |
| Fixed-time wait | `TS-SUI-07` | [Teste de Software - Confiabilidade da Suíte](../../../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md) |
| One worker as the solution | `TS-SUI-09` | [Teste de Software - Confiabilidade da Suíte](../../../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md) |
| Cleanup in the next one's setup instead of teardown | `TS-SUI-08` | [Teste de Software - Confiabilidade da Suíte](../../../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md) |
| Shared pre-existing data in the environment | `TS-SUI-05` | [Teste de Software - Confiabilidade da Suíte](../../../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md) |
| A test that cannot fail, kept | `TS-SUI-10` | [Teste de Software - Confiabilidade da Suíte](../../../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md) |
| `skip` with neither reason nor deadline | `TS-SUI-11` | [Teste de Software - Confiabilidade da Suíte](../../../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md) |
| Blaming the refactor for the test that broke | `TS-SUI-06` | [Teste de Software - Confiabilidade da Suíte](../../../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md) |
| An assertion that does not detect a break | `TS-SUI-04` | [Teste de Software - Confiabilidade da Suíte](../../../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md) |
| Test observing implementation | `TS-CORE-07` | [Teste de Software - Confiabilidade da Suíte](../../../../knowledge-base/docs/teste-de-software-confiabilidade-da-suite.md) |
| Coverage as proof of detection | `TS-CORE-05` | [Teste de Software - Técnicas de Design de Caso](../../../../knowledge-base/docs/teste-de-software-tecnicas-de-design-de-caso.md) |
| Declaring the suite sufficient without breaking anything | `TS-TEC-08` | [Teste de Software - Técnicas de Design de Caso](../../../../knowledge-base/docs/teste-de-software-tecnicas-de-design-de-caso.md) |
| Mocking what the test came to prove | `TS-CORE-03` | [Teste de Software - Dublês de Teste](../../../../knowledge-base/docs/teste-de-software-dubles-de-teste.md) |
| Real clock in a test about time | `TS-DUB-05` | [Teste de Software - Dublês de Teste](../../../../knowledge-base/docs/teste-de-software-dubles-de-teste.md) |
| An unfaithful fake used to verify a contract | `TS-DUB-03` | [Teste de Software - Dublês de Teste](../../../../knowledge-base/docs/teste-de-software-dubles-de-teste.md) |
| A slow suite nobody runs (inverted shape) | `TS-NIV-04` | [Teste de Software - Níveis e Escopo](../../../../knowledge-base/docs/teste-de-software-niveis-e-escopo.md) |
| Error state without coverage | `TS-TIPO-02` | [Teste de Software - Tipos e Atributos de Qualidade](../../../../knowledge-base/docs/teste-de-software-tipos-e-atributos-de-qualidade.md) |
| Recurring defect fixed one-off | `TS-PROC-08` | [Teste de Software - Processo e Artefatos](../../../../knowledge-base/docs/teste-de-software-processo-e-artefatos.md) |
| Production defect with no test that catches it | `TS-CORE-06` | [Teste de Software](../../../../knowledge-base/docs/teste-de-software.md) |
| Green suite treated as fitness for the user | `TS-CORE-08` | [Teste de Software](../../../../knowledge-base/docs/teste-de-software.md) |

Check the ID in `mapa-de-ids.md` before citing: `TS-SUI-02`, `TS-NIV-01` and `TS-DUB-02` are
aliases.
