# Review in independent context

`WF-VAL-01`. The builder does not approve the builder's own feature — validation must inspect
the diff against the approved acceptance criteria, the Task's Surface and Risk, and the checks'
result, in a context independent from whoever implemented the change (Google, *Software Engineering at Google*, on code review culture; see
also `CC-SES-07` in [Claude Code - Sessão e Verificação](../../../../knowledge-base/claude-code-sessao-e-verificacao.md), which states the same requirement at the level of a Claude Code
subagent).

## Why this is structural, not a suggestion

An implementer who just spent time deciding how to solve a problem has already committed to a
mental model of the solution. Reviewing their own work tends to confirm that model rather than
test it — not from carelessness, but because the questions that would surface a gap are
exactly the questions already answered, in their own head, during implementation. A fresh
context does not carry that commitment.

## What "fresh context" means in practice

`code-reviewer` (the agent that carries out most of this pillar) receives the Task's:

- diff
- acceptance criterion from `workflow-planning`
- **Surface** and **Risk** lines (`template-task.md` in the `spec-task` skill)
- checks' envelope from `repo-operator`, when it returns: the checks run at the same time
  (hub §4.4)

and nothing else — **not** the conversation that produced the change.

This mirrors `CC-SES-07`: a reviewer who reads the implementer's reasoning tends to
inherit the implementer's blind spots along with the reasoning. The diff, the criterion, the
Surface, the Risk and the checks' envelope are enough to judge whether the criterion is met
inside the planned scope; the conversation is not needed for that judgment
and actively risks contaminating it.

Before reading code, the reviewer compares the diff's file list with the Surface: a file outside
it is a finding (`WF-IMPL-03`), caught without reading a line. It reads the checks' envelope
rather than running the checks again. After a fix, a new instance gets the delta instead
(`WF-VAL-06`).

## When the "independent context" is a person, not an agent

The same principle holds outside Claude Code: whoever reviews a PR should be evaluating it
against the stated acceptance criterion, not re-deriving whether they would have solved the
problem the same way. Style disagreement is not a validation finding; failure to meet the
criterion is.

## What this does not require

Independent context does not mean a different perfil, and it does not mean re-deciding
architecture. A `backend-developer` can validate another `backend-developer`'s change — the
independence that matters is "did not write this diff," not "works in a different domain."
