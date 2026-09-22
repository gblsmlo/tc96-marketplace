---
gerado-por: skills/storybook/storybook-setup/scripts/gerar-mapa-de-ids.sh
gerado-em: 2026-09-22
---

# Mapa de IDs `SB-*`

> Índice, não cópia. **`SB-TS-*` e `SB-RV-*` são mutuamente exclusivas:**
> citar a família do caminho errado é achado inválido. Descubra o caminho primeiro —
> `bash ${CLAUDE_PLUGIN_ROOT}/skills/storybook-setup/scripts/descobrir-caminho.sh`.
> Regenerar com `bash skills/storybook/storybook-setup/scripts/gerar-mapa-de-ids.sh`.

## Canônicos, apelidos e os pares por caminho


**Dois** princípios aparecem em mais de um satélite com IDs diferentes, porque cada satélite precisa se sustentar sozinho. **Para citar, use sempre o ID canônico** — o outro é apelido e não deve aparecer em revisão.

| Princípio | Canônico | Apelidos |
| --- | --- | --- |
| Estado nomeado é `args`, não código | `SB-CSF-04` | `SB-DOC-05` |
| Estado compartilhado entre stories é resetado | `SB-CTX-04` | `SB-TS-04` |

**Pares por caminho.** Dois princípios têm um ID em cada caminho, e **nenhum dos dois é apelido do outro** — citar o ID do caminho errado é achado inválido (ver a nota sob as famílias). Use o que corresponde ao `framework` do projeto:

| Princípio | Sob `tanstack-react` | Sob `react-vite` |
| --- | --- | --- |
| Não embrulhar o que o framework já embrulha | `SB-TS-03` | `SB-RV-05` |
| Design system que exige rota é acoplamento a corrigir | `SB-TS-08` | `SB-RV-06` |

> **Quatro regras que parecem apelido e não são**, e por isso continuam citáveis por ID próprio:
>
> - `SB-CTX-05` (globals não é `args`) exprime um achado que `SB-CSF-04` não exprime — "usou global onde devia ser arg" não é "pôs estado no `render`".
> - `SB-TEST-07` carrega a exceção do `fn`, que `SB-CTX-04` não carrega.
> - `SB-MOCK-04` é a **metade complementar** de `SB-MOCK-01`, não seu sinônimo: uma diz onde registra, a outra onde comporta. E as duas vivem no mesmo satélite, o que já as tira do critério de apelido.
> - `SB-CTX-06` é **condicional ao framework** e por isso mais ampla que `SB-TS-03`: sob `react-vite` ela continua valendo e simplesmente não é acionada.


## Índice completo

