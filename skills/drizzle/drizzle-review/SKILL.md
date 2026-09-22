---
name: drizzle-review
description: Revisar uma camada de persistência Drizzle e PostgreSQL que já existe, citando IDs `DRZ-*`, com onze sondas executáveis para os defeitos que a leitura de código não encontra — use quando a tarefa for revisar schema, migrações, repositórios ou queries, conferir se a migração aplicada corresponde ao schema, achar N+1, escrita sem `where` ou interpolação em SQL cru, ou confirmar a linha de versão do pacote antes de codar. Não use para escrever schema ou query nova — siga as árvores de decisão de Drizzle ORM § 5 direto, porque ainda não existe skill de construção.
tags:
  - skill
  - drizzle
  - database
fonte: "[[Drizzle ORM]]"
---

# drizzle-review

> **Fonte desta skill:** [[Drizzle ORM]], que é o hub e também a nota normativa — `DRZ-CORE-*` mora na § 6 dela, e os corpos das demais famílias nos dois satélites.
> Esta skill **não contém** o texto das regras — ela diz o que executar, em que ordem varrer e como reportar.

Contrato que esta skill implementa: [[Drizzle ORM]] § 7 ("Contrato de skill").

---

## Quando usar

Revisar persistência que **já existe**: schema, migrações, repositórios, queries.

| Situação | Vá para |
| --- | --- |
| escrever schema ou query nova | [[Drizzle ORM]] § 5, direto — **não há skill de construção ainda** |
| modelagem, índice, constraint, RLS no banco | [[PostgreSQL]] |
| a rota que chama o repositório | [[elysia-build]] |
| a suíte que deveria cobrir isso | [[bun-test-review]] · [[test-review]] |
| o contrato HTTP que a rota expõe | [[http-review]] |

---

## Carregamento mínimo

| Ordem | Carregar | Por quê |
| --- | --- | --- |
| 1 | [[Drizzle ORM]] § 0 | **não é opcional** — o `package.json` do projeto decide qual API de relations vale, não a doc ao vivo |
| 2 | [[Drizzle ORM]] § 6 | as regras citáveis e a tabela de famílias |
| 3 | [[Drizzle ORM]] § 2 e § 5 | modelo mental e árvores, para separar "errado" de "diferente" |
| 4 | [[Drizzle - Schema e Migrations]] | só quando o achado toca tabela, índice ou `drizzle-kit` |
| 5 | [[Drizzle - Queries e Relations]] | só quando o achado toca query, `relations()`, RQB ou transaction |

**Nunca carregue os dois satélites por padrão.**

Referências desta skill:

| Arquivo | Para quê |
| --- | --- |
| `references/sondas.md` | as quatro sondas da doc, mais as sete que o script acrescenta |
| `references/varredura-e-severidade.md` | a ordem por frequência de falha, e a classificação |
| `references/relatorio-e-corte.md` | formato do achado, e o que **não** é achado |
| `references/antipadroes.md` | a grade com ID — e as linhas **sem ID**, que citam a nota |
| `references/fechamento.md` | transformar sonda em teste, e o que exige decisão de produto |
| `references/mapa-de-ids.md` | os 32 `DRZ-*`: declaração, satélite do corpo e seção |
| `scripts/sondas.sh` | roda as onze |
| `scripts/gerar-mapa-de-ids.sh` | regenera o mapa a partir de `Docs/Drizzle*` |

---

## Passo 1 — Sondar antes de ler

```bash
bash ~/.claude/skills/drizzle-review/scripts/sondas.sh src
```

**S1 é a parada obrigatória:** se o objeto passado a `drizzle({ schema })` não contém os `relations()`, `with` lança em runtime e `db.query.x` é `undefined` (`DRZ-REL-05`). Com a API relacional desligada, **toda leitura montada à mão é consequência** — criticar cada uma é ruído.

O script imprime as duas listas — o que é exportado e o que é registrado — e a comparação é sua.

**S0 vem antes de tudo:** a linha de versão no `package.json` decide qual API de relations vale.

---

## Passo 2 — Varrer na ordem que falha mais

`references/varredura-e-severidade.md`: fronteira do cliente e do schema → migração → leituras que multiplicam query → leituras sem teto → índice × predicado → escrita e transaction → projeção e SQL cru → validação de fronteira.

**`DRZ-RQB-01` é a regra que mais paga:** uma leitura por item dentro de `map`/`for` é o achado mais comum e o mais caro.

---

## Passo 3 — Classificar e reportar

Bloqueante: perda de isolamento entre tenants, `update`/`delete` sem `where` (`DRZ-QUERY-04`), `push` em produção (`DRZ-MIG-02`), migração destrutiva sem rollback.

**Custo medido vence custo suposto.** "Isso pode ficar lento" sem número nem plano de execução é Baixa, não Média.

Formato de quatro partes, com `arquivo:linha`. Para sonda, **cole a saída do script**.

---

## Passo 4 — Fechar

1. **Transforme sonda em teste.** S1, S2 e S3 viram teste que falha na regressão: exports × schema registrado, journal × snapshots, índice × prefixo.
2. **Verifique se o banco já resolve** — `CHECK`, unique parcial, exclusion constraint, RLS — antes de propor invariante na aplicação.
3. **Separe o que exige decisão de produto.** Teto de listagem e política de retenção não são bug até alguém decidir. Reporte como **pergunta com opções**.
4. **Ordene por severidade**, não por arquivo.
5. **Declare o que não foi verificado.** Sonda que não rodou — banco fora do ar, flag de teste não destravada — é "não verificado", nunca "sem achado".

---

## Exemplo

Repositório de tarefas: a sonda S1 mostra `usersRelations` exportado e **ausente** do `drizzle({ schema })` — achado que invalida os demais. Depois dele, S4 aponta uma listagem que chama a leitura de agregado **uma vez por linha** dentro de `Promise.all` (`DRZ-RQB-01`), e S9 um `.default(crypto.randomUUID())` que congela o valor no SQL da migração (`DRZ-SCHEMA-04`).

O formato e o corte estão em `references/relatorio-e-corte.md`.

---

## Relacionados

- [[Drizzle ORM]] — fonte desta skill: § 0, § 5, § 6, § 7
- [[Drizzle - Schema e Migrations]] · [[Drizzle - Queries e Relations]] — os satélites
- [[PostgreSQL]] — o que o ORM não dispensa
- [[Paginação por offset e cursor]] · [[Migrações de banco de dados]] — quando o achado é de estratégia
- [[react-review]] — de onde vem o formato de achado
