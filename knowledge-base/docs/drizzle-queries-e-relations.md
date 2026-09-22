---
titulo: Drizzle - Queries e Relations
Link: https://orm.drizzle.team/docs/select
tags:
  - typescript
  - backend
  - database
  - orm
  - postgresql
  - zod
  - agent-context
source: "Documentação oficial do Drizzle ORM — query builder, relations, RQB, transactions, drizzle-zod, cruzada com o snapshot pinado na versão estável"
verificado-em: 2026-08-16
---

# Drizzle — Queries e Relations

> `select`/`insert`/`update`/`delete` · `relations()` · Relational Queries (`db.query`) · `transaction` · `drizzle-zod`
>
> Como ler e escrever dados, como declarar que tabelas se relacionam, e como buscar isso tudo numa query só.

Entrada: [Drizzle ORM](drizzle-orm.md) · **Confirme a § 0 de lá antes de usar esta nota** — a API de relations aqui é a estável (`relations()` + `one`/`many`), não `defineRelations()` da v1-rc.

> **Convenção de import nesta nota.** Para não repetir a mesma linha em cada bloco, os exemplos abaixo assumem, salvo indicação contrária: `sql`, `eq`, `and`, `or`, `not`, `asc`, `desc`, `count`, `sum`, `avg`, `max`, `min` importados de `'drizzle-orm'`; `relations` também de `'drizzle-orm'`; e, no exemplo de `drizzle-zod` (§ 6.1), `z` de `'zod'`. Cada bloco é uma ilustração independente — nomes de variável não persistem de um bloco para o outro.

---

## 1. Query builder: `select`

```ts
const result = await db.select().from(users)
```

**Sem `select(...)` a query lista colunas explícitas, nunca `SELECT *`** — a doc é explícita nisso: a ordem das colunas no resultado é garantida pela ordem declarada, o que `SELECT *` não garante entre migrações.

### 1.1 Seleção parcial e expressão SQL

```ts
await db.select({
  id: users.id,
  name: users.name,
}).from(users)

// expressão arbitrária, com tipo explícito
await db.select({
  id: users.id,
  lowerName: sql<string>`lower(${users.name})`,
}).from(users)
```

### 1.2 Filtros

```ts
import { eq, and, or, not } from 'drizzle-orm'

await db.select().from(users).where(eq(users.id, 42))
await db.select().from(users).where(and(eq(users.id, 42), eq(users.name, 'Dan')))
await db.select().from(users).where(or(eq(users.id, 1), eq(users.id, 2)))
await db.select().from(users).where(not(eq(users.id, 42)))
```

Os operadores são **funções importadas**, não métodos encadeados — `eq(coluna, valor)`, não `coluna.eq(valor)`. Isso é o que faz o `where` compor: `and(eq(...), or(eq(...), eq(...)))` é só função dentro de função.

`eq` cobre igualdade; para o resto da família de comparação a forma é idêntica — `lt`, `lte`, `gt`, `gte(coluna, valor)`, `ne` (diferente de), todos importados do mesmo `'drizzle-orm'`.

### 1.3 Ordenação e paginação

```ts
import { desc } from 'drizzle-orm'

await db.select().from(users).orderBy(users.name)      // asc é o default; a coluna sozinha basta
await db.select().from(users).orderBy(desc(users.name))
await db.select().from(users).limit(10).offset(10)
```

### 1.4 Joins

```ts
await db
  .select()
  .from(countries)
  .leftJoin(cities, eq(cities.countryId, countries.id))
  .where(eq(countries.id, 10))
```

`leftJoin`, `innerJoin`, `rightJoin`, `fullJoin` seguem a mesma forma: a condição de junção é o segundo argumento, escrita com o mesmo `eq` do `where`.

### 1.5 Agregação

```ts
import { count, sum, avg, max, min } from 'drizzle-orm'

await db.select({ value: count() }).from(users)
await db.select({ value: sum(users.age) }).from(users)

await db.select({
  age: users.age,
  total: sql<number>`cast(count(${users.id}) as int)`,
})
  .from(users)
  .groupBy(users.age)
```

