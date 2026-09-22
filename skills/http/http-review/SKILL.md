---
name: http-review
description: Auditar o contrato HTTP de uma API existente contra as regras normativas da doc do vault, citando IDs `HTTP-*`, com oito sondas `curl` executáveis para o que a leitura de código não mostra — use quando a tarefa for revisar as rotas de um serviço ou de um PR, conferir se os status e headers estão certos, achar escrita sem proteção de concorrência, verificar se o CORS está desenhado ou improvisado, ou checar citação de RFC em ADR e documentação. Não use para desenhar rota nova, que é http-contract, para política de frescor, que é http-cache, nem para uma falha concreta em investigação, que é http-diagnose.
tags:
  - skill
  - http
  - backend
  - code-review
fonte: "[[HTTP]]"
---

# http-review

> **Fonte desta skill:** [[HTTP]] — a § 6 normativa (74 regras, numeração contínua), a § 6.1 com as 25 que viajam com o caminho mínimo, e a § 6.2 com os IDs canônicos.
> Esta skill **não contém** o texto das regras — ela diz o que executar, em que ordem varrer, como classificar e como reportar.

Contrato que esta skill implementa: [[HTTP]] § 7 ("Contrato de skill").

---

## Quando usar

Auditar o contrato de uma API que **já existe** — o serviço inteiro, ou as rotas de um PR.

| Situação | Vá para |
| --- | --- |
| desenhar rota nova | [[http-contract]] |
| política de frescor e condicional | [[http-cache]] |
| uma falha concreta em investigação | [[http-diagnose]] |
| o handler no framework | [[elysia-build]] |
| a suíte que deveria cobrir isso | [[teste-review]] |

---

## Carregamento mínimo

| Ordem | Carregar | Por quê |
| --- | --- | --- |
| 1 | [[HTTP]] § 2 | o modelo mental |
| 2 | [[HTTP]] § 6 + § 6.1 | regras e as críticas |
| 3 | `references/mapa-de-ids.md` | **obrigatório antes de citar** |
| 4 | o satélite do achado | via § 4 do hub |

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/sondas.md` | as oito sondas, e o que cada uma revela |
| `references/varredura-e-severidade.md` | a ordem por consequência, e a classificação |
| `references/relatorio-e-corte.md` | formato do achado, e o que **não** é achado |
| `references/antipadroes.md` | a grade completa com ID |
| `references/fechamento.md` | transformar sonda em teste, e declarar o não verificado |
| `references/mapa-de-ids.md` | os 74 `HTTP-*` por satélite e seção |
| `scripts/sondas.sh` | roda as oito contra o serviço de pé |
| `scripts/gerar-mapa-de-ids.sh` | regenera o mapa nas quatro skills de HTTP |

---

## Passo 1 — Sondar antes de ler

Contrato HTTP é **invisível no código**: o handler parece certo, o teste passa, e o header que falta só quebra atrás de uma CDN ou noutro browser.

```bash
bash ~/.claude/skills/http-review/scripts/sondas.sh https://api.local /faturas/42 /faturas/42
```

**Duas paradas obrigatórias:**

| Sonda | Se mostrar… | Por quê |
| --- | --- | --- |
| S5 | a escrita com `If-Match` obsoleto foi **aplicada** | perda silenciosa de dado sob concorrência — não é achado de estilo |
| S8 | dois formatos de erro na mesma API | contrato público inconsistente, e cada rota nova amplia |

**S3 é a que mais acende no stack:** em Hono, sem o middleware `methodNotAllowed`, método não suportado devolve `404` em vez de `405`.

---

## Passo 2 — Varrer na ordem

`references/varredura-e-severidade.md`, por **consequência**: o que corrompe dado → o que mente sobre o resultado → o que quebra cliente → o que degrada cache → convenção.

---

## Passo 3 — Classificar e reportar

Bloqueante é o que **corrompe dado ou mente** (escrita sem `If-Match`, falha em `2xx`, origem refletida cegamente); Alta é o que quebra cliente hoje; Média é dívida.

Para sonda, **a evidência é a saída do `curl`** — cole-a, com o status e os headers.

**Três coisas não são achado:** ausência de header que o stack já emite, escolha de formato de erro **consistente** que não é a sua preferida, e verbosidade de URL. Detalhe em `references/relatorio-e-corte.md`.

---

## Passo 4 — Fechar

1. **Transforme sonda em teste.** S3, S4, S5 e S6 são verificáveis em teste de API — achado que só existe no relatório volta em seis meses.
2. **Ordene por severidade**, não por rota.
3. **Se o serviço não sobe**, declare quais sondas não rodaram. **"Não verificado" não é "sem achado"**.

---

## Exemplo

API de faturas: as sondas mostram `PUT` com `If-Match` obsoleto sendo **aplicado** (perda silenciosa), `PATCH` devolvendo `404` em vez de `405`, e a origem `malicioso.example` sendo ecoada sem `Vary`. Os três são de categorias diferentes — corrupção, cliente quebrado e segurança — e o relatório os separa.

O formato e o corte estão em `references/relatorio-e-corte.md`.

---

## Relacionados

- [[HTTP]] — fonte desta skill: § 6, § 6.1, § 6.2, § 7
- [[http-contract]] · [[http-cache]] · [[http-diagnose]] — as skills irmãs
- [[elysia-build]] — onde a correção costuma ser feita
- [[teste-review]] — a suíte que deveria proteger o contrato
