# Self-check before delivering

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/elysia-schema/scripts/autoverificar.sh src
```

| # | Check | Rule |
| --- | --- | --- |
| 1 | type derived via `typeof S.static`, not rewritten | `ELYSIA-TYPE-01` |
| 2 | uploads use `fileType` | `ELYSIA-TYPE-02` |
| 3 | header names in lowercase | `ELYSIA-TYPE-03` |
| 4 | a numeric `body` field does not rely on coercion | `ELYSIA-TYPE-04` |
| 5 | a `guard` that adds declares `schema: 'standalone'` | `ELYSIA-TYPE-05` |
| 6 | a multi-status route has `response` as a map | `ELYSIA-TYPE-06` |
| 7 | a route with Zod/Valibot has `mapJsonSchema` | `ELYSIA-TYPE-07` |
| 8 | every Eden return checks `error` before `data` | `ELYSIA-TYPE-08` |
| 9 | `queryFn`/`mutationFn` throws on error | `ELYSIA-TYPE-09` |
| 10 | a client feeding Query uses `parseDate: false` | `ELYSIA-TYPE-10` |
| 11 | the same `elysia` version on both sides | `ELYSIA-TYPE-11` |
| 12 | `allowUnsafeValidationDetails` switched off | `ELYSIA-TYPE-12` |
| 13 | a paginated listing returns an envelope | `ELYSIA-TYPE-13` |
| 14 | `strict: true` and TS ≥ 5.0 on both sides | `ELYSIA-APP-04` |

**Run `tsc --noEmit` in both packages.** It is the only check that catches an Eden contract
break — and Bun does not do it (`BUN-CORE-02`).

**And the test that proves `ELYSIA-TYPE-09`:** force an error and confirm the query ends up in
`isError`, **not** in `success`. If it ends up in `success`, this skill's most expensive defect
is present.

## Related

- `eden.md` — the three traps
- `antipadroes.md` — the grid, with IDs
