# Autoverificação antes de entregar

```bash
bash ~/.claude/skills/storybook-test/scripts/autoverificar.sh src
```

| # | Confira | Regra |
| --- | --- | --- |
| 1 | o `framework` foi lido antes de qualquer prescrição de router | `SB-CFG-01` |
| 2 | nenhum `SB-TS-*` prescrito num projeto `react-vite`, e vice-versa | § 6.2 do hub |
| 3 | todo `expect` tem `await` | `SB-TEST-01` |
| 4 | a primeira query de story assíncrona é `findBy…` | `SB-TEST-10` |
| 5 | callback é `fn()` em `args`, não função no `render` | `SB-TEST-03` |
| 6 | `mount` desestruturado e chamado, se há setup antes do render | `SB-TEST-02` |
| 7 | nenhuma asserção sobre implementação interna | `SB-TEST-09` |
| 8 | query por papel/rótulo, não por classe ou test id desnecessário | `SB-TEST-06` |
| 9 | o que distingue a story é `args` | `SB-CSF-04` |
| 10 | `sb.mock()` só no preview; comportamento em `beforeEach` | `SB-MOCK-01`, `SB-MOCK-04` |
| 11 | `beforeEach` que altera ambiente retorna a limpeza | `SB-CTX-08` |
| 12 | utilitários de `storybook/test`, sem `@` | `SB-CORE-01` |
| 13 | `a11y.test` é `'error'` onde se espera que o CI reprove | `SB-TEST-04` |
| 14 | import de `Meta`/`StoryObj` é do pacote do framework | `SB-CORE-02` |

E a verificação que vale mais que as catorze: **quebre o componente de propósito e confirme que a story fica vermelha.** Inverta uma condição, remova o handler. Se nada quebrar, a `play` não afirma nada — `TS-TEC-08` em [[Teste de Software - Técnicas de Design de Caso]].

**Depois, rode:** `vitest run --project=storybook`. Não `vitest` — sem `run` entra em watch mode.

---

