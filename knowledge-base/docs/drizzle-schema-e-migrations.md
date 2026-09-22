---
Link: https://orm.drizzle.team/docs/sql-schema-declaration
tags:
 - typescript
 - backend
 - database
 - orm
 - postgresql
 - agent-context
source: "Documentação oficial do Drizzle ORM — schema declaration e drizzle-kit, cruzada com o snapshot pinado na versão estável"
verificado-em: 2026-08-16
---

# Drizzle — Schema e Migrations

> `pgTable` · tipos de coluna · índices · enums · `drizzle-kit generate`/`migrate`/`push`/`pull`
>
> Como o schema é declarado em TypeScript, e como ele vira SQL de verdade no banco.

Entrada: [Drizzle ORM](drizzle-orm.md) · **Confirme a § 0 de lá antes de usar esta nota** — a API aqui é a estável (0.45.x/0.31.x), não a v1-rc.

> **Convenção de import nesta nota.** Os blocos abaixo assumem `pgTable`, `integer`, `varchar`, `timestamp`, `index`, `uniqueIndex`, `primaryKey` já importados de `'drizzle-orm/pg-core'` (§ 1, forma 1), salvo quando o bloco existe justamente para introduzir um import novo (`pgEnum`, `AnyPgColumn`, `pgSchema`) — nesse caso só a linha nova aparece, para não repetir o resto. Cada bloco é uma ilustração independente.

---

## 1. Declarar uma tabela

`pgTable` aceita três formas de importar os tipos de coluna. As três produzem o mesmo resultado — a escolha é estilo.

```ts
// Forma 1 — funções importadas direto
import { pgTable, integer, varchar } from 'drizzle-orm/pg-core'

export const usersTable = pgTable('users', {
 id: integer.primaryKey.generatedAlwaysAsIdentity,
 name: varchar.notNull,
 age: integer.notNull,
 email: varchar.notNull.unique,
})
```

```ts
// Forma 2 — callback com namespace `t`
import { pgTable } from 'drizzle-orm/pg-core'

export const usersTable = pgTable('users', (t) => ({
 id: t.integer.primaryKey.generatedAlwaysAsIdentity,
 name: t.varchar.notNull,
}))
```

```ts
// Forma 3 — wildcard
import * as p from 'drizzle-orm/pg-core'

export const usersTable = p.pgTable('users', { id: p.integer.primaryKey })
```

**A tabela precisa ser exportada.** `drizzle-kit` importa o módulo de schema e lê o que está exportado — uma tabela declarada e não exportada não existe para efeito de migração. `DRZ-CORE-02`.

### 1.1 Nome de coluna: chave TS × nome no banco

Por padrão, a chave do objeto é o nome da coluna no banco.

```ts
name: varchar // coluna "name"
firstName: varchar('first_name') // coluna "first_name" — nome explícito como 1º arg
```

Isso é relevante quando o projeto segue `snake_case` no banco e `camelCase` em TS — declarar todo campo com nome explícito é tedioso, e a alternativa é `casing: 'snake_case'` na configuração do `drizzle-kit` (ver § 3), que converte automaticamente.

### 1.2 Tipos de coluna (PostgreSQL)

| Categoria | Tipos |
| --- | --- |
| Numérico | `serial`, `integer`, `bigint`, `smallint` |

> **Por que os exemplos desta doc usam `integer.primaryKey.generatedAlwaysAsIdentity` e não `serial`.** Os dois geram chave auto-incrementada, mas `serial` é o tipo legado do Postgres (`SERIAL`, por trás das cortinas uma sequence solta, sem `NOT NULL` implícito consistente entre versões); `GENERATED ALWAYS AS IDENTITY` é o padrão SQL moderno (Postgres ≥ 10) e o que a doc oficial recomenda em todo exemplo novo. `serial` continua existindo por compatibilidade com schema antigo ou introspecção (`drizzle-kit pull`) de um banco que já o usa.
| Texto | `varchar`, `text`, `char` |
| Temporal | `timestamp`, `date`, `time` |
| Booleano | `boolean` |
| Outros | `json`, `uuid` |

Todos aceitam nome de coluna como primeiro argumento e configuração como objeto:

```ts
varchar('first_name', { length: 256 })
varchar({ length: 256 }) // sem nome explícito: usa a chave
```

### 1.3 Modificadores encadeáveis

```ts
coluna: tipo
.primaryKey
.notNull
.unique
.default(valor)
.$default( => calcularEmRuntime)
.references( => outraTabela.id)
.generatedAlwaysAsIdentity
```

**`.references` entre duas tabelas normais** — o caso comum, fora da autorreferência da § 1.6:

```ts
export const users = pgTable('users', {
 id: integer.primaryKey.generatedAlwaysAsIdentity,
})

export const posts = pgTable('posts', {
 id: integer.primaryKey.generatedAlwaysAsIdentity,
 authorId: integer.notNull.references( => users.id),
})
```

