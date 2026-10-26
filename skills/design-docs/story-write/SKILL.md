---
name: story-write
description: Writes one feature's `story.md` in the delivery flow v2 — the one-sentence user story quoted from the PRD, the `AC-*` IDs the PRD assigns to the feature with a one-line summary each, and the features it enables from the dependency graph — pointing to the PRD instead of copying its Given / When / Then, as a `Draft`, with an executable check against the PRD, citing `SDD-SPEC-02` and default D9. Also writes the story of a new item (same `AC-*`, narrowed to the failing ones) and of a fast-lane fix. In a project on the delivery flow v2 (`story.md` bundles), use when `workflow-plan` hands `spec-writer` a feature, or someone asks to write, fix or check a feature's story file. Not for writing or changing the PRD's user stories and acceptance criteria (workflow-search, spec-prd), the feature's interfaces (spec-write), nor its checks (contract-write).
type: skill
family: design-docs
language: en
source: "[Rules](references/rules.md)"
tags:
  - skill
  - workflow
  - spec
  - story
---

# story-write

> **Who runs it.** `spec-writer`, first of the three bundle files, before `spec-write` and `contract-write`. It reads the PRD and writes one file; it decides nothing about the product.
> **Self-contained.** The template is `references/template.md`; the rule text and the defaults it applies are `references/rules.md`; the check is `scripts/self-check.sh`. Nothing here needs another skill to run.
> **Status.** Draft. Implements the `story.md` row of `workflow/foundations/phases.md` §2.

`story.md` answers one question: **who is this feature for, and which acceptance criteria does it deliver?** Template: `references/template.md`.

## Inputs

| Input | From | Missing → |
| --- | --- | --- |
| the PRD path and the feature's `F` number | `workflow-plan` | return the gap, do not guess |
| mode: bundle, new item or fast lane | `workflow-plan` | assume bundle |
| new item: the failing checks and their `AC-*` | the state file, verbatim | return the gap |
| fast lane: the defect and the `AC-*` it protects | the request | return the gap |

## Step 1: Read only the feature's part of the PRD

| Section | Take |
| --- | --- |
| Functionalities | the feature's row: its sentence and the `AC-*` it satisfies |
| User Stories | the heading and the one-sentence story each of those `AC-*` belongs to |
| Dependency Graph | the features that consume from this one |

Nothing else. A row that names no `AC-*` is a PRD defect: return the gap "F<NN> traces no AC in the PRD" to `workflow-plan`, which sends it to `workflow-search` as an amendment.

## Step 2: Write the file

From `references/template.md`:

1. **Story.** Quote the one-sentence story as the PRD wrote it. When the feature's `AC-*` come from two stories, quote both, one line each. Never reword: a reworded story is a second source of truth.
2. **Acceptance criteria delivered.** One row per `AC-*`, the summary in a few words, and the PRD heading it lives under. The Given / When / Then stays in the PRD (default D9, `SDD-SPEC-02`).
3. **Enables.** `F<NN> (enables F<MM>, F<KK>)` from the Dependency Graph, or `F<NN> (enables none)`.
4. `status: Draft`.

| Mode | What changes |
| --- | --- |
| bundle | everything above |
| new item | folder `F<NN>.<n>-<slug>`; the same story; only the `AC-*` the failing checks cite |
| fast lane | the `AC-*` the fix protects; with none, one row `— defect: <one sentence>` and `Enables` omitted |

## Step 3: Self-check

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/story-write/scripts/self-check.sh .specs/features/F03-invitations .specs/PRD.md
```

The script checks the frontmatter, the folder name, the story sentence shape, that every `AC-*` exists in the PRD and matches what the PRD assigns to the feature, and that no Given / When / Then was copied. Fix every `FAIL` before returning. Then, by reading:

| # | Check | Rule |
| --- | --- | --- |
| 1 | the story sentence is the PRD's, word for word | `SDD-SPEC-02` |
| 2 | no interface, step or check is in this file | `SDD-SPEC-02` |
| 3 | `Enables` matches the PRD's Dependency Graph | `SDD-PRD-04` |

## Examples

**Happy path.** F03 invitations, PRD row "F03 — admins invite by email — AC-01, AC-02, AC-03". Story: `> As an admin, I invite a teammate by email, so that my team joins without manual setup.` Three AC rows. `F03 (enables F04, F05)`. The script prints all `ok`.

**Robust variant.** F04 accept invitation draws `AC-04` from "Invitee joins" and `AC-05` from "Admin sees who joined". Two quoted story lines, two AC rows, each with its own PRD heading. A new item `F04.1` after `C5` failed keeps both story lines and lists only `AC-05`.

**Anti-pattern and correction.**

```markdown
### Acceptance criteria delivered
- AC-02: Given a member without the admin role, when they invite, then 403 and no email.
```

The criterion now lives in two files; a PRD amendment would leave this one stale, and the script fails "no Given / When / Then copied". Corrected:

```markdown
| AC-02 | non-admin invite is refused, no email | User Stories › Admin invites |
```

## Output

To `workflow-plan`, at most 3 lines: the file path, the `AC-*` listed, open gaps.
