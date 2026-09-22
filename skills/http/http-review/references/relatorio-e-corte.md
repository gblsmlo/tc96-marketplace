# Formato do achado, e o corte

Quatro partes, o mesmo contrato de [[playwright-review]], [[bun-test-review]] e [[react-review]]:

```
`ID-DA-REGRA` — arquivo:linha
<o que está errado, uma frase>
Correção: <mudança concreta>
Ver [[Satélite correspondente]].
```

Para sonda, **a evidência é a saída do comando** — cole os headers.

### Exemplo

```
`HTTP-CACHE-08` — apps/server/src/features/faturas/rotas.ts:88
A rota PUT /faturas/:id não aceita If-Match e aplica a escrita sempre; duas edições
concorrentes se sobrescrevem sem aviso.
Evidência: S5 — `curl -i -X PUT -H 'If-Match: "obsoleto"'` devolveu 200, não 412.
Correção: comparar o If-Match com o ETag atual e responder 412 quando divergir;
  o ETag precisa ser forte, sem W/ (HTTP-CACHE-09). O cliente trata o 412 como
  estado da UI, não como exceção.
Ver [[HTTP - Cache e Requisições Condicionais]].
```

```
`HTTP-CORE-06` — apps/server/src/features/pedidos/rotas.ts:41
Erro de domínio devolvido como 200 com {ok: false}; o hc do Hono não lança em status
de erro, então a query do cliente fica em success com o erro dentro de data —
isError é false, o retry não roda, o Error Boundary não pega.
Correção: 422 para regra de negócio reprovada (HTTP-STATUS-11), com problem+json.
Ver [[HTTP]] § 6, e [[Hono - Validação e RPC]] para o lado do cliente.
```

Regras do formato: **ID conferido na § 6**, e **nunca apelido** (§ 6.2); localização sempre; correção concreta — se outra rota do serviço já faz certo, aponte-a; um link de satélite.

---

## Passo 5 — O corte: achado × opinião

**Achado sem ID é opinião**, com três saídas:

1. **Existe ID** → achado, cite o ID.
2. **Não existe ID, mas há nota normativa** → cite a nota: [[Status HTTP e contrato da API]], [[OWASP - Sessão e Autorização]], [[Idempotência torna retries seguros]]. Não invente `HTTP-*`.
3. **Nem uma coisa nem outra** → seção separada "Sugestões (sem regra)".

Quatro casos que **não** são achado:

- **Estilo de URL.** `/faturas/42/aprovacao` × `/faturas/42:aprovar` não tem ID. É convenção, e vira achado só se violar semântica de método.
- **Verbosidade do corpo de resposta.** Não há regra sobre quanto devolver — há sobre ter **um** formato de erro (`HTTP-SPEC-08`).
- **Ausência de cache.** `Cache-Control: no-store` numa rota que poderia cachear é decisão, não violação — o que **é** violação é a **ausência** do header (`HTTP-CACHE-01`).
- **O framework não fazer sozinho.** "Bun.serve não faz CORS" não é achado contra o time; o achado é a rota sem CORS onde ela precisa.

E um **inválido**: citar `HTTP-STATUS-01`. É apelido de `HTTP-CORE-06` (§ 6.2).

Se a varredura encontrar defeito real e recorrente sem regra, o produto é uma **proposta de regra** para [[HTTP]] § 6 — ID sugerido, texto, e o caso que a motivou.

---

