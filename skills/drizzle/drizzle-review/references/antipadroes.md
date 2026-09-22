# Antipadrões mais frequentes, com ID

> Confira em `mapa-de-ids.md`: `DRZ-SCHEMA-01` é apelido de `DRZ-CORE-02`.
> As linhas **sem ID** citam a nota normativa, nunca um `DRZ-*` inventado.

| Antipadrão | ID canônico | Satélite |
| --- | --- | --- |
| `drizzle({ schema })` sem os `relations` — `with` lança em runtime | `DRZ-REL-05` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| Tabela exportada mas ausente do objeto de schema do cliente | `DRZ-CORE-02` (adjacente; ver Passo 6) | [Drizzle - Schema e Migrations](../../../../knowledge-base/docs/drizzle-schema-e-migrations.md) |
| Relação declarada de um lado só | `DRZ-REL-01` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| Duas relações entre as mesmas tabelas sem `relationName` | `DRZ-REL-04` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| Uma query por item dentro de `map`/`for` | `DRZ-RQB-01` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| `offset` dentro de `with` aninhado | `DRZ-RQB-02` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| `eq`/`and` importados dentro do `where` de RQB | `DRZ-RQB-03` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| Escritas atômicas fora de uma transaction comum | `DRZ-TX-01` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| `db` externo usado dentro do bloco de transaction | `DRZ-TX-03` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| `update`/`delete` sem `where` | `DRZ-QUERY-04` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| `select` seguido de `insert`/`update` condicional em vez de upsert | `DRZ-QUERY-06` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| `undefined` usado para limpar campo (o `set` ignora) | `DRZ-QUERY-05` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| ``sql`...` `` como via padrão de filtro | `DRZ-QUERY-03` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| `select` sem projeção onde o subconjunto importa | `DRZ-QUERY-01` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| Zod escrito à mão duplicando colunas | `DRZ-ZOD-01` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| Regra extra por `.extend` em vez do 2º argumento de `create*Schema` | `DRZ-ZOD-02` | [Drizzle - Queries e Relations](../../../../knowledge-base/docs/drizzle-queries-e-relations.md) |
| `push` em staging ou produção | `DRZ-MIG-02` | [Drizzle - Schema e Migrations](../../../../knowledge-base/docs/drizzle-schema-e-migrations.md) |
| `push` e `generate` convivendo no mesmo ambiente | `DRZ-MIG-04` | [Drizzle - Schema e Migrations](../../../../knowledge-base/docs/drizzle-schema-e-migrations.md) |
| `.default` confundido com `.$default` | `DRZ-SCHEMA-04` | [Drizzle - Schema e Migrations](../../../../knowledge-base/docs/drizzle-schema-e-migrations.md) |
| FK autorreferente sem `AnyPgColumn` | `DRZ-SCHEMA-02` | [Drizzle - Schema e Migrations](../../../../knowledge-base/docs/drizzle-schema-e-migrations.md) |
| Snapshot não atualizado por migração escrita à mão | sem ID — ver Passo 6 | |
| Índice prefixo estrito de outro índice | sem ID — ver Passo 6 | — |
| Filtro por faixa de data sem índice que o cubra | sem ID — ver Passo 6 | — |
| Expressão sobre coluna no predicado (`split_part`, `lower`) | sem ID — ver Passo 6 | — |
| Listagem sem `limit` em tela de volume aberto | sem ID — ver Passo 6 | |
| `updated_at` mantido por disciplina, sem `$onUpdate` nem trigger | sem ID — ver Passo 6 | [Drizzle - Schema e Migrations](../../../../knowledge-base/docs/drizzle-schema-e-migrations.md) |

