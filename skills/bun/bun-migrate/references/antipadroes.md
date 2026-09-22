# Antipadrões, com ID

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| Supor compatibilidade porque funciona no Node | `BUN-CORE-05` | [Bun](../../../../knowledge-base/docs/bun.md) |
| Migrar sem enumerar `node:*` das dependências transitivas | `BUN-SYS-07` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/docs/bun-shell-ffi-e-compat-node.md) |
| Presumir suporte a `secp256k1`, `argon2`, `ed448`, CCM/OCB/XTS | `BUN-SYS-08` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/docs/bun-shell-ffi-e-compat-node.md) |
| Observabilidade apoiada em `async_hooks` | `BUN-SYS-09` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/docs/bun-shell-ffi-e-compat-node.md) |
| Contar com `AsyncLocalStorage` atravessando `Worker` | `BUN-SYS-06` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/docs/bun-shell-ffi-e-compat-node.md) |
| IPC `serialization: "advanced"` entre Bun e Node | `BUN-SYS-10` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/docs/bun-shell-ffi-e-compat-node.md) |
| `bun:ffi` ou `cc` em produção | `BUN-SYS-05` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/docs/bun-shell-ffi-e-compat-node.md) |
| Container sem dreno de `SIGTERM` | `BUN-SYS-11` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/docs/bun-shell-ffi-e-compat-node.md) |
| Imagem como root, ou com tag `latest` | `BUN-SYS-12` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/docs/bun-shell-ffi-e-compat-node.md) |
| Produção contando com auto-install no boot | `BUN-RT-12` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| `child_process.exec` com string concatenada | `BUN-SYS-01` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/docs/bun-shell-ffi-e-compat-node.md) |
| `$.nothrow` em escopo global | `BUN-SYS-04` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/docs/bun-shell-ffi-e-compat-node.md) |
| Global `Bun` rodando sob `node` | `BUN-CORE-01` | [Bun](../../../../knowledge-base/docs/bun.md) |
| Sem `tsc --noEmit` no CI | `BUN-CORE-02` | [Bun](../../../../knowledge-base/docs/bun.md) |
| `require` em módulo com top-level `await` | `BUN-CORE-04` | [Bun](../../../../knowledge-base/docs/bun.md) |
| Flag de runtime depois do subcomando | `BUN-CORE-07` | [Bun](../../../../knowledge-base/docs/bun.md) |

