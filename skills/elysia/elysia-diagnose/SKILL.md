---
nome: elysia-diagnose
descricao: Diagnosticar por que um plugin ou hook não afeta uma rota em Elysia, e escolher o ponto certo do lifecycle — ordem de registro, escopo `local`/`scoped`/`global`, `name` de plugin, `derive` × `resolve`, `state` × `decorate`, macro, tracing — citando IDs `ELYSIA-LIFE-*`, com dez sondas executáveis — use quando a tarefa for investigar hook que não roda, autenticação que não protege a rota do consumidor, valor do `store` congelado, plugin cujo lifecycle roda uma vez só, ou span `anonymous` no OpenTelemetry. Não use para escrever rota e handler, que é elysia-build, nem para schema e Eden, que é elysia-schema.
tipo: skill
familia: elysia
fonte: "[Elysia - Lifecycle e Plugins](../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md)"
docs:
  - /websites/elysiajs
tags:
  - skill
  - elysia
  - backend
---

# elysia-diagnose

> **Fonte desta skill:** [Elysia - Lifecycle e Plugins](../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md), com o hub [Elysia](../../../knowledge-base/docs/elysia.md) como roteador.
> Esta skill **não contém** o texto das regras — ela diz o que sondar, em que ordem eliminar hipóteses, e o que **prova** cada uma.
> **Superfície de API:** resolva pelo Context7 — `/websites/elysiajs`. Assinatura, opção e comportamento por versão vêm de lá; a regra e o ID vêm da knowledge-base.

Contrato que esta skill implementa: [Elysia](../../../knowledge-base/docs/elysia.md) § 7 ("Contrato de skill").

---

## Quando usar

Um hook, plugin, `derive`, `resolve` ou `onError` **não está afetando** a rota — ou o estado se comporta de forma inesperada.

| Situação | Vá para |
| --- | --- |
| escrever rota e handler | `elysia-build` |
| schema, `response`, cliente Eden | `elysia-schema` |
| requisição bloqueada pelo browser, preflight | `http-diagnose` |
| teste flaky sob `bun test` | `bun-test-review` |

---

## Carregamento mínimo

| Ordem | Carregar | Por quê |
| --- | --- | --- |
| 1 | [Elysia](../../../knowledge-base/docs/elysia.md) § 2 | o modelo mental de instância e plugin |
| 2 | [Elysia](../../../knowledge-base/docs/elysia.md) § 6 + § 6.1 + § 6.2 | regras, críticas e IDs canônicos |
| 3 | [Elysia - Lifecycle e Plugins](../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | a fonte |

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/duas-causas.md` | ordem de registro e escopo não declarado — quase todo caso está aqui |
| `references/arvore.md` | os cinco ramos, e `derive` × `resolve` × `state` × `decorate` |
| `references/macro-tracing-e-cors.md` | as três que falham sem quebrar nada |
| `references/prova-de-escopo.md` | o teste que distingue `local` de `scoped`, e o corte do que não é lifecycle |
| `references/antipadroes.md` | a grade com ID |
| `references/mapa-de-ids.md` | os 44 `ELYSIA-*`: declaração, satélite do corpo e seção |
| `references/exemplo-plugin-sem-escopo.md` | diagnóstico inteiro, da sonda ao achado |
| `scripts/sondas.sh` | dez sondas de lifecycle |
| `scripts/gerar-mapa-de-ids.sh` | regenera o mapa nas três skills de Elysia |

---

## Passo 1 — Sondar

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/elysia-diagnose/scripts/sondas.sh src
```

**S1 mede a ordem por número de linha** — hook registrado depois da primeira rota do arquivo. É a **primeira hipótese, sempre** (`ELYSIA-CORE-01`), e não dá erro nem aviso: a rota simplesmente não passa pelo hook.

As outras nove: escopo não declarado, plugin sem `name`, `derive` decidindo auth, `onRequest` lendo `body`/`query`, `store` desestruturado, `decorate` mutado, hook anônimo sob tracing, `cors` default, macro com `throw`, plugin como callback.

---

## Passo 2 — As duas causas

**1. Registrado depois da rota** (`ELYSIA-CORE-01`) — hooks só se aplicam a rota registrada **depois** deles.

**2. Escopo não declarado** (`ELYSIA-LIFE-01`) — o default é **`local`**: o hook fica dentro do plugin e **não atravessa** para a instância consumidora. Um plugin de autenticação sem escopo declarado protege as rotas dele e **nenhuma** do consumidor.

```
local → só a instância do próprio plugin
scoped → o consumidor direto
global → toda a árvore
```

Hook transversal — tracing, logging, CORS — usa `global` (`ELYSIA-LIFE-09`), não uma corrente de `scoped`.

---

## Passo 3 — A árvore

`references/arvore.md`, cinco ramos. Dois que produzem bug desconcertante:

- **`ELYSIA-LIFE-03`** — plugin sem `name` aplicado duas vezes tem o lifecycle executado **uma** vez; o sintoma é o hook rodando para metade das rotas.
- **`ELYSIA-LIFE-04`** — `onRequest` recebe `PreContext`, que **não** tem `body`, `query`, `params` nem `cookie`; lê `undefined`, e `undefined` frequentemente passa como "sem filtro".

**A regra de segurança:** decisão de auth/autorização **nunca** usa `derive` (`ELYSIA-LIFE-02`) — `derive` roda **antes** da validação. Use `resolve` ou `macro.resolve`.

---

## Passo 4 — Estado

| Sintoma | Causa | Regra |
| --- | --- | --- |
| valor do `store` congelado | primitivo desestruturado no parâmetro — a referência se perde | `ELYSIA-LIFE-06` |
| `decorate` mutado, comportamento imprevisível | `decorate` é imutável; mutável é `state` | `ELYSIA-LIFE-05` |

---

## Passo 5 — Provar

**A sonda aponta; ela não prova.** `local` e `scoped` produzem o mesmo código dentro do plugin: a diferença só aparece na instância que o consome.

`references/prova-de-escopo.md` traz o teste que `ELYSIA-LIFE-08` exige — uma rota da instância **consumidora** rejeitada sem credencial. É a única asserção que distingue os dois escopos.

---

## Passo 6 — Reportar

```
`ID-DA-REGRA` — arquivo:linha
Sintoma: <o que não acontece>
Evidência: <o teste, o log, ou a ordem de registro>
Causa: <uma frase>
Correção: <mudança concreta>
Ver Satélite correspondente.
```

**Evidência é teste ou ordem de registro**, não impressão.

---

## Passo 7 — O corte: o que não é lifecycle

Erro chegando como `unknown` no Eden, `data` `null`, tipo que perdeu rotas, header que "nunca chega", body numérico que falha, teste flaky com plugin assíncrono, SSE que cai — **nenhum é lifecycle**. A tabela com o dono de cada um está em `references/prova-de-escopo.md`.

---

## Exemplo

Plugin de auth cujas rotas de teste são rejeitadas corretamente, e as rotas do servidor passam sem credencial. S1 limpo, S2 apontando `.onBeforeHandle(verificar)` sem escopo — e o teste na instância consumidora devolvendo **200 onde deveria dar 401**. O teste que existia rodava **dentro** do plugin, e por isso nunca pegou.

Diagnóstico completo: `references/exemplo-plugin-sem-escopo.md`.

---

## Relacionados

- [Elysia - Lifecycle e Plugins](../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) — fonte desta skill
- [Elysia](../../../knowledge-base/docs/elysia.md) § 6, § 7
- `elysia-build` · `elysia-schema` — as skills irmãs
- `http-diagnose` — quando o sintoma é CORS no browser
