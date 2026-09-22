---
nome: elysia-build
descricao: Escrever rota e handler em Elysia — method chaining, contexto desestruturado, `status`, cookie assinado, stream, taxonomia de erro e teste por `app.handle` — citando IDs `ELYSIA-CORE-*` e `ELYSIA-APP-*`, com autoverificação executável — use quando a tarefa for criar rota nova, devolver erro esperado de forma tipada, assinar cookie de sessão, registrar erro de domínio com `code` próprio, tratar `onError`, ou testar rota sem subir servidor. Não use para schema e cliente Eden, que é elysia-schema, para plugin ou hook que não afeta a rota, que é elysia-diagnose, nem para o contrato HTTP em si, que é http-contract.
tipo: skill
familia: elysia
fonte: "[Elysia - Roteamento e Handler](../../../knowledge-base/docs/elysia-roteamento-e-handler.md)"
docs:
  - /websites/elysiajs
tags:
  - skill
  - elysia
  - backend
---

# elysia-build

> **Fonte desta skill:** [Elysia - Roteamento e Handler](../../../knowledge-base/docs/elysia-roteamento-e-handler.md), com o hub [Elysia](../../../knowledge-base/docs/elysia.md) como roteador. As 44 regras da família `ELYSIA-*` são declaradas na § 6 do hub; o corpo de `CORE`, `LIFE` e `TYPE` vive no satélite dono.
> Esta skill **não contém** o texto das regras — ela diz o que carregar, em que ordem decidir e o que conferir antes de entregar.
> **Superfície de API:** resolva pelo Context7 — `/websites/elysiajs`. Assinatura, opção e comportamento por versão vêm de lá; a regra e o ID vêm da knowledge-base.

Contrato que esta skill implementa: [Elysia](../../../knowledge-base/docs/elysia.md) § 7 ("Contrato de skill").

---

## Quando usar

Escrever ou editar **rota e handler**.

| Situação | Vá para |
| --- | --- |
| schema de validação, `response` por status, cliente Eden | `elysia-schema` |
| hook ou plugin que **não afeta** a rota | `elysia-diagnose` |
| qual status, `Location`, idempotência, corpo de erro | `http-contract` — Elysia é o mecanismo, não o critério |
| política de cache e `ETag` | `http-cache` |
| persistência que o handler chama | `drizzle-review` |
| o teste em si, sob `bun test` | `bun-test-build` |

---

## Carregamento mínimo

| Ordem | Carregar | Por quê |
| --- | --- | --- |
| 1 | [Elysia](../../../knowledge-base/docs/elysia.md) § 2 | **uma declaração de schema produz quatro efeitos** — é o modelo mental |
| 2 | [Elysia](../../../knowledge-base/docs/elysia.md) § 3 | fronteiras de import, e os **dois escopos npm** que coexistem |
| 3 | [Elysia](../../../knowledge-base/docs/elysia.md) § 6 + § 6.1 + § 6.2 | regras, críticas e IDs canônicos |
| 4 | [Elysia - Roteamento e Handler](../../../knowledge-base/docs/elysia-roteamento-e-handler.md) | a fonte |
| 5 | [Elysia](../../../knowledge-base/docs/elysia.md) § 5 ("Como devolvo um erro?") | a árvore de erro |

