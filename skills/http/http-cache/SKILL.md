---
name: http-cache
description: Decidir a política de cache HTTP de um recurso e implementar requisição condicional — `Cache-Control` diretiva a diretiva, `ETag`, `304`, `If-Match` para escrita concorrente, `Vary` — citando IDs `HTTP-CACHE-*`, com sondas `curl` que provam se a condicional é tratada — use quando a tarefa for definir frescor de uma rota, ligar `ETag` e responder `304`, proteger escrita concorrente contra sobrescrita, decidir entre `no-store` e `no-cache`, versionar asset, ou entender por que um cache serviu resposta errada. Não use para desenhar método e status, que é http-contract, para requisição bloqueada pelo browser, que é http-diagnose, nem para o cache do TanStack Query, que é outra camada.
tags:
  - skill
  - http
  - backend
fonte: "[[HTTP - Cache e Requisições Condicionais]]"
---

# http-cache

> **Fonte desta skill:** [[HTTP - Cache e Requisições Condicionais]], com o hub [[HTTP]] como roteador.
> Esta skill **não contém** o texto das regras — ela diz o que decidir e o que provar com `curl`.

Contrato que esta skill implementa: [[HTTP]] § 7 ("Contrato de skill").

---

## Quando usar

A pergunta é **por quanto tempo**, **quem pode guardar**, ou **como revalidar** — ou uma escrita concorrente sobrescreveu a de outra pessoa.

| Situação | Vá para |
| --- | --- |
| qual método, qual status, `Location` | [[http-contract]] |
| requisição bloqueada, CORS, formato errado | [[http-diagnose]] |
| auditar a API inteira | [[http-review]] |
| `staleTime`/`gcTime` do cliente | [[tanstack-query]] — **outra camada**, ver Passo 5 |

---

## Carregamento mínimo

| Ordem | Carregar | Por quê |
| --- | --- | --- |
| 1 | [[HTTP]] § 5.3 | a árvore de frescor — o núcleo desta skill |
| 2 | [[HTTP]] § 6 + § 6.2 | regras e, **obrigatório**, a nota sobre `Vary` e `ETag` forte |
| 3 | [[HTTP - Cache e Requisições Condicionais]] | a fonte |
| 4 | [[HTTP]] § 8.3 | a fronteira com o cache do TanStack Query |

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/frescor-e-etag.md` | a árvore de frescor, `ETag`, e o `304` |
| `references/escrita-e-vary.md` | `If-Match`/`412`, e as obrigações de `Vary` |
| `references/fronteira-com-o-query.md` | por que a confusão com o cache do cliente é estrutural |
| `references/autoverificacao.md` | os 12 itens, e as sondas que provam |
| `references/antipadroes.md` | a grade com ID |
| `references/mapa-de-ids.md` | os 74 `HTTP-*` por satélite e seção |
| `references/exemplo.md` | caso trabalhado |
| `scripts/sondas-cache.sh` | prova se a condicional é tratada e se a escrita concorrente é barrada |

> **A nota de § 6.2 que esta skill mais usa:** as três regras de `Vary` **não são apelidos**. `HTTP-CORE-04` é o enunciado geral; `HTTP-CACHE-10` acrescenta a consequência de cache; `HTTP-NEG-01` a de compressão; `HTTP-CORS-03` a de origem dinâmica.

---

## Passo 1 — A árvore de frescor

`references/frescor-e-etag.md`. Toda resposta `GET` declara `Cache-Control` (`HTTP-CACHE-01`) — sem ele, a política é do cache intermediário, não sua. Resposta de usuário autenticado é `private` ou `no-store` (`HTTP-CACHE-02`).

**`no-store` não é "revalidar sempre"** (`HTTP-CACHE-03`) — isso é `no-cache`.

---

## Passo 2 — `ETag` e o `304`

Emitir `ETag` não basta: a rota precisa **tratar** `If-None-Match` e devolver `304` sem corpo (`HTTP-CACHE-07`, `HTTP-CACHE-06`). ETag emitido e ignorado é decorativo — e a sonda 2 do script prova isso em um comando.

---

## Passo 3 — Escrita concorrente

`If-Match` com **ETag forte** (`HTTP-CACHE-09`) e `412` quando não casa (`HTTP-CACHE-08`). É a regra mais grave desta skill: sem ela, **duas edições simultâneas apagam uma à outra em silêncio**.

---

## Passo 4 — `Vary`

Liste os headers que **mudam o corpo** (`HTTP-CACHE-10`), e **nunca** use `Vary` com `Cookie`/`User-Agent` para proteger dado (`HTTP-CACHE-11`) — isso não é controle de acesso.

---

## Passo 5 — A fronteira com o TanStack Query

São **camadas empilhadas com donos diferentes**: o cache HTTP é decidido pelo **servidor**, por header; o do Query, pelo **cliente**, por `staleTime`. Um `staleTime` alto não impede o browser de servir resposta cacheada; um `no-store` não impede o Query de devolver o que já tem. Detalhe: `references/fronteira-com-o-query.md`.

---

## Passo 6 — Autoverificar antes de entregar

```bash
bash ~/.claude/skills/http-cache/scripts/sondas-cache.sh https://api.local/faturas/42
```

As duas sondas que mais falham são as que **não dão erro** quando não implementadas: a condicional devolve `200` com o corpo inteiro, e a escrita concorrente aplica a mudança.

---

## Passo 7 — Fechar

1. **Rode as sondas.** Política declarada e política implementada são coisas diferentes.
2. **Se a decisão virou "qual status devolver"**, é [[http-contract]].
3. **Se o cache serviu resposta de outra origem**, o achado é `Vary` — e pode ser CORS ([[http-diagnose]]).
4. **Declare o que não verificou.**

---

## Exemplo

Recurso de fatura: `private, max-age=0, must-revalidate` com `ETag` forte, `304` tratado, e `If-Match` obrigatório na escrita. A sonda mostra que o `PUT` com `If-Match` obsoleto **aplicava** a escrita — perda silenciosa sob concorrência, e o achado mais grave da revisão.

Caso completo: `references/exemplo.md`.

---

## Relacionados

- [[HTTP - Cache e Requisições Condicionais]] — fonte desta skill
- [[HTTP]] § 5.3, § 6, § 7, § 8.3
- [[http-contract]] · [[http-diagnose]] · [[http-review]] — as skills irmãs
- [[tanstack-query]] — a outra camada de cache
