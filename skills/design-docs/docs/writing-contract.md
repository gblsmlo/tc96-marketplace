---
title: Design Docs - Writing Contract
tags:
  - design-docs
  - writing
---
# Design Docs - Writing Contract

Every `doc-*` skill follows this contract. It is what makes them **writers**: they take what was
already decided and put it on the page, in the house template, without deciding, investigating or
researching anything themselves. A workflow calls them at its edges; a person can call one alone.

## Contents

- 1. Writer, not investigator
- 2. Structure is the writer's, substance is the input's
- 3. Gaps
- 4. Status and lifecycle
- 5. Where the output goes
- 6. Style
- 7. Model and effort
- 8. IDs across documents

---

## 1. Writer, not investigator

| Rule | Text |
| --- | --- |
| `DD-CORE-01` | The writer **MUST** read only: the request, the files the request names as input, its own template and rules, the target file when revising or amending it, and a listing of the target folder when the document is numbered. |
| `DD-CORE-02` | The writer **NEVER** searches the codebase, opens a file nobody named, browses the web, runs a command to reproduce or investigate, or asks a round of discovery questions. A fact the document needs and the input does not hold is a gap (§3), not a reason to go looking. |

**Why.** Investigation is a different job, with different tools, on a different tier. A writer
that also investigates mixes verified input with its own unverified findings, and the reader can no
longer tell which claim came from whom. Kept apart, the input is the single source of every fact in
the document, and the owner reviews one thing: whether the page says what was decided.

"Files the request names" includes what the caller points at by reference: "the PRD", "the notes
in `docs/meeting.md`", "this branch's diff". It does not include the code those files mention. The
one command a writer may run is the read of a named diff (`git log` and `git diff` of the range the
caller named, in `doc-pr`): the diff is the input, and it says *what* changed, never *why*.

