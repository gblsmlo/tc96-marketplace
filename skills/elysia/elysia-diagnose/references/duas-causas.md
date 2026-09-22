# As duas causas que respondem por quase tudo

### 1.1 Registrado depois da rota

`ELYSIA-CORE-01`: hook, plugin e `onError` **só se aplicam a rota registrada depois deles**.

```ts
// ✗ o hook não afeta /faturas
new Elysia
.get('/faturas', h)
.onBeforeHandle(auth)

// ✓
new Elysia
.onBeforeHandle(auth)
.get('/faturas', h)
```

**É a primeira hipótese, sempre.** Não dá erro, não dá aviso — a rota simplesmente não passa pelo hook.

### 1.2 Escopo não declarado

`ELYSIA-LIFE-01`: hook de plugin que precisa valer **para quem o consome** declara escopo — `{ as: 'scoped' }`, `guard({ as })` ou `.as(...)`.

O default é **`local`**: o hook fica dentro do plugin e **não atravessa** para a instância consumidora. Um plugin de autenticação sem escopo declarado protege as rotas dele e **nenhuma** do consumidor.

```
local → só a instância do próprio plugin
scoped → o consumidor direto
global → toda a árvore
```

`ELYSIA-LIFE-09`: hook transversal que deve valer em toda a árvore — tracing, logging, CORS — usa **`global`**, não uma corrente de `scoped`.

> **A prova que `ELYSIA-LIFE-08` exige:** plugin de autenticação **precisa provar em teste que uma rota da instância consumidora é rejeitada sem credencial.** Testar dentro do plugin não prova nada — é exatamente o caso que passa com escopo `local` e falha em produção.

---

