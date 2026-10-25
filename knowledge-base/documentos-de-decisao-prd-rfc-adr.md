---
titulo: Decision Documents — PRD, RFC and ADR
aliases:
  - PRD, RFC and ADR
  - Decision documents
tags:
  - workflow
  - documentation
  - architecture
  - product
  - reference
source: "Michael Nygard, Documenting Architecture Decisions (2011, ADR format: context, decision, status, consequences); IETF, the RFC series as a record of a proposal open to comment; Aridane Martín, PRD vs ADR vs RFC: The Documents Every Engineer Should Know (2026-08-09, secondary synthesis of the PRD → RFC → ADR chain)"
verificado-em: 2026-10-07
---
# Decision Documents — PRD, RFC and ADR

> **What this note is.** The rule for **which document records which decision**, when it is born,
> when it freezes and where it lives. It gives a citable ID to three documents that are often treated
> as interchangeable: PRD, RFC and ADR.
>
> **What it is not.** It is not the delivery flow: the *when* of each pillar is
> [Delivery Flow — Four Pillars](fluxo-de-entrega-quatro-pilares.md), and that note is the one that says which
> pillar writes which file in `.specs/`. This note says what each document **is**.
>
> **Why it exists.** A decision that exists only in the conversation or in the code gets reconstructed backwards
> by whoever arrives later, person or agent. The three documents keep the *why*
> at three different moments: the intent, the proposal and the record.