`having()` filtra depois do `groupBy`, na mesma sintaxe de `where`.

### 1.6 Subquery e CTE

```ts
// subquery
const sq = db.select().from(users).where(eq(users.id, 42)).as('sq')
const result = await db.select().from(sq)

// CTE (WITH)
const cte = db.$with('sq').as(db.select().from(users).where(eq(users.id, 42)))
const result2 = await db.with(cte).select().from(cte)
```

### 1.7 `sql` para o que o query builder não expressa

```ts
await db.select().from(users).where(sql`lower(${users.name}) = 'aaron'`)
```

Todo valor interpolado dentro de `` sql`...` `` é **parametrizado automaticamente** — o template literal não concatena string, ele monta a query com placeholders. `sql` é escape hatch, não substituto do `where(eq(...))` no caso comum.

### 1.8 Regras — `DRZ-QUERY-*` (select)

| ID | Regra |
| --- | --- |
| `DRZ-QUERY-01` | Seleção de campos **MUST** ser explícita quando a ordem ou o subconjunto de colunas importa; `select()` sem argumento é aceitável só quando o objeto inteiro é consumido. |
| `DRZ-QUERY-02` | Filtro **MUST** ser composto com `eq`/`and`/`or`/`not` importados de `drizzle-orm`, **NEVER** concatenação de string dentro de `sql`. |
| `DRZ-QUERY-03` | `` sql`...` `` **MUST** ficar restrito ao que o query builder não expressa; não é a via padrão de filtro. |

---

## 2. Query builder: `insert`, `update`, `delete`

### 2.1 Insert

```ts
await db.insert(users).values({ name: 'Andrew' })
await db.insert(users).values([{ name: 'Andrew' }, { name: 'Dan' }])   // várias linhas
```

`returning()` (Postgres e SQLite) devolve as linhas inseridas:

```ts
await db.insert(users).values({ name: 'Dan' }).returning()
await db.insert(users).values({ name: 'Dan' }).returning({ insertedId: users.id })
```

O tipo do objeto de entrada vem de `typeof users.$inferInsert` — nunca escrito à mão.

### 2.2 Upsert — `onConflictDoNothing` e `onConflictDoUpdate`

```ts
// ignora se colidir
await db.insert(users).values({ id: 1, name: 'John' }).onConflictDoNothing({ target: users.id })

// atualiza campos específicos ao colidir
await db.insert(users)
  .values({ id: 1, name: 'Dan' })
  .onConflictDoUpdate({ target: users.id, set: { name: 'John' } })

// só atualiza sob uma condição, e referencia a linha nova via `excluded`
await db.insert(employees)
  .values({ employeeId: 123, name: 'John Doe' })
  .onConflictDoUpdate({
    target: employees.employeeId,
    targetWhere: sql`name <> 'John Doe'`,
    set: { name: sql`excluded.name` },
  })
```

Chave composta em `target` aceita array: `target: [users.firstName, users.lastName]`.

`.returning()` encadeia depois de `onConflictDoUpdate`/`onConflictDoNothing` normalmente — é o mesmo método de § 2.1, aplicado à linha final (inserida ou atualizada):

```ts
const [post] = await db.insert(posts)
  .values({ slug: 'meu-post', title: 'Meu Post' })
  .onConflictDoUpdate({ target: posts.slug, set: { title: 'Meu Post' } })
  .returning()
```

**`target` precisa ser uma coluna com `UNIQUE` ou chave primária no banco** — `ON CONFLICT` do Postgres exige uma constraint real para saber qual colisão observar. Declarar `.unique()` na coluna do schema (ver [Drizzle - Schema e Migrations](drizzle-schema-e-migrations.md) § 1.3) é pré-requisito, não detalhe do Drizzle.

### 2.3 Insert a partir de um select

```ts
await db
  .insert(employees)
  .select(
    db.select({ name: users.name }).from(users).where(eq(users.role, 'employee')),
  )
  .returning({ id: employees.id })
```

