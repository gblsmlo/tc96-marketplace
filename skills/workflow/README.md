# workflow skills — the procedure layer over the eleven agents

Four skills, one per pillar. They decide **when** — which moment a task is in — never **who**:
that stays with the eleven agents in `agents/README.md`. Each skill routes to an existing
agent or skill; none of them re-decides architecture, product scope, or test level — those
already have an owner.

| Skill | The question it answers | Routes to (existing) |
| --- | --- | --- |
| `workflow-research` | is this task's intent actually decided yet? | `product-manager` · `product-designer` · `software-architect` · `workflow-planning` |
| `workflow-planning` | is this task executable yet — bounded, owned, with acceptance? | `project-manager` · `software-architect` · `workflow-implementation` · `workflow-research` |
| `workflow-implementation` | is this ready unit's behavior already decided, so it is safe to write? | `frontend-developer` · `backend-developer` · `test-design` · `workflow-validation` |
| `workflow-validation` | does this change have proof proportional to its risk? | `code-reviewer` · `qa-engineer` · `devops-security` · back to the pillar of origin |

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
│       ├── apetite-e-corte.md
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

## Board and PR templates

`workflow-planning/references/` carries the tool-neutral work-item templates — Epic, Story,
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

- **No `scripts/gerar-mapa-de-ids.sh`.** The 25 `WF-*` rules live in one hub section, cited
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
