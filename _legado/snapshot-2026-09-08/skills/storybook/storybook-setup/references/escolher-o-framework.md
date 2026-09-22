# Escolher o framework, e a plataforma

A decisão que tudo depois pressupõe. A árvore completa é a § 5.1 do hub:

```
Alguma story vai importar @tanstack/react-router —
direta ou transitivamente (um <Link> dentro de um componente conta)?
├── NÃO, e nunca vai        → @storybook/react-vite
│                             piso: React ≥ 16.8 · Vite ≥ 5
└── SIM, ou provavelmente
    ├── o projeto está em React ≥ 18 E Vite ≥ 7?
    │   ├── SIM → @storybook/tanstack-react
    │   └── NÃO → @storybook/react-vite + router à mão  (transição)
```

| | `@storybook/tanstack-react` | `@storybook/react-vite` |
| --- | --- | --- |
| React | ≥ **18** | ≥ 16.8 |
| Vite | ≥ **7** | ≥ 5 |
| família de regra | `SB-TS-*` | `SB-RV-*` |
| nota | [[Storybook - TanStack React]] | [[Storybook - React Vite]] |

Três fatos que mudam a decisão e não são óbvios:

- **`tanstack-react` cobra o piso mais alto de toda a estrutura: Vite ≥ 7.** Adotá-lo num app em Vite 5 ou 6 é agendar uma **migração de Vite antes de qualquer story** — não é detalhe de configuração.
- **TanStack Start não é requisito.** A fonte declara suporte a SPA usando só `@tanstack/react-router`. Numa SPA com BFF separado, os stubs de server function ficam inertes, e isso é esperado, não sintoma.
- **O redirecionamento de `@tanstack/react-router` para a camada de mock é global**, não opt-in — vale também para stories de `packages/ui` que não tocam rota. É custo, e entra na conta.

**Num monorepo, a pergunta não é sobre `packages/ui`** — é sobre o pacote mais exigente que o Storybook vai cobrir. Um Storybook que também mostra `apps/web`, onde toda página importa `Link`, precisa do framework que embrulha rota.

> **A escolha é praticamente irreversível.** A automigração `react-vite-to-tanstack-react` é unidirecional, e `routeOverrides` não tem substituto direto do lado Vite. Decidir por inércia aqui custa uma migração depois.

Registre a escolha: ela determina qual nota de caminho carregar pelo resto da vida do projeto, e citar a família do caminho errado é achado inválido ([[Storybook]] § 6.2).

---

## Passo 2 — Conferir a plataforma

Duas restrições da linha 10 que quebram projeto vindo da 8 ou 9:

| Restrição | Regra |
| --- | --- |
| **ESM-only** — `main.ts` e presets precisam ser ESM válido; `require`/`module.exports` não sobem | `SB-CORE-03` |
| **Node ≥ 20.19 ou ≥ 22.12** | `SB-CORE-04` |

> **Atenção ao piso de Node quando há Playwright no projeto:** [[Playwright]] exige Node **≥ 22** (22.x, 24.x ou 26.x). Um projeto em Node 20.19 roda Storybook e **não** roda Playwright 1.62 — e o addon-vitest usa Playwright. Na prática, o piso efetivo do monorepo é 22.12.

---

