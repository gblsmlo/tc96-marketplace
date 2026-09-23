# Review in independent context

`WF-VAL-01`. The builder does not approve the builder's own feature — validation must inspect
the approved acceptance criteria and the diff in a context independent from whoever
implemented the change (Google, *Software Engineering at Google*, on code review culture; see
also `CC-SES-07` in [Claude Code - Sessão e Verificação](../../../../knowledge-base/claude-code-sessao-e-verificacao.md), which states the same requirement at the level of a Claude Code
subagent).

## Why this is structural, not a suggestion

An implementer who just spent time deciding how to solve a problem has already committed to a
mental model of the solution. Reviewing their own work tends to confirm that model rather than
test it — not from carelessness, but because the questions that would surface a gap are
exactly the questions already answered, in their own head, during implementation. A fresh
context does not carry that commitment.

## What "fresh context" means in practice

`code-reviewer` (the agent that carries out most of this pillar) should receive:

- the diff
- the acceptance criterion from `workflow-planning`
- **not** the conversation that produced the change

This mirrors `CC-SES-07` exactly: a reviewer who reads the implementer's reasoning tends to
inherit the implementer's blind spots along with the reasoning. The diff plus the criterion is
enough to judge whether the criterion is met; the conversation is not needed for that judgment
and actively risks contaminating it.

## When the "independent context" is a person, not an agent

The same principle holds outside Claude Code: whoever reviews a PR should be evaluating it
against the stated acceptance criterion, not re-deriving whether they would have solved the
problem the same way. Style disagreement is not a validation finding; failure to meet the
criterion is.

## What this does not require

Independent context does not mean a different perfil, and it does not mean re-deciding
architecture. A `backend-developer` can validate another `backend-developer`'s change — the
independence that matters is "did not write this diff," not "works in a different domain."
