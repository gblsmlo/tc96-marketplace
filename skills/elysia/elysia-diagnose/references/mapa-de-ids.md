---
gerado-por: plugins/hermes-backend/skills/elysia-diagnose/scripts/gerar-mapa-de-ids.sh
gerado-em: 2026-09-17
---

# Mapa de IDs `ELYSIA-*`

> Índice, não cópia: diz **onde** a regra está declarada, nunca o que ela diz.
> Regenerar com `bash plugins/hermes-backend/skills/elysia-diagnose/scripts/gerar-mapa-de-ids.sh` —
> o mesmo arquivo é escrito nas três skills de Elysia.

## Apelidos parciais — a peculiaridade desta família


Três princípios aparecem em mais de uma família, porque cada satélite precisa se sustentar sozinho. **Para citar, use sempre o ID canônico** — o outro é apelido e não deve aparecer em revisão.

| Princípio | Canônico | Apelido |
| --- | --- | --- |
| `strict: true` e TypeScript >= 5.0 nos dois lados da fronteira Eden | `ELYSIA-APP-04` | `ELYSIA-TYPE-11`, **só nesta cláusula** |
| Falha esperada se sinaliza com `return status(...)`, não com `throw` | `ELYSIA-CORE-03` | `ELYSIA-LIFE-10` (aplicação do mesmo princípio dentro de `macro`) |
| Handler desestrutura o contexto; função externa anotada com `Context` não é aceita | `ELYSIA-CORE-02` | `ELYSIA-APP-03`, **só nesta cláusula** |

Os dois "só nesta cláusula" são deliberados, porque as duas regras não são redundantes por inteiro:

- **`ELYSIA-TYPE-11` continua citável por si** para o que é só dele: **a paridade de versão de `elysia` entre cliente e servidor**, que `ELYSIA-APP-04` não cobre e é a causa mais comum de o Eden degradar para `any`. É por isso que ele está na § 6.1 — a paridade de versão precisa viajar com o caminho mínimo. Ao citar o requisito de `strict: true` isoladamente, use `ELYSIA-APP-04`.
- **`ELYSIA-APP-09` não é apelido de nada.** Ele espelha `HONO-APP-03` na estrutura vizinha, mas ali a motivação é outra; aqui existe um export `env` no próprio pacote.
- **`ELYSIA-APP-03` continua citável por si** para o que é só dele: a legitimidade de valor literal e `file` no lugar do handler. Ao citar a desestruturação do contexto, use `ELYSIA-CORE-02`.


## Índice completo

