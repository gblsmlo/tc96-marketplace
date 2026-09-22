# Skills de TanStack

Duas skills, e a fronteira entre elas é **de quem é o dado**.

| Skill | A pergunta que responde | Fonte | Apoio interno |
| --- | --- | --- | --- |
| [[tanstack-query]] | o dado vem do servidor e outra pessoa pode alterá-lo | [[TanStack Query]] | 6 referências + 2 scripts |
| [[tanstack-router]] | o estado pertence à URL, ou a rota carrega o dado | [[TanStack Router]] | 5 referências + 2 scripts |

## O que os pacotes acrescentaram

| Skill | Ganhou | Lacuna que fechou |
| --- | --- | --- |
| `tanstack-query` | **12 sondas** | a skill tinha as melhores tabelas de diagnóstico do vault — e nenhum comando |
| `tanstack-router` | **16 sondas** + **`regras-por-tarefa.md`** | ela **não citava ID nenhum** |

**A correção de estado que saiu daqui.** `tanstack-router` abria com um "aviso de estado da
doc" dizendo que os satélites estavam **em construção**, e por isso emprestava `REACT-*` em
vez de citar família própria. Os dez satélites hoje existem e somam **102 regras `TSR-*`**
declaradas. O aviso saiu; cada tarefa passou a ter família citável, e o mapa é gerado da doc.

**As sondas que mais pagam, uma de cada:**

- **Query, S6** — update otimista **sem** `cancelQueries`/`onError`/`onSettled`: o script
  diz qual das três falta, arquivo por arquivo (`TSQ-MUT-10`);
- **Router, S15** — loader usando Query **sem** `defaultPreloadStaleTime: 0`: dois caches
  decidindo frescor (`TSR-LOAD-14`), cujo sintoma é "dado velho com o Query aparentemente
  certo".

As duas apontam para a **mesma fronteira**, de lados opostos — e é por isso que a tabela de
diagnóstico da Query termina numa linha que cita `TSR-LOAD-14`.

## Os mapas de IDs

Um gerador por skill, porque as fontes são distintas: **55 `TSQ-*`** e **102 `TSR-*`**.

```bash
bash Skills/tanstack/tanstack-query/scripts/gerar-mapa-de-ids.sh
bash Skills/tanstack/tanstack-router/scripts/gerar-mapa-de-ids.sh
bash Skills/instalar.sh
```

<!-- tokens:inicio -->
## Orçamento de contexto

Medido por `skill-validator` (tiktoken), em 2026-09-05. **O número que importa é o da
coluna `SKILL.md`**: é o que entra no contexto antes de a skill decidir o que abrir.
As referências carregam sob demanda, uma por vez.

| Skill | `SKILL.md` | maior `references/` | total | refs |
| --- | ---: | --- | ---: | ---: |
| [[tanstack-query]] | 1.467 | `por-tarefa.md` (3.535) | 9.969 | 6 |
| [[tanstack-router]] | 1.272 | `mapa-de-ids.md` (3.467) | 8.066 | 5 |

Carregar as 2 skills deste grupo de uma vez custaria **2.739 tokens** só de `SKILL.md`,
e **18.035** com todas as referências. É por isso que cada skill declara o que **nunca** carregar.

Regenerar: `bash Skills/tokens.sh`
<!-- tokens:fim -->

## Relacionados

- [[Skills/README|Skill — Índice]]
- [[Skills/react/README|Skills/react/]] — o componente em volta
- [[Skills/elysia/README|Skills/elysia/]] — a ponte com o Eden (`ELYSIA-TYPE-09`)
- [[http-cache]] — a camada de cache do servidor
