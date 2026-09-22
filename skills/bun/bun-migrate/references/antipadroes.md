# Antipadrões, com ID

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| Supor compatibilidade porque funciona no Node | `BUN-CORE-05` | [[Bun]] |
| Migrar sem enumerar `node:*` das dependências transitivas | `BUN-SYS-07` | [[Bun - Shell, FFI e Compat Node]] |
| Presumir suporte a `secp256k1`, `argon2`, `ed448`, CCM/OCB/XTS | `BUN-SYS-08` | [[Bun - Shell, FFI e Compat Node]] |
| Observabilidade apoiada em `async_hooks` | `BUN-SYS-09` | [[Bun - Shell, FFI e Compat Node]] |
| Contar com `AsyncLocalStorage` atravessando `Worker` | `BUN-SYS-06` | [[Bun - Shell, FFI e Compat Node]] |
| IPC `serialization: "advanced"` entre Bun e Node | `BUN-SYS-10` | [[Bun - Shell, FFI e Compat Node]] |
| `bun:ffi` ou `cc()` em produção | `BUN-SYS-05` | [[Bun - Shell, FFI e Compat Node]] |
| Container sem dreno de `SIGTERM` | `BUN-SYS-11` | [[Bun - Shell, FFI e Compat Node]] |
| Imagem como root, ou com tag `latest` | `BUN-SYS-12` | [[Bun - Shell, FFI e Compat Node]] |
| Produção contando com auto-install no boot | `BUN-RT-12` | [[Bun - Runtime e APIs]] |
| `child_process.exec` com string concatenada | `BUN-SYS-01` | [[Bun - Shell, FFI e Compat Node]] |
| `$.nothrow()` em escopo global | `BUN-SYS-04` | [[Bun - Shell, FFI e Compat Node]] |
| Global `Bun` rodando sob `node` | `BUN-CORE-01` | [[Bun]] |
| Sem `tsc --noEmit` no CI | `BUN-CORE-02` | [[Bun]] |
| `require()` em módulo com top-level `await` | `BUN-CORE-04` | [[Bun]] |
| Flag de runtime depois do subcomando | `BUN-CORE-07` | [[Bun]] |

