# Antipatterns, with IDs

| Antipattern | ID | Satellite |
| --- | --- | --- |
| `Bun.file` for a directory operation | `BUN-RT-01` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| Treating `Bun.file` as a read already done | `BUN-RT-02` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| Checking existence via `size === 0` | `BUN-RT-03` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| `FileSink` without `.end` — the process never exits | `BUN-RT-04` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| Production secret in the runtime `.env` | `BUN-RT-05` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| Env without validation at startup | `BUN-RT-06` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| Unescaped `$` in a `.env` value | `BUN-RT-07` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| `*Sync` in an HTTP handler | `BUN-RT-08` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| Subprocess without `timeout`/`signal` | `BUN-RT-09` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| `Bun.hash` on a password or token | `BUN-RT-10` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| `--hot` in a test or job | `BUN-RT-11` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| Production relying on auto-install | `BUN-RT-12` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| Code with the `Bun` global running under `node` | `BUN-CORE-01` | [Bun](../../../../knowledge-base/docs/bun.md) |
| Project without `tsc --noEmit` in CI | `BUN-CORE-02` | [Bun](../../../../knowledge-base/docs/bun.md) |
| `jest`/`ts-node`/`nodemon`/`dotenv` without justification | `BUN-CORE-03` | [Bun](../../../../knowledge-base/docs/bun.md) |
| `require` on a module with top-level `await` | `BUN-CORE-04` | [Bun](../../../../knowledge-base/docs/bun.md) |
| `bun <script>` in automation (short form) | `BUN-CORE-06` | [Bun](../../../../knowledge-base/docs/bun.md) |
| Runtime flag after the subcommand | `BUN-CORE-07` | [Bun](../../../../knowledge-base/docs/bun.md) |
| `child_process.exec` with a concatenated string | `BUN-SYS-01` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/docs/bun-shell-ffi-e-compat-node.md) |
| External value inside `sh -c` fired by `Bun.$` | `BUN-SYS-02` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/docs/bun-shell-ffi-e-compat-node.md) |
| Runtime argument starting with `-`, without `--` | `BUN-SYS-03` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/docs/bun-shell-ffi-e-compat-node.md) |
| `$.nothrow` in global scope | `BUN-SYS-04` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/docs/bun-shell-ffi-e-compat-node.md) |

