# Mentioned vs. developed

The single judgment call this whole skill exists for. Every knowledge-base doc in this vault
introduces future concepts in passing — a table row, a "ver X", a "desenvolvido em." with no
link attached. That is normal editorial practice, not a defect: the author (or the agent
consuming the doc) can always come back and develop the cell later. The failure mode is a
coverage audit that reads the row, sees the words, and reports "covered" — which is wrong in
exactly the way that matters, because it hides the gap instead of naming it.

## What counts as developed

A topic is developed when **at least one** of these is true for the candidate section:

1. **A citable rule ID**, in the family's own prefix (`references/convencoes-de-id.md`).
   `REACT-PAT-04`, `DRZ-07`, `TSQ-12` — something a review finding could cite by name, file
   and line, the way every skill in this vault already does.
2. **A worked example.** A code block that applies the concept, not just a sentence that names
   it. `react-patterns.md` § 3 (Composition) has one; § 2's "Persistido no browser" row has
   none.
3. **A probe or self-check that exercises it.** Some skill's `references/autoverificacao.md`,
   `scripts/*.sh`, or scan table has a line for this specific concept — proof that a reviewer
   is expected to actually check for it, not just know it exists.
4. **A skill whose `descricao:` names the task.** If a `SKILL.md` frontmatter says "use when
   the task is X", the topic has a home, even if the prose explaining *why* lives in the
   doc it cites as `fonte:`.

Any one of these is enough. Most well-covered topics have two or three.

## What does not count

- **A bare table row.** One cell, no ID, no linked note, sometimes literally a lone `·` where
  a Zettel link used to be. `architecture-in-react.md` § 2 has a dozen of these — it is a
  router page, and a blank "Nota de entrada" there is an honest admission that the routing
  was never finished, not evidence the topic is undocumented everywhere.
- **Incidental appearance.** The term shows up inside an example that is *about* something
  else. Zod appearing inside a Drizzle schema example does not mean Zod-in-Drizzle is a
  developed topic — check whether the surrounding prose actually discusses the choice, or
  whether the library just happened to be in the snippet.
- **A dangling reference.** "Ver X", "desenvolvido em.", or a wikilink (`[[Some Note]]`) that
  does not resolve to a file that exists in this repository. This is the sharpest case,
  because it is not merely thin — it is **actively wrong**: something cites it as if it
  existed. Report this as a gap *and* name it as a dangling reference, because whoever fixes
  it needs to know there is a live citation to clean up, not just a hole to fill.

## The worked precedent

From the 2026-09-23 audit of `frontend-roadmap.md`, in the same source doc, two rows apart:

| | Composition (§ 3) | "Persistido no browser" (§ 2) |
| --- | --- | --- |
| Rule ID | `REACT-PAT-04`, `REACT-PAT-05` | none — the `REACT-PAT-*` range stops at 10 and skips it |
| Example | children/slots code block | none |
| Probe | referenced by `react-developer`'s decision tree | not mentioned in any skill's self-check |
| Verdict | **Coberto** | **Parcial** |

Same document, same author, same table shape. The only difference is whether the row was
ever built out — which is exactly why this cannot be judged by "does the doc contain the
word" and has to be judged by opening the section and checking against the four criteria
above.

## A shortcut that fails

Do not treat "this topic is mentioned in N different docs" as a proxy for coverage. A concept
repeated as a forward reference in five different routing tables, developed in none of them,
is still a gap — it just has five dangling pointers instead of one. Count developed sections,
not mentions.

## Fragmented is not partial

Do not confuse a topic that is legitimately split across layers with one that is
underdeveloped. **Cache** is `Coberto`, not `Parcial`, even though it lives in two places
(`http-cache` for the HTTP layer, `tanstack-query` for the application layer) — because each
side is fully developed on its own terms, and each skill's own "do not use" line names the
other explicitly (`tanstack-query`: "nor for HTTP caching, which is http-cache"). That
cross-reference is the tell: intentional layering excludes its neighbor by name; an
underdeveloped topic just trails off.