`INSERT ... SELECT` numa query só, sem trazer os dados para a aplicação e reinseri-los — importante quando o volume é grande.

### 2.4 Update

```ts
await db.update(users).set({ name: 'Mr. Dan' }).where(eq(users.name, 'Dan'))

// expressão SQL no set — incrementar, tocar timestamp
await db.update(users).set({ updatedAt: sql`now()` }).where(eq(users.name, 'Dan'))
```

**`undefined` no objeto de `set` é ignorado — o campo não muda.** Para setar `null` de verdade, passe `null` explícito. É o mesmo cuidado de `RHF-CORE-06` do lado do formulário: `undefined` nunca é "vazio", é "não mexi aqui".

`returning()` funciona igual ao insert. `limit()` no update só existe em MySQL/SQLite/SingleStore — **não em Postgres**.

### 2.5 Delete

```ts
await db.delete(users).where(eq(users.name, 'Dan'))
await db.delete(users)   // sem where: apaga a tabela inteira
```

`returning()` funciona igual. Mesma ausência de `limit()` em Postgres.

> **A pegadinha mais cara desta seção.** `db.delete(users)` sem `.where()` **não é erro de sintaxe** — é `DELETE FROM users` sem filtro, e apaga tudo. O mesmo vale para `update` sem `where`: atualiza a tabela inteira. Nenhum aviso do TypeScript pega isso, porque `where()` é opcional na assinatura.

### 2.6 Regras — `DRZ-QUERY-*` (escrita)

| ID | Regra |
| --- | --- |
| `DRZ-QUERY-04` | `update`/`delete` sem `where` **MUST** ter a ausência do filtro confirmada como intencional — é a causa mais cara de incidente nesta API. |
| `DRZ-QUERY-05` | Para limpar um campo, o valor **MUST** ser `null` explícito; `undefined` é ignorado pelo `set`. |
| `DRZ-QUERY-06` | Upsert **MUST** usar `onConflictDoNothing`/`onConflictDoUpdate`, **NEVER** um `select` seguido de `insert`/`update` condicional em duas queries — perde atomicidade. |

---

## 3. Transactions

```ts
await db.transaction(async (tx) => {
  await tx.update(accounts).set({ balance: sql`${accounts.balance} - 100` }).where(eq(accounts.id, 1))
  await tx.update(accounts).set({ balance: sql`${accounts.balance} + 100` }).where(eq(accounts.id, 2))
})
```

Todo método de `tx` espelha o de `db` — inclusive RQB (`tx.query.users.findMany(...)`).

### 3.1 Rollback e retorno

```ts
const novoSaldo = await db.transaction(async (tx) => {
  const [conta] = await tx.select({ saldo: accounts.balance }).from(accounts).where(eq(accounts.id, 1))
  if (conta.saldo < 100) {
    tx.rollback()   // interrompe e desfaz — não precisa de throw
  }
  await tx.update(accounts).set({ balance: sql`${accounts.balance} - 100` }).where(eq(accounts.id, 1))
  return conta.saldo - 100
})
```

`tx.rollback()` é a via idiomática — não é preciso lançar uma exceção para desfazer a transaction.

### 3.2 Savepoints (transaction aninhada)

```ts
await db.transaction(async (tx) => {
  await tx.update(accounts).set({ balance: sql`${accounts.balance} - 100` }).where(eq(accounts.id, 1))

  await tx.transaction(async (tx2) => {
    await tx2.update(users).set({ name: 'Mr. Dan' }).where(eq(users.id, 1))
  })
})
```

Uma `transaction` dentro de outra vira `SAVEPOINT` no Postgres — a interna pode falhar e reverter sem desfazer a externa.

### 3.3 Isolamento (PostgreSQL)

```ts
await db.transaction(
  async (tx) => { /* ... */ },
  {
    isolationLevel: 'serializable',   // 'read uncommitted' | 'read committed' | 'repeatable read' | 'serializable'
    accessMode: 'read write',          // 'read only' | 'read write'
  },
)
```

### 3.4 Regras — `DRZ-TX-*`

