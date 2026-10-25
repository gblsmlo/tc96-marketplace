# spec skills — the two documents that stand alone

Two skills, one per document a project keeps outside a feature folder. Each is
**self-contained**: it carries its own template, the text of the rules it enforces, the status
lifecycle and the owner-review step, so a person can call one without running the delivery flow
and without loading any other skill.

| Skill | The question it answers | Owner role | File |
| --- | --- | --- | --- |
| `spec-prd` | what are we building, and why, in which features and in which order? | `product-manager` | `.specs/PRD.md` |
| `spec-adr` | what did we decide that must outlive a single feature? | `software-architect` | `.specs/adr/NNNN-<slug>.md` |

A feature's own files — `spec.md`, `plan.md`, `contract.md` — are not here: they are always
written together, by `spec-writer`, so their templates live in `skills/sdd/sdd-spec-writer/`.

```
spec/
├── README.md
├── evals/                    one case per skill
└── <skill>/
    ├── SKILL.md              scope, steps, self-check, example
    └── references/
        ├── template.md       the document's body
        └── rules.md          the rule text, lifecycle and amendment or superseding procedure
```

## Decisions

1. **Rule text is copied into each skill.** The repository's other families cite a rule by ID
   and leave its text in `knowledge-base/`. These skills copy the text of the rules they
   enforce, on purpose: a spec skill must work alone, including in a project that never loaded
   the knowledge base. `DOC-*` and `SDD-*` IDs are kept, so a citation still resolves.
2. **Every document is born a draft.** The writer never approves its own file; the status moves
   only on the owner's explicit reply (`SDD-CORE-03`).
3. **The PRD is the product's, not a capability's.** One `.specs/PRD.md` names every feature,
   what each provides and consumes, and the waves they run in (`SDD-PRD-*`). It replaced the
   per-capability `requirements.md`, and with it the RFC, UX, Epic, Story and Task skills: the
   design moved into each feature's `spec.md` (UX as a section of it, when needed), the plan into
   `plan.md`, the acceptance into `contract.md`, and board items out of the flow.

## Sources

[Delivery Flow — Spec Driven Development](../../knowledge-base/fluxo-de-entrega-sdd.md)
(`SDD-*`) and [Decision Documents — PRD, RFC and ADR](../../knowledge-base/documentos-de-decisao-prd-rfc-adr.md)
(`DOC-*`).
