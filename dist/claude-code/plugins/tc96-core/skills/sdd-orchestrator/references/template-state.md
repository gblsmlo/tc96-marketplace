# Template: the state file

Saved as `.sdd/state/<ID>-<slug>.md`, git-ignored. The orchestrator's whole view of one feature
(`SDD-CORE-04`): it reads and writes this file and nothing else about the feature. Every value is
an ID, a status or one line; never a log, a diff or a review report.

## Body (copy from here down)

---

```yaml
feature: F02-approval
status: waiting      # waiting | running | gates-failed | in-review | fixing | contract-met | merged | split | dropped
wave: W1
role: backend-developer
branch: feat/F02-approval
worktree: ../.worktrees/F02-approval
round: 0             # fix rounds used; at most 2 (SDD-RUN-05)
gates: ""            # pass | fail — one line from run-gates
review: ""           # met | unmet — the unmet AC-* and failing check IDs, nothing else
notes: []            # non-blocking reviewer notes, one line each, for the owner if asked
blocking: []         # security defect or regression of a merged contract, one line each
gaps: []             # questions the implementer returned, one sentence each
next: ""             # the new item's ID, when status is split
authorization: ""    # the owner's push-and-PR words, quoted, and their scope (run or wave)
started: ""          # ISO 8601
finished: ""         # ISO 8601
```

## Transitions

| From | Event | To |
| --- | --- | --- |
| waiting | start conditions hold (`SDD-RUN-01`), `spawn-detached` exits 0 | running |
| running | `.sdd/run/<ID>.exit` exists and `.sdd/run/<ID>.result` says `done` | gates run: pass → in-review; fail → gates-failed |
| running | `.sdd/run/<ID>.result` says `gap: …` | waiting, with `gaps` filled |
| running | `.sdd/run/<ID>.exit` is non-zero, or `.result` is missing | waiting; tell the owner the run failed, with the log path |
| gates-failed | implementer resumed with the failing gates | running (round unchanged) |
| in-review | reviewer: met | contract-met |
| in-review | reviewer: unmet, round < 2 | fixing, round + 1 |
| in-review | reviewer: unmet, round = 2 | split, `next` set after the owner approves the new item |
| in-review | reviewer: blocking note | waiting, with `blocking` filled, until the owner decides |
| fixing | the fix run's `.result` says `done` | gates run, as from running |
| contract-met | push, PR and merge done under `authorization` | merged |
| any | the owner drops the feature | dropped |