| ID | Regra |
| --- | --- |
| `DRZ-TX-01` | Duas ou mais escritas que precisam ser atômicas **MUST** estar dentro do mesmo `db.transaction`, **NEVER** chamadas soltas em sequência. |
| `DRZ-TX-02` | Reverter uma transaction **MUST** usar `tx.rollback()`, **NEVER** um `throw` só para produzir o mesmo efeito quando não há erro real a propagar. |
| `DRZ-TX-03` | Toda operação dentro da transaction **MUST** usar `tx`, **NEVER** o `db` externo — usar `db` por engano executa fora da transaction e quebra a atomicidade sem erro visível. |

---

## 4. Relations: declarando que tabelas se relacionam

`relations()` é importado de `'drizzle-orm'` — **não** de `drizzle-orm/pg-core`. Ele não altera o schema SQL; é metadado consumido só pelo RQB (§ 5).

### 4.1 Um-para-muitos

```ts
import { relations } from 'drizzle-orm'

export const usersRelations = relations(users, ({ many }) => ({
  posts: many(posts),
}))

export const postsRelations = relations(posts, ({ one }) => ({
  author: one(users, {
    fields: [posts.authorId],
    references: [users.id],
  }),
}))
```

**As duas declarações são necessárias** — uma por tabela. `fields`/`references` vivem do lado que **tem** a foreign key (`posts.authorId`); o lado `many()` só declara que a relação existe, sem repetir a FK.

### 4.2 Um-para-um

```ts
export const usersRelations = relations(users, ({ one }) => ({
  invitee: one(users, {
    fields: [users.invitedBy],
    references: [users.id],
  }),
}))
```

Quando a FK está na tabela relacionada em vez de nesta, `fields`/`references` somem e a relação vira opcional:

```ts
export const usersRelations = relations(users, ({ one }) => ({
  profileInfo: one(profileInfo),   // sem fields/references — FK mora em profileInfo
}))
```

### 4.3 Muitos-para-muitos, com tabela de junção

Drizzle **não** tem uma primitiva de muitos-para-muitos direta — é sempre uma tabela intermediária explícita, com duas relações um-para-muitos.

```ts
export const usersToGroups = pgTable('users_to_groups', {
  userId: integer('user_id').notNull().references(() => users.id),
  groupId: integer('group_id').notNull().references(() => groups.id),
}, (t) => [
  primaryKey({ columns: [t.userId, t.groupId] }),
])

export const usersRelations = relations(users, ({ many }) => ({
  usersToGroups: many(usersToGroups),
}))
export const groupsRelations = relations(groups, ({ many }) => ({
  usersToGroups: many(usersToGroups),
}))
export const usersToGroupsRelations = relations(usersToGroups, ({ one }) => ({
  user: one(users, { fields: [usersToGroups.userId], references: [users.id] }),
  group: one(groups, { fields: [usersToGroups.groupId], references: [groups.id] }),
}))
```

Uma busca de `usuário → grupos` precisa passar pela tabela de junção em `with` (ver § 5.1) — o RQB não "pula" a tabela intermediária sozinho.

### 4.4 Duas relações entre as mesmas tabelas: `relationName`

Quando existe mais de um caminho entre as mesmas duas tabelas (autor **e** revisor de um post, ambos `users`), o RQB não sabe qual FK usar sem ajuda:

```ts
export const usersRelations = relations(users, ({ many }) => ({
  postsAsAuthor: many(posts, { relationName: 'author' }),
  postsAsReviewer: many(posts, { relationName: 'reviewer' }),
}))

export const postsRelations = relations(posts, ({ one }) => ({
  author: one(users, { fields: [posts.authorId], references: [users.id], relationName: 'author' }),
  reviewer: one(users, { fields: [posts.reviewerId], references: [users.id], relationName: 'reviewer' }),
}))
```

### 4.5 Wiring: conectar `relations` ao client

```ts
import * as schema from './schema'
import { drizzle } from 'drizzle-orm/node-postgres'

const db = drizzle(process.env.DATABASE_URL!, { schema })
```

