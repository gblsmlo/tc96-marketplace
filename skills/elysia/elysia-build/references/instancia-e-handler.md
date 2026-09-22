# A instância e o handler

> Passos 0 a 2. O texto das regras mora em [Elysia](../../../../knowledge-base/docs/elysia.md) § 6 e [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md).

---

## Duas coisas que datam o código

**1. `error` não existe mais.** O nome atual é **`status`**, e `error` foi removido em 1.4
(`ELYSIA-APP-02`). Exemplos com `error` ainda circulam na doc oficial — código novo usa `status`.

**2. Dois escopos npm coexistem.** `@elysia/*` é o atual; `@elysiajs/*` é legado. E
`@elysiajs/swagger` está **descontinuado** — use `@elysia/openapi` (`ELYSIA-APP-07`).

---

## A instância

```ts
// ✓ method chaining contínuo — ELYSIA-APP-01
const app = new Elysia
.use(auth)
.get('/faturas', => listar)
.post('/faturas', ({ body }) => criar(body));

export type App = typeof app; // exportado como TIPO — ELYSIA-APP-05
```

| Regra | O que exige |
| --- | --- |
| `ELYSIA-APP-01` | method chaining **contínuo** — atribuir e chamar em statement separado perde o tipo acumulado |
| `ELYSIA-APP-05` | a instância para o Eden é exportada **como tipo**, do módulo onde o encadeamento termina |
| `ELYSIA-APP-04` | `strict: true` e TypeScript ≥ 5.0 no servidor **e** em todo cliente Eden |

**`ELYSIA-APP-01` produz o bug mais confuso:** o encadeamento é o que constrói o tipo.
Quebrá-lo em statements faz o tipo parar de acumular, e o Eden do cliente **perde as rotas**
— sem erro no servidor.

`ELYSIA-APP-09`: código de aplicação **nunca** lê `process.env` direto — use o export `env`
de `elysia`. E segredo nunca é literal (`ELYSIA-APP-08`).

---

## O handler

```ts
// ✓ desestrutura o que usa — ELYSIA-CORE-02
.post('/faturas', ({ body, status, cookie, set }) => { /* … */ })

// ✗ recebe o Context inteiro, ou é função externa anotada
.post('/faturas', criarFatura) // ELYSIA-CORE-02 (apelido: ELYSIA-APP-03)
```

Não é estilo: o contexto de Elysia é construído **por tipo** a partir do que a rota declara,
e uma função externa anotada com `Context` genérico apaga a inferência que o schema produziu.

`ELYSIA-APP-06`: código que usa `context.server`, `Bun.*` ou valor inline em rota declara Bun
como runtime alvo — nenhum dos três é portável.

---

## Relacionados

- [Elysia - Roteamento e Handler](../../../../knowledge-base/docs/elysia-roteamento-e-handler.md) — a fonte
- `erro-cookie-e-teste.md` — o passo seguinte
- `mapa-de-ids.md` — onde cada `ELYSIA-*` tem corpo
