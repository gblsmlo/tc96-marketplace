---
nome: kb-coverage
descricao: Look up whether this repository's knowledge-base (`knowledge-base/`, `knowledge-base/`) and its skills already develop a given topic — an architecture concept, a React/TanStack/HTTP/Elysia/Drizzle/Bun/Playwright/Storybook mechanism, a testing concern, anything — and report exactly which doc section and which skill own it, or that it is a confirmed gap. The hard part it solves is telling a real, citable rule (an ID, a worked example, a probe some skill runs) apart from a topic that only gets a passing one-line mention — treating the second as coverage is the most common false positive when auditing this vault. Use this whenever the task is checking coverage ("do we already have a skill for X", "is Y documented anywhere"), filling in a "Nota de entrada" / entry-note column in a routing table (`frontend-roadmap.md`, `architecture-in-react.md`), deciding a new skill's `fonte:` before writing it, or confirming a topic is a genuine gap before adding new documentation for it. Do not use it to write or edit knowledge-base content or skills — it only locates and reports, and never changes a file on its own.
tipo: skill
familia: kb
idioma: en
fonte: "[Skills index](../../README.md)"
tags:
  - skill
  - meta
  - knowledge-base
  - documentation-audit
---

# kb-coverage

> **Source of this skill:** [Skills index](../../README.md) — the convention every other skill already follows: one `fonte:` note per skill, families grouped under `skills/<family>/`, IDs owned by the family's normative doc. This skill does not add a new convention; it reads the one that is already there and answers *"for this topic, which file and which skill?"*.

> **Design note.** This is a **lookup** skill, not a build or review skill: it never edits `knowledge-base/` or a `SKILL.md`. When it finds a gap, the next step — writing the missing note, wiring a new skill, fixing a dangling reference — is a separate, explicit task the user decides on, not something this skill does on its own.

---

## When to use