Sources consulted on **2026-10-07**. See [Sources consulted](#sources-consulted).

---

## 0. Before anything else: three questions, three documents

| Document | Question | Who writes it | When |
| --- | --- | --- | --- |
| **PRD** | what are we going to build, and why? | `product-manager` | before design and code |
| **RFC** | how do I propose to build it, and what do you think? | `software-architect` | before committing to a design, only while the decision is open |
| **ADR** | what did we decide, and why? | `software-architect` | at the moment of the decision, often when closing an RFC |

The three form a chain: the PRD fixes the intent, one or more RFCs propose the how, and each
architecture choice an RFC resolves becomes an ADR. A large initiative may have one PRD,
a few RFCs and a dozen ADRs; a one-line fix has none (`DOC-CORE-02`).

**Design doc × RFC.** A technical design with no real alternative under debate is a *design doc*,
not an RFC. Both are legitimate; calling one by the other's name is not (`DOC-RFC-03`).

---

## 1. How to use this doc

### For a person

Before writing, ask which of the three questions in §0 is open. If none is,
do not write a document: deliver.

### For a coding agent

When writing the output of Research or Planning to `.specs/`, use §4 to know which
file each decision lives in, and §3 to know whether the file can still change. The skill that
writes is `workflow-spec`; the pillar only requests the file.

### Conventions

`MUST`/`NEVER` are normative, as in the rest of the knowledge-base. **†** marks a decision
of this doc, with no direct parallel in a single external source.

---

## 2. Decision tree: which document to write

```
Is WHAT to build and WHY still unaligned?
├── yes → PRD
└── no
    Is there a proposal for HOW to build it, with a real alternative, still undecided?
    ├── yes → RFC
    └── no
        Has a technical decision already been made that will outlast this increment?
        ├── yes → ADR
        └── no
            Is there a technical design to record, with no alternative under debate?
            ├── yes → design doc
            └── no → no document; deliver
```

An RFC opened to approve what is already built is theater: the right record is an ADR
(`DOC-RFC-01`).

---

## 3. Lifecycle

| Document | States | Changes when |
| --- | --- | --- |
| PRD | `Draft` → `In review` → `Approved` | freely during discovery; after `Approved`, only through a deliberate return to Research, as a dated amendment (`DOC-PRD-04`) |
| RFC | `Draft` → `In review` → `Accepted` \| `Rejected` | revised during the comment period; closes on the decision date, with the owner deciding (`DOC-RFC-02`) |
| Design doc | `Draft` → `In review` → `Accepted` | revised until accepted; afterwards, only through a dated amendment |
| ADR | `Proposed` → `Accepted` → `Superseded by ADR-NNNN` | freely while `Proposed`; after `Accepted`, never; the new decision is another ADR (`DOC-ADR-02`) |

The debate recorded in an RFC is worth as much as the outcome: it is what answers, a year later,
why the obvious alternative was discarded.

The owner is the one who moves the status, with an explicit answer in the conversation; the agent that wrote it never
approves its own document (`WF-SPEC-06`, in
[Delivery Flow — Four Pillars](fluxo-de-entrega-quatro-pilares.md) §5).

---

## 4. Where each document lives in `.specs/`

| Document | File | Template |
| --- | --- | --- |
| PRD | `.specs/<capability>/requirements.md` | `spec/spec-prd/references/template.md` |
| RFC or design doc | `.specs/<capability>/design.md` | `spec/spec-rfc/references/template.md` |
| ADR | `.specs/adr/NNNN-<slug>.md` | `spec/spec-adr/references/template.md` |

The folder belongs to the capability, not to the delivery: PRD and design doc follow the capability for as long as
it exists and change by amendment (`WF-SPEC-08`, in
[Delivery Flow — Four Pillars](fluxo-de-entrega-quatro-pilares.md) §5). The ADR stays outside
it because an architecture decision usually applies to more than one capability, and the numbering
is a single one for the repository (`DOC-ADR-03`). `user-experience.md` and the plan in `tasks/` are not decision
documents of this note; their owner and their moment are in
[Delivery Flow — Four Pillars](fluxo-de-entrega-quatro-pilares.md) §5.

---

## 5. Normative rules

Convention: `MUST`/`NEVER` are normative. **†** marks a decision of this doc.

### `DOC-CORE-*` — what applies to all three

| ID | Rule |
| --- | --- |
| `DOC-CORE-01` | Each document **MUST** answer a single question from §0; a document that answers two **NEVER** stays that way, it is two documents. |
| `DOC-CORE-02` | The number of documents **MUST** be proportional to the cost of getting the decision wrong; opening a document for a change with no real trade-off **NEVER**. |

### `DOC-PRD-*` — PRD

| ID | Rule |
| --- | --- |
| `DOC-PRD-01` | The PRD **MUST** declare explicit non-goals; a vague non-goal **NEVER**, it is the door to scope creep. |
| `DOC-PRD-02` | Every requirement **MUST** have a metric or a verifiable scenario; a requirement with no measure **NEVER** is a requirement, it is a wish. |
| `DOC-PRD-03` | The PRD **NEVER** contains technical design (schema, API contract, service boundary); that **MUST** go to an RFC, design doc or ADR. |
| `DOC-PRD-04` | An `Approved` PRD **MUST** be frozen; a change after that returns to Research and enters as a dated amendment at the end of the file, approved by the owner; rewriting the approved text, or editing silently, **NEVER**. |

### `DOC-RFC-*` — RFC

| ID | Rule |
| --- | --- |
| `DOC-RFC-01` | An RFC **MUST** open only for a decision not yet made; an RFC to approve what is already built **NEVER**, the record is an ADR. |
| `DOC-RFC-02` | An RFC **MUST** have an owner who decides and a decision date; an RFC with no deadline **NEVER**, it blocks the work that waits on it. |
| `DOC-RFC-03` | An alternative in an RFC **MUST** be real, with the reason it was discarded; a straw-man alternative **NEVER**. With no real alternative, the document **MUST** declare itself a design doc. |
| `DOC-RFC-04` | A resolved RFC **MUST** record the decision and list the ADRs it produced. † |

### `DOC-ADR-*` — ADR

| ID | Rule |
| --- | --- |
| `DOC-ADR-01` | An ADR **MUST** record a single decision; three choices are three ADRs. |
| `DOC-ADR-02` | An `Accepted` ADR is **NEVER** edited; a decision that changes **MUST** become a new ADR, and the old one receives only `Superseded by ADR-NNNN` in its status. |
| `DOC-ADR-03` | An ADR **MUST** live in the code repository, in `.specs/adr/NNNN-<slug>.md`, numbered in sequence with four digits; an ADR in a wiki **NEVER**. † |
| `DOC-ADR-04` | An ADR **MUST** record the consequences, cost included, and the discarded alternatives; recording only the gain **NEVER**. |

### Count

**14 rules** in four families.

| Family | Rules |
| --- | --- |
| `DOC-CORE-*` | 2 |
| `DOC-PRD-*` | 4 |
| `DOC-RFC-*` | 4 |
| `DOC-ADR-*` | 4 |

---

## 6. Skill contract

### What to load

```
WHEN WRITING requirements.md:      § 0, § 3 + DOC-CORE-*, DOC-PRD-*
WHEN WRITING design.md:            § 0, § 2, § 3 + DOC-CORE-*, DOC-RFC-*
WHEN WRITING or SUPERSEDING an ADR: § 3, § 4 + DOC-ADR-*
NEVER:                             this note for an execution task (a fix, refactor or technical adjustment)
                                   (it does not open a decision document, DOC-CORE-02)
```

### How to cite

> `DOC-ADR-02` — ADR 0007 chose PostgreSQL and the team wants to switch to SQLite in the
> test environment. Editing 0007 erases the why of the original choice; the right move is ADR 0012,
> and 0007 receives `Superseded by ADR-0012`.
> See [Decision Documents — PRD, RFC and ADR](documentos-de-decisao-prd-rfc-adr.md) § 3.

---

## 7. Bridges to the stack

| Decision | What **not** to do | The bridge |
| --- | --- | --- |
| When each `.specs/` file is written, and by which pillar | decide it here | [Delivery Flow — Four Pillars](fluxo-de-entrega-quatro-pilares.md) §5, `WF-SPEC-*` |
| The format of the architecture decision | invent another one | `software-architect`, "Output format": the ADR inherits axis, invariants and cost |
| The format of the product decision | invent another one | `product-manager`, "Writing a spec / PRD" |
| Acceptance scenario for a requirement | write prose | `spec/spec-story/references/template.md` |

---

## Sources consulted

- Michael Nygard, *Documenting Architecture Decisions* (2011) — the ADR format with context,
  decision, status and consequences, and the rule of never rewriting an accepted ADR.
- IETF, the RFC series — the origin of the name and of the model of a proposal open to comment.
- Aridane Martín, *PRD vs ADR vs RFC: The Documents Every Engineer Should Know* (2026-08-09) —
  **secondary** source: the PRD → RFC → ADR chain, the anti-patterns and the adoption order.

**What could not be verified against a primary source in this version:** the texts by Nygard and the
IETF were not reread on this date; the `DOC-*` rules are our own synthesis. The secondary source
has two internal inconsistencies, resolved here: the `Superseded` state is missing from its RFC
template (here the RFC closes in `Accepted` or `Rejected`, and what gets superseded is the ADR), and
its ADR template has no alternatives section (here it does, `DOC-ADR-04`).

---

## Related

- [Delivery Flow — Four Pillars](fluxo-de-entrega-quatro-pilares.md) — §5, where the
  `.specs/` files enter the flow
- `skills/workflow/workflow-spec/` — the skill that writes each document in this note, with its templates
- `agents/software-architect.md` — writes `design.md` and the ADRs
- `agents/product-manager.md` — writes `requirements.md`