A document the input mentions without giving it ("see F01's spec") is not hunted for — no `grep`,
no `find` over the project: what the writer needs from it is a gap ("the shape of F01's token —
decides: whoever holds F01's spec"). A listing of the target folder, to number or to check a path
the caller named exists, is the only look around the writer takes.

A `file:line` or link in the document is copied from the input. The writer never looks one up,
and never opens one to check it: a path the input cites ("no status column, `src/db/schema.ts:40`")
is a fact to copy as given, not a file named as input. If it looks wrong, that is a gap for whoever
supplied it.

## 2. Structure is the writer's, substance is the input's

| The writer owns (structure) | The input owns (substance) |
| --- | --- |
| section order, headings, tables | facts, numbers, sources, evidence |
| IDs and numbering (`AC-01`, `F02`, `T3`, `0005`) | decisions, and the alternatives that were weighed |
| rewording a stated need as a story or as Given / When / Then | scope, non-goals, priorities |
| splitting stated needs into stories, criteria, tasks | targets, deadlines, owners |
| deriving an order from stated dependencies | severity, risk, who is affected |
| cross-references between documents | what the code does today |

| Rule | Text |
| --- | --- |
| `DD-CORE-03` | The writer **NEVER** invents substance. A value the input lacks is a gap; a claim the input makes without a source is written with `(hypothesis)`. |
| `DD-CORE-04` | Structure the writer derives that implies a choice (a feature cut, a task order, a priority read from wording) **MUST** be marked `(proposed)`, so the owner sees it was the writer's reading and not the input's decision. |

**Why.** A plausible invented number is worse than a visible hole: it survives review because it
looks decided. A hole marked with who decides it gets decided.

## 3. Gaps

A gap is written where the value belongs, and collected again in the document's **Open questions**
section (**Open gaps** in the PRD and the spec, where the delivery flow already names it so), so a
reader finds every one in one place:

```
[GAP: <the question, in one sentence> — decides: <owner | a role | the reporter>]
```

| Rule | Text |
| --- | --- |
| `DD-CORE-05` | Every gap **MUST** name who decides it. A gap with no decider stays open forever. Open sides of the same item that one person decides in one answer are one gap ("the route's error body, unknown id and invalid token responses"), not three. |
| `DD-CORE-06` | When the document's **anchor** is missing, the writer **MUST NOT** write the file. It returns the questions instead. A file made mostly of gaps passes for progress and is not. |

Each skill names its anchor — the one input without which the document has no subject:

| Skill | Anchor |
| --- | --- |
| `doc-prd` | the problem, and who has it |
| `doc-adr` | the decision that was made |
| `doc-epic` | the capability, and who uses it |
| `doc-feature` | what it delivers, and the benefit expected |
| `doc-story` | the user, the action and the outcome |
| `doc-tasks` | the source being broken down (a story, feature, spec or request with its acceptance) |
| `doc-bug` | what happened, and what was expected instead |
| `doc-spec` | what the feature provides or changes |
| `doc-pr` | the change, from a diff, a commit list or the caller's summary |

## 4. Status and lifecycle

| Rule | Text |
| --- | --- |
| `DD-CORE-07` | A decision document **MUST** be born `Draft` (an ADR `Proposed`). The writer never approves its own file, and silence is not approval. |
| `DD-CORE-08` | A frozen document (`Approved` PRD, `Accepted` ADR) is **NEVER** rewritten. A change is a dated amendment (PRD) or a new superseding document (ADR). |

Tracker items (epic, feature, story, bug) carry the tracker's status, not this one: the writer
leaves the status field for the tracker and does not invent one.

Moving a status is a one-field edit made on the owner's explicit words ("approve", "accepted"). It
is the only edit the writer makes to a file it did not just draft.

## 5. Where the output goes

| The caller... | Output |
| --- | --- |
| names a path | that path |
| names none, and the skill has a default path | the default (each SKILL.md says it) |
| names none, and the document is a tracker item or a PR body | the body, in the reply, ready to paste; no file is written |

Return, in this order and nothing else:

1. the outcome: `complete` (no gap), `partial` (written, with gaps) or `blocked` (anchor missing,
   nothing written, `DD-CORE-06`);
2. the path (or "inline", with the body after the return block);
3. the document's status;
4. one sentence on what the document says;
5. every open gap verbatim with who decides it, and every `(proposed)` item.

The caller reads the file; the reply does not repeat it. A workflow branches on the outcome: on
`blocked` or `partial` it takes the gaps to whoever decides them, then calls the writer again with
the answers.

## 6. Style

- Write in the language of the request, or of the project's existing documents when the caller
  says so. Templates are in English; their headings are translated with the body.
- Short sentences, active voice, present tense. No preamble ("This document describes…").
- Delete every bracketed hint of the template. A hint left in place is an unmade decision.
- A section the template marks optional and the input does not touch is deleted, not filled with
  `N/A`. A required section with nothing to say says `none`, so the reader knows it was considered.
- Keep the template's tables as tables: a reviewer scans a table, and re-reads prose.

## 7. Model and effort

The content is decided before the writer runs, so the tier follows how much structuring the
document needs, not how important it is. Each skill declares its tier in the frontmatter.

| Skill | Model | Effort | Why |
| --- | --- | --- | --- |
| `doc-prd` | `medio` | `alto` | most structure: stories, criteria, features, waves, traceability both ways |
| `doc-spec` | `medio` | `alto` | shapes a consumer codes against; a vague shape costs every downstream feature |
| `doc-adr` | `rapido` | `medio` | one decision, a fixed template |
| `doc-epic` · `doc-feature` · `doc-story` | `rapido` | `medio` | rewording into a fixed format, with criteria to keep observable |
| `doc-tasks` | `rapido` | `medio` | ordering and slicing from stated dependencies |
| `doc-bug` | `rapido` | `medio` | the reporter's facts in a fixed order |
| `doc-pr` | `rapido` | `medio` | summarizes a diff and a checklist the caller already holds |

The two `medio` writers are the ones where the fast tier lost points in the evals: it added unmarked
scope to a PRD and went looking for a spec it was not given. The other seven held on the fast tier
(`evals/README.md`, "Cost per model vs result").

Neutral tiers map per runtime (`alto`/`medio`/`rapido` → `opus`/`sonnet`/`haiku` in Claude Code).

A skill's tier is reliable only when the writer runs in its own context. Loaded inline inside
another agent, the skill shares that agent's context, and Claude Code does not document its
`model` applying there. Two agents hold the tier in their own frontmatter instead, and their tool
list is the read list of §1 — `Read`, `Write`, `Glob` and `Skill`, with no `Grep`, `Bash` or `Edit`:

| Agent | Model · effort | Skills |
| --- | --- | --- |
| `doc-writer` | `rapido` · `medio` | the seven above |
| `doc-writer-deep` | `medio` · `alto` | `doc-prd`, `doc-spec` |

With no shell, `doc-pr` reads the diff from a file the caller writes and names.

## 8. IDs across documents

| ID | Born in | Example |
| --- | --- | --- |
| `PO-n`, `OBJ-n`, `US-n`, `AC-NN`, `F<NN>` | `doc-prd` | `AC-07`, `F03` |
| `ADR-NNNN` | `doc-adr` | `ADR-0005` |
| `EPIC-<slug>` | `doc-epic` | `EPIC-quote-approval` |
| `T<n>` | `doc-tasks` | `T4` |

A document that derives from another cites these IDs instead of copying the text: a story traces
`AC-03`, a task enables `AC-03`, a PR closes `T4`. When the input gives the parent's IDs, the writer
reuses them; when it gives none, the writer numbers locally and says so.