**Nunca carregue os satélites todos.**

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/instancia-e-handler.md` | as duas coisas que datam o código, o chaining, o contexto desestruturado |
| `references/erro-cookie-e-teste.md` | a árvore de erro, cookie assinado, stream, e o teste por `app.handle` |
| `references/autoverificacao.md` | os 15 itens, e quais o script **não** decide |
| `references/antipadroes.md` | 17 antipadrões com ID |
| `references/mapa-de-ids.md` | os 44 `ELYSIA-*`: declaração, **satélite do corpo** e seção |
| `references/exemplo-rota-de-faturas.md` | caso trabalhado, da instância ao teste |
| `scripts/autoverificar.sh` | roda os itens mecânicos e lista os que exigem leitura |

**Confira a § 6.2 antes de citar:** esta família tem **apelidos parciais** — `ELYSIA-APP-03` é apelido de `ELYSIA-CORE-02` **só** na cláusula de desestruturação, e `ELYSIA-TYPE-11` é apelido de `ELYSIA-APP-04` **só** na de `strict`. Fora dessas cláusulas, os dois são citáveis pelo que é só deles.

---

## Passo 0 — Duas coisas que datam o código

1. **`error` não existe mais** — é `status` desde a 1.4 (`ELYSIA-APP-02`). Exemplos com `error` ainda circulam.
2. **`@elysiajs/*` é legado**, e `@elysiajs/swagger` está descontinuado — use `@elysia/openapi` (`ELYSIA-APP-07`).

---

## Passo 1 — A instância

Method chaining **contínuo** (`ELYSIA-APP-01`), `export type App = typeof app` no fim (`ELYSIA-APP-05`), `strict: true` nos dois lados (`ELYSIA-APP-04`). Quebrar o chaining em statements faz o Eden **perder as rotas sem erro no servidor**.

---

## Passo 2 — O handler

Desestruture o contexto **inline** (`ELYSIA-CORE-02`). Função externa anotada com `Context` genérico apaga a inferência que o schema produziu — não é preferência de estilo.

---

## Passo 3 — Erro

**Esperado → `return status(código, corpo)`** (`ELYSIA-CORE-03`); inesperado → `throw`, que cai no `onError`. `throw` sai por um caminho **fora do tipo da rota**, então o Eden não sabe que aquele status existe.

`onError` **nunca** devolve `error.message` de erro `UNKNOWN` (`ELYSIA-CORE-07`) — é achado de segurança: vaza caminho de arquivo, query e nome de tabela.

---

## Passo 4 — Cookie e stream

Cookie de sessão **assinado e `httpOnly`** (`ELYSIA-CORE-05`); a semântica de `SameSite` e prefixos é de `Docs/RFC 6265 - Cookies HTTP.md`. Em stream, `set.headers` depois do primeiro `yield` é **silenciosamente ignorado** (`ELYSIA-CORE-06`) — e o `idleTimeout` do `Bun.serve` derruba SSE por conta própria.

---

## Passo 5 — Teste

`app.handle`, nunca por rede (`ELYSIA-CORE-09`), e **`await app.modules`** antes das asserções (`ELYSIA-CORE-10`) — sem isso o teste roda antes de o plugin registrar a rota, e vira flaky.

---

## Passo 6 — Autoverificar antes de entregar

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/elysia-build/scripts/autoverificar.sh src
tsc --noEmit # Bun transpila sem checar tipo — BUN-CORE-02
```

Os 15 itens estão em `references/autoverificacao.md`, com a marcação de quais o script decide e quais exigem leitura.

---

## Passo 7 — Fechar

1. **`tsc --noEmit`** e o teste por `app.handle`.
2. **Rota com mais de um status** precisa de `response` como mapa — é `elysia-schema` (`ELYSIA-TYPE-06`); sem ele o Eden vê `unknown`.
3. **Hook que não afeta a rota** é escopo ou ordem — `elysia-diagnose`.
4. **Decisão de protocolo** (status, `Location`, `Retry-After`) é `http-contract`.
5. **Streaming**: confira o `idleTimeout` do `Bun.serve` — o framework não o contorna.
6. **Declare o que não verificou.** O caminho do `onError` para erro realmente inesperado raramente é exercitado.

---

## Exemplo

Rota de aprovação de fatura com erro de limite e sessão assinada: o erro esperado sai por `return status(422, …)` e chega **tipado** ao Eden; o `onError` responde genérico e loga o detalhe; o cookie é assinado e `httpOnly`; o teste roda por `app.handle` depois de `await app.modules`.

Caso completo: `references/exemplo-rota-de-faturas.md`.

---

## Relacionados

- [Elysia - Roteamento e Handler](../../../knowledge-base/docs/elysia-roteamento-e-handler.md) — fonte desta skill
- [Elysia](../../../knowledge-base/docs/elysia.md) § 2, § 5, § 6, § 7 — modelo mental, árvores, regras, contrato
- `elysia-schema` · `elysia-diagnose` — as skills irmãs
- `http-contract` · `http-cache` — o protocolo, que Elysia só implementa
- `bun-test-build` — o teste em si
