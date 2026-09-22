# Erro, cookie, stream e teste

> Passos 3 a 5.

---

## Erro — a decisão mais consequente da skill

```
O erro é ESPERADO (validação, 404 de negócio, limite)?
├── SIM → return status(código, corpo)          ELYSIA-CORE-03
│         (o tipo chega tipado ao Eden)
└── NÃO — é inesperado
    └── throw → cai no onError
        └── e onError NUNCA devolve error.message de UNKNOWN
                                                  ELYSIA-CORE-07
```

| Regra | O que exige |
| --- | --- |
| `ELYSIA-CORE-03` | erro esperado é `return status(...)`, **não `throw`**, quando o tipo precisa chegar ao Eden |
| `ELYSIA-CORE-04` | `status(code, valor)` no lugar de `set.status` sempre que a rota declarar schema de `response` |
| `ELYSIA-CORE-07` | `onError` **nunca** devolve `error.message` de um erro `UNKNOWN` |
| `ELYSIA-CORE-08` | erro de domínio recorrente é registrado em `.error({...})`, para ter `code` próprio e narrowing |

**Por que `throw` perde o tipo:** o `throw` sai pelo `onError`, que é um caminho **fora do
tipo da rota** — então o Eden não sabe que aquele status existe. `return status(...)` entra
no tipo. É o mesmo princípio que `ELYSIA-LIFE-10` aplica dentro de `macro`.

**`ELYSIA-CORE-07` é achado de segurança**, não de estilo: `error.message` de erro
desconhecido vaza caminho de arquivo, query e nome de tabela.

---

## Cookie e stream

Cookie de sessão é **assinado e `httpOnly`** (`ELYSIA-CORE-05`):

```ts
new Elysia({ cookie: { secrets: env.COOKIE_SECRET, sign: ['sessao'] } })
  .get('/eu', ({ cookie: { sessao } }) => {
    sessao.value = { id };
    sessao.httpOnly = true;
    sessao.secure = true;
    sessao.sameSite = 'lax';
  });
```

A semântica de `SameSite`, `Domain` e dos prefixos é de [[RFC 6265 - Cookies HTTP]] —
Elysia é o mecanismo, não o critério.

**Stream:** `ELYSIA-CORE-06` — `set.headers` **nunca** é alterado depois do primeiro `yield`
de um handler generator. A alteração é **silenciosamente ignorada**.

> **A armadilha que vem do runtime, não do framework:** o `idleTimeout` de 10 s do
> `Bun.serve` **conta durante a resposta**, não só antes — é a causa de SSE que cai sozinho.
> Ver [[Bun - HTTP e Servidor]].

---

## Teste

| Regra | O que exige |
| --- | --- |
| `ELYSIA-CORE-09` | teste de rota usa `app.fetch`/`app.handle` — **nunca** subir servidor e requisitar por rede |
| `ELYSIA-CORE-10` | app com plugin assíncrono ou `import()` lazy **aguarda `app.modules`** antes das asserções |

```ts
test('cria fatura', async () => {
  await app.modules;                       // ELYSIA-CORE-10
  const res = await app.handle(new Request('http://localhost/faturas', {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ valor: 100 }),
  }));
  expect(res.status).toBe(201);
});
```

**`ELYSIA-CORE-10` produz flake clássico:** sem `await app.modules`, o teste roda antes de o
plugin registrar a rota, e o resultado depende de timing. Ver [[bun-test-build]].

---

## Relacionados

- [[Elysia - Roteamento e Handler]] · [[Elysia]] § 5 — a árvore de erro
- [[http-contract]] — qual status devolver é decisão de protocolo, não de framework
