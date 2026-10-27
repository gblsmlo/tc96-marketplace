# Template: the implementer brief

The prompt file `scripts/spawn-detached` hands to the agent CLI in the feature's worktree. It
makes the detached session call the owner role as a subagent, instead of playing it, so the role
runs on its own tier (`SDD-CORE-02`). Fill the brackets; send nothing else. `[result-file]` is
the absolute path `<main checkout>/.sdd/run/<ID>.result`: the session runs inside the worktree,
and the orchestrator reads the main checkout's `.sdd/`.

## Body: first run (copy from here down)

---

Implement feature [ID] in this worktree. Call the `[role]` subagent for all of the writing; you
only relay its result.

Give the subagent exactly this:

- Read `.specs/features/[ID]-[slug]/spec.md`, `plan.md` and `contract.md`, and the files
  `plan.md` cites. Read nothing else from `.specs/`.
- Write the code and the checks `contract.md` lists, following `plan.md`'s tasks in order, each
  inside its own Surface.
- A question these files do not answer is a gap: stop, and return it in one sentence. Do not
  choose an answer (`SDD-RUN-07`).
- Commit once per task, when its check is green.

When the subagent returns, write its result to `[result-file]`, one line:
`done` · `gap: <the question>`. Do not run the gates; the orchestrator does.

## Body: fix round (copy from here down)

---

Fix round [n] of 2 for feature [ID]. Call the `[role]` subagent; you only relay its result.

Give the subagent exactly this, and nothing else:

- These checks failed or these `AC-*` are unproved: [verbatim from the state file's `review` or
  `gates`].
- Change only what makes them pass, inside the Surface in `plan.md`. Commit your diff.
- A question the files do not answer is a gap: return it in one sentence.

When the subagent returns, write its result to `[result-file]`, one line:
`done` · `gap: <the question>`.
