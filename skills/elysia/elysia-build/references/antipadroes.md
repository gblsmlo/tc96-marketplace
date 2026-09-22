# Antipadrões, com ID

> Confira o ID em `mapa-de-ids.md` antes de citar. Dois apelidos são **parciais**:
> `ELYSIA-APP-03` só na cláusula de desestruturação, `ELYSIA-TYPE-11` só na de `strict`.

| Antipadrão | ID | Satélite |
| --- | --- | --- |
| Quebrar o method chaining em statements | `ELYSIA-APP-01` | [[Elysia]] |
| Usar `error` do contexto (removido em 1.4) | `ELYSIA-APP-02` | [[Elysia]] |
| Handler como função externa anotada com `Context` | `ELYSIA-CORE-02` | [[Elysia - Roteamento e Handler]] |
| `strict: false` ou TS < 5.0 num dos lados do Eden | `ELYSIA-APP-04` | [[Elysia]] |
| Exportar a instância como valor, não como tipo | `ELYSIA-APP-05` | [[Elysia]] |
| `@elysiajs/swagger` em código novo | `ELYSIA-APP-07` | [[Elysia]] |
| Segredo literal em `jwt.secret`/`cookie.secrets` | `ELYSIA-APP-08` | [[Elysia]] |
| `process.env` lido direto na aplicação | `ELYSIA-APP-09` | [[Elysia]] |
| Hook, plugin ou `onError` registrado depois das rotas | `ELYSIA-CORE-01` | [[Elysia - Roteamento e Handler]] |
| `throw` para erro esperado que precisa chegar tipado | `ELYSIA-CORE-03` | [[Elysia - Roteamento e Handler]] |
| `set.status` onde há schema de `response` | `ELYSIA-CORE-04` | [[Elysia - Roteamento e Handler]] |
| Cookie de sessão sem assinatura ou sem `httpOnly` | `ELYSIA-CORE-05` | [[Elysia - Roteamento e Handler]] |
| Alterar `set.headers` depois do primeiro `yield` | `ELYSIA-CORE-06` | [[Elysia - Roteamento e Handler]] |
| `onError` devolvendo `error.message` de `UNKNOWN` | `ELYSIA-CORE-07` | [[Elysia - Roteamento e Handler]] |
| Erro de domínio sem `.error({...})` | `ELYSIA-CORE-08` | [[Elysia - Roteamento e Handler]] |
| Teste subindo servidor e requisitando por rede | `ELYSIA-CORE-09` | [[Elysia - Roteamento e Handler]] |
| Asserção antes de `await app.modules` | `ELYSIA-CORE-10` | [[Elysia - Roteamento e Handler]] |

