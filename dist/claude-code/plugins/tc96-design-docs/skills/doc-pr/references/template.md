# Template: Pull Request

Tool-neutral: works for GitHub, GitLab or any review tool. The PR description says **what the change
does, why, and how a reviewer checks it**. The title follows Conventional Commits. Hints in
brackets are deleted when filled.

## Title

```
<type>(<scope>): <imperative summary> [<work item ID>]
```

| `type` | When |
| --- | --- |
| `feat` | a new behavior a user or consumer can see |
| `fix` | a defect corrected |
| `refactor` | structure changes, behavior does not |
| `perf` · `test` · `docs` · `build` · `ci` · `chore` | what the name says |

`!` after the scope (`feat(api)!:`) marks a breaking change, and only when the input says so.

## Body (copy from here down)

---

## Summary

[One or two sentences: what this change does and why.]

## Changes

- [Grouped by intent: what each group achieves, not a file list.]

## Linked items

- [Closes #N · task IDs · AC-* — from the input. Delete the section when none.]

## How to test

1. [From the input or the task list.]

## Validation

- [ ] [check] — passed · failed · skipped · not run, as the input reports it

## Risk and rollout

- [Migration, feature flag, deploy order, rollback, breaking change — from the input. Delete the
  section when the input touches none and the diff shows none.]

## Contract

[Only when the input names a contract: its **Met when** line verbatim, then each check with its
result. Otherwise delete.]

## Screenshots

[Only when the change is visual and the input attaches them. Otherwise delete.]

## Open questions

- [GAP: the question — decides: author or a role. Delete this section when there is none.]
