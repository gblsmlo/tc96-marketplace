# kb skill — the meta family

One skill, cross-cutting: it does not belong to a framework, it belongs to the vault itself.

| Skill | The question it answers | Source | Internal support |
| --- | --- | --- | --- |
| `kb-coverage` | for a given topic, which doc and which skill already develop it — or is it a gap? | [Skills index](../README.md) | 4 references + 1 script |

Every other family answers "how do I write/review/diagnose X in framework Y". This one answers
a question that sits above all of them: *before writing a new note or a new skill, has this
topic already been developed somewhere in this repository, and where?* The distinction it
exists to enforce is between a topic that is genuinely documented (a citable rule ID, a worked
example, a probe some skill runs) and one that only got a passing mention in a routing table —
see `kb-coverage/references/mentioned-vs-developed.md` for the full calibration.

```
kb-coverage/
├── SKILL.md
├── references/
│   ├── mentioned-vs-developed.md   the calibration — what counts as "developed", what doesn't
│   ├── indice-por-familia.md       seed index: topics already verified, one table per family
│   ├── convencoes-de-id.md         each family's rule-ID prefix, to recognize a real hit
│   └── exemplo-auditoria.md        four topics, four verdicts, fully worked
└── scripts/
    └── buscar-tema.sh              live search across knowledge-base/ and every SKILL.md
```

**It only reports.** `kb-coverage` never edits `knowledge-base/`, a `SKILL.md`, or a routing
table — when it finds a gap, closing it is a separate, explicit task.

Registered under `tc96-core` in `build/claude-code.sh`, next to `test` and `http`: those are
the families this house's plugin map already calls "the roles that cut across any stack".
