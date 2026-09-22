# Self-check before delivering

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/bun-runtime/scripts/autoverificar.sh src
```

| # | Check | Rule |
| --- | --- | --- |
| 1 | `tsc --noEmit` is in CI | `BUN-CORE-02` |
| 2 | directory operations use `node:fs` | `BUN-RT-01` |
| 3 | no read assumes `Bun.file` has already read | `BUN-RT-02` |
| 4 | existence checked via `.exists`, not via `size` | `BUN-RT-03` |
| 5 | every `FileSink` has `.end` or `.unref` | `BUN-RT-04` |
| 6 | env validated at startup | `BUN-RT-06` |
| 7 | production secrets do not come from `.env` | `BUN-RT-05` |
| 8 | no `*Sync` in an HTTP handler | `BUN-RT-08` |
| 9 | subprocesses have `timeout`/`signal` | `BUN-RT-09` |
| 10 | external commands use `Bun.$` interpolation | `BUN-SYS-01` |
| 11 | passwords use `Bun.password`, not `Bun.hash` | `BUN-RT-10` |
| 12 | `--hot` is not used where state has to be clean | `BUN-RT-11` |
| 13 | runtime flags before the subcommand | `BUN-CORE-07` |

**Actually run it:**

```bash
tsc --noEmit # the runtime does not type-check
bun run <script> # explicit form
```
