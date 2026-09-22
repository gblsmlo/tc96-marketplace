# Antipadrões, com ID

> Confira o ID em `mapa-de-ids.md` antes de citar. Dois apelidos são **parciais**:
> `ELYSIA-APP-03` só na cláusula de desestruturação, `ELYSIA-TYPE-11` só na de `strict`.

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| Quebrar o method chaining em statements | `ELYSIA-APP-01` | [Elysia](../../../../knowledge-base/docs/elysia.md) |
| Usar `error` do contexto (removido em 1.4) | `ELYSIA-APP-02` | [Elysia](../../../../knowledge-base/docs/elysia.md) |
| Handler como função externa anotada com `Context` | `ELYSIA-CORE-02` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) |
| `strict: false` ou TS < 5.0 num dos lados do Eden | `ELYSIA-APP-04` | [Elysia](../../../../knowledge-base/docs/elysia.md) |
| Exportar a instância como valor, não como tipo | `ELYSIA-APP-05` | [Elysia](../../../../knowledge-base/docs/elysia.md) |
| `@elysiajs/swagger` em código novo | `ELYSIA-APP-07` | [Elysia](../../../../knowledge-base/docs/elysia.md) |
| Segredo literal em `jwt.secret`/`cookie.secrets` | `ELYSIA-APP-08` | [Elysia](../../../../knowledge-base/docs/elysia.md) |
| `process.env` lido direto na aplicação | `ELYSIA-APP-09` | [Elysia](../../../../knowledge-base/docs/elysia.md) |
| Hook, plugin ou `onError` registrado depois das rotas | `ELYSIA-CORE-01` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) |
| `throw` para erro esperado que precisa chegar tipado | `ELYSIA-CORE-03` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) |
| `set.status` onde há schema de `response` | `ELYSIA-CORE-04` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) |
| Cookie de sessão sem assinatura ou sem `httpOnly` | `ELYSIA-CORE-05` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) |
| Alterar `set.headers` depois do primeiro `yield` | `ELYSIA-CORE-06` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) |
| `onError` devolvendo `error.message` de `UNKNOWN` | `ELYSIA-CORE-07` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) |
| Erro de domínio sem `.error({...})` | `ELYSIA-CORE-08` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) |
| Teste subindo servidor e requisitando por rede | `ELYSIA-CORE-09` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) |
| Asserção antes de `await app.modules` | `ELYSIA-CORE-10` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) |

