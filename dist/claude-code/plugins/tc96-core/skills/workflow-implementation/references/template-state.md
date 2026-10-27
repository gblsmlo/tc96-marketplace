# Template: the state file

Saved as `.sdd/state/<delivery>/<layer>.md`, git-ignored. The whole view of one layer that
`workflow-implementation` and `workflow-review` share, and the only thing that passes between
them (`SDD-CORE-04`, `SDD-FLOW-03`): each reads and writes this file and nothing else about the
layer. Every value is an ID, a status or one line; never a log, a diff or a review report. The
index's Status column mirrors `status`, written by the orchestrator (`SDD-PLAN-11`).

## Body (copy from here down)

---

```yaml
delivery: 2026-10-27-quote-approval
layer: L2a
status: waiting      # waiting | running | gates-failed | in-review | fixing | checks-met | merged | split | dropped
role: backend-developer
branch: feat/2026-10-27-quote-approval-L2a
worktree: ../.worktrees/2026-10-27-quote-approval-L2a
round: 0             # fix rounds used; at most 2 (SDD-RUN-05)
gates: ""            # pass | fail — one line from run-gates
review: ""           # met | unmet — the failing check IDs and broken rules, nothing else
notes: []            # non-blocking reviewer notes, one line each, for the owner if asked
blocking: []         # security defect or regression of a merged layer, one line each
gaps: []             # questions the implementer returned, one sentence each
next: ""             # the new layer's ID, when status is split
pr: ""               # the layer's PR into the feature branch, once opened
authorization: ""    # the owner's push-and-PR words, quoted
started: ""          # ISO 8601
finished: ""         # ISO 8601
```

## Transitions

| From | Event | To |
| --- | --- | --- |
| waiting | start conditions hold (`SDD-RUN-01`), `spawn-detached` exits 0 | running |
| running | `.sdd/run/<delivery>/<layer>.exit` exists and `.result` says `done` | gates run: pass → in-review; fail → gates-failed |
| running | `.result` says `gap: …` | waiting, with `gaps` filled |
| running | `.exit` is non-zero, or `.result` is missing | waiting; tell the owner the run failed, with the log path |
| gates-failed | implementer resumed with the failing gates | running (round unchanged) |
| in-review | reviewer: met | checks-met |
| in-review | reviewer: unmet, round < 2 | fixing, round + 1 |
| in-review | reviewer: unmet, round = 2 | split, `next` set after the owner approves the new layer |
| in-review | reviewer: blocking note | waiting, with `blocking` filled, until the owner decides |
| fixing | the fix run's `.result` says `done` | gates run, as from running |
| checks-met | PR into the feature branch opened and merged under `authorization` | merged |
| any | the owner drops the layer | dropped |
