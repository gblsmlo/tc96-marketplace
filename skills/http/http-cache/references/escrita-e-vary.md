# Escrita concorrente e Vary

Este passo é o menos conhecido e o que evita perda de dado silenciosa.

```
Mais de um cliente pode editar este recurso?
├── NÃO → nada a fazer
└── SIM → a rota de escrita MUST aceitar If-Match e responder 412
 quando o ETag não corresponde (HTTP-CACHE-08)
```

```
PUT /faturas/42 If-Match: "v7"
├── ETag atual é "v7" → 200, aplica
└── ETag atual é "v9" → 412 Precondition Failed
 (outra pessoa editou; o cliente relê e decide)
```

Sem isso, o padrão é **last-write-wins**: quem salvou depois apaga a alteração de quem salvou antes, e ninguém é avisado.

**O `ETag` usado em `If-Match` precisa ser forte** — sem o prefixo `W/` (`HTTP-CACHE-09`). Um `ETag` fraco declara equivalência semântica, não identidade de bytes, e não serve para decidir se houve escrita concorrente.

> **Ponte com o cliente:** o `412` é um **erro esperado**, não uma exceção — ele é estado da UI ("alguém editou; recarregar?"), não caso para Error Boundary. Ver `REACT-ASYNC-09` em `Docs/React - Suspense e Assincronia.md` e o update otimista de `Docs/TanStack Query - Mutations e Invalidação.md`, que precisa de rollback quando o `412` chega.

---

## Passo 4 — `Vary`

**Resposta cujo corpo depende de um header do request declara esse header em `Vary`** (`HTTP-CACHE-10`). Sem isso, o cache compartilhado serve a representação errada para outro cliente — e o sintoma é "funciona pra mim, quebra pro colega".

Os casos que aparecem no stack:

| O corpo varia por… | `Vary` | Regra específica |
| --- | --- | --- |
| `Accept` | `Vary: Accept` | `HTTP-CORE-04` |
| `Accept-Encoding` (resposta comprimida) | `Vary: Accept-Encoding` | `HTTP-NEG-01` |
| `Accept-Language` | `Vary: Accept-Language` | `HTTP-CORE-04` |
| `Origin` (CORS com origem dinâmica) | `Vary: Origin` — **inclusive quando a origem é recusada** | `HTTP-CORS-03` |

**E o que `Vary` não resolve:** `Vary: Cookie` ou `Vary: User-Agent` para proteger conteúdo personalizado **não funciona** — a cardinalidade é alta demais e o cache fica inútil ou vaza. O mecanismo correto é `private` (`HTTP-CACHE-11`).

---