| Situation | Go to |
| --- | --- |
| "do we have coverage for topic X" / filling a "Nota de entrada" cell | this skill |
| deciding the `fonte:` of a skill you are about to write | this skill, then `skill-creator` (or the house's own scaffold) for the skill itself |
| the topic already resolved to a doc and you need to change that doc | edit it directly — this skill does not write |
| the topic resolved to a skill and you need to change its rules | the skill's own family (`react-review`, `drizzle-review`, …) |
| you already know the doc and just want its rule IDs | `references/mapa-de-ids.md` of the skill that owns that doc, not this one |

---

## Minimum loading

| Order | Load | Why |
| --- | --- | --- |
| 1 | `references/mentioned-vs-developed.md` | the calibration that decides every verdict — read this before trusting any hit |
| 2 | `references/indice-por-familia.md` | the seed index: topics already verified, one table per family |
| 3 | `references/convencoes-de-id.md` | each family's rule-ID prefix, so a hit's nearby ID tells you it is real |
| 4 | `scripts/buscar-tema.sh` | live search, for anything not already in the seed index |
| 5 | `references/exemplo-auditoria.md` | a full worked audit — a clean hit, a fragmented hit, a partial gap, a confirmed gap |

**Never assume the seed index is exhaustive.** It was seeded from one audit (2026-09-23, the 17 themes of `frontend-roadmap.md`); anything outside that list needs Step 2.

---

## Step 1 — Check the seed index first

`references/indice-por-familia.md` has one table per family with topics already verified against the actual files, not against memory of what a doc *should* say. Before trusting an index row, open the cited section — files move, and a stale index entry is worse than no entry, because it reads as confidently as a fresh one.

If the topic (or something close enough in meaning) is in the index, you likely have your answer already — jump to Step 3 to re-verify it still holds, then report.

---

## Step 2 — If it's not in the seed index, search live

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/kb-coverage/scripts/buscar-tema.sh "<tema>"
```

The script greps `knowledge-base/`, `knowledge-base/` and every `skills/*/*/SKILL.md` (its `descricao:` and `fonte:` fields), and prints candidates grouped by: direct text hits, hits with a rule ID within three lines, skills whose description matches, and skills whose `fonte:` points at a matched doc. It finds **candidates** — it does not judge coverage. That judgment is Step 3.

Run it more than once with different phrasings (English and Portuguese, the concept name and a concrete symptom) before concluding there is nothing — a doc titled around one word may develop a related concept under different vocabulary (e.g. "N+1" lives inside `drizzle-orm.md` under a query-pattern heading, not under a heading called "N+1").

---

## Step 3 — Verify: mentioned vs. developed

This is the actual work of the skill; everything before it is just gathering candidates. `references/mentioned-vs-developed.md` has the full criteria and the worked precedent, but the short version:

**Counts as developed:**
- a citable rule ID in the family's convention (`references/convencoes-de-id.md`) — `REACT-PAT-04`, `DRZ-07`, `TSQ-12`…
- a worked example (a code block that shows the concept applied, not just named)
- a self-check, probe or script in some skill that exercises it
- a skill whose `descricao:` explicitly names the task ("use when the task is…")

**Does not count:**
- a bare row in a routing table with an empty cell or a lone `·`
- the term appearing only inside an example that is *about* something else
- a "ver X" / "desenvolvido em" pointer that does not resolve to an actual file in this repo (a private Zettel that was never migrated) — this is a **gap**, and worth flagging as a *dangling reference* specifically, because other files may keep citing it as if it existed

When a hit satisfies only the second list, do not report it as covered. Report it as a **partial gap** and say exactly what is missing (an ID, an example, a probe) — that is the actionable part for whoever picks this up next.

---

## Step 4 — Report

Always report, per topic:

```
Tema: <topic>
Status: Coberto | Parcial | Gap confirmado
Nota de entrada: <doc/page § section>, or "—" for a confirmed gap
Skill(s): <which skill(s) consume this note, if any>
Por quê: <one line — the ID/example/probe that makes it "developed",
          or what's missing, or what the dangling reference points at>
```

Group multiple topics into one table when reviewing a routing table like `frontend-roadmap.md` — that mirrors the format the doc itself already uses, so the answer drops straight into the "Nota de entrada" column if the user asks you to apply it.

Never merge "Parcial" into "Coberto" to make a report look cleaner. A fragmented-but-real topic (covered across two or three skills, each owning one layer — e.g. **Cache** split between `http-cache` and `tanstack-query`) is still **Coberto**, by design, not partial: check whether the split is intentional layering (each skill's own "do not use" line excludes the other's territory) before calling it fragmented. A **Parcial** is when the *same* topic has no layer that actually develops it.

---

## Example

Three topics from the 2026-09-23 audit, one of each kind:

- **TanStack Query** — `Coberto`. `knowledge-base/tanstack-query.md` is the hub, `tanstack-query` is the skill, `TSQ-*` are the IDs.
- **Persistência (browser)** — `Parcial`. `react-patterns.md` § 2 has the row "Persistido no browser · precisa versão e validação" — mentioned — but no `REACT-PAT-*` ID exists for it (the range stops at 10), no example, no probe in `react-developer`/`react-review`.
- **Clean Code** — `Gap confirmado`, and a dangling reference: `agents/code-reviewer.md` and `agents/frontend-developer.md` both cite `Clean Code - React e Node - Mapa de Fundamentos`, a hub that does not exist anywhere in `knowledge-base/` — it is a private Zettel from `_legado/snapshot-2026-09-08/` that was never migrated.

Full replay, including the search commands and why each verdict landed where it did: `references/exemplo-auditoria.md`.

---

## Related

- [Skills index](../../README.md) — the `fonte:`/`familia` convention this skill reads, not invents
- `frontend-roadmap.md`, `architecture-in-react.md` — the routing tables this skill is most often asked to check (edits to them are a separate step, done by the user or on explicit request)
- `react-structure`, `test-review`, and the other family skills — once a topic resolves to one of them, that skill's own `references/mapa-de-ids.md` has the exhaustive ID list this skill does not repeat
