# Template: story.md

Saved as `.specs/features/<ID>-<slug>/story.md`. Answers one question: **who is this feature for,
and which acceptance criteria does it deliver?** Written by `spec-writer`. Rule: `SDD-SPEC-02`.

The Given / When / Then of each `AC-*` stays in the PRD (default D9). This file quotes the story
sentence and points to the criteria by ID, so a change to a criterion happens in one place.

## Fields

The file opens with these fields as YAML frontmatter, then the body. Self-check:
`scripts/self-check.sh` of `story-write`.

| Field | Meaning |
| --- | --- |
| `feature` | `<ID>-<slug>` |
| `prd` | `.specs/PRD.md`, and the amendment date when the feature came from one |
| `status` | `Draft` · `Approved` |

## Body (copy from here down)

---

### Story

> As [who], I [do what], so that [outcome].

From the PRD, User Stories, [story heading].

### Acceptance criteria delivered

| AC | One-line summary | PRD section |
| --- | --- | --- |
| AC-NN | [what it observes, in a few words] | User Stories › [story heading] |

### Enables

The features that consume from this one, from the PRD's Dependency Graph: `F<NN> (enables F<MM>, F<KK>)`.

### Out of this file

| Belongs in | What |
| --- | --- |
| `.specs/PRD.md` | the Given / When / Then of each `AC-*` |
| `spec.md` | the shape of what is provided and consumed |
| `contract.md` | the checks, the lanes, the Surface, when the contract is met |
