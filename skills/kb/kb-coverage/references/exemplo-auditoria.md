# Worked example: four topics, four verdicts

Replays the reasoning end to end for four topics — one clean hit already in the seed index,
one live search for a topic that was not, one partial gap, and one confirmed gap. All four
were re-verified against the files on disk while writing this reference (2026-09-23).

## 1. "TanStack Query" — Coberto, straight from the seed index

Already a row in `references/indice-por-familia.md`. Re-opening it: `docs/tanstack-query.md`
exists, is the declared `fonte:` of the `tanstack-query` skill, and its body has `TSQ-*` IDs
throughout. Nothing to search for — report and move on.

```
Tema: TanStack Query
Status: Coberto
Nota de entrada: docs/tanstack-query.md
Skill(s): tanstack-query
Por quê: hub doc, TSQ-* IDs, and it is the skill's own declared `fonte:`.
```

## 2. "N+1 query" — not in the seed index, resolved with a live search

Not one of the 17 rows. Step 2:

```bash
bash scripts/buscar-tema.sh "N+1"
```

The literal string `N+1` is a poor grep pattern in extended regex (`+` is a quantifier on the
preceding char, so `N+1` matches "N1", "NN1", …, not the literal text) — a reminder from
`SKILL.md` Step 2 to try more than one phrasing. A fixed-string pass finds it:

```bash
grep -rniF "N+1" knowledge-base/ skills/
```

Two hits: `knowledge-base/drizzle-orm.md:85` ("sem N+1 escondido") and
`knowledge-base/drizzle-queries-e-relations.md:495`, inside § 5.6 "A garantia de
performance" — right before § 5.8, a table of `DRZ-RQB-*` rules. Reading that table:

```
DRZ-RQB-01 — Busca que aninha mais de uma tabela relacionada MUST usar
db.query.tabela.findMany/findFirst com with, NEVER N chamadas separadas —
RQB garante uma única query SQL.
```

That is the rule. It also shows up verbatim in `drizzle-review`'s own `descricao:` ("finding
N+1" is one of its eleven probes) — two of the four "developed" criteria at once (ID +
skill trigger phrase).

```
Tema: N+1 query (Drizzle)
Status: Coberto
Nota de entrada: docs/drizzle-queries-e-relations.md § 5.6–5.8 (DRZ-RQB-01)
Skill(s): drizzle-review (review only — writing the fix still routes through
          Drizzle ORM § 5 directly, since there is no build skill; see the
          "known structural gaps" note in indice-por-familia.md)
Por quê: DRZ-RQB-01 names the exact failure and the exact fix, and
          drizzle-review's description lists "finding N+1" as a stated probe.
```

## 3. "Persistência (dados no navegador)" — Parcial

In the seed index already, but worth re-deriving to show why it is not simply "Coberto"
because the word appears. `references/mentioned-vs-developed.md` has the full table; the
short version:

```bash
grep -n "Persistido no browser" knowledge-base/react-patterns.md
```

→ one row, § 2: `| Persistido no browser | precisa versão e validação | |` — third column (the
"Zettel" link) empty, unlike its neighbors. Checking for an ID:

```bash
grep -n "REACT-PAT-1[1-9]\|REACT-PAT-2" knowledge-base/ skills/ -r
```

→ no matches. The `REACT-PAT-*` range stops at `REACT-PAT-10` (URL state), and browser
persistence never got one. No code example either. This fails all four "developed" criteria
except the loosest reading of the fourth (no skill's `descricao:` names it specifically).

```
Tema: Persistência (dados no navegador)
Status: Parcial
Nota de entrada: docs/react-patterns.md § 2 — one unlinked table row
Skill(s): none
Por quê: mentioned, not developed — no REACT-PAT-* ID, no example, no probe
          in react-developer or react-review. This is exactly the gap the
          roadmap's own Nível 3 evidence ("versionar e migrar dados
          persistidos no navegador") needs closed.
```

## 4. "Clean Code" — Gap confirmado, and a dangling reference

```bash
grep -rniE "clean code" agents/ knowledge-base/ skills/ _legado/
```

Two live agent files cite it (`agents/code-reviewer.md:80`, `agents/frontend-developer.md:65`)
as `Clean Code - React e Node - Mapa de Fundamentos` / `Clean Code - React e Node`. Neither
string resolves to a file under `knowledge-base/`. The old snapshot
(`_legado/snapshot-2026-09-08/agents/frontend-developer.md:58`) still has it as an Obsidian
wikilink — `[[Clean Code - React e Node]]` — confirming it used to be a private vault Zettel
that was never migrated into this repository.

```
Tema: Clean Code
Status: Gap confirmado (dangling reference)
Nota de entrada: —
Skill(s): none
Por quê: agents/code-reviewer.md and agents/frontend-developer.md cite a hub
          that does not exist anywhere in knowledge-base/. It is a private
          Zettel from the old vault, never migrated — two active agents
          still point at it.
```
