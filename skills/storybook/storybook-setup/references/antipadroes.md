# Antipadrões, com ID

> `SB-TS-*` e `SB-RV-*` são **mutuamente exclusivas** — confira o caminho antes de citar.

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| Escolher o framework por inércia, sem checar os pisos | § 5.1 do hub | [Storybook](../../../../knowledge-base/docs/storybook.md) |
| Adotar `tanstack-react` em Vite 5 ou 6 | Passo 1 | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| Prescrever `SB-TS-*` sob `react-vite`, ou o inverso | § 6.2 do hub | [Storybook](../../../../knowledge-base/docs/storybook.md) |
| `main.ts` com `require` | `SB-CORE-03` | [Storybook](../../../../knowledge-base/docs/storybook.md) |
| Node abaixo de 20.19 / 22.12 | `SB-CORE-04` | [Storybook](../../../../knowledge-base/docs/storybook.md) |
| `framework` ausente ou implícito | `SB-CFG-01` | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| Glob relativo à raiz do pacote em vez de `.storybook/` | `SB-CFG-02` | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| Glob apontando para `dist` | § 5.2 do satélite | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| Versões desalinhadas entre pacotes do Storybook | `SB-CFG-04` | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| Configurar tema em `main.ts` | § 5.1 do satélite | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| CSS editável em `preview-head.html` | `SB-CFG-03` | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| `staticDirs` sem o service worker, com MSW em uso | `SB-CFG-05` | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| Duplicar a config do Vite em cada pacote | `SB-CFG-06` | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| Resolver por `viteFinal` o que a base deveria dar | § 3 do satélite | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| Tratar `apps/storybook` como pacote consumível | `SB-CFG-07` | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| Augmentation de tipo dentro de `main.tsx` | Passo 6 | `Pages/Monorepo com Bun - estrutura e tooling.md` |
| Ligar o runner antes de a sidebar mostrar stories | Passo 3.6 | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) |
| Provider repetido por arquivo em vez de decorator global | `SB-CTX-03` | [Storybook - Decorators e Contexto](../../../../knowledge-base/docs/storybook-decorators-e-contexto.md) |