**`schema` aqui precisa incluir tanto as tabelas quanto os `relations()`** — normalmente um `export * from './tabelas'` e `export * from './relations'` no mesmo arquivo reexportado, ou um objeto que agrupa os dois. Sem o `relations` no schema passado ao `drizzle()`, `db.query` existe mas `with` não encontra a relação.

### 4.6 Regras — `DRZ-REL-*`

| ID | Regra |
| --- | --- |
| `DRZ-REL-01` | Toda relação **MUST** ser declarada dos dois lados — `many()` numa tabela sem o `one()` correspondente na outra deixa `with` incompleto. |
| `DRZ-REL-02` | `fields`/`references` **MUST** ficar do lado que tem a coluna de foreign key; o lado oposto usa `many()`/`one()` sem eles. |
| `DRZ-REL-03` | Muitos-para-muitos **MUST** passar por tabela de junção explícita — não existe atalho direto entre as duas tabelas de domínio. |
| `DRZ-REL-04` | Duas relações entre as mesmas tabelas **MUST** usar `relationName` nos dois lados, com o mesmo nome — senão o RQB não sabe distinguir qual FK usar. |
| `DRZ-REL-05` | O `schema` passado a `drizzle(..., { schema })` **MUST** incluir os `relations()`, **NEVER** só as tabelas — sem isso `with` não resolve nada. |

---

## 5. Relational Queries (RQB)

`db.query.tabela.findMany()`/`findFirst()`. Requer `relations` no schema conectado (§ 4.5).

### 5.1 `with` — trazer relações aninhadas

```ts
const posts = await db.query.posts.findMany({
  with: { comments: true },
})
```

Aninha arbitrariamente fundo, e cada nível pode trazer `columns`, `where`, `orderBy`, `limit` e um novo `with` — **exceto `offset`, que só existe no nível raiz** (§ 5.4).

```ts
const postsComAutorDoComentario = await db.query.posts.findMany({
  with: {
    comments: {
      with: { author: true },   // with dentro de with — o autor de cada comentário
    },
  },
})
```

Com `limit` no nível aninhado:

```ts
const posts2 = await db.query.posts.findMany({
  with: {
    comments: { limit: 3 },
  },
})
```

`findFirst` é a mesma API com `LIMIT 1` aplicado — o caso comum de "busca um post pelo id, com o autor":

```ts
const post = await db.query.posts.findFirst({
  where: (posts, { eq }) => eq(posts.id, postId),
  with: { author: true },
})
// post é o objeto ou undefined — não um array de um elemento
```

### 5.2 `columns` — seleção parcial

```ts
await db.query.posts.findMany({
  columns: { id: true, content: true },
  with: { comments: true },
})
```

**Quando `true` e `false` coexistem no mesmo `columns`, os `false` são ignorados** — a doc é explícita: misturar os dois modos não faz sentido e o include vence.

### 5.3 `where` — sintaxe de callback com operadores

```ts
await db.query.users.findMany({
  where: (users, { eq }) => eq(users.id, 1),
})
```

**Isto é diferente do `where` do query builder de select.** Lá os operadores (`eq`, `and`...) vêm de `import { eq } from 'drizzle-orm'`. Aqui, a **callback recebe os operadores como segundo argumento** — não é preciso importar nada além do necessário para compor a lógica em volta. Confundir os dois estilos é o erro mais comum ao migrar de select para RQB.

### 5.4 `orderBy`, `limit`, `offset`

```ts
await db.query.posts.findMany({
  orderBy: (posts, { asc }) => [asc(posts.id)],
  limit: 5,
  offset: 2,
})
```

**`offset` só existe no nível raiz.** Um `with.comments.offset` não é aceito — só `limit` desce para relações aninhadas.

### 5.5 `extras` — campo computado

```ts
await db.query.users.findMany({
  extras: {
    loweredName: (table) => sql`lower(${table.name})`.as('lowered_name'),
  },
})
```

`.as()` é obrigatório aqui — sem ele o campo computado não tem nome de coluna no resultado.

