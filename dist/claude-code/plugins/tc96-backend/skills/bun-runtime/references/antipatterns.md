# Antipatterns, with IDs

| Antipattern | ID | Satellite |
| --- | --- | --- |
| `Bun.file` for a directory operation | `BUN-RT-01` | [Bun - Runtime and APIs](../../../docs/bun/bun-runtime-and-apis.md) |
| Treating `Bun.file` as a read already done | `BUN-RT-02` | [Bun - Runtime and APIs](../../../docs/bun/bun-runtime-and-apis.md) |
| Checking existence via `size === 0` | `BUN-RT-03` | [Bun - Runtime and APIs](../../../docs/bun/bun-runtime-and-apis.md) |
| `FileSink` without `.end` — the process never exits | `BUN-RT-04` | [Bun - Runtime and APIs](../../../docs/bun/bun-runtime-and-apis.md) |
| Production secret in the runtime `.env` | `BUN-RT-05` | [Bun - Runtime and APIs](../../../docs/bun/bun-runtime-and-apis.md) |
| Env without validation at startup | `BUN-RT-06` | [Bun - Runtime and APIs](../../../docs/bun/bun-runtime-and-apis.md) |
| Unescaped `$` in a `.env` value | `BUN-RT-07` | [Bun - Runtime and APIs](../../../docs/bun/bun-runtime-and-apis.md) |
| `*Sync` in an HTTP handler | `BUN-RT-08` | [Bun - Runtime and APIs](../../../docs/bun/bun-runtime-and-apis.md) |
| Subprocess without `timeout`/`signal` | `BUN-RT-09` | [Bun - Runtime and APIs](../../../docs/bun/bun-runtime-and-apis.md) |
| `Bun.hash` on a password or token | `BUN-RT-10` | [Bun - Runtime and APIs](../../../docs/bun/bun-runtime-and-apis.md) |
| `--hot` in a test or job | `BUN-RT-11` | [Bun - Runtime and APIs](../../../docs/bun/bun-runtime-and-apis.md) |
| Production relying on auto-install | `BUN-RT-12` | [Bun - Runtime and APIs](../../../docs/bun/bun-runtime-and-apis.md) |
| Code with the `Bun` global running under `node` | `BUN-CORE-01` | [Bun](../../../docs/bun/bun.md) |
| Project without `tsc --noEmit` in CI | `BUN-CORE-02` | [Bun](../../../docs/bun/bun.md) |
| `jest`/`ts-node`/`nodemon`/`dotenv` without justification | `BUN-CORE-03` | [Bun](../../../docs/bun/bun.md) |
| `require` on a module with top-level `await` | `BUN-CORE-04` | [Bun](../../../docs/bun/bun.md) |
| `bun <script>` in automation (short form) | `BUN-CORE-06` | [Bun](../../../docs/bun/bun.md) |
| Runtime flag after the subcommand | `BUN-CORE-07` | [Bun](../../../docs/bun/bun.md) |
| `child_process.exec` with a concatenated string | `BUN-SYS-01` | [Bun - Shell, FFI and Node Compat](../../../docs/bun/bun-shell-ffi-and-node-compat.md) |
| External value inside `sh -c` fired by `Bun.$` | `BUN-SYS-02` | [Bun - Shell, FFI and Node Compat](../../../docs/bun/bun-shell-ffi-and-node-compat.md) |
| Runtime argument starting with `-`, without `--` | `BUN-SYS-03` | [Bun - Shell, FFI and Node Compat](../../../docs/bun/bun-shell-ffi-and-node-compat.md) |
| `$.nothrow` in global scope | `BUN-SYS-04` | [Bun - Shell, FFI and Node Compat](../../../docs/bun/bun-shell-ffi-and-node-compat.md) |

