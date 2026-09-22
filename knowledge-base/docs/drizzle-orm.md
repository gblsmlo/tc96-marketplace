---
titulo: Drizzle ORM
Link: https://orm.drizzle.team/docs/overview
tags:
 - typescript
 - backend
 - database
 - orm
 - postgresql
 - reference
 - agent-context
source: "Documentação oficial do Drizzle ORM — orm.drizzle.team, cruzada com o snapshot do monorepo na tag npm estável"
verificado-em: 2026-08-16
---
# Drizzle ORM — referência conduzida (fundamentos)

> **O que esta nota é.** O ponto de entrada único para Drizzle ORM neste vault: para mim ao consultar, e para agentes de código ao gerar ou revisar acesso a banco. Não é um resumo linear da doc — é um **roteador**, com o modelo mental que faz o resto fazer sentido e regras citáveis por ID.
>
> **Escopo: fundamentos.** Cobre o suficiente para schema, query builder, relações, transactions e migração corretos. Não é referência exaustiva de todo dialeto, todo driver, nem de MySQL/SQLite/SingleStore/MSSQL — o foco é **PostgreSQL**, o dialeto já documentado em `PostgreSQL` e usado no stack deste vault.
>
> **O que não é.** Não substitui a fonte. Quando houver divergência, [orm.drizzle.team/docs](https://orm.drizzle.team/docs/overview) vence — **com uma ressalva importante, ver § 0**.

Ver [Fontes consultadas](#fontes-consultadas) e, antes de qualquer coisa, [Notas de verificação](#notas-de-verificacao).

---

## 0. Leia isto antes de tudo: qual versão esta doc documenta

**A doc pública ao vivo não está documentando a versão que `npm install drizzle-orm` instala hoje.**

| | O que `npm view drizzle-orm dist-tags` devolve | O que orm.drizzle.team/docs mostra, nas mesmas URLs |
| --- | --- | --- |
| `drizzle-orm` | **0.45.2** (`latest`) | conteúdo de `1.0.0-rc.5` |
| `drizzle-kit` | **0.31.10** (`latest`) | idem |
| `drizzle-zod` | **0.8.3** (`latest`) | idem, com aviso de depreciação |

O site não versiona por caminho — `/docs/rqb` e `/docs/get-started-postgresql` foram **reescritos no lugar** para a linha `v1.0.0-rc`, que instala com `npm i drizzle-orm@rc`. Um agente que consulte a URL ao vivo hoje e escreva código a partir dela produz um projeto que **não compila** contra o que `npm install drizzle-orm` de fato traz.

**Esta doc documenta a API estável (0.45.x / 0.31.x / 0.8.x)** — a que roda em qualquer projeto criado com `npm i drizzle-orm` sem tag. A verificação foi feita cruzando o pacote publicado (via `npm view` e os `.d.ts` em `unpkg`) com o snapshot do repositório de documentação na tag correspondente à data de publicação do 0.45.2. Ver [Notas de verificação](#notas-de-verificacao) para o detalhe de cada divergência e o que muda na v1.

> **Antes de seguir qualquer link desta doc para orm.drizzle.team**: confirme que o projeto não está na tag `@rc`/`@beta`. Se estiver, a API de relations desta nota **não se aplica** — ver § 0.1.

### 0.1 O que muda na v1, resumido

A mudança que quebra código, não cosmética: a API de **relations** foi reescrita.

| | Estável (esta doc) | v1 (rc) |
| --- | --- | --- |
| Declarar relação | `relations(tabela, ({ one, many }) => ({...}))`, uma chamada por tabela | `defineRelations(schema, (r) => ({...}))`, um único lugar |
| Filtro em RQB | `where: (t, { eq }) => eq(t.col, v)` — callback com operadores | `where: { col: { eq: v } }` — objeto |
| `drizzle-zod` | pacote separado, atual | **deprecado** — geração de schema passa a ser nativa do `drizzle-orm` |

Se o projeto atualizar para `v1` no futuro, os satélites [Drizzle - Schema e Migrations](drizzle-schema-e-migrations.md) e [Drizzle - Queries e Relations](drizzle-queries-e-relations.md) precisam ser revisados na seção de relations e RQB — o resto (schema declaration, query builder de select/insert/update/delete, transactions) diverge pouco.

---

## 1. Como usar esta doc

### Para um humano

Leia a § 2 uma vez. Use a § 5 quando estiver em dúvida entre duas formas de escrever uma query. A § 4 é índice.

### Para um agente de código

| Passo | Carregar | Quando |
| --- | --- | --- |
| 1 | Esta nota (§ 2, § 5, § 6) | Sempre que a tarefa envolver Drizzle |
| 2 | [Drizzle - Schema e Migrations](drizzle-schema-e-migrations.md) | Ao declarar tabela, coluna, índice, ou rodar `drizzle-kit` |
| 3 | [Drizzle - Queries e Relations](drizzle-queries-e-relations.md) | Ao escrever select/insert/update/delete, relação entre tabelas, ou transaction |

**Regra de economia de contexto:** não abra um satélite antes de saber, pela § 5, que precisa dele.

---

## 2. Modelo mental

Quatro afirmações.

**1. Drizzle não é um framework de dados — é uma camada fina sobre SQL.** A frase da própria doc é literal: *"se você sabe SQL, você sabe Drizzle"*. Ele não introduz uma linguagem de query própria (como o `where: { AND: [...] }` do Prisma) — o que se escreve é composição de funções que geram SQL, e o resultado é previsível porque é **quase SQL com tipos**. Isso é o oposto do Prisma: lá se aprende a API do Prisma além de SQL; aqui, o conhecimento de SQL transfere direto.

**2. Existem duas APIs, e elas resolvem problemas diferentes.** (A partir daqui, **RQB** = Relational Queries — a sigla que os IDs `DRZ-RQB-*` usam.) O *query builder* (`db.select.from(...)`) é SQL explícito — controle total, um `JOIN` por vez, visível na query gerada. As *Relational Queries* (`db.query.tabela.findMany({ with: {...} })`) resolvem o caso comum de buscar uma entidade com suas relações aninhadas, **sempre em uma única query SQL** — mesmo que o resultado pareça N tabelas aninhadas em JSON. A doc chama isso de propriedade central para banco serverless, onde cada round-trip custa latência de rede.

**3. O schema TypeScript é a fonte da verdade — e migração é uma escolha, não uma obrigação.** `drizzle-kit generate` compara o schema declarado contra o histórico de migrações e escreve SQL; `drizzle-kit push` aplica a diferença direto, sem arquivo. São dois fluxos legítimos para momentos diferentes do projeto, não um certo e um errado. Ver § 5.3.

**4. Nada acontece que não esteja no SQL gerado.** Sem lazy loading, sem N+1 escondido, sem query disparada por acessar uma propriedade. Uma relação só é buscada se estiver em `with`; um `JOIN` só existe se foi escrito. O preço dessa previsibilidade é que **você** decide a forma da query — a ferramenta não decide por você.

---

## 3. Fronteiras de pacote

| Pacote | Contém | Nota |
| --- | --- | --- |
| `drizzle-orm` | schema, query builder, RQB, `relations`, transactions — o runtime | zero dependências; import por dialeto (`drizzle-orm/pg-core`) e por driver (`drizzle-orm/node-postgres`) |
| `drizzle-kit` | CLI de migração: `generate`, `migrate`, `push`, `pull`, `studio`, `check`, `up` | dev dependency; não entra no bundle de produção |
| `drizzle-zod` | `createSelectSchema`/`createInsertSchema`/`createUpdateSchema` a partir de uma tabela | **pacote separado, com aviso de depreciação para a v1** — ver § 0.1 e [Drizzle - Queries e Relations](drizzle-queries-e-relations.md) § 6 |

```bash
npm i drizzle-orm pg
npm i -D drizzle-kit @types/pg
```

Este comando instala a linha estável. **`@rc`/`@beta` instalam a v1** e a API de relations desta doc não se aplica a eles.

---

## 4. Mapa da API

| Área | Cobre | Satélite |
| --- | --- | --- |
| Conexão | `drizzle(url)`, `drizzle({ connection })`, `drizzle({ client })` | esta nota § 8, logo abaixo |
| Declaração de schema | `pgTable`, tipos de coluna, modificadores, índices, enums, multi-schema | [Drizzle - Schema e Migrations](drizzle-schema-e-migrations.md) |
| Migração | `drizzle-kit generate`/`migrate`/`push`/`pull`, `drizzle.config.ts`, `migrate` em runtime | [Drizzle - Schema e Migrations](drizzle-schema-e-migrations.md) |
| Query builder | `select`/`insert`/`update`/`delete`, `where`, joins, agregação, CTE, upsert | [Drizzle - Queries e Relations](drizzle-queries-e-relations.md) |
| Relações | `relations`, `one`/`many`, muitos-para-muitos, `relationName` | [Drizzle - Queries e Relations](drizzle-queries-e-relations.md) |
| Relational Queries | `db.query.tabela.findMany`/`findFirst`, `with`, `columns`, `where` callback, `extras` | [Drizzle - Queries e Relations](drizzle-queries-e-relations.md) |
| Transactions | `db.transaction`, `tx.rollback`, savepoints, isolamento | [Drizzle - Queries e Relations](drizzle-queries-e-relations.md) |
| Validação de fronteira | `drizzle-zod` | [Drizzle - Queries e Relations](drizzle-queries-e-relations.md) § 6 |

---

## 5. Árvores de decisão

### 5.1 Query builder ou Relational Queries?

```
A busca precisa de dados de MAIS DE UMA tabela relacionada
(post + autor + comentários, por exemplo)?
├── NÃO → query builder simples. select/insert/update/delete
│ resolvem sozinhos; RQB (Relational Queries, § 2 item 2)
│ não ganha nada aqui.
└── SIM
 └── Você precisa controlar exatamente a forma do JOIN
 (semi-join, self-join, agregação complexa por linha)?
 ├── SIM → query builder com leftJoin/innerJoin explícito
 └── NÃO → db.query.tabela.findMany({ with: {...} })
 Uma query só, resultado já aninhado.
 DRZ-RQB-01
```

### 5.2 Insert simples ou upsert?

```
A chave já pode existir?
├── NÃO → insert.values(...) simples
└── SIM
 └── Ao colidir, o que fazer?
 ├── Ignorar e manter o que já existe
 │ → onConflictDoNothing({ target: coluna })
 ├── Atualizar campos específicos
 │ → onConflictDoUpdate({ target, set: {...} })
 └── Atualizar só se uma condição valer
 → onConflictDoUpdate + targetWhere/setWhere
```

### 5.3 Como migrar: generate+migrate ou push?

Esta é a decisão mais mal-entendida da ferramenta — as duas vias são legítimas, para momentos diferentes.

```
O schema muda várias vezes por dia, sozinho, em protótipo/local?
├── SIM → drizzle-kit push
│ Aplica a diferença direto no banco. Sem arquivo de
│ migração, sem histórico. Rápido, mas sem trilha
│ auditável. DRZ-MIG-01
└── NÃO — vai para staging/produção, ou tem mais de um dev
 → drizzle-kit generate, depois:
 ├── CI/CD roda `drizzle-kit migrate` DRZ-MIG-02
 └── Deploy serverless/monolito
 → migrate chamado no boot da aplicação,
 programaticamente, a partir do runtime. DRZ-MIG-03

Nunca os dois no mesmo ambiente para o mesmo schema — push
e generate divergem sobre o que é "o estado atual". DRZ-MIG-04
```

### 5.4 Preciso validar dado que entra ou sai do banco. Onde?

```
O shape a validar já EXISTE como tabela Drizzle?
├── SIM → createInsertSchema/createSelectSchema/createUpdateSchema
│ de drizzle-zod. Não duplique o shape à mão. DRZ-ZOD-01
│ Precisa refinar uma regra (min, regex)?
│ → segundo argumento da função create*Schema
└── NÃO — é um shape que não é tabela (DTO, filtro de query,
 payload de webhook)
 → Zod puro, como em [Zod - Validação de Ambiente](zod-validacao-de-ambiente.md)
```

---

## 6. Regras normativas

Regras citáveis por ID. `MUST`/`NEVER` são normativos.

### `DRZ-CORE-*` — fundamento

| ID | Regra |
| --- | --- |
| `DRZ-CORE-01` | Código gerado **MUST** assumir a linha estável (`drizzle-orm` sem tag), **NEVER** a API de `defineRelations`/`where` por objeto da v1-rc, salvo confirmação explícita de que o projeto está em `@rc`/`@beta`. |
| `DRZ-CORE-02` | Toda tabela **MUST** ser exportada do módulo de schema — `drizzle-kit` só enxerga o que é exportado. |

### `DRZ-RQB-*` — Relational Queries

| ID | Regra |
| --- | --- |
| `DRZ-RQB-01` | Busca que aninha mais de uma tabela relacionada **MUST** usar `db.query.tabela.findMany`/`findFirst` com `with`, **NEVER** N chamadas separadas — RQB garante uma única query SQL. |
| `DRZ-RQB-02` | `offset` **MUST** ficar só no nível raiz — não existe em `with` aninhado. |

### `DRZ-MIG-*` — migração

| ID | Regra |
| --- | --- |
| `DRZ-MIG-01` | `push` **MUST** ficar restrito a ambiente local/protótipo sem histórico auditável exigido. |
| `DRZ-MIG-02` | Staging e produção **MUST** usar `generate` + `migrate`, **NEVER** `push`. |
| `DRZ-MIG-03` | Em deploy serverless, a migração **MUST** rodar via `migrate` programático no boot. |
| `DRZ-MIG-04` | `push` e `generate`/`migrate` **NEVER** convivem no mesmo ambiente para o mesmo schema. |

### `DRZ-ZOD-*` — fronteira de validação

| ID | Regra |
| --- | --- |
| `DRZ-ZOD-01` | Validação de linha de tabela **MUST** derivar de `createInsertSchema`/`createSelectSchema`/`createUpdateSchema`, **NEVER** um schema Zod escrito à mão duplicando as colunas. |

### Famílias completas nos satélites

`DRZ-SCHEMA-*` · `DRZ-MIG-*` (corpo completo) — [Drizzle - Schema e Migrations](drizzle-schema-e-migrations.md)
`DRZ-QUERY-*` · `DRZ-REL-*` · `DRZ-RQB-*` (corpo completo) · `DRZ-TX-*` · `DRZ-ZOD-*` (corpo completo) — [Drizzle - Queries e Relations](drizzle-queries-e-relations.md)

---

## 7. Contrato de skill

```
SEMPRE: docs/Drizzle ORM.md § 0 (qual versão) — NÃO É OPCIONAL
 § 2 (modelo mental)
 § 5 (árvores de decisão)
 § 6 (regras)

AO DECLARAR SCHEMA ou RODAR drizzle-kit:
 docs/Drizzle - Schema e Migrations.md

AO ESCREVER QUERY, RELAÇÃO ou TRANSACTION:
 docs/Drizzle - Queries e Relations.md

NUNCA: seguir um link para orm.drizzle.team sem confirmar
 que o projeto não está em @rc/@beta primeiro
```

### Invariantes que a skill deve fazer valer

1. **Verificar a versão antes de gerar código.** `package.json` do projeto decide qual API de relations vale — não a doc ao vivo.
2. **A fonte vence, com a ressalva da § 0.** Divergência entre esta nota e a doc **estável** é bug desta nota. Divergência entre esta nota e a doc **ao vivo** pode ser só a v1 se anunciando cedo.
3. **`push` nunca em produção.** `DRZ-MIG-02` é a regra que mais economiza um incidente.
4. **Não duplicar shape de tabela em Zod à mão.** `DRZ-ZOD-01`.

---

## 8. Conectar ao banco

Três formas, as mesmas para `node-postgres` e `postgres-js` — só o subpath de import muda.

```ts
// 1 — string de conexão direta
import { drizzle } from 'drizzle-orm/node-postgres'
const db = drizzle(process.env.DATABASE_URL!)

// 2 — objeto de configuração, quando precisa de opção extra (ssl, por exemplo)
const db = drizzle({
 connection: { connectionString: process.env.DATABASE_URL!, ssl: true },
})

// 3 — driver já instanciado por fora (pool próprio, reuso entre módulos)
import { Pool } from 'pg'
const pool = new Pool({ connectionString: process.env.DATABASE_URL! })
const db = drizzle({ client: pool })
```

A forma 3 é a que se usa quando o projeto já gerencia o `Pool`/client em outro lugar (um singleton de conexão, por exemplo) e só quer que o Drizzle desenhe em cima dele — sem isso, `drizzle(url)` cria e gerencia o pool sozinho.

**Diferença real entre os dois drivers principais, que a doc registra:** `postgres.js` usa **prepared statements por padrão**, o que pode exigir desligar em ambiente AWS/serverless com pooler; `node-postgres` aceita o addon opcional `pg-native` para um ganho de performance.

---

## 9. Pontes com o stack

| Cenário | Uso |
| --- | --- |
| Conexão em runtime Bun | `drizzle-orm/node-postgres` ou `drizzle-orm/postgres-js` funcionam sob Bun; a doc do Bun também documenta um driver nativo — ver [Bun - Dados e Persistência](bun-dados-e-persistencia.md) |
| Backend Hono/Elysia | `db` instanciado uma vez, importado pelos handlers — mesmo padrão de singleton do Prisma em `Prisma` |
| Validação de entrada de rota | `createInsertSchema` alimentando `zValidator`/`t.Object` — mesma fronteira que [Hono - Validação e RPC](hono-validacao-e-rpc.md) e [Elysia - Schema e Eden](elysia-schema-e-eden.md) já documentam para Zod puro |
| Alternativa mais pesada | `Prisma` — camada de abstração maior, migração mais opinativa, sem a filosofia "SQL explícito" |
| Alternativa mais fina | `Knex.js` — query builder sem tipos gerados do schema e sem RQB |

**Por que Drizzle em vez de Prisma neste stack:** [Bun - Dados e Persistência](bun-dados-e-persistencia.md) já registra o critério — "migração e geração de tipos são o que se compra com um ORM", e Drizzle entrega isso "continuando a deixar você escrever SQL", o que combina com a filosofia SQL-first de [HTTP](http.md) e das demais docs deste vault: menos abstração própria, mais controle explícito.

---

## Relacionados

- [Drizzle - Schema e Migrations](drizzle-schema-e-migrations.md) — declarar tabela, `drizzle-kit`
- [Drizzle - Queries e Relations](drizzle-queries-e-relations.md) — query builder, relações, RQB, transactions, `drizzle-zod`
- `PostgreSQL` · [Bun - Dados e Persistência](bun-dados-e-persistencia.md) · `Prisma` · `Knex.js`
- [Zod - Validação de Ambiente](zod-validacao-de-ambiente.md) — o mesmo Zod usado em `drizzle-zod`

## Fontes consultadas

Verificadas em **2026-08-16**:

- [Overview](https://orm.drizzle.team/docs/overview) · [Get Started PostgreSQL](https://orm.drizzle.team/docs/get-started-postgresql) — **conteúdo ao vivo já na linha v1-rc**, ver § 0
- `npm view drizzle-orm dist-tags`, `npm view drizzle-kit dist-tags`, `npm view drizzle-zod dist-tags` — versões estáveis publicadas
- `unpkg.com/drizzle-orm@0.45.2/relations.d.ts` — confirma que o export estável é `relations`, não `defineRelations`
- Snapshot do repositório `drizzle-team/drizzle-orm-docs`, commit `3e7fe1b3` (2026-03-21, mais próximo da tag `0.45.2` de 2026-03-27): `overview.mdx`, `get-started-postgresql.mdx`, `sql-schema-declaration.mdx`, `relations.mdx`, `rqb.mdx`, `select.mdx`, `insert.mdx`, `update.mdx`, `delete.mdx`, `transactions.mdx`, `migrations.mdx`, `kit-overview.mdx`, `zod.mdx`, `relations-v1-v2.mdx` (guia oficial de migração v1→v2, confirma a reescrita da API de relations)

## Notas de verificação

- **A doc ao vivo não é a doc estável.** `orm.drizzle.team/docs/rqb` e `/docs/get-started-postgresql`, acessadas em 2026-08-16, mostram `defineRelations` e `npm i drizzle-orm@rc` — conteúdo da linha `1.0.0-rc.5`. O `npm view drizzle-orm dist-tags` na mesma data mostra `latest: 0.45.2`. O site reescreve as URLs no lugar, sem versionamento por caminho; a única forma confiável de obter o conteúdo estável foi o snapshot do repositório de docs numa tag anterior à mudança.
- **`relations` (minúsculo, com `one`/`many` na callback) é a API que o pacote publicado exporta**, confirmado lendo `relations.d.ts` de `drizzle-orm@0.45.2` via unpkg. `defineRelations` não existe nesse pacote.
- **`drizzle-zod` está marcado como deprecado a partir de `1.0.0-beta.15`**, a favor de geração de schema nativa dentro do próprio `drizzle-orm`. Isso **não afeta o pacote estável hoje** (`drizzle-zod@0.8.3` continua sendo a resposta correta) — é um aviso do que muda quando o projeto migrar para v1.
- **Precedente do mesmo padrão:** a estrutura de Bun já registrou "a doc está à frente do binário publicado" para exemplos rotulados `1.4.0` com `latest` em `1.3.14`. Aqui a divergência é maior — não é atraso de changelog, é a página ativa documentando por padrão uma API com breaking change ainda não publicada como `latest`.
- **Não verificado nesta rodada:** dialetos MySQL, SQLite, SingleStore, MSSQL, CockroachDB; drivers gerenciados (Neon, Supabase, PlanetScale, Xata, Vercel Postgres); `drizzle-kit studio`/`check`/`up` em detalhe; `drizzle-seed`. Fora do escopo de fundamentos combinado.
