# Sources of the design-docs family

Provenance for maintainers re-checking a template against what it was compared to. No doc links
here, so the build and the `.skill` packages leave this file out and no run loads it.

Compared on 2026-10-26.

## Skills and prompts compared

- github/spec-kit — `templates/commands/specify.md`, `clarify.md`, `tasks.md`, `templates/spec-template.md`: `[NEEDS CLARIFICATION]` markers, the task line `- [ ] T001 [P] [US1] …`, phases Setup → Foundational → per story → Polish
- AWS Kiro specs (kiro.dev/docs/specs) — `requirements.md` with EARS, `design.md`, `tasks.md`; the bugfix spec's current / expected / unchanged behavior
- BMAD-METHOD v6.12 — `bmad-prd` (coaching and headless modes, `assumptions[]`, `open_questions[]`, `complete` / `partial` / `blocked`), `bmad-create-epics-and-stories` (no story depends on a later one)
- snarktank/ai-dev-tasks — `create-prd.md` (clarifying questions, Non-Goals, Open Questions), `generate-tasks.md` (parent tasks, then sub-tasks)
- phuryn/pm-skills — `create-prd` ("Don't invent", omit unknown optional sections), `user-stories` (3 C's, INVEST)
- deanpeters/Product-Manager-Skills — `prd-development`, `user-story`, `epic-hypothesis`, `user-story-splitting`
- product-on-purpose/pm-skills — `develop-adr` ("an ADR without a decision is noise")
- anthropics/skills — `doc-coauthoring` (context gathering, reader testing)
- This repository's former `skills/spec/` (`spec-prd`, `spec-adr`) and `skills/sdd/` templates

## Canon per document

- PRD — Marty Cagan (SVPG), opportunity assessment; Intercom, problem before solution; Atlassian and Kevin Yien's templates
- ADR — Michael Nygard, "Documenting Architecture Decisions" (2011); MADR 4.x (`adr/madr`); Olaf Zimmermann's Y-statements
- Epic, feature, story — SAFe (epic hypothesis, feature benefit hypothesis); Bill Wake, INVEST; Ron Jeffries, the 3 C's; Alan Klement, job stories; Dan North, Given / When / Then; Richard Lawrence, story splitting patterns
- Tasks — spec-kit and Kiro task formats; vertical slicing
- Bug — Mozilla bug writing guidelines; ISTQB severity versus priority
- Spec — Malte Ubl, "Design Docs at Google"; Rust-style RFC sections; Alistair Mavin, EARS
- PR — Google engineering practices, "Writing good CL descriptions" and "Small CLs"; Conventional Commits 1.0
