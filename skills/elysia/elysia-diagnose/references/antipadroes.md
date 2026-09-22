# Antipadrões, com ID

> Confira em `mapa-de-ids.md`. `ELYSIA-LIFE-10` é a aplicação de `ELYSIA-CORE-03` dentro de `macro` — cite o canônico ao falar do princípio, e `LIFE-10` ao falar do macro.

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| Hook, plugin ou `onError` registrado depois das rotas | `ELYSIA-CORE-01` | [[Elysia - Roteamento e Handler]] |
| Hook de plugin sem escopo declarado | `ELYSIA-LIFE-01` | [[Elysia - Lifecycle e Plugins]] |
| `derive` para decisão de auth ou autorização | `ELYSIA-LIFE-02` | [[Elysia - Lifecycle e Plugins]] |
| Plugin sem `name` aplicado por mais de uma instância | `ELYSIA-LIFE-03` | [[Elysia - Lifecycle e Plugins]] |
| `onRequest` lendo `body`/`query`/`params`/`cookie` | `ELYSIA-LIFE-04` | [[Elysia - Lifecycle e Plugins]] |
| Mutar valor de `decorate` | `ELYSIA-LIFE-05` | [[Elysia - Lifecycle e Plugins]] |
| Primitivo do `store` desestruturado no parâmetro | `ELYSIA-LIFE-06` | [[Elysia - Lifecycle e Plugins]] |
| Plugin como callback `(app) => app` | `ELYSIA-LIFE-07` | [[Elysia - Lifecycle e Plugins]] |
| Testar auth só dentro do plugin | `ELYSIA-LIFE-08` | [[Elysia - Lifecycle e Plugins]] |
| Corrente de `scoped` onde cabia `global` | `ELYSIA-LIFE-09` | [[Elysia - Lifecycle e Plugins]] |
| `throw` dentro de macro | `ELYSIA-LIFE-10` | [[Elysia - Lifecycle e Plugins]] |
| Hook como arrow anônima sob OpenTelemetry | `ELYSIA-LIFE-11` | [[Elysia - Lifecycle e Plugins]] |
| `cors()` com `origin` default em API autenticada | `ELYSIA-LIFE-12` | [[Elysia - Lifecycle e Plugins]] |
| Asserção antes de `await app.modules` | `ELYSIA-CORE-10` | [[Elysia - Roteamento e Handler]] |

