---
name: http-contract
description: Desenhar ou alterar o contrato HTTP de um endpoint — método, status, `Location`, idempotência, corpo de erro — citando IDs `HTTP-*`, com conferência executável por `curl` antes de entregar — use quando a tarefa for criar rota nova, escolher entre `PUT` e `PATCH`, decidir qual status devolver, projetar redirecionamento, tornar uma escrita segura para retry, ou padronizar o corpo de erro de uma API. Não use para política de cache e requisição condicional, que é http-cache, para requisição bloqueada pelo browser, que é http-diagnose, nem para auditar uma API inteira, que é http-review.
tags:
  - skill
  - http
  - backend
fonte: "[[HTTP - Métodos e Semântica]]"
---

# http-contract

> **Fonte desta skill:** [[HTTP - Métodos e Semântica]] e [[HTTP - Status e Redirecionamento]], com o hub [[HTTP]] como roteador. As 74 regras `HTTP-*` são declaradas na § 6 do hub.
> Esta skill **não contém** o texto das regras — ela diz o que decidir, em que ordem, e o que conferir com `curl` antes de entregar.

Contrato que esta skill implementa: [[HTTP]] § 7 ("Contrato de skill").

---

## Quando usar

Há um endpoint a desenhar ou alterar, e as perguntas são **qual método**, **qual status**, **o que volta no corpo**.

| Situação | Vá para |
| --- | --- |
| `Cache-Control`, `ETag`, `304`, `If-Match`, `Vary` | [[http-cache]] |
| requisição bloqueada, CORS, formato errado | [[http-diagnose]] |
| auditar o contrato de uma API existente | [[http-review]] |
| escrever o handler no framework | [[elysia-build]] · [[Hono - Roteamento e Contexto]] |
| validar o corpo em runtime | [[elysia-schema]] · [[Hono - Validação e RPC]] |
| autenticação, sessão, token | [[OWASP - Sessão e Autorização]] · [[RFC 9700 - OAuth 2.0 Security BCP]] |

---

## Carregamento mínimo

| Ordem | Carregar | Por quê |
| --- | --- | --- |
| 1 | [[HTTP]] § 2 | o modelo mental do protocolo |
| 2 | [[HTTP]] § 5.1 e § 5.2 | as duas árvores desta skill |
| 3 | [[HTTP]] § 6 + § 6.1 + § 6.2 | regras, críticas, e os IDs canônicos |
| 4 | [[HTTP - Métodos e Semântica]] · [[HTTP - Status e Redirecionamento]] | as duas fontes, inseparáveis |
| 5 | [[HTTP]] § 8 | **antes de escrever header à mão** — o stack pode já fazer |

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/metodo-e-status.md` | as duas árvores, com o que cada ramo decide |
| `references/idempotencia-e-erro.md` | retry seguro, chave de idempotência, corpo de erro, header à mão |
| `references/autoverificacao.md` | os 15 itens, e os três `curl` que valem mais |
| `references/antipadroes.md` | a grade com ID |
| `references/mapa-de-ids.md` | os 74 `HTTP-*` por satélite e seção, e a nota sobre `Vary` |
| `references/exemplo.md` | caso trabalhado |
| `scripts/conferir.sh` | roda os `curl` do Passo 6 e lista o que exige leitura |

**A nota de § 6.2 que mais importa aqui:** as três regras de `Vary` **não são apelidos** — cada uma acrescenta uma obrigação concreta. Cite a específica quando o contexto for específico.

---

## Passo 1 — Qual método

`references/metodo-e-status.md`. O corte que decide quase tudo: **método safe não escreve estado** (`HTTP-CORE-02`, `HTTP-METH-01`), e `PUT` substitui a representação **inteira** (`HTTP-METH-03`).

---

## Passo 2 — Qual status

Falha **nunca** é `2xx` (`HTTP-CORE-06`). `201` leva `Location`; `204` não tem corpo; `405` leva `Allow`; `401` leva `WWW-Authenticate`; `429`/`503` levam `Retry-After`.

---

## Passo 3 — Idempotência e retry

`POST`/`PATCH` que pode ser retentado aceita **chave de idempotência** (`HTTP-METH-09`). Sem isso, o retry do cliente cria o segundo pedido — e o cliente não tem como saber.

---

## Passo 4 — Corpo de erro

**Um formato só na API inteira** (`HTTP-SPEC-08`). Dois formatos é contrato público inconsistente, e cada rota nova amplia o problema.

---

## Passo 5 — Antes de escrever header à mão

Confira [[HTTP]] § 8: o stack pode já fazer. Header escrito à mão onde o framework já emite é fonte de divergência silenciosa.

---

## Passo 6 — Autoverificar antes de entregar

```bash
bash ~/.claude/skills/http-contract/scripts/conferir.sh https://api.local /pedidos/42 /pedidos
```

Quinze itens em `references/autoverificacao.md`. **O que vale mais:** `curl -i` na rota e ler os headers de verdade — em especial o `PATCH` numa rota que só aceita `PUT`, que pega `HTTP-METH-07` (`404` em vez de `405` com `Allow`).

---

## Passo 7 — Fechar

1. **Rode o `curl`.** Contrato é o que o servidor responde, não o que o handler parece fazer.
2. **Se a pergunta virou "por quanto tempo isso pode ser guardado"**, é [[http-cache]].
3. **Se o browser bloqueou**, é [[http-diagnose]] — e a causa é do servidor, não do cliente.
4. **Declare o que não verificou.**

---

## Exemplo

Endpoint de criação de pedido: `POST` com chave de idempotência, `201` com `Location`, erro de validação em `422` no formato único da API, e `405` com `Allow` para método não suportado. O `curl -i` mostra que a rota devolvia `404` no `PATCH` — o middleware faltando, não o handler.

Caso completo: `references/exemplo.md`.

---

## Relacionados

- [[HTTP - Métodos e Semântica]] · [[HTTP - Status e Redirecionamento]] — as fontes
- [[HTTP]] § 2, § 5, § 6, § 7, § 8
- [[http-cache]] · [[http-diagnose]] · [[http-review]] — as skills irmãs
- [[elysia-build]] — o mecanismo que implementa este contrato
