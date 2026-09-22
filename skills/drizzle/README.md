# Skills de Drizzle

Uma skill, por enquanto: **revisão**. Não há skill de construção — para escrever schema ou
query nova, as árvores de [[Drizzle ORM]] § 5 são consultadas direto.

| Skill | A pergunta que responde | Fonte | Apoio interno |
| --- | --- | --- | --- |
| [[drizzle-review]] | esta camada de persistência tem defeito? | [[Drizzle ORM]] | 6 referências + 2 scripts |

## O que o pacote acrescentou

A skill descrevia **quatro** sondas em tabela. O script roda onze: as quatro originais mais
sete que a varredura pedia e não tinha comando.

| Sonda extra | Regra |
| --- | --- |
| query dentro de `map`/`for` | `DRZ-RQB-01` — o achado mais comum e o mais caro |
| `update`/`delete` sem `where` | `DRZ-QUERY-04` — bloqueante, e uma linha o produz |
| `sql\`\`` com interpolação | `DRZ-QUERY-03` — vira **segurança** quando o valor vem do usuário |
| `db` externo dentro de `transaction` | `DRZ-TX-03` — a escrita sai da transação sem erro |
| `push` fora do local | `DRZ-MIG-02`, `DRZ-MIG-04` |
| `.default()` com valor computado | `DRZ-SCHEMA-04` — o valor congela no SQL da migração |
| Zod à mão | `DRZ-ZOD-01` |

**A sonda S1 continua sendo a parada obrigatória:** o script imprime **as duas listas** — o
que é exportado como `pgTable`/`relations` e o que é registrado em `drizzle({ schema })` — e
a comparação é do revisor. Com a API relacional desligada, toda leitura montada à mão é
**consequência**, e criticar cada uma é ruído.

## O mapa de IDs

Gerado por `scripts/gerar-mapa-de-ids.sh`: **32 IDs**, com a coluna **"corpo no satélite"**,
porque `DRZ-CORE-*` é declarada só no hub. `DRZ-SCHEMA-01` é apelido de `DRZ-CORE-02` e não
aparece em revisão.

**As linhas sem ID são deliberadas.** Índice redundante, filtro por faixa sem índice,
expressão sobre coluna e listagem sem teto **não têm `DRZ-*`** — a grade cita a nota
normativa, e inventar ID ali seria pior que não citar.

```bash
bash Skills/drizzle/drizzle-review/scripts/gerar-mapa-de-ids.sh
bash Skills/instalar.sh
```

<!-- tokens:inicio -->
## Orçamento de contexto

Medido por `skill-validator` (tiktoken), em 2026-09-05. **O número que importa é o da
coluna `SKILL.md`**: é o que entra no contexto antes de a skill decidir o que abrir.
As referências carregam sob demanda, uma por vez.

| Skill | `SKILL.md` | maior `references/` | total | refs |
| --- | ---: | --- | ---: | ---: |
| [[drizzle-review]] | 1.471 | `mapa-de-ids.md` (1.401) | 5.688 | 6 |

Carregar as 1 skills deste grupo de uma vez custaria **1.471 tokens** só de `SKILL.md`,
e **5.688** com todas as referências. É por isso que cada skill declara o que **nunca** carregar.

Regenerar: `bash Skills/tokens.sh`
<!-- tokens:fim -->

## Relacionados

- [[Skills/README|Skill — Índice]] · [[Drizzle ORM]] § 7 — o contrato
- [[PostgreSQL]] — o que o ORM não dispensa
- [[Skills/elysia/README|Skills/elysia/]] — a rota que chama o repositório
