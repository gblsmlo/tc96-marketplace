# design-docs skills — a feature's interfaces and proof

> **Status:** Draft, 2026-10-26. Written for the delivery flow v2 (`workflow/README.md`, itself a
> draft).

Three skills, one per design document a feature keeps in its folder. Each follows the layout of the
[spec family](../spec/README.md): **self-contained**, with its own template, the text of the rules
it enforces, the defaults it applies, and an executable self-check, so it works without loading
the knowledge base or another skill.

| Skill | The question it answers | Writer | File |
| --- | --- | --- | --- |
| `story-write` | who is this feature for, and which acceptance criteria does it deliver? | `spec-writer` | `.specs/features/<ID>-<slug>/story.md` |
| `spec-write` | what does this feature expose and consume? | `spec-writer` | `.specs/features/<ID>-<slug>/spec.md` |
| `contract-write` | how do we prove this feature works? | `spec-writer` | `.specs/features/<ID>-<slug>/contract.md` |

`workflow-plan` calls the three, in this order, for each feature of an approved PRD:
`story.md` → `spec.md` → `contract.md`, because the contract proves the invariants the spec
declares and traces the `AC-*` the story lists.

```
design-docs/
├── README.md
└── <skill>/
    ├── SKILL.md              inputs, steps, self-check, examples
    ├── references/
    │   ├── template.md       the document's body
    │   └── rules.md          the rule text, the v2 defaults and the lifecycle
    └── scripts/
        └── self-check.sh     structural probes; exit 1 on any FAIL
```

## Why the spec family is the base, and the `spec` command is not

| Candidate | What it is | Used as |
| --- | --- | --- |
| `skills/spec/` (`spec-prd`, `spec-adr`) | one self-contained skill per document: template, rules copied in, owner review, self-check, evals | the layout and the decisions of this family |
| `commands/spec.md` | an orchestration command: PRD, then `sdd-spec-writer`, then stop | not a base: it orders writers, it writes nothing; `workflow-plan` plays that role in v2 |

## Decisions

1. **Rule text is copied into each skill**, as in the spec family, with the IDs kept so a citation
   still resolves. A v2 change to a rule is written after the rule, not over it.
2. **Every document is born a draft.** The writer never approves its own file (`SDD-CORE-03`).
3. **Self-checks are scripts.** What a script can prove (an `AC-*` without a check, a lane with no
   check, a consumed item its provider does not provide) is not left to reading.
