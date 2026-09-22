# Exemplo trabalhado — rota de faturas

Tarefa: *"rota de aprovação de fatura, com erro de limite e sessão assinada"*.

```ts
import { Elysia, t } from 'elysia';
import { env } from 'elysia';

class LimiteExcedido extends Error {}

const app = new Elysia({ cookie: { secrets: env.COOKIE_SECRET, sign: ['sessao'] } })
.error({ LIMITE_EXCEDIDO: LimiteExcedido }) // ELYSIA-CORE-08
.onError(({ code, error, status }) => { // registrado ANTES das rotas
 if (code === 'LIMITE_EXCEDIDO') return status(422, { erro: 'limite' });
 console.error(error); // logue o detalhe…
 return status(500, { erro: 'interno' }); // …responda genérico — ELYSIA-CORE-07
 })
.put('/faturas/:id/aprovacao', async ({ params, cookie: { sessao }, status }) => {
 const usuario = sessao.value?.id;
 if (!usuario) return status(401, { erro: 'sem sessão' }); // ELYSIA-CORE-03

 const fatura = await buscar(params.id);
 if (!fatura) return status(404, { erro: 'não encontrada' });
 if (fatura.valor > limiteDe(usuario)) throw new LimiteExcedido;

 return aprovar(fatura);
 }, {
 params: t.Object({ id: t.String }),
 response: { // mapa por status — ELYSIA-TYPE-06
 200: t.Object({ id: t.String, status: t.String }),
 401: t.Object({ erro: t.String }),
 404: t.Object({ erro: t.String }),
 422: t.Object({ erro: t.String }),
 },
 });

export type App = typeof app; // ELYSIA-APP-05
```

**O que as decisões evitaram:**

| Decisão | Alternativa que dói | Regra |
| --- | --- | --- |
| `return status(401, …)` para sem-sessão | `throw`, e o Eden não sabe que 401 existe | `ELYSIA-CORE-03` |
| `.error({ LIMITE_EXCEDIDO })` | `if (e.message === 'limite')` no `onError`, sem narrowing | `ELYSIA-CORE-08` |
| `console.error` + resposta genérica | devolver `error.message`, vazando query e caminho | `ELYSIA-CORE-07` |
| `onError` antes das rotas | registrado depois, e não afeta nenhuma | `ELYSIA-CORE-01` |
| `response` como mapa por status | erro chegando ao Eden como `unknown` | `ELYSIA-TYPE-06` |
| encadeamento contínuo até o `export type` | tipo parando de acumular, e o Eden perdendo rotas | `ELYSIA-APP-01`, `ELYSIA-APP-05` |
| `env` de `elysia` | `process.env` cru | `ELYSIA-APP-09` |
| cookie assinado no construtor | cookie de sessão forjável | `ELYSIA-CORE-05` |

Note que o `throw` **é** usado — para `LimiteExcedido`, que é registrado em `.error` e mapeado no `onError` para `422`. A regra não proíbe `throw`; ela exige que o erro **esperado que precisa chegar tipado** use `return status(...)`.

---

