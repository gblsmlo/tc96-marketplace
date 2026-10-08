# workflow skills — the procedure layer over the twelve agents

Four skills, one per pillar, plus one writer. The pillars decide **when** — which moment a
task is in — never **who**: that stays with the twelve agents in `agents/README.md`. Each
skill routes to an existing agent or skill; none of them re-decides architecture, product
scope, or test level — those already have an owner. `workflow-spec` is not a pillar: it
writes the `.specs/` file a pillar asked for, through the owning agent, and records the
owner's approval.

| Skill | The question it answers | Routes to (existing) |
| --- | --- | --- |
| `workflow-research` | is this task's intent actually decided yet? | `product-manager` · `product-designer` · `software-architect` · `workflow-planning` |
| `workflow-planning` | is this task executable yet — bounded, owned, with acceptance? | `project-manager` · `software-architect` · `product-designer` · `workflow-implementation` · `workflow-research` |
| `workflow-implementation` | is this ready unit's behavior already decided, so it is safe to write? | `frontend-developer` · `backend-developer` · `test-design` · `workflow-validation` |
| `workflow-validation` | does this change have proof proportional to its risk? | `code-reviewer` · `qa-engineer` · `devops-security` · back to the pillar of origin |
| `workflow-spec` | which file records this, from which template, and did the owner approve it? | `product-manager` · `software-architect` · `product-designer` · `project-manager` · back to the calling pillar |

**The order is research → planning → implementation → validation**, and a task may return one
pillar back when it discovers a gap — it never skips forward past an open decision
(`WF-CORE-03`). Source: [Fluxo de Entrega — Quatro Pilares](../../knowledge-base/fluxo-de-entrega-quatro-pilares.md).

```
workflow/
├── README.md                    this file
├── workflow-research/
│   ├── SKILL.md
│   └── references/
│       ├── separar-fato-hipotese-decisao.md
│       └── classificar-escopo.md
├── workflow-planning/
│   ├── SKILL.md
│   └── references/
│       ├── portoes.md
│       └── apetite-e-corte.md
├── workflow-spec/
│   ├── SKILL.md
│   └── references/
│       ├── project-document-set.md
│       ├── owner-review.md
│       ├── template-requirements.md
│       ├── template-design.md
│       ├── template-adr.md
│       ├── template-user-experience.md
│       ├── template-tasks.md
│       ├── template-epic.md
│       ├── template-story.md
│       └── template-task.md
├── workflow-implementation/
│   ├── SKILL.md
│   └── references/
│       └── condicoes-de-parada.md
└── workflow-validation/
    ├── SKILL.md
    └── references/
        ├── proporcionalidade-da-evidencia.md
        ├── revisao-em-contexto-independente.md
        └── template-pr.md
```

## Spec files in `.specs/`

Research and planning write their output into the project, and the envelope's `artefato`
points to it (`WF-SPEC-01`). The scope decides which files exist (`WF-SPEC-03`); the `spec`
command runs both pillars and stops before implementation (`WF-SPEC-05`). Every file is
written through `workflow-spec`, which owns the templates, reads the project's document set
(`WF-SPEC-07`) and puts each `Draft` in front of the owner before any status moves
(`WF-SPEC-06`).

| File | Pillar that asks | Agent that writes | Template, in `workflow-spec/references/` |
| --- | --- | --- | --- |
| `.specs/<feature>/requirements.md` | research | `product-manager` | `template-requirements.md` |
| `.specs/<feature>/design.md` | planning | `software-architect` | `template-design.md` |
| `.specs/<feature>/user-experience.md` | planning | `product-designer` | `template-user-experience.md` |
| `.specs/<feature>/tasks.md` | planning | `project-manager` | `template-tasks.md` |
| `.specs/adr/NNNN-<slug>.md` | planning | `software-architect` | `template-adr.md` |

Who writes, in one line: the pillar decides *when* a file is needed, the scope decides
*which*, the owning agent decides *what it says*, `workflow-spec` decides *form, location,
status and review*. The three questions `workflow-spec` asks the owner — which documents the
project keeps, whether `AGENTS.md` may hold that record, whether a draft is approved — are
why it runs in the orchestrating conversation and not inside an agent.

What each decision document is, and when it freezes:
[Documentos de Decisão — PRD, RFC e ADR](../../knowledge-base/documentos-de-decisao-prd-rfc-adr.md).

## Board and PR templates

`workflow-spec/references/` carries the tool-neutral work-item templates — Epic, Story,
Task — and `workflow-validation/references/template-pr.md` carries the PR (change-artifact)
template. Adapted from a real reference project, lemind (`studio-risine`), specifically its
`docs/product/templates/{epic,story,task}.md` and `.github/pull_request_template.md`, current
as of ADR 117 (`docs/decisions/117-o-multica-e-autoridade-unica-do-backlog.md`).

The full "discover → task" path — where product Discovery ends and the board begins, and
which pillar owns each board level — is the fourth distinction in the hub, §0.4 and the
board column in §3: research never opens a board item, planning is where Epic → Story → Task
is born, implementation executes one Task, validation reviews the PR that closes it.

Two decisions were made adapting that model into the neutral source, both confirmed with the
project owner while dogfooding `workflow-research` on this exact task:

1. **Tool-neutral, not Multica-flavored.** The reference project's templates name their
   tracker (Multica, `Work level`, `LEMI-*`) directly — coherent for them, but this source
   never embeds a runtime or tool name (see the root `README.md`). The templates here use
   generic fields (`capability`, `milestone`, `parent`) that any adapter fills.
2. **No standalone Milestone template.** The reference project's own most current decision
   (ADR 117 clause 4) already treats Milestone as a roadmap-block **property** on Epic/Story/
   Task, not a fourth narrative artifact — this family keeps that same cut rather than
   inventing a heavier one.

## What this family deliberately does not have, yet

Unlike the mature families (`react`, `test`, `http`), this one ships lean on purpose:

- **No `scripts/gerar-mapa-de-ids.sh`.** The 34 `WF-*` rules live in one hub section, cited
  inline by each skill — a generator earns its keep once a second consumer needs the same map.
- **No satellite notes.** If the hub grows past what one file should hold, the natural cut is
  one satellite per pillar (four), not a replica of `teste-de-software.md`'s seven.
- **No measured context-budget table.** That section on other family READMEs comes from a
  tiktoken measurement tool; adding fabricated numbers here would be worse than omitting it.

## Registered under

`tc96-core` in `build/claude-code.sh`, next to `test` and `http` — the families this
house's plugin map already calls "the roles that cut across any stack".

## Related

- [Skills index](../README.md)
- [Fluxo de Entrega — Quatro Pilares](../../knowledge-base/fluxo-de-entrega-quatro-pilares.md) — the hub all four skills implement, §7 "Contrato de skill"
- `agents/README.md` — "How agents hand off", the flow this family formalizes
