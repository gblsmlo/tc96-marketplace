# Antipatterns, with IDs

| Antipattern | ID | Satellite |
| --- | --- | --- |
| Assuming compatibility because it works in Node | `BUN-CORE-05` | [Bun](../../../../knowledge-base/bun.md) |
| Migrating without enumerating `node:*` from transitive dependencies | `BUN-SYS-07` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/bun-shell-ffi-e-compat-node.md) |
| Presuming support for `secp256k1`, `argon2`, `ed448`, CCM/OCB/XTS | `BUN-SYS-08` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/bun-shell-ffi-e-compat-node.md) |
| Observability resting on `async_hooks` | `BUN-SYS-09` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/bun-shell-ffi-e-compat-node.md) |
| Relying on `AsyncLocalStorage` crossing a `Worker` | `BUN-SYS-06` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/bun-shell-ffi-e-compat-node.md) |
| IPC `serialization: "advanced"` between Bun and Node | `BUN-SYS-10` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/bun-shell-ffi-e-compat-node.md) |
| `bun:ffi` or `cc` in production | `BUN-SYS-05` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/bun-shell-ffi-e-compat-node.md) |
| Container without a `SIGTERM` drain | `BUN-SYS-11` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/bun-shell-ffi-e-compat-node.md) |
| Image as root, or with the `latest` tag | `BUN-SYS-12` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/bun-shell-ffi-e-compat-node.md) |
| Production relying on auto-install at boot | `BUN-RT-12` | [Bun - Runtime e APIs](../../../../knowledge-base/bun-runtime-e-apis.md) |
| `child_process.exec` with a concatenated string | `BUN-SYS-01` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/bun-shell-ffi-e-compat-node.md) |
| `$.nothrow` in global scope | `BUN-SYS-04` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/bun-shell-ffi-e-compat-node.md) |
| `Bun` global running under `node` | `BUN-CORE-01` | [Bun](../../../../knowledge-base/bun.md) |
| No `tsc --noEmit` in CI | `BUN-CORE-02` | [Bun](../../../../knowledge-base/bun.md) |
| `require` on a module with top-level `await` | `BUN-CORE-04` | [Bun](../../../../knowledge-base/bun.md) |
| Runtime flag after the subcommand | `BUN-CORE-07` | [Bun](../../../../knowledge-base/bun.md) |

