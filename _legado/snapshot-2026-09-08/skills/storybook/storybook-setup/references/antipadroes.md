# Antipadrões, com ID

> `SB-TS-*` e `SB-RV-*` são **mutuamente exclusivas** — confira o caminho antes de citar.

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| Escolher o framework por inércia, sem checar os pisos | § 5.1 do hub | [[Storybook]] |
| Adotar `tanstack-react` em Vite 5 ou 6 | Passo 1 | [[Storybook - Configuração e Builder]] |
| Prescrever `SB-TS-*` sob `react-vite`, ou o inverso | § 6.2 do hub | [[Storybook]] |
| `main.ts` com `require` | `SB-CORE-03` | [[Storybook]] |
| Node abaixo de 20.19 / 22.12 | `SB-CORE-04` | [[Storybook]] |
| `framework` ausente ou implícito | `SB-CFG-01` | [[Storybook - Configuração e Builder]] |
| Glob relativo à raiz do pacote em vez de `.storybook/` | `SB-CFG-02` | [[Storybook - Configuração e Builder]] |
| Glob apontando para `dist` | § 5.2 do satélite | [[Storybook - Configuração e Builder]] |
| Versões desalinhadas entre pacotes do Storybook | `SB-CFG-04` | [[Storybook - Configuração e Builder]] |
| Configurar tema em `main.ts` | § 5.1 do satélite | [[Storybook - Configuração e Builder]] |
| CSS editável em `preview-head.html` | `SB-CFG-03` | [[Storybook - Configuração e Builder]] |
| `staticDirs` sem o service worker, com MSW em uso | `SB-CFG-05` | [[Storybook - Configuração e Builder]] |
| Duplicar a config do Vite em cada pacote | `SB-CFG-06` | [[Storybook - Configuração e Builder]] |
| Resolver por `viteFinal` o que a base deveria dar | § 3 do satélite | [[Storybook - Configuração e Builder]] |
| Tratar `apps/storybook` como pacote consumível | `SB-CFG-07` | [[Storybook - Configuração e Builder]] |
| Augmentation de tipo dentro de `main.tsx` | Passo 6 | [[Monorepo com Bun - estrutura e tooling]] |
| Ligar o runner antes de a sidebar mostrar stories | Passo 3.6 | [[Storybook - Configuração e Builder]] |
| Provider repetido por arquivo em vez de decorator global | `SB-CTX-03` | [[Storybook - Decorators e Contexto]] |

