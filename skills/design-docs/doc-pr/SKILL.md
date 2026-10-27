---
name: doc-pr
description: Writes a pull request title and description from a change that already exists — a Conventional Commits title, a summary of what changed and why, the changes grouped by intent, linked work items and acceptance criteria, how to test, risk and rollout, the contract checks when there is one, and open questions — from the diff or commit range the caller names and the reasons the caller gives. Use whenever someone asks to write, draft, fill or improve a PR or MR description, PR body, PR title or merge request summary, or "describe this branch for review". A writer only — it reads the named diff to say what changed, but never investigates why, reviews the code or runs the tests. Not for a commit message alone, a code review (code-reviewer), or the task list behind the change (doc-tasks).
type: skill
family: design-docs
language: en
source: "[Template: Pull Request](references/template.md)"
model: rapido
effort: medio
tags:
  - skill
  - design-docs
  - pr
---

# doc-pr

> **A writer.** It follows the [writing contract](../docs/writing-contract.md): it reads the request, the files the request names (a task list, a contract, a state file) and `references/template.md`. The one command it may run reads the diff the caller named — `git log --oneline <base>..<head>` and `git diff --stat <base>..<head>`, plus `git diff` of that range when the stat is not enough to say what changed (`DD-CORE-01`). It never runs tests, opens other files or guesses a reason.

## Scope

A PR description answers one question: **what does this change do, why, and how does a reviewer check it?**

| The request is... | Go to |
| --- | --- |
| reviewing the change | `code-reviewer` |
| the tasks the change implements | `doc-tasks` |
| a defect the change fixes, not yet reported | `doc-bug` first |

**Anchor:** the change — a diff, a commit range or the caller's summary (`DD-CORE-06`). "Write my PR" in a repository with no named branch or base: read the current branch against the default base only if the caller asked for "this branch"; otherwise `blocked`, asking which range.

## Step 1: Gather the input

1. The **what**: the diff or commit range the caller named, read as above; a diff file the caller wrote (`git diff <base>..<head> > <file>`), read as a named file; or the caller's summary. With no shell (the `doc-writer` agent), a range with no file is `blocked`, asking for the file.
2. The **why**: only from the caller — the request, a linked issue, task or bug it names. The diff says what changed, never why: a reason the caller did not give is a gap with `decides: author`.
3. The **proof**: test results, a contract, a state file the caller names. A check the caller did not report as run is listed as "not run", never as passed.

## Step 2: Write

Copy the template from "Body" down.

| # | Rule | Why |
| --- | --- | --- |
| 1 | Title in Conventional Commits form, `<type>(<scope>): <imperative summary>`, under about 72 characters, with the work item ID at the end when the input gives one; `!` after the scope only when the input says the change breaks a contract | the title stands alone in history |
| 2 | Summary: one or two sentences, what and why; never "fixes bug" or "updates files" | a reviewer decides from this line how to read the rest |
| 3 | Changes are grouped by intent (behavior, schema, tests, config), not listed file by file; each bullet names what it achieves | the file list is already in the diff |
| 4 | Linked items: `Closes #N`, task IDs, `AC-*` — only those the input gives | links are copied, never searched |
| 5 | How to test: steps from the input or the task list; none given → a gap, not steps you made up | an invented test plan gets followed and proves nothing |
| 6 | Validation reports each check as passed, failed, skipped or not run, as the input says; "skipped" is never folded into "passed" | review trusts this section |
| 7 | Risk and rollout (migration, flag, rollback, breaking change): from the input; a migration or config file visible in the diff with no rollout note in the input becomes a gap | the diff shows it exists, only the author knows how it ships |
| 8 | Optional sections (Contract, Screenshots, Risk) are deleted when the input does not touch them | the reviewer reads every heading |

## Step 3: Self-check

| # | Check |
| --- | --- |
| 1 | the title matches `<type>(<scope>)?!?: <summary>` and is imperative |
| 2 | every reason, link, test step and result came from the input |
| 3 | no check is reported as passed that the input did not report as passed |
| 4 | the change list matches the diff's areas; nothing in the diff is omitted from it silently |
| 5 | every gap is inline and again under Open questions; no bracketed hint or HTML hint comment survived |

## Step 4: Return

The return block of the [writing contract](../docs/writing-contract.md) §5 — outcome (`complete`, `partial` or `blocked`), path or "inline", status, one sentence, then every gap and `(proposed)` item, then the title and the body inline, ready to paste. A file only when the caller names a path.

## Example

*"PR for this branch against main. It's T2 and T3 of F02 — customers approve or reject from the link. Tests pass locally (`bun test`: 48 pass). Closes #212."* `git log` shows 4 commits; `git diff --stat` touches `src/server/quotes.route.ts`, `src/routes/q.$token.tsx`, two test files and `drizzle/0007_quote_status.sql`. Title: `feat(quotes): approve or reject a quote from its link [F02]`. Summary from the caller's words. Changes: decision route with its tests; approve and reject buttons with a component test; a migration adding the quote status. Linked: Closes #212, T2, T3. Validation: unit and component tests passed (48), E2E not run. Risk: the migration has no rollout note → `[GAP: does the migration need a backfill or a deploy order? — decides: author]`. Outcome `partial`.
