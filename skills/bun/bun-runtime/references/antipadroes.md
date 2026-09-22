# Antipadrões, com ID

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| `Bun.file` para operação de diretório | `BUN-RT-01` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| Tratar `Bun.file` como leitura já feita | `BUN-RT-02` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| Checar existência por `size === 0` | `BUN-RT-03` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| `FileSink` sem `.end` — processo não termina | `BUN-RT-04` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| Segredo de produção em `.env` do runtime | `BUN-RT-05` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| Env sem validação na inicialização | `BUN-RT-06` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| `$` não escapado em valor de `.env` | `BUN-RT-07` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| `*Sync` em handler HTTP | `BUN-RT-08` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| Subprocesso sem `timeout`/`signal` | `BUN-RT-09` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| `Bun.hash` em senha ou token | `BUN-RT-10` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| `--hot` em teste ou job | `BUN-RT-11` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| Produção contando com auto-install | `BUN-RT-12` | [Bun - Runtime e APIs](../../../../knowledge-base/docs/bun-runtime-e-apis.md) |
| Código com global `Bun` rodando sob `node` | `BUN-CORE-01` | [Bun](../../../../knowledge-base/docs/bun.md) |
| Projeto sem `tsc --noEmit` no CI | `BUN-CORE-02` | [Bun](../../../../knowledge-base/docs/bun.md) |
| `jest`/`ts-node`/`nodemon`/`dotenv` sem justificativa | `BUN-CORE-03` | [Bun](../../../../knowledge-base/docs/bun.md) |
| `require` em módulo com top-level `await` | `BUN-CORE-04` | [Bun](../../../../knowledge-base/docs/bun.md) |
| `bun <script>` em automação (forma curta) | `BUN-CORE-06` | [Bun](../../../../knowledge-base/docs/bun.md) |
| Flag de runtime depois do subcomando | `BUN-CORE-07` | [Bun](../../../../knowledge-base/docs/bun.md) |
| `child_process.exec` com string concatenada | `BUN-SYS-01` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/docs/bun-shell-ffi-e-compat-node.md) |
| Valor externo dentro de `sh -c` disparado por `Bun.$` | `BUN-SYS-02` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/docs/bun-shell-ffi-e-compat-node.md) |
| Argumento de runtime começando com `-`, sem `--` | `BUN-SYS-03` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/docs/bun-shell-ffi-e-compat-node.md) |
| `$.nothrow` em escopo global | `BUN-SYS-04` | [Bun - Shell, FFI e Compat Node](../../../../knowledge-base/docs/bun-shell-ffi-e-compat-node.md) |