### 5.6 A garantia de performance

A doc afirma, e é o motivo de a API existir: **"Drizzle relational queries sempre geram exatamente uma instrução SQL"**, e faz seleção parcial no nível da query — nenhum dado a mais que o pedido trafega da rede do banco até a aplicação, mesmo com `with` aninhado três níveis. É o oposto do problema clássico de N+1 de ORMs com lazy loading.

### 5.7 Prepared statements

```ts
const prepared = db.query.users.findMany({
  where: (users, { eq }) => eq(users.id, sql.placeholder('id')),
}).prepare('buscar_usuario')

await prepared.execute({ id: 1 })
```

`where`, `limit` e `offset` aceitam `sql.placeholder(nome)` — a query é compilada uma vez e reutilizada com parâmetros diferentes.

### 5.8 Regras — `DRZ-RQB-*`

| ID | Regra |
| --- | --- |
| `DRZ-RQB-01` | Busca que aninha mais de uma tabela relacionada **MUST** usar `db.query.tabela.findMany`/`findFirst` com `with`, **NEVER** N chamadas separadas — RQB garante uma única query SQL. |
| `DRZ-RQB-02` | `offset` **MUST** ficar só no nível raiz — não existe em `with` aninhado. |
| `DRZ-RQB-03` | O `where` de RQB **NEVER** importa `eq`/`and` do módulo `drizzle-orm` — os operadores chegam pelo segundo argumento da própria callback. |
| `DRZ-RQB-04` | Campo computado em `extras` **MUST** ter `.as()` — sem nome de coluna, o resultado não expõe o campo. |
| `DRZ-RQB-05` | Query repetida com parâmetros variáveis (endpoint de alto tráfego) **MUST** considerar `.prepare()` com `sql.placeholder`. |

---

## 6. `drizzle-zod`: schema Zod a partir da tabela

```bash
npm i drizzle-zod
```

```ts
import { createSelectSchema, createInsertSchema, createUpdateSchema } from 'drizzle-zod'

const userSelectSchema = createSelectSchema(users)
const userInsertSchema = createInsertSchema(users)
const userUpdateSchema = createUpdateSchema(users)
```

Cada função deriva o schema Zod diretamente das colunas da tabela — nome, tipo, nulidade e default já vêm certos, sem reescrever o shape à mão.

```ts
// validar o que a rota recebe, antes de inserir
const parsed = userInsertSchema.parse(req.body)
await db.insert(users).values(parsed)

// validar o que a rota recebe, antes de atualizar (campos gerados não são atualizáveis)
function atualizarUsuario(userId: number, body: unknown) {
  const parsedUpdate = userUpdateSchema.parse(body)
  return db.update(users).set(parsedUpdate).where(eq(users.id, userId))
}
```

### 6.1 Refinar uma regra

```ts
import { z } from 'zod'
import { createInsertSchema } from 'drizzle-zod'

const userInsertSchema = createInsertSchema(users, {
  name: (schema) => schema.max(20),               // estende a regra gerada
  preferences: z.object({ theme: z.string() }),    // substitui inteiro
})
```

Segundo argumento por coluna: uma função recebe o schema gerado e o estende; um schema Zod puro substitui.

### 6.2 Regras — `DRZ-ZOD-*`

| ID | Regra |
| --- | --- |
| `DRZ-ZOD-01` | Validação de linha de tabela **MUST** derivar de `createInsertSchema`/`createSelectSchema`/`createUpdateSchema`, **NEVER** um schema Zod escrito à mão duplicando as colunas. |
| `DRZ-ZOD-02` | Regra adicional sobre um campo gerado **MUST** usar o segundo argumento de `create*Schema`, **NEVER** um `.extend()`/`.merge()` manual por fora. |

> **Nota de versão, não regra:** `drizzle-zod` está marcado como deprecado a partir da v1 do `drizzle-orm` (`1.0.0-beta.15`), que passa a gerar schema nativamente. Isso **não muda nada hoje** — `drizzle-zod@0.8.x` continua sendo a resposta certa enquanto o projeto estiver na linha estável. Ver [Drizzle ORM](drizzle-orm.md) § 0.1.