Sem anotação de tipo — `AnyPgColumn` só é necessário quando a tabela referencia **a si mesma** (§ 1.6), porque aí a inferência de tipo do TypeScript ainda não terminou de resolver `users` no momento em que `users` é usado dentro de si.

`.references` cria a foreign key. `.$default` roda no cliente, no momento do insert — diferente de `.default`, que vira `DEFAULT` no SQL e roda no banco.

### 1.4 Índices e chaves compostas

Declarados numa função de segundo argumento, que recebe a tabela e devolve um array:

```ts
export const posts = pgTable('posts', {
 id: integer.primaryKey,
 slug: varchar.notNull,
 title: varchar({ length: 256 }),
}, (table) => [
 uniqueIndex('slug_idx').on(table.slug),
 index('title_idx').on(table.title),
])
```

Chave primária composta segue o mesmo lugar:

```ts
export const composite = pgTable('composite', {
 col1: integer,
 col2: varchar,
}, (table) => [
 primaryKey({ columns: [table.col1, table.col2] }),
])
```

### 1.5 Enum do Postgres

```ts
import { pgEnum } from 'drizzle-orm/pg-core'

export const rolesEnum = pgEnum('roles', ['guest', 'user', 'admin'])

export const users = pgTable('users', {
 role: rolesEnum.default('guest'),
})
```

O enum é um tipo de banco de verdade (`CREATE TYPE roles AS ENUM (...)`), não uma checagem só em TypeScript — `drizzle-kit generate` gera a migração do tipo.

### 1.6 Chave estrangeira autorreferente

Uma tabela que referencia a si mesma precisa de anotação de tipo explícita, porque a referência ocorre antes de `users` terminar de ser inferido:

```ts
import type { AnyPgColumn } from 'drizzle-orm/pg-core'

export const users = pgTable('users', {
 id: integer.primaryKey.generatedAlwaysAsIdentity,
 invitedBy: integer.references(: AnyPgColumn => users.id),
})
```

### 1.7 Colunas reutilizáveis

Um objeto plano de colunas pode ser espalhado em várias tabelas — é o `timestamps` que toda tabela normalmente quer:

```ts
export const timestamps = {
 createdAt: timestamp.defaultNow.notNull,
 updatedAt: timestamp,
 deletedAt: timestamp,
}

export const users = pgTable('users', {
 id: integer.primaryKey,
...timestamps,
})
```

### 1.8 Múltiplos schemas do Postgres

Quando o banco organiza tabelas em schemas (`public`, `auth`, `billing`...):

```ts
import { pgSchema } from 'drizzle-orm/pg-core'

export const authSchema = pgSchema('auth')

export const users = authSchema.table('users', {
 id: integer.primaryKey,
})
```

### 1.9 Organização de arquivos

O `drizzle.config.ts` aponta para o schema de duas formas:

```ts
schema: './src/db/schema.ts' // um arquivo
schema: './src/db/schema' // uma pasta — drizzle-kit lê todo export dela recursivamente
```

Para um projeto pequeno, um arquivo. Para muitas tabelas, a pasta evita um arquivo de milhares de linhas — sem exigir um `index.ts` reexportando tudo manualmente, já que `drizzle-kit` varre a pasta.

### 1.10 Regras — `DRZ-SCHEMA-*`

| ID | Regra |
| --- | --- |
| `DRZ-SCHEMA-01` | Toda tabela **MUST** ser exportada — `drizzle-kit` só enxerga export. Apelido de `DRZ-CORE-02`. |
| `DRZ-SCHEMA-02` | Chave estrangeira autorreferente **MUST** anotar o tipo de retorno como `AnyPgColumn`, senão o TypeScript não resolve a referência circular. |
| `DRZ-SCHEMA-03` | Coluna repetida em várias tabelas (timestamps, soft delete) **MUST** ser extraída como objeto reutilizável e espalhada, **NEVER** redeclarada em cada tabela. |
| `DRZ-SCHEMA-04` | `.default` (SQL, roda no banco) e `.$default` (TS, roda no cliente) **NEVER** são confundidos — mudam onde o valor é calculado e o que aparece na migração gerada. |

---

## 2. `drizzle-kit`: o que cada comando faz

| Comando | Faz |
| --- | --- |
| `generate` | Compara o schema TS contra o histórico de migrações e escreve `migration.sql` + `snapshot.json` numa pasta com timestamp |
| `migrate` | Aplica os arquivos de migração ainda não aplicados, comparando contra uma tabela de histórico no banco |
| `push` | Aplica a diferença **direto** no banco, sem gerar arquivo — introspecta o schema atual, compara, altera |
| `pull` | Introspecta um banco existente e escreve o schema TypeScript correspondente |
| `studio` | Sobe um proxy local que alimenta o Drizzle Studio (GUI de navegação de dados) |
| `check` | Varre as migrações geradas procurando colisão ou condição de corrida entre elas |
| `up` | Atualiza o formato de snapshots de migrações antigas para o formato atual do `drizzle-kit` |

### 2.1 `drizzle.config.ts`

