# Antipadrões, com ID

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| `Bun.file` para operação de diretório | `BUN-RT-01` | [[Bun - Runtime e APIs]] |
| Tratar `Bun.file()` como leitura já feita | `BUN-RT-02` | [[Bun - Runtime e APIs]] |
| Checar existência por `size === 0` | `BUN-RT-03` | [[Bun - Runtime e APIs]] |
| `FileSink` sem `.end()` — processo não termina | `BUN-RT-04` | [[Bun - Runtime e APIs]] |
| Segredo de produção em `.env` do runtime | `BUN-RT-05` | [[Bun - Runtime e APIs]] |
| Env sem validação na inicialização | `BUN-RT-06` | [[Bun - Runtime e APIs]] |
| `$` não escapado em valor de `.env` | `BUN-RT-07` | [[Bun - Runtime e APIs]] |
| `*Sync` em handler HTTP | `BUN-RT-08` | [[Bun - Runtime e APIs]] |
| Subprocesso sem `timeout`/`signal` | `BUN-RT-09` | [[Bun - Runtime e APIs]] |
| `Bun.hash` em senha ou token | `BUN-RT-10` | [[Bun - Runtime e APIs]] |
| `--hot` em teste ou job | `BUN-RT-11` | [[Bun - Runtime e APIs]] |
| Produção contando com auto-install | `BUN-RT-12` | [[Bun - Runtime e APIs]] |
| Código com global `Bun` rodando sob `node` | `BUN-CORE-01` | [[Bun]] |
| Projeto sem `tsc --noEmit` no CI | `BUN-CORE-02` | [[Bun]] |
| `jest`/`ts-node`/`nodemon`/`dotenv` sem justificativa | `BUN-CORE-03` | [[Bun]] |
| `require()` em módulo com top-level `await` | `BUN-CORE-04` | [[Bun]] |
| `bun <script>` em automação (forma curta) | `BUN-CORE-06` | [[Bun]] |
| Flag de runtime depois do subcomando | `BUN-CORE-07` | [[Bun]] |
| `child_process.exec` com string concatenada | `BUN-SYS-01` | [[Bun - Shell, FFI e Compat Node]] |
| Valor externo dentro de `sh -c` disparado por `Bun.$` | `BUN-SYS-02` | [[Bun - Shell, FFI e Compat Node]] |
| Argumento de runtime começando com `-`, sem `--` | `BUN-SYS-03` | [[Bun - Shell, FFI e Compat Node]] |
| `$.nothrow()` em escopo global | `BUN-SYS-04` | [[Bun - Shell, FFI e Compat Node]] |

