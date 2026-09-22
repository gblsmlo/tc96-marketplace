# A árvore, e o que ela elimina

```
O hook não roda para esta rota.
├── ele foi registrado ANTES da rota?
│   └── NÃO → é isso.                                  ELYSIA-CORE-01
├── ele vem de um plugin, e a rota é da instância CONSUMIDORA?
│   └── SIM, e o escopo não foi declarado → é isso.     ELYSIA-LIFE-01
├── o plugin é aplicado por mais de uma instância?
│   └── e não tem `name` → o lifecycle roda uma vez só. ELYSIA-LIFE-03
├── o hook precisa de body/query/params/cookie?
│   └── e está em onRequest → o PreContext não os tem.  ELYSIA-LIFE-04
└── o plugin é um callback (app) => app?
    └── troque por instância `new Elysia()`.            ELYSIA-LIFE-07
```

**`ELYSIA-LIFE-03` produz o bug mais desconcertante:** sem `name`, o plugin aplicado duas vezes tem o lifecycle executado **uma** vez. O sintoma é o hook rodando para metade das rotas.

**`ELYSIA-LIFE-04`:** `onRequest` recebe `PreContext`, que **não** tem `body`, `query`, `params` nem `cookie`. Lógica que precisa deles ali lê `undefined` — e o `undefined` frequentemente passa como "sem filtro".

---


---

## Passo 3 — `derive` × `resolve`: a regra de segurança

`ELYSIA-LIFE-02`: **decisão de autenticação ou autorização nunca usa `derive`** — usa `resolve` ou `macro.resolve`, que rodam **depois** da validação.

`derive` roda **antes** da validação. Uma decisão de autorização ali opera sobre entrada não validada — é o caso clássico de checar um campo que a validação depois rejeitaria, ou de confiar num valor coagido de forma diferente.

| Precisa de… | Use |
| --- | --- |
| valor derivado, sem decisão de segurança | `derive` |
| **decisão de auth/autorização** | `resolve` ou `macro.resolve` |
| estado **mutável** | `state` |
| valor imutável injetado | `decorate` |

---

## Passo 4 — Estado que não muda, ou muda demais

| Sintoma | Causa | Regra |
| --- | --- | --- |
| valor do `store` fica congelado | primitivo desestruturado no parâmetro do handler — a referência se perde | `ELYSIA-LIFE-06` |
| valor de `decorate` foi mutado e o comportamento ficou imprevisível | `decorate` é imutável; estado mutável é `state` | `ELYSIA-LIFE-05` |

```ts
// ✗ contador congela no valor do momento do registro
.get('/x', ({ store: { contador } }) => contador)

// ✓ lê pela referência
.get('/x', ({ store }) => store.contador)
```

`ELYSIA-LIFE-06` é sutil e comum: a desestruturação copia o primitivo, e toda leitura seguinte devolve o valor antigo.

---

