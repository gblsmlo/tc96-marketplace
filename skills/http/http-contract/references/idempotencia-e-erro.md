# Idempotência, corpo de erro e headers

Decisão de desenho, não detalhe de implementação.

```
O cliente pode reenviar esta requisição sem intenção?
(retry automático, botão clicado duas vezes, timeout de rede)
├── é GET/HEAD/PUT/DELETE → já é idempotente por semântica (HTTP-METH-04)
└── é POST ou PATCH
    ├── criar duplicata é aceitável?  → nada a fazer
    └── criar duplicata é defeito
        → aceitar chave de idempotência no request (HTTP-METH-09)
          e o cliente NÃO configura retry sem ela (HTTP-METH-08)
```

**`HTTP-METH-08` é sobre o cliente e é frequentemente violada por configuração**, não por código: um retry global no cliente HTTP transforma todo `POST` em risco de duplicata. Ver [[Idempotência torna retries seguros]].

---

## Passo 4 — Corpo de erro

**Uma API tem um formato só, declarado no contrato** (`HTTP-SPEC-08`). O padrão citável é `application/problem+json` — e ele é **RFC 9457**, não 7807, que foi obsoletada em 2023 (`HTTP-SPEC-02`).

E o que **não** vai no erro: dado sensível nunca em query string (`HTTP-CORE-07`), e o status nunca é `2xx` (`HTTP-CORE-06`).

---

## Passo 5 — Antes de escrever header à mão

A § 8 do hub existe para este passo, e ela muda o trabalho:

| Onde o handler roda | O que **você** precisa escrever |
| --- | --- |
| `Bun.serve` cru | **tudo** — CORS, `Cache-Control`, `ETag` dinâmico, mapeamento de erro para status, `405` com `Allow` |
| Hono | há built-in para CORS, `etag`, `compress`, `bodyLimit`, e **`methodNotAllowed`** |
| Elysia | `@elysia/cors`, e o schema produz validação + tipo + OpenAPI + cliente |

**A armadilha do Hono que é violação silenciosa de `HTTP-METH-07`:** sem o middleware `methodNotAllowed`, método não suportado numa rota existente devolve **`404`**, não `405` com `Allow`. Ver [[Hono - Middleware e Ciclo de Vida]] § 5.

---

