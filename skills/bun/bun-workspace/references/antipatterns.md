# Antipatterns, with IDs

| Antipattern | ID | Satellite |
| --- | --- | --- |
| `bun.lock` outside the repository | `BUN-PKG-01` | [Bun - Package Manager](../../docs/bun-package-manager.md) |
| Plain `bun install` in CI | `BUN-PKG-02` | [Bun - Package Manager](../../docs/bun-package-manager.md) |
| Adding to `trustedDependencies` without showing the command | `BUN-PKG-03` | [Bun - Package Manager](../../docs/bun-package-manager.md) |
| Declaring `trustedDependencies` without re-including the default list | `BUN-PKG-04` | [Bun - Package Manager](../../docs/bun-package-manager.md) |
| `--production` as `node_modules` cleanup | `BUN-PKG-05` | [Bun - Package Manager](../../docs/bun-package-manager.md) |
| Shared version repeated in every `package.json` | `BUN-PKG-06` | [Bun - Package Manager](../../docs/bun-package-manager.md) |
| `catalog:` in a published package | `BUN-PKG-07` | [Bun - Package Manager](../../docs/bun-package-manager.md) |
| `overrides` in a workspace `package.json` | `BUN-PKG-08` | [Bun - Package Manager](../../docs/bun-package-manager.md) |
| Editing `node_modules/` without `bun patch` | `BUN-PKG-09` | [Bun - Package Manager](../../docs/bun-package-manager.md) |
| Layout-dependent build without a declared `linker` | `BUN-PKG-10` | [Bun - Package Manager](../../docs/bun-package-manager.md) |
| `bunx <pkg>` without a version in CI | `BUN-PKG-11` | [Bun - Package Manager](../../docs/bun-package-manager.md) |
| Monorepo root listing a dependency that a package imports | `BUN-PKG-12` | [Bun - Package Manager](../../docs/bun-package-manager.md) |
| Project without `tsc --noEmit` in CI | `BUN-CORE-02` | [Bun](../../docs/bun.md) |
| `jest`/`ts-node`/`nodemon`/`dotenv` added without justification | `BUN-CORE-03` | [Bun](../../docs/bun.md) |
| `bun <script>` in automation | `BUN-CORE-06` | [Bun](../../docs/bun.md) |

