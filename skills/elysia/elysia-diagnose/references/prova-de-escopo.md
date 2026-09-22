# A prova de escopo — o teste que ELYSIA-LIFE-08 exige

```bash
# a rota passa pelo hook? instrumente temporariamente e conte
# (e prefira função nomeada, para o span não virar anonymous)
```

```ts
// prova de escopo — o teste que ELYSIA-LIFE-08 exige
import { describe, test, expect } from 'bun:test';
import { Elysia } from 'elysia';
import { authPlugin } from './auth';

test('plugin protege rota da instância CONSUMIDORA', async => {
 const consumidor = new Elysia.use(authPlugin).get('/privado', => 'ok');
 await consumidor.modules; // ELYSIA-CORE-10
 const res = await consumidor.handle(new Request('http://x/privado'));
 expect(res.status).toBe(401); // se der 200, o escopo é local
});
```

Esse teste é a sonda mais valiosa desta skill: ele distingue `local` de `scoped` em uma asserção, e é o único jeito de provar `ELYSIA-LIFE-01` sem ler o código do plugin.

---


---

## Por que este teste, e não a leitura do plugin

`local` e `scoped` **produzem o mesmo código** dentro do plugin: a diferença só aparece na
instância que o consome. Um teste escrito **dentro** do plugin passa nos dois casos — e é
exatamente o teste que a maioria dos projetos tem.

| Onde o teste roda | Escopo `local` | Escopo `scoped` |
| --- | --- | --- |
| dentro do plugin | rejeita ✓ | rejeita ✓ |
| **na instância consumidora** | **passa (200)** ✗ | rejeita (401) ✓ |

A linha de baixo é a única que distingue os dois — e é a que `ELYSIA-LIFE-08` exige.

## O corte: o que não é lifecycle
| Sintoma | Não é lifecycle — é |
| --- | --- |
| erro chega ao Eden como `unknown` | `response` sem mapa por status — `elysia-schema` (`ELYSIA-TYPE-06`) |
| `data` do Eden é `null` | status ≥ 300 — `ELYSIA-TYPE-08` |
| tipo do Eden perdeu rotas | method chaining quebrado — `ELYSIA-APP-01` |
| header obrigatório "nunca chega" | nome capitalizado no schema — `ELYSIA-TYPE-03` |
| body numérico falha a validação | `body` não coage — `ELYSIA-TYPE-04` |
| teste flaky com plugin assíncrono | falta `await app.modules` — `ELYSIA-CORE-10` |
| SSE cai sozinho | `idleTimeout` do `Bun.serve` — [Bun - HTTP e Servidor](../../../../knowledge-base/docs/bun-http-e-servidor.md) |

**E o mais comum de todos:** o hook não roda porque foi registrado **depois** da rota (`ELYSIA-CORE-01`). Antes de investigar escopo, confira a ordem.

---
