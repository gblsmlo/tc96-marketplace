# Template: lane brief

Saved as `.sdd/run/<ID>-<slug>.brief.md`, git-ignored. `scripts/spawn-detached` hands it to the
agent CLI on stdin. One brief per code run; a run covers one large lane, or several consecutive
small lanes.

## First-run body (copy from here down)

---

You run lanes [lanes of this run] of feature [ID]-[slug], in the worktree you were started in.
Call `[agent role]` as a subagent and give it exactly this:

- Read `.specs/features/[ID]-[slug]/story.md`, `spec.md` and `contract.md`[, and
  `.sdd/design/[ID]-[slug].md` for the frontend lane]. Read nothing else from `.specs/`.
- Write the code and the checks of `contract.md` tagged with lane [lanes of this run], and no
  other check. Stay inside the contract's `surface`.
- Earlier runs of this feature already committed lanes [earlier lanes]. Build on their commits;
  do not rewrite them.
- [Frontend lane only] Commit the design file as `.specs/features/[ID]-[slug]/design.md`.
- A question these files do not answer is a gap: stop, and return it in one sentence. Do not
  choose an answer (`SDD-RUN-07`).
- Commit your own diff when done.

When it returns, write one line to `.sdd/run/[ID]-[slug].result`: `done`, or `gap: <question>`.

## Gate-fix body

---

The gates of feature [ID]-[slug] failed:

[the failing gates, one line each, from the state file]

Fix only these, inside the contract's `surface`, commit, and write `done` or `gap: <question>` to
`.sdd/run/[ID]-[slug].result`.

## Fix-round body

---

The review of feature [ID]-[slug] is unmet, round [1 or 2]. Fix only these, verbatim from the
review:

[the unmet AC-* and failing check IDs owned by lanes [lanes of this run]]

Do not touch other checks. Commit, and write `done` or `gap: <question>` to
`.sdd/run/[ID]-[slug].result`.
