# Antipadrões, com ID

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| `bun.lock` fora do repositório | `BUN-PKG-01` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| `bun install` puro em CI | `BUN-PKG-02` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| Adicionar a `trustedDependencies` sem mostrar o comando | `BUN-PKG-03` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| Declarar `trustedDependencies` sem reincluir a lista padrão | `BUN-PKG-04` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| `--production` como limpeza de `node_modules` | `BUN-PKG-05` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| Versão compartilhada repetida em cada `package.json` | `BUN-PKG-06` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| `catalog:` num pacote publicado | `BUN-PKG-07` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| `overrides` num `package.json` de workspace | `BUN-PKG-08` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| Editar `node_modules/` sem `bun patch` | `BUN-PKG-09` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| Build dependente do layout, sem `linker` declarado | `BUN-PKG-10` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| `bunx <pkg>` sem versão em CI | `BUN-PKG-11` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| Raiz de monorepo listando dependência que um pacote importa | `BUN-PKG-12` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| Projeto sem `tsc --noEmit` no CI | `BUN-CORE-02` | [Bun](../../../../knowledge-base/docs/bun.md) |
| `jest`/`ts-node`/`nodemon`/`dotenv` adicionados sem justificativa | `BUN-CORE-03` | [Bun](../../../../knowledge-base/docs/bun.md) |
| `bun <script>` em automação | `BUN-CORE-06` | [Bun](../../../../knowledge-base/docs/bun.md) |

