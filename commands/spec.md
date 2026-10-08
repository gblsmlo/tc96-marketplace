---
nome: spec
descricao: Gera só a especificação de uma feature em .specs/ (requirements, design, user-experience, tasks, ADRs), cada arquivo como rascunho que o dono aprova, e para antes da implementação
tipo: comando
idioma: en
tags:
  - workflow
  - spec
---
# Spec generation only

**Input:** the request the person typed with the command: a feature, a change, or a problem.
**Output:** the files in `.specs/` that the scope needs, each written as a draft the owner
reviewed, and the planning envelope. No code.

This command runs two pillars, `workflow-research` and `workflow-planning`, and stops. It does
not decide anything those skills do not already decide; it fixes their order and the stop.
Every file is written through `workflow-spec`.
Rules: `WF-SPEC-*` in [Fluxo de Entrega — Quatro Pilares](../knowledge-base/fluxo-de-entrega-quatro-pilares.md) §5.

---

## Phase 0: Name the feature, read the project's document set

Pick a kebab-case slug for `.specs/<feature>/`. If the folder already exists, read only its
files' status lines: an `Approved` `requirements.md` means research is done, and this run
resumes at Phase 2; a `Draft` one means the run resumes at its review.

Read the record of which documents this project keeps: `## Specs` in `AGENTS.md`, then
`.specs/README.md` (`WF-SPEC-07`). Missing: `workflow-spec` asks the owner once, and asks
before writing to `AGENTS.md`.

---

## Phase 1: Research

Run `workflow-research` on the request.

- The scope (product, architecture, implementation detail) decides which files exist (`WF-SPEC-03`).
- Product scope: `workflow-spec` starts `product-manager` on `.specs/<feature>/requirements.md`
  and returns the `Draft` to the owner: path, problem sentence, open gaps, "approve, change,
  or reject?".
- An open gap that only the owner can decide stops the run here. Ask the owner, with the gap
  in one sentence.

**Gate:** product scope requires `requirements.md` in `Approved` before Phase 2, and only the
owner's answer sets it (`WF-SPEC-06`). No answer: the run ends here, with the path under
`lacunas`.

---

## Phase 2: Planning

Run `workflow-planning` from the research envelope. One `workflow-spec` call per file, each
returned to the owner for review before the next depends on it.

| File | Agent | When |
| --- | --- | --- |
| `.specs/<feature>/design.md` | `software-architect` | architecture scope, or a boundary or contract |
| `.specs/adr/NNNN-<slug>.md` | `software-architect` | one per accepted decision that outlives the feature |
| `.specs/<feature>/user-experience.md` | `product-designer` | product scope with an interface |
| `.specs/<feature>/tasks.md` | `project-manager` | always |

A document the project turned off is not written; its decision goes as one line to `tasks.md`
under **Origin** (`WF-SPEC-07`).

**Gate:** a `design.md` in `rfc` mode stays `In review` until its decision date; the run
reports it as an open gap instead of accepting it.

---

## Phase 3: Stop

Return the planning envelope, with every `.specs/` path in `artefato` and every file not yet
approved under `lacunas` as `awaiting owner approval: <path>`. Do not start
`workflow-implementation` (`WF-SPEC-05`). Implementation starts only on a new request from the
owner, one Task at a time, and only on files the owner approved (`WF-SPEC-04`).

---

## Checklist

- [ ] The project's document set was read, or asked once and recorded with permission.
- [ ] The scope is classified, and only the files it needs exist.
- [ ] Each file was written by its own agent through `workflow-spec`, and links the others instead of copying them.
- [ ] Every status past `Draft` came from the owner's answer in this conversation.
- [ ] `tasks.md` names one owner, acceptance and evidence per Task.
- [ ] No code, branch, commit or PR was created.
