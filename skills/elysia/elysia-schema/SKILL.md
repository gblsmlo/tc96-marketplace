---
name: elysia-schema
description: Declarar schema em Elysia e consumir a API pelo Eden — `t`/TypeBox, coerção por fonte, `response` por status, `guard` standalone, OpenAPI, e a ponte com TanStack Query — citando IDs `ELYSIA-TYPE-*`, com autoverificação executável — use quando a tarefa for validar body, query, params, headers ou upload, tipar o retorno de uma rota, montar cliente Eden, paginar listagem, gerar documentação OpenAPI, ou consertar `data` que vem `null` no cliente. Não use para escrever a rota e o handler, que é elysia-build, para plugin que não afeta rota, que é elysia-diagnose, nem para o cache do cliente, que é tanstack-query.
tags:
  - skill
  - elysia
  - backend
fonte: "[[Elysia - Schema e Eden]]"
---

# elysia-schema

> **Fonte desta skill:** [[Elysia - Schema e Eden]], com o hub [[Elysia]] como roteador.
> Esta skill **não contém** o texto das regras — ela diz o que decidir, em que ordem, e o que conferir antes de entregar.

Contrato que esta skill implementa: [[Elysia]] § 7 ("Contrato de skill").

---

## Quando usar

Declarar schema, tipar retorno, ou consumir a API pelo Eden.

| Situação | Vá para |
| --- | --- |
| a rota e o handler em si | [[elysia-build]] |
| hook ou plugin que não afeta a rota | [[elysia-diagnose]] |
| política de frescor do cache do cliente | [[tanstack-query]] |
| política de cache **HTTP** (`ETag`, `Cache-Control`) | [[http-cache]] |
| qual status devolver, e o corpo de erro padrão | [[http-contract]] |

---

## Carregamento mínimo

| Ordem | Carregar | Por quê |
| --- | --- | --- |
| 1 | [[Elysia]] § 2 | **uma declaração de schema produz quatro efeitos** |
| 2 | [[Elysia]] § 6 + § 6.1 + § 6.2 | regras, críticas e IDs canônicos |
| 3 | [[Elysia - Schema e Eden]] | a fonte |
| 4 | [[Elysia]] § 5 | as árvores, quando houver dúvida |

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/coercao-response-e-guard.md` | coerção por fonte, `response` por status, `guard`, upload, OpenAPI |
| `references/eden.md` | as três armadilhas do Eden, e por que as três compilam |
| `references/autoverificacao.md` | os 14 itens, e o teste que prova `ELYSIA-TYPE-09` |
| `references/antipadroes.md` | 16 antipadrões com ID |
| `references/mapa-de-ids.md` | os 44 `ELYSIA-*`: declaração, satélite do corpo e seção |
| `references/exemplo-listagem-paginada.md` | caso trabalhado, do schema ao `queryFn` |
| `scripts/autoverificar.sh` | roda os itens mecânicos e lista os que exigem leitura |

---

## Passo 0 — O modelo mental

> **Uma declaração de schema produz quatro efeitos:** validação em runtime, tipo em TypeScript, documento OpenAPI, e o tipo do cliente Eden.

Isso muda a economia: um schema mal declarado não erra em um lugar — **erra em quatro**. E é por isso que `ELYSIA-TYPE-01` proíbe reescrever o tipo à mão.

---

## Passo 1 — Coerção depende da fonte

`params`, `query`, `headers` e `cookie` **coagem**; **`body` não** (`ELYSIA-TYPE-04`). Um `t.Number()` no body recebendo `"100"` falha a validação, e o desenvolvedor conclui que o schema está errado.

E `ELYSIA-TYPE-03`: nomes de header em **minúsculas** — um nome capitalizado **nunca casa**, e o sintoma é um header obrigatório que "nunca é enviado".

---

## Passo 2 — `response` por status

Sem o mapa por status, **o erro chega ao Eden como `unknown`** (`ELYSIA-TYPE-06`) — o cliente perde exatamente a informação que justificava usar um cliente tipado. Listagem paginada declara **envelope**, não array cru (`ELYSIA-TYPE-13`).

---

## Passo 3 — `guard` e composição

O default é **`override`**: o schema do guard **substitui** o da rota. Para somar, `schema: 'standalone'` (`ELYSIA-TYPE-05`). Sintoma de esquecer: a validação do body da rota **desaparece em silêncio**.

---

## Passo 4 — Upload e OpenAPI

Upload usa **`fileType()`** (`ELYSIA-TYPE-02`) — validador genérico confere o `content-type` **declarado**, que o cliente controla. É achado de segurança.

Rota com Zod/Valibot/Effect precisa de `mapJsonSchema` **ou some da documentação** (`ELYSIA-TYPE-07`) — falha em silêncio. E `allowUnsafeValidationDetails: true` **nunca** em produção (`ELYSIA-TYPE-12`).

---

## Passo 5 — O Eden, e as três armadilhas

`references/eden.md`. Nenhuma quebra o build:

1. **`data` é `null` em qualquer status ≥ 300** — cheque `error` antes (`ELYSIA-TYPE-08`).
2. **O Eden não lança.** `queryFn`/`mutationFn` precisa lançar, ou usar `throwHttpError: true` (`ELYSIA-TYPE-09`). Sem isso a query fica em **`success`** com o erro dentro de `data`: `isError` falso, sem retry, sem Error Boundary. **É o bug mais caro da ponte.**
3. **`parseDate: true` quebra structural sharing** do Query e re-renderiza a lista inteira (`ELYSIA-TYPE-10`).

---

## Passo 6 — Autoverificar antes de entregar

```bash
bash ~/.claude/skills/elysia-schema/scripts/autoverificar.sh src
tsc --noEmit    # nos DOIS pacotes — a única verificação de contrato do Eden
```

E **force um erro**: a query tem de ficar em `isError`, não em `success`.

---

## Passo 7 — Fechar

1. **`tsc --noEmit` nos dois pacotes.**
2. **Se a rota some do OpenAPI**, é `mapJsonSchema` (`ELYSIA-TYPE-07`), não bug do plugin.
3. **Se há re-render inexplicável na lista**, é `parseDate` (`ELYSIA-TYPE-10`).
4. **Três camadas de cache, três donos:** o do cliente é [[tanstack-query]], o HTTP é [[http-cache]], e esta skill só entrega o dado tipado.
5. **Declare o que não verificou.** Contrato sob versão divergente de `elysia` só aparece quando alguém atualiza um lado (`ELYSIA-TYPE-11`).

---

## Exemplo

Listagem paginada de faturas consumida pelo front: o `response` é mapa por status, a listagem devolve **envelope** com `itens`/`total`/`hasMore`, o cliente Eden usa `parseDate: false`, e o `queryFn` **lança** quando `error` vem preenchido — sem isso a tela renderiza sucesso com dado nulo.

Caso completo: `references/exemplo-listagem-paginada.md`.

---

## Relacionados

- [[Elysia - Schema e Eden]] — fonte desta skill
- [[Elysia]] § 2, § 6, § 7
- [[elysia-build]] · [[elysia-diagnose]] — as skills irmãs
- [[tanstack-query]] — o cache do outro lado da ponte
- [[Zod - Validação de Ambiente]] — quando o schema é Zod
