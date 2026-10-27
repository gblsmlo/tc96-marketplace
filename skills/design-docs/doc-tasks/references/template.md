# Template: Tasks

Saved as `tasks.md` beside the source (a feature folder, a spec), or returned inline. A task list
is **the order in which already-specified work is built**, in pieces an implementer finishes and
proves one at a time. Hints in brackets are deleted when filled.

## Fields

The file opens with these fields as YAML frontmatter, then the body. Inline, they become the first
lines of the body.

| Field | Meaning |
| --- | --- |
| `source` | the story, feature, spec or request this breaks down, by path or ID |
| `criteria` | the `AC-*` IDs of the source, all of them |

## Task line

```
- [ ] T<n> [P] [AC-…] <verb-first outcome> — <surface>
  - Depends on: <T-ids, or "none">
  - Done when: <one observable condition>
```

- `T<n>` numbers in execution order across the whole file, never restarted per phase.
- `[P]` marks a task that can run beside the other `[P]` tasks of its phase: it waits on no
  unfinished task and touches a different surface. Delete the marker otherwise.
- `[AC-…]` lists the criteria the task enables; setup and polish tasks write `[—]`.
- The surface is the file, module, route or screen the input names.

## Body (copy from here down)

---

### Phase 1 · Setup

[Only what every later task needs and the input asks for: a dependency, a config, a flag. Delete
the phase when empty.]

### Phase 2 · Foundation

[Shared pieces several criteria need: a schema change, a shared type, a provider. Delete when
empty.]

### Phase 3 · [story or criterion group, smallest usable result first]

- [ ] T[n] [AC-…] [outcome] — [surface]
  - Depends on: [...]
  - Done when: [...]

### Phase N · Polish

[Cross-cutting work the input asks for: docs, cleanup, observability. Delete when empty.]

### Order

[One line per phase with the tasks that can start together, e.g. `T2, T3 after T1`. The writer
derives it from the Depends on lines; an order the input did not state is `(proposed)`.]

### Coverage

| Criterion | Tasks |
| --- | --- |
| AC-[n] | T[n], T[n] |

### Open questions

- [GAP: the question — decides: who. Delete this section when there is none.]
