# design-docs evals

Ten cases, at least one per skill, in the layout `claude plugin eval` reads (`prompt.md`,
`case.yaml`, `graders/`, and `files/` with `place-files.sh` when the case needs inputs). Each
case checks what the [writing contract](../docs/writing-contract.md) promises: the document's
shape, nothing invented, gaps with who decides, and no investigation.

| Case | Skill | What it stresses |
| --- | --- | --- |
| `prd-quote-approval` | `doc-prd` | sections, AC IDs, waves, traceability; a target the prompt never gave |
| `adr-sessions-postgres` | `doc-adr` | one decision, a cost marked `(proposed)`, invariants left as a gap |
| `adr-no-decision-blocked` | `doc-adr` | two options and no choice: `blocked`, no file, no recommendation |
| `epic-quote-approval` | `doc-epic` | hypothesis with its target as a gap, no scope creep |
| `feature-from-prd-row` | `doc-feature` | reuse the PRD's IDs; read only the PRD |
| `story-approve-quote` | `doc-story` | a missing "so that" is a gap; no invented rule |
| `tasks-from-spec` | `doc-tasks` | task line format, AC tracing, `[P]`; decoy `src/` files |
| `bug-safari-approve` | `doc-bug` | steps, expected and actual, severity apart from priority; no root cause |
| `spec-approval-route` | `doc-spec` | shapes as given; auth as a gap; decoy `src/` files |
| `pr-from-diff` | `doc-pr` | Conventional Commits title; nothing reported as passed that was not run |

## The decoy check

`tasks-from-spec` and `spec-approval-route` place `src/` files the prompt cites but never names as
input. A writer that opens them broke `DD-CORE-02`. The self-reported read list is not enough, so
the runs measure it: after each run, a `src/` file whose access time moved past its modification
time was read (the filesystem must update atime on read, as `relatime` does for a file just
copied). The result goes in `<run>/decoy-reads.txt`, and the "did not read `src/`" grader uses it.

## Cost per model vs result

Every skill declares its tier, so the suite also runs each case with the skill on both models and
compares what the cheaper one loses. A workspace iteration has three configurations per case:

```
iteration-N/<case>/
├── eval_metadata.json
├── with_skill/      the skill, on Sonnet
├── haiku_skill/     the skill, on Haiku
└── without_skill/   no skill (the baseline)
    ├── outputs/  grading.json  timing.json  [decoy-reads.txt]
```

`python3 model-cost.py <workspace>/iteration-N` writes `model-cost.md` there: pass rate, run time
and an uncached list-price cost per model, per case and in total. The token count is the run's
cumulative total with no input/output split, so the dollars are an upper bound; the ratio between
the models is the number to read.

### Results — 2026-10-26

**Iteration 2**: every case, the skill on each model, one run each.

| Model | Pass rate | Cost, all 10 cases | Per passed assertion | Mean seconds |
| --- | --- | --- | --- | --- |
| Sonnet 5.5, with the skill | 100% (70/70) | $1.67 | $0.0239 | 85 |
| Haiku 5.5, with the skill | 97% (68/70) | $0.10 | $0.0014 | 110 |
| no skill | 40% | — | — | 38 |

Haiku cost about 17 times less. It used more tokens (94k against 80k per run) and more time, so
the saving is all price per token. Its two misses fell on `doc-prd` (a user group and two criteria
added without `(proposed)`) and `doc-spec` (`grep -r` over the project to find a spec the prompt
mentioned without a path, which opened the decoys).

**Iteration 3**: the five skills moved to `rapido` (`doc-adr`, `doc-epic`, `doc-feature`,
`doc-story`, `doc-tasks`) re-run on Haiku, two runs per case, against Sonnet's iteration-2 runs.

| Model | Pass rate | Cost per run of the six cases | Mean seconds |
| --- | --- | --- | --- |
| Sonnet 5.5 | 100% (36/36) | $0.93 | 53 |
| Haiku 5.5 | 99% (71/72) | $0.06 | 92 |

The one miss: a `doc-story` run listed three exclusions under "Out of this story" without marking
them `(proposed)`. The graders also found Haiku noisier than Sonnet on what no assertion checks —
extra `(proposed)` costs and alternative questions in the ADR, an epic run that skipped the return
block, formatting slips — but none of it invented substance. No run opened a decoy.

**What changed after the runs, not re-run yet:** the contract forbids hunting for a document the
input only mentions (the `doc-spec` miss); every skill spells out the return block instead of only
linking it (the skipped return block); `doc-story` marks an exclusion it adds as `(proposed)` (the
story miss).

**The tiers that follow:** `doc-prd` and `doc-spec` stay on `medio` · `alto`, where Haiku lost
points. The other seven run on `rapido` · `medio`.
