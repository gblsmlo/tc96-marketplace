# Antipatterns, with IDs

| Antipattern | ID | Satellite |
| --- | --- | --- |
| `bun.lock` outside the repository | `BUN-PKG-01` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| Plain `bun install` in CI | `BUN-PKG-02` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| Adding to `trustedDependencies` without showing the command | `BUN-PKG-03` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| Declaring `trustedDependencies` without re-including the default list | `BUN-PKG-04` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| `--production` as `node_modules` cleanup | `BUN-PKG-05` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| Shared version repeated in every `package.json` | `BUN-PKG-06` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| `catalog:` in a published package | `BUN-PKG-07` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| `overrides` in a workspace `package.json` | `BUN-PKG-08` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| Editing `node_modules/` without `bun patch` | `BUN-PKG-09` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| Layout-dependent build without a declared `linker` | `BUN-PKG-10` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| `bunx <pkg>` without a version in CI | `BUN-PKG-11` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| Monorepo root listing a dependency that a package imports | `BUN-PKG-12` | [Bun - Gerenciador de Pacotes](../../../../knowledge-base/docs/bun-gerenciador-de-pacotes.md) |
| Project without `tsc --noEmit` in CI | `BUN-CORE-02` | [Bun](../../../../knowledge-base/docs/bun.md) |
| `jest`/`ts-node`/`nodemon`/`dotenv` added without justification | `BUN-CORE-03` | [Bun](../../../../knowledge-base/docs/bun.md) |
| `bun <script>` in automation | `BUN-CORE-06` | [Bun](../../../../knowledge-base/docs/bun.md) |

