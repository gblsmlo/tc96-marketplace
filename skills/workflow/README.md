# workflow skills — delivery flow v2

> **Status:** Draft, 2026-10-26. These skills implement `workflow/README.md` at the repository
> root, itself a draft. Until the owner approves it, the [sdd family](../sdd/README.md) and its hub
> stay the rule.

One skill per phase. The bundle's three files are written with `story-write`, `spec-write` and `contract-write`, in the [design-docs family](../design-docs/README.md). Each phase closes with one output, and each move of work between phases is
a handoff numbered in `workflow/foundations/handoffs.md` (`H1`…`H17`).

| Skill | Phase | Output | Runs in | Calls |
| --- | --- | --- | --- | --- |
| `workflow-search` | 1. Search | `PRD.md` and the evidence file | the orchestrating conversation | `repo-explorer` · `web-researcher` · `product-manager` (`spec-prd`) |
| `workflow-plan` | 2. Plan | per feature: `story.md`, `spec.md`, `contract.md` | the orchestrating conversation | `spec-writer` with `story-write`, `spec-write`, `contract-write` · `repo-explorer` when a fact is missing · `software-architect` (`spec-adr`) |
| `workflow-implementation` | 3. Implementation | commits and a green gate summary per feature | the orchestrating conversation | the harness scripts · `product-designer` · the feature implementer · one discipline agent per large lane |
| `workflow-review` | 4. Review | merge, or a new item back to Plan | the orchestrating conversation | `code-reviewer` (`sdd-contract-review`) · `devops-security` · the lane that owns a failing check |

**The order is Search → Plan → Implementation → Review.** Nothing goes back to a closed phase: a
product change is a PRD amendment, a spec that turned out short is a new item (`SDD-RUN-06`).

```
workflow/
├── README.md                         this file
├── workflow-search/
│   ├── SKILL.md
│   └── references/template-evidence.md   claims, verdicts, evidence and repo facts
├── workflow-plan/
│   └── SKILL.md                      calls story-write, spec-write and contract-write (design-docs)
├── workflow-implementation/
│   ├── SKILL.md
│   └── references/template-lane-brief.md   the prompt each lane's agent receives
└── workflow-review/
    └── SKILL.md
```

## Defaults until the owner decides

`workflow/README.md` leaves nine questions open. These skills need an answer to run, so each takes
the default below. Each default is stated once, in the skill that applies it, and changes in that
one place.

| # | Open question | Default | Applied in |
| --- | --- | --- | --- |
| D1 | where Surface, Size, base branch and local scripts live | `contract.md` frontmatter and its **Delivery** section | `workflow-plan` |
| D2 | lanes in parallel or in sequence | design starts on bundle approval; code lanes run in sequence in one worktree: backend, AI, DevOps, tooling, frontend, QA | `workflow-implementation` |
| D3 | worktree and PR per feature or per lane | one worktree and one PR per feature | `workflow-implementation` |
| D4 | what makes a lane large | the lane alone is estimated above 150 changed lines, half the review budget | `workflow-plan` |
| D5 | who runs a large tooling lane | tooling is never large; the feature implementer runs it | `workflow-plan` |
| D6 | where claims and evidence live between Search and Plan | `.specs/search/<YYYY-MM-DD>-<slug>.md`, `Draft`, sent with the PRD | `workflow-search` |
| D7 | does the PRD keep Traceability and Open gaps | yes, `SDD-PRD-01` unchanged | `workflow-search` |
| D8 | what the design lane delivers | screens and states in `.sdd/design/<ID>-<slug>.md`, committed by the frontend run as `design.md` in the feature folder, reviewed with the PR | `workflow-implementation` |
| D9 | does `story.md` repeat the PRD story | it quotes the one-sentence story and lists `AC-*` IDs; Given / When / Then stays in the PRD | `workflow-plan` |

## Files in `.specs/` and `.sdd/`

| File | Written by | Through |
| --- | --- | --- |
| `.specs/search/<date>-<slug>.md` | the orchestrating session | `workflow-search` |
| `.specs/PRD.md` | `product-manager` | `spec-prd`, from `workflow-search` |
| `.specs/features/<ID>-<slug>/story.md`, `spec.md`, `contract.md` | `spec-writer` | `workflow-plan` |
| `.specs/features/<ID>-<slug>/design.md` | `product-designer`; committed by the frontend run | `workflow-implementation` |
| `.sdd/state/<ID>-<slug>.md` | the orchestrating session | `workflow-implementation`, `workflow-review` |

Every `.specs/` file is born `Draft` and moves only on the owner's reply (`SDD-CORE-03`). The
harness scripts are the same six as the SDD flow, written by `scaffold-sdd-scripts`.
