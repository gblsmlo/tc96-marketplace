---
name: doc-bug
description: Writes a bug report from facts the reporter already has — a specific title, summary, environment, numbered steps to reproduce, expected versus actual result, the behavior that must stay unchanged, frequency, severity and priority as separate fields, evidence copied verbatim, and workaround — as a tracker-ready body or a file, marking every missing fact as a gap. Use whenever someone asks to write, file, log, clean up or rewrite a bug, defect, issue or incident ticket, or pastes a stack trace, error, screenshot description or Slack complaint and wants it turned into a proper report. A writer only — it does not reproduce the bug, read the code, find the root cause or propose a fix. Not for a new behavior (doc-story), the fix's task list (doc-tasks), or the fix's PR (doc-pr).
source: "[Template: Bug](references/template.md)"
model: haiku
effort: medium
tags:
  - skill
  - design-docs
  - bug
---

# doc-bug

> **A writer.** It follows the [writing contract](../../docs/design-docs/writing-contract.md): it reads the request, the files the request names (a log, a transcript, a screenshot) and `references/template.md` — nothing else (`DD-CORE-01`, `DD-CORE-02`). It never runs the steps, opens the code or guesses a cause.

## Scope

A bug report answers one question: **what fails, where, and how does someone else see it fail?** One defect per report: two failures with different steps are two reports.

| The request is... | Go to |
| --- | --- |
| behavior that never existed and is wanted | `doc-story` |
| the steps to fix it | `doc-tasks` |
| the fix, once written | `doc-pr` |

**Anchor:** what happened, and what was expected instead (`DD-CORE-06`). "It's broken" with no actual or expected result is `blocked`: return "what did you see, and what did you expect to see?"

## Step 1: Sort the input

Sort the reporter's words into: actual result, expected result, steps, environment (version or build, OS, browser, device, account or role, data), frequency, impact, evidence, workaround. Paraphrase the reporter's prose; copy evidence (errors, logs, stack traces, IDs) verbatim.

## Step 2: Write

Copy the template from "Body" down.

| # | Rule | Why |
| --- | --- | --- |
| 1 | Title: `<what fails> when <condition>`, specific enough to find among a hundred bugs; never "X is broken" | the title is the search key |
| 2 | Steps are numbered, one action each, starting from a state someone else can reach; a step the input skipped is a gap with `decides: reporter` | a report nobody can reproduce gets closed |
| 3 | Expected and actual are separate and observable; expected comes from the input, never from what you think the product should do | the gap between them is the bug (`DD-CORE-03`) |
| 4 | Unchanged behavior lists what must keep working, from the input; delete the section when the input names none | it is the regression guard of the fix |
| 5 | Severity is technical impact, priority is urgency; copy what the input gives. A severity read from the stated impact is `(proposed)`; priority is never proposed — it is the triager's | the two answer different people |
| 6 | Evidence is verbatim and trimmed to the relevant lines; secrets, tokens and personal data are masked | the reader needs the signal, not the dump |
| 7 | No cause, no fix, no file blamed: a hypothesis the reporter states goes under Notes as `(hypothesis)` | the writer does not investigate (`DD-CORE-02`) |

## Step 3: Self-check

| # | Check |
| --- | --- |
| 1 | one defect; the title names what fails and when |
| 2 | numbered steps, expected and actual present (or gaps) |
| 3 | environment lists only what the input gave; the rest is a gap or omitted |
| 4 | severity and priority are separate fields; priority is not invented |
| 5 | no cause or fix asserted; secrets masked |
| 6 | every gap is inline and again under Open questions; no bracketed hint survived |

## Step 4: Return

The return block of the [writing contract](../../docs/design-docs/writing-contract.md) §5 — outcome (`complete`, `partial` or `blocked`), path or "inline", status, one sentence, then every gap and `(proposed)` item. With no path named, the body goes inline, ready to paste.

## Example

*"Customers on Safari can't approve quotes — the button does nothing. Chrome is fine. Console shows `TypeError: crypto.randomUUID is not a function`. Started after Tuesday's deploy. It's blocking 3 big deals."* Title: "Approve button does nothing on Safari". Environment: Safari `[GAP: which version and OS? — decides: reporter]`; Chrome works. Steps: 1. Open a quote link in Safari. 2. Click Approve. Expected: the quote is marked approved. Actual: nothing happens; the console shows the error, verbatim. Unchanged: approval on Chrome. Frequency: `[GAP: every time? — decides: reporter]`. Severity: `(proposed) critical — approval is impossible for Safari users`. Priority: `untriaged`. Notes: "started after Tuesday's deploy" (reporter). Outcome `partial`.
