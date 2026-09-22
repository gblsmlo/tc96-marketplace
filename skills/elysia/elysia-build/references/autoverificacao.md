# Autoverificação antes de entregar

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/elysia-build/scripts/autoverificar.sh src
```

| # | Confira | Regra |
| --- | --- | --- |
| 1 | method chaining contínuo, sem quebrar em statements | `ELYSIA-APP-01` |
| 2 | nenhum `error` do contexto — é `status` | `ELYSIA-APP-02` |
| 3 | handler desestrutura o contexto inline | `ELYSIA-CORE-02` |
| 4 | `strict: true` e TS ≥ 5.0 nos dois lados | `ELYSIA-APP-04` |
| 5 | `export type App = typeof app` no fim do encadeamento | `ELYSIA-APP-05` |
| 6 | erro esperado é `return status(...)` | `ELYSIA-CORE-03` |
| 7 | `status(code, valor)` onde há schema de `response` | `ELYSIA-CORE-04` |
| 8 | `onError` não vaza `error.message` de `UNKNOWN` | `ELYSIA-CORE-07` |
| 9 | erro de domínio recorrente em `.error({...})` | `ELYSIA-CORE-08` |
| 10 | cookie de sessão assinado e `httpOnly` | `ELYSIA-CORE-05` |
| 11 | `set.headers` não é alterado depois do primeiro `yield` | `ELYSIA-CORE-06` |
| 12 | teste usa `app.handle`, com `await app.modules` | `ELYSIA-CORE-09`, `ELYSIA-CORE-10` |
| 13 | `process.env` não é lido direto | `ELYSIA-APP-09` |
| 14 | nenhum `@elysiajs/swagger` | `ELYSIA-APP-07` |
| 15 | hook e plugin registrados **antes** das rotas que afetam | `ELYSIA-CORE-01` |

Os itens que o script **não** decide, e por quê:

| Item | Por que exige leitura |
| --- | --- |
| `ELYSIA-APP-01` — chaining contínuo | é estrutura de expressão; grep não vê onde o encadeamento quebra |
| `ELYSIA-CORE-03` — erro esperado com `return status` | distinguir esperado de inesperado é semântica de domínio |
| `ELYSIA-CORE-08` — erro de domínio com `code` próprio | idem |
| `ELYSIA-CORE-06` — `set.headers` depois do `yield` | exige ordem dentro do generator |
| `ELYSIA-CORE-01` — ordem de registro | a sonda S1 de `elysia-diagnose` mede isso por número de linha |

**Rode**, sempre:

```bash
tsc --noEmit # Bun transpila sem checar tipo — BUN-CORE-02
bun test # por app.handle, com await app.modules
```

## Relacionados

- `antipadroes.md` — a grade com ID
- `elysia-diagnose` — quando o hook não afeta a rota
