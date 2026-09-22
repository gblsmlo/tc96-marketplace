# As sondas — antes de ler o código

> Em persistência, os piores defeitos são **invisíveis à leitura**: o schema parece completo,
> a query parece certa, o teste passa — e mesmo assim a API relacional está desligada ou o
> gerador de migração está cego.

```bash
bash ~/.claude/skills/drizzle-review/scripts/sondas.sh src
```

| Sonda | Como | O que revela |
| --- | --- | --- |
| **S1. Registro do cliente** | Comparar os `pgTable` e `relations()` exportados com as chaves do objeto passado a `drizzle({ schema })` | `DRZ-REL-05` — schema sem os `relations()` faz `with` lançar em runtime; tabela ausente faz `db.query.x` ser `undefined` |
| **S2. Cadeia de snapshots** | Contar entradas de `meta/_journal.json` × arquivos `*_snapshot.json`; rodar `generate` num tree limpo | migração escrita à mão que não atualizou o snapshot faz o gerador diffar de um estado antigo e propor SQL destrutivo |
| **S3. Índices redundantes** | Para cada tabela, achar índice que seja prefixo estrito de outro | custo de escrita e de cache sem nenhum leitor |
| **S4. Testes de integração vivos** | Rodar a suíte com as flags que destravam os testes de banco | teste que nunca roda não é cobertura; caminho de arquivo errado passa despercebido por anos |

S1 e S3 são leitura de código — nenhum precisa de conexão. **S2** precisa de um `generate`
num tree limpo. **S4** (testes de integração vivos) precisa do banco de pé e das migrações
aplicadas — se não rodou, declare.

**Se S1 falhar, pare e reporte antes de continuar.** Com a API relacional desligada, toda
leitura montada à mão é **consequência, não causa**, e criticar cada uma é ruído.

## O que o script acrescenta às quatro sondas da doc

| Sonda extra | Regra | Por que entra aqui |
| --- | --- | --- |
| S4 — query dentro de `map`/`for` | `DRZ-RQB-01` | o achado mais comum e o mais caro |
| S5 — `update`/`delete` sem `where` | `DRZ-QUERY-04` | bloqueante, e uma linha o produz |
| S6 — `sql\`\`` com interpolação | `DRZ-QUERY-03` | vira achado de **segurança** quando o valor vem do usuário |
| S7 — `db` externo dentro de `transaction` | `DRZ-TX-03` | a escrita sai da transação sem erro |
| S8 — `push` fora do local | `DRZ-MIG-02`, `DRZ-MIG-04` | grep no `package.json` e no workflow resolve |
| S9 — `.default()` com valor computado | `DRZ-SCHEMA-04` | o valor congela no SQL da migração |
| S10 — Zod à mão | `DRZ-ZOD-01` | aponta os candidatos; a confirmação é leitura |

## Relacionados

- `varredura-e-severidade.md` — o que fazer com o que a sonda apontou
- `mapa-de-ids.md` — onde cada `DRZ-*` tem corpo
