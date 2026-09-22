# Coerção, response e guard

> Passos 0 a 5. O texto das regras mora em [[Elysia - Schema e Eden]].

> **Uma declaração de schema produz quatro efeitos:** validação em runtime, tipo em TypeScript, documento OpenAPI, e o tipo do cliente Eden.

Isso muda a economia: um schema mal declarado não erra em um lugar — erra em quatro. E é por isso que `ELYSIA-TYPE-01` proíbe reescrever o tipo à mão: `typeof S.static` deriva do schema, e uma cópia manual divergirá.

---

## Passo 1 — Coerção depende da fonte

A regra mais consequente da família, e a menos intuitiva:

| Fonte | `t.Number` coage string? |
| --- | --- |
| `params` | **sim** |
| `query` | **sim** |
| `headers` | **sim** |
| `cookie` | **sim** |
| **`body`** | **não** |

`ELYSIA-TYPE-04`: campo numérico de `body` **nunca** conta com coerção. Um `t.Number()` no body recebendo `"100"` de um JSON malformado falha a validação — e o desenvolvedor conclui que o schema está errado.

E `ELYSIA-TYPE-03`: schema de `headers` declara os nomes em **minúsculas** — Elysia normaliza, e um nome capitalizado **nunca casa**. O sintoma é um header obrigatório que "nunca é enviado".

---

## Passo 2 — `response` por status

```ts
// ✓ mapa por status — ELYSIA-TYPE-06
response: {
  200: t.Object({ id: t.String() }),
  404: t.Object({ erro: t.String() }),
  422: t.Object({ erro: t.String() }),
}
```

Sem o mapa, **o erro chega ao Eden como `unknown`** — e o cliente perde exatamente a informação que justificava usar um cliente tipado.

E `ELYSIA-TYPE-13`: listagem paginada declara no `response` um envelope com `itens`, `total` e `hasMore`. Devolver o array cru fecha a porta para paginação sem quebrar o contrato.

---

## Passo 3 — `guard` e composição

`ELYSIA-TYPE-05`: schema de `guard` que precisa **somar-se** ao da rota declara `schema: 'standalone'`. O default é **`override`** — o schema do guard **substitui** o da rota.

```ts
// ✗ o schema da rota é substituído
.guard({ headers: t.Object({ authorization: t.String() }) })

// ✓ soma
.guard({ schema: 'standalone', headers: t.Object({ authorization: t.String() }) })
```

Sintoma de esquecer: a validação do body da rota desaparece, silenciosamente, e o handler recebe qualquer coisa.

---

## Passo 4 — Upload

`ELYSIA-TYPE-02`: upload validado por Standard Schema usa **`fileType()`** — validadores genéricos conferem o `content-type` **declarado**, que o cliente controla. `fileType()` inspeciona o conteúdo.

É achado de segurança: um `.exe` renomeado para `.png` passa por validação de `content-type` e não passa por `fileType()`.

---

## Passo 5 — OpenAPI

| Regra | O que exige |
| --- | --- |
| `ELYSIA-APP-07` | `@elysia/openapi`, **nunca** `@elysiajs/swagger` (descontinuado) |
| `ELYSIA-TYPE-07` | rota declarada com Zod/Valibot/Effect precisa de `mapJsonSchema` no plugin — **ou some da documentação** |
| `ELYSIA-TYPE-12` | `allowUnsafeValidationDetails: true` **nunca** em produção |

**`ELYSIA-TYPE-07` falha em silêncio:** a rota funciona, valida, e simplesmente não aparece no OpenAPI. Num projeto que mistura `t` e Zod, metade da documentação desaparece sem aviso.

**`ELYSIA-TYPE-12` é global e vaza contrato interno:** a opção faz a resposta de erro publicar detalhe de validação — nome de campo, formato esperado, estrutura interna.

---