```ts
import { defineConfig } from 'drizzle-kit'

export default defineConfig({
 dialect: 'postgresql',
 schema: './src/db/schema.ts',
 out: './drizzle',
 dbCredentials: {
 url: process.env.DATABASE_URL!,
 },
 casing: 'snake_case', // converte camelCase (TS) → snake_case (banco) automaticamente
})
```

`dialect` e `schema` são as únicas opções obrigatórias — o resto tem default sensato. `casing` é o que evita escrever `varchar('first_name')` em toda coluna quando a convenção do banco é `snake_case` e a do TS é `camelCase`.

### 2.2 Dois fluxos de trabalho, para dois momentos

A doc é explícita: `drizzle-kit` foi desenhado para deixar você escolher, e as duas formas são legítimas.

**Fluxo A — `push`, para prototipagem.**

```bash
npx drizzle-kit push
```

Sem arquivo de migração, sem trilha auditável. Rápido para quando o schema muda várias vezes ao dia e não há segunda pessoa nem ambiente compartilhado dependendo do histórico.

**Fluxo B — `generate` + `migrate`, para staging/produção.**

```bash
npx drizzle-kit generate # escreve drizzle/0000_nome/migration.sql
npx drizzle-kit migrate # aplica os arquivos pendentes
```

Deixa um histórico revisável em PR — o arquivo `.sql` gerado pode ser lido antes de ir para produção, o que `push` não oferece.

**Fluxo C — migração programática, para deploy serverless.**

```ts
import { drizzle } from 'drizzle-orm/node-postgres'
import { migrate } from 'drizzle-orm/node-postgres/migrator'

const db = drizzle(process.env.DATABASE_URL!)
await migrate(db, { migrationsFolder: './drizzle' })
```

Roda a partir do próprio código, no boot da aplicação — sem depender de alguém rodar um CLI manualmente após o deploy. É a forma comum em ambiente onde não há um passo de CI separado para migração.

### 2.3 Por que não misturar

`push` e `generate`/`migrate` divergem sobre **o que é o estado atual**: `push` compara contra o banco ao vivo; `generate` compara contra o histórico de arquivos. Usar os dois no mesmo ambiente para o mesmo schema produz migração gerada que já foi aplicada por `push`, ou `push` desfazendo uma coluna que uma migração pendente ainda ia criar.

### 2.4 Regras — `DRZ-MIG-*`

| ID | Regra |
| --- | --- |
| `DRZ-MIG-01` | `push` **MUST** ficar restrito a ambiente local/protótipo sem histórico auditável exigido. |
| `DRZ-MIG-02` | Staging e produção **MUST** usar `generate` + `migrate`, **NEVER** `push`. |
| `DRZ-MIG-03` | Em deploy serverless, a migração **MUST** rodar via `migrate` programático no boot. |
| `DRZ-MIG-04` | `push` e `generate`/`migrate` **NEVER** convivem no mesmo ambiente para o mesmo schema. |
| `DRZ-MIG-05` | Toda tabela `pgEnum` **MUST** ser tratada como mudança de schema real — alterar valores do enum entra na mesma disciplina de `generate`/`migrate`, não é só TypeScript. |

---

## 3. Antipadrões

| Antipadrão | Correção |
| --- | --- |
| Tabela declarada sem `export` | exportar — `DRZ-SCHEMA-01` |
| `varchar('first_name')` repetido em todo campo por convenção de caso | `casing: 'snake_case'` no config |
| Timestamps redeclarados em cada tabela | objeto reutilizável espalhado · `DRZ-SCHEMA-03` |
| `.default` quando a intenção era calcular no cliente | `.$default` · `DRZ-SCHEMA-04` |
| `push` em produção | `generate` + `migrate` · `DRZ-MIG-02` |
| `push` e `generate` alternados no mesmo ambiente | escolher um fluxo · `DRZ-MIG-04` |
| Chave estrangeira autorreferente sem `AnyPgColumn` | anotar o tipo · `DRZ-SCHEMA-02` |

---

## Relacionados

- [Drizzle ORM](drizzle-orm.md) — entrada, § 0 sobre qual versão esta doc documenta
- [Drizzle - Queries e Relations](drizzle-queries-e-relations.md) — o que fazer com o schema depois de declarado
- `PostgreSQL`

## Fontes consultadas

Snapshot do repositório `drizzle-team/drizzle-orm-docs`, commit `3e7fe1b3` (2026-03-21, o mais próximo da tag `drizzle-orm@0.45.2`, publicada em 2026-03-27), verificado em 2026-08-16:

- `sql-schema-declaration.mdx` — as três formas de import, tipos de coluna, modificadores, índices, chave composta, autorreferência, `pgSchema`, colunas reutilizáveis
- `migrations.mdx` — os fluxos de trabalho e a distinção database-first × codebase-first
- `kit-overview.mdx` — a tabela de comandos e o `drizzle.config.ts`

Ver [Drizzle ORM](drizzle-orm.md) § 0 para a ressalva sobre a doc ao vivo estar na linha v1-rc nestas mesmas URLs.
