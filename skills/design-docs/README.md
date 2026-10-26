# design-docs skills — writers for every document the delivery touches

Nine skills, one per document. Each is a **writer**: it takes what was already decided and puts it
on the page in the house template. None of them searches the codebase, investigates the problem,
researches or decides scope — that work happens before the writer runs, and its result is the
writer's input. A workflow calls them at its edges; a person can call any one alone.

| Skill | The question the document answers | Default output | Model · effort |
| --- | --- | --- | --- |
| `doc-prd` | what are we building, why, in which features and order? | `.specs/PRD.md` | `medio` · `alto` |
| `doc-adr` | what did we decide that outlives this change? | `.specs/adr/NNNN-<slug>.md` | `rapido` · `medio` |
| `doc-epic` | which capability, for whom, and how do we know it paid off? | inline (tracker) | `rapido` · `medio` |
| `doc-feature` | what slice ships next, and how do we know it works? | inline (tracker) | `rapido` · `medio` |
| `doc-story` | what can one user do, and how is it proved? | inline (tracker) | `rapido` · `medio` |
| `doc-tasks` | in what order is it built, in provable pieces? | `tasks.md` beside the source | `rapido` · `medio` |
| `doc-bug` | what fails, where, and how does someone see it fail? | inline (tracker) | `rapido` · `medio` |
| `doc-spec` | what does the feature expose and consume, and how at its boundaries? | `.specs/features/<ID>-<slug>/spec.md` | `medio` · `alto` |
| `doc-pr` | what does the change do, why, and how is it checked? | inline | `rapido` · `medio` |

The contract all nine follow — what a writer may read, structure versus substance, the gap marker,
the anchor, status, the return block and the tier table — is
[docs/writing-contract.md](docs/writing-contract.md) (`DD-*`).

```
design-docs/
├── README.md
├── docs/
│   ├── writing-contract.md   the DD-* rules every skill links to
│   └── SOURCES.md            what the templates were compared against (not shipped)
├── evals/                    test cases, run with `claude plugin eval`, and model-cost.py (not shipped)
└── doc-<type>/
    ├── SKILL.md              scope, anchor, steps, self-check, example
    └── references/
        ├── template.md       the document's fields and body
        └── rules.md          doc-prd and doc-adr only: the DOC-* and SDD-* rule text, lifecycle, amendment
```

## How the documents connect

```
PRD ──► Epic ──► Feature ──► Story ──► Tasks ──► PR
 │                  │                    ▲         ▲
 │                  └──► Spec ───────────┘         │
 └──► ADR ◄── Spec                     Bug ────────┘
```

IDs born in one document are cited, not copied, by the next: a story traces `AC-03`, a task
enables it, a PR closes the task (contract §8).

## Decisions

1. **Writers, not investigators** (`DD-CORE-01`, `DD-CORE-02`). Popular document skills either
   interview the user (snarktank `create-prd`, BMAD's coaching PRD, Anthropic's `doc-coauthoring`)
   or research (BMAD discovery, spec-kit `/plan`, Kiro's bugfix design). Both stall or leak inside
   a workflow. This family follows the "record, don't invent" line — BMAD's headless mode, phuryn's
   `create-prd`, this repository's own former `spec-prd`: an unknown goes to a named gap with who
   decides it, and the writer never guesses to fill it. spec-kit's `[NEEDS CLARIFICATION]` cap of
   three was not adopted: a writer that cannot guess must not be forced to.
2. **One anchor per document** (`DD-CORE-06`). Missing the anchor returns `blocked` with the
   questions, instead of a file of placeholders that passes for progress.
3. **Structure is the writer's, substance is the input's** (`DD-CORE-03`, `DD-CORE-04`). Splitting
   needs into stories or tasks, numbering, Given / When / Then and wave order are the writer's job;
   a cut or order it derived is marked `(proposed)`. Numbers, targets, reasons and decisions come
   from the input or become gaps.
4. **The tier follows the structuring, not the importance.** The content is decided upstream, so
   no writer runs on the top tier. Measured on the eval cases (2026-10-26,
   [evals/README.md](evals/README.md)): Haiku with the skill passed 97–99% of the checks against
   Sonnet's 100%, at about a seventeenth of the cost, and lost real points only on `doc-prd` and
   `doc-spec`, which stay on `medio` · `alto`. The other seven run on `rapido` · `medio`. Without the
   skill, the pass rate was 40%.
5. **Absorbs the former `spec` family.** `spec-prd` and `spec-adr` became `doc-prd` and `doc-adr`,
   keeping their `DOC-*` and `SDD-*` rule text and their house formats, so the delivery flow reads
   the same files. They lost the analysis they did (the PRD edge sweep, the ADR's own `file:line`
   lookups): that is the owner role's work before the writer runs.
6. **The spec template keeps the delivery flow's section names** (Consumes, Provides, What already
   exists, Boundary decisions, UX, Open gaps), adding Summary, Goals and non-goals, Alternatives and
   Cross-cutting from Google-style design docs, so one file serves both uses.

## Registered under

Its own plugin, `tc96-design-docs`, in `build/claude-code.sh`. Self-contained: it carries its docs
and cites no knowledge-base note by link, so it can be enabled without the rest of tc96. The
delivery flow in `tc96-core` calls `doc-prd` and `doc-adr` by name when both plugins are enabled.

## Related

- [Skills index](../README.md)
- [Writing contract](docs/writing-contract.md)
