# Antipatterns, with IDs

| Antipattern | ID | Satellite |
| --- | --- | --- |
| Assuming compatibility because it works in Node | `BUN-CORE-05` | [Bun](../../docs/bun.md) |
| Migrating without enumerating `node:*` from transitive dependencies | `BUN-SYS-07` | [Bun - Shell, FFI and Node Compat](../../docs/bun-shell-ffi-and-node-compat.md) |
| Presuming support for `secp256k1`, `argon2`, `ed448`, CCM/OCB/XTS | `BUN-SYS-08` | [Bun - Shell, FFI and Node Compat](../../docs/bun-shell-ffi-and-node-compat.md) |
| Observability resting on `async_hooks` | `BUN-SYS-09` | [Bun - Shell, FFI and Node Compat](../../docs/bun-shell-ffi-and-node-compat.md) |
| Relying on `AsyncLocalStorage` crossing a `Worker` | `BUN-SYS-06` | [Bun - Shell, FFI and Node Compat](../../docs/bun-shell-ffi-and-node-compat.md) |
| IPC `serialization: "advanced"` between Bun and Node | `BUN-SYS-10` | [Bun - Shell, FFI and Node Compat](../../docs/bun-shell-ffi-and-node-compat.md) |
| `bun:ffi` or `cc` in production | `BUN-SYS-05` | [Bun - Shell, FFI and Node Compat](../../docs/bun-shell-ffi-and-node-compat.md) |
| Shell-form `CMD bun …` in the Dockerfile | — (Docker) | `references/container.md` § 4.1 |
| Container without a `SIGTERM` drain | `BUN-SYS-11` | [Bun - Shell, FFI and Node Compat](../../docs/bun-shell-ffi-and-node-compat.md) |
| Image as root, or with the `latest` tag | `BUN-SYS-12` | [Bun - Shell, FFI and Node Compat](../../docs/bun-shell-ffi-and-node-compat.md) |
| Production relying on auto-install at boot | `BUN-RT-12` | [Bun - Runtime and APIs](../../docs/bun-runtime-and-apis.md) |
| `child_process.exec` with a concatenated string | `BUN-SYS-01` | [Bun - Shell, FFI and Node Compat](../../docs/bun-shell-ffi-and-node-compat.md) |
| `$.nothrow` in global scope | `BUN-SYS-04` | [Bun - Shell, FFI and Node Compat](../../docs/bun-shell-ffi-and-node-compat.md) |
| `Bun` global running under `node` | `BUN-CORE-01` | [Bun](../../docs/bun.md) |
| No `tsc --noEmit` in CI | `BUN-CORE-02` | [Bun](../../docs/bun.md) |
| `require` on a module with top-level `await` | `BUN-CORE-04` | [Bun](../../docs/bun.md) |
| Runtime flag after the subcommand | `BUN-CORE-07` | [Bun](../../docs/bun.md) |

