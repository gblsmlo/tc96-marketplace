# Autoverificação antes de entregar

```bash
bash ~/.claude/skills/elysia-schema/scripts/autoverificar.sh src
```

| # | Confira | Regra |
| --- | --- | --- |
| 1 | tipo derivado por `typeof S.static`, não reescrito | `ELYSIA-TYPE-01` |
| 2 | upload usa `fileType()` | `ELYSIA-TYPE-02` |
| 3 | nomes de header em minúsculas | `ELYSIA-TYPE-03` |
| 4 | campo numérico de `body` não conta com coerção | `ELYSIA-TYPE-04` |
| 5 | `guard` que soma declara `schema: 'standalone'` | `ELYSIA-TYPE-05` |
| 6 | rota multi-status tem `response` como mapa | `ELYSIA-TYPE-06` |
| 7 | rota com Zod/Valibot tem `mapJsonSchema` | `ELYSIA-TYPE-07` |
| 8 | todo retorno de Eden checa `error` antes de `data` | `ELYSIA-TYPE-08` |
| 9 | `queryFn`/`mutationFn` lança em erro | `ELYSIA-TYPE-09` |
| 10 | cliente que alimenta Query usa `parseDate: false` | `ELYSIA-TYPE-10` |
| 11 | mesma versão de `elysia` nos dois lados | `ELYSIA-TYPE-11` |
| 12 | `allowUnsafeValidationDetails` desligado | `ELYSIA-TYPE-12` |
| 13 | listagem paginada devolve envelope | `ELYSIA-TYPE-13` |
| 14 | `strict: true` e TS ≥ 5.0 nos dois lados | `ELYSIA-APP-04` |

**Rode `tsc --noEmit` nos dois pacotes.** É a única verificação que pega quebra de contrato
do Eden — e Bun não a faz (`BUN-CORE-02`).

**E o teste que prova `ELYSIA-TYPE-09`:** force um erro e confirme que a query fica em
`isError`, **não** em `success`. Se ficar em `success`, o defeito mais caro desta skill está
presente.

## Relacionados

- `eden.md` — as três armadilhas
- `antipadroes.md` — a grade com ID
