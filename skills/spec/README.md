# spec skills — one standalone skill per spec document

Seven skills, one per document a project can keep in `.specs/` or its tracker. Each is
**self-contained**: it carries its own template, the text of the rules it enforces, the status
lifecycle and the owner-review step, so a person can call one without running a workflow pillar
and without loading any other skill.

| Skill | The question it answers | Owner role | File |
| --- | --- | --- | --- |
| `spec-prd` | what are we building, and why? | `product-manager` | `.specs/<capability>/requirements.md` |
| `spec-rfc` | how do we build it: boundaries and contracts? (RFC or design doc) | `software-architect` | `.specs/<capability>/design.md` |
| `spec-adr` | what did we decide that must outlive this increment? | `software-architect` | `.specs/adr/NNNN-<slug>.md` |
| `spec-ux` | how does the person move through it, in every screen state? | `product-designer` | `.specs/<capability>/user-experience.md` |
| `spec-epic` | what permanent capability does this backlog item represent? | `project-manager` | the tracker item |
| `spec-story` | what can a role do, and how will we know it works? | `project-manager` | the tracker item |
| `spec-task` | what is the smallest unit someone can implement and prove alone, and in what order? | `project-manager` | the tracker item, and `.specs/<capability>/tasks/NNNN-<slug>.md` |

```
spec/
├── README.md
└── <skill>/
    ├── SKILL.md              scope, steps, self-check, example
    └── references/
        ├── template.md       the document's body (spec-task: template-task.md and template-plan.md)
        └── rules.md          the rule text, lifecycle and amendment procedure
```

## Decisions

1. **Rule text is copied into each skill.** The repository's other families cite a rule by ID
   and leave its text in `knowledge-base/`. These skills copy the text of the rules they
   enforce, on purpose: a spec skill must work alone, including in a project that never loaded
   the knowledge base. `DOC-*` and `WF-*` IDs are kept, so a citation still resolves; rules
   that exist only here are `SPEC-<DOC>-*`.
2. **Every document is born a draft.** The writer never approves its own file; the status moves
   only on the owner's explicit reply (`WF-SPEC-06`). Epic, Story and Task are tracker items:
   publishing one needs the owner's yes.
3. **`workflow-spec` stays as the router.** It keeps what only an orchestrating conversation can
   do: record the project's document set once, choose which spec skills a pillar's scope needs,
   and put several drafts in front of the owner as one bundle. It no longer carries templates.
4. **The plan lives in `spec-task`.** A plan is a list of Tasks with their order, inputs and
   delivery, so it shares the Task's rules and sits beside its template.

## Sources

The text was split out of `workflow-spec/references/` and adapted: [Delivery Flow — Four
Pillars](../../knowledge-base/fluxo-de-entrega-quatro-pilares.md) (`WF-*`) and [Decision
Documents — PRD, RFC and ADR](../../knowledge-base/documentos-de-decisao-prd-rfc-adr.md)
(`DOC-*`).