| ID | Declarada em | Corpo no satélite | Seção do corpo |
| --- | --- | --- | --- |
| `ELYSIA-APP-01` | [Elysia](../../../../knowledge-base/docs/elysia.md) | — (família ELYSIA-APP-*, só no hub) | — |
| `ELYSIA-APP-02` | [Elysia](../../../../knowledge-base/docs/elysia.md) | — (família ELYSIA-APP-*, só no hub) | — |
| `ELYSIA-APP-03` | [Elysia](../../../../knowledge-base/docs/elysia.md) | — (família ELYSIA-APP-*, só no hub) | — |
| `ELYSIA-APP-04` | [Elysia](../../../../knowledge-base/docs/elysia.md) | — (família ELYSIA-APP-*, só no hub) | — |
| `ELYSIA-APP-05` | [Elysia](../../../../knowledge-base/docs/elysia.md) | — (família ELYSIA-APP-*, só no hub) | — |
| `ELYSIA-APP-06` | [Elysia](../../../../knowledge-base/docs/elysia.md) | — (família ELYSIA-APP-*, só no hub) | — |
| `ELYSIA-APP-07` | [Elysia](../../../../knowledge-base/docs/elysia.md) | — (família ELYSIA-APP-*, só no hub) | — |
| `ELYSIA-APP-08` | [Elysia](../../../../knowledge-base/docs/elysia.md) | — (família ELYSIA-APP-*, só no hub) | — |
| `ELYSIA-APP-09` | [Elysia](../../../../knowledge-base/docs/elysia.md) | — (família ELYSIA-APP-*, só no hub) | — |
| `ELYSIA-CORE-01` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) | 2. Instância, rotas e precedência de caminho |
| `ELYSIA-CORE-02` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) | 1. Conceito: o contexto é um acúmulo de decisões anteriores, não um objeto fixo |
| `ELYSIA-CORE-03` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) | 5. Erros: taxonomia, retorno × exceção, e customização |
| `ELYSIA-CORE-04` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) | 4. Formas de resposta |
| `ELYSIA-CORE-05` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) | 4. Formas de resposta |
| `ELYSIA-CORE-06` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) | 4. Formas de resposta |
| `ELYSIA-CORE-07` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) | 5. Erros: taxonomia, retorno × exceção, e customização |
| `ELYSIA-CORE-08` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) | 5. Erros: taxonomia, retorno × exceção, e customização |
| `ELYSIA-CORE-09` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) | 6. Testar sem subir servidor |
| `ELYSIA-CORE-10` | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) | [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) | 6. Testar sem subir servidor |
| `ELYSIA-LIFE-01` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | 5. Escopo: `local`, `scoped`, `global` e o método `as` |
| `ELYSIA-LIFE-02` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | 3. `state` × `decorate` × `derive` × `resolve` |
| `ELYSIA-LIFE-03` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | 4. Plugin é uma instância, e `use` é a única forma de compor |
| `ELYSIA-LIFE-04` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | 2. A ordem do lifecycle |
| `ELYSIA-LIFE-05` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | 3. `state` × `decorate` × `derive` × `resolve` |
| `ELYSIA-LIFE-06` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | 3. `state` × `decorate` × `derive` × `resolve` |
| `ELYSIA-LIFE-07` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | 4. Plugin é uma instância, e `use` é a única forma de compor |
| `ELYSIA-LIFE-08` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | 5. Escopo: `local`, `scoped`, `global` e o método `as` |
| `ELYSIA-LIFE-09` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | 5. Escopo: `local`, `scoped`, `global` e o método `as` |
| `ELYSIA-LIFE-10` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | 6. `macro`: hook reutilizável, ativado declarativamente |
| `ELYSIA-LIFE-11` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | 8. Plugins oficiais em produção |
| `ELYSIA-LIFE-12` | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | [Elysia - Lifecycle e Plugins](../../../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | 8. Plugins oficiais em produção |
| `ELYSIA-TYPE-01` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | 1. Conceito: uma declaração produz quatro artefatos — duplicar qualquer um é regressão |
| `ELYSIA-TYPE-02` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | 2. `t` × Standard Schema: onde Zod ainda faz sentido |
| `ELYSIA-TYPE-03` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | 3. Schema por rota e coerção automática |
| `ELYSIA-TYPE-04` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | 3. Schema por rota e coerção automática |
| `ELYSIA-TYPE-05` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | 4. `guard`, precedência e `standalone`; reference models |
| `ELYSIA-TYPE-06` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | 5. `response` por status, e o erro de validação |
| `ELYSIA-TYPE-07` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | 6. OpenAPI |
| `ELYSIA-TYPE-08` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | 7. Eden: o contrato atravessa para o frontend |
| `ELYSIA-TYPE-09` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | 7. Eden: o contrato atravessa para o frontend |
| `ELYSIA-TYPE-10` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | 7. Eden: o contrato atravessa para o frontend |
| `ELYSIA-TYPE-11` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | 7. Eden: o contrato atravessa para o frontend |
| `ELYSIA-TYPE-12` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | 5. `response` por status, e o erro de validação |
| `ELYSIA-TYPE-13` | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | [Elysia - Schema e Eden](../../../../knowledge-base/docs/elysia-schema-e-eden.md) | 7. Eden: o contrato atravessa para o frontend |
