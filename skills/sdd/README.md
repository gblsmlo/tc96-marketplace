# sdd skills — Spec Driven Development

Three skills that run the delivery flow of this house: plan big, once, on the high tier; execute
small, per feature, on the mid tier, driven by scripts. The PRD itself is written by `spec-prd`,
in the [spec family](../spec/README.md); lasting technical decisions by `spec-adr`.

| Skill | The question it answers | Runs in | Calls |
| --- | --- | --- | --- |
| `sdd-spec-writer` | what does each feature expose, how is it built, and how do we prove it? | the orchestrating conversation | `repo-explorer` · `spec-writer` · `software-architect` (`spec-adr`) |
| `sdd-orchestrator` | which features run now, and is each one done? | the orchestrating conversation | the harness scripts · the implementer role, detached · `code-reviewer` · `devops-security` · `sdd-spec-writer` |
| `sdd-contract-review` | is this feature's contract met? | a new `code-reviewer` instance | — |

**The order is PRD → Spec Writer → run.** A feature with a failed contract or a gap does not go
back: it becomes a new item, written by the Spec Writer and approved by the owner
(`SDD-RUN-06`, `SDD-RUN-07`). Source: [Delivery Flow — Spec Driven
Development](../../knowledge-base/fluxo-de-entrega-sdd.md).

```
sdd/
├── README.md                     this file
├── sdd-spec-writer/
│   ├── SKILL.md
│   └── references/
│       ├── template-spec.md      what the feature exposes and consumes; UX section when needed
│       ├── template-plan.md      steps, Surface, Size, base branch, local scripts
│       └── template-contract.md  one check per AC-*; met only when every traced AC-* is proved
├── sdd-orchestrator/
│   ├── SKILL.md
│   └── references/
│       ├── template-state.md     the one file the orchestrator holds per feature
│       ├── template-brief.md     the prompt spawn-detached hands to the implementer
│       └── template-pr.md        the PR of a feature whose contract is met
└── sdd-contract-review/
    └── SKILL.md
```

## Files in `.specs/` and `.sdd/`

| File | Written by | Through |
| --- | --- | --- |
| `.specs/PRD.md` | `product-manager` | `spec-prd` |
| `.specs/adr/NNNN-<slug>.md` | `software-architect` | `spec-adr` |
| `.specs/features/<ID>-<slug>/spec.md`, `plan.md`, `contract.md` | `spec-writer` | `sdd-spec-writer` |
| `.sdd/state/<ID>-<slug>.md` | the orchestrating session | `sdd-orchestrator` |
| `.sdd/logs/`, `.sdd/run/` | the harness scripts | `scaffold-sdd-scripts` |

Every `.specs/` file is born `Draft` (an ADR `Proposed`) and moves only on the owner's reply
(`SDD-CORE-03`). `.sdd/` is runtime state, git-ignored.

## Which model runs each point

Decisions stay on the high tier, inside named agents called as subagents; code and review on the
mid tier, each in a fresh context; everything whose result is an exit code is a script
(`SDD-CORE-02`, `SDD-CORE-05`). The full table is in the hub, §3; what each tier costs per
provider is in `agents/README.md`.

## The harness

The six scripts — `init.sh`, `scripts/resolve-env`, `scripts/migrate-dev`, `scripts/run-gates`,
`scripts/spawn-detached`, `scripts/stop` — live at the root of the consuming project, written once
by the [`scaffold-sdd-scripts`](../../commands/scaffold-sdd-scripts.md) command, and read their
commands from `sdd.config.sh` (`SDD-SCR-*`). A script only one feature needs lives in that
feature's `plan.md`.

## What this family deliberately does not have

- **No board.** Registering work on a tracker is outside the flow (`SDD-CORE-06`).
- **No research or planning pillar.** Product decisions are the PRD; specification decisions are
  the bundle. A wrong decision found later is an amendment or a new item, never a return.
- **No third fix round, no tier escalation.** Two rounds, then a new item (`SDD-RUN-05`).

## Registered under

`tc96-core` in `build/claude-code.sh`, next to `spec`, `test` and `http`.

## Related

- [Skills index](../README.md)
- [Delivery Flow — Spec Driven Development](../../knowledge-base/fluxo-de-entrega-sdd.md) — the hub
  these skills implement, §8 "Skill contract"
- `agents/README.md` — the roles this flow calls
