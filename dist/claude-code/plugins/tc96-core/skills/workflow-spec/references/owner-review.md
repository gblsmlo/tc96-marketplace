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
| Plan (`tasks/NNNN-<slug>.md`) | `Draft` | `Ready` | stays `Draft` | the first Task may start (`WF-SPEC-04`); the next increment gets a new plan |
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

## What counts as the owner's answer

| Counts | Does not count |
| --- | --- |
| "approve", "accepted", "ok, ship it", or the owner editing the status line in the file | the writer agent's self-check passing |
| "change X" — a revision request | a pillar's "advance without asking" rule |
| "reject", "no" | an `Approved` status pasted by an agent |

The "advance without asking" rule of the pillars stops at a file awaiting review: that is an
owner decision, the one case those rules already except.

## Spec-only run

The `spec` command runs research and planning and stops (`WF-SPEC-05`). A product scope waits
at `requirements.md` for the owner's answer before planning starts (`WF-CORE-03`); when the
owner answers in the same conversation, the run continues; when not, the envelope returns
with `lacunas: ["awaiting owner approval: .specs/<capability>/requirements.md"]` and a later
run resumes from that file.

---

## Related

- `../SKILL.md` Step 4 — where this protocol runs
- [Documentos de Decisão — PRD, RFC e ADR](../../../referencias/documentos-de-decisao-prd-rfc-adr.md) §3 — the lifecycle of each decision document
