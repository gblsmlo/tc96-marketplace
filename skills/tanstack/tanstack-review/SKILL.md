---
name: tanstack-review
description: Reviews or debugs TanStack Query/Router code with probes, citing TSQ/TSR IDs
type: skill
family: tanstack
language: en
source: "[TanStack Query](../docs/tanstack-query.md) § 5.1 · [TanStack Router](../docs/tanstack-router.md) § 6.1"
docs:
  - /websites/tanstack_query
  - /websites/tanstack_router
tags:
  - skill
  - tanstack-query
  - tanstack-router
  - review
---

# tanstack-review

> **Source:** the two hubs, [TanStack Query](../docs/tanstack-query.md) (§ 5.1 diagnosis by symptom) and [TanStack Router](../docs/tanstack-router.md) (§ 6.1 canonical IDs); one satellite per confirmed finding.
> **API surface:** Context7 `/websites/tanstack_query`, `/websites/tanstack_router`.

Reviews code that **already exists** (a PR, a diff, a file list) or finds why it misbehaves ("the list does not update", "too many requests", "the filter resets"). Writing new code is `tanstack-query` or `tanstack-router`; component interior findings are `react-review`.

## Step 1: probe before reading

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/tanstack-review/scripts/probes.sh <dir> [all|query|router]
```

Pass the narrowest directory the diff allows. Each line is `file:line` plus the rule ID: a **candidate**, never yet a finding. Open the line, confirm, and only then cite. Probes cannot see these, so read for them every time: a key whose order or shape differs between reader and invalidator (`TSQ-BASE-02`), `staleTime: 'static'` on mutable data (`TSQ-CACHE-02`), a disabled query holding data a mutation must refresh (`TSQ-PATTERN-10`), search state copied into `useState` (`REACT-PAT-03`), an open redirect in a post-login `redirect` param.

## Step 2: debugging a symptom

Walk the matching table in [TanStack Query](../docs/tanstack-query.md) § 5.1 **in its order of likelihood** and confirm each cause in code before moving on. Two causes often stack: fix all you confirm, not the first. Never ship a trigger switched off (`refetchOnWindowFocus: false`, `staleTime: 0` everywhere) as the cure: it hides the symptom and leaves a contradictory policy (`TSQ-CACHE-03`). If Query looks right and data is still stale after navigation, check the router's preload cache (`TSR-LOAD-14`).

## Step 3: confirm against one satellite

`references/id-map.md` gives each ID's doc and section (157 IDs, about 2k tokens). Open that section only when the finding needs its text. Cite the canonical ID: Router hub § 6.1 lists the aliases (`TSR-NAV-08` → `TSR-LOAD-14`, `TSR-LOAD-01` → `REACT-EFFECT-06`, `TSQ-BASE-09` in a loader → `TSR-LOAD-15`). Never invent an ID; a defect with no ID goes under "Suggestions".

## Step 4: classify and report

| Severity | Contains |
| --- | --- |
| **High** | wrong or stale data reaching the user, a rollback that does not run, data leaking between users: `TSQ-BASE-03`, `-05`, `TSQ-CACHE-02`, `TSQ-MUT-07`, `-08`, `-10`, `-11`, `TSQ-SSR-04`, `TSR-LOAD-14`, `TSR-SEARCH-01`, `TSR-LOAD-06`, `TSR-CTX-07` |
| **Medium** | any other `TSQ-*` / `TSR-*` |
| **Suggestion** | no ID; not a finding |

One block per finding, ordered by severity:

```
`TSQ-MUT-11` (High) src/features/orders/useCancelOrder.ts:15
The snapshot lives in a useRef, so concurrent cancels overwrite it and the rollback restores the wrong list.
Fix: return { previous } from onMutate and restore from onError's third argument.
See TanStack Query - Mutations and Invalidation § 5.
```

Close with: files read, probes run and their candidates you **rejected** (one line why), and what you did not verify. A file outside the diff goes to "Open items", never into a severity section. When asked to fix, fix every High, then rerun the probes and `bunx tsc --noEmit`.
