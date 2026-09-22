---
nome: http-diagnose
descricao: Diagnosticar requisição bloqueada pelo browser ou discordância de formato entre cliente e servidor — o modelo de falha de CORS, preflight, headers legíveis, `415` × `406`, charset — citando IDs `HTTP-CORS-*` e `HTTP-NEG-*`, com cinco sondas `curl` executáveis — use quando a tarefa for investigar erro de CORS no console, preflight que falha, header que chega `undefined` no JavaScript, requisição que funciona no curl e falha no browser, acento quebrado, ou corpo no formato errado. Não use para desenhar método e status, que é http-contract, para política de frescor, que é http-cache, nem para auditar a API inteira, que é http-review.
tipo: skill
familia: http
fonte: "[HTTP - CORS](../../../knowledge-base/docs/http-cors.md)"
tags:
  - skill
  - http
  - backend
---

# http-diagnose

> **Fonte desta skill:** [HTTP - CORS](../../../knowledge-base/docs/http-cors.md) e [HTTP - Negociação de Conteúdo e Range](../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md), com o hub [HTTP](../../../knowledge-base/docs/http.md) como roteador.
> Esta skill **não contém** o texto das regras — ela diz o que sondar, em que ordem eliminar hipóteses, e o que **não** é CORS.

Contrato que esta skill implementa: [HTTP](../../../knowledge-base/docs/http.md) § 7 ("Contrato de skill").

---

## Quando usar

Uma requisição não chega, ou chega e o formato está errado.

| Situação | Vá para |
| --- | --- |
| desenhar método e status | `http-contract` |
| política de frescor, `ETag`, condicional | `http-cache` |
| auditar a API inteira | `http-review` |
| o plugin `cors` do Elysia com default permissivo | `elysia-diagnose` (`ELYSIA-LIFE-12`) — é o mesmo achado por outro caminho |

---

## Carregamento mínimo

| Ordem | Carregar | Por quê |
| --- | --- | --- |
| 1 | [HTTP](../../../knowledge-base/docs/http.md) § 5.4 e § 5.5 | as duas árvores desta skill |
| 2 | [HTTP](../../../knowledge-base/docs/http.md) § 6 + § 6.2 | regras e IDs canônicos |
| 3 | [HTTP - CORS](../../../knowledge-base/docs/http-cors.md) | a fonte |
| 4 | [HTTP - Negociação de Conteúdo e Range](../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) | quando o sintoma é formato, não bloqueio |

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/modelo-de-falha.md` | "é CORS mesmo?" e o modelo de falha, ramo a ramo |
| `references/formato-e-encoding.md` | `415` × `406`, idioma, charset |
| `references/sondas.md` | as cinco sondas, e como ler cada resultado |
| `references/relatorio-e-corte.md` | formato do achado, e o que **não** é CORS |
| `references/antipadroes.md` | a grade com ID |
| `references/mapa-de-ids.md` | os 74 `HTTP-*` por satélite e seção |
| `scripts/sondas-cors.sh` | roda as cinco e imprime a leitura de cada uma |

---

## Passo 0 — Duas coisas que economizam a sessão inteira

1. **CORS é decisão do servidor.** Mexer no cliente nunca é a correção.
2. **`curl` não faz CORS** — e é por isso que ele serve: mostra o que o servidor responde, **sem o browser no meio**.

---

## Passo 1 — É CORS mesmo?

`references/modelo-de-falha.md`. Metade dos "erros de CORS" é o servidor não respondendo: a mensagem do browser é a mesma.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/http-diagnose/scripts/sondas-cors.sh https://api.local/faturas http://localhost:5173
```

**A sonda 2 é a que mais rende:** se o preflight devolve `401`, `404` ou `405`, o problema é o **preflight**, não a chamada real — e o handler está correto.

---

## Passo 2 — O modelo de falha, ramo a ramo

Origem não permitida · preflight não tratado · header de request não listado · header de resposta não exposto · credencial com `origin: '*'` · `Vary: Origin` ausente.

**`origin: '*'` com `credentials: true` é inválido** e o browser recusa (`HTTP-CORS-02`) — é o mesmo achado que `ELYSIA-LIFE-12` pelo lado do framework.

**A sonda 4 é a que quase ninguém roda:** com a origem **recusada**, ainda há `Vary: Origin`? Sem ele, o cache serve a resposta de uma origem para outra (`HTTP-CORS-03`).

---

## Passo 3 — Formato, idioma, encoding

`references/formato-e-encoding.md`. `415` é sobre o que **entra**; `406` sobre o que **sai** — trocar os dois é o erro mais comum. E `text/*` sem `charset` é acento quebrado esperando acontecer (`HTTP-CORE-03`).

---

## Passo 4 — Reportar

```
`ID-DA-REGRA` — <onde>
Sintoma: <a mensagem do browser, e o que o usuário vê>
Evidência: <a saída da sonda, com o header>
Causa: <uma frase>
Correção: <no servidor>
Ver Satélite correspondente.
```

**Evidência é a saída do `curl`**, com o header colado. "Parece CORS" não é evidência.

---

## Passo 5 — O corte: o que não é CORS

Erro que o `curl` também reproduz, `401` legítimo, header que o servidor nunca enviou, mixed content, e cookie que não vai por `SameSite` — **nenhum é CORS**, e tratar como tal leva a afrouxar a política sem resolver. Tabela em `references/relatorio-e-corte.md`.

---

## Passo 6 — Fechar

1. **A correção é no servidor.** Se a proposta mexe no cliente, ela está errada.
2. **Se a origem é ecoada sem lista**, o achado é de **segurança** (`HTTP-CORS-01`), não de configuração.
3. **Se o preflight é a causa**, confira também o cache dele (`Access-Control-Max-Age`).
4. **Declare o que não verificou.**

---

## Relacionados

- [HTTP - CORS](../../../knowledge-base/docs/http-cors.md) — fonte desta skill
- [HTTP - Negociação de Conteúdo e Range](../../../knowledge-base/docs/http-negociacao-de-conteudo-e-range.md) — a segunda fonte
- `http-contract` · `http-cache` · `http-review` — as skills irmãs
- `elysia-diagnose` — o mesmo achado pelo lado do plugin
