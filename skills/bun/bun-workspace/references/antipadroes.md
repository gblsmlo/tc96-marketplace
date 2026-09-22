# Antipadrões, com ID

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| `bun.lock` fora do repositório | `BUN-PKG-01` | [[Bun - Gerenciador de Pacotes]] |
| `bun install` puro em CI | `BUN-PKG-02` | [[Bun - Gerenciador de Pacotes]] |
| Adicionar a `trustedDependencies` sem mostrar o comando | `BUN-PKG-03` | [[Bun - Gerenciador de Pacotes]] |
| Declarar `trustedDependencies` sem reincluir a lista padrão | `BUN-PKG-04` | [[Bun - Gerenciador de Pacotes]] |
| `--production` como limpeza de `node_modules` | `BUN-PKG-05` | [[Bun - Gerenciador de Pacotes]] |
| Versão compartilhada repetida em cada `package.json` | `BUN-PKG-06` | [[Bun - Gerenciador de Pacotes]] |
| `catalog:` num pacote publicado | `BUN-PKG-07` | [[Bun - Gerenciador de Pacotes]] |
| `overrides` num `package.json` de workspace | `BUN-PKG-08` | [[Bun - Gerenciador de Pacotes]] |
| Editar `node_modules/` sem `bun patch` | `BUN-PKG-09` | [[Bun - Gerenciador de Pacotes]] |
| Build dependente do layout, sem `linker` declarado | `BUN-PKG-10` | [[Bun - Gerenciador de Pacotes]] |
| `bunx <pkg>` sem versão em CI | `BUN-PKG-11` | [[Bun - Gerenciador de Pacotes]] |
| Raiz de monorepo listando dependência que um pacote importa | `BUN-PKG-12` | [[Bun - Gerenciador de Pacotes]] |
| Projeto sem `tsc --noEmit` no CI | `BUN-CORE-02` | [[Bun]] |
| `jest`/`ts-node`/`nodemon`/`dotenv` adicionados sem justificativa | `BUN-CORE-03` | [[Bun]] |
| `bun <script>` em automação | `BUN-CORE-06` | [[Bun]] |

