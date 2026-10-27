# Template: the implementer brief

The prompt file `scripts/spawn-detached` hands to the agent CLI in the layer's worktree. It makes
the detached session call the layer's owner role as a subagent, instead of playing it, so the
role runs on its own tier (`SDD-CORE-02`). Fill the brackets; send nothing else. `[result-file]`
is the absolute path `<main checkout>/.sdd/run/<delivery>/<layer>.result`: the session runs inside
the worktree, and `workflow-implementation` reads the main checkout's `.sdd/`.

## Body: first run (copy from here down)

---

Implement layer [layer] of the delivery `.specs/delivery/[delivery]/` in this worktree. Call the
`[role]` subagent for all of the writing; you only relay its result.

Give the subagent exactly this:

1. Read the delivery's index `plan.md` and your layer's file `plans/[layer]-[slug].md`. For each
   seam under **Consumes**, read only the **Provides** of the layer file it links to, or the
   merged code it names. Read the ADR sections your file cites. Read nothing else from `.specs/`,
   and never edit `plan.md`: the orchestrator keeps its progress (`SDD-PLAN-11`).
2. **Before writing any code, load with the Skill tool every skill on your layer's Skills line:
   [skill names, verbatim].** Follow each skill's procedure and self-check for the part of the
   layer it covers. Where the plan and a skill disagree on how, the skill decides; where they
   disagree on what (a **Provides** shape, a **Must hold** rule), the plan decides.
3. Build what the layer **Provides**, holding to its **Must hold**. What is under **Free to
   decide** is yours.
4. Turn green the checks under your file's **Checks**.
5. Before committing, run G1 (types and lint, formatting included; apply the formatter's fixes)
   and G2 (the project's test command, every suite). A failure that was already there before this
   layer is reported, not fixed.
6. A question these files and the skills do not answer is a gap: stop, and return it in one
   sentence. Do not choose an answer (`SDD-RUN-07`).
7. Commit your own diff on this branch, `feat/[delivery]-[layer]`.

When the subagent returns, write its result to `[result-file]`, one line:
`done` · `gap: <the question>`. Do not run the gates; `workflow-implementation` does.

## Body: fix round (copy from here down)

---

Fix round [n] of 2 for layer [layer] of the delivery `[delivery]`. Call the `[role]` subagent; you
only relay its result.

Give the subagent exactly this, and nothing else:

- These checks failed or these rules are broken: [verbatim from the state file's `review` or
  `gates`].
- Reload the skills on your layer's Skills line if this session no longer has them.
- Change only what makes them pass, inside the layer's Surface. Run G1 and G2. Commit your diff.
- A question the files do not answer is a gap: return it in one sentence.

When the subagent returns, write its result to `[result-file]`, one line:
`done` · `gap: <the question>`.
