# TanStack skills

Two skills, and the boundary between them is **who owns the data**.

| Skill | The question it answers | Source | Internal support |
| --- | --- | --- | --- |
| `tanstack-query` | the data comes from a server and someone else can change it | [TanStack Query](../../knowledge-base/tanstack-query.md) | 6 references + 2 scripts |
| `tanstack-router` | the state belongs to the URL, or the route loads the data | [TanStack Router](../../knowledge-base/tanstack-router.md) | 5 references + 2 scripts |

## What the packages added

| Skill | Gained | Gap it closed |
| --- | --- | --- |
| `tanstack-query` | **12 probes** | the skill had the best diagnostic tables in the vault — and no command |
| `tanstack-router` | **16 probes** + **`regras-por-tarefa.md`** | it **cited no ID at all** |

**The status fix that came out of here.** `tanstack-router` opened with a "doc status warning"
saying the satellites were **under construction**, and for that reason borrowed `REACT-*` instead
of citing a family of its own. The ten satellites exist today and add up to **102 declared
`TSR-*` rules**. The warning is gone; every task now has a citable family, and the map is
generated from the docs.

**The probes that pay most, one from each:**

- **Query, S6** — an optimistic update **without** `cancelQueries`/`onError`/`onSettled`: the
 script says which of the three is missing, file by file (`TSQ-MUT-10`);
- **Router, S15** — a loader using Query **without** `defaultPreloadStaleTime: 0`: two caches
 deciding freshness (`TSR-LOAD-14`), whose symptom is "stale data with Query apparently
 right".

Both point at the **same boundary**, from opposite sides — and that is why Query's diagnostic
table ends on a row citing `TSR-LOAD-14`.

## The ID maps

One generator per skill, because the sources are distinct: **55 `TSQ-*`** and **102 `TSR-*`**.

```bash
bash plugins/tc96-frontend/skills/tanstack-query/scripts/gerar-mapa-de-ids.sh
bash plugins/tc96-frontend/skills/tanstack-router/scripts/gerar-mapa-de-ids.sh
bash scripts/instalar.sh
```

<!-- tokens:inicio -->
## Context budget

Measured by `skill-validator` (tiktoken), on 2026-09-05. **The number that matters is the
`SKILL.md` column**: it is what enters the context before the skill decides what to open.
References load on demand, one at a time.

| Skill | `SKILL.md` | largest `references/` | total | refs |
| --- | ---: | --- | ---: | ---: |
| `tanstack-query` | 1.467 | `por-tarefa.md` (3.535) | 9.969 | 6 |
| `tanstack-router` | 1.272 | `mapa-de-ids.md` (3.467) | 8.066 | 5 |

Loading all 2 skills in this group at once would cost **2.739 tokens** in `SKILL.md` alone,
and **18.035** with every reference. That is why each skill declares what it must **never** load.

Regenerate: `bash scripts/medir.sh`
<!-- tokens:fim -->

## Related

- [Skills index](../README.md)
- [react family](../react/README.md) — the component around it
- `tc96-backend: elysia family` — the bridge with Eden (`ELYSIA-TYPE-09`)
- `http-cache` — a camada de cache do servidor
