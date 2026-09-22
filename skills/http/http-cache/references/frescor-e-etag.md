# A árvore de frescor, ETag e o 304

A árvore completa é a § 5.3 do hub. O resumo operacional:

| O recurso é… | `Cache-Control` |
| --- | --- |
| dado sensível que não pode tocar disco | `no-store` |
| específico do usuário autenticado | `private, max-age=<n>` |
| público com URL versionada (hash no nome) | `public, max-age=31536000, immutable` |
| público, muda de vez em quando, servir velho é aceitável | `s-maxage=<curto>, stale-while-revalidate=<n>` |
| público, muda a cada escrita | `max-age=0, must-revalidate` + `ETag` |

**A regra de entrada:** toda resposta de `GET` declara `Cache-Control` explicitamente (`HTTP-CACHE-01`). Omitir **não desliga o cache** — entra o **frescor heurístico**, cerca de 10% do intervalo desde o `Last-Modified` (RFC 9111 § 4.2.2). É a razão nº 1 de "cacheou e eu não pedi".

### 1.1 As três confusões de diretiva

| Você quer | Diretiva certa | O erro comum |
| --- | --- | --- |
| "não guarde em lugar nenhum" | `no-store` | `no-cache` — que **armazena** |
| "guarde, mas pergunte antes de reusar" | `no-cache` | `no-store`, que joga fora e perde o `304` |
| "só o browser dele, nunca a CDN" | `private` | `public` com dado de sessão |

**`no-cache` armazena a resposta** — ele impede o reuso **sem revalidação**. Quem escreve `no-store` querendo "sempre revalidar" perde a economia do `304` inteira (`HTTP-CACHE-03`, `HTTP-CACHE-12`).

**Resposta personalizada por usuário é `private` no mínimo** (`HTTP-CACHE-02`). `public` num corpo derivado de cookie de sessão é como um cache compartilhado serve o dado de uma pessoa para outra.

**`max-age` acima de 24 h exige URL versionada** (`HTTP-CACHE-04`) — sem hash no nome, não há como corrigir antes do prazo.

---

## Passo 2 — `ETag` e o `304`

```
GET  /faturas/42            → 200 + ETag: "v7" + Cache-Control
GET  /faturas/42            → If-None-Match: "v7"
                             → 304, sem corpo, repetindo ETag/Cache-Control/Date/Vary
```

| Confira | Regra |
| --- | --- |
| resposta `200` revalidável inclui `ETag`; `Last-Modified` é fallback | `HTTP-CACHE-05` |
| a rota **trata** `If-None-Match` e responde `304` quando bate | `HTTP-CACHE-07` |
| `304` **sem corpo**, repetindo `ETag`, `Cache-Control`, `Date` e `Vary` | `HTTP-CACHE-06` |

**Emitir `ETag` sem tratar `If-None-Match` é o antipadrão mais comum aqui**: custa o header e não entrega economia nenhuma — o cliente pergunta e recebe o corpo inteiro de volta.

**O que o stack faz sozinho:** `Bun.serve` responde `304` a `If-None-Match` ao servir `Bun.file` — mas **só para arquivo**. Para resposta dinâmica, o `ETag` é seu ([[Bun - HTTP e Servidor]]). Em Hono há `hono/etag`, com `weak: false` por default ([[Hono - Middleware e Ciclo de Vida]] § 5).

---

