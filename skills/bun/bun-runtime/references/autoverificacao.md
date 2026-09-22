# Autoverificação antes de entregar

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/bun-runtime/scripts/autoverificar.sh src
```

| # | Confira | Regra |
| --- | --- | --- |
| 1 | `tsc --noEmit` está no CI | `BUN-CORE-02` |
| 2 | operação de diretório usa `node:fs` | `BUN-RT-01` |
| 3 | nenhuma leitura assume que `Bun.file` já leu | `BUN-RT-02` |
| 4 | existência checada por `.exists`, não por `size` | `BUN-RT-03` |
| 5 | todo `FileSink` tem `.end` ou `.unref` | `BUN-RT-04` |
| 6 | env validado na inicialização | `BUN-RT-06` |
| 7 | segredo de produção não vem de `.env` | `BUN-RT-05` |
| 8 | nenhum `*Sync` em handler HTTP | `BUN-RT-08` |
| 9 | subprocesso tem `timeout`/`signal` | `BUN-RT-09` |
| 10 | comando externo usa interpolação de `Bun.$` | `BUN-SYS-01` |
| 11 | senha usa `Bun.password`, não `Bun.hash` | `BUN-RT-10` |
| 12 | `--hot` não é usado onde o estado precisa ser limpo | `BUN-RT-11` |
| 13 | flag de runtime antes do subcomando | `BUN-CORE-07` |

**Rode de verdade:**

```bash
tsc --noEmit # o runtime não checa tipo
bun run <script> # forma explícita
```

---

