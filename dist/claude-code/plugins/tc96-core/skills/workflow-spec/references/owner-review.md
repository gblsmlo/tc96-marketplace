# The owner's review — what moves a status

A spec file is born as a draft and becomes authority only by the owner's explicit answer in
the conversation (`WF-SPEC-06`). The writer never approves its own file; silence approves
nothing; a spec-only run ends with every unapproved file listed under `lacunas`.

---

## States per document

| Document | Born as | Owner says approve | Owner says reject | After approval |
| --- | --- | --- | --- | --- |
| PRD | `Draft` | `Approved` | stays `Draft` | frozen; a change returns to `workflow-research` and enters as an amendment (`DOC-PRD-04`, `WF-SPEC-08`) |
| Design doc | `Draft` | `Accepted` | `Rejected` | frozen; a change enters as an amendment, a lasting decision as an ADR (`WF-SPEC-08`) |
| RFC (`design.md` in `rfc` mode) | `Draft` → `In review` | `Accepted`, on or after the decision date | `Rejected` | lists the ADRs it produced (`DOC-RFC-04`) |
| ADR | `Proposed` | `Accepted` | file removed, it recorded nothing | never edited; superseded by a new ADR (`DOC-ADR-02`) |
| User experience | `draft` | `accepted` | stays `draft` | a frontend Task may start (`WF-SPEC-04`); a change enters as an amendment |
| Plan (`tasks/NNNN-<slug>.md`) | `Draft` | `Ready` | stays `Draft` | each Task starts once its own inputs are accepted (`WF-SPEC-04`); the next increment gets a new plan |
| Amendment | `Draft` | the document's approved state | `Rejected`; the text above it is untouched | frozen, like the text above it (`WF-SPEC-08`) |

"Change" is the third answer for every row: the owner agent revises from the owner's words,
and the status does not move.

## The review message

One message, four parts, nothing else:

1. the path;
2. the one-sentence problem (PRD, UX) or decision (design, ADR, tasks);
3. the open gaps, verbatim from the file;
4. "approve, change, or reject?"

Not the file's content: the owner reads the file. Not a summary of its sections: a summary
widens or narrows what the file says, and the owner would approve the summary.

**The bundle.** When a stage drafted several files side by side — Planning's `design.md`, ADRs,
`user-experience.md` and the plan (hub §5 "The planning bundle") — they go in one message, not
one message each:

1. per file, parts 1–3 above, one file per row or item;
2. which file depends on which — the plan cites the design and the UX, an ADR the design;
3. when the bundle holds a plan, whether to publish its board items, and its `Delivery` mode and
   push-and-PR authorization (hub §5 "Delivery");
4. "approve, change, or reject — per file, or name the files one answer covers?"

The calling pillar sends it, from the results its `workflow-spec` calls returned (`../SKILL.md`
Step 4). A standalone request for one file keeps the four-part message.

## What counts as the owner's answer

| Counts | Does not count |
| --- | --- |
| "approve", "accepted", "ok, ship it", or the owner editing the status line in the file | the writer agent's self-check passing |
| "change X" — a revision request | a pillar's "advance without asking" rule |
| "reject", "no" | an `Approved` status pasted by an agent |
| in a bundle, one answer that names the files it covers: "approve the design, ADR-0004 and the plan"; or "approve all", which counts only because the message listed the paths, covers exactly those paths, and is recorded as one status move per path | in a bundle, an answer that names one file moving any other; "approve all" over a file the message did not list; silence on a file moving it |

A "change" on one file of a bundle re-drafts that file and only the files the message listed as
depending on it; the files that do not depend on it keep the answer they got (`WF-SPEC-06`).

The "advance without asking" rule of the pillars stops at a file awaiting review: that is an
owner decision, the one case those rules already except.

## Spec-only run

The `spec` command runs research and planning and stops (`WF-SPEC-05`). A product scope waits
at `requirements.md` for the owner's answer before planning starts (`WF-CORE-03`); when the
owner answers in the same conversation, the run continues; when not, the envelope returns
with that file under `lacunas` (`decide: dono`, `fecha-em: pesquisa`, `WF-CORE-09`), its
`pergunta` reading `awaiting owner approval: .specs/<capability>/requirements.md`, and a later
run resumes from that file.

---

## Related

- `../SKILL.md` Step 4 — where this protocol runs
- [Decision Documents — PRD, RFC and ADR](../../../referencias/documentos-de-decisao-prd-rfc-adr.md) §3 — the lifecycle of each decision document