---

## 7. Antipadrões

| Antipadrão | Correção |
| --- | --- |
| `SELECT *` implícito quando a ordem de colunas importa | listar campos explícitos · `DRZ-QUERY-01` |
| Filtro concatenado dentro de `sql` | `eq`/`and`/`or` · `DRZ-QUERY-02` |
| `update`/`delete` sem `where`, sem confirmação de que é intencional | revisar antes de rodar · `DRZ-QUERY-04` |
| `set({ campo: undefined })` esperando limpar o valor | `null` explícito · `DRZ-QUERY-05` |
| `select` + `insert`/`update` condicional em duas chamadas para simular upsert | `onConflictDoUpdate`/`DoNothing` · `DRZ-QUERY-06` |
| Duas escritas relacionadas fora de `db.transaction` | envolver na mesma transaction · `DRZ-TX-01` |
| `throw` só para provocar rollback sem erro real | `tx.rollback()` · `DRZ-TX-02` |
| Chamar `db` em vez de `tx` dentro de uma transaction | usar `tx` em tudo · `DRZ-TX-03` |
| `many()` de um lado sem `one()`/`fields`/`references` do outro | declarar os dois lados · `DRZ-REL-01`/`DRZ-REL-02` |
| Tentar `with` direto entre duas tabelas ligadas só por junção | passar pela tabela de junção · `DRZ-REL-03` |
| Duas relações mesmas tabelas sem `relationName` | nomear os dois lados · `DRZ-REL-04` |
| `drizzle(client, { schema: tabelas })` sem as relations | incluir os `relations()` no schema · `DRZ-REL-05` |
| N chamadas de query builder para montar uma árvore de relação | `db.query....findMany({ with })` · `DRZ-RQB-01` |
| `import { eq } from 'drizzle-orm'` dentro do `where` de RQB | usar o operador da própria callback · `DRZ-RQB-03` |
| Schema Zod de tabela escrito à mão | `createInsertSchema`/`createSelectSchema` · `DRZ-ZOD-01` |

---

## Relacionados

- [Drizzle ORM](drizzle-orm.md) — entrada, § 0 sobre qual versão esta doc documenta
- [Drizzle - Schema e Migrations](drizzle-schema-e-migrations.md) — schema e `drizzle-kit`
- [Zod - Validação de Ambiente](zod-validacao-de-ambiente.md) · [React Hook Form - Validação e Resolvers](react-hook-form-validacao-e-resolvers.md) — o mesmo Zod, outra fronteira
- [Hono - Validação e RPC](hono-validacao-e-rpc.md) · [Elysia - Schema e Eden](elysia-schema-e-eden.md) — onde `createInsertSchema` alimenta a validação de rota

## Fontes consultadas

Snapshot do repositório `drizzle-team/drizzle-orm-docs`, commit `3e7fe1b3` (2026-03-21, o mais próximo da tag `drizzle-orm@0.45.2`, publicada em 2026-03-27), verificado em 2026-08-16:

- `select.mdx` · `insert.mdx` · `update.mdx` · `delete.mdx` — query builder completo
- `transactions.mdx` — `db.transaction`, `tx.rollback()`, savepoints, isolamento por dialeto
- `relations.mdx` — `relations()` com `one`/`many`, muitos-para-muitos, `relationName` — **API estável, confirmada contra `relations.d.ts` de `drizzle-orm@0.45.2` via unpkg**
- `rqb.mdx` — `db.query`, `with`, `columns`, `where` callback, `orderBy`, `extras`, prepared statements
- `zod.mdx` — `createSelectSchema`/`createInsertSchema`/`createUpdateSchema`, refinamento, e o aviso de depreciação a partir de `1.0.0-beta.15`

Ver [Drizzle ORM](drizzle-orm.md) § 0 para a ressalva sobre a doc ao vivo estar na linha v1-rc (`defineRelations()`, `where` por objeto) nestas mesmas URLs.
