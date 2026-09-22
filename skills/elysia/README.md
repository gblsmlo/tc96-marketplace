# Skills de Elysia

Três skills, uma por satélite: **rota**, **schema**, **lifecycle**.

| Skill | A pergunta que responde | Fonte | Apoio interno |
| --- | --- | --- | --- |
| `elysia-build` | como escrevo esta rota e este handler? | [Elysia - Roteamento e Handler](../../knowledge-base/docs/elysia-roteamento-e-handler.md) | 5 referências + 1 script |
| `elysia-schema` | como valido, tipo o retorno e consumo pelo Eden? | [Elysia - Schema e Eden](../../knowledge-base/docs/elysia-schema-e-eden.md) | 5 referências + 1 script |
| `elysia-diagnose` | por que este hook não afeta a rota? | [Elysia - Lifecycle e Plugins](../../knowledge-base/docs/elysia-lifecycle-e-plugins.md) | 6 referências + 2 scripts |

## O que os pacotes acrescentaram

| Skill | Ganhou | Lacuna que fechou |
| --- | --- | --- |
| `elysia-diagnose` | **`scripts/sondas.sh`** — dez sondas de lifecycle | a skill tinha "as sondas" como seção **sem comando**: só o teste de escopo em TypeScript |
| `elysia-build` · `elysia-schema` | `scripts/autoverificar.sh` | as checklists de 15 e 14 itens eram leitura |

**A sonda que não existia em lugar nenhum: S1 do diagnose.** Ela mede a **ordem de registro
por número de linha** — hook registrado depois da primeira rota do arquivo (`ELYSIA-CORE-01`),
que é a primeira hipótese, sempre, e não dá erro nem aviso.

**E o que a sonda deliberadamente não faz:** provar escopo. `local` e `scoped` produzem o
mesmo código dentro do plugin; a diferença só aparece na instância consumidora. A prova é o
teste de `references/prova-de-escopo.md` — e a tabela de lá mostra por que o teste que a
maioria dos projetos tem (dentro do plugin) **passa nos dois casos**.

## O mapa de IDs

Gerado por `elysia-diagnose/scripts/gerar-mapa-de-ids.sh`, igual nas três. **44 IDs** — o
número que o hub declara, o que serve de conferência. Como `ELYSIA-APP-*` é declarada só no
hub, o mapa tem a coluna **"corpo no satélite"**, e as 9 linhas de `APP` aparecem
explicitamente como "só no hub" — batendo com a contagem da doc.

**A peculiaridade da família:** os apelidos são **parciais**. `ELYSIA-APP-03` é apelido de
`ELYSIA-CORE-02` **só** na cláusula de desestruturação; `ELYSIA-TYPE-11` é apelido de
`ELYSIA-APP-04` **só** na de `strict`. Fora dessas cláusulas, os dois são citáveis pelo que
é só deles — e o cabeçalho do mapa carrega a § 6.2 inteira por isso.

```bash
bash plugins/hermes-backend/skills/elysia-diagnose/scripts/gerar-mapa-de-ids.sh
bash scripts/instalar.sh
```

<!-- tokens:inicio -->
## Orçamento de contexto

Medido por `skill-validator` (tiktoken), em 2026-09-05. **O número que importa é o da
coluna `SKILL.md`**: é o que entra no contexto antes de a skill decidir o que abrir.
As referências carregam sob demanda, uma por vez.

| Skill | `SKILL.md` | maior `references/` | total | refs |
| --- | ---: | --- | ---: | ---: |
| `elysia-build` | 1.751 | `mapa-de-ids.md` (2.596) | 8.182 | 6 |
| `elysia-diagnose` | 1.609 | `mapa-de-ids.md` (2.596) | 7.568 | 7 |
| `elysia-schema` | 1.620 | `mapa-de-ids.md` (2.596) | 7.657 | 6 |

Carregar as 3 skills deste grupo de uma vez custaria **4.980 tokens** só de `SKILL.md`,
e **23.407** com todas as referências. É por isso que cada skill declara o que **nunca** carregar.

Regenerar: `bash scripts/medir.sh`
<!-- tokens:fim -->

## Relacionados

- [Skill — Índice](../README.md) · [Elysia](../../knowledge-base/docs/elysia.md) § 7 — o contrato
- `hermes-core: família http` — o protocolo que Elysia implementa
- `família drizzle` — a persistência que o handler chama
