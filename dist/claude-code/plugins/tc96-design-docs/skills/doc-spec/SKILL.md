---
name: doc-spec
description: Writes the technical spec (design doc) of one feature or change from design decisions already made — summary, goals and non-goals, what it consumes and from whom, what it provides with an exact shape, invariants and errors a consumer can code against, the facts about existing code the caller supplied, boundary decisions, alternatives considered, cross-cutting concerns, an optional UX section, and open gaps — as a `Draft` `spec.md`. Use whenever someone asks to write, draft or revise a spec, tech spec, design doc, RFC-style design, or a feature's `spec.md`, or to turn decided interfaces, data shapes and trade-offs into a document others implement against. A writer only — it does not read the codebase, explore options or choose the design. Not for the product's requirements (doc-prd), a decision that outlives the feature (doc-adr), or the build steps (doc-tasks).
source: "[Template: Spec](references/template.md)"
model: sonnet
effort: high
tags:
  - skill
  - design-docs
  - spec
---

# doc-spec

> **A writer.** It follows the [writing contract](../../docs/design-docs/writing-contract.md): it reads the request, the files the request names (the PRD, the providers' specs, repo-search facts someone else gathered) and `references/template.md` — nothing else (`DD-CORE-01`, `DD-CORE-02`). Facts about existing code arrive in the input with their `file:line`; the writer never looks them up, and never opens a cited file to check it — a citation is copied as given.

## Scope

A spec answers one question: **what does this feature expose and consume, and how is it built at its boundaries?**

| The request is... | Go to |
| --- | --- |
| why the feature exists and its acceptance criteria | `doc-prd` or `doc-feature` |
| a decision other features will depend on after this one ships | `doc-adr`, cited here as `ADR-NNNN` |
| the ordered steps and files to build it | `doc-tasks` |

**Anchor:** what the feature provides or changes (`DD-CORE-06`).

**Default path:** `.specs/features/<ID>-<slug>/spec.md` when the caller gives a feature ID; otherwise the path the caller names, or inline.

## Step 1: Sort the input

Sort into: goals and non-goals; each provided item with whatever shape the input gives; each consumed item and its provider; facts about existing code (with their `file:line`); decisions and their reasons; alternatives that were weighed; security, privacy, observability and migration notes; UX flow and states, if any.

## Step 2: Write

Copy the template from "Body" down.

| # | Rule | Why |
| --- | --- | --- |
| 1 | Each provided item gets a shape a consumer can code against — type or schema, route with method, status codes and body, event name and payload — from the input; a field, status or type the input leaves open is a gap, never a plausible guess | a guessed shape is coded against and breaks later (`DD-CORE-03`) |
| 2 | Each provided item lists its invariants and the errors a consumer sees; invariants come from the input, each worded so a test can prove it | the contract checks prove these |
| 3 | Each consumed item names its provider and where its shape is defined (the provider's spec section, or `file:line` the input gave) | a consumer without a source codes against a guess |
| 4 | "What already exists" holds only facts the input supplied, each with its `file:line`; none supplied → `none supplied` | the writer does not search (`DD-CORE-02`) |
| 5 | Boundary decisions: one line each, decision and reason, from the input; a decision the input marks as lasting beyond this feature is flagged "→ ADR" | `doc-adr` records it |
| 6 | Alternatives considered: only those the input weighed, each with why it lost; delete the section when none | no straw men |
| 7 | Non-goals are written, not implied; cross-cutting and UX sections are deleted when the input does not touch them | `DD` style §6 |
| 8 | No step order, file list or command: that is `doc-tasks` | one question per document |
| 9 | `status: Draft`; delete every bracketed hint | `DD-CORE-07` |

## Step 3: Self-check

| # | Check |
| --- | --- |
| 1 | every provided item has a shape, invariants and errors (or gaps for each open part) |
| 2 | every consumed item names one provider and where its shape lives |
| 3 | no field, status code, type, `file:line` or decision appears that the input did not give |
| 4 | non-goals present; no build steps leaked in |
| 5 | decisions flagged "→ ADR" are listed in the return |
| 6 | every gap is inline and again under Open gaps, with who decides; status is `Draft` |

## Step 4: Return

The return block of the [writing contract](../../docs/design-docs/writing-contract.md) §5 — outcome (`complete`, `partial` or `blocked`), path or "inline", status, one sentence, then every gap and `(proposed)` item, plus every decision flagged "→ ADR".

## Example

*"Spec for F02 approval. Provides: POST /quotes/:id/decision with body {decision: 'approve'|'reject'}, 200 with the quote, 410 if expired, 409 if already decided; emits `quote.approved` with quoteId and approvedAt. Consumes the signed link token from F01 (see F01 spec §Provides). Facts: quotes table has no status column (src/db/schema.ts:40). Decision: links are signed, not stored — we want that for every future link."* Provides: the route with its body and three statuses, the event with its payload; the auth on the route is not stated → `[GAP: who may call it — anyone with the token, or a session too? — decides: software-architect]`. Consumes: the token from F01. Existing: the schema fact with its line. Boundary: "links are signed, not stored" → ADR. Outcome `partial`; return lists the ADR flag.