| ID | Satélite | Seção |
| --- | --- | --- |
| `SB-CFG-01` | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) | 1. Os dois arquivos, e a divisão entre eles |
| `SB-CFG-02` | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) | 1. Os dois arquivos, e a divisão entre eles |
| `SB-CFG-03` | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) | 2. Estilo |
| `SB-CFG-04` | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) | 1. Os dois arquivos, e a divisão entre eles |
| `SB-CFG-05` | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) | 2. Estilo |
| `SB-CFG-06` | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) | 4. O recorte no monorepo |
| `SB-CFG-07` | [Storybook - Configuração e Builder](../../../../knowledge-base/docs/storybook-configuracao-e-builder.md) | 4. O recorte no monorepo |
| `SB-CORE-01` | [Storybook](../../../../knowledge-base/docs/storybook.md) | 6. Regras normativas |
| `SB-CORE-02` | [Storybook](../../../../knowledge-base/docs/storybook.md) | 6. Regras normativas |
| `SB-CORE-03` | [Storybook](../../../../knowledge-base/docs/storybook.md) | 6. Regras normativas |
| `SB-CORE-04` | [Storybook](../../../../knowledge-base/docs/storybook.md) | 6. Regras normativas |
| `SB-CORE-05` | [Storybook](../../../../knowledge-base/docs/storybook.md) | 6. Regras normativas |
| `SB-CORE-06` | [Storybook](../../../../knowledge-base/docs/storybook.md) | 6. Regras normativas |
| `SB-CSF-01` | [Storybook - Stories e Args](../../../../knowledge-base/docs/storybook-stories-e-args.md) | 1. Anatomia do arquivo |
| `SB-CSF-02` | [Storybook - Stories e Args](../../../../knowledge-base/docs/storybook-stories-e-args.md) | 2. Tipagem |
| `SB-CSF-03` | [Storybook - Stories e Args](../../../../knowledge-base/docs/storybook-stories-e-args.md) | 1. Anatomia do arquivo |
| `SB-CSF-04` | [Storybook - Stories e Args](../../../../knowledge-base/docs/storybook-stories-e-args.md) | 3. Args |
| `SB-CSF-05` | [Storybook - Stories e Args](../../../../knowledge-base/docs/storybook-stories-e-args.md) | 3. Args |
| `SB-CSF-06` | [Storybook - Stories e Args](../../../../knowledge-base/docs/storybook-stories-e-args.md) | 4. `argTypes` e controles |
| `SB-CSF-07` | [Storybook - Stories e Args](../../../../knowledge-base/docs/storybook-stories-e-args.md) | 3. Args |
| `SB-CSF-08` | [Storybook - Stories e Args](../../../../knowledge-base/docs/storybook-stories-e-args.md) | 4. `argTypes` e controles |
| `SB-CSF-09` | [Storybook - Stories e Args](../../../../knowledge-base/docs/storybook-stories-e-args.md) | 1. Anatomia do arquivo |
| `SB-CSF-10` | [Storybook - Stories e Args](../../../../knowledge-base/docs/storybook-stories-e-args.md) | 1. Anatomia do arquivo |
| `SB-CTX-01` | [Storybook - Decorators e Contexto](../../../../knowledge-base/docs/storybook-decorators-e-contexto.md) | 3. `parameters` |
| `SB-CTX-02` | [Storybook - Decorators e Contexto](../../../../knowledge-base/docs/storybook-decorators-e-contexto.md) | 2. Decorators |
| `SB-CTX-03` | [Storybook - Decorators e Contexto](../../../../knowledge-base/docs/storybook-decorators-e-contexto.md) | 2. Decorators |
| `SB-CTX-04` | [Storybook - Decorators e Contexto](../../../../knowledge-base/docs/storybook-decorators-e-contexto.md) | 5. `beforeEach` |
| `SB-CTX-05` | [Storybook - Decorators e Contexto](../../../../knowledge-base/docs/storybook-decorators-e-contexto.md) | 2. Decorators |
| `SB-CTX-06` | [Storybook - Decorators e Contexto](../../../../knowledge-base/docs/storybook-decorators-e-contexto.md) | 2. Decorators |
| `SB-CTX-07` | [Storybook - Decorators e Contexto](../../../../knowledge-base/docs/storybook-decorators-e-contexto.md) | 5. `beforeEach` |
| `SB-CTX-08` | [Storybook - Decorators e Contexto](../../../../knowledge-base/docs/storybook-decorators-e-contexto.md) | 5. `beforeEach` |
| `SB-DOC-01` | [Storybook - Docs e Autodocs](../../../../knowledge-base/docs/storybook-docs-e-autodocs.md) | 2. Ligar |
| `SB-DOC-02` | [Storybook - Docs e Autodocs](../../../../knowledge-base/docs/storybook-docs-e-autodocs.md) | 5. Story de documentação × story de teste |
| `SB-DOC-03` | [Storybook - Docs e Autodocs](../../../../knowledge-base/docs/storybook-docs-e-autodocs.md) | 5. Story de documentação × story de teste |
| `SB-DOC-04` | [Storybook - Docs e Autodocs](../../../../knowledge-base/docs/storybook-docs-e-autodocs.md) | 5. Story de documentação × story de teste |
| `SB-DOC-05` | [Storybook - Docs e Autodocs](../../../../knowledge-base/docs/storybook-docs-e-autodocs.md) | 2. Ligar |
| `SB-MOCK-01` | [Storybook - Mocking](../../../../knowledge-base/docs/storybook-mocking.md) | 2. `sb.mock` — automock de módulo |
| `SB-MOCK-02` | [Storybook - Mocking](../../../../knowledge-base/docs/storybook-mocking.md) | 2. `sb.mock` — automock de módulo |
| `SB-MOCK-03` | [Storybook - Mocking](../../../../knowledge-base/docs/storybook-mocking.md) | 2. `sb.mock` — automock de módulo |
| `SB-MOCK-04` | [Storybook - Mocking](../../../../knowledge-base/docs/storybook-mocking.md) | 2. `sb.mock` — automock de módulo |
| `SB-MOCK-05` | [Storybook - Mocking](../../../../knowledge-base/docs/storybook-mocking.md) | 2. `sb.mock` — automock de módulo |
| `SB-MOCK-06` | [Storybook - Mocking](../../../../knowledge-base/docs/storybook-mocking.md) | 4. Módulos server-only |
| `SB-MOCK-07` | [Storybook - Mocking](../../../../knowledge-base/docs/storybook-mocking.md) | 3. Rede, com MSW |
| `SB-RV-01` | [Storybook - React Vite](../../../../knowledge-base/docs/storybook-react-vite.md) | 4. O router à mão |
| `SB-RV-02` | [Storybook - React Vite](../../../../knowledge-base/docs/storybook-react-vite.md) | 4. O router à mão |
| `SB-RV-03` | [Storybook - React Vite](../../../../knowledge-base/docs/storybook-react-vite.md) | 4. O router à mão |
| `SB-RV-04` | [Storybook - React Vite](../../../../knowledge-base/docs/storybook-react-vite.md) | 4. O router à mão |
| `SB-RV-05` | [Storybook - React Vite](../../../../knowledge-base/docs/storybook-react-vite.md) | 5. Trocar de caminho |
| `SB-RV-06` | [Storybook - React Vite](../../../../knowledge-base/docs/storybook-react-vite.md) | 4. O router à mão |
| `SB-RV-07` | [Storybook - React Vite](../../../../knowledge-base/docs/storybook-react-vite.md) | 4. O router à mão |
| `SB-TEST-01` | [Storybook - Testes e Interações](../../../../knowledge-base/docs/storybook-testes-e-interacoes.md) | 2. `play` |
| `SB-TEST-02` | [Storybook - Testes e Interações](../../../../knowledge-base/docs/storybook-testes-e-interacoes.md) | 2. `play` |
| `SB-TEST-03` | [Storybook - Testes e Interações](../../../../knowledge-base/docs/storybook-testes-e-interacoes.md) | 2. `play` |
| `SB-TEST-04` | [Storybook - Testes e Interações](../../../../knowledge-base/docs/storybook-testes-e-interacoes.md) | 3. Acessibilidade |
| `SB-TEST-05` | [Storybook - Testes e Interações](../../../../knowledge-base/docs/storybook-testes-e-interacoes.md) | 4. O runner: `@storybook/addon-vitest` |
| `SB-TEST-06` | [Storybook - Testes e Interações](../../../../knowledge-base/docs/storybook-testes-e-interacoes.md) | 2. `play` |
| `SB-TEST-07` | [Storybook - Testes e Interações](../../../../knowledge-base/docs/storybook-testes-e-interacoes.md) | 2. `play` |
| `SB-TEST-08` | [Storybook - Testes e Interações](../../../../knowledge-base/docs/storybook-testes-e-interacoes.md) | 2. `play` |
| `SB-TEST-09` | [Storybook - Testes e Interações](../../../../knowledge-base/docs/storybook-testes-e-interacoes.md) | 2. `play` |
| `SB-TEST-10` | [Storybook - Testes e Interações](../../../../knowledge-base/docs/storybook-testes-e-interacoes.md) | 2. `play` |
| `SB-TEST-11` | [Storybook - Cobertura e CI](../../../../knowledge-base/docs/storybook-cobertura-e-ci.md) | 4. Regras — `SB-TEST-11` a `SB-TEST-17` |
| `SB-TEST-12` | [Storybook - Cobertura e CI](../../../../knowledge-base/docs/storybook-cobertura-e-ci.md) | 4. Regras — `SB-TEST-11` a `SB-TEST-17` |
| `SB-TEST-13` | [Storybook - Cobertura e CI](../../../../knowledge-base/docs/storybook-cobertura-e-ci.md) | 4. Regras — `SB-TEST-11` a `SB-TEST-17` |
| `SB-TEST-14` | [Storybook - Cobertura e CI](../../../../knowledge-base/docs/storybook-cobertura-e-ci.md) | 4. Regras — `SB-TEST-11` a `SB-TEST-17` |
| `SB-TEST-15` | [Storybook - Cobertura e CI](../../../../knowledge-base/docs/storybook-cobertura-e-ci.md) | 4. Regras — `SB-TEST-11` a `SB-TEST-17` |
| `SB-TEST-16` | [Storybook - Cobertura e CI](../../../../knowledge-base/docs/storybook-cobertura-e-ci.md) | 4. Regras — `SB-TEST-11` a `SB-TEST-17` |
| `SB-TEST-17` | [Storybook - Cobertura e CI](../../../../knowledge-base/docs/storybook-cobertura-e-ci.md) | 4. Regras — `SB-TEST-11` a `SB-TEST-17` |
| `SB-TS-01` | [Storybook - TanStack React](../../../../knowledge-base/docs/storybook-tanstack-react.md) | 11. Regras — `SB-TS-*` |
| `SB-TS-02` | [Storybook - TanStack React](../../../../knowledge-base/docs/storybook-tanstack-react.md) | 11. Regras — `SB-TS-*` |
| `SB-TS-03` | [Storybook - TanStack React](../../../../knowledge-base/docs/storybook-tanstack-react.md) | 11. Regras — `SB-TS-*` |
| `SB-TS-04` | [Storybook - TanStack React](../../../../knowledge-base/docs/storybook-tanstack-react.md) | 11. Regras — `SB-TS-*` |
| `SB-TS-05` | [Storybook - TanStack React](../../../../knowledge-base/docs/storybook-tanstack-react.md) | 11. Regras — `SB-TS-*` |
| `SB-TS-06` | [Storybook - TanStack React](../../../../knowledge-base/docs/storybook-tanstack-react.md) | 11. Regras — `SB-TS-*` |
| `SB-TS-07` | [Storybook - TanStack React](../../../../knowledge-base/docs/storybook-tanstack-react.md) | 11. Regras — `SB-TS-*` |
| `SB-TS-08` | [Storybook - TanStack React](../../../../knowledge-base/docs/storybook-tanstack-react.md) | 11. Regras — `SB-TS-*` |
